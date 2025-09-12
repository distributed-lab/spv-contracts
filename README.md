# ERC-8002: SPV Gateway 

Introduce a singleton contract for on-chain verification of transactions that happened on Bitcoin. The contract acts as a trustless Simplified Payment Verification (SPV) gateway where anyone can submit Bitcoin block headers. The gateway maintains the mainchain of blocks and allows the existence of Bitcoin transactions to be verified via Merkle proofs.

Link to [ERC-8002](https://ethereum-magicians.org/t/erc-8002-simplified-payment-verification-gateway/25038).

> [!NOTE]
> Since the ERC is currently a draft, there is no deployment on mainnet available. Please use [the contract on Sepolia](https://sepolia.etherscan.io/address/0xE8e6CA2113338c12eb397617371D92239f3E6A60) for testing purposes.

# How it Works

The gateway is a permissionless contract that operates by receiving raw Bitcoin block headers (anyone can submit them), which are then parsed and validated against Bitcoin's consensus rules:

1. Header Parsing: Raw 80-byte Bitcoin block headers are parsed into a structured *BlockHeader.HeaderData* format, handling Bitcoin's little-endian byte ordering.
2. Double SHA256 Hashing: Each block header is double SHA256 hashed to derive its unique block hash, which is then saved in a big-endian format.
3. Proof-of-Work Verification: The calculated block hash is checked against the current network difficulty target (derived from the *bits* field in the block header).
4. Chain Extension & Reorganization: New blocks are added to a data structure that allows for tracking multiple chains. When a new block extends a chain with larger cumulative work, the *mainchainHead* is updated, reflecting potential chain reorganizations.
5. Difficulty Adjustment: Every 2016 blocks, the contract calculates a new difficulty target based on the time taken to mine the preceding epoch. This ensures the 10-minute average block time is maintained.

Under the hood, the contract builds the mainchain but doesn't define its finality. The number of required block confirmations is up to the integration dApps to decide.

## Submitting Bitcoin Blocks

To submit a new Bitcoin block, call `addBlockHeader` function by passing a valid raw block header as a parameter. It is an open function that will revert in case Bitcoin PoW checks don't pass.

In case multiple blocks can be added, call `addBlockHeaderBatch` function to save ~15% on gas per block.

## Verifying Bitcoin Tx Inclusion

In order to verify the tx existence, the `checkTxInclusion` function needs to be called. 

The list parameters to be passed:

1. `merkleProof` - Merkle path for a given transaction to be checked. The Merkle path can either be built locally or by calling `gettxoutproof` on a Bitcoin node.
2. `blockHash` - Hash of the block to check the tx inclusion against. This block is required to exist in the SPV storage.
3. `txId` - Tx hash (Merkle leaf) to be checked.
4. `txIndex` - The Merkle "direction bits" to decide on left or right hashing order.
5. `minConfirmationsCount` - Number of required mainchain confirmation for the block to have.

> [!TIP]
> Please check out [this test case](./test/SPVGateway.test.ts#L223) for more integration information.

## Permissionlessness

In order for the gateway to be truly permissionless, the contract's bootstrapping needs to be permissionless as well.

To initialize the gateway contract in a trustless manner, there is an extension contract, `HistoricalSPVGateway`, that uses a "proof-of-bitcoin" ZK proof for the initial bootstrapping.
More detailed information can be found in the extension section.

This will enable verification of historical Bitcoin transactions otherwise too expensive to include. Syncing up the gateway from Bitcoin's genesis would cost ~100 ETH on the mainnet.

# Extensions

## HistoricalSPVGateway

`HistoricalSPVGateway` is an extension of the basic `SPVGateway` contract. It allows for a "proof-of-bitcoin" ZK proof to be used during the initialization process to verify the correctness of the initial parameters. The ZK proof also contains public inputs that the `HistoricalSPVGateway` contract uses to build a Merkle root for the entire verified Bitcoin history.

This enables two new functions: `checkHistoryBlockInclusion` and `checkHistoryTxInclusion`, which can be used to verify the inclusion of historical blocks and transactions, respectively.

> [!TIP]
> The "proof-of-bitcoin" circuits can be found [here](https://github.com/distributed-lab/bitcoin-prover).

### History Merkle Root Calculation

As mentioned above, the `HistoricalSPVGateway` contract calculates the history Merkle root from the public inputs of the "proof-of-bitcoin" ZK proof. This Merkle root is a bit unusual, so here are instructions on how to build the same Merkle root on your own.

To understand the process, you need to be aware of a few key concepts.

#### Recursive Proofs and Chunks

First, it’s important to understand how the ZK circuits were built. Proving the entire Bitcoin history requires an immense amount of computational power. To make the circuits runnable on most computers, they use recursive proofs and process the history in chunks of **1024** blocks.

Because the proof is recursive, we must somehow pass the Merkle tree built from previous proofs. This brings us to the second key point: the final Merkle tree has two levels:
- Level1 is used to build an in-chunk tree for each **1024-block** segment.
- Level2 uses the roots of the Level1 Merkle trees as the values for its leaves.

[!NOTE]
> Level1 Merkle trees use `SHA256(abi.encodePacked("leaf1", blockHash))` and `SHA256(abi.encodePacked("node1", left, right))` for hashing leaves and nodes.
> Level2 Merkle trees use `SHA256(abi.encodePacked("leaf2", level1MerkleRoot))` and `SHA256(abi.encodePacked("node2", left, right))` for hashing leaves and nodes.

#### Understanding the *Frontier*

The next concept to grasp is the *frontier*. The *frontier* is the left part of the Level 2 Merkle tree, and it's returned in the public inputs. Simply put, it's an array of node hashes where the index corresponds to the level in the final Merkle tree.

> [!NOTE]
> The length of the *frontier* is calculated as  `Math.log2(provedBlocksCount / CHUNK_SIZE) + 1`.
> `zeroNodeHash(level)` is a recursive hash function that returns a zero hash for a leaf if the level is 0, and a node hash for subsequent levels.

#### Calculating the History Merkle Root on the Contract Side

Finally, here is how to calculate the History Merkle root on the contract side:
1. Count the length of the *frontier* from the `provedBlocksCount`.
2. Check if `provedBlocksCount` is a power of 2.
    1. If it is, the last element in the *frontier* is the History Merkle root.
    2. If not, proceed to step 3.
3. Iterate over all the *frontier* elements from the public inputs and calculate the History Merkle root according to the following rules:
    1. If `currentNode` and `computedRoot` are both zero, move to the next iteration.
    2. On the first iteration, the left element for hashing will be `currentNode` and the right will be `zeroNodeHash(0)`.
    3. For subsequent iterations, if the `currentNode` is zero, the left element for hashing will be `computedRoot` and the right will be `zeroNodeHash(currentLevel)`.
    4. In all other cases, the left element for hashing will be `currentNode` and the right will be `computedRoot`.
    5. Use the hash function for the Level 2 Merkle tree with the left and right values from the previous steps.

#### Calculating the History Merkle Root Off-chain

To calculate the History Merkle Root off-chain, you need to perform the following steps:
1. Fetch all block hashes from the genesis block up to the height of `provedBlocksCount - 1`.
2. Split these blocks into *1024-block* chunks.
3. Create Level1 Merkle trees for each chunk.
4. Create an array containing all the Level1 tree roots.
5. Pad array from the previous step with zeros to reach the next power of 2.
6. Create a Level2 Merkle tree, using the array from the last step as the tree's values.

### Verifying History Bitcoin blocks Inclusion

To verify the existence of a historical Bitcoin block, you need to call the `checkHistoryBlockInclusion` function.

This function requires a `HistoryBlockInclusionProofData` struct as a parameter, which contains the following fields:

1. `level1MerkleProof` - Level1 Merkle path for the block hash being checked.
2. `level2MerkleProof` - Level2 Merkle path for the Level1 Merkle root, which is calculated from the `level1MerkleProof`
3. `blockHash` - Block hash to be checked.
4. `blockHeight` - Block height of the passed block hash.

> [!TIP]
> Please check out [this test cases](./test/HistoricalSPVGateway.test.ts#L181) for more integration information.

### Verifying History Bitcoin Tx Inclusion

In order to verify the tx existence in the proved Bitcoin history, the `checkHistoryTxInclusion` function needs to be called. 

The list parameters to be passed:

1. `merkleProof` - Merkle path for a given transaction to be checked. The Merkle path can either be built locally or by calling `gettxoutproof` on a Bitcoin node.
2. `blockHeaderRaw` - Raw block header of the block to check the transaction's inclusion against.
3. `txId` - Tx hash (Merkle leaf) to be checked.
4. `txIndex` - The Merkle "direction bits" to decide on left or right hashing order.
5. `blockInclusionProofData` - The proof data for the block hash inclusion. For more details, refer to the description of the `checkHistoryBlockInclusion` function.

> [!TIP]
> Please check out [this test case](./test/HistoricalSPVGateway.test.ts#L309) for more integration information.

# Disclaimer

Bitcoin + Ethereum = <3

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title ISPVGatewayV2
 * @notice Interface for the SPV Gateway V2 contract, which manages Bitcoin mainchain block and transaction inclusion proofs,
 * SPV token rewards, and mainchain state updates.
 */
interface ISPVGatewayV2 {
    /**
     * @notice Data structure for block inclusion proof in history.
     * @param level1MerkleProof Merkle proof for the first level of the blocks tree.
     * @param level2MerkleProof Merkle proof for the second level of the blocks tree.
     * @param blockHash Hash of the block being proved.
     * @param blockHeight Height of the block in the Bitcoin blockchain.
     */
    struct HistoryBlockInclusionProofData {
        bytes32[] level1MerkleProof;
        bytes32[] level2MerkleProof;
        bytes32 blockHash;
        uint256 blockHeight;
    }

    /**
     * @notice Returns the root of the blocks tree.
     * @return The blocks tree root.
     */
    function getBlocksTreeRoot() external view returns (bytes32);

    /**
     * @notice Returns the current height of the mainchain.
     * @return The mainchain height.
     */
    function getMainchainHeight() external view returns (uint64);

    /**
     * @notice Checks if a transaction is included in a block using the provided Merkle proof and block inclusion proof data.
     * @param merkleProof_ The merkle proof for the transaction inclusion.
     * @param blockHeaderRaw_ The raw block header data.
     * @param txId_ The transaction ID to check for inclusion.
     * @param txIndex_ The index of the transaction in the block.
     * @param blockInclusionProofData_ The proof data for block inclusion in the mainchain.
     * @return True if the transaction is included, false otherwise.
     */
    function checkTxInclusion(
        bytes32[] calldata merkleProof_,
        bytes calldata blockHeaderRaw_,
        bytes32 txId_,
        uint256 txIndex_,
        HistoryBlockInclusionProofData calldata blockInclusionProofData_
    ) external view returns (bool);

    /**
     * @notice Checks if a block is included in the mainchain using the provided proof data.
     * @param inclusionProofData_ The proof data for block inclusion in the mainchain.
     * @return True if the block is included, false otherwise.
     */
    function checkBlockInclusion(
        HistoryBlockInclusionProofData calldata inclusionProofData_
    ) external view returns (bool);
}

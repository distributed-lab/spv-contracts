// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ISPVGateway} from "./ISPVGateway.sol";

/**
 * @title IHistoricalSPVGateway
 * @notice An interface for the Historical SPV Gateway that extends ISPVGateway.
 *
 * This contract allows for the trustless initialization of the gateway using a "proof-of-bitcoin" ZK proof.
 * It also includes functions to verify the inclusion of historical blocks and transactions using Merkle proofs.
 */
interface IHistoricalSPVGateway is ISPVGateway {
    /**
     * @notice Data structure for block inclusion proof in history.
     * @param level1MerkleProof Merkle proof for the first level of the history tree.
     * @param level2MerkleProof Merkle proof for the second level of the history tree.
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
     * @notice Error thrown when block header hash and inclusion proof hash differ.
     * @param blockHeaderHash Hash of the block header.
     * @param inclusionProofHash Hash from the inclusion proof.
     */
    error DifferentBlockHashes(bytes32 blockHeaderHash, bytes32 inclusionProofHash);

    /**
     * @notice Error thrown when a block hash is not found in the history.
     * @param blockHash Hash of the block not found in history.
     */
    error BlockHashNotInHistory(bytes32 blockHash);

    /**
     * @notice Checks whether a transaction is included in a historical block.
     * @param merkleProof_ Merkle proof for transaction inclusion.
     * @param blockHeaderRaw_ Raw block header data.
     * @param txId_ Transaction ID to verify.
     * @param txIndex_ Index of the transaction in the block.
     * @param blockInclusionProofData_ Proof data for block inclusion in history.
     * @return Returns true if the transaction is included in the historical block, false - otherwise.
     */
    function checkHistoryTxInclusion(
        bytes32[] calldata merkleProof_,
        bytes calldata blockHeaderRaw_,
        bytes32 txId_,
        uint256 txIndex_,
        HistoryBlockInclusionProofData calldata blockInclusionProofData_
    ) external view returns (bool);

    /**
     * @notice Checks whether a block is included in the historical blocks tree.
     * @param inclusionProofData_ Proof data for block inclusion in history.
     * @return Returns true if the block is included in the historical blocks tree, false - otherwise.
     */
    function checkHistoryBlockInclusion(
        HistoryBlockInclusionProofData calldata inclusionProofData_
    ) external view returns (bool);

    /**
     * @notice Gets the total number of historical blocks stored.
     * @return Returns the number of historical blocks.
     */
    function getHistoryBlocksCount() external view returns (uint256);

    /**
     * @notice Gets the root of the historical blocks tree.
     * @return Returns the root hash of the historical blocks tree.
     */
    function getHistoryBlocksTreeRoot() external view returns (bytes32);
}

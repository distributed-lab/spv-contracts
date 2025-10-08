// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ProofHelper} from "../libs/ProofHelper.sol";

/**
 * @title ISPVGatewayV2
 * @notice Interface for the SPV Gateway V2 contract, which manages Bitcoin mainchain block and transaction inclusion proofs,
 * SPV token rewards, and mainchain state updates.
 * @dev Provides functions and events for verifying block and transaction inclusion, updating mainchain state, and querying SPV-related data.
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
     * @notice Error thrown when the new cumulative work does not exceed the current mainchain cumulative work.
     * @param currentCumulativeWork The current cumulative work of the mainchain.
     * @param newCumulativeWork The cumulative work of the new mainchain candidate.
     */
    error NotANewMainchain(uint256 currentCumulativeWork, uint256 newCumulativeWork);
    /**
     * @notice Error thrown when the block header hash and the inclusion proof hash differ.
     * @param blockHeaderHash Hash of the block header.
     * @param inclusionProofHash Hash from the inclusion proof.
     */
    error DifferentBlockHashes(bytes32 blockHeaderHash, bytes32 inclusionProofHash);
    /**
     * @notice Error thrown when a block hash is not found in the current mainchain blocks tree.
     * @param blockHash Hash of the block not found in the mainchain blocks tree.
     */
    error BlockHashNotInTheMainchain(bytes32 blockHash);

    /**
     * @notice Emitted when the SPV token rewards amount is updated.
     * @param newRewardsAmount The new amount of SPV token rewards.
     */
    event SPVTokenRewardsAmountUpdated(uint256 newRewardsAmount);
    /**
     * @notice Emitted when SPV token rewards are sent to a recipient.
     * @param recipient The address receiving the rewards.
     * @param rewardsAmount The amount of rewards sent.
     */
    event SPVTokenRewardsSent(address indexed recipient, uint256 rewardsAmount);
    /**
     * @notice Emitted when the mainchain is updated.
     * @param newHeight The new height of the mainchain.
     * @param newCumulativeWork The new cumulative work of the mainchain.
     * @param newBlocksTreeRoot The new root of the blocks tree.
     */
    event MainchainUpdated(uint64 newHeight, uint256 newCumulativeWork, bytes32 newBlocksTreeRoot);

    /**
     * @notice Updates the mainchain with a new proof.
     * @param proofData_ The proof data for updating the mainchain.
     */
    function updateMainchain(ProofHelper.ProofData calldata proofData_) external;

    /**
     * @notice Returns the address of the proof verifier contract.
     * @return The address of the proof verifier.
     */
    function proofVerifier() external view returns (address);

    /**
     * @notice Returns the chunk size used for the proof generation.
     * @return The chunk size value.
     */
    function chunkSize() external view returns (uint256);

    /**
     * @notice Returns the maximum length of the proof frontier.
     * @return The maximum proof frontier length.
     */
    function maxProofFrontierLength() external view returns (uint256);

    /**
     * @notice Returns the address of the SPV token contract.
     * @return The address of the SPV token.
     */
    function getSPVToken() external view returns (address);

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
     * @notice Returns the cumulative work of the mainchain.
     * @return The mainchain cumulative work.
     */
    function getMainchainCumulativeWork() external view returns (uint256);

    /**
     * @notice Returns the current SPV token rewards amount.
     * @return The SPV token rewards amount.
     */
    function getSPVTokenRewardsAmount() external view returns (uint256);

    /**
     * @notice Returns the number of proofs since the last SPV token rewards halving.
     * @return The count of proofs from the last rewards halving.
     */
    function getProofsCountFromHalving() external view returns (uint256);

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

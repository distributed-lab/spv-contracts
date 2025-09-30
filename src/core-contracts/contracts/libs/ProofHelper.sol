// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {LibBit} from "solady/src/utils/LibBit.sol";

import {IHistoryProofVerifier} from "../interfaces/IHistoryProofVerifier.sol";

library ProofHelper {
    uint256 private constant FRONTIER_LENGTH = 25;
    uint256 private constant PROOF_BLOCK_HASH_OFFSET = 0;
    uint256 private constant PROOF_MEDIAN_TIMES_OFFSET = 32;
    uint256 private constant PROOF_BLOCK_HEIGHT_OFFSET = 44;
    uint256 private constant PROOF_CUMULATIVE_WORK_OFFSET = 45;
    uint256 private constant PROOF_FRONTIER_OFFSET = 46;

    /**
     * @notice A struct containing the data for a ZK-SNARK proof.
     * @param publicInputs An array of public inputs for the proof.
     * @param proof The serialized proof data.
     */
    struct ProofData {
        bytes32[] publicInputs;
        bytes proof;
    }

    error InvalidProofBlockHash();
    error InvalidProofBlockHeight();
    error InvalidProofCumulativeWork();
    error InvalidProofEpochStartTime();
    error InvalidHistoryBlocksTreeRoot();

    /**
     * @notice Calculates the history blocks Merkle tree root from the proof data.
     * @param provedBlocksCount_ The total number of blocks included in the proof.
     * @param proofData_ The struct containing the proof and public inputs.
     * @return parsedBlocksTreeRoot_ The calculated Merkle tree root.
     */
    function getBlocksTreeRoot(
        uint64 provedBlocksCount_,
        ProofData calldata proofData_
    ) internal pure returns (bytes32 parsedBlocksTreeRoot_) {
        // uint256 frontierLength_ = _countFrontierLength(provedBlocksCount_, 1);

        if (LibBit.isPo2(provedBlocksCount_)) {
            parsedBlocksTreeRoot_ = _getBytes32FromInputs(
                proofData_,
                PROOF_FRONTIER_OFFSET + 32 * (FRONTIER_LENGTH - 1)
            );
        } else {
            parsedBlocksTreeRoot_ = _countRootFromFrontier(FRONTIER_LENGTH, proofData_);
        }
    }

    /**
     * @notice Retrieves the block hash from the ZK proof's public inputs.
     * @param proofData_ The proof data struct.
     * @return The block hash.
     */
    function getProofBlockHash(ProofData calldata proofData_) internal pure returns (bytes32) {
        return _getBytes32FromInputs(proofData_, PROOF_BLOCK_HASH_OFFSET);
    }

    /**
     * @notice Retrieves the block height from the ZK proof's public inputs.
     * @param proofData_ The proof data struct.
     * @return The block height.
     */
    function getProofBlockHeight(ProofData calldata proofData_) internal pure returns (uint64) {
        return uint64(uint256(proofData_.publicInputs[PROOF_BLOCK_HEIGHT_OFFSET]));
    }

    /**
     * @notice Retrieves the cumulative work from the ZK proof's public inputs.
     * @param proofData_ The proof data struct.
     * @return The cumulative work.
     */
    function getProofCumulativeWork(
        ProofData calldata proofData_
    ) internal pure returns (uint256) {
        return uint256(proofData_.publicInputs[PROOF_CUMULATIVE_WORK_OFFSET]);
    }

    /**
     * @notice Retrieves the last proved epoch start time from the ZK proof's public inputs.
     * @param provedBlocksCount_ The total number of blocks included in the proof.
     * @param proofData_ The struct containing the proof and public inputs.
     * @return The epoch start time.
     */
    function getProofEpochStartTime(
        uint64 provedBlocksCount_,
        ProofData calldata proofData_
    ) internal pure returns (uint32) {
        return
            uint32(uint256(proofData_.publicInputs[PROOF_FRONTIER_OFFSET + 32 * FRONTIER_LENGTH]));
    }

    function getChunkNumber(
        uint256 blockHeight_,
        uint256 chunkSize_
    ) internal pure returns (uint256) {
        return blockHeight_ / chunkSize_;
    }

    function getIndexInChunk(
        uint256 blockHeight_,
        uint256 chunkSize_
    ) internal pure returns (uint256) {
        return blockHeight_ % chunkSize_;
    }

    /**
     * @notice Hashes two nodes to create a new node in a Level2 Merkle tree.
     * @param left_ The left node hash.
     * @param right_ The right node hash.
     * @return The resulting node hash.
     */
    function hashLevel2HistoryTreeNode(
        bytes32 left_,
        bytes32 right_
    ) internal pure returns (bytes32) {
        return sha256(abi.encodePacked("node2", left_, right_));
    }

    /**
     * @notice Hashes a value to create a leaf in a Level2 Merkle tree.
     * @param value_ The value to be hashed.
     * @return The resulting leaf hash.
     */
    function hashLevel2HistoryTreeLeaf(bytes32 value_) internal pure returns (bytes32) {
        return sha256(abi.encodePacked("leaf2", value_));
    }

    /**
     * @notice Hashes two nodes to create a new node in a Level1 Merkle tree.
     * @param left_ The left node hash.
     * @param right_ The right node hash.
     * @return The resulting node hash.
     */
    function hashLevel1HistoryTreeNode(
        bytes32 left_,
        bytes32 right_
    ) internal pure returns (bytes32) {
        return sha256(abi.encodePacked("node1", left_, right_));
    }

    /**
     * @notice Hashes a value to create a leaf in a Level1 Merkle tree.
     * @param value_ The value to be hashed.
     * @return The resulting leaf hash.
     */
    function hashLevel1HistoryTreeLeaf(bytes32 value_) internal pure returns (bytes32) {
        return sha256(abi.encodePacked("leaf1", value_));
    }

    /**
     * @notice Calculates the Merkle root from the `frontier` array.
     * @dev This function iterates through the public inputs' frontier to compute the final root.
     * @param frontierLength_ The length of the frontier array.
     * @param proofData_ The proof data struct.
     * @return computedRoot_ The computed Merkle root.
     */
    function _countRootFromFrontier(
        uint256 frontierLength_,
        ProofData calldata proofData_
    ) internal pure returns (bytes32 computedRoot_) {
        for (uint256 i = 0; i < frontierLength_ - 1; ++i) {
            bytes32 currentNode_ = _getBytes32FromInputs(
                proofData_,
                PROOF_FRONTIER_OFFSET + 32 * i
            );

            if (currentNode_ == 0 && computedRoot_ == 0) {
                // continue for the first not empty node
                continue;
            }

            bytes32 left_;
            bytes32 right_;

            if (i == 0) {
                (left_, right_) = (currentNode_, _getZeroNodeHash(i));
            } else if (currentNode_ == 0) {
                (left_, right_) = (computedRoot_, _getZeroNodeHash(i));
            } else {
                (left_, right_) = (currentNode_, computedRoot_);
            }

            computedRoot_ = hashLevel2HistoryTreeNode(left_, right_);
        }
    }

    // function _countFrontierLength(uint64 provedBlocksCount_, uint256 chunkSize_) private pure returns (uint256) {
    //     return Math.log2(provedBlocksCount_ / chunkSize_, Math.Rounding.Ceil) + 1;
    // }

    function _processProof(
        bytes32[] calldata merkleProof_,
        bytes32 value_,
        uint256 valueKey_,
        function(bytes32) pure returns (bytes32) hashLeaf_,
        function(bytes32, bytes32) pure returns (bytes32) hashNode_
    ) private pure returns (bytes32) {
        bytes32 computedHash_ = hashLeaf_(value_);

        uint256 pathIndex_ = valueKey_;
        uint256 depth_ = merkleProof_.length;

        while (depth_ > 0 && merkleProof_[depth_ - 1] == bytes32(0)) {
            --depth_;
        }

        for (uint256 i = depth_; i > 0; --i) {
            uint256 sIndex_ = i - 1;

            if ((pathIndex_ >> sIndex_) & 1 == 1) {
                computedHash_ = hashNode_(merkleProof_[sIndex_], computedHash_);
            } else {
                computedHash_ = hashNode_(computedHash_, merkleProof_[sIndex_]);
            }
        }

        return computedHash_;
    }

    function _getBytes32FromInputs(
        ProofData calldata proofData_,
        uint256 offset_
    ) private pure returns (bytes32) {
        bytes memory proofBlockHashRaw_ = new bytes(32);

        for (uint256 i = 0; i < 32; ++i) {
            proofBlockHashRaw_[i] = bytes1(uint8(uint256(proofData_.publicInputs[offset_ + i])));
        }

        return abi.decode(proofBlockHashRaw_, (bytes32));
    }

    function _getZeroNodeHash(uint256 level_) private pure returns (bytes32) {
        if (level_ == 0) {
            return hashLevel2HistoryTreeLeaf(0);
        }

        bytes32 prevLevelNodeHash_ = _getZeroNodeHash(level_ - 1);

        return hashLevel2HistoryTreeNode(prevLevelNodeHash_, prevLevelNodeHash_);
    }

    function _getHistoryTreeKey(
        uint256 indexInTree_,
        uint256 maxTreeDepth_
    ) private pure returns (uint256) {
        uint256 blockIndexReversed_ = LibBit.reverseBits(indexInTree_);

        return blockIndexReversed_ >> (256 - maxTreeDepth_);
    }
}

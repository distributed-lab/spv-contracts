// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {LibBit} from "solady/src/utils/LibBit.sol";

import {IHistoryProofVerifier} from "../interfaces/IHistoryProofVerifier.sol";

library ProofHelper {
    uint8 private constant MEDIAN_PAST_BLOCKS = 11;

    // Offsets from the start of the public inputs
    uint256 private constant PROOF_BLOCK_HASH_OFFSET = 0;
    uint256 private constant PROOF_MEDIAN_TIMES_OFFSET = 32;
    uint256 private constant PROOF_BLOCK_HEIGHT_OFFSET = 44;
    uint256 private constant PROOF_CUMULATIVE_WORK_OFFSET = 45;
    uint256 private constant PROOF_FRONTIER_OFFSET = 46;

    // Offsets after frontier
    uint256 private constant PROOF_EPOCH_START_TIME_OFFSET = 0;
    uint256 private constant PROOF_ADDRESS_COMM_OFFSET = 1;

    struct ProofData {
        uint64 blocksCount;
        bytes32[] publicInputs;
        bytes proof;
    }

    error InvalidProofBlockHeight();
    error InvalidProof();
    error InvalidAddressCommitment();

    function verifyProof(
        ProofData calldata proofData_,
        address verifier_
    ) internal view returns (bool) {
        require(
            proofData_.blocksCount == getBlockHeight(proofData_) + 1,
            InvalidProofBlockHeight()
        );
        require(
            IHistoryProofVerifier(verifier_).verify(proofData_.proof, proofData_.publicInputs),
            InvalidProof()
        );

        return true;
    }

    function verifyAddressCommitment(
        ProofData calldata proofData_,
        uint256 maxFrontierLength_,
        address sender_
    ) internal pure returns (bool) {
        bytes32 blockHash_ = getBlockHash(proofData_);
        bytes32 proofAddressComm_ = getAddressCommitment(proofData_, maxFrontierLength_);

        require(
            proofAddressComm_ == hashAddressCommitment(blockHash_, sender_) ||
                proofAddressComm_ == hashAddressCommitment(blockHash_, address(0)),
            InvalidAddressCommitment()
        );

        return true;
    }

    /**
     * @notice Verifies a Merkle proof against a Level2 Merkle tree.
     * @param level2MerkleProof_ The Merkle proof for the Level2 tree.
     * @param level2BlocksTreeRoot_ The expected root of the Level2 tree.
     * @param level1Root_ The root of the Level1 Merkle tree to be verified.
     * @param totalChunksNumber_ The total number of chunks.
     * @param chunkNumber_ The index of the chunk to be verified.
     * @return A boolean indicating whether the proof is valid.
     */
    function verifyLevel2Proof(
        bytes32[] calldata level2MerkleProof_,
        bytes32 level2BlocksTreeRoot_,
        bytes32 level1Root_,
        uint256 totalChunksNumber_,
        uint256 chunkNumber_
    ) internal pure returns (bool) {
        bytes32 processedLevel2Proof = processLevel2Proof(
            level2MerkleProof_,
            level1Root_,
            totalChunksNumber_,
            chunkNumber_
        );

        return processedLevel2Proof == level2BlocksTreeRoot_;
    }

    /**
     * @notice Verifies a Merkle proof against a Level1 Merkle tree.
     * @param level1MerkleProof_ The Merkle proof for the Level1 tree.
     * @param level1BlocksTreeRoot_ The expected root of the Level1 tree.
     * @param blockHash_ The hash of the block to be verified.
     * @param blockHeight_ The height of the block.
     * @return A boolean indicating whether the proof is valid.
     */
    function verifyLevel1Proof(
        bytes32[] calldata level1MerkleProof_,
        bytes32 level1BlocksTreeRoot_,
        bytes32 blockHash_,
        uint256 blockHeight_,
        uint256 chunkSize_
    ) internal pure returns (bool) {
        return
            processLevel1Proof(level1MerkleProof_, blockHash_, blockHeight_, chunkSize_) ==
            level1BlocksTreeRoot_;
    }

    /**
     * @notice Processes a Level2 Merkle proof to compute the final root.
     * @param level2MerkleProof_ The Merkle proof path.
     * @param level1Root_ The root of the Level1 Merkle tree.
     * @param totalChunksNumber_ The total number of chunks.
     * @param chunkNumber_ The index of the chunk.
     * @return The computed Level2 Merkle root.
     */
    function processLevel2Proof(
        bytes32[] calldata level2MerkleProof_,
        bytes32 level1Root_,
        uint256 totalChunksNumber_,
        uint256 chunkNumber_
    ) internal pure returns (bytes32) {
        return
            _processProof(
                level2MerkleProof_,
                level1Root_,
                getLevel2HistoryTreeKey(chunkNumber_, totalChunksNumber_),
                hashLevel2HistoryTreeLeaf,
                hashLevel2HistoryTreeNode
            );
    }

    /**
     * @notice Processes a Level1 Merkle proof to compute the final root.
     * @param level1MerkleProof_ The Merkle proof path.
     * @param blockHash_ The hash of the block.
     * @param blockHeight_ The height of the block.
     * @return The computed Level1 Merkle root.
     */
    function processLevel1Proof(
        bytes32[] calldata level1MerkleProof_,
        bytes32 blockHash_,
        uint256 blockHeight_,
        uint256 chunkSize_
    ) internal pure returns (bytes32) {
        return
            _processProof(
                level1MerkleProof_,
                blockHash_,
                getLevel1HistoryTreeKey(blockHeight_, chunkSize_),
                hashLevel1HistoryTreeLeaf,
                hashLevel1HistoryTreeNode
            );
    }

    /**
     * @notice Retrieves the block hash from the ZK proof's public inputs.
     * @param proofData_ The proof data struct.
     * @return The block hash.
     */
    function getBlockHash(ProofData calldata proofData_) internal pure returns (bytes32) {
        return _getBytes32FromInputs(proofData_, PROOF_BLOCK_HASH_OFFSET);
    }

    function getMedianTimes(
        ProofData calldata proofData_
    ) internal pure returns (uint32[] memory medianTimeArr_) {
        medianTimeArr_ = new uint32[](MEDIAN_PAST_BLOCKS);

        for (uint256 i = 0; i < MEDIAN_PAST_BLOCKS; ++i) {
            medianTimeArr_[i] = uint32(
                uint256(proofData_.publicInputs[PROOF_MEDIAN_TIMES_OFFSET + i])
            );
        }
    }

    /**
     * @notice Retrieves the block height from the ZK proof's public inputs.
     * @param proofData_ The proof data struct.
     * @return The block height.
     */
    function getBlockHeight(ProofData calldata proofData_) internal pure returns (uint64) {
        return uint64(uint256(proofData_.publicInputs[PROOF_BLOCK_HEIGHT_OFFSET]));
    }

    /**
     * @notice Retrieves the cumulative work from the ZK proof's public inputs.
     * @param proofData_ The proof data struct.
     * @return The cumulative work.
     */
    function getCumulativeWork(ProofData calldata proofData_) internal pure returns (uint256) {
        return uint256(proofData_.publicInputs[PROOF_CUMULATIVE_WORK_OFFSET]);
    }

    /**
     * @notice Calculates the blocks Merkle tree root from the proof data.
     * @param proofData_ The struct containing the proof and public inputs.
     * @return parsedBlocksTreeRoot_ The calculated Merkle tree root.
     */
    function getBlocksTreeRoot(
        ProofData calldata proofData_,
        uint256 chunkSize_
    ) internal pure returns (bytes32 parsedBlocksTreeRoot_) {
        uint256 frontierLength_ = _countFrontierLength(proofData_, chunkSize_);

        if (LibBit.isPo2(proofData_.blocksCount)) {
            parsedBlocksTreeRoot_ = _getBytes32FromInputs(
                proofData_,
                PROOF_FRONTIER_OFFSET + 32 * (frontierLength_ - 1)
            );
        } else {
            parsedBlocksTreeRoot_ = _countRootFromFrontier(frontierLength_, proofData_);
        }
    }

    /**
     * @notice Retrieves the last proved epoch start time from the ZK proof's public inputs.
     * @param proofData_ The struct containing the proof and public inputs.
     * @return The epoch start time.
     */
    function getEpochStartTime(
        ProofData calldata proofData_,
        uint256 maxFrontierLength_
    ) internal pure returns (uint32) {
        return
            uint32(
                uint256(
                    proofData_.publicInputs[
                        _getFrontierEndOffset(maxFrontierLength_) + PROOF_EPOCH_START_TIME_OFFSET
                    ]
                )
            );
    }

    function getAddressCommitment(
        ProofData calldata proofData_,
        uint256 maxFrontierLength_
    ) internal pure returns (bytes32) {
        return
            _getBytes32FromInputs(
                proofData_,
                _getFrontierEndOffset(maxFrontierLength_) + PROOF_ADDRESS_COMM_OFFSET
            );
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
     * @notice Calculates the Merkle tree key for a chunk in the Level2 tree.
     * @param chunkNumber_ The index of the chunk.
     * @param totalChunksNumber_ The total number of chunks.
     * @return The Level2 Merkle tree key.
     */
    function getLevel2HistoryTreeKey(
        uint256 chunkNumber_,
        uint256 totalChunksNumber_
    ) internal pure returns (uint256) {
        return _getHistoryTreeKey(chunkNumber_, Math.log2(totalChunksNumber_) + 1);
    }

    /**
     * @notice Calculates the Merkle tree key for a block in the Level1 tree.
     * @param blockHeight_ The height of the block.
     * @return The Level1 Merkle tree key.
     */
    function getLevel1HistoryTreeKey(
        uint256 blockHeight_,
        uint256 chunkSize_
    ) internal pure returns (uint256) {
        return
            _getHistoryTreeKey(getIndexInChunk(blockHeight_, chunkSize_), Math.log2(chunkSize_));
    }

    function hashAddressCommitment(
        bytes32 blockHash_,
        address addr_
    ) internal pure returns (bytes32) {
        return sha256(abi.encodePacked("address", blockHash_, addr_));
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

    function _getFrontierEndOffset(uint256 maxFrontierLength_) private pure returns (uint256) {
        return PROOF_FRONTIER_OFFSET + 32 * maxFrontierLength_;
    }

    function _countFrontierLength(
        ProofData calldata proofData_,
        uint256 chunkSize_
    ) private pure returns (uint256) {
        return Math.log2(proofData_.blocksCount / chunkSize_, Math.Rounding.Ceil) + 1;
    }

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

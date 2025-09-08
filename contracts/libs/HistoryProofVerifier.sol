// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IHistoryProofVerifier} from "../interfaces/IHistoryProofVerifier.sol";

library HistoryProofVerifier {
    uint256 private constant CHUNK_SIZE = 1024;

    uint256 private constant PROOF_BLOCK_HASH_OFFSET = 0;
    uint256 private constant PROOF_MEDIAN_TIMES_OFFSET = 32;
    uint256 private constant PROOF_BLOCK_HEIGHT_OFFSET = 44;
    uint256 private constant PROOF_CUMULATIVE_WORK_OFFSET = 45;
    uint256 private constant PROOF_FRONTIER_OFFSET = 46;

    struct HistoryProofData {
        address verifier;
        bytes32[] publicInputs;
        bytes proof;
    }

    error InvalidProofBlockHash();
    error InvalidProofBlockHeight();
    error InvalidProofCumulativeWork();
    error InvalidProof();
    error InvalidHistoryBlocksTreeRoot();

    function verifyHistoryProof(
        bytes32 historyBlocksTreeRoot_,
        bytes32 blockHash_,
        uint64 blockHeight_,
        uint256 cumulativeWork_,
        HistoryProofData calldata proofData_
    ) internal view returns (bool) {
        require(blockHash_ == getProofBlockHash(proofData_), InvalidProofBlockHash());
        require(blockHeight_ == getProofBlockHeight(proofData_), InvalidProofBlockHeight());
        require(
            cumulativeWork_ == getProofCumulativeWork(proofData_),
            InvalidProofCumulativeWork()
        );
        require(
            historyBlocksTreeRoot_ == getHistoryBlocksTreeRoot(blockHeight_ + 1, proofData_),
            InvalidHistoryBlocksTreeRoot()
        );
        require(
            IHistoryProofVerifier(proofData_.verifier).verify(
                proofData_.proof,
                proofData_.publicInputs
            ),
            InvalidProof()
        );

        return true;
    }

    function verifyLevel2Proof(
        bytes32[] calldata level2MerkleProof_,
        bytes32 level2BlocksTreeRoot_,
        bytes32 level1Root_,
        uint256 chunkNumber_
    ) internal pure returns (bool) {
        return
            processLevel2Proof(level2MerkleProof_, level1Root_, chunkNumber_) ==
            level2BlocksTreeRoot_;
    }

    function verifyLevel1Proof(
        bytes32[] calldata level1MerkleProof_,
        bytes32 level1BlocksTreeRoot_,
        bytes32 blockHash_,
        uint256 blockHeight_
    ) internal pure returns (bool) {
        return
            processLevel1Proof(level1MerkleProof_, blockHash_, blockHeight_) ==
            level1BlocksTreeRoot_;
    }

    function processLevel2Proof(
        bytes32[] calldata level2MerkleProof_,
        bytes32 level1Root_,
        uint256 chunkNumber_
    ) internal pure returns (bytes32) {
        return
            _processProof(
                level2MerkleProof_,
                level1Root_,
                chunkNumber_,
                hashLevel2HistoryTreeLeaf,
                hashLevel2HistoryTreeNode
            );
    }

    function processLevel1Proof(
        bytes32[] calldata level1MerkleProof_,
        bytes32 blockHash_,
        uint256 blockHeight_
    ) internal pure returns (bytes32) {
        return
            _processProof(
                level1MerkleProof_,
                blockHash_,
                getIndexInChunk(blockHeight_),
                hashLevel1HistoryTreeLeaf,
                hashLevel1HistoryTreeNode
            );
    }

    function getHistoryBlocksTreeRoot(
        uint64 provedBlocksCount_,
        HistoryProofData calldata proofData_
    ) internal pure returns (bytes32 parsedBlocksTreeRoot_) {
        uint256 frontierLength_ = Math.log2(provedBlocksCount_ / CHUNK_SIZE) + 1;

        bool isPowOf2_ = provedBlocksCount_ & (provedBlocksCount_ - 1) == 0;

        if (isPowOf2_) {
            parsedBlocksTreeRoot_ = _getBytes32FromInputs(
                proofData_,
                PROOF_FRONTIER_OFFSET + 32 * (frontierLength_ - 1)
            );
        } else {
            parsedBlocksTreeRoot_ = _countRootFromFrontier(frontierLength_, proofData_);
        }
    }

    function getProofBlockHash(
        HistoryProofData calldata proofData_
    ) internal pure returns (bytes32) {
        return _getBytes32FromInputs(proofData_, PROOF_BLOCK_HASH_OFFSET);
    }

    function getProofBlockHeight(
        HistoryProofData calldata proofData_
    ) internal pure returns (uint64) {
        return uint64(uint256(proofData_.publicInputs[PROOF_BLOCK_HEIGHT_OFFSET]));
    }

    function getProofCumulativeWork(
        HistoryProofData calldata proofData_
    ) internal pure returns (uint256) {
        return uint256(proofData_.publicInputs[PROOF_CUMULATIVE_WORK_OFFSET]);
    }

    function getChunkNumber(uint256 blockHeight_) internal pure returns (uint256) {
        return blockHeight_ / CHUNK_SIZE;
    }

    function getIndexInChunk(uint256 blockHeight_) internal pure returns (uint256) {
        return blockHeight_ % CHUNK_SIZE;
    }

    function hashLevel2HistoryTreeNode(
        bytes32 left_,
        bytes32 right_
    ) internal pure returns (bytes32) {
        return _doubleSHA256(abi.encode("node2", left_, right_));
    }

    function hashLevel2HistoryTreeLeaf(bytes32 value_) internal pure returns (bytes32) {
        return _doubleSHA256(abi.encode("leaf2", value_));
    }

    function hashLevel1HistoryTreeNode(
        bytes32 left_,
        bytes32 right_
    ) internal pure returns (bytes32) {
        return _doubleSHA256(abi.encode("node1", left_, right_));
    }

    function hashLevel1HistoryTreeLeaf(bytes32 value_) internal pure returns (bytes32) {
        return _doubleSHA256(abi.encode("leaf1", value_));
    }

    function _countRootFromFrontier(
        uint256 frontierLength_,
        HistoryProofData calldata proofData_
    ) internal pure returns (bytes32 computedRoot_) {
        for (uint256 i = 0; i < frontierLength_; ++i) {
            bytes32 currentNode_ = _getBytes32FromInputs(
                proofData_,
                PROOF_FRONTIER_OFFSET + 32 * i
            );

            if (currentNode_ == 0) {
                continue;
            }

            computedRoot_ = hashLevel2HistoryTreeNode(
                currentNode_,
                computedRoot_ == 0 ? _getZeroNodeHash(i) : computedRoot_
            );
        }
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
        HistoryProofData calldata proofData_,
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

    function _doubleSHA256(bytes memory data_) private pure returns (bytes32) {
        return sha256(abi.encodePacked(sha256(data_)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {BlockHeader} from "@solarity/solidity-lib/libs/bitcoin/BlockHeader.sol";
import {TxMerkleProof} from "@solarity/solidity-lib/libs/bitcoin/TxMerkleProof.sol";
import {EndianConverter} from "@solarity/solidity-lib/libs/utils/EndianConverter.sol";

import {TargetsHelper} from "./libs/TargetsHelper.sol";
import {HistoryProofVerifier} from "./libs/HistoryProofVerifier.sol";

import {IExtendedSPVGateway} from "./interfaces/IExtendedSPVGateway.sol";

import {SPVGateway} from "./SPVGateway.sol";

contract ExtendedSPVGateway is IExtendedSPVGateway, SPVGateway {
    using BlockHeader for bytes;
    using TargetsHelper for bytes32;
    using EndianConverter for bytes32;
    using HistoryProofVerifier for bytes32[];

    bytes32 public constant SPV_GATEWAY_HISTORY_STORAGE_SLOT =
        keccak256("spv.gateway.extended.spv.gateway.storage");

    struct ExtendedSPVGatewayStorage {
        bytes32 historyBlocksTreeRoot;
    }

    function _getExtendedSPVGatewayStorage()
        private
        pure
        returns (ExtendedSPVGatewayStorage storage _spvhs)
    {
        bytes32 slot_ = SPV_GATEWAY_STORAGE_SLOT;

        assembly {
            _spvhs.slot := slot_
        }
    }

    function __SPVGateway_init(
        bytes calldata blockHeaderRaw_,
        uint64 blockHeight_,
        uint256 cumulativeWork_,
        bytes32 historyBlocksTreeRoot_,
        HistoryProofVerifier.HistoryProofData calldata proofData_
    ) external initializer {
        (BlockHeader.HeaderData memory blockHeader_, bytes32 blockHash_) = _parseBlockHeaderRaw(
            blockHeaderRaw_
        );

        HistoryProofVerifier.verifyHistoryProof(
            historyBlocksTreeRoot_,
            blockHash_,
            blockHeight_,
            cumulativeWork_,
            proofData_
        );

        _initialize(blockHeader_, blockHash_, blockHeight_, cumulativeWork_);

        _getExtendedSPVGatewayStorage().historyBlocksTreeRoot = historyBlocksTreeRoot_;
    }

    function checkHistoryTxInclusion(
        bytes32[] calldata merkleProof_,
        bytes calldata blockHeaderRaw_,
        bytes32 txId_,
        uint256 txIndex_,
        HistoryBlockInclusionProofData calldata blockInclusionProofData_
    ) external view returns (bool) {
        (BlockHeader.HeaderData memory blockHeader_, bytes32 blockHash_) = blockHeaderRaw_
            .parseBlockHeader(true);

        require(
            blockHash_ == blockInclusionProofData_.blockHash,
            DifferentBlockHashes(blockHash_, blockInclusionProofData_.blockHash)
        );

        require(
            checkHistoryBlockInclusion(blockInclusionProofData_),
            BlockHashNotInHistory(blockHash_)
        );

        bytes32 leRoot_ = blockHeader_.merkleRoot.bytes32BEtoLE();

        return TxMerkleProof.verify(merkleProof_, leRoot_, txId_, txIndex_);
    }

    function checkHistoryBlockInclusion(
        HistoryBlockInclusionProofData calldata inclusionProofData_
    ) public view returns (bool) {
        bytes32 level1Root_ = inclusionProofData_.level1MerkleProof.processLevel1Proof(
            inclusionProofData_.blockHash,
            inclusionProofData_.blockHeight
        );
        uint256 chunkNumber_ = HistoryProofVerifier.getChunkNumber(
            inclusionProofData_.blockHeight
        );

        return
            inclusionProofData_.level2MerkleProof.verifyLevel2Proof(
                getHistoryBlocksTreeRoot(),
                level1Root_,
                chunkNumber_
            );
    }

    function getHistoryBlocksTreeRoot() public view returns (bytes32) {
        return _getExtendedSPVGatewayStorage().historyBlocksTreeRoot;
    }
}

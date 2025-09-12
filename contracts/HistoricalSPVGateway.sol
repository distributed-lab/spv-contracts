// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {BlockHeader} from "@solarity/solidity-lib/libs/bitcoin/BlockHeader.sol";
import {TxMerkleProof} from "@solarity/solidity-lib/libs/bitcoin/TxMerkleProof.sol";
import {EndianConverter} from "@solarity/solidity-lib/libs/utils/EndianConverter.sol";

import {TargetsHelper} from "./libs/TargetsHelper.sol";
import {BlockHistory} from "./libs/BlockHistory.sol";

import {IHistoricalSPVGateway} from "./interfaces/IHistoricalSPVGateway.sol";

import {SPVGateway} from "./SPVGateway.sol";

contract HistoricalSPVGateway is IHistoricalSPVGateway, SPVGateway {
    using BlockHeader for bytes;
    using TargetsHelper for bytes32;
    using EndianConverter for bytes32;
    using BlockHistory for bytes32[];

    bytes32 public constant HISTORICAL_SPV_GATEWAY_STORAGE_SLOT =
        keccak256("spv.gateway.historical.spv.gateway.storage");

    struct HistoricalSPVGatewayStorage {
        uint256 historyBlocksCount;
        bytes32 historyBlocksTreeRoot;
    }

    function _getHistoricalSPVGatewayStorage()
        private
        pure
        returns (HistoricalSPVGatewayStorage storage _hspvs)
    {
        bytes32 slot_ = HISTORICAL_SPV_GATEWAY_STORAGE_SLOT;

        assembly {
            _hspvs.slot := slot_
        }
    }

    function __HistoricalSPVGateway_init(
        bytes calldata blockHeaderRaw_,
        uint64 blockHeight_,
        uint256 cumulativeWork_,
        bytes32 historyBlocksTreeRoot_,
        BlockHistory.HistoryProofData calldata proofData_
    ) external initializer {
        (BlockHeader.HeaderData memory blockHeader_, bytes32 blockHash_) = _parseBlockHeaderRaw(
            blockHeaderRaw_
        );

        BlockHistory.verifyHistoryProof(
            historyBlocksTreeRoot_,
            blockHash_,
            blockHeight_,
            cumulativeWork_,
            proofData_
        );

        _initialize(blockHeader_, blockHash_, blockHeight_, cumulativeWork_);

        _getHistoricalSPVGatewayStorage().historyBlocksCount = blockHeight_;
        _getHistoricalSPVGatewayStorage().historyBlocksTreeRoot = historyBlocksTreeRoot_;
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

        return
            inclusionProofData_.level2MerkleProof.verifyLevel2Proof(
                getHistoryBlocksTreeRoot(),
                level1Root_,
                BlockHistory.getChunkNumber(getHistoryBlocksCount()),
                BlockHistory.getChunkNumber(inclusionProofData_.blockHeight)
            );
    }

    function getHistoryBlocksCount() public view returns (uint256) {
        return _getHistoricalSPVGatewayStorage().historyBlocksCount;
    }

    function getHistoryBlocksTreeRoot() public view returns (bytes32) {
        return _getHistoricalSPVGatewayStorage().historyBlocksTreeRoot;
    }
}

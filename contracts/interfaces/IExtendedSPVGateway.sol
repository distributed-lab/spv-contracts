// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ISPVGateway} from "./ISPVGateway.sol";

interface IExtendedSPVGateway is ISPVGateway {
    struct HistoryBlockInclusionProofData {
        bytes32[] level1MerkleProof;
        bytes32[] level2MerkleProof;
        bytes32 blockHash;
        uint256 blockHeight;
    }

    error DifferentBlockHashes(bytes32 blockHeaderHash, bytes32 inclusionProofHash);
    error BlockHashNotInHistory(bytes32 blockHash);

    function checkHistoryTxInclusion(
        bytes32[] calldata merkleProof_,
        bytes calldata blockHeaderRaw_,
        bytes32 txId_,
        uint256 txIndex_,
        HistoryBlockInclusionProofData calldata blockInclusionProofData_
    ) external view returns (bool);

    function checkHistoryBlockInclusion(
        HistoryBlockInclusionProofData calldata inclusionProofData_
    ) external view returns (bool);

    function getHistoryBlocksTreeRoot() external view returns (bytes32);
}

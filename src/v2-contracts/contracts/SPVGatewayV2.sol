// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

import {ADeployerGuard} from "@solarity/solidity-lib/utils/ADeployerGuard.sol";
import {BlockHeader} from "@solarity/solidity-lib/libs/bitcoin/BlockHeader.sol";
import {TxMerkleProof} from "@solarity/solidity-lib/libs/bitcoin/TxMerkleProof.sol";
import {EndianConverter} from "@solarity/solidity-lib/libs/utils/EndianConverter.sol";

import {ISPVGatewayV2} from "./interfaces/ISPVGatewayV2.sol";

import {ProofHelper} from "./libs/ProofHelper.sol";

contract SPVGatewayV2 is ISPVGatewayV2, ADeployerGuard, ERC20PermitUpgradeable {
    using BlockHeader for bytes;
    using EndianConverter for bytes32;
    using ProofHelper for *;

    bytes32 public constant SPV_GATEWAY_V2_STORAGE_SLOT =
        keccak256("spv.gateway.spv.gateway.v2.storage");

    uint256 public constant SPV_TOKEN_REWARDS_HALVING_PERIOD = 210_000;
    uint256 public constant INITIAL_SPV_TOKEN_REWARDS_AMOUNT = 50;

    address public immutable proofVerifier;
    uint256 public immutable chunkSize;
    uint256 public immutable maxProofFrontierLength;

    struct SPVGatewayV2Storage {
        uint256 spvTokenRewardsAmount;
        uint64 proofsCountFromHalving;
        uint64 mainchainHeight;
        uint256 mainchainCumulativeWork;
        bytes32 blocksTreeRoot;
    }

    function _getSPVGatewayV2Storage() private pure returns (SPVGatewayV2Storage storage _spvv2s) {
        bytes32 slot_ = SPV_GATEWAY_V2_STORAGE_SLOT;

        assembly {
            _spvv2s.slot := slot_
        }
    }

    constructor(
        address proofVerifier_,
        uint256 chunkSize_,
        uint256 maxProofFrontierLength_
    ) ADeployerGuard(msg.sender) {
        proofVerifier = proofVerifier_;
        chunkSize = chunkSize_;
        maxProofFrontierLength = maxProofFrontierLength_;
    }

    function __SPVGatewayV2_init() external initializer onlyDeployer {
        __ERC20_init("SPV Token", "SPV");
        __ERC20Permit_init("SPV Token");

        _setSPVTokenRewardsAmount(INITIAL_SPV_TOKEN_REWARDS_AMOUNT * (10 ** decimals()));
    }

    /// @inheritdoc ISPVGatewayV2
    function updateMainchain(ProofHelper.ProofData calldata proofData_) external {
        SPVGatewayV2Storage storage $ = _getSPVGatewayV2Storage();

        uint256 newCumulativeWork_ = proofData_.getCumulativeWork();

        require(
            newCumulativeWork_ > $.mainchainCumulativeWork,
            NotANewMainchain($.mainchainCumulativeWork, newCumulativeWork_)
        );
        proofData_.verifyAddressCommitment(maxProofFrontierLength, msg.sender);
        proofData_.verifyProof(proofVerifier);

        uint64 newMainchainHeight_ = proofData_.getBlockHeight();
        bytes32 newBlocksTreeRoot_ = proofData_.getBlocksTreeRoot(chunkSize);

        $.mainchainHeight = newMainchainHeight_;
        $.mainchainCumulativeWork = newCumulativeWork_;
        $.blocksTreeRoot = newBlocksTreeRoot_;

        _sendTokenRewards(msg.sender);
        _updateTokenRewardsAmount();

        emit MainchainUpdated(newMainchainHeight_, newCumulativeWork_, newBlocksTreeRoot_);
    }

    /// @inheritdoc ISPVGatewayV2
    function getBlocksTreeRoot() external view returns (bytes32) {
        return _getSPVGatewayV2Storage().blocksTreeRoot;
    }

    /// @inheritdoc ISPVGatewayV2
    function getMainchainHeight() external view returns (uint64) {
        return _getSPVGatewayV2Storage().mainchainHeight;
    }

    /// @inheritdoc ISPVGatewayV2
    function getMainchainCumulativeWork() external view returns (uint256) {
        return _getSPVGatewayV2Storage().mainchainCumulativeWork;
    }

    /// @inheritdoc ISPVGatewayV2
    function getSPVTokenRewardsAmount() external view returns (uint256) {
        return _getSPVGatewayV2Storage().spvTokenRewardsAmount;
    }

    /// @inheritdoc ISPVGatewayV2
    function getProofsCountFromHalving() external view returns (uint256) {
        return _getSPVGatewayV2Storage().proofsCountFromHalving;
    }

    /// @inheritdoc ISPVGatewayV2
    function checkTxInclusion(
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
            checkBlockInclusion(blockInclusionProofData_),
            BlockHashNotInTheMainchain(blockHash_)
        );

        bytes32 leRoot_ = blockHeader_.merkleRoot.bytes32BEtoLE();

        return TxMerkleProof.verify(merkleProof_, leRoot_, txId_, txIndex_);
    }

    /// @inheritdoc ISPVGatewayV2
    function checkBlockInclusion(
        HistoryBlockInclusionProofData calldata inclusionProofData_
    ) public view returns (bool) {
        SPVGatewayV2Storage storage $ = _getSPVGatewayV2Storage();

        bytes32 level1Root_ = inclusionProofData_.level1MerkleProof.processLevel1Proof(
            inclusionProofData_.blockHash,
            inclusionProofData_.blockHeight,
            chunkSize
        );

        return
            inclusionProofData_.level2MerkleProof.verifyLevel2Proof(
                $.blocksTreeRoot,
                level1Root_,
                ProofHelper.getChunkNumber($.mainchainHeight, chunkSize),
                ProofHelper.getChunkNumber(inclusionProofData_.blockHeight, chunkSize)
            );
    }

    function _sendTokenRewards(address to_) internal {
        SPVGatewayV2Storage storage $ = _getSPVGatewayV2Storage();

        uint256 rewardsAmount_ = $.spvTokenRewardsAmount;

        _mint(to_, rewardsAmount_);
        $.proofsCountFromHalving++;

        emit SPVTokenRewardsSent(to_, rewardsAmount_);
    }

    function _updateTokenRewardsAmount() internal {
        SPVGatewayV2Storage storage $ = _getSPVGatewayV2Storage();

        if ($.proofsCountFromHalving == _getHalvingPeriod()) {
            _setSPVTokenRewardsAmount($.spvTokenRewardsAmount / 2);

            delete $.proofsCountFromHalving;
        }
    }

    function _setSPVTokenRewardsAmount(uint256 newRewardsAmount) internal {
        _getSPVGatewayV2Storage().spvTokenRewardsAmount = newRewardsAmount;

        emit SPVTokenRewardsAmountUpdated(newRewardsAmount);
    }

    function _getHalvingPeriod() internal view virtual returns (uint256) {
        return SPV_TOKEN_REWARDS_HALVING_PERIOD;
    }
}

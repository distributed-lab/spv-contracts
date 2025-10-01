// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {ADeployerGuard} from "@solarity/solidity-lib/utils/ADeployerGuard.sol";

import {ISPVGatewayV2} from "./interfaces/ISPVGatewayV2.sol";
import {ISPVToken} from "./interfaces/tokens/ISPVToken.sol";

import {ProofHelper} from "./libs/ProofHelper.sol";

contract SPVGatewayV2 is ISPVGatewayV2, ADeployerGuard, Initializable {
    using ProofHelper for ProofHelper.ProofData;

    bytes32 public constant SPV_GATEWAY_V2_STORAGE_SLOT =
        keccak256("spv.gateway.spv.gateway.v2.storage");

    uint256 public constant SPV_TOKEN_REWARDS_HALVING_PERIOD = 210_000;
    uint256 public constant INITIAL_SPV_TOKEN_REWARDS_AMOUNT = 50;

    address public immutable proofVerifier;
    uint256 public immutable chunkSize;
    uint256 public immutable maxProofFrontierLength;

    struct SPVGatewayV2Storage {
        ISPVToken spvToken;
        uint256 currentTokenRewardsAmount;
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

    function __SPVGatewayV2_init(address spvTokenAddr_) external initializer onlyDeployer {
        SPVGatewayV2Storage storage $ = _getSPVGatewayV2Storage();

        ISPVToken spvToken = ISPVToken(spvTokenAddr_);

        $.spvToken = spvToken;
        _setSPVTokenRewardsAmount(INITIAL_SPV_TOKEN_REWARDS_AMOUNT * (10 ** spvToken.decimals()));
    }

    function updateMainchain(ProofHelper.ProofData calldata proofData_) external {
        SPVGatewayV2Storage storage $ = _getSPVGatewayV2Storage();

        uint256 newCumulativeWork_ = proofData_.getCumulativeWork();

        require(
            newCumulativeWork_ > $.mainchainCumulativeWork,
            NotANewMainchain($.mainchainCumulativeWork, newCumulativeWork_)
        );
        proofData_.verifyProof(proofVerifier);

        uint64 newMainchainHeight_ = proofData_.getBlockHeight();
        bytes32 newBlocksTreeRoot_ = proofData_.getBlocksTreeRoot(chunkSize);

        $.mainchainHeight = newMainchainHeight_;
        $.mainchainCumulativeWork = newCumulativeWork_;
        $.blocksTreeRoot = newBlocksTreeRoot_;

        _updateTokenRewardsAmount();
        _sendTokenRewards(msg.sender);

        emit MainchainUpdated(newMainchainHeight_, newCumulativeWork_, newBlocksTreeRoot_);
    }

    function getSPVToken() external view returns (address) {
        return address(_getSPVGatewayV2Storage().spvToken);
    }

    function getBlocksTreeRoot() external view returns (bytes32) {
        return _getSPVGatewayV2Storage().blocksTreeRoot;
    }

    function getMainchainHeight() external view returns (uint64) {
        return _getSPVGatewayV2Storage().mainchainHeight;
    }

    function getMainchainCumulativeWork() external view returns (uint256) {
        return _getSPVGatewayV2Storage().mainchainCumulativeWork;
    }

    function getCurrentSPVTokensRewardsAmount() external view returns (uint256) {
        return _getSPVGatewayV2Storage().currentTokenRewardsAmount;
    }

    function getProofsCountFromHalving() external view returns (uint256) {
        return _getSPVGatewayV2Storage().proofsCountFromHalving;
    }

    function _sendTokenRewards(address to_) internal {
        SPVGatewayV2Storage storage $ = _getSPVGatewayV2Storage();

        uint256 rewardsAmount_ = $.currentTokenRewardsAmount;

        $.spvToken.mintTo(to_, rewardsAmount_);
        $.proofsCountFromHalving++;

        emit SPVTokenRewardsSent(to_, rewardsAmount_);
    }

    function _updateTokenRewardsAmount() internal {
        SPVGatewayV2Storage storage $ = _getSPVGatewayV2Storage();

        if ($.proofsCountFromHalving == _getHalvingPeriod()) {
            _setSPVTokenRewardsAmount($.currentTokenRewardsAmount >> 2);

            delete $.proofsCountFromHalving;
        }
    }

    function _setSPVTokenRewardsAmount(uint256 newRewardsAmount) internal {
        _getSPVGatewayV2Storage().currentTokenRewardsAmount = newRewardsAmount;

        emit SPVTokenRewardsAmountUpdated(newRewardsAmount);
    }

    function _getHalvingPeriod() internal view virtual returns (uint256) {
        return SPV_TOKEN_REWARDS_HALVING_PERIOD;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {ADeployerGuard} from "@solarity/solidity-lib/utils/ADeployerGuard.sol";

import {ISPVGatewayV2} from "./interfaces/ISPVGatewayV2.sol";
import {IHistoryProofVerifier} from "./interfaces/IHistoryProofVerifier.sol";
import {ISPVToken} from "./interfaces/tokens/ISPVToken.sol";

import {ProofHelper} from "./libs/ProofHelper.sol";

contract SPVGatewayV2 is ISPVGatewayV2, ADeployerGuard, Initializable {
    using ProofHelper for ProofHelper.ProofData;

    bytes32 public constant SPV_GATEWAY_V2_STORAGE_SLOT =
        keccak256("spv.gateway.spv.gateway.v2.storage");

    uint256 public constant SPV_TOKEN_REWARDS_HALVING_PERIOD = 210_000;
    uint256 public constant INITIAL_SPV_TOKEN_REWARDS_AMOUNT = 50;

    struct SPVGatewayV2Storage {
        ISPVToken spvToken;
        IHistoryProofVerifier proofVerifier;
        uint256 currentTokenRewardsAmount;
        uint64 currentProofsCount;
        uint64 mainchainHeight;
        uint256 mainchainCumulativeWork;
        bytes32 blocksTreeRoot;
    }

    error NotANewMainchain(uint256 currentCumulativeWork, uint256 newCumulativeWork);
    error InvalidProof();

    event SPVTokenRewardsAmountUpdated(uint256 newRewardsAmount);
    event SPVTokenRewardsSent(address indexed recipient, uint256 rewardsAmount);
    event MainchainUpdated(uint64 newHeight, uint256 newCumulativeWork, bytes32 newBlocksTreeRoot);

    function _getSPVGatewayV2Storage() private pure returns (SPVGatewayV2Storage storage _spvv2s) {
        bytes32 slot_ = SPV_GATEWAY_V2_STORAGE_SLOT;

        assembly {
            _spvv2s.slot := slot_
        }
    }

    constructor() ADeployerGuard(msg.sender) {}

    function __SPVGatewayV2_init(
        address spvTokenAddr_,
        address proofVerifier_
    ) external initializer onlyDeployer {
        SPVGatewayV2Storage storage $ = _getSPVGatewayV2Storage();

        ISPVToken spvToken = ISPVToken(spvTokenAddr_);

        $.spvToken = spvToken;
        $.proofVerifier = IHistoryProofVerifier(proofVerifier_);
        _setSPVTokenRewardsAmount(INITIAL_SPV_TOKEN_REWARDS_AMOUNT * (10 ** spvToken.decimals()));
    }

    function updateMainchain(ProofHelper.ProofData calldata proofData_) external {
        SPVGatewayV2Storage storage $ = _getSPVGatewayV2Storage();

        uint256 newCumulativeWork_ = proofData_.getProofCumulativeWork();

        require(
            newCumulativeWork_ > $.mainchainCumulativeWork,
            NotANewMainchain($.mainchainCumulativeWork, newCumulativeWork_)
        );
        require($.proofVerifier.verify(proofData_.proof, proofData_.publicInputs), InvalidProof());

        uint64 newMainchainHeight_ = proofData_.getProofBlockHeight();
        bytes32 newBlocksTreeRoot_ = ProofHelper.getBlocksTreeRoot(
            newMainchainHeight_,
            proofData_
        );

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

    function getProofVerifier() external view returns (address) {
        return address(_getSPVGatewayV2Storage().proofVerifier);
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

    function getCurrentProofsCount() external view returns (uint256) {
        return _getSPVGatewayV2Storage().currentProofsCount;
    }

    function _sendTokenRewards(address to_) internal {
        SPVGatewayV2Storage storage $ = _getSPVGatewayV2Storage();

        uint256 rewardsAmount_ = $.currentTokenRewardsAmount;

        $.spvToken.mintTo(to_, rewardsAmount_);
        $.currentProofsCount++;

        emit SPVTokenRewardsSent(to_, rewardsAmount_);
    }

    function _updateTokenRewardsAmount() internal {
        SPVGatewayV2Storage storage $ = _getSPVGatewayV2Storage();

        if ($.currentProofsCount == _getProofsCountToRewardsHalving()) {
            _setSPVTokenRewardsAmount($.currentTokenRewardsAmount >> 2);

            delete $.currentProofsCount;
        }
    }

    function _setSPVTokenRewardsAmount(uint256 newRewardsAmount) internal {
        _getSPVGatewayV2Storage().currentTokenRewardsAmount = newRewardsAmount;

        emit SPVTokenRewardsAmountUpdated(newRewardsAmount);
    }

    function _getProofsCountToRewardsHalving() internal view virtual returns (uint256) {
        return SPV_TOKEN_REWARDS_HALVING_PERIOD;
    }
}

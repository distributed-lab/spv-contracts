// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ProofHelper} from "../libs/ProofHelper.sol";

interface ISPVGatewayV2 {
    error NotANewMainchain(uint256 currentCumulativeWork, uint256 newCumulativeWork);

    event SPVTokenRewardsAmountUpdated(uint256 newRewardsAmount);
    event SPVTokenRewardsSent(address indexed recipient, uint256 rewardsAmount);
    event MainchainUpdated(uint64 newHeight, uint256 newCumulativeWork, bytes32 newBlocksTreeRoot);

    function updateMainchain(ProofHelper.ProofData calldata proofData_) external;

    function proofVerifier() external view returns (address);

    function chunkSize() external view returns (uint256);

    function maxProofFrontierLength() external view returns (uint256);

    function getSPVToken() external view returns (address);

    function getBlocksTreeRoot() external view returns (bytes32);

    function getMainchainHeight() external view returns (uint64);

    function getMainchainCumulativeWork() external view returns (uint256);

    function getCurrentSPVTokensRewardsAmount() external view returns (uint256);

    function getProofsCountFromHalving() external view returns (uint256);
}

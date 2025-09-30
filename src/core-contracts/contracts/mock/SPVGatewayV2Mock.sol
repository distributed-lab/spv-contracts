// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {SPVGatewayV2} from "../SPVGatewayV2.sol";

contract SPVGatewayV2Mock is SPVGatewayV2 {
    uint256 public proofsCountToHalving;

    function setProofsCountToHalving(uint256 newValue_) external {
        proofsCountToHalving = newValue_;
    }

    function _getProofsCountToRewardsHalving() internal view override returns (uint256) {
        return proofsCountToHalving;
    }
}

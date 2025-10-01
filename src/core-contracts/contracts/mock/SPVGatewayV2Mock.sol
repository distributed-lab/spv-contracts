// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {SPVGatewayV2} from "../SPVGatewayV2.sol";

contract SPVGatewayV2Mock is SPVGatewayV2 {
    uint256 public proofsCountToHalving;

    constructor(
        address proofVerifier_,
        uint256 chunkSize_,
        uint256 maxProofFrontierLength_
    ) SPVGatewayV2(proofVerifier_, chunkSize_, maxProofFrontierLength_) {}

    function setProofsCountToHalving(uint256 newValue_) external {
        proofsCountToHalving = newValue_;
    }

    function _getHalvingPeriod() internal view override returns (uint256) {
        return proofsCountToHalving;
    }
}

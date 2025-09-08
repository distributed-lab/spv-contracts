// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IHistoryProofVerifier {
    function verify(
        bytes calldata proof_,
        bytes32[] calldata publicInputs_
    ) external view returns (bool);
}

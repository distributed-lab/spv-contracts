// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IHistoryProofVerifier
 * @notice An interface for verifying a historical proof using a ZK-SNARK.
 */
interface IHistoryProofVerifier {
    /**
     * @notice Verifies a ZK-SNARK proof against a set of public inputs.
     * @param proof_ The serialized ZK-SNARK proof.
     * @param publicInputs_ An array of public inputs required for proof verification.
     * @return A boolean value indicating whether the proof is valid (true) or not (false).
     */
    function verify(
        bytes calldata proof_,
        bytes32[] calldata publicInputs_
    ) external view returns (bool);
}

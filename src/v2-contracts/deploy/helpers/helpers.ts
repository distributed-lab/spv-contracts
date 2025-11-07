import { ethers } from "hardhat";

export function getGuardedSalt(salt: string): string {
  return ethers.keccak256(ethers.AbiCoder.defaultAbiCoder().encode(["bytes32"], [salt]));
}

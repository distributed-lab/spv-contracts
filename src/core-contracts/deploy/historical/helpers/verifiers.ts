import { getGuardedSalt } from "@/deploy/helpers/helpers";
import {
  ICreateX__factory,
  HistoryProofVerifier912384__factory,
  HistoryProofVerifier914432__factory,
} from "@/generated-types/ethers";
import { Deployer } from "@solarity/hardhat-migrate";
import { ethers } from "hardhat";

export async function deployHistoryVerifier(deployer: Deployer, blocksCount: bigint): Promise<string> {
  const createXDeployer = await deployer.deployed(ICreateX__factory, "0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed");

  const verifierBytecode = getHistoryVerifierBytecode(blocksCount);
  const verifierSalt = getHistoryVerifierSalt(blocksCount);

  const verifierAddress = await createXDeployer.computeCreate2Address(
    getGuardedSalt(verifierSalt),
    ethers.keccak256(verifierBytecode),
  );

  if ((await ethers.provider.getCode(verifierAddress)) == "") {
    await createXDeployer.deployCreate2(verifierSalt, verifierBytecode);
  }

  return verifierAddress;
}

export function getHistoryVerifierBytecode(blocksCount: bigint): string {
  switch (blocksCount) {
    case 912384n:
      return HistoryProofVerifier912384__factory.bytecode;
    case 914432n:
      return HistoryProofVerifier914432__factory.bytecode;
    default:
      throw new Error("Unsupported blocks count!");
  }
}

export function getHistoryVerifierSalt(blocksCount: bigint): string {
  const saltSuffix = ethers.hexlify(ethers.toUtf8Bytes(`HPV${blocksCount}`));

  // zero address + 00 (cross-chain redeploy protection) + 0000 + ASCII(HPV + {blocksCount})
  return `${ethers.ZeroAddress}000000${saltSuffix.slice(2)}`;
}

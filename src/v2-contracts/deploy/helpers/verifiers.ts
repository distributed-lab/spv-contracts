import { getGuardedSalt } from "@/deploy/helpers/helpers";
import { ICreateX__factory, HistoryProofVerifier__factory } from "@/generated-types/ethers";
import { Deployer } from "@solarity/hardhat-migrate";
import { ethers } from "hardhat";

export async function deployHistoryVerifier(deployer: Deployer): Promise<string> {
  const createXDeployer = await deployer.deployed(ICreateX__factory, "0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed");

  const verifierBytecode = HistoryProofVerifier__factory.bytecode;
  const verifierSalt = getHistoryVerifierSalt();

  const verifierAddress = await createXDeployer.computeCreate2Address(
    getGuardedSalt(verifierSalt),
    ethers.keccak256(verifierBytecode),
  );

  if ((await ethers.provider.getCode(verifierAddress)).slice(2) == "") {
    await createXDeployer.deployCreate2(verifierSalt, verifierBytecode);
  }

  return verifierAddress;
}

export function getHistoryVerifierSalt(): string {
  const saltSuffix = ethers.hexlify(ethers.toUtf8Bytes(`HVerifier`));

  // zero address + 00 (cross-chain redeploy protection) + 0000 + ASCII(HVerifier)
  return `${ethers.ZeroAddress}000000${saltSuffix.slice(2)}`;
}

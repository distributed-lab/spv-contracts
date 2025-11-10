import { Deployer, Reporter } from "@solarity/hardhat-migrate";

import { SPVGatewayV2__factory, ICreateX__factory } from "@ethers-v6";

import { deployHistoryVerifier, getGuardedSalt } from "./helpers";
import { getConfig } from "./config/config";
import { ethers } from "hardhat";

export = async (deployer: Deployer) => {
  const config = await getConfig();

  const createXDeployer = await deployer.deployed(ICreateX__factory, "0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed");

  const historyVerifierAddress = await deployHistoryVerifier(deployer);

  const constructorArgsEncoded = SPVGatewayV2__factory.createInterface().encodeDeploy([
    historyVerifierAddress,
    config.chunkSize,
    config.maxProofFrontierLength,
  ]);

  const SPVGatewayV2Initcode = SPVGatewayV2__factory.bytecode + constructorArgsEncoded.slice(2);

  const initCalldata = SPVGatewayV2__factory.createInterface().encodeFunctionData("__SPVGatewayV2_init()");

  // zero address + 00 (cross-chain redeploy protection) + ASCII(SPV2Gateway)
  const historicalSPVGatewaySalt = `0x0000000000000000000000000000000000000000005350563247617465776179`;

  await createXDeployer.deployCreate2AndInit(historicalSPVGatewaySalt, SPVGatewayV2Initcode, initCalldata, {
    constructorAmount: 0n,
    initCallAmount: 0n,
  });

  const guardedSalt = getGuardedSalt(historicalSPVGatewaySalt);
  const initcodeHash = ethers.keccak256(SPVGatewayV2Initcode);

  const spvGatewayAddr = await createXDeployer.computeCreate2Address(guardedSalt, initcodeHash);

  Reporter.reportContracts(["SPVGatewayV2", spvGatewayAddr]);
};

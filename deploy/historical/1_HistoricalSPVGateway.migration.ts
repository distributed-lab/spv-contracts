import { Deployer, Reporter } from "@solarity/hardhat-migrate";

import { ICreateX__factory, HistoricalSPVGateway__factory } from "@ethers-v6";

import path from "path";
import { ethers } from "hardhat";
import { getHistoryProofFromFile, getHistoryProofPublicInputsFromFile } from "@/test/helpers";

import { getHistoricalConfig } from "../config/config";
import { getGuardedSalt } from "../helpers/helpers";
import { deployHistoryVerifier } from "./helpers";

export = async (deployer: Deployer) => {
  const config = await getHistoricalConfig();

  const createXDeployer = await deployer.deployed(ICreateX__factory, "0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed");

  const historyVerifierAddress = await deployHistoryVerifier(deployer, config.proofBlocksCount);

  const proofDirPath = path.join(__dirname, "./proofs", config.proofBlocksCount.toString());

  const proof = getHistoryProofFromFile(proofDirPath);
  const publicInputs = getHistoryProofPublicInputsFromFile(proofDirPath);

  const historicalSPVInitData = HistoricalSPVGateway__factory.createInterface().encodeFunctionData(
    "__HistoricalSPVGateway_init(bytes,uint64,uint32,uint256,bytes32,(address,bytes32[],bytes))",
    [
      config.blockHeader,
      config.blockHeight,
      config.lastHistoryEpochStartTime,
      config.cumulativeWork,
      config.historyBlocksTreeRoot,
      {
        verifier: historyVerifierAddress,
        proof: proof,
        publicInputs: publicInputs,
      },
    ],
  );

  // zero address + 00 (cross-chain redeploy protection) + ASCII(HSPVGateway)
  const historicalSPVGatewaySalt = `0x0000000000000000000000000000000000000000004853505647617465776179`;

  await createXDeployer.deployCreate2AndInit(
    historicalSPVGatewaySalt,
    HistoricalSPVGateway__factory.bytecode,
    historicalSPVInitData,
    {
      constructorAmount: 0n,
      initCallAmount: 0n,
    },
  );

  const historicalSPVGatewayAddress = await createXDeployer.computeCreate2Address(
    getGuardedSalt(historicalSPVGatewaySalt),
    ethers.keccak256(HistoricalSPVGateway__factory.bytecode),
  );

  Reporter.reportContracts(["HistoricalSPVGateway", historicalSPVGatewayAddress]);
};

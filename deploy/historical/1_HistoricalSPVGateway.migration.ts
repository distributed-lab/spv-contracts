import { Deployer, Reporter } from "@solarity/hardhat-migrate";

import { HistoryProofVerifier912384__factory, ICreateX__factory, HistoricalSPVGateway__factory } from "@ethers-v6";

import path from "path";
import { ethers } from "hardhat";
import { getHistoryProofFromFile, getHistoryProofPublicInputsFromFile } from "@/test/helpers";

import { getHistoricalConfig } from "../config/config";
import { getGuardedSalt } from "../helpers/helpers";

export = async (deployer: Deployer) => {
  const config = await getHistoricalConfig();

  const createXDeployer = await deployer.deployed(ICreateX__factory, "0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed");

  // zero address + 00 (cross-chain redeploy protection) + 0000 + ASCII(HPV912384)
  const historyVerifier912384Salt = `0x0000000000000000000000000000000000000000000000485056393132333834`;

  await createXDeployer.deployCreate2(historyVerifier912384Salt, HistoryProofVerifier912384__factory.bytecode);

  const historyVerifierAddress = await createXDeployer.computeCreate2Address(
    getGuardedSalt(historyVerifier912384Salt),
    ethers.keccak256(HistoryProofVerifier912384__factory.bytecode),
  );

  const proofDirPath = path.join(__dirname, "./proofs", config.proofBlocksCount.toString());

  const proof = getHistoryProofFromFile(proofDirPath);
  const publicInputs = getHistoryProofPublicInputsFromFile(proofDirPath);

  const historicalSPVInitData = HistoricalSPVGateway__factory.createInterface().encodeFunctionData(
    "__SPVGateway_init(bytes,uint64,uint256,bytes32,(address,bytes32[],bytes))",
    [
      config.blockHeader,
      config.blockHeight,
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

import { BigNumberish } from "ethers";

export type DeployConfig = {
  blockHeader: string;
  blockHeight: BigNumberish;
  cumulativeWork: BigNumberish;
};

export type HistoricalDeployConfig = {
  blockHeader: string;
  blockHeight: BigNumberish;
  cumulativeWork: BigNumberish;
  historyBlocksTreeRoot: string;
  proofBlocksCount: bigint;
};

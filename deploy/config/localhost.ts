import { DeployConfig, HistoricalDeployConfig } from "./types";

export const deployConfig: DeployConfig = {
  blockHeader:
    "0x0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a29ab5f49ffff001d1dac2b7c",
  blockHeight: 0,
  cumulativeWork: 0,
};

export const historicalDeployConfig: HistoricalDeployConfig = {
  blockHeader:
    "0x00a00220e968938e8359a569ee6572db4d84e0b4e082872d83a5010000000000000000009c9671154ec76af4d624d88a1359373f85b76328f4afe78a3e53c7be83bcf21396c3b268912b02178f54c573",
  blockHeight: 912383n,
  cumulativeWork: "0x0000000000000000000000000000000000000000de5f1bd9bd93c239552a585e",
  historyBlocksTreeRoot: "0xd2fde3f66540b59b7b41411d875c0ecee424d70dce15d3685566c34ed66feae3",
  proofBlocksCount: 912384n,
};

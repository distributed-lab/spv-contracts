import { DeployConfig, HistoricalDeployConfig } from "./types";

export const deployConfig: DeployConfig = {
  blockHeader:
    "0x010000006397bb6abd4fc521c0d3f6071b5650389f0b4551bc40b4e6b067306900000000ace470aecda9c8818c8fe57688cd2a772b5a57954a00df0420a7dd546b6d2c576b0e7f49ffff001d33f0192f",
  blockHeight: 2016,
  cumulativeWork: "0x000000000000000000000000000000000000000000000000000007e107e107e1",
};

export const historicalDeployConfig: HistoricalDeployConfig = {
  blockHeader:
    "0x00a00220e968938e8359a569ee6572db4d84e0b4e082872d83a5010000000000000000009c9671154ec76af4d624d88a1359373f85b76328f4afe78a3e53c7be83bcf21396c3b268912b02178f54c573",
  blockHeight: 912383n,
  lastHistoryEpochStartTime: 1755895678n,
  cumulativeWork: "0x0000000000000000000000000000000000000000de5ea5e3576fb66c630a9540",
  historyBlocksTreeRoot: "0xd2fde3f66540b59b7b41411d875c0ecee424d70dce15d3685566c34ed66feae3",
  proofBlocksCount: 912384n,
};

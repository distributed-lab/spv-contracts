import hre from "hardhat";

import { DeployConfig, HistoricalDeployConfig } from "./types";

export async function getConfig(): Promise<DeployConfig> {
  if (hre.network.name == "localhost" || hre.network.name == "hardhat") {
    return (await import("./localhost")).deployConfig;
  }

  if (hre.network.name == "sepolia") {
    return (await import("./sepolia")).deployConfig;
  }

  throw new Error(`Config for network ${hre.network.name} is not specified`);
}

export async function getHistoricalConfig(): Promise<HistoricalDeployConfig> {
  if (hre.network.name == "localhost" || hre.network.name == "hardhat") {
    return (await import("./localhost")).historicalDeployConfig;
  }

  if (hre.network.name == "sepolia") {
    return (await import("./sepolia")).historicalDeployConfig;
  }

  if (hre.network.name == "base") {
    return (await import("./base")).historicalDeployConfig;
  }

  if (hre.network.name == "ethereum") {
    return (await import("./ethereum")).historicalDeployConfig;
  }

  throw new Error(`Config for network ${hre.network.name} is not specified`);
}

import hre from "hardhat";

import { DeployConfig } from "./types";

export async function getConfig(): Promise<DeployConfig> {
  if (hre.network.name == "localhost" || hre.network.name == "hardhat") {
    return (await import("./localhost")).deployConfig;
  }

  if (hre.network.name == "sepolia") {
    return (await import("./sepolia")).deployConfig;
  }

  if (hre.network.name == "base") {
    return (await import("./base")).deployConfig;
  }

  if (hre.network.name == "ethereum") {
    return (await import("./ethereum")).deployConfig;
  }

  throw new Error(`Config for network ${hre.network.name} is not specified`);
}

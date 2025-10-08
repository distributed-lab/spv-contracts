import { expect } from "chai";
import { ethers } from "hardhat";

import { Reverter } from "@test-helpers";

import { SPVToken } from "@ethers-v6";
import { wei } from "@/scripts";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("SPVToken", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;
  let FIRST: SignerWithAddress;
  let SPV_GATEWAY_V2: SignerWithAddress;

  let spvToken: SPVToken;

  before(async () => {
    [OWNER, FIRST, SPV_GATEWAY_V2] = await ethers.getSigners();

    spvToken = await ethers.deployContract("SPVToken", [SPV_GATEWAY_V2]);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("creation", async () => {
    it("should set correct init data", async () => {
      expect(await spvToken.name()).to.equal("SPV Token");
      expect(await spvToken.symbol()).to.equal("SPV");
      expect(await spvToken.spvGatewayV2()).to.equal(SPV_GATEWAY_V2);
    });
  });

  describe("mintTo", async () => {
    it("should correctly mint tokens", async () => {
      const amount = wei(100);

      const tx = await spvToken.connect(SPV_GATEWAY_V2).mintTo(FIRST, amount);

      expect(await spvToken.totalSupply()).to.equal(amount);
      expect(await spvToken.balanceOf(FIRST)).to.equal(amount);

      await expect(tx).to.changeTokenBalance(spvToken, FIRST, amount);
    });

    it("should get exception if the not a SPV Gateway v2 tries to mint tokens", async () => {
      const amount = wei(100);

      await expect(spvToken.connect(OWNER).mintTo(FIRST, amount))
        .to.be.revertedWithCustomError(spvToken, "NotASPVGatewayV2")
        .withArgs(OWNER.address);
    });
  });
});

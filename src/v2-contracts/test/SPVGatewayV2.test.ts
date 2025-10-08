import { expect } from "chai";
import { ethers } from "hardhat";

import {
  buildLevel1MerkleTree,
  buildLevel2MerkleTree,
  getBlockHeaderData,
  getBlockHeaderDataBatch,
  getBlocksDataFilePath,
  getHistoryProofDirPath,
  getHistoryProofFromFile,
  getHistoryProofPublicInputsFromFile,
  Reverter,
} from "@test-helpers";

import { SPVGatewayV2Mock, HistoryProofVerifier, SPVToken } from "@ethers-v6";
import { wei } from "@/scripts";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("SPVGatewayV2", () => {
  const reverter = new Reverter();

  const chunkSize: bigint = 1n;
  const maxFrontierLength: bigint = 25n;

  const startRewardsAmount = wei(50);

  let OWNER: SignerWithAddress;
  let FIRST: SignerWithAddress;

  let spvToken: SPVToken;
  let spvGatewayV2: SPVGatewayV2Mock;

  let historyProofVerifier: HistoryProofVerifier;

  let genesisBlockDataFilePath: string;
  let firstBlocksDataFilePath: string;

  let historyProof2CDirPath: string;
  let historyProof4DDirPath: string;

  before(async () => {
    [OWNER, FIRST] = await ethers.getSigners();

    historyProofVerifier = await ethers.deployContract("HistoryProofVerifier");

    spvGatewayV2 = await ethers.deployContract("SPVGatewayV2Mock", [
      historyProofVerifier,
      chunkSize,
      maxFrontierLength,
    ]);

    spvToken = await ethers.deployContract("SPVToken", [spvGatewayV2]);

    await spvGatewayV2.__SPVGatewayV2_init(spvToken);

    genesisBlockDataFilePath = getBlocksDataFilePath("genesis_block.json");
    firstBlocksDataFilePath = getBlocksDataFilePath("headers_1_30.json");

    historyProof2CDirPath = getHistoryProofDirPath(2n, false);
    historyProof4DDirPath = getHistoryProofDirPath(4n);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("#initialize", () => {
    it("should set correct data after initialization", async () => {
      expect(await spvGatewayV2.proofVerifier()).to.be.eq(historyProofVerifier);
      expect(await spvGatewayV2.chunkSize()).to.be.eq(chunkSize);
      expect(await spvGatewayV2.maxProofFrontierLength()).to.be.eq(maxFrontierLength);

      expect(await spvGatewayV2.getSPVToken()).to.be.eq(spvToken);
      expect(await spvGatewayV2.getSPVTokenRewardsAmount()).to.be.eq(startRewardsAmount);
    });
  });

  describe("#updateMainchain", () => {
    it("should correctly update mainchain with proof for 2 blocks and custom address in comm", async () => {
      const provedBlocksCount = 2n;

      const allBlockHashes = [getBlockHeaderData(genesisBlockDataFilePath, 0).blockHash];
      allBlockHashes.push(
        ...getBlockHeaderDataBatch(firstBlocksDataFilePath, 1, Number(provedBlocksCount) - 1).map((b) => b.blockHash),
      );

      const level1Trees = [];
      for (let i = 0; i < provedBlocksCount; i++) {
        level1Trees.push(buildLevel1MerkleTree([allBlockHashes[i]]));
      }

      const level2Tree = buildLevel2MerkleTree(level1Trees.map((t) => t.root));

      const newHeight = Number(provedBlocksCount - 1n);
      const newHeadBlockHeader = getBlockHeaderData(firstBlocksDataFilePath, newHeight);

      const proof = getHistoryProofFromFile(historyProof2CDirPath);
      const publicInputs = getHistoryProofPublicInputsFromFile(historyProof2CDirPath);

      const tx = await spvGatewayV2.updateMainchain({
        blocksCount: provedBlocksCount,
        proof: proof,
        publicInputs: publicInputs,
      });

      expect(await spvGatewayV2.getMainchainHeight()).to.be.eq(newHeadBlockHeader.height);
      expect(await spvGatewayV2.getMainchainCumulativeWork()).to.be.eq(newHeadBlockHeader.parsedBlockHeader.chainwork);
      expect(await spvGatewayV2.getMainchainHeight()).to.be.eq(newHeadBlockHeader.height);
      expect(await spvGatewayV2.getBlocksTreeRoot()).to.be.eq(level2Tree.root);

      expect(tx)
        .to.emit(spvGatewayV2, "MainchainUpdated")
        .withArgs(newHeight, newHeadBlockHeader.parsedBlockHeader.chainwork, level2Tree.root);
      expect(tx).to.changeTokenBalance(spvToken, OWNER, startRewardsAmount);
    });

    it("should correctly update mainchain with proof for 4 blocks and default address in comm", async () => {
      const provedBlocksCount = 4n;

      const allBlockHashes = [getBlockHeaderData(genesisBlockDataFilePath, 0).blockHash];
      allBlockHashes.push(
        ...getBlockHeaderDataBatch(firstBlocksDataFilePath, 1, Number(provedBlocksCount) - 1).map((b) => b.blockHash),
      );

      const level1Trees = [];
      for (let i = 0; i < provedBlocksCount; i++) {
        level1Trees.push(buildLevel1MerkleTree([allBlockHashes[i]]));
      }

      const level2Tree = buildLevel2MerkleTree(level1Trees.map((t) => t.root));

      const newHeight = Number(provedBlocksCount - 1n);
      const newHeadBlockHeader = getBlockHeaderData(firstBlocksDataFilePath, newHeight);

      const proof = getHistoryProofFromFile(historyProof4DDirPath);
      const publicInputs = getHistoryProofPublicInputsFromFile(historyProof4DDirPath);

      const tx = await spvGatewayV2.connect(FIRST).updateMainchain({
        blocksCount: provedBlocksCount,
        proof: proof,
        publicInputs: publicInputs,
      });

      expect(await spvGatewayV2.getMainchainHeight()).to.be.eq(newHeadBlockHeader.height);
      expect(await spvGatewayV2.getMainchainCumulativeWork()).to.be.eq(newHeadBlockHeader.parsedBlockHeader.chainwork);
      expect(await spvGatewayV2.getMainchainHeight()).to.be.eq(newHeadBlockHeader.height);
      expect(await spvGatewayV2.getBlocksTreeRoot()).to.be.eq(level2Tree.root);

      expect(tx)
        .to.emit(spvGatewayV2, "MainchainUpdated")
        .withArgs(newHeight, newHeadBlockHeader.parsedBlockHeader.chainwork, level2Tree.root);
      expect(tx).to.changeTokenBalance(spvToken, OWNER, startRewardsAmount);
    });

    it("should correctly update SPV token rewards amount", async () => {
      const proofsToUpdate = 5n;
      const addrCommArr = [false, false, true, true, false];

      await spvGatewayV2.setProofsCountToHalving(proofsToUpdate);

      let tx;

      for (let i = 0; i < proofsToUpdate; ++i) {
        const provedBlocksCount = 2n + BigInt(i);
        const currentProofDir = getHistoryProofDirPath(provedBlocksCount, addrCommArr[i]);

        const proof = getHistoryProofFromFile(currentProofDir);
        const publicInputs = getHistoryProofPublicInputsFromFile(currentProofDir);

        expect(await spvGatewayV2.getProofsCountFromHalving()).to.be.eq(i);

        tx = await spvGatewayV2.updateMainchain({
          blocksCount: provedBlocksCount,
          proof: proof,
          publicInputs: publicInputs,
        });

        expect(await spvGatewayV2.getMainchainHeight()).to.be.eq(provedBlocksCount - 1n);
      }

      expect(await spvGatewayV2.getProofsCountFromHalving()).to.be.eq(0);
      expect(await spvGatewayV2.getSPVTokenRewardsAmount()).to.be.eq(startRewardsAmount / 2n);

      expect(tx)
        .to.emit(spvGatewayV2, "SPVTokenRewardsAmountUpdated")
        .withArgs(startRewardsAmount / 2n);
      expect(tx).to.changeTokenBalance(spvToken, OWNER, startRewardsAmount);
    });

    it("should get exception if try to submit proof with lower chainwork", async () => {
      let provedBlocksCount = 4n;

      let proof = getHistoryProofFromFile(historyProof4DDirPath);
      let publicInputs = getHistoryProofPublicInputsFromFile(historyProof4DDirPath);

      const mainchainBlockHeader = getBlockHeaderData(firstBlocksDataFilePath, Number(provedBlocksCount - 1n));

      await spvGatewayV2.connect(FIRST).updateMainchain({
        blocksCount: provedBlocksCount,
        proof: proof,
        publicInputs: publicInputs,
      });

      expect(await spvGatewayV2.getMainchainCumulativeWork()).to.be.eq(
        mainchainBlockHeader.parsedBlockHeader.chainwork,
      );

      provedBlocksCount = 2n;

      proof = getHistoryProofFromFile(historyProof2CDirPath);
      publicInputs = getHistoryProofPublicInputsFromFile(historyProof2CDirPath);

      const newBlockHeader = getBlockHeaderData(firstBlocksDataFilePath, Number(provedBlocksCount - 1n));

      await expect(
        spvGatewayV2.updateMainchain({
          blocksCount: provedBlocksCount,
          proof: proof,
          publicInputs: publicInputs,
        }),
      )
        .to.be.revertedWithCustomError(spvGatewayV2, "NotANewMainchain")
        .withArgs(mainchainBlockHeader.parsedBlockHeader.chainwork, newBlockHeader.parsedBlockHeader.chainwork);
    });

    it("should get exception if try to submit proof with invalid proved blocks count", async () => {
      const provedBlocksCount = 2n;

      const proof = getHistoryProofFromFile(historyProof2CDirPath);
      const publicInputs = getHistoryProofPublicInputsFromFile(historyProof2CDirPath);

      await expect(
        spvGatewayV2.updateMainchain({
          blocksCount: provedBlocksCount + 1n,
          proof: proof,
          publicInputs: publicInputs,
        }),
      ).to.be.revertedWithCustomError(spvGatewayV2, "InvalidProofBlockHeight");
    });

    it("should get exception if try to submit a proof with a non-default address in comm", async () => {
      const provedBlocksCount = 2n;

      const proof = getHistoryProofFromFile(historyProof2CDirPath);
      const publicInputs = getHistoryProofPublicInputsFromFile(historyProof2CDirPath);

      await expect(
        spvGatewayV2.connect(FIRST).updateMainchain({
          blocksCount: provedBlocksCount,
          proof: proof,
          publicInputs: publicInputs,
        }),
      ).to.be.revertedWithCustomError(spvGatewayV2, "InvalidAddressCommitment");
    });
  });
});

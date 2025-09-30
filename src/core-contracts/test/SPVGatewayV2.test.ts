import { expect } from "chai";
import { ethers } from "hardhat";

import {
  buildLevel1MerkleTree,
  buildLevel2MerkleTree,
  DIFFICULTY_ADJUSTMENT_INTERVAL,
  getBlockHeaderData,
  getBlockHeaderDataBatch,
  getBlocksDataFilePath,
  getChunkNumber,
  getHistoryProofDirPath,
  getHistoryProofFromFile,
  getHistoryProofPublicInputsFromFile,
  getLevel1TreeRootsFromFile,
  HISTORY_PROOF_CHUNK_SIZE,
  MerkleRawProofParser,
  Reverter,
} from "@test-helpers";

import { SPVGatewayV2Mock, HistoryProofVerifier, SPVToken } from "@ethers-v6";
import { SimpleMerkleTree } from "@openzeppelin/merkle-tree";
import { wei } from "@/scripts";

describe.only("SPVGatewayV2", () => {
  const reverter = new Reverter();

  const startRewardsAmount = wei(50);

  let spvToken: SPVToken;
  let spvGatewayV2: SPVGatewayV2Mock;

  let historyProofVerifier: HistoryProofVerifier;

  let genesisBlockDataFilePath: string;
  let firstBlocksDataFilePath: string;

  let historyProof20DirPath: string;

  before(async () => {
    historyProofVerifier = await ethers.deployContract("HistoryProofVerifier");
    spvGatewayV2 = await ethers.deployContract("SPVGatewayV2Mock");

    spvToken = await ethers.deployContract("SPVToken", [spvGatewayV2]);

    await spvGatewayV2.__SPVGatewayV2_init(spvToken, historyProofVerifier);

    genesisBlockDataFilePath = getBlocksDataFilePath("genesis_block.json");
    firstBlocksDataFilePath = getBlocksDataFilePath("headers_1_10000.json");

    historyProof20DirPath = getHistoryProofDirPath(20n, 2n);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("#initialize", () => {
    it("should set correct data after initialization", async () => {
      expect(await spvGatewayV2.getSPVToken()).to.be.eq(spvToken);
      expect(await spvGatewayV2.getProofVerifier()).to.be.eq(historyProofVerifier);
      expect(await spvGatewayV2.getCurrentSPVTokensRewardsAmount()).to.be.eq(startRewardsAmount);
    });
  });

  describe("#updateMainchain", () => {
    it("should correctly update mainchain with proof", async () => {
      const provedBlocksCount = 20n;

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

      const proof = getHistoryProofFromFile(historyProof20DirPath);
      const publicInputs = getHistoryProofPublicInputsFromFile(historyProof20DirPath);

      const tx = await spvGatewayV2.updateMainchain({
        proof: proof,
        publicInputs: publicInputs,
      });

      expect(await spvGatewayV2.getMainchainHeight()).to.be.eq(newHeadBlockHeader.height);
      expect(await spvGatewayV2.getMainchainCumulativeWork()).to.be.eq(newHeadBlockHeader.parsedBlockHeader.chainwork);
      expect(await spvGatewayV2.getMainchainHeight()).to.be.eq(newHeadBlockHeader.height);
      expect(await spvGatewayV2.getBlocksTreeRoot()).to.be.eq(level2Tree.root);
    });
  });
});

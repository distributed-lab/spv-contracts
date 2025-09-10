import { expect } from "chai";
import { ethers } from "hardhat";

import {
  buildLevel1MerkleTree,
  buildLevel2MerkleTree,
  getBlockHeaderData,
  getBlockHeaderDataBatch,
  getBlocksDataFilePath,
  getChunkNumber,
  getHistoryProofDirPath,
  getHistoryProofFromFile,
  getHistoryProofPublicInputsFromFile,
  getLevel1TreeRootsFromFile,
  HISTORY_PROOF_CHUNK_SIZE,
  Reverter,
} from "@test-helpers";

import {
  HistoricalSPVGateway,
  HistoryProofVerifier912384,
  HistoryProofVerifier3072,
  HistoryProofVerifier4096,
} from "@ethers-v6";

describe("HistoricalSPVGateway", () => {
  const reverter = new Reverter();

  let historicalSPVGateway: HistoricalSPVGateway;

  let historyProofVerifier912384: HistoryProofVerifier912384;
  let historyProofVerifier3072: HistoryProofVerifier3072;
  let historyProofVerifier4096: HistoryProofVerifier4096;

  let genesisBlockDataFilePath: string;
  let firstBlocksDataFilePath: string;
  let lastBlocksDataFilePath: string;

  let historyProof912384DirPath: string;
  let historyProof3072DirPath: string;
  let historyProof4096DirPath: string;

  before(async () => {
    historicalSPVGateway = await ethers.deployContract("HistoricalSPVGateway");

    historyProofVerifier912384 = await ethers.deployContract("HistoryProofVerifier912384");
    historyProofVerifier3072 = await ethers.deployContract("HistoryProofVerifier3072");
    historyProofVerifier4096 = await ethers.deployContract("HistoryProofVerifier4096");

    genesisBlockDataFilePath = getBlocksDataFilePath("genesis_block.json");
    firstBlocksDataFilePath = getBlocksDataFilePath("headers_1_10000.json");
    lastBlocksDataFilePath = getBlocksDataFilePath("headers_911230_912429.json");

    historyProof3072DirPath = getHistoryProofDirPath(3072n);
    historyProof4096DirPath = getHistoryProofDirPath(4096n);
    historyProof912384DirPath = getHistoryProofDirPath(912384n);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("#initialize", () => {
    it("should correctly initialize with proof from 912383 height", async () => {
      const level1TreeRoots = getLevel1TreeRootsFromFile(historyProof912384DirPath);
      const level2Tree = buildLevel2MerkleTree(level1TreeRoots);

      const proof = getHistoryProofFromFile(historyProof912384DirPath);
      const publicInputs = getHistoryProofPublicInputsFromFile(historyProof912384DirPath);

      const blocksCount = 912384n;
      const initBlockHeader = getBlockHeaderData(lastBlocksDataFilePath, Number(blocksCount) - 1);

      await historicalSPVGateway["__SPVGateway_init(bytes,uint64,uint256,bytes32,(address,bytes32[],bytes))"](
        initBlockHeader.rawHeader,
        initBlockHeader.height,
        initBlockHeader.parsedBlockHeader.chainwork,
        level2Tree.root,
        {
          verifier: await historyProofVerifier912384.getAddress(),
          proof: proof,
          publicInputs: publicInputs,
        },
      );

      const lastEpochCumulativeWork = getBlockHeaderData(lastBlocksDataFilePath, 911231).parsedBlockHeader.chainwork;

      expect(await historicalSPVGateway.getMainchainHead()).to.be.eq(initBlockHeader.blockHash);
      expect(await historicalSPVGateway.getMainchainHeight()).to.be.eq(initBlockHeader.height);
      expect(await historicalSPVGateway.getLastEpochCumulativeWork()).to.be.eq(lastEpochCumulativeWork);

      const nextBlockHeader = getBlockHeaderData(lastBlocksDataFilePath, Number(blocksCount));

      await historicalSPVGateway.addBlockHeader(nextBlockHeader.rawHeader);

      expect(await historicalSPVGateway.getMainchainHead()).to.be.eq(nextBlockHeader.blockHash);
      expect(await historicalSPVGateway.getMainchainHeight()).to.be.eq(nextBlockHeader.height);
    });

    it("should correctly initialize with proof from 3071 height", async () => {
      const blocksCount = 3072n;
      const chunks = getChunkNumber(blocksCount);

      const allBlockHashes = [getBlockHeaderData(genesisBlockDataFilePath, 0).blockHash];
      allBlockHashes.push(
        ...getBlockHeaderDataBatch(firstBlocksDataFilePath, 1, Number(blocksCount) - 1).map((b) => b.blockHash),
      );

      const level1Trees = [];
      for (let i = 0n; i < chunks; i++) {
        const chunkBlockHashes = allBlockHashes.slice(
          Number(i * HISTORY_PROOF_CHUNK_SIZE),
          Number((i + 1n) * HISTORY_PROOF_CHUNK_SIZE),
        );
        level1Trees.push(buildLevel1MerkleTree(chunkBlockHashes));
      }

      const level2Tree = buildLevel2MerkleTree(level1Trees.map((t) => t.root));

      const initBlockHeader = getBlockHeaderData(firstBlocksDataFilePath, Number(blocksCount) - 1);

      const proof = getHistoryProofFromFile(historyProof3072DirPath);
      const publicInputs = getHistoryProofPublicInputsFromFile(historyProof3072DirPath);

      await historicalSPVGateway["__SPVGateway_init(bytes,uint64,uint256,bytes32,(address,bytes32[],bytes))"](
        initBlockHeader.rawHeader,
        initBlockHeader.height,
        initBlockHeader.parsedBlockHeader.chainwork,
        level2Tree.root,
        {
          verifier: await historyProofVerifier3072.getAddress(),
          proof: proof,
          publicInputs: publicInputs,
        },
      );

      const lastEpochCumulativeWork = getBlockHeaderData(firstBlocksDataFilePath, 2015).parsedBlockHeader.chainwork;

      expect(await historicalSPVGateway.getMainchainHead()).to.be.eq(initBlockHeader.blockHash);
      expect(await historicalSPVGateway.getMainchainHeight()).to.be.eq(initBlockHeader.height);
      expect(await historicalSPVGateway.getLastEpochCumulativeWork()).to.be.eq(lastEpochCumulativeWork);
    });

    it("should correctly initialize with proof from 4095 height", async () => {
      const blocksCount = 4096n;
      const chunks = getChunkNumber(blocksCount);

      const allBlockHashes = [getBlockHeaderData(genesisBlockDataFilePath, 0).blockHash];
      allBlockHashes.push(
        ...getBlockHeaderDataBatch(firstBlocksDataFilePath, 1, Number(blocksCount) - 1).map((b) => b.blockHash),
      );

      const level1Trees = [];
      for (let i = 0n; i < chunks; i++) {
        const chunkBlockHashes = allBlockHashes.slice(
          Number(i * HISTORY_PROOF_CHUNK_SIZE),
          Number((i + 1n) * HISTORY_PROOF_CHUNK_SIZE),
        );
        level1Trees.push(buildLevel1MerkleTree(chunkBlockHashes));
      }

      const level2Tree = buildLevel2MerkleTree(level1Trees.map((t) => t.root));

      const initBlockHeader = getBlockHeaderData(firstBlocksDataFilePath, Number(blocksCount) - 1);

      const proof = getHistoryProofFromFile(historyProof4096DirPath);
      const publicInputs = getHistoryProofPublicInputsFromFile(historyProof4096DirPath);

      await historicalSPVGateway["__SPVGateway_init(bytes,uint64,uint256,bytes32,(address,bytes32[],bytes))"](
        initBlockHeader.rawHeader,
        initBlockHeader.height,
        initBlockHeader.parsedBlockHeader.chainwork,
        level2Tree.root,
        {
          verifier: await historyProofVerifier3072.getAddress(),
          proof: proof,
          publicInputs: publicInputs,
        },
      );

      const lastEpochCumulativeWork = getBlockHeaderData(firstBlocksDataFilePath, 4031).parsedBlockHeader.chainwork;

      expect(await historicalSPVGateway.getMainchainHead()).to.be.eq(initBlockHeader.blockHash);
      expect(await historicalSPVGateway.getMainchainHeight()).to.be.eq(initBlockHeader.height);
      expect(await historicalSPVGateway.getLastEpochCumulativeWork()).to.be.eq(lastEpochCumulativeWork);
    });
  });
});

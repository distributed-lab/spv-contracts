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
  MerkleRawProofParser,
  Reverter,
} from "@test-helpers";

import { SPVGatewayV2Mock, HistoryProofVerifier } from "@ethers-v6";
import { wei } from "@/scripts";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("SPVGatewayV2", () => {
  const reverter = new Reverter();

  const chunkSize: bigint = 1n;
  const maxFrontierLength: bigint = 25n;

  const startRewardsAmount = wei(50);

  let OWNER: SignerWithAddress;
  let FIRST: SignerWithAddress;

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

    await spvGatewayV2.__SPVGatewayV2_init();

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

      expect(await spvGatewayV2.name()).to.be.eq("SPV Token");
      expect(await spvGatewayV2.symbol()).to.be.eq("SPV");
      expect(await spvGatewayV2.getSPVTokenRewardsAmount()).to.be.eq(startRewardsAmount);
    });
  });

  describe("#updateMainchain", () => {
    it("should correctly update mainchain several times", async () => {
      const proofsToUpdate = 10n;
      const addrCommArr = [false, false, true, true, false, false, true, true, false, false];

      const allBlockHashes = [getBlockHeaderData(genesisBlockDataFilePath, 0).blockHash];
      allBlockHashes.push(
        ...getBlockHeaderDataBatch(firstBlocksDataFilePath, 1, Number(proofsToUpdate)).map((b) => b.blockHash),
      );

      for (let i = 0; i < proofsToUpdate; ++i) {
        const provedBlocksCount = 2n + BigInt(i);
        const currentProofDir = getHistoryProofDirPath(provedBlocksCount, addrCommArr[i]);

        const level1Trees = [];
        for (let i = 0; i < provedBlocksCount; i++) {
          level1Trees.push(buildLevel1MerkleTree([allBlockHashes[i]]));
        }

        const level2Tree = buildLevel2MerkleTree(level1Trees.map((t) => t.root));

        const proof = getHistoryProofFromFile(currentProofDir);
        const publicInputs = getHistoryProofPublicInputsFromFile(currentProofDir);

        expect(await spvGatewayV2.getProofsCountFromHalving()).to.be.eq(i);

        await spvGatewayV2.updateMainchain({
          blocksCount: provedBlocksCount,
          proof: proof,
          publicInputs: publicInputs,
        });

        expect(await spvGatewayV2.getMainchainHeight()).to.be.eq(provedBlocksCount - 1n);
        expect(await spvGatewayV2.getBlocksTreeRoot()).to.be.eq(level2Tree.root);
      }
    });

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
      expect(tx).to.changeTokenBalance(spvGatewayV2, OWNER, startRewardsAmount);
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
      expect(tx).to.changeTokenBalance(spvGatewayV2, OWNER, startRewardsAmount);
    });

    it("should correctly update mainchain 50k, 70k and 100k blocks height", async () => {
      const headersFilePath = getBlocksDataFilePath("headers_10k_50k_70k.json");
      const blockTreeRoots = [
        "0x8ff41848eace5eab2b8e471b6c4d18c119eef50aeeb7dfa2625c070be51c4398",
        "0xdae36e8bc2e5d9d01a5a96c204e200e74715a46a5802dca09f95e71215b29071",
        "0x840c9b764da7480d8961f33ebc5894eaf2513fd51530995423ab59eea78b402d",
      ];

      const startHeight = 10000;
      const blockHeaders = getBlockHeaderDataBatch(headersFilePath, startHeight, 3);

      let provedBlocksCount = 10001n;
      let proofDirPath = getHistoryProofDirPath(provedBlocksCount, true);
      let proof = getHistoryProofFromFile(proofDirPath);
      let publicInputs = getHistoryProofPublicInputsFromFile(proofDirPath);

      let tx = await spvGatewayV2.connect(FIRST).updateMainchain({
        blocksCount: provedBlocksCount,
        proof: proof,
        publicInputs: publicInputs,
      });

      expect(await spvGatewayV2.getMainchainHeight()).to.be.eq(blockHeaders[0].height);
      expect(await spvGatewayV2.getMainchainCumulativeWork()).to.be.eq(blockHeaders[0].parsedBlockHeader.chainwork);
      expect(await spvGatewayV2.getBlocksTreeRoot()).to.be.eq(blockTreeRoots[0]);

      expect(tx).to.emit(spvGatewayV2, "MainchainUpdated");
      expect(tx).to.changeTokenBalance(spvGatewayV2, OWNER, startRewardsAmount);

      provedBlocksCount = 50001n;
      proofDirPath = getHistoryProofDirPath(provedBlocksCount, true);
      proof = getHistoryProofFromFile(proofDirPath);
      publicInputs = getHistoryProofPublicInputsFromFile(proofDirPath);

      tx = await spvGatewayV2.connect(FIRST).updateMainchain({
        blocksCount: provedBlocksCount,
        proof: proof,
        publicInputs: publicInputs,
      });

      expect(await spvGatewayV2.getMainchainHeight()).to.be.eq(blockHeaders[1].height);
      expect(await spvGatewayV2.getMainchainCumulativeWork()).to.be.eq(blockHeaders[1].parsedBlockHeader.chainwork);
      expect(await spvGatewayV2.getBlocksTreeRoot()).to.be.eq(blockTreeRoots[1]);

      expect(tx).to.emit(spvGatewayV2, "MainchainUpdated");
      expect(tx).to.changeTokenBalance(spvGatewayV2, OWNER, startRewardsAmount);

      provedBlocksCount = 70001n;
      proofDirPath = getHistoryProofDirPath(provedBlocksCount, true);
      proof = getHistoryProofFromFile(proofDirPath);
      publicInputs = getHistoryProofPublicInputsFromFile(proofDirPath);

      tx = await spvGatewayV2.connect(FIRST).updateMainchain({
        blocksCount: provedBlocksCount,
        proof: proof,
        publicInputs: publicInputs,
      });

      expect(await spvGatewayV2.getMainchainHeight()).to.be.eq(blockHeaders[2].height);
      expect(await spvGatewayV2.getMainchainCumulativeWork()).to.be.eq(blockHeaders[2].parsedBlockHeader.chainwork);
      expect(await spvGatewayV2.getBlocksTreeRoot()).to.be.eq(blockTreeRoots[2]);

      expect(tx).to.emit(spvGatewayV2, "MainchainUpdated");
      expect(tx).to.changeTokenBalance(spvGatewayV2, OWNER, startRewardsAmount);
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
      expect(tx).to.changeTokenBalance(spvGatewayV2, OWNER, startRewardsAmount);
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

  describe("checkBlockInclusion", () => {
    beforeEach(async () => {
      const provedBlocksCount = 10n;

      const historyProof10CDirPath = getHistoryProofDirPath(provedBlocksCount, false);

      const proof = getHistoryProofFromFile(historyProof10CDirPath);
      const publicInputs = getHistoryProofPublicInputsFromFile(historyProof10CDirPath);

      await spvGatewayV2.updateMainchain({
        blocksCount: provedBlocksCount,
        proof: proof,
        publicInputs: publicInputs,
      });

      expect(await spvGatewayV2.getMainchainHeight()).to.be.eq(provedBlocksCount - 1n);
    });

    it("should correctly check block inclusion for 4 height", async () => {
      const blockHeight = 4;
      const blockHeader = getBlockHeaderData(firstBlocksDataFilePath, blockHeight);

      const level2MerklePath = [
        "0xe32e10bf9f9f1bf1b57a958c51ed7a2a519eb8afcaf8530b24b414c64967819d",
        "0x09dbdab95166b8d2e4ba0bb5939e716d62b1d1fdbccbc1cab85d75d90278702b",
        "0xdc50af91c44dadd3f98cd581d18cb0e323e1643ea1bc43f76d2eb78713cd6006",
        "0xcb73f4e3f81ce9fca9372b78e37d1be5c4cc7c974e261d7d0e3e444bc0daa479",
      ];

      expect(
        await spvGatewayV2.checkBlockInclusion({
          blockHash: blockHeader.blockHash,
          blockHeight: blockHeight,
          level1MerkleProof: [],
          level2MerkleProof: level2MerklePath,
        }),
      ).to.be.true;
    });

    it("should correctly check block inclusion for 7 height", async () => {
      const blockHeight = 7;
      const blockHeader = getBlockHeaderData(firstBlocksDataFilePath, blockHeight);

      const level2MerklePath = [
        "0xe32e10bf9f9f1bf1b57a958c51ed7a2a519eb8afcaf8530b24b414c64967819d",
        "0x09dbdab95166b8d2e4ba0bb5939e716d62b1d1fdbccbc1cab85d75d90278702b",
        "0xa3cf239c53c927591a986ecb84e5a5e963525b90ccbf001ca2e51e43385dea5c",
        "0xa6d7febafe0a9305b887d55a0e32b176fb5e9f7b1ce56275d11ef1e0816e3087",
      ];

      expect(
        await spvGatewayV2.checkBlockInclusion({
          blockHash: blockHeader.blockHash,
          blockHeight: blockHeight,
          level1MerkleProof: [],
          level2MerkleProof: level2MerklePath,
        }),
      ).to.be.true;
    });

    it("should correctly check block inclusion for 9 height", async () => {
      const blockHeight = 9;
      const blockHeader = getBlockHeaderData(firstBlocksDataFilePath, blockHeight);

      const level2MerklePath = [
        "0x931dfcfef71b66135b01f4d9b36d6b2db7b998819505dbe2ba4cd5489961c048",
        "0x0b0d6f5969c4d1ff7962d0f7b1695aabfd42696d4cd805f4c7c0b4cf717bb5dd",
        "0x1e22963165139a0f70170bcf62cdd6063064d3cea3e141bd593a56d06a81c7ec",
        "0x968c8026f3325338cec051d618090e95f8121b3c4c4b44664c2d379b9e3a4611",
      ];

      expect(
        await spvGatewayV2.checkBlockInclusion({
          blockHash: blockHeader.blockHash,
          blockHeight: blockHeight,
          level1MerkleProof: [],
          level2MerkleProof: level2MerklePath,
        }),
      ).to.be.true;
    });
  });

  describe("checkTxInclusion", () => {
    beforeEach(async () => {
      const provedBlocksCount = 10n;

      const historyProof10CDirPath = getHistoryProofDirPath(provedBlocksCount, false);

      const proof = getHistoryProofFromFile(historyProof10CDirPath);
      const publicInputs = getHistoryProofPublicInputsFromFile(historyProof10CDirPath);

      await spvGatewayV2.updateMainchain({
        blocksCount: provedBlocksCount,
        proof: proof,
        publicInputs: publicInputs,
      });

      expect(await spvGatewayV2.getMainchainHeight()).to.be.eq(provedBlocksCount - 1n);
    });

    it("should correctly check tx inclusion for 4 height", async () => {
      const blockHeight = 4;
      const blockHeader = getBlockHeaderData(firstBlocksDataFilePath, blockHeight);

      const level2MerklePath = [
        "0xe32e10bf9f9f1bf1b57a958c51ed7a2a519eb8afcaf8530b24b414c64967819d",
        "0x09dbdab95166b8d2e4ba0bb5939e716d62b1d1fdbccbc1cab85d75d90278702b",
        "0xdc50af91c44dadd3f98cd581d18cb0e323e1643ea1bc43f76d2eb78713cd6006",
        "0xcb73f4e3f81ce9fca9372b78e37d1be5c4cc7c974e261d7d0e3e444bc0daa479",
      ];

      const txid = "df2b060fa2e5e9c8ed5eaf6a45c13753ec8c63282b2688322eba40cd98ea067a";
      const rawTxProof =
        "010000004944469562ae1c2c74d9a535e00b6f3e40ffbad4f2fda3895501b582000000007a06ea98cd40ba2e3288262b28638cec5337c1456aaf5eedc8e9e5a20f062bdf8cc16649ffff001d2bfee0a901000000017a06ea98cd40ba2e3288262b28638cec5337c1456aaf5eedc8e9e5a20f062bdf0101";

      const parser = new MerkleRawProofParser(txid, rawTxProof);

      expect(
        await spvGatewayV2.checkTxInclusion(
          parser.getSiblings(),
          blockHeader.rawHeader,
          parser.getTxidReversed(),
          parser.getTxIndex(),
          {
            blockHash: blockHeader.blockHash,
            blockHeight: blockHeader.height,
            level1MerkleProof: [],
            level2MerkleProof: level2MerklePath,
          },
        ),
      ).to.be.true;
    });

    it("should correctly check tx inclusion for 7 height", async () => {
      const blockHeight = 7;
      const blockHeader = getBlockHeaderData(firstBlocksDataFilePath, blockHeight);

      const level2MerklePath = [
        "0xe32e10bf9f9f1bf1b57a958c51ed7a2a519eb8afcaf8530b24b414c64967819d",
        "0x09dbdab95166b8d2e4ba0bb5939e716d62b1d1fdbccbc1cab85d75d90278702b",
        "0xa3cf239c53c927591a986ecb84e5a5e963525b90ccbf001ca2e51e43385dea5c",
        "0xa6d7febafe0a9305b887d55a0e32b176fb5e9f7b1ce56275d11ef1e0816e3087",
      ];

      const txid = "8aa673bc752f2851fd645d6a0a92917e967083007d9c1684f9423b100540673f";
      const rawTxProof =
        "010000008d778fdc15a2d3fb76b7122a3b5582bea4f21f5a0c693537e7a03130000000003f674005103b42f984169c7d008370967e91920a6a5d64fd51282f75bc73a68af1c66649ffff001d39a59c8601000000013f674005103b42f984169c7d008370967e91920a6a5d64fd51282f75bc73a68a0101";

      const parser = new MerkleRawProofParser(txid, rawTxProof);

      expect(
        await spvGatewayV2.checkTxInclusion(
          parser.getSiblings(),
          blockHeader.rawHeader,
          parser.getTxidReversed(),
          parser.getTxIndex(),
          {
            blockHash: blockHeader.blockHash,
            blockHeight: blockHeader.height,
            level1MerkleProof: [],
            level2MerkleProof: level2MerklePath,
          },
        ),
      ).to.be.true;
    });
  });
});

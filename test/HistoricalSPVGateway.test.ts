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
  MerkleRawProofParser,
  Reverter,
} from "@test-helpers";

import {
  HistoricalSPVGateway,
  HistoryProofVerifier912384,
  HistoryProofVerifier3072,
  HistoryProofVerifier4096,
} from "@ethers-v6";
import { SimpleMerkleTree } from "@openzeppelin/merkle-tree";

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

  async function initFromProof(
    blocksCount: bigint,
    historyProofDir: string,
    verifierAddress: string,
  ): Promise<{
    level1Trees: SimpleMerkleTree[];
    level2Tree: SimpleMerkleTree;
  }> {
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

    const proof = getHistoryProofFromFile(historyProofDir);
    const publicInputs = getHistoryProofPublicInputsFromFile(historyProofDir);

    await historicalSPVGateway.__HistoricalSPVGateway_init(
      initBlockHeader.rawHeader,
      initBlockHeader.height,
      initBlockHeader.parsedBlockHeader.chainwork,
      level2Tree.root,
      {
        verifier: verifierAddress,
        proof: proof,
        publicInputs: publicInputs,
      },
    );

    return {
      level1Trees,
      level2Tree,
    };
  }

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

      await historicalSPVGateway.__HistoricalSPVGateway_init(
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

      await initFromProof(blocksCount, historyProof3072DirPath, await historyProofVerifier3072.getAddress());

      const initBlockHeader = getBlockHeaderData(firstBlocksDataFilePath, Number(blocksCount) - 1);

      const lastEpochCumulativeWork = getBlockHeaderData(firstBlocksDataFilePath, 2015).parsedBlockHeader.chainwork;

      expect(await historicalSPVGateway.getMainchainHead()).to.be.eq(initBlockHeader.blockHash);
      expect(await historicalSPVGateway.getMainchainHeight()).to.be.eq(initBlockHeader.height);
      expect(await historicalSPVGateway.getLastEpochCumulativeWork()).to.be.eq(lastEpochCumulativeWork);
    });

    it("should correctly initialize with proof from 4095 height", async () => {
      const blocksCount = 4096n;

      await initFromProof(blocksCount, historyProof4096DirPath, await historyProofVerifier3072.getAddress());

      const initBlockHeader = getBlockHeaderData(firstBlocksDataFilePath, Number(blocksCount) - 1);

      const lastEpochCumulativeWork = getBlockHeaderData(firstBlocksDataFilePath, 4031).parsedBlockHeader.chainwork;

      expect(await historicalSPVGateway.getMainchainHead()).to.be.eq(initBlockHeader.blockHash);
      expect(await historicalSPVGateway.getMainchainHeight()).to.be.eq(initBlockHeader.height);
      expect(await historicalSPVGateway.getLastEpochCumulativeWork()).to.be.eq(lastEpochCumulativeWork);
    });
  });

  describe("checkHistoryBlockInclusion", () => {
    it("should correctly check block inclusion for 1074 height with 3072 blocks proof", async () => {
      await initFromProof(3072n, historyProof3072DirPath, await historyProofVerifier3072.getAddress());

      const blockHeight = 1074;
      const blockHeader = getBlockHeaderData(firstBlocksDataFilePath, blockHeight);

      const level1MerklePath = [
        "0x6d897dcd172d76f6ec458141aac591591df45800ec44fc2022196f03d570f7cf",
        "0x440e43bf1bae9b8be9d0a8b6db203bbd22193d46ca809191934c8423f24770a7",
        "0xbb88017ae3fd39683af847ec0d682c904e95c79254c40fe452cf4b18ec3d3cdf",
        "0xc16932cce8616466c5dd09671d7f4946cb59f5d1a058c05a4f3ed68eefee7f07",
        "0x7afbe82e69d42164008cdd91385ba5115b985c8dee66451f15b29d2d830b1c4c",
        "0xc250e6dc95212834a5795167311493834dc6122a737026a033a2f9fd47e96c41",
        "0x87d781802967795d9b7d56742ba192831431292b944a1dba95fbe73ad1cc4623",
        "0x48c22e757997e2008da6077b94fd2f14e1c3abd893c1db442dbcb17ab2ba48d0",
        "0x8b137e37a030d3e95c17a4581c390c675ea5fd3d6ee42245d1f6a1a5a605a3e2",
        "0xf2bfa268443ee67b5b59af68f00eb64e12073119b17d557b806f372e6687f1f0",
      ];
      const level2MerklePath = [
        "0xd62bd8d77e128b4787f9341a2dc6fe48d910011431d6cf7b65a018b513c0043a",
        "0x8c0b9d816b7caece90e5cc69bdc97d759125b35525e025fed564e6073bf39cb3",
      ];

      expect(
        await historicalSPVGateway.checkHistoryBlockInclusion({
          blockHash: blockHeader.blockHash,
          blockHeight: blockHeight,
          level1MerkleProof: level1MerklePath.reverse(),
          level2MerkleProof: level2MerklePath.reverse(),
        }),
      ).to.be.true;
    });

    it("should correctly check block inclusion for 4044 height with 4096 blocks proof", async () => {
      await initFromProof(4096n, historyProof4096DirPath, await historyProofVerifier3072.getAddress());

      const blockHeight = 4044;
      const blockHeader = getBlockHeaderData(firstBlocksDataFilePath, blockHeight);

      const level1MerklePath = [
        "0xab45a2281c33f626e16386be8f243c73eb3c743dbe334131ef0bd81700be622e",
        "0x70859c9e6e3255cefad9d75bd634d32362e450434d88bbb5005ba9b3000ea155",
        "0x6a0b70f273a2b1667da318e472da43ebb4b8ee7536ab4bb4d9c0565244342d63",
        "0x8d8553c95b4cf4766ceac965f1a95af74365850ef4a0f81db020f962c7c4b42e",
        "0x31ddc987a168ac6cda363888ce4ffd6bf23009e68ea797fc4bac88abf81da2a6",
        "0xf06ea238186cb0521eb73c63bb1e0286fcb3039a8a69beeb4f759372c972dcda",
        "0xfa5c95b6ac238131910da29cd054b75e5b66ea934fc98e022e14bd9ad371c9dc",
        "0x5c109c0a7bf807ef3c1fb1b9b81b59666fc0ea4127adc28fb6f38aad113e714c",
        "0xb06f13817ba18679f0bff446b92f3f62d6cbbadf119b58bac3becca750f25260",
        "0xb5b9e17a2822c0d6bd2bc822049ce265c4fe0b9ffdd82fb635c91e9ec7163539",
      ];
      const level2MerklePath = [
        "0x37087424d5054bace152ad3274751ca61ae16c2feb476d34a4640cff08c6ff61",
        "0xa56acd861b9edbc4112e7c6a74aa23ad9b4a2b7378e23c7823497d19e18d7abf",
      ];

      expect(
        await historicalSPVGateway.checkHistoryBlockInclusion({
          blockHash: blockHeader.blockHash,
          blockHeight: blockHeight,
          level1MerkleProof: level1MerklePath.reverse(),
          level2MerkleProof: level2MerklePath.reverse(),
        }),
      ).to.be.true;
    });

    it("should correctly check block inclusion for 912380 height with 912384 blocks proof", async () => {
      const level1TreeRoots = getLevel1TreeRootsFromFile(historyProof912384DirPath);
      const level2Tree = buildLevel2MerkleTree(level1TreeRoots);

      const proof = getHistoryProofFromFile(historyProof912384DirPath);
      const publicInputs = getHistoryProofPublicInputsFromFile(historyProof912384DirPath);

      const blocksCount = 912384n;
      const initBlockHeader = getBlockHeaderData(lastBlocksDataFilePath, Number(blocksCount) - 1);

      await historicalSPVGateway.__HistoricalSPVGateway_init(
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

      const blockHeight = 912380;
      const blockHeader = getBlockHeaderData(lastBlocksDataFilePath, blockHeight);

      const level1MerklePath = [
        "0x32d18bb3020aa5196ffe6e3863a2485a5c6371d7f8ecc027c6a68129da9fec8b",
        "0xa4d1a70d60cd511ef4513fc62915dd6b4fcdeb2db5ce9dd2241929a4aa35b561",
        "0x41703abd3877cf2eb9a173f02676e00500bbb3a20cddd931f33da82ad814c580",
        "0xa520203fd3c1e0266673d5b0fdf2f596438ae78d4188c30593bfc9861678f097",
        "0x4157359a681296e7a10aa8846ee598970f015a8661c0785a3925baab96647409",
        "0x2bef473c3499978c4e4f4b2fdddeafdb94c4f900a26e53228be41f790d8d1a6a",
        "0x91854d696c8bede34cb27a26c63305b16eb8e6ca5ad12d0fe8485e514769e25e",
        "0xb1dba4db581ca2dc78cafe46c4bda789644d503687d79391b373c3910438c833",
        "0x79b42a1208d17028a48ead5aa78cf08e10456f382eb25bb7b063af312a0c3e0d",
        "0x032428794d34eeb08406d9760510d5541c76b1077e6ec04320ef041e61b95934",
      ];
      const level2MerklePath = [
        "0xb4f860e45b275305a85f465e9052716a70759ed9cff0d70adcfd7befa77e89b1",
        "0xaf055aa158cab621a3aa049028cca92789c06b76ca97e43b839f3a26001bcfe8",
        "0x0b0d6f5969c4d1ff7962d0f7b1695aabfd42696d4cd805f4c7c0b4cf717bb5dd",
        "0x48cb9d915f8a649aa1f54fc6b45e3cc7a4eafc331b929b996bc95da919c17649",
        "0x0d7f394ac6f78ccf904f80ffd5b31dbe4cb30f3795a96f80fb1c068805f3f54b",
        "0xd1907bd951a9e454ff9b27e8654382f1a54036346c60a8b98bd25559eab65d25",
        "0x9c692941785b97cda07bd03794f7aebda8eab3586241189253c9ecfbe7da6692",
        "0x0112e0783ad2697a8b444459115780266be0eb527c5b5b1a6b50afc490fa2001",
        "0x6e8e9a829b7c5bc2e5b9e6afc0ee59bbc3d16dbcf82eff2d5384e403c5989497",
        "0x11048b3c45758fe8904af7cee702fb3493f27a983ed108b4c93e0324d9e8e5bf",
      ];

      expect(
        await historicalSPVGateway.checkHistoryBlockInclusion({
          blockHash: blockHeader.blockHash,
          blockHeight: blockHeight,
          level1MerkleProof: level1MerklePath.reverse(),
          level2MerkleProof: level2MerklePath.reverse(),
        }),
      ).to.be.true;
    });
  });

  describe("checkHistoryTxInclusion", () => {
    it("should correctly check tx inclusion for 1074 height with 3072 blocks proof", async () => {
      await initFromProof(3072n, historyProof3072DirPath, await historyProofVerifier3072.getAddress());

      const blockHeight = 1074;
      const blockHeader = getBlockHeaderData(firstBlocksDataFilePath, blockHeight);

      const level1MerklePath = [
        "0x6d897dcd172d76f6ec458141aac591591df45800ec44fc2022196f03d570f7cf",
        "0x440e43bf1bae9b8be9d0a8b6db203bbd22193d46ca809191934c8423f24770a7",
        "0xbb88017ae3fd39683af847ec0d682c904e95c79254c40fe452cf4b18ec3d3cdf",
        "0xc16932cce8616466c5dd09671d7f4946cb59f5d1a058c05a4f3ed68eefee7f07",
        "0x7afbe82e69d42164008cdd91385ba5115b985c8dee66451f15b29d2d830b1c4c",
        "0xc250e6dc95212834a5795167311493834dc6122a737026a033a2f9fd47e96c41",
        "0x87d781802967795d9b7d56742ba192831431292b944a1dba95fbe73ad1cc4623",
        "0x48c22e757997e2008da6077b94fd2f14e1c3abd893c1db442dbcb17ab2ba48d0",
        "0x8b137e37a030d3e95c17a4581c390c675ea5fd3d6ee42245d1f6a1a5a605a3e2",
        "0xf2bfa268443ee67b5b59af68f00eb64e12073119b17d557b806f372e6687f1f0",
      ];
      const level2MerklePath = [
        "0xd62bd8d77e128b4787f9341a2dc6fe48d910011431d6cf7b65a018b513c0043a",
        "0x8c0b9d816b7caece90e5cc69bdc97d759125b35525e025fed564e6073bf39cb3",
      ];

      const txid = "ebc6ab4245fea8bf211fc12b6b71037230dc7fd2a9d0d6b98fbc2c38dc9902e8";
      const rawTxProof =
        "010000009231f9ad5e5406e3c511307feb888a70760fdb91a9c2571416ee927900000000e80299dc382cbc8fb9d6d0a9d27fdc307203716b2bc11f21bfa8fe4542abc6ebf5007549ffff001d2452869c0100000001e80299dc382cbc8fb9d6d0a9d27fdc307203716b2bc11f21bfa8fe4542abc6eb0101";

      const parser = new MerkleRawProofParser(txid, rawTxProof);

      expect(
        await historicalSPVGateway.checkHistoryTxInclusion(
          parser.getSiblings(),
          blockHeader.rawHeader,
          parser.getTxidReversed(),
          parser.getTxIndex(),
          {
            blockHash: blockHeader.blockHash,
            blockHeight: blockHeader.height,
            level1MerkleProof: level1MerklePath.reverse(),
            level2MerkleProof: level2MerklePath.reverse(),
          },
        ),
      ).to.be.true;
    });

    it("should correctly check tx inclusion for 4044 height with 4096 blocks proof", async () => {
      await initFromProof(4096n, historyProof4096DirPath, await historyProofVerifier3072.getAddress());

      const blockHeight = 4044;
      const blockHeader = getBlockHeaderData(firstBlocksDataFilePath, blockHeight);

      const level1MerklePath = [
        "0xab45a2281c33f626e16386be8f243c73eb3c743dbe334131ef0bd81700be622e",
        "0x70859c9e6e3255cefad9d75bd634d32362e450434d88bbb5005ba9b3000ea155",
        "0x6a0b70f273a2b1667da318e472da43ebb4b8ee7536ab4bb4d9c0565244342d63",
        "0x8d8553c95b4cf4766ceac965f1a95af74365850ef4a0f81db020f962c7c4b42e",
        "0x31ddc987a168ac6cda363888ce4ffd6bf23009e68ea797fc4bac88abf81da2a6",
        "0xf06ea238186cb0521eb73c63bb1e0286fcb3039a8a69beeb4f759372c972dcda",
        "0xfa5c95b6ac238131910da29cd054b75e5b66ea934fc98e022e14bd9ad371c9dc",
        "0x5c109c0a7bf807ef3c1fb1b9b81b59666fc0ea4127adc28fb6f38aad113e714c",
        "0xb06f13817ba18679f0bff446b92f3f62d6cbbadf119b58bac3becca750f25260",
        "0xb5b9e17a2822c0d6bd2bc822049ce265c4fe0b9ffdd82fb635c91e9ec7163539",
      ];
      const level2MerklePath = [
        "0x37087424d5054bace152ad3274751ca61ae16c2feb476d34a4640cff08c6ff61",
        "0xa56acd861b9edbc4112e7c6a74aa23ad9b4a2b7378e23c7823497d19e18d7abf",
      ];

      const txid = "f863bff5b8c36f7d22c500a91cb4e420b000215a1bee407a92f817db84d21114";
      const rawTxProof =
        "01000000b358ab90abc0e3ed9d7389e89615819449475050a321b910419bb2dd000000001411d284db17f8927a40ee1b5a2100b020e4b41ca900c5227d6fc3b8f5bf63f877919449ffff001d2dcd36dd01000000011411d284db17f8927a40ee1b5a2100b020e4b41ca900c5227d6fc3b8f5bf63f80101";

      const parser = new MerkleRawProofParser(txid, rawTxProof);

      expect(
        await historicalSPVGateway.checkHistoryTxInclusion(
          parser.getSiblings(),
          blockHeader.rawHeader,
          parser.getTxidReversed(),
          parser.getTxIndex(),
          {
            blockHash: blockHeader.blockHash,
            blockHeight: blockHeader.height,
            level1MerkleProof: level1MerklePath.reverse(),
            level2MerkleProof: level2MerklePath.reverse(),
          },
        ),
      ).to.be.true;
    });

    it("should correctly check tx inclusion for 912380 height with 912384 blocks proof", async () => {
      const level1TreeRoots = getLevel1TreeRootsFromFile(historyProof912384DirPath);
      const level2Tree = buildLevel2MerkleTree(level1TreeRoots);

      const proof = getHistoryProofFromFile(historyProof912384DirPath);
      const publicInputs = getHistoryProofPublicInputsFromFile(historyProof912384DirPath);

      const blocksCount = 912384n;
      const initBlockHeader = getBlockHeaderData(lastBlocksDataFilePath, Number(blocksCount) - 1);

      await historicalSPVGateway.__HistoricalSPVGateway_init(
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

      const blockHeight = 912380;
      const blockHeader = getBlockHeaderData(lastBlocksDataFilePath, blockHeight);

      const level1MerklePath = [
        "0x32d18bb3020aa5196ffe6e3863a2485a5c6371d7f8ecc027c6a68129da9fec8b",
        "0xa4d1a70d60cd511ef4513fc62915dd6b4fcdeb2db5ce9dd2241929a4aa35b561",
        "0x41703abd3877cf2eb9a173f02676e00500bbb3a20cddd931f33da82ad814c580",
        "0xa520203fd3c1e0266673d5b0fdf2f596438ae78d4188c30593bfc9861678f097",
        "0x4157359a681296e7a10aa8846ee598970f015a8661c0785a3925baab96647409",
        "0x2bef473c3499978c4e4f4b2fdddeafdb94c4f900a26e53228be41f790d8d1a6a",
        "0x91854d696c8bede34cb27a26c63305b16eb8e6ca5ad12d0fe8485e514769e25e",
        "0xb1dba4db581ca2dc78cafe46c4bda789644d503687d79391b373c3910438c833",
        "0x79b42a1208d17028a48ead5aa78cf08e10456f382eb25bb7b063af312a0c3e0d",
        "0x032428794d34eeb08406d9760510d5541c76b1077e6ec04320ef041e61b95934",
      ];
      const level2MerklePath = [
        "0xb4f860e45b275305a85f465e9052716a70759ed9cff0d70adcfd7befa77e89b1",
        "0xaf055aa158cab621a3aa049028cca92789c06b76ca97e43b839f3a26001bcfe8",
        "0x0b0d6f5969c4d1ff7962d0f7b1695aabfd42696d4cd805f4c7c0b4cf717bb5dd",
        "0x48cb9d915f8a649aa1f54fc6b45e3cc7a4eafc331b929b996bc95da919c17649",
        "0x0d7f394ac6f78ccf904f80ffd5b31dbe4cb30f3795a96f80fb1c068805f3f54b",
        "0xd1907bd951a9e454ff9b27e8654382f1a54036346c60a8b98bd25559eab65d25",
        "0x9c692941785b97cda07bd03794f7aebda8eab3586241189253c9ecfbe7da6692",
        "0x0112e0783ad2697a8b444459115780266be0eb527c5b5b1a6b50afc490fa2001",
        "0x6e8e9a829b7c5bc2e5b9e6afc0ee59bbc3d16dbcf82eff2d5384e403c5989497",
        "0x11048b3c45758fe8904af7cee702fb3493f27a983ed108b4c93e0324d9e8e5bf",
      ];

      const txid = "5409d692cb3d3c7fc50ee91e59ae3b9f3104c01767833c185410a379b4f68b87";
      const rawTxProof =
        "0060682ddcdd2f2ad705cbf299a2f8552461083a71598dfd5288010000000000000000002a62a9baf40b7157d167463b1c55122b058f82175151cb5088cd15ee18e0d093dac1b268912b02177a20f5e24c1200000e44098705578cf09ba5d2483a90185e802d2cbc8bf6ffdc730ef0e90c302cbf0b93ac647622337333090ecbcb3dd8cd948a7b6ddf7f9a103e2d2c2e1badd5d1b4e4639e85f25b9e05b4ee5361a0f623811c1a0d46c9f2d4d0408285f8bbfd201a85704ad1930100bc8c5645e73a290e7a6ba788788a50d3f4ba716a832545bc4c878bf6b479a31054183c836717c004319f3bae591ee90ec57f3c3dcb92d609549c4b3de4a5ecd5eb41f45beb1c26ac6678d54fb674cd30f372a953f1d761564ee3206c041790d67a45636e96ecbba73b506aeaceeaf4b0f861a8ac355eb53fc7ad99e27cf0e2d58fd3402b0949fb2e32ce0f75fbbc0b28d275e8ef98cfda279c9c29da273f516a2eb2a912878d36486eda015eeccdbdca5c3f0b9bc0ded2f5a9fa6c51c1fc6e8c3af099b59c10a901aedab95a217c3a89167305c3734182df84f641ef40e6dd4b06b2dc855956c2a3191df63c9347fb09dcb9df1f58c6d75ca9139f4a4e618583c9b6ea9f9ff9aeab7baeaaa692a2798accc2197134967457a2208601403a4591c83c71c6c2735407f61f46894508987e7c539ba47f2f6e4f872fa007e549b34cb47a9aa6349a8f2ba52c9eba1f19920cb0c2296dd3570421da04bfab0300";

      const parser = new MerkleRawProofParser(txid, rawTxProof);

      expect(
        await historicalSPVGateway.checkHistoryTxInclusion(
          parser.getSiblings(),
          blockHeader.rawHeader,
          parser.getTxidReversed(),
          parser.getTxIndex(),
          {
            blockHash: blockHeader.blockHash,
            blockHeight: blockHeader.height,
            level1MerkleProof: level1MerklePath.reverse(),
            level2MerkleProof: level2MerklePath.reverse(),
          },
        ),
      ).to.be.true;
    });
  });
});

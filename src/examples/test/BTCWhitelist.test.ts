import { expect } from "chai";
import { ethers } from "hardhat";

import {
  BlockHeaderData,
  getBlockHeaderData,
  getBlocksDataFilePath,
  getHistoryProofDirPath,
  getHistoryProofFromFile,
  getHistoryProofPublicInputsFromFile,
  MerkleRawProofParser,
  Reverter,
} from "@test-helpers";

import {
  BTCWhitelist,
  SPVGatewayV2,
  SPVGatewayV2__factory,
  HistoryProofVerifier,
  HistoryProofVerifier__factory,
} from "@ethers-v6";
import { wei } from "@/scripts";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("BTCWhitelist", () => {
  const reverter = new Reverter();

  const chunkSize: bigint = 1n;
  const maxFrontierLength: bigint = 25n;

  const provedBlocksCount = 10n;

  const whitelistMinAmount = wei(30, 8);
  const minConfirmationsCount = 5n;

  let OWNER: SignerWithAddress;
  let FIRST: SignerWithAddress;

  let spvGatewayV2: SPVGatewayV2;
  let btcWhitelist: BTCWhitelist;

  let historyProofVerifier: HistoryProofVerifier;

  let firstBlocksDataFilePath: string;

  before(async () => {
    [OWNER, FIRST] = await ethers.getSigners();

    const SPVGatewayV2Factory = new SPVGatewayV2__factory().connect(OWNER);
    const HistoryProofVerifierFactory = new HistoryProofVerifier__factory().connect(OWNER);

    historyProofVerifier = await HistoryProofVerifierFactory.deploy();
    spvGatewayV2 = await SPVGatewayV2Factory.deploy(historyProofVerifier, chunkSize, maxFrontierLength);

    await spvGatewayV2.__SPVGatewayV2_init();

    btcWhitelist = await ethers.deployContract("BTCWhitelist", [
      spvGatewayV2,
      whitelistMinAmount,
      minConfirmationsCount,
    ]);

    firstBlocksDataFilePath = getBlocksDataFilePath("headers_1_30.json");

    const historyProof10CDirPath = getHistoryProofDirPath(provedBlocksCount, false);

    const proof = getHistoryProofFromFile(historyProof10CDirPath);
    const publicInputs = getHistoryProofPublicInputsFromFile(historyProof10CDirPath);

    await spvGatewayV2.updateMainchain({
      blocksCount: provedBlocksCount,
      proof: proof,
      publicInputs: publicInputs,
    });

    expect(await spvGatewayV2.getMainchainHeight()).to.be.eq(provedBlocksCount - 1n);

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("initialization", () => {
    it("should set correct initial data", async () => {
      expect(await btcWhitelist.spvGatewayV2()).to.be.eq(spvGatewayV2);
      expect(await btcWhitelist.getWhitelistMinAmount()).to.be.eq(whitelistMinAmount);
      expect(await btcWhitelist.getMinConfirmationsCount()).to.be.eq(minConfirmationsCount);
    });
  });

  describe("updateWhitelistMinAmount", () => {
    it("should correctly update min amount to enter whitelist", async () => {
      const newMinAmount = whitelistMinAmount * 2n;

      const tx = await btcWhitelist.updateWhitelistMinAmount(newMinAmount);

      await expect(tx).to.emit(btcWhitelist, "WhitelistMinAmountUpdated").withArgs(newMinAmount);
    });

    it("should get exception if not an owner try to call this function", async () => {
      const newMinAmount = whitelistMinAmount * 2n;

      await expect(btcWhitelist.connect(FIRST).updateWhitelistMinAmount(newMinAmount))
        .to.be.revertedWithCustomError(btcWhitelist, "OwnableUnauthorizedAccount")
        .withArgs(FIRST.address);
    });
  });

  describe("updateMinConfirmationsCount", () => {
    it("should correctly update min amount to enter whitelist", async () => {
      const newMinConfirmationsCount = 8n;

      const tx = await btcWhitelist.updateMinConfirmationsCount(newMinConfirmationsCount);

      await expect(tx).to.emit(btcWhitelist, "MinConfirmationsCountUpdated").withArgs(newMinConfirmationsCount);
    });

    it("should get exception if not an owner try to call this function", async () => {
      const newMinConfirmationsCount = 8n;

      await expect(btcWhitelist.connect(FIRST).updateMinConfirmationsCount(newMinConfirmationsCount))
        .to.be.revertedWithCustomError(btcWhitelist, "OwnableUnauthorizedAccount")
        .withArgs(FIRST.address);
    });
  });

  describe("enterToWhitelist", () => {
    const blockHeight = 4;
    const level2MerklePath = [
      "0xe32e10bf9f9f1bf1b57a958c51ed7a2a519eb8afcaf8530b24b414c64967819d",
      "0x09dbdab95166b8d2e4ba0bb5939e716d62b1d1fdbccbc1cab85d75d90278702b",
      "0xdc50af91c44dadd3f98cd581d18cb0e323e1643ea1bc43f76d2eb78713cd6006",
      "0xcb73f4e3f81ce9fca9372b78e37d1be5c4cc7c974e261d7d0e3e444bc0daa479",
    ];

    // We will prove next tx - https://learnmeabitcoin.com/explorer/tx/df2b060fa2e5e9c8ed5eaf6a45c13753ec8c63282b2688322eba40cd98ea067a
    const txid = "df2b060fa2e5e9c8ed5eaf6a45c13753ec8c63282b2688322eba40cd98ea067a";
    // To obtain the raw TX, we used the getrawtransaction RPC call with the txid
    const rawTx =
      "0x01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff0704ffff001d011affffffff0100f2052a01000000434104184f32b212815c6e522e66686324030ff7e5bf08efb21f8b00614fb7690e19131dd31304c54f37baa40db231c918106bb9fd43373e37ae31a0befc6ecaefb867ac00000000";
    // To obtain the TX proof, we used the gettxoutproof RPC call with the txid and the block hash as parameters
    const rawTxProof =
      "010000004944469562ae1c2c74d9a535e00b6f3e40ffbad4f2fda3895501b582000000007a06ea98cd40ba2e3288262b28638cec5337c1456aaf5eedc8e9e5a20f062bdf8cc16649ffff001d2bfee0a901000000017a06ea98cd40ba2e3288262b28638cec5337c1456aaf5eedc8e9e5a20f062bdf0101";

    let blockHeader: BlockHeaderData;

    beforeEach("setup", async () => {
      blockHeader = getBlockHeaderData(firstBlocksDataFilePath, blockHeight);
    });

    it("should correctly enter to the whitelist", async () => {
      const parser = new MerkleRawProofParser(txid, rawTxProof);

      const inclusionProofData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["bytes", "uint256", "bytes32[]", "tuple(bytes32[],bytes32[],bytes32,uint256)"],
        [
          blockHeader.rawHeader,
          parser.getTxIndex(),
          parser.getSiblings(),
          [[], level2MerklePath, blockHeader.blockHash, blockHeight],
        ],
      );

      const tx = await btcWhitelist.connect(FIRST).enterToWhitelist(rawTx, inclusionProofData);

      expect(await btcWhitelist.isAccountWhitelisted(FIRST)).to.be.true;
      expect(await btcWhitelist.getWhitelistedAccountsCount()).to.be.eq(1n);
      expect(await btcWhitelist.getAllWhitelistedAccounts()).to.be.deep.eq([FIRST.address]);

      await expect(tx).to.emit(btcWhitelist, "AccountWhitelisted").withArgs(FIRST.address);
    });

    it("should get exception if the min confirmation count not reached", async () => {
      const newMinConfirmationsCount = 6n;

      await btcWhitelist.updateMinConfirmationsCount(newMinConfirmationsCount);

      expect(await btcWhitelist.getMinConfirmationsCount()).to.be.eq(newMinConfirmationsCount);

      const parser = new MerkleRawProofParser(txid, rawTxProof);

      const inclusionProofData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["bytes", "uint256", "bytes32[]", "tuple(bytes32[],bytes32[],bytes32,uint256)"],
        [
          blockHeader.rawHeader,
          parser.getTxIndex(),
          parser.getSiblings(),
          [[], level2MerklePath, blockHeader.blockHash, blockHeight],
        ],
      );

      await expect(btcWhitelist.connect(FIRST).enterToWhitelist(rawTx, inclusionProofData))
        .to.be.revertedWithCustomError(btcWhitelist, "MinConfirmationsCountNotReached")
        .withArgs(blockHeight, await spvGatewayV2.getMainchainHeight());
    });

    it("should get exception if the account is already whitelisted", async () => {
      const parser = new MerkleRawProofParser(txid, rawTxProof);

      const inclusionProofData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["bytes", "uint256", "bytes32[]", "tuple(bytes32[],bytes32[],bytes32,uint256)"],
        [
          blockHeader.rawHeader,
          parser.getTxIndex(),
          parser.getSiblings(),
          [[], level2MerklePath, blockHeader.blockHash, blockHeight],
        ],
      );

      await btcWhitelist.connect(FIRST).enterToWhitelist(rawTx, inclusionProofData);

      await expect(btcWhitelist.connect(FIRST).enterToWhitelist(rawTx, inclusionProofData))
        .to.be.revertedWithCustomError(btcWhitelist, "AccountIsAlreadyWhitelisted")
        .withArgs(FIRST.address);
    });

    it("should get exception if the whitelist entry rules are not matched", async () => {
      const newWhitelistMinAmount = wei(51, 8);

      await btcWhitelist.updateWhitelistMinAmount(newWhitelistMinAmount);

      expect(await btcWhitelist.getWhitelistMinAmount()).to.be.eq(newWhitelistMinAmount);

      const parser = new MerkleRawProofParser(txid, rawTxProof);

      const inclusionProofData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["bytes", "uint256", "bytes32[]", "tuple(bytes32[],bytes32[],bytes32,uint256)"],
        [
          blockHeader.rawHeader,
          parser.getTxIndex(),
          parser.getSiblings(),
          [[], level2MerklePath, blockHeader.blockHash, blockHeight],
        ],
      );

      await expect(
        btcWhitelist.connect(FIRST).enterToWhitelist(rawTx, inclusionProofData),
      ).to.be.revertedWithCustomError(btcWhitelist, "WhitelistEntryRulesAreNotMatched");
    });

    it("should get exception if the tx is not included in the passed block", async () => {
      // TX from the block at height 7
      const newTxId = "8aa673bc752f2851fd645d6a0a92917e967083007d9c1684f9423b100540673f";
      const newRawTX =
        "0x01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff0704ffff001d012bffffffff0100f2052a01000000434104a59e64c774923d003fae7491b2a7f75d6b7aa3f35606a8ff1cf06cd3317d16a41aa16928b1df1f631f31f28c7da35d4edad3603adb2338c4d4dd268f31530555ac00000000";
      const newRawTxProof =
        "010000008d778fdc15a2d3fb76b7122a3b5582bea4f21f5a0c693537e7a03130000000003f674005103b42f984169c7d008370967e91920a6a5d64fd51282f75bc73a68af1c66649ffff001d39a59c8601000000013f674005103b42f984169c7d008370967e91920a6a5d64fd51282f75bc73a68a0101";

      const parser = new MerkleRawProofParser(newTxId, newRawTxProof);

      const inclusionProofData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["bytes", "uint256", "bytes32[]", "tuple(bytes32[],bytes32[],bytes32,uint256)"],
        [
          blockHeader.rawHeader,
          parser.getTxIndex(),
          parser.getSiblings(),
          [[], level2MerklePath, blockHeader.blockHash, blockHeight],
        ],
      );

      await expect(
        btcWhitelist.connect(FIRST).enterToWhitelist(newRawTX, inclusionProofData),
      ).to.be.revertedWithCustomError(btcWhitelist, "TxNotIncluded");
    });
  });
});

import * as fs from "fs";
import { ethers } from "hardhat";
import path from "path";

import { SimpleMerkleTree } from "@openzeppelin/merkle-tree";
import { HexString, BytesLike } from "@openzeppelin/merkle-tree/dist/bytes";

export const HISTORY_PROOF_CHUNK_SIZE_V1 = 1024n;

export function getHistoryProofDirPath(provedBlocksCount: bigint): string {
  return path.join(__dirname, `../data/history_proof`, provedBlocksCount.toString());
}

export function getHistoryProofV2DirPath(provedBlocksCount: bigint, isDefaultAddr: boolean = true): string {
  const fileNameSuffix = isDefaultAddr ? `_d` : `_c`;

  return path.join(__dirname, `../data/history_proof_v2`, `${provedBlocksCount.toString()}${fileNameSuffix}`);
}

export function getHistoryProofFromFile(proofDirPath: string, proofFileName: string = "proof_fields.json"): string {
  const filePath = path.join(proofDirPath, proofFileName);
  const proofDataArr = JSON.parse(fs.readFileSync(filePath, "utf-8")) as string[];

  return "0x" + proofDataArr.map((el: string) => el.slice(2)).join("");
}

export function getHistoryProofPublicInputsFromFile(
  proofDirPath: string,
  publicInputsFileName: string = "public_inputs_fields.json",
): string[] {
  const filePath = path.join(proofDirPath, publicInputsFileName);
  const publicInputsDataArr = JSON.parse(fs.readFileSync(filePath, "utf-8")) as string[];

  return publicInputsDataArr;
}

export function getLevel1TreeRootsFromFile(
  proofDirPath: string,
  level1TreeRootsFileName: string = "level1TreeRoots.json",
): string[] {
  const filePath = path.join(proofDirPath, level1TreeRootsFileName);
  const level1TreeRoots = JSON.parse(fs.readFileSync(filePath, "utf-8")) as string[];

  return level1TreeRoots;
}

export function buildLevel2MerkleTree(level1Hashes: string[]): SimpleMerkleTree {
  const realValuesLength = Math.pow(2, Math.ceil(Math.log2(level1Hashes.length)));
  const valuesPadded = [
    ...level1Hashes,
    ...new Array<string>(realValuesLength - level1Hashes.length).fill(ethers.ZeroHash),
  ];

  const leaves = valuesPadded.map((value) => hashLevel2TreeLeaf(value)).reverse();

  return SimpleMerkleTree.of(leaves, { nodeHash: hashLevel2TreeNode, sortLeaves: false });
}

export function buildLevel1MerkleTree(blockHashes: string[]): SimpleMerkleTree {
  const leaves = blockHashes.map((blockHash) => hashLevel1TreeLeaf(blockHash)).reverse();

  return SimpleMerkleTree.of(leaves, { nodeHash: hashLevel1TreeNode, sortLeaves: false });
}

export function getChunkNumber(blockHeight: bigint, chunkSize: bigint = HISTORY_PROOF_CHUNK_SIZE_V1): bigint {
  return blockHeight / chunkSize;
}

export function getIndexInChunk(blockHeight: bigint, chunkSize: bigint = HISTORY_PROOF_CHUNK_SIZE_V1): bigint {
  return blockHeight % chunkSize;
}

export function hashLevel2TreeNode(left: BytesLike, right: BytesLike): HexString {
  return ethers.solidityPackedSha256(["string", "bytes32", "bytes32"], ["node2", left, right]);
}

export function hashLevel2TreeLeaf(value: string): string {
  return ethers.solidityPackedSha256(["string", "bytes32"], ["leaf2", value]);
}

export function hashLevel1TreeNode(left: BytesLike, right: BytesLike): HexString {
  return ethers.solidityPackedSha256(["string", "bytes32", "bytes32"], ["node1", left, right]);
}

export function hashLevel1TreeLeaf(value: string): string {
  return ethers.solidityPackedSha256(["string", "bytes32"], ["leaf1", value]);
}

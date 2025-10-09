from typing import List
import hashlib
import os
import json

BLOCK_HEADER_SIZE = 80


class Block:
    def __init__(self, header: str):
        self.version = header[:8]
        self.prev_hash = ''.join([header[8:72][i:i + 2]
                                 for i in range(0, len(header[8:72]), 2)][::-1])
        self.merkle_hash = ''.join([header[72:136][i:i + 2]
                                   for i in range(0, len(header[72:136]), 2)][::-1])
        self.time = header[136:144]
        self.nBits = header[144:152]
        self.nonce = header[152:]

    def get_block_hash(self) -> str:
        return hashlib.sha256(
            hashlib.sha256(
                bytes.fromhex(self.version) + 
                bytes.fromhex(self.prev_hash)[::-1] + 
                bytes.fromhex(
                    self.merkle_hash)[::-1] + 
                    bytes.fromhex(
                        self.time + 
                        self.nBits + 
                        self.nonce)
            ).digest()
        ).digest()[::-1].hex()

    def to_toml_block(self) -> str:
        return f"version = \"{int.from_bytes(bytes.fromhex(self.version), byteorder='little')}\"\n" + \
            f"prev_block = \"{self.prev_hash}\"\n" + \
            f"merkle_root = \"{self.merkle_hash}\"\n" + \
            f"timestamp = \"{int.from_bytes(bytes.fromhex(self.time), byteorder='little')}\"\n" + \
            f"bits = \"{int.from_bytes(bytes.fromhex(self.nBits), byteorder='little')}\"\n" + \
            f"nonce = \"{int.from_bytes(bytes.fromhex(self.nonce), byteorder='little')}\"\n"

    def __str__(self) -> str:
        return self.to_toml_block()
    
    def to_dict(self):
        return {
            "version": self.version,
            "prev_hash": self.prev_hash,
            "merkle_hash": self.merkle_hash,
            "time": self.time,
            "nBits": self.nBits,
            "nonce": self.nonce
        }


def create_nargo_toml(blocks: List[Block], struct_name: str) -> str:
    nargo_field_blocks = map(lambda b: f"[{struct_name}]\n{b.to_toml_block()}", blocks)
    return "\n".join(nargo_field_blocks)


class Blocks:
    def __init__(self, json_path):
        self.json_path = json_path
        blocks = []
        try:
            with open(self.json_path, "r", encoding="utf-8") as f:
                for line in f:
                    data = json.loads(line)
                    block = Block.__new__(Block)
                    for k, v in data.items():
                        setattr(block, k, v)
                    blocks.append(block)
        except FileNotFoundError:
            pass
        
        self.amount = len(blocks)
        self.blocks = blocks

    def add_blocks(self, new_blocks: list[Block]):
        self.amount += len(new_blocks)
        self.blocks.extend(new_blocks)
        with open(self.json_path, "a", encoding="utf-8") as f:
            for block in new_blocks:
                f.write(json.dumps(block.to_dict(), ensure_ascii=False) + "\n")

import json
from typing import Dict
from generators.blocks.pullers import BlockHeaderPuller
from generators.blocks.block import Block, create_nargo_toml, Blocks
import logging
import subprocess
import ast
import logging
import os
import shutil
import argparse

DEFAULT_CONFIG_PATH = "./generators/blocks/config.json"
OUTPUT_DATA_PATH = "./target/blocks/"

RECURSIVE_BASE_APP_PATH = "./app/blocks_recursive/recursive_base/"
RECURSIVE_BASE_SCHEME_PATH = "./target/recursive_base.json"
RECURSIVE_BASE_OUTPUT_PATH = "./target/blocks_bin/"

RECURSIVE_APP_PATH = "./app/blocks_recursive/recursive/"
RECURSIVE_SCHEME_PATH = "./target/recursive.json"
RECURSIVE_OUTPUT_PATH = "./target/blocks_bin/recursive/"

MERKLE_ROOT_STATE_LEN = 25
ETH_ADDRESS = "0x0000000000000000000000000000000000000000"

def setup_logging():
    logging.basicConfig(level=logging.DEBUG)


def get_config(path) -> Dict:
    with open(path, "r") as f:
        return json.load(f)


def hex_to_bytearray(hex_str: str) -> bytearray:
    if hex_str.startswith("0x") or hex_str.startswith("0X"):
        hex_str = hex_str[2:]
    
    if len(hex_str) % 2 != 0:
        hex_str = "0" + hex_str

    return bytearray.fromhex(hex_str)


def to_toml_array_hashes(elements) -> str:
    chunks = [elements[i:i + 32] for i in range(0, len(elements), 32)]

    toml_str = "[\n"
    for chunk in chunks:
        toml_str += "  [" + ", ".join(f'"{v}"' for v in chunk) + "],\n"
    toml_str += "]"

    return toml_str


def save_batch_info(batch_idx: int, is_start: bool):
    os.makedirs(f"{OUTPUT_DATA_PATH}batch{batch_idx}", exist_ok=True)

    filename = "recursive_base.gz" if is_start else "recursive.gz"
    src = f"target/{filename}"
    dst = f"{OUTPUT_DATA_PATH}batch{batch_idx}/"
    shutil.copy(src, dst)

    if is_start:
        src = RECURSIVE_BASE_OUTPUT_PATH 
    else:
        src = RECURSIVE_OUTPUT_PATH

    shutil.copy(src + "proof", dst)
    shutil.copy(src + "proof_fields.json", dst)
    shutil.copy(src + "public_inputs", dst)
    shutil.copy(src + "public_inputs_fields.json", dst)

    logging.debug(f"Proof data saved to {dst}")


def main():
    setup_logging()

    parser = argparse.ArgumentParser(description="Prove the validity of the Bitcoin block header chain")
    parser.add_argument("--config", type=str, required=False, help="config file path", default="generators/blocks/config.json")
    parser.add_argument("--address", type=str, required=False, help="ethereum address", default="0x0000000000000000000000000000000000000000")
    args = parser.parse_args()

    config = get_config(args.config if args.config is not None else DEFAULT_CONFIG_PATH)
    address = hex_to_bytearray(args.address if args.address is not None else ETH_ADDRESS)
    index = 0
    checkpoint = config["from_checkpoint"]
    batch_idx = 0
    os.makedirs(OUTPUT_DATA_PATH + "schemas", exist_ok=True)

    blocks_amount = config["blocks"]["count"]

    with open(RECURSIVE_BASE_APP_PATH + "src/constants.nr", "w") as f:
        f.write(f"pub global MERKLE_ROOT_ARRAY_LEN: u32 = {MERKLE_ROOT_STATE_LEN};")

    with open(RECURSIVE_APP_PATH + "src/constants.nr", "w") as f:
        f.write(f"""pub global HONK_VK_SIZE: u32 = 128;
pub global HONK_PROOF_SIZE: u32 = 456;
pub global HONK_IDENTIFIER: u32 = 1;
pub global PUBLIC_INPUTS: u32 = {79 + 32 * MERKLE_ROOT_STATE_LEN};

pub global MERKLE_ROOT_ARRAY_LEN: u32 = {MERKLE_ROOT_STATE_LEN};
""")
        
    loaded = Blocks("./generators/blocks/blocks.json")  

    if loaded.amount >= blocks_amount:
        blocks = loaded.blocks
    else:
        puller = BlockHeaderPuller(config["rpc"])
        end = False
        for i in range(loaded.amount, config["blocks"]["count"], 2000):
            hex_headers = puller.pull_block_headers(
                i, min(2000, config["blocks"]["count"] - i))
            
            if any(h is None for h in hex_headers):
                end = True

            hex_headers = [h for h in hex_headers if h is not None]

            blocks = [Block(header) for header in hex_headers]
            loaded.add_blocks(blocks)
            if end:
                break

        blocks = loaded.blocks

    if not checkpoint:
        nargo_toml = create_nargo_toml(blocks[0:1], "block")
        index += 1

        with open(RECURSIVE_BASE_APP_PATH + "Prover.toml", "w") as f:
            f.write(f"address = [{', '.join(
                f'"{elem}"' for elem in address)}]\n\n")
            f.write(nargo_toml)

        logging.debug("nargo execute (base)")
        subprocess.run(['nargo', 'execute', '--package', 'recursive_base'], check=True)

        shutil.copy(RECURSIVE_BASE_SCHEME_PATH, OUTPUT_DATA_PATH + "schemas/")

        logging.debug("bb proof")
        subprocess.run(['bb', 'prove',
                        '-s', 'ultra_honk',
                        '-b', RECURSIVE_BASE_SCHEME_PATH,
                        '-w', './target/recursive_base.gz',
                        '-o', RECURSIVE_BASE_OUTPUT_PATH,
                        '--output_format', 'bytes_and_fields',
                        '--honk_recursion', '1',
                        '--recursive',
                        '--init_kzg_accumulator'],
                       check=True)

        logging.debug("bb write_vk (start)")
        subprocess.run(['bb', 'write_vk',
                        '-s', 'ultra_honk',
                        '-b', RECURSIVE_BASE_SCHEME_PATH,
                        '-o', RECURSIVE_BASE_OUTPUT_PATH,
                        '--output_format', 'bytes_and_fields',
                        '--honk_recursion', '1',
                        '--init_kzg_accumulator'],
                       check=True)

        shutil.copy(RECURSIVE_BASE_OUTPUT_PATH + "vk", OUTPUT_DATA_PATH + "schemas/vk_base")
        shutil.copy(RECURSIVE_BASE_OUTPUT_PATH + "vk_fields.json",
                    OUTPUT_DATA_PATH + "schemas/vk_fields_base.json")

        subprocess.run(['bb', 'verify',
                        '-s', 'ultra_honk',
                        '-k', RECURSIVE_BASE_OUTPUT_PATH + 'vk',
                        '-p', RECURSIVE_BASE_OUTPUT_PATH + 'proof',
                        '-i', RECURSIVE_BASE_OUTPUT_PATH + 'public_inputs'],
                       check=True)

        save_batch_info(batch_idx, True)
        batch_idx += 1

        with open(RECURSIVE_BASE_OUTPUT_PATH + "proof_fields.json", "r") as file:
            proof = file.read()

        with open(RECURSIVE_BASE_OUTPUT_PATH + "vk_fields.json", "r") as file:
            vk = file.read()

        with open(RECURSIVE_BASE_OUTPUT_PATH + "public_inputs_fields.json", "r") as file:
            pi = file.read()

        logging.debug("nargo compile (recursive)")
        subprocess.run(
            ['nargo', 'compile', '--package', 'recursive'], check=True)

        shutil.copy(RECURSIVE_SCHEME_PATH, OUTPUT_DATA_PATH + "schemas/")

        logging.debug("bb write_vk (recursive)")
        subprocess.run(['bb', 'write_vk',
                        '-s', 'ultra_honk',
                        '-b', RECURSIVE_SCHEME_PATH,
                        '-o', RECURSIVE_OUTPUT_PATH,
                        '--output_format', 'bytes_and_fields',
                        '--honk_recursion', '1',
                        '--init_kzg_accumulator'],
                       check=True)

        shutil.copy(
            RECURSIVE_OUTPUT_PATH + "vk",
            OUTPUT_DATA_PATH + "schemas/vk_recursive")
        shutil.copy(RECURSIVE_OUTPUT_PATH + "vk_fields.json",
                    OUTPUT_DATA_PATH + "schemas/vk_fields_recursive.json")

    else:
        with open(RECURSIVE_OUTPUT_PATH + "public_inputs_fields.json", "r") as file:
            pi = file.read()

        pi_array = ast.literal_eval(pi)
        index = int(pi_array[44], 16)
        batch_idx = index

        with open(OUTPUT_DATA_PATH + f"batch{index - 1}/" + "proof_fields.json", "r") as file:
            proof = file.read()

        with open(OUTPUT_DATA_PATH + f"schemas/" + "vk_fields_recursive.json", "r") as file:
            vk = file.read()

        with open(OUTPUT_DATA_PATH + f"batch{index - 1}/" + "public_inputs_fields.json", "r") as file:
            pi = file.read()

        logging.debug(f"Continue proving from {index} block...")

    with open(OUTPUT_DATA_PATH + 'schemas/vk_fields_recursive.json', "r") as file:
        vk_recursive = file.read()

    while index < blocks_amount:
        pi_array = ast.literal_eval(pi)

        if index == 3 and not checkpoint:
            logging.debug("You can use checkpoint from this moment...")

        logging.debug(f"Prooving block {index}")
        nargo_toml = create_nargo_toml(blocks[index:(index + 1)], "block")
        prev_block_toml = create_nargo_toml(blocks[(index - 1):index], "prev_block")
        index += 1

        with open(RECURSIVE_APP_PATH + "Prover.toml", "w") as f:
            f.write(f"verification_key = {vk}\n\n")
            f.write(f"proof = {proof}\n\n")
            f.write(f"public_inputs = {pi}\n\n")
            f.write(f"address = [{', '.join(
                f'"{elem}"' for elem in address)}]\n\n")
            f.write(nargo_toml)
            f.write(prev_block_toml)

        logging.debug("nargo execute (recursive)")
        subprocess.run(['nargo', 'execute', '--package', 'recursive'], check=True)

        if (index == blocks_amount):
            logging.debug("bb prove (last recursive)")
            subprocess.run(['bb', 'prove',
                            '-s', 'ultra_honk',
                            '-b', RECURSIVE_SCHEME_PATH,
                            '-w', './target/recursive.gz',
                            '-o', RECURSIVE_OUTPUT_PATH,
                            '--output_format', 'bytes_and_fields',
                            '--oracle_hash', 'keccak'],
                           check=True)
        else:
            logging.debug("bb prove (recursive)")
            subprocess.run(['bb', 'prove',
                            '-s', 'ultra_honk',
                            '-b', RECURSIVE_SCHEME_PATH,
                            '-w', './target/recursive.gz',
                            '-o', RECURSIVE_OUTPUT_PATH,
                            '--output_format', 'bytes_and_fields',
                            '--honk_recursion', '1',
                            '--recursive',
                            '--init_kzg_accumulator'],
                           check=True)

            subprocess.run(['bb', 'verify',
                            '-s', 'ultra_honk',
                            '-k', OUTPUT_DATA_PATH + 'schemas/vk_recursive',
                            '-p', RECURSIVE_OUTPUT_PATH + 'proof',
                            '-i', RECURSIVE_OUTPUT_PATH + 'public_inputs'],
                           check=True)

        save_batch_info(batch_idx, False)
        batch_idx += 1

        with open(RECURSIVE_OUTPUT_PATH + "proof_fields.json", "r") as file:
            proof = file.read()

        vk = vk_recursive

        with open(RECURSIVE_OUTPUT_PATH + "public_inputs_fields.json", "r") as file:
            pi = file.read()

    logging.debug("bb write_vk (last recursive)")
    subprocess.run(['bb', 'write_vk',
                    '-s', 'ultra_honk',
                    '-b', RECURSIVE_SCHEME_PATH,
                    '-o', RECURSIVE_OUTPUT_PATH,
                    '--output_format', 'bytes_and_fields',
                    '--honk_recursion', '1',
                    '--init_kzg_accumulator',
                    '--oracle_hash', 'keccak'],
                   check=True)

    subprocess.run(['bb', 'verify',
                    '-s', 'ultra_honk',
                    '-k', RECURSIVE_OUTPUT_PATH + 'vk',
                    '-p', RECURSIVE_OUTPUT_PATH + 'proof',
                    '-i', RECURSIVE_OUTPUT_PATH + 'public_inputs',
                    '--oracle_hash', 'keccak'],
                   check=True)

    subprocess.run(['bb', 'write_solidity_verifier',
                    '-k', RECURSIVE_OUTPUT_PATH + 'vk',
                    '-o', RECURSIVE_OUTPUT_PATH + 'Verifier.sol'],
                   check=True)

    print("Recursive proof was created successfully")


if __name__ == "__main__":
    main()

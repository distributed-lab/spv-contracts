import requests
import sys
from typing import Tuple

from bitcoin.core import b2x, CTransaction
from bitcoin.core.serialize import BytesIO
from generators.utils.tx import Transaction


def get_outputs_from_inputs(
        tx: Transaction) -> tuple[list[int], list[Tuple[int, int, int]]]:
    outs = []
    pos = []
    cur_pos = 0
    txid = calculate_txid_from_hex(tx.to_hex())
    response = requests.get(f"https://blockstream.info/api/tx/{txid}")
    if response.ok:
        tx_data = response.json()
        for inp in tx_data["vin"]:
            amount_bytes = inp["prevout"]["value"].to_bytes(
                8, byteorder='little')
            script_pub_key = bytearray.fromhex(inp["prevout"]["scriptpubkey"])
            script_pub_key_size = bytearray.fromhex(
                tx._get_hex_from_compact_size(len(script_pub_key)))
            pos += [(cur_pos, cur_pos + 8, cur_pos +
                     8 + len(script_pub_key_size))]
            cur_pos += 8 + len(script_pub_key_size) + len(script_pub_key)
            outs += amount_bytes + script_pub_key_size + script_pub_key
    else:
        print("Error:", response.status_code)
        sys.exit()

    pos += [(cur_pos, 0, 0)]

    return (outs, pos)


def calculate_txid_from_hex(raw_hex: str) -> str:
    tx = CTransaction.stream_deserialize(BytesIO(bytes.fromhex(raw_hex)))
    return b2x(tx.GetTxid()[::-1])


def get_outputs_positions_as_toml(pos: list[Tuple[int, int, int]]) -> str:
    res = ""
    for i in range(len(pos) - 1):
        res += f"""
[[utxos_pos]]
amount = {{offset = {pos[i][0]}, size = {pos[i][1] - pos[i][0]}}}
script_pub_key_size = {{offset = {pos[i][1]}, size = {pos[i][2] - pos[i][1]}}}
script_pub_key = {{offset = {pos[i][2]}, size = {pos[i + 1][0] - pos[i][2]}}}

"""
    return res

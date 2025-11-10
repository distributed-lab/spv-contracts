from bitcoin.core import CTransaction
from bitcoin.core.script import CScript, SignatureHash, SIGHASH_ALL, SIGHASH_ANYONECANPAY
from bitcoin import SelectParams

SelectParams('mainnet')

tx_hex = "..."  # Paste raw tx
tx_bytes = bytes.fromhex(tx_hex)
tx = CTransaction.deserialize(tx_bytes)

script_pubkey_hex = "..."  # Paste script pub key
script_pubkey = CScript(bytes.fromhex(script_pubkey_hex))

sighash = SignatureHash(
    script_pubkey,
    tx,
    0,
    SIGHASH_ALL | SIGHASH_ANYONECANPAY)

print(sighash.hex())

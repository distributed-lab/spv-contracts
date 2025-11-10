import json
from typing import Dict
from bitcoin.core import CScript
from generators.utils.tx import Transaction
from generators.utils.script import Script
from generators.utils.opcodes_gen import generate
from generators.constants import CONSTANTS_TEMPLATE, CONSTANTS_NR, PROVER_TEMPLATE, PROVER_TOML


def get_config(path: str = "./generators/p2pk/config.json") -> Dict:
    with open(path, "r") as f:
        return json.load(f)


def main():
    config = get_config()

    currentTx = Transaction(config["current_tx"])
    currentTx.cut_script_sigs()

    prevTx = Transaction(config["prev_tx"])
    prevTx.cut_script_sigs()

    with open(config["file_path"] + CONSTANTS_TEMPLATE, "r") as file:
        templateOpcodes = file.read()

    CURRENT_TX_INP_COUNT_SIZE = currentTx._get_compact_size_size(currentTx.input_count)
    CURRENT_TX_INP_SIZE = sum(currentTx._get_input_size(inp)
                            for inp in currentTx.inputs) + CURRENT_TX_INP_COUNT_SIZE
    CURRENT_TX_OUT_COUNT_SIZE = currentTx._get_compact_size_size(currentTx.output_count)
    CURRENT_TX_OUT_SIZE = sum(currentTx._get_output_size(out)
                            for out in currentTx.outputs) + CURRENT_TX_OUT_COUNT_SIZE

    PREV_TX_INP_COUNT_SIZE = prevTx._get_compact_size_size(prevTx.input_count)
    PREV_TX_INP_SIZE = sum(prevTx._get_input_size(inp)
                            for inp in prevTx.inputs) + PREV_TX_INP_COUNT_SIZE
    PREV_TX_OUT_COUNT_SIZE = prevTx._get_compact_size_size(prevTx.output_count)
    PREV_TX_OUT_SIZE = sum(prevTx._get_output_size(out)
                            for out in prevTx.outputs) + PREV_TX_OUT_COUNT_SIZE
    PREV_TX_MAX_WITNESS_STACK_SIZE = 0 if prevTx.witness is None else max(
        len(w.stack_items) for w in prevTx.witness)
    PREV_TX_WITNESS_SIZE = 0 if prevTx.witness is None else sum(
        prevTx._get_witness_size(wit) for wit in prevTx.witness)

    vout = currentTx.inputs[config["input_to_sign"]].vout
    script_pub_key = bytearray(prevTx.outputs[vout].script_pub_key)

    print("Spending type: p2pk")

    script_sig = config["script_sig"]
    full_script = bytes.fromhex(script_sig) + script_pub_key

    script = Script(full_script.hex(), currentTx, config["input_to_sign"])
    generate(script.sizes)

    INPUT_TO_SIGN = config["input_to_sign"]

    opcodesFile = templateOpcodes.format(
        currentTx=currentTx,
        prevTx=prevTx,
        currentTxInCountSize=CURRENT_TX_INP_COUNT_SIZE,
        currentTxInSize=CURRENT_TX_INP_SIZE,
        currentTxOutCountSize=CURRENT_TX_OUT_COUNT_SIZE,
        currentTxOutSize=CURRENT_TX_OUT_SIZE,
        prevTxInCountSize=PREV_TX_INP_COUNT_SIZE,
        prevTxInSize=PREV_TX_INP_SIZE,
        prevTxOutCountSize=PREV_TX_OUT_COUNT_SIZE,
        prevTxOutSize=PREV_TX_OUT_SIZE,
        prevTxMaxWitnessStackSize=PREV_TX_MAX_WITNESS_STACK_SIZE,
        prevTxWitnessSize=PREV_TX_WITNESS_SIZE,
        isPrevSegwit=str(PREV_TX_WITNESS_SIZE != 0).lower(),
        currentTxSize=currentTx._get_transaction_size() * 2,
        prevTxSize=prevTx._get_transaction_size() * 2,
        scriptSigSize=len(config["script_sig"]),
        nOutputSize=currentTx._get_output_size(currentTx.outputs[INPUT_TO_SIGN]),
        inputToSign=INPUT_TO_SIGN,
        inputToSignSize=currentTx._get_compact_size_size(INPUT_TO_SIGN),
        nInputSize=currentTx._get_input_size(currentTx.inputs[INPUT_TO_SIGN]),
        scriptPubKeySize=len(script_pub_key),
    )

    with open(config["file_path"] + CONSTANTS_NR, "w") as file:
        file.write(opcodesFile)

    with open(config["file_path"] + PROVER_TEMPLATE, "r") as file:
        templateProver = file.read()

    currentTxData = currentTx.to_hex()
    prevTxData = prevTx.to_hex()

    proverFile = templateProver.format(
        currentTxData=currentTxData,
        prevTxData=prevTxData,
        scriptSig=config["script_sig"],
        inputToSign=INPUT_TO_SIGN
    )

    with open(config["file_path"] + PROVER_TOML, "w") as file:
        file.write(proverFile)


if __name__ == "__main__":
    main()

import json
from typing import Dict
from generators.utils.tx import Transaction
from generators.utils.script import Script
from generators.utils.opcodes_gen import generate
from generators.utils.taproot_utils import get_outputs_from_inputs
from generators.constants import CONSTANTS_TEMPLATE, CONSTANTS_NR, PROVER_TEMPLATE, PROVER_TOML


def get_config(path: str = "./generators/p2tr_script/config.json") -> Dict:
    with open(path, "r") as f:
        return json.load(f)


def main():
    print("Spending type: p2tr - script path spend")
    config = get_config()

    currentTx = Transaction(config["current_tx"])
    currentTx.cut_script_sigs()

    prevTx = Transaction(config["prev_tx"])
    prevTx.cut_script_sigs()

    INPUT_TO_SIGN = config["input_to_sign"]

    witness = currentTx.witness_to_hex_script(INPUT_TO_SIGN, 2)
    ws = Script(witness, currentTx, 0, [])
    script = currentTx.witness[INPUT_TO_SIGN].stack_items[-2].item
    script_parse = Script(
        script.hex(), 
        currentTx, 
        config["input_to_sign"], 
        [
            elem.item for elem in currentTx.witness[INPUT_TO_SIGN].stack_items[:-2]
        ])
    control_block = currentTx.witness[INPUT_TO_SIGN].stack_items[-1].item
    sizes = script_parse.sizes
    generate(sizes, True)

    with open(config["file_path"] + CONSTANTS_TEMPLATE, "r") as file:
        templateOpcodes = file.read()

    CURRENT_TX_INP_COUNT_SIZE = currentTx._get_compact_size_size(currentTx.input_count)
    CURRENT_TX_INP_SIZE = sum(currentTx._get_input_size(inp)
                            for inp in currentTx.inputs) + CURRENT_TX_INP_COUNT_SIZE
    CURRENT_TX_OUT_COUNT_SIZE = currentTx._get_compact_size_size(currentTx.output_count)
    CURRENT_TX_OUT_SIZE = sum(currentTx._get_output_size(out)
                            for out in currentTx.outputs) + CURRENT_TX_OUT_COUNT_SIZE
    CURRENT_TX_MAX_WITNESS_STACK_SIZE = 0 if currentTx.witness is None else max(
        len(w.stack_items) for w in currentTx.witness)
    CURRENT_TX_WITNESS_SIZE = 0 if currentTx.witness is None else sum(
        currentTx._get_witness_size(wit) for wit in currentTx.witness)

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

    outpus = get_outputs_from_inputs(currentTx)
    requireStackSize = ws.require_stack_size + script_parse.require_stack_size
    maxStackElementSize = max(
        script_parse.max_element_size,
        ws.max_element_size)

    opcodesFile = templateOpcodes.format(
        currentTx=currentTx,
        prevTx=prevTx,
        utxosSize=len(outpus[0]),
        inputWitnessSize=currentTx._get_witness_size(
            currentTx.witness[INPUT_TO_SIGN]) - 
            currentTx._get_compact_size_size(
                currentTx.witness[INPUT_TO_SIGN].stack_items[-1].item_size) -
        currentTx.witness[INPUT_TO_SIGN].stack_items[-1].item_size - 
        currentTx._get_compact_size_size(
            currentTx.witness[INPUT_TO_SIGN].stack_items[-2].item_size) - 
            currentTx.witness[INPUT_TO_SIGN].stack_items[-2].item_size - 1,
        currentTxInCountSize=CURRENT_TX_INP_COUNT_SIZE,
        currentTxInSize=CURRENT_TX_INP_SIZE,
        currentTxOutCountSize=CURRENT_TX_OUT_COUNT_SIZE,
        currentTxOutSize=CURRENT_TX_OUT_SIZE,
        currentTxMaxWitnessStackSize=CURRENT_TX_MAX_WITNESS_STACK_SIZE,
        currentTxWitnessSize=CURRENT_TX_WITNESS_SIZE,
        isCurSegwit=str(CURRENT_TX_WITNESS_SIZE != 0).lower(),
        prevTxInCountSize=PREV_TX_INP_COUNT_SIZE,
        prevTxInSize=PREV_TX_INP_SIZE,
        prevTxOutCountSize=PREV_TX_OUT_COUNT_SIZE,
        prevTxOutSize=PREV_TX_OUT_SIZE,
        prevTxMaxWitnessStackSize=PREV_TX_MAX_WITNESS_STACK_SIZE,
        prevTxWitnessSize=PREV_TX_WITNESS_SIZE,
        isPrevSegwit=str(PREV_TX_WITNESS_SIZE != 0).lower(),
        currentTxSize=currentTx._get_transaction_size() * 2,
        prevTxSize=prevTx._get_transaction_size() * 2,
        nOutputSize=currentTx._get_output_size(currentTx.outputs[INPUT_TO_SIGN]),
        scriptSize=len(script),
        scriptSizeSize=currentTx._get_compact_size_size(len(script)),
        scriptOpcodesCount=script_parse.opcodes,
        controlBlockSize=len(control_block),
        stackSize=requireStackSize,
        maxStackElementSize=maxStackElementSize,
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
        utxosData=list_to_toml(outpus[0]),
        inputToSign=INPUT_TO_SIGN,
    )

    with open(config["file_path"] + PROVER_TOML, "w") as file:
        file.write(proverFile)


def list_to_toml(list) -> str:
    res = "["
    for elem in list:
        res += f'"{elem}", '

    res = res[:-2]
    res += "]"
    return res


if __name__ == "__main__":
    main()

import json
from typing import Dict
from generators.utils.tx import Transaction
from generators.utils.script import Script
from generators.utils.opcodes_gen import generate
from generators.constants import CONSTANTS_TEMPLATE, CONSTANTS_NR, PROVER_TEMPLATE, PROVER_TOML


def get_config(path: str = "./generators/p2sh/config.json") -> Dict:
    with open(path, "r") as f:
        return json.load(f)


def main():
    config = get_config()

    currentTx = Transaction(config["current_tx"])
    currentTx.cut_script_sigs()

    vout = currentTx.inputs[config["input_to_sign"]].vout

    prevTx = Transaction(config["prev_tx"])
    prevTx.cut_script_sigs()

    INPUT_TO_SIGN = config["input_to_sign"]

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

    script_pub_key = prevTx.outputs[vout].script_pub_key

    script_sig = config["script_sig"] if CURRENT_TX_WITNESS_SIZE == 0 else currentTx.witness_to_hex_script(
        INPUT_TO_SIGN)

    if CURRENT_TX_WITNESS_SIZE != 0:
        print("Spending type: p2wsh")
        full_script_pub_key = [168, 32]
        full_script_pub_key.extend(script_pub_key[2:])
        full_script_pub_key.append(135)
        script_pub_key = full_script_pub_key
    else:
        print("Spending type: p2sh")

    script = Script(
        script_sig, 
        currentTx, 
        config["input_to_sign"])
    sizes = script.sizes

    redeem_script = Script(
        script.script_elements[-1], 
        currentTx, config["input_to_sign"], 
        script.script_elements[0:-1])
    
    spk_script = Script(
        bytearray(script_pub_key).hex(),
        currentTx,
        config["input_to_sign"],
        [script.script_elements[-1]])
    sizes = sizes | redeem_script.sizes | spk_script.sizes
    generate(sizes)

    require_stack_size = max(
        script.require_stack_size +
        spk_script.require_stack_size,
        redeem_script.require_stack_size)
    max_element_size = max(
        script.max_element_size,
        redeem_script.max_element_size,
        spk_script.max_element_size)

    with open(config["file_path"] + CONSTANTS_TEMPLATE, "r") as file:
        templateOpcodes = file.read()

    opcodesFile = templateOpcodes.format(
        currentTx=currentTx,
        prevTx=prevTx,
        currentTxInCountSize=CURRENT_TX_INP_COUNT_SIZE,
        currentTxInSize=CURRENT_TX_INP_SIZE,
        currentTxOutCountSize=CURRENT_TX_OUT_COUNT_SIZE,
        currentTxOutSize=CURRENT_TX_OUT_SIZE,
        currentTxMaxWitnessStackSize=CURRENT_TX_MAX_WITNESS_STACK_SIZE,
        currentTxWitnessSize=CURRENT_TX_WITNESS_SIZE,
        isCurrentSegwit=str(CURRENT_TX_WITNESS_SIZE != 0).lower(),
        prevTxInCountSize=PREV_TX_INP_COUNT_SIZE,
        prevTxInSize=PREV_TX_INP_SIZE,
        prevTxOutCountSize=PREV_TX_OUT_COUNT_SIZE,
        prevTxOutSize=PREV_TX_OUT_SIZE,
        prevTxMaxWitnessStackSize=PREV_TX_MAX_WITNESS_STACK_SIZE,
        prevTxWitnessSize=PREV_TX_WITNESS_SIZE,
        isPrevSegwit=str(PREV_TX_WITNESS_SIZE != 0).lower(),
        opcodesCount=0 if CURRENT_TX_WITNESS_SIZE != 0 else script.opcodes,
        currentTxSize=currentTx._get_transaction_size() * 2,
        prevTxSize=prevTx._get_transaction_size() * 2,
        signSize=1 if CURRENT_TX_WITNESS_SIZE != 0 else len(script_sig),
        scriptPubKeySize=len(script_pub_key),
        inputWitnessSize=currentTx._get_witness_size(
            currentTx.witness[INPUT_TO_SIGN]) - 1 if currentTx.witness is not None else 0,
        redeemScriptSize=len(script.script_elements[-1]) // 2,
        codeseparatorRedeemScriptSize=redeem_script.script_len_codeseparator,
        codeseparatorRedeemScriptSizeSize=currentTx._get_compact_size_size(
            redeem_script.script_len_codeseparator),
        redeemOpcodesCount=redeem_script.opcodes,
        stackSize=require_stack_size,
        maxStackElementSize=max_element_size,
        nOutputSize=currentTx._get_output_size(
            currentTx.outputs[INPUT_TO_SIGN]) if len(
            currentTx.outputs) > INPUT_TO_SIGN else 0,
        inputToSign=INPUT_TO_SIGN,
        inputToSignSize=currentTx._get_compact_size_size(INPUT_TO_SIGN),
        nInputSize=currentTx._get_input_size(currentTx.inputs[INPUT_TO_SIGN]),
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
        scriptSig="-" if CURRENT_TX_WITNESS_SIZE != 0 else script_sig,
        inputToSign=INPUT_TO_SIGN
    )

    with open(config["file_path"] + PROVER_TOML, "w") as file:
        file.write(proverFile)


if __name__ == "__main__":
    main()

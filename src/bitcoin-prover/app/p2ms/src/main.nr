mod constants;

use bvm::stack::{empty_stack_array, Stack};
use constants::{
    CURRENT_TX_IN_COUNT, CURRENT_TX_IN_COUNT_SIZE, CURRENT_TX_IN_SIZE, CURRENT_TX_OUT_COUNT,
    CURRENT_TX_OUT_COUNT_SIZE, CURRENT_TX_OUT_SIZE, CURRENT_TX_SIZE, INPUT_TO_SIGN,
    INPUT_TO_SIGN_SIZE, IS_PREV_SEGWIT, MAX_STACK_ELEMENT_SIZE, N_INPUT_SIZE, N_OUTPUT_SIZE,
    OPCODES_COUNT, PREV_TX_IN_COUNT, PREV_TX_IN_COUNT_SIZE, PREV_TX_IN_SIZE,
    PREV_TX_MAX_WITNESS_STACK_SIZE, PREV_TX_OUT_COUNT, PREV_TX_OUT_COUNT_SIZE, PREV_TX_OUT_SIZE,
    PREV_TX_SIZE, PREV_TX_WITNESS_SIZE, SCRIPT_PUB_KEY_SIZE, SCRIPT_PUB_KEY_SIZE_SIZE,
    SCRIPT_SIG_SIZE, STACK_SIZE,
};
use script::execution::ScriptExecutionEngine;
use sign::{address::Address, transaction::Transaction};
use utils::convert::{hex_to_bytes, le_bytes_to_u32};

fn main(
    current_tx_data: str<CURRENT_TX_SIZE>,
    prev_tx_data: str<PREV_TX_SIZE>,
    script_sig: str<SCRIPT_SIG_SIZE>,
    input_to_sign: pub u32,
) -> pub bool {
    let current_tx_data = hex_to_bytes(current_tx_data);
    let prev_tx_data = hex_to_bytes(prev_tx_data);

    let current_tx = Transaction::<CURRENT_TX_SIZE / 2, CURRENT_TX_IN_COUNT, CURRENT_TX_IN_COUNT_SIZE, CURRENT_TX_IN_SIZE, CURRENT_TX_OUT_COUNT, CURRENT_TX_OUT_COUNT_SIZE, CURRENT_TX_OUT_SIZE, 0, 0>::new(
        current_tx_data,
        false,
    );

    let prev_tx = Transaction::<PREV_TX_SIZE / 2, PREV_TX_IN_COUNT, PREV_TX_IN_COUNT_SIZE, PREV_TX_IN_SIZE, PREV_TX_OUT_COUNT, PREV_TX_OUT_COUNT_SIZE, PREV_TX_OUT_SIZE, PREV_TX_MAX_WITNESS_STACK_SIZE, PREV_TX_WITNESS_SIZE>::new(
        prev_tx_data,
        IS_PREV_SEGWIT,
    );

    let mut script_pub_key = [0; SCRIPT_PUB_KEY_SIZE];

    let vout_pos = current_tx.inputs[input_to_sign].vout.offset;
    let mut vout_bytes = [0; 4];
    for i in 0..4 {
        vout_bytes[i] = current_tx.data[vout_pos + i];
    }

    let vout = le_bytes_to_u32(vout_bytes);
    let script_pub_key_pos = prev_tx.outputs[vout].script_pub_key.offset;

    for i in 0..SCRIPT_PUB_KEY_SIZE {
        script_pub_key[i] = prev_tx.data[script_pub_key_pos + i];
    }

    let mut stack = Stack::new(
        current_tx,
        prev_tx,
        input_to_sign,
        vout,
        empty_stack_array::<MAX_STACK_ELEMENT_SIZE, STACK_SIZE>(),
        [],
    );

    let mut script_execution_engine = ScriptExecutionEngine::new(stack);

    let script_sig_bytes = hex_to_bytes(script_sig);

    let script = script_sig_bytes
        .as_slice()
        .append(script_pub_key.as_slice())
        .as_array::<SCRIPT_SIG_SIZE / 2 + SCRIPT_PUB_KEY_SIZE>();

    script_execution_engine
        .execute::<SCRIPT_SIG_SIZE / 2 + SCRIPT_PUB_KEY_SIZE, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_SIZE, N_INPUT_SIZE, OPCODES_COUNT, SCRIPT_PUB_KEY_SIZE + SCRIPT_PUB_KEY_SIZE_SIZE, 0>(
            script,
            Address::new_p2ms(),
            [],
            Option::none(),
        );

    script_execution_engine.stack.op_verify()
}

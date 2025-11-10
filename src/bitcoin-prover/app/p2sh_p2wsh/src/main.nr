mod constants;

use bvm::stack::{empty_stack_array, Stack};
use constants::{
    CODESEPARATOR_REDEEM_SCRIPT_SIZE, CODESEPARATOR_REDEEM_SCRIPT_SIZE_SIZE, CURRENT_TX_IN_COUNT,
    CURRENT_TX_IN_COUNT_SIZE, CURRENT_TX_IN_SIZE, CURRENT_TX_MAX_WITNESS_STACK_SIZE,
    CURRENT_TX_OUT_COUNT, CURRENT_TX_OUT_COUNT_SIZE, CURRENT_TX_OUT_SIZE, CURRENT_TX_SIZE,
    CURRENT_TX_WITNESS_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_SIZE, IS_PREV_SEGWIT,
    MAX_STACK_ELEMENT_SIZE, N_INPUT_SIZE, N_OUTPUT_SIZE, OPCODES_COUNT, PREV_TX_IN_COUNT,
    PREV_TX_IN_COUNT_SIZE, PREV_TX_IN_SIZE, PREV_TX_MAX_WITNESS_STACK_SIZE, PREV_TX_OUT_COUNT,
    PREV_TX_OUT_COUNT_SIZE, PREV_TX_OUT_SIZE, PREV_TX_SIZE, PREV_TX_WITNESS_SIZE,
    REDEEM_SCRIPT_OPCODES_COUNT, REDEEM_SCRIPT_SIZE, SCRIPT_PUB_KEY_SIZE, SCRIPT_SIG_SIZE,
    STACK_SIZE, WITNESS_SCRIPT_SIZE,
};
use script::execution::ScriptExecutionEngine;
use sign::{address::Address, compact_size::u32_to_compact_size_array, transaction::Transaction};
use utils::convert::{hex_to_bytes, le_bytes_to_u32};

fn main(
    current_tx_data: str<CURRENT_TX_SIZE>,
    prev_tx_data: str<PREV_TX_SIZE>,
    script_sig: str<SCRIPT_SIG_SIZE>,
    witness_script: str<WITNESS_SCRIPT_SIZE>,
    input_to_sign: pub u32,
) -> pub bool {
    let current_tx_data = hex_to_bytes(current_tx_data);
    let prev_tx_data = hex_to_bytes(prev_tx_data);

    let current_tx = Transaction::<CURRENT_TX_SIZE / 2, CURRENT_TX_IN_COUNT, CURRENT_TX_IN_COUNT_SIZE, CURRENT_TX_IN_SIZE, CURRENT_TX_OUT_COUNT, CURRENT_TX_OUT_COUNT_SIZE, CURRENT_TX_OUT_SIZE, CURRENT_TX_MAX_WITNESS_STACK_SIZE, CURRENT_TX_WITNESS_SIZE>::new(
        current_tx_data,
        true,
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

    assert(SCRIPT_PUB_KEY_SIZE == 23);
    for i in 0..SCRIPT_PUB_KEY_SIZE {
        script_pub_key[i] = prev_tx.data[script_pub_key_pos + i];
    }

    let script_sig_bytes = hex_to_bytes(script_sig);

    let mut sig_script = [0; 35];

    sig_script[0] = 0xa8;
    sig_script[1] = 0x20;
    for i in 2..34 {
        sig_script[i] = script_sig_bytes[i + 1];
    }
    sig_script[34] = 0x87;

    let mut redeem_script = [0; REDEEM_SCRIPT_SIZE];
    let mut codeseparator_redeem_script = [0; CODESEPARATOR_REDEEM_SCRIPT_SIZE];
    let witness_script = hex_to_bytes(witness_script);

    for i in 0..REDEEM_SCRIPT_SIZE {
        redeem_script[REDEEM_SCRIPT_SIZE - 1 - i] =
            witness_script[(WITNESS_SCRIPT_SIZE / 2) - 1 - i];
    }

    for i in 0..CODESEPARATOR_REDEEM_SCRIPT_SIZE {
        codeseparator_redeem_script[CODESEPARATOR_REDEEM_SCRIPT_SIZE - 1 - i] =
            witness_script[(WITNESS_SCRIPT_SIZE / 2) - 1 - i];
    }

    let mut stack = Stack::new(
        current_tx,
        prev_tx,
        input_to_sign,
        vout,
        empty_stack_array::<MAX_STACK_ELEMENT_SIZE, STACK_SIZE>(),
        u32_to_compact_size_array::<CODESEPARATOR_REDEEM_SCRIPT_SIZE_SIZE>(
            CODESEPARATOR_REDEEM_SCRIPT_SIZE,
        )
            .as_slice()
            .append(codeseparator_redeem_script)
            .as_array::<CODESEPARATOR_REDEEM_SCRIPT_SIZE_SIZE + CODESEPARATOR_REDEEM_SCRIPT_SIZE>(),
    );

    let mut script_execution_engine = ScriptExecutionEngine::new(stack);

    let script = script_sig_bytes
        .as_slice()
        .append(script_pub_key.as_slice())
        .as_array::<SCRIPT_SIG_SIZE / 2 + SCRIPT_PUB_KEY_SIZE>();

    script_execution_engine
        .execute::<SCRIPT_SIG_SIZE / 2 + SCRIPT_PUB_KEY_SIZE, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_SIZE, N_INPUT_SIZE, 4, 0, 0>(
            script,
            Address::new_p2sh(),
            [],
            Option::none(),
        );

    assert(script_execution_engine.stack.op_verify());

    let script = witness_script
        .as_slice()
        .append(sig_script.as_slice())
        .as_array::<WITNESS_SCRIPT_SIZE / 2 + 35>();

    script_execution_engine
        .execute::<WITNESS_SCRIPT_SIZE / 2 + 35, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_SIZE, N_INPUT_SIZE, OPCODES_COUNT, 0, 0>(
            script,
            Address::new_p2wsh(),
            [],
            Option::none(),
        );

    assert(script_execution_engine.stack.op_verify());

    script_execution_engine
        .execute::<REDEEM_SCRIPT_SIZE, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_SIZE, N_INPUT_SIZE, REDEEM_SCRIPT_OPCODES_COUNT, 0, 0>(
            redeem_script,
            Address::new_p2wsh(),
            [],
            Option::none(),
        );

    script_execution_engine.stack.op_verify()
}

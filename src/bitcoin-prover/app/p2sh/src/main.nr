mod constants;

use bvm::stack::{empty_stack_array, Stack};
use constants::{
    CODESEPARATOR_REDEEM_SCRIPT_SIZE, CODESEPARATOR_REDEEM_SCRIPT_SIZE_SIZE, CURRENT_TX_IN_COUNT,
    CURRENT_TX_IN_COUNT_SIZE, CURRENT_TX_IN_SIZE, CURRENT_TX_MAX_WITNESS_STACK_SIZE,
    CURRENT_TX_OUT_COUNT, CURRENT_TX_OUT_COUNT_SIZE, CURRENT_TX_OUT_SIZE, CURRENT_TX_SIZE,
    CURRENT_TX_WITNESS_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_SIZE, INPUT_WITNESS_SIZE,
    IS_CURRENT_SEGWIT, IS_PREV_SEGWIT, MAX_STACK_ELEMENT_SIZE, N_INPUT_SIZE, N_OUTPUT_SIZE,
    OPCODES_COUNT, PREV_TX_IN_COUNT, PREV_TX_IN_COUNT_SIZE, PREV_TX_IN_SIZE,
    PREV_TX_MAX_WITNESS_STACK_SIZE, PREV_TX_OUT_COUNT, PREV_TX_OUT_COUNT_SIZE, PREV_TX_OUT_SIZE,
    PREV_TX_SIZE, PREV_TX_WITNESS_SIZE, REDEEM_SCRIPT_OPCODES_COUNT, REDEEM_SCRIPT_SIZE,
    SCRIPT_PUB_KEY_SIZE, SCRIPT_SIG_SIZE, STACK_SIZE,
};
use script::execution::ScriptExecutionEngine;
use sign::{
    address::Address,
    compact_size::{self, u32_to_compact_size_array},
    transaction::Transaction,
};
use utils::convert::{hex_to_bytes, le_bytes_to_u32};

fn main(
    current_tx_data: str<CURRENT_TX_SIZE>,
    prev_tx_data: str<PREV_TX_SIZE>,
    script_sig: str<SCRIPT_SIG_SIZE>,
    input_to_sign: pub u32,
) -> pub bool {
    let current_tx_data = hex_to_bytes(current_tx_data);
    let prev_tx_data = hex_to_bytes(prev_tx_data);

    let current_tx = Transaction::<CURRENT_TX_SIZE / 2, CURRENT_TX_IN_COUNT, CURRENT_TX_IN_COUNT_SIZE, CURRENT_TX_IN_SIZE, CURRENT_TX_OUT_COUNT, CURRENT_TX_OUT_COUNT_SIZE, CURRENT_TX_OUT_SIZE, CURRENT_TX_MAX_WITNESS_STACK_SIZE, CURRENT_TX_WITNESS_SIZE>::new(
        current_tx_data,
        IS_CURRENT_SEGWIT,
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

    let mut redeem_script = [0; REDEEM_SCRIPT_SIZE];
    let mut codeseparator_redeem_script = [0; CODESEPARATOR_REDEEM_SCRIPT_SIZE];
    let script_sig_bytes = hex_to_bytes(script_sig);

    if IS_CURRENT_SEGWIT {
        assert(prev_tx.data[script_pub_key_pos] == 0);
        assert(SCRIPT_PUB_KEY_SIZE == 35);
        script_pub_key[0] = 168;
        for i in 1..34 {
            script_pub_key[i] = prev_tx.data[script_pub_key_pos + i];
        }
        script_pub_key[34] = 135;

        let size_offset = current_tx.witness.unwrap()[input_to_sign].stack_size.offset;
        let size = compact_size::get_compact_size(current_tx.data, size_offset);
        let size_u32 = compact_size::compact_size_to_u32(current_tx.data, size);

        let rds_offset =
            current_tx.witness.unwrap()[input_to_sign].items.get(size_u32 - 1).unwrap().item.offset;
        for i in 0..REDEEM_SCRIPT_SIZE {
            redeem_script[i] = current_tx.data[rds_offset + i];
        }
    } else {
        assert(SCRIPT_PUB_KEY_SIZE == 23);
        for i in 0..SCRIPT_PUB_KEY_SIZE {
            script_pub_key[i] = prev_tx.data[script_pub_key_pos + i];
        }

        for i in 0..REDEEM_SCRIPT_SIZE {
            redeem_script[REDEEM_SCRIPT_SIZE - 1 - i] =
                script_sig_bytes[(SCRIPT_SIG_SIZE / 2) - 1 - i];
        }
    }

    for i in 0..CODESEPARATOR_REDEEM_SCRIPT_SIZE {
        codeseparator_redeem_script[CODESEPARATOR_REDEEM_SCRIPT_SIZE - 1 - i] =
            redeem_script[REDEEM_SCRIPT_SIZE - 1 - i];
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

    let address = if IS_CURRENT_SEGWIT {
        Address::new_p2wsh()
    } else {
        Address::new_p2sh()
    };

    if IS_CURRENT_SEGWIT {
        let mut witness = [0; INPUT_WITNESS_SIZE];
        let witness_input_offset =
            current_tx.witness.unwrap()[input_to_sign].items.get(0).unwrap().size.offset;
        for i in 0..INPUT_WITNESS_SIZE {
            witness[i] = current_tx.data[witness_input_offset + i];
        }
        script_execution_engine.add_witness_to_stack(witness);
    } else {
        script_execution_engine
            .execute::<SCRIPT_SIG_SIZE / 2, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_SIZE, N_INPUT_SIZE, OPCODES_COUNT, 0, 0>(
                script_sig_bytes,
                address,
                [],
                Option::none(),
            );
    }

    script_execution_engine
        .execute::<SCRIPT_PUB_KEY_SIZE, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_SIZE, N_INPUT_SIZE, 3, 0, 0>(
            script_pub_key,
            address,
            [],
            Option::none(),
        );

    assert(script_execution_engine.stack.op_verify());

    script_execution_engine
        .execute::<REDEEM_SCRIPT_SIZE, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_SIZE, N_INPUT_SIZE, REDEEM_SCRIPT_OPCODES_COUNT, 0, 0>(
            redeem_script,
            address,
            [],
            Option::none(),
        );

    script_execution_engine.stack.op_verify()
}

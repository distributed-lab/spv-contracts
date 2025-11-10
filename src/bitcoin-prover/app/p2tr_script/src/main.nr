mod constants;

use bvm::stack::{empty_stack_array, Stack};
use constants::{
    CONTROL_BLOCK_SIZE, CURRENT_TX_IN_COUNT, CURRENT_TX_IN_COUNT_SIZE, CURRENT_TX_IN_SIZE,
    CURRENT_TX_MAX_WITNESS_STACK_SIZE, CURRENT_TX_OUT_COUNT, CURRENT_TX_OUT_COUNT_SIZE,
    CURRENT_TX_OUT_SIZE, CURRENT_TX_SIZE, CURRENT_TX_WITNESS_SIZE, INPUT_WITNESS_SIZE,
    IS_CURRENT_SEGWIT, IS_PREV_SEGWIT, MAX_STACK_ELEMENT_SIZE, N_OUTPUT_SIZE, PREV_TX_IN_COUNT,
    PREV_TX_IN_COUNT_SIZE, PREV_TX_IN_SIZE, PREV_TX_MAX_WITNESS_STACK_SIZE, PREV_TX_OUT_COUNT,
    PREV_TX_OUT_COUNT_SIZE, PREV_TX_OUT_SIZE, PREV_TX_SIZE, PREV_TX_WITNESS_SIZE,
    SCRIPT_OPCODES_COUNT, SCRIPT_SIZE, SCRIPT_SIZE_SIZE, STACK_SIZE, UTXOS_SIZE,
};
use crypto::{merkle::calc_merkle_root, point::check_tweaked_pub_key, schnorr::tagged_hash};
use script::execution::ScriptExecutionEngine;
use sign::{address::Address, compact_size::u32_to_compact_size_array, transaction::Transaction};
use utils::convert::{hex_to_bytes, le_bytes_to_u32};

// Script path spend
fn main(
    current_tx_data: str<CURRENT_TX_SIZE>,
    prev_tx_data: str<PREV_TX_SIZE>,
    utxos_data: [u8; UTXOS_SIZE],
    input_to_sign: pub u32,
) -> pub bool {
    assert(CONTROL_BLOCK_SIZE % 32 == 1);

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

    let vout_pos = current_tx.inputs[input_to_sign].vout.offset;
    let mut vout_bytes = [0; 4];
    for i in 0..4 {
        vout_bytes[i] = current_tx.data[vout_pos + i];
    }

    let vout = le_bytes_to_u32(vout_bytes);
    let script_pub_key_offset = prev_tx.outputs[vout].script_pub_key.offset;

    let mut tweaked_pub_key = [0; 32];

    for i in 0..32 {
        tweaked_pub_key[i] = prev_tx.data[script_pub_key_offset + i + 2];
    }

    let witness = current_tx.witness.unwrap()[input_to_sign].items;

    let mut script = [0; SCRIPT_SIZE];
    let script_offset = witness.get(witness.len() - 2).unwrap().item.offset;

    for i in 0..SCRIPT_SIZE {
        script[i] = current_tx.data[script_offset + i];
    }

    let mut control_block = [0; CONTROL_BLOCK_SIZE];
    let control_block_offset = witness.get(witness.len() - 1).unwrap().item.offset;

    for i in 0..CONTROL_BLOCK_SIZE {
        control_block[i] = current_tx.data[control_block_offset + i];
    }

    let is_even = (control_block[0] & 1) == 0;
    let script_version = control_block[0] - (!is_even) as u8;

    let mut pub_key_x = [0; 32];
    for i in 0..32 {
        pub_key_x[i] = control_block[i + 1];
    }

    // First hash in merkle path will be our script hash
    let mut merkle_path = [[0; 32]; (CONTROL_BLOCK_SIZE - 1) / 32];

    merkle_path[0] = tagged_hash(
        u32_to_compact_size_array::<SCRIPT_SIZE_SIZE>(SCRIPT_SIZE)
            .as_slice()
            .append(script)
            .push_front(script_version)
            .as_array::<1 + SCRIPT_SIZE + SCRIPT_SIZE_SIZE>(),
        "TapLeaf".as_bytes(),
    );

    for i in 0..((CONTROL_BLOCK_SIZE - 1) / 32 - 1) {
        for j in 0..32 {
            merkle_path[i + 1][j] = control_block[i * 32 + j + 33];
        }
    }

    let merkle_root = calc_merkle_root(merkle_path);

    assert(check_tweaked_pub_key(pub_key_x, is_even, merkle_root, tweaked_pub_key));

    let mut stack = Stack::new(
        current_tx,
        prev_tx,
        input_to_sign,
        vout,
        empty_stack_array::<MAX_STACK_ELEMENT_SIZE, STACK_SIZE>(),
        [],
    );

    let mut script_execution_engine = ScriptExecutionEngine::new(stack);

    let mut witness = [0; INPUT_WITNESS_SIZE];
    let witness_input_offset =
        current_tx.witness.unwrap()[input_to_sign].items.get(0).unwrap().size.offset;
    for i in 0..INPUT_WITNESS_SIZE {
        witness[i] = current_tx.data[witness_input_offset + i];
    }
    script_execution_engine.add_witness_to_stack(witness);

    script_execution_engine
        .execute::<SCRIPT_SIZE, N_OUTPUT_SIZE, 0, 0, 0, SCRIPT_OPCODES_COUNT, 0, UTXOS_SIZE>(
            script,
            Address::new_p2tr(),
            utxos_data,
            Option::some(merkle_path[0]),
        );

    script_execution_engine.stack.op_verify()
}

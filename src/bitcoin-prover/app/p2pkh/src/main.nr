mod constants;

use bvm::stack::{empty_stack_array, Stack};
use constants::{
    CURRENT_TX_IN_COUNT, CURRENT_TX_IN_COUNT_SIZE, CURRENT_TX_IN_SIZE,
    CURRENT_TX_MAX_WITNESS_STACK_SIZE, CURRENT_TX_OUT_COUNT, CURRENT_TX_OUT_COUNT_SIZE,
    CURRENT_TX_OUT_SIZE, CURRENT_TX_SIZE, CURRENT_TX_WITNESS_SIZE, INPUT_TO_SIGN,
    INPUT_TO_SIGN_SIZE, IS_CURRENT_SEGWIT, IS_PREV_SEGWIT, N_INPUT_SIZE, N_OUTPUT_SIZE,
    OPCODES_COUNT, PK_SIZE, PREV_TX_IN_COUNT, PREV_TX_IN_COUNT_SIZE, PREV_TX_IN_SIZE,
    PREV_TX_MAX_WITNESS_STACK_SIZE, PREV_TX_OUT_COUNT, PREV_TX_OUT_COUNT_SIZE, PREV_TX_OUT_SIZE,
    PREV_TX_SIZE, PREV_TX_WITNESS_SIZE, SCRIPT_SIG_SIZE, SIG_SIZE,
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

    let current_tx = Transaction::<CURRENT_TX_SIZE / 2, CURRENT_TX_IN_COUNT, CURRENT_TX_IN_COUNT_SIZE, CURRENT_TX_IN_SIZE, CURRENT_TX_OUT_COUNT, CURRENT_TX_OUT_COUNT_SIZE, CURRENT_TX_OUT_SIZE, CURRENT_TX_MAX_WITNESS_STACK_SIZE, CURRENT_TX_WITNESS_SIZE>::new(
        current_tx_data,
        IS_CURRENT_SEGWIT,
    );

    let prev_tx = Transaction::<PREV_TX_SIZE / 2, PREV_TX_IN_COUNT, PREV_TX_IN_COUNT_SIZE, PREV_TX_IN_SIZE, PREV_TX_OUT_COUNT, PREV_TX_OUT_COUNT_SIZE, PREV_TX_OUT_SIZE, PREV_TX_MAX_WITNESS_STACK_SIZE, PREV_TX_WITNESS_SIZE>::new(
        prev_tx_data,
        IS_PREV_SEGWIT,
    );

    let mut script_pub_key = [0; 25];

    let vout_pos = current_tx.inputs[input_to_sign].vout.offset;
    let mut vout_bytes = [0; 4];
    for i in 0..4 {
        vout_bytes[i] = current_tx.data[vout_pos + i];
    }

    let vout = le_bytes_to_u32(vout_bytes);
    let script_pub_key_pos = prev_tx.outputs[vout].script_pub_key.offset;

    let mut signature_bytes = [0; SIG_SIZE / 2];
    let mut pub_key_bytes = [0; PK_SIZE / 2];
    let script_sig_bytes = hex_to_bytes(script_sig);

    if IS_CURRENT_SEGWIT {
        let witness = current_tx.witness.unwrap()[input_to_sign];
        let sig_item = witness.items.get(0).unwrap().item;
        assert(sig_item.size == (SIG_SIZE / 2));
        let signature_bytes_offset = sig_item.offset;

        for i in 0..(SIG_SIZE / 2) {
            signature_bytes[i] = current_tx.data[signature_bytes_offset + i];
        }

        let pk_item = witness.items.get(1).unwrap().item;
        assert(pk_item.size == (PK_SIZE / 2));
        let pk_bytes_offset = pk_item.offset;

        for i in 0..(PK_SIZE / 2) {
            pub_key_bytes[i] = current_tx.data[pk_bytes_offset + i];
        }

        assert(prev_tx.data[script_pub_key_pos] == 0);
        script_pub_key[0] = 118;
        script_pub_key[1] = 169;
        script_pub_key[2] = 20;
        for i in 3..23 {
            script_pub_key[i] = prev_tx.data[script_pub_key_pos + i - 1];
        }
        script_pub_key[23] = 136;
        script_pub_key[24] = 172;
    } else {
        for i in 0..(SIG_SIZE / 2) {
            signature_bytes[i] = script_sig_bytes[i + 1];
        }
        for i in 0..(PK_SIZE / 2) {
            pub_key_bytes[i] = script_sig_bytes[(SIG_SIZE / 2) + i + 2];
        }
        for i in 0..25 {
            script_pub_key[i] = prev_tx.data[script_pub_key_pos + i];
        }
    }

    let mut stack = Stack::new(
        current_tx,
        prev_tx,
        input_to_sign,
        vout,
        empty_stack_array::<80, 7>(),
        [],
    );

    let mut script_execution_engine = ScriptExecutionEngine::new(stack);

    let script = [signature_bytes.len() as u8]
        .as_slice()
        .append(signature_bytes.as_slice())
        .push_back(pub_key_bytes.len() as u8)
        .append(pub_key_bytes.as_slice())
        .append(script_pub_key.as_slice())
        .as_array::<SIG_SIZE / 2 + PK_SIZE / 2 + 25 + 2>();

    let address = if IS_CURRENT_SEGWIT {
        Address::new_p2wpkh()
    } else {
        Address::new_p2pkh()
    };

    script_execution_engine
        .execute::<SIG_SIZE / 2 + PK_SIZE / 2 + 25 + 2, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_SIZE, N_INPUT_SIZE, OPCODES_COUNT, 26, 0>(
            script,
            address,
            [],
            Option::none(),
        );

    script_execution_engine.stack.op_verify()
}

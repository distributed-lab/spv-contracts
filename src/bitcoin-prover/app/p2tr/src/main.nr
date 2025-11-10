mod constants;

use constants::{
    CURRENT_TX_IN_COUNT, CURRENT_TX_IN_COUNT_SIZE, CURRENT_TX_IN_SIZE,
    CURRENT_TX_MAX_WITNESS_STACK_SIZE, CURRENT_TX_OUT_COUNT, CURRENT_TX_OUT_COUNT_SIZE,
    CURRENT_TX_OUT_SIZE, CURRENT_TX_SIZE, CURRENT_TX_WITNESS_SIZE, IS_CURRENT_SEGWIT,
    IS_PREV_SEGWIT, N_OUTPUT_SIZE, PREV_TX_IN_COUNT, PREV_TX_IN_COUNT_SIZE, PREV_TX_IN_SIZE,
    PREV_TX_MAX_WITNESS_STACK_SIZE, PREV_TX_OUT_COUNT, PREV_TX_OUT_COUNT_SIZE, PREV_TX_OUT_SIZE,
    PREV_TX_SIZE, PREV_TX_WITNESS_SIZE, SIGNATURE_SIZE, UTXOS_SIZE,
};
use crypto::schnorr::schnorr_verify;
use sign::{
    sig_types::{SIGHASH_ALL, SIGHASH_ANYONECANPAY, SIGHASH_NONE, SIGHASH_SINGLE},
    taproot::{
        parse_outputs, serialize_p2tr_sighash_all, serialize_p2tr_sighash_all_anyonecanpay,
        serialize_p2tr_sighash_none, serialize_p2tr_sighash_none_anyonecanpay,
        serialize_p2tr_sighash_single, serialize_p2tr_sighash_single_anyonecanpay,
    },
    transaction::Transaction,
};
use utils::convert::{hex_to_bytes, le_bytes_to_u32};

// Key path spend
fn main(
    current_tx_data: str<CURRENT_TX_SIZE>,
    prev_tx_data: str<PREV_TX_SIZE>,
    utxos_data: [u8; UTXOS_SIZE],
    input_to_sign: pub u32,
) -> pub bool {
    let current_tx_data = hex_to_bytes(current_tx_data);
    let prev_tx_data = hex_to_bytes(prev_tx_data);
    let utxos_pos = parse_outputs::<UTXOS_SIZE, CURRENT_TX_IN_COUNT>(utxos_data);

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
    let n_utxo_offset = prev_tx.outputs[vout].amount.offset;
    let script_pub_key_offset = prev_tx.outputs[vout].script_pub_key.offset;

    assert(script_pub_key_offset + prev_tx.outputs[vout].script_pub_key.size - n_utxo_offset == 43);

    // 8 + 1 + 34 (amount + spk_len + spk)
    let mut n_utxo = [0; 43];
    let mut pub_key = [0; 32];

    for i in 0..43 {
        n_utxo[i] = prev_tx.data[n_utxo_offset + i];
    }

    for i in 0..32 {
        pub_key[i] = prev_tx.data[script_pub_key_offset + i + 2];
    }

    let mut signature = [0; 64];
    let signature_offset =
        current_tx.witness.unwrap()[input_to_sign].items.get(0).unwrap().item.offset;

    for i in 0..64 {
        signature[i] = current_tx.data[signature_offset + i];
    }

    let sigtype = if SIGNATURE_SIZE == 64 {
        0x01
    } else {
        current_tx.data[signature_offset + 64]
    };

    let message = if sigtype == SIGHASH_ALL {
        serialize_p2tr_sighash_all(
            current_tx,
            input_to_sign,
            0,
            utxos_pos,
            utxos_data,
            Option::none(),
            Option::none(),
        )
    } else if sigtype == SIGHASH_NONE {
        serialize_p2tr_sighash_none(
            current_tx,
            input_to_sign,
            0,
            utxos_pos,
            utxos_data,
            Option::none(),
            Option::none(),
        )
    } else if sigtype == SIGHASH_SINGLE {
        serialize_p2tr_sighash_single::<CURRENT_TX_SIZE / 2, CURRENT_TX_IN_COUNT, CURRENT_TX_IN_COUNT_SIZE, CURRENT_TX_IN_SIZE, CURRENT_TX_OUT_COUNT, CURRENT_TX_OUT_COUNT_SIZE, CURRENT_TX_OUT_SIZE, CURRENT_TX_MAX_WITNESS_STACK_SIZE, CURRENT_TX_WITNESS_SIZE, UTXOS_SIZE, N_OUTPUT_SIZE>(
            current_tx,
            input_to_sign,
            0,
            utxos_pos,
            utxos_data,
            Option::none(),
            Option::none(),
        )
    } else if sigtype == (SIGHASH_ALL | SIGHASH_ANYONECANPAY) {
        serialize_p2tr_sighash_all_anyonecanpay(
            current_tx,
            input_to_sign,
            0,
            n_utxo,
            Option::none(),
            Option::none(),
        )
    } else if sigtype == (SIGHASH_NONE | SIGHASH_ANYONECANPAY) {
        serialize_p2tr_sighash_none_anyonecanpay(
            current_tx,
            input_to_sign,
            0,
            n_utxo,
            Option::none(),
            Option::none(),
        )
    } else if sigtype == (SIGHASH_SINGLE | SIGHASH_ANYONECANPAY) {
        serialize_p2tr_sighash_single_anyonecanpay::<CURRENT_TX_SIZE / 2, CURRENT_TX_IN_COUNT, CURRENT_TX_IN_COUNT_SIZE, CURRENT_TX_IN_SIZE, CURRENT_TX_OUT_COUNT, CURRENT_TX_OUT_COUNT_SIZE, CURRENT_TX_OUT_SIZE, CURRENT_TX_MAX_WITNESS_STACK_SIZE, CURRENT_TX_WITNESS_SIZE, N_OUTPUT_SIZE>(
            current_tx,
            input_to_sign,
            0,
            n_utxo,
            Option::none(),
            Option::none(),
        )
    } else {
        assert(false, "Unknown sighash type");
        [0; 32]
    };

    schnorr_verify(pub_key, message, signature)
}

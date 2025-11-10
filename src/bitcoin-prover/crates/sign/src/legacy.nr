use crate::transaction::Transaction;
use super::sig_types::{SIGHASH_ALL, SIGHASH_ANYONECANPAY, SIGHASH_NONE, SIGHASH_SINGLE};
use dep::bignum::{BigNum, U256};
use crypto::ecdsa::ecdsa_verify;
use utils::convert::{bytes_to_hex, hex_to_bytes, u32_to_le_bytes};

fn prepare_preimage_hash_for_sighash_all<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_PUB_KEY_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    script_pub_key: [u8; SCRIPT_PUB_KEY_SIZE],
) -> [u8; 4 + INPUT_SIZE + OUTPUT_SIZE + 4 + SCRIPT_PUB_KEY_SIZE + 4 - 1] {
    let mut data = [0; 4 + INPUT_SIZE + OUTPUT_SIZE + 4 + SCRIPT_PUB_KEY_SIZE + 4 - 1];
    let mut data_pos: u32 = 0;

    for i in 0..4 {
        data[data_pos] = transaction.data[i];
        data_pos += 1;
    }

    let mut transaction_offset = transaction.input_count.offset;
    let i_when_change_offset = transaction.inputs[input_to_sign].script_sig_size.offset;
    let i_change_offset = transaction.inputs[input_to_sign].script_sig_size.size;
    let mut data_pos_script_pub_key = 0;

    for i in 0..(INPUT_SIZE - 1) {
        if transaction_offset + i == i_when_change_offset {
            data_pos_script_pub_key = data_pos;
            data_pos += SCRIPT_PUB_KEY_SIZE;

            transaction_offset += i_change_offset;
        }

        data[data_pos] = transaction.data[transaction_offset + i];
        data_pos += 1;
    }

    if data_pos_script_pub_key != 0 {
        for j in 0..SCRIPT_PUB_KEY_SIZE {
            data[data_pos_script_pub_key + j] = script_pub_key[j];
        }
    }

    transaction_offset = transaction.output_count.offset;

    for i in 0..OUTPUT_SIZE {
        data[data_pos] = transaction.data[transaction_offset + i];
        data_pos += 1;
    }

    transaction_offset = transaction.output_count.offset + OUTPUT_SIZE + WITNESS_SIZE;

    for i in 0..4 {
        data[data_pos] = transaction.data[transaction_offset + i];
        data_pos += 1;
    }

    data[data_pos] = 0x01;
    data[data_pos + 1] = 0x00;
    data[data_pos + 2] = 0x00;
    data[data_pos + 3] = 0x00;

    data_pos += 4;

    assert(data_pos == 4 + INPUT_SIZE + OUTPUT_SIZE + 4 + SCRIPT_PUB_KEY_SIZE + 4 - 1);

    data
}

pub fn serialize_sighash_all<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_PUB_KEY_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    // script_pub_key should contain script_pub_key_size along with the script_pub_key
    script_pub_key: [u8; SCRIPT_PUB_KEY_SIZE],
) -> [u8; 32] {
    assert(input_to_sign < INPUT_COUNT);

    // The transaction should contain empty script_sigs
    for i in 0..INPUT_COUNT {
        assert(transaction.inputs[i].script_sig.size == 0);
    }

    let transaction_data =
        prepare_preimage_hash_for_sighash_all(transaction, input_to_sign, script_pub_key);

    let hashed_transaction = sha256::digest(sha256::digest(transaction_data));

    hashed_transaction
}

fn prepare_preimage_hash_for_sighash_all_anyonecanpay<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_PUB_KEY_SIZE: u32, let N_INPUT_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    script_pub_key: [u8; SCRIPT_PUB_KEY_SIZE],
) -> [u8; 4 + 1 + N_INPUT_SIZE + OUTPUT_SIZE + 4 + SCRIPT_PUB_KEY_SIZE + 4 - 1] {
    let mut data = [0; 4 + 1 + N_INPUT_SIZE + OUTPUT_SIZE + 4 + SCRIPT_PUB_KEY_SIZE + 4 - 1];
    let mut data_pos: u32 = 0;

    for i in 0..4 {
        data[data_pos] = transaction.data[i];
        data_pos += 1;
    }

    data[data_pos] = 1;
    data_pos += 1;

    let mut transaction_offset = transaction.inputs[input_to_sign].txid.offset;
    let mut data_pos_script_pub_key = 0;

    for i in 0..(N_INPUT_SIZE - 1) {
        if i == 36 {
            data_pos_script_pub_key = data_pos;
            data_pos += SCRIPT_PUB_KEY_SIZE;

            transaction_offset += 1;
        }

        data[data_pos] = transaction.data[transaction_offset + i];
        data_pos += 1;
    }

    if data_pos_script_pub_key != 0 {
        for j in 0..SCRIPT_PUB_KEY_SIZE {
            data[data_pos_script_pub_key + j] = script_pub_key[j];
        }
    }

    transaction_offset = transaction.output_count.offset;

    for i in 0..OUTPUT_SIZE {
        data[data_pos] = transaction.data[transaction_offset + i];
        data_pos += 1;
    }

    transaction_offset = transaction.output_count.offset + OUTPUT_SIZE + WITNESS_SIZE;

    for i in 0..4 {
        data[data_pos] = transaction.data[transaction_offset + i];
        data_pos += 1;
    }

    data[data_pos] = 0x81;
    data[data_pos + 1] = 0x00;
    data[data_pos + 2] = 0x00;
    data[data_pos + 3] = 0x00;

    data_pos += 4;

    assert(data_pos == 4 + 1 + N_INPUT_SIZE + OUTPUT_SIZE + 4 + SCRIPT_PUB_KEY_SIZE + 4 - 1);

    data
}

pub fn serialize_sighash_all_anyonecanpay<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_PUB_KEY_SIZE: u32, let N_INPUT_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    // script_pub_key should contain script_pub_key_size along with the script_pub_key
    script_pub_key: [u8; SCRIPT_PUB_KEY_SIZE],
) -> [u8; 32] {
    assert(input_to_sign < INPUT_COUNT);

    // The transaction should contain empty script_sigs
    for i in 0..INPUT_COUNT {
        assert(transaction.inputs[i].script_sig.size == 0);
    }

    let transaction_data = prepare_preimage_hash_for_sighash_all_anyonecanpay::<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE, SCRIPT_PUB_KEY_SIZE, N_INPUT_SIZE>(
        transaction,
        input_to_sign,
        script_pub_key,
    );

    let hashed_transaction = sha256::digest(sha256::digest(transaction_data));

    hashed_transaction
}

fn prepare_preimage_hash_for_sighash_single<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_PUB_KEY_SIZE: u32, let N_OUTPUT_SIZE: u32, let INPUT_TO_SIGN: u32, let INPUT_TO_SIGN_LEN: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    script_pub_key: [u8; SCRIPT_PUB_KEY_SIZE],
    ) -> [u8; 4 + INPUT_SIZE + INPUT_TO_SIGN_LEN + ((INPUT_TO_SIGN) * 9) + N_OUTPUT_SIZE + 4 + SCRIPT_PUB_KEY_SIZE + 4 - 1] {
    assert(input_to_sign == INPUT_TO_SIGN);

    let mut data = [
        0; 4
            + INPUT_SIZE
            + INPUT_TO_SIGN_LEN
            + ((INPUT_TO_SIGN) * 9)
            + N_OUTPUT_SIZE
            + 4
            + SCRIPT_PUB_KEY_SIZE
            + 4
            - 1
    ];
    let mut data_pos: u32 = 0;

    for i in 0..4 {
        data[data_pos] = transaction.data[i];
        data_pos += 1;
    }

    let mut transaction_offset = transaction.input_count.offset;
    let i_when_change_offset = transaction.inputs[input_to_sign].script_sig_size.offset;
    let i_change_offset = transaction.inputs[input_to_sign].script_sig_size.size;
    let mut data_pos_script_pub_key = 0;

    for i in 0..(INPUT_SIZE) {
        if transaction_offset + i == i_when_change_offset {
            data_pos_script_pub_key = data_pos;
            data_pos += SCRIPT_PUB_KEY_SIZE;

            transaction_offset += i_change_offset - 1;
        } else {
            if (i >= INPUT_COUNT_LEN) {
                if ((i - INPUT_COUNT_LEN) % 41 >= 36)
                    & ((i - INPUT_COUNT_LEN) % 41 < 41)
                    & ((i - INPUT_COUNT_LEN) / 41 != input_to_sign) {
                    data[data_pos] = 0;
                } else {
                    data[data_pos] = transaction.data[transaction_offset + i];
                }
            } else {
                data[data_pos] = transaction.data[transaction_offset + i];
            }
            data_pos += 1;
        }
    }

    if data_pos_script_pub_key != 0 {
        for j in 0..SCRIPT_PUB_KEY_SIZE {
            data[data_pos_script_pub_key + j] = script_pub_key[j];
        }
    }

    transaction_offset = transaction.output_count.offset;

    let len = u32_to_le_bytes(INPUT_TO_SIGN + 1);
    for i in 0..INPUT_TO_SIGN_LEN {
        data[data_pos] = len[i];
        data_pos += 1;
    }

    transaction_offset += INPUT_TO_SIGN_LEN;

    for _ in 0..(INPUT_TO_SIGN) {
        for _ in 0..8 {
            data[data_pos] = 0xff;
            data_pos += 1;
        }

        data[data_pos] = 0;
        data_pos += 1;
    }

    transaction_offset = transaction.outputs[input_to_sign].amount.offset;

    for i in 0..N_OUTPUT_SIZE {
        data[data_pos] = transaction.data[transaction_offset + i];
        data_pos += 1;
    }

    transaction_offset = transaction.lock_time.offset;

    for i in 0..4 {
        data[data_pos] = transaction.data[transaction_offset + i];
        data_pos += 1;
    }

    data[data_pos] = 0x03;
    data[data_pos + 1] = 0x00;
    data[data_pos + 2] = 0x00;
    data[data_pos + 3] = 0x00;

    data_pos += 4;

    assert(transaction_offset + 4 == TRANSACTION_SIZE);
    assert(
        data_pos
            == 4
                + INPUT_SIZE
                + INPUT_TO_SIGN_LEN
                + ((INPUT_TO_SIGN) * 9)
                + N_OUTPUT_SIZE
                + 4
                + SCRIPT_PUB_KEY_SIZE
                + 4
                - 1,
    );

    data
}

pub fn serialize_sighash_single<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_PUB_KEY_SIZE: u32, let N_OUTPUT_SIZE: u32, let INPUT_TO_SIGN: u32, let INPUT_TO_SIGN_LEN: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    // script_pub_key should contain script_pub_key_size along with the script_pub_key
    script_pub_key: [u8; SCRIPT_PUB_KEY_SIZE],
) -> [u8; 32] {
    assert(input_to_sign < INPUT_COUNT);
    assert(OUTPUT_COUNT > input_to_sign);

    // The transaction should contain empty script_sigs
    for i in 0..INPUT_COUNT {
        assert(transaction.inputs[i].script_sig.size == 0);
    }

    let transaction_data = prepare_preimage_hash_for_sighash_single::<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE, SCRIPT_PUB_KEY_SIZE, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN>(
        transaction,
        input_to_sign,
        script_pub_key,
    );

    let hashed_transaction = sha256::digest(sha256::digest(transaction_data));

    hashed_transaction
}

fn prepare_preimage_hash_for_sighash_single_anyonecanpay<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_PUB_KEY_SIZE: u32, let N_OUTPUT_SIZE: u32, let INPUT_TO_SIGN: u32, let INPUT_TO_SIGN_LEN: u32, let N_INPUT_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    script_pub_key: [u8; SCRIPT_PUB_KEY_SIZE],
    ) -> [u8; 4 + 1 + N_INPUT_SIZE + INPUT_TO_SIGN_LEN + ((INPUT_TO_SIGN) * 9) + N_OUTPUT_SIZE + 4 + SCRIPT_PUB_KEY_SIZE + 4 - 1] {
    assert(input_to_sign == INPUT_TO_SIGN);

    let mut data = [
        0; 4
            + 1
            + N_INPUT_SIZE
            + INPUT_TO_SIGN_LEN
            + ((INPUT_TO_SIGN) * 9)
            + N_OUTPUT_SIZE
            + 4
            + SCRIPT_PUB_KEY_SIZE
            + 4
            - 1
    ];
    let mut data_pos: u32 = 0;

    for i in 0..4 {
        data[data_pos] = transaction.data[i];
        data_pos += 1;
    }

    data[data_pos] = 1;
    data_pos += 1;

    let mut transaction_offset = transaction.inputs[input_to_sign].txid.offset;
    let mut data_pos_script_pub_key = 0;

    for i in 0..(N_INPUT_SIZE - 1) {
        if i == 36 {
            data_pos_script_pub_key = data_pos;
            data_pos += SCRIPT_PUB_KEY_SIZE;

            transaction_offset += 1;
        }

        data[data_pos] = transaction.data[transaction_offset + i];
        data_pos += 1;
    }

    if data_pos_script_pub_key != 0 {
        for j in 0..SCRIPT_PUB_KEY_SIZE {
            data[data_pos_script_pub_key + j] = script_pub_key[j];
        }
    }

    transaction_offset = transaction.output_count.offset;

    let len = u32_to_le_bytes(INPUT_TO_SIGN + 1);
    for i in 0..INPUT_TO_SIGN_LEN {
        data[data_pos] = len[i];
        data_pos += 1;
    }

    for _ in 0..(INPUT_TO_SIGN) {
        for _ in 0..8 {
            data[data_pos] = 0xff;
            data_pos += 1;
        }

        data[data_pos] = 0;
        data_pos += 1;
    }

    transaction_offset = transaction.outputs[input_to_sign].amount.offset;

    for i in 0..N_OUTPUT_SIZE {
        data[data_pos] = transaction.data[transaction_offset + i];
        data_pos += 1;
    }

    transaction_offset = transaction.lock_time.offset;

    for i in 0..4 {
        data[data_pos] = transaction.data[transaction_offset + i];
        data_pos += 1;
    }

    data[data_pos] = 0x83;
    data[data_pos + 1] = 0x00;
    data[data_pos + 2] = 0x00;
    data[data_pos + 3] = 0x00;

    data_pos += 4;

    assert(
        data_pos
            == 4
                + 1
                + N_INPUT_SIZE
                + INPUT_TO_SIGN_LEN
                + ((INPUT_TO_SIGN) * 9)
                + N_OUTPUT_SIZE
                + 4
                + SCRIPT_PUB_KEY_SIZE
                + 4
                - 1,
    );

    data
}

pub fn serialize_sighash_single_anyonecanpay<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_PUB_KEY_SIZE: u32, let N_OUTPUT_SIZE: u32, let INPUT_TO_SIGN: u32, let INPUT_TO_SIGN_LEN: u32, let N_INPUT_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    // script_pub_key should contain script_pub_key_size along with the script_pub_key
    script_pub_key: [u8; SCRIPT_PUB_KEY_SIZE],
) -> [u8; 32] {
    assert(input_to_sign < INPUT_COUNT);
    assert(OUTPUT_COUNT > input_to_sign);

    // The transaction should contain empty script_sigs
    for i in 0..INPUT_COUNT {
        assert(transaction.inputs[i].script_sig.size == 0);
    }

    let transaction_data = prepare_preimage_hash_for_sighash_single_anyonecanpay::<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE, SCRIPT_PUB_KEY_SIZE, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN, N_INPUT_SIZE>(
        transaction,
        input_to_sign,
        script_pub_key,
    );

    let hashed_transaction = sha256::digest(sha256::digest(transaction_data));

    hashed_transaction
}

fn prepare_preimage_hash_for_sighash_none<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_PUB_KEY_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    script_pub_key: [u8; SCRIPT_PUB_KEY_SIZE],
) -> [u8; 4 + INPUT_SIZE + 1 + 4 + SCRIPT_PUB_KEY_SIZE + 4 - 1] {
    let mut data = [0; 4 + INPUT_SIZE + 1 + 4 + SCRIPT_PUB_KEY_SIZE + 4 - 1];
    let mut data_pos: u32 = 0;

    for i in 0..4 {
        data[data_pos] = transaction.data[i];
        data_pos += 1;
    }

    let mut transaction_offset = transaction.input_count.offset;
    let i_when_change_offset = transaction.inputs[input_to_sign].script_sig_size.offset;
    let i_change_offset = transaction.inputs[input_to_sign].script_sig_size.size;
    let mut data_pos_script_pub_key = 0;

    for i in 0..(INPUT_SIZE) {
        if transaction_offset + i == i_when_change_offset {
            data_pos_script_pub_key = data_pos;
            data_pos += SCRIPT_PUB_KEY_SIZE;

            transaction_offset += i_change_offset - 1;
        } else {
            if (i >= INPUT_COUNT_LEN) {
                if ((i - INPUT_COUNT_LEN) % 41 >= 36)
                    & ((i - INPUT_COUNT_LEN) % 41 < 41)
                    & ((i - INPUT_COUNT_LEN) / 41 != input_to_sign) {
                    data[data_pos] = 0;
                } else {
                    data[data_pos] = transaction.data[transaction_offset + i];
                }
            } else {
                data[data_pos] = transaction.data[transaction_offset + i];
            }
            data_pos += 1;
        }
    }

    if data_pos_script_pub_key != 0 {
        for j in 0..SCRIPT_PUB_KEY_SIZE {
            data[data_pos_script_pub_key + j] = script_pub_key[j];
        }
    }

    data[data_pos] = 0;
    data_pos += 1;

    transaction_offset = transaction.output_count.offset + OUTPUT_SIZE + WITNESS_SIZE;

    for i in 0..4 {
        data[data_pos] = transaction.data[transaction_offset + i];
        data_pos += 1;
    }

    data[data_pos] = 0x02;
    data[data_pos + 1] = 0x00;
    data[data_pos + 2] = 0x00;
    data[data_pos + 3] = 0x00;

    data_pos += 4;

    assert(data_pos == 4 + INPUT_SIZE + 1 + 4 + SCRIPT_PUB_KEY_SIZE + 4 - 1);

    data
}

pub fn serialize_sighash_none<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_PUB_KEY_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    // script_pub_key should contain script_pub_key_size along with the script_pub_key
    script_pub_key: [u8; SCRIPT_PUB_KEY_SIZE],
) -> [u8; 32] {
    assert(input_to_sign < INPUT_COUNT);

    // The transaction should contain empty script_sigs
    for i in 0..INPUT_COUNT {
        assert(transaction.inputs[i].script_sig.size == 0);
    }

    let transaction_data =
        prepare_preimage_hash_for_sighash_none(transaction, input_to_sign, script_pub_key);

    let hashed_transaction = sha256::digest(sha256::digest(transaction_data));

    hashed_transaction
}

fn prepare_preimage_hash_for_sighash_none_anyonecanpay<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_PUB_KEY_SIZE: u32, let N_INPUT_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    script_pub_key: [u8; SCRIPT_PUB_KEY_SIZE],
) -> [u8; 4 + 1 + N_INPUT_SIZE + 1 + 4 + SCRIPT_PUB_KEY_SIZE + 4 - 1] {
    let mut data = [0; 4 + 1 + N_INPUT_SIZE + 1 + 4 + SCRIPT_PUB_KEY_SIZE + 4 - 1];
    let mut data_pos: u32 = 0;

    for i in 0..4 {
        data[data_pos] = transaction.data[i];
        data_pos += 1;
    }

    data[data_pos] = 1;
    data_pos += 1;

    let mut transaction_offset = transaction.inputs[input_to_sign].txid.offset;
    let mut data_pos_script_pub_key = 0;

    for i in 0..(N_INPUT_SIZE - 1) {
        if i == 36 {
            data_pos_script_pub_key = data_pos;
            data_pos += SCRIPT_PUB_KEY_SIZE;

            transaction_offset += 1;
        }

        data[data_pos] = transaction.data[transaction_offset + i];
        data_pos += 1;
    }

    if data_pos_script_pub_key != 0 {
        for j in 0..SCRIPT_PUB_KEY_SIZE {
            data[data_pos_script_pub_key + j] = script_pub_key[j];
        }
    }

    data[data_pos] = 0;
    data_pos += 1;

    transaction_offset = transaction.output_count.offset + OUTPUT_SIZE + WITNESS_SIZE;

    for i in 0..4 {
        data[data_pos] = transaction.data[transaction_offset + i];
        data_pos += 1;
    }

    data[data_pos] = 0x82;
    data[data_pos + 1] = 0x00;
    data[data_pos + 2] = 0x00;
    data[data_pos + 3] = 0x00;

    data_pos += 4;

    assert(data_pos == 4 + 1 + N_INPUT_SIZE + 1 + 4 + SCRIPT_PUB_KEY_SIZE + 4 - 1);

    data
}

pub fn serialize_sighash_none_anyonecanpay<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_PUB_KEY_SIZE: u32, let N_INPUT_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    // script_pub_key should contain script_pub_key_size along with the script_pub_key
    script_pub_key: [u8; SCRIPT_PUB_KEY_SIZE],
) -> [u8; 32] {
    assert(input_to_sign < INPUT_COUNT);

    // The transaction should contain empty script_sigs
    for i in 0..INPUT_COUNT {
        assert(transaction.inputs[i].script_sig.size == 0);
    }

    let transaction_data = prepare_preimage_hash_for_sighash_none_anyonecanpay::<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE, SCRIPT_PUB_KEY_SIZE, N_INPUT_SIZE>(
        transaction,
        input_to_sign,
        script_pub_key,
    );

    let hashed_transaction = sha256::digest(sha256::digest(transaction_data));

    hashed_transaction
}

pub fn serialize_sighash<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_PUB_KEY_SIZE: u32, let N_OUTPUT_SIZE: u32, let INPUT_TO_SIGN: u32, let INPUT_TO_SIGN_LEN: u32, let N_INPUT_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    script_pub_key: [u8; SCRIPT_PUB_KEY_SIZE],
    hash_type: u8,
) -> [u8; 32] {
    let mut hashed_transaction = [0 as u8; 32];

    if hash_type == SIGHASH_ALL {
        hashed_transaction = serialize_sighash_all(transaction, input_to_sign, script_pub_key);
    } else if hash_type == SIGHASH_NONE {
        hashed_transaction = serialize_sighash_none(transaction, input_to_sign, script_pub_key);
    } else if hash_type == SIGHASH_SINGLE {
        hashed_transaction = serialize_sighash_single::<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE, SCRIPT_PUB_KEY_SIZE, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN>(
            transaction,
            input_to_sign,
            script_pub_key,
        );
    } else if hash_type == (SIGHASH_ALL | SIGHASH_ANYONECANPAY) {
        hashed_transaction = serialize_sighash_all_anyonecanpay::<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE, SCRIPT_PUB_KEY_SIZE, N_INPUT_SIZE>(
            transaction,
            input_to_sign,
            script_pub_key,
        );
    } else if hash_type == (SIGHASH_NONE | SIGHASH_ANYONECANPAY) {
        hashed_transaction = serialize_sighash_none_anyonecanpay::<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE, SCRIPT_PUB_KEY_SIZE, N_INPUT_SIZE>(
            transaction,
            input_to_sign,
            script_pub_key,
        );
    } else if hash_type == (SIGHASH_SINGLE | SIGHASH_ANYONECANPAY) {
        hashed_transaction = serialize_sighash_single_anyonecanpay::<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE, SCRIPT_PUB_KEY_SIZE, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN, N_INPUT_SIZE>(
            transaction,
            input_to_sign,
            script_pub_key,
        );
    } else {
        assert(false, "Unsupported hash type");
    }

    hashed_transaction
}

#[test]
fn test_serialize_legacy_transaction_sighash_all() {
    let string = "0100000001b7994a0db2f373a29227e1d90da883c6ce1cb0dd2d6812e4558041ebbbcfa54b0000000000ffffffff01983a0000000000001976a914b3e2819b6262e0b1f19fc7229d75677f347c91ac88ac00000000";
    let bytes = hex_to_bytes(string);
    let transaction = Transaction::<85, 1, 1, 42, 1, 1, 35, 1, 0>::new(bytes, false);

    // script_pub_key should contain script_pub_key_size along with the script_pub_key
    let script_pub_key = "1976a9144299ff317fcd12ef19047df66d72454691797bfc88ac";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let sighash_all_transaction_bytes = serialize_sighash_all(transaction, 0, script_pub_key_bytes);

    let sighash_all_transaction = bytes_to_hex(sighash_all_transaction_bytes);

    assert(
        sighash_all_transaction
            == "a6b4103f527dfe43dfbadf530c247bac8a98b7463c7c6ad38eed97021d18ffcb",
    );
}

#[test]
fn test_serialize_segwit_transaction_sighash_all() {
    let string = "0200000000010192f29384a956361b9b9ebc667d01489cb360068c22c7b89396e5fdc3ece0305a0100000000ffffffff023d0500000000000016001464193f85b629823f114c9d997ee68627d7395d5fe7a1000000000000160014d0446764c4f16f78ca0ce0b7f487cc5fe205835e024730440220598ef97f63f7648e39d03ff58383056322fa13effaee8d11c9c9e8789a72522002204dda5bbc9cba008682d62820395a2c43b9abae52d6ad81835e72bda09468fa21012103d9a4d0bbe47d58b68e366a380107ba3470f6893764a2d020127d36c169df850100000000";
    let bytes = hex_to_bytes(string);
    let transaction = Transaction::<222, 1, 1, 42, 2, 1, 63, 2, 107>::new(bytes, true);
    let script_pub_key = "1976a9144299ff317fcd12ef19047df66d72454691797bfc88ac";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let sighash_all_transaction_bytes = serialize_sighash_all(transaction, 0, script_pub_key_bytes);

    let sighash_all_transaction = bytes_to_hex(sighash_all_transaction_bytes);

    assert(
        sighash_all_transaction
            == "39e3884c3761427b3a7eee244fc1495036a9f2dad35cfbfc0abbac2455f6bf26",
    );
}

#[test]
fn test_serialize_legacy_transaction_sighash_single() {
    let string = "02000000042800c7c57ee56571e1ebc62d1673645d7103700081355e88a44e688de8507ab00000000000feffffff693e2f55eb86baaeb48691e84e83664b7629042582adbb423019c1f03f1c214c0100000000feffffffa77204e95f097b656a9d3f4c4c8ec894a1e6ca333b47df95df09bbe3633f45890100000000feffffffc81c55dde094af8105d779fda708c890d62589765e4ae2e5661bbf0b681707af0000000000feffffff3b664f0200000000001600140d6c887ce96acf1fdd900f24f4e5cbffbef4683cb0710b00000000001976a914282f1a1a6c76f5f9940aa40e3ca09b85facd922c88ac40420f00000000001976a91486500a0985f14434f767fee4da715c7a67e1cce188ac405102210000000017a9146e852f1a9d1fccf7da065819ce55542bb9ccdfa5873db3570800000000160014b78900c011ded11218b13f3af1af5b482762bacd08cc27000000000017a9140c47ddbc001da63a8e3c47ace05325a0a3a2248087903a1c000000000016001489a0b00a0299ea359655e368c7394a68ac1ea7148cb892000000000017a91460e5317aeeca07d012730840a3a641825cff222587fced29000000000016001455f8875e8e7ce370f822fb76d617c1a3735d255fa4410b000000000017a9141b0dc97c864f220c84af2d60e9a821b8ded2fa26879a9b0e0000000000160014022d86804d210a4e44ddb15192a7bdca67e9bbc3b0e78f41000000001976a9141f6d21d6a58cf152d3960744977ee2eb2a58239088aca0c620000000000017a9145e73a81be9a705498c7319bf05c647327bfec07387b01df5050000000017a914478161dbe92d770ad21f1fd79af0723064ae998687e1390a000000000017a91470552d0cd63ad0ed22030790df1ef2b2a47c37508788800300000000001976a914555382e9e7a1140e1eecaced43059064a56e68ae88ac843e470300000000160014a206598ce0144bbeeb45b66ee96ba90e594435224081ba01000000001600140b552bf38e6084dd2856b85cc91e3a631b3b25caf4f8bd000000000017a9142fab6147bae49ebb8d7dfdf73528a9c5467286d987db593f01000000001600146c7da38e13f416b16b12f5e39d8ad1844eb5d07dec180b000000000017a9140e76e5497ab6cf6f356ba907055a0809ea396bfa87559b0c000000000017a914f71609e303b4afdb4fa1af11bfbd9f9517ce8b6e8770a733000000000017a914dde60ca59565ea983c4f7b5dc4b241430987f04587e7658e000000000017a9149ee281527918e4d57e8335cdbb756c7bc25c09db876ad8330100000000160014cba130d48a98bd131e47ae4e25cb68b9638cb4c890410600000000001976a9148ba0533632e72f430c364c84720fe4c62cdc94a788ac36c20e00000000001976a91468420a6c5e3524cf99e2ec0b0547ffddaef3d5a388ac60b6430000000000160014b6451a23679a56fb5bdded963b6ddfc22869150162d9160000000000160014d205e186b8fc9ad8823393005f91add2db6a0ba07fd718000000000017a914035581dcee5b8c99bdeb0315346084c4f6b9f12687ec150800000000001976a91471847c78e721932b42f16a07f765c0994d0cbeed88ac185405000000000017a91411a69f45f30e102ddc9887f1abe673bb46c468e9877ff401000000000017a9149c2416c89dad1ffc5519bef7657b812c41730d008766624802000000001976a914b324454aea1fedb0f47b413f83e955d2d2175fd288ac603402000000000017a914db7f315be90b7022f31270697564e1c7a994e9b687d2022e000000000017a9144ebd9d354be95f957014c7292d63821ec979a2bf87ea2af5050000000017a9142c5aaf32151fd602443d44113826d8ca9e8a96bd87379a6d000000000017a91466e2a13a1f13f312057a20c3911436a637fd414d87deec20000000000017a914daf439ba256c4b3261886e5db1d4e24c90958c86875b5b7f000000000017a914d3f8fed0bda74b23591306e05c801e211d9a8ace870c2165020000000017a91415ba3236b3cb38aeacfaa208ede807e1f95fb4228751fe85000000000017a9141df20c75511cd6d8b32ae23e05cd61cfc99ae79a87c429a5040000000017a914a795abce313485c1999296454ed2d7dd1fc1adc8872e2d0e000000000017a9145601d74f984dc80570a909f10b6e2ed3c7e9836a87b7d0cb040000000017a914cbb25f0ddc4255223569238a3ccac00ace9d9378876ac71a00000000001976a914fb2ee33468821beee7891b303576209182336b7c88ac21b08e00000000001976a914de8ed7b455e874c3c609c68e723842f3e4b430e388ac3b581900000000001600148a192ae515d9e2e9604de41a5482fb10a3a3a4a75b160b00000000001600140de7ededcc35cd084df364ee188c194424b3525532090100000000001976a914f27840ad766eeef816ecc5342daa0df56e481d7488ac64d9590000000000160014a419699c712f3fd08b0cbae10fbaf485fb69754fa19a270000000000160014841b80d2cc75f5345c482af96294d04fdd66b2b764a30200000000001976a9148c6579b5132af36fe33ee1af53b897d062182d9388ac94d815000000000017a914b6c3339f250048e3b17c28c39078c5cb4757cefb87b0a1cc1d0000000017a9147f15850f842a085a07d1e8fbcde07b6a298759f287b210fa08000000001976a9140fd2127de1ff592139ecb3e5284dd2e35463afb888ac8e8bab000000000017a914c92e69aa102c52359b891b002de9d63bc999cd2c87b0069a3b0000000017a91408845b275c33e8065b9e785d23717f8355d7b75587ab917e020000000017a91419519448c3667f647c2f2269e96820716cc32a528720610a00";
    let bytes = hex_to_bytes(string);
    let transaction = Transaction::<2073, 4, 1, 165, 59, 1, 1900, 0, 0>::new(bytes, false);

    // script_pub_key should contain script_pub_key_size along with the script_pub_key
    let script_pub_key = "1976a914e8cea30989bd15530f819b766684b00dc7ba7cfa88ac";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let sighash = serialize_sighash_single::<2073, 4, 1, 165, 59, 1, 1900, 0, 0, 26, 34, 1, 1>(
        transaction,
        1,
        script_pub_key_bytes,
    );

    assert(
        bytes_to_hex(sighash) == "bdc2a43eb83d308b13bb8003ab01ca6c9b098ddde5c762ca524600195a97bceb",
    );
}

// todo: Write proper test assertions - currently only checking that no panics occur
#[test]
fn test_serialize_legacy_transaction_sighash_none() {
    let string = "01000000056c499afac2e1a63bb6b9461a337319b970c13c2c77be53ebc1c7c870059334000800000000ffffffff00e16741107dcd7cfa2eaeb7d767e47edbec577511b3e10f16980754c3493b090900000000ffffffff078f6ec6d77fc7e0200e12fc1e2114e56e1c5bfc869d376a87b0a1bc5f8dc50e0800000000ffffffff64289405350c34a437566b764989b50381f68cf208531c54cb205f4e859e22100800000000ffffffff291cd5940ac16559eef5a2f2b4770271959f2007b45a0d850ef5d35d134df4100900000000ffffffff010000000000000000266a24e4b883e5bda9e7a59ee4bb99e9b1bcf09f909f426974636f696e20746f20506c75746f2100000000";
    let bytes = hex_to_bytes(string);
    let transaction = Transaction::<262, 5, 1, 206, 1, 1, 48, 1, 0>::new(bytes, false);

    // script_pub_key should contain script_pub_key_size along with the script_pub_key
    let script_pub_key = "1976a9140fb87a5071385b6976397d1c53ee16f09139a33488ac";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let sighash = serialize_sighash_none(transaction, 0, script_pub_key_bytes);

    assert(
        bytes_to_hex(sighash) == "809a85f9e793e9cb66866db039e8753402dcf6bc5b65893ffaccb2746e499ebe",
    );
}

// todo: Write proper test assertions - currently only checking that no panics occur
#[test]
fn test_serialize_legacy_transaction_sighash_all_anyonecanpay() {
    let string = "01000000056c499afac2e1a63bb6b9461a337319b970c13c2c77be53ebc1c7c870059334000800000000ffffffff00e16741107dcd7cfa2eaeb7d767e47edbec577511b3e10f16980754c3493b090900000000ffffffff078f6ec6d77fc7e0200e12fc1e2114e56e1c5bfc869d376a87b0a1bc5f8dc50e0800000000ffffffff64289405350c34a437566b764989b50381f68cf208531c54cb205f4e859e22100800000000ffffffff291cd5940ac16559eef5a2f2b4770271959f2007b45a0d850ef5d35d134df4100900000000ffffffff010000000000000000266a24e4b883e5bda9e7a59ee4bb99e9b1bcf09f909f426974636f696e20746f20506c75746f2100000000";
    let bytes = hex_to_bytes(string);
    let transaction = Transaction::<262, 5, 1, 206, 1, 1, 48, 1, 0>::new(bytes, false);

    // script_pub_key should contain script_pub_key_size along with the script_pub_key
    let script_pub_key = "1976a9140fb87a5071385b6976397d1c53ee16f09139a33488ac";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let sighash = serialize_sighash_all_anyonecanpay::<262, 5, 1, 206, 1, 1, 48, 1, 0, 26, 41>(
        transaction,
        0,
        script_pub_key_bytes,
    );

    assert(
        bytes_to_hex(sighash) == "376ce858de8118381de658dd3ad3e03b0b9f52931c75d40d5db37aa24a3e1a8b",
    );
}

// todo: Write proper test assertions - currently only checking that no panics occur
#[test]
fn test_serialize_legacy_transaction_sighash_single_anyonecanpay() {
    let string = "02000000042800c7c57ee56571e1ebc62d1673645d7103700081355e88a44e688de8507ab00000000000feffffff693e2f55eb86baaeb48691e84e83664b7629042582adbb423019c1f03f1c214c0100000000feffffffa77204e95f097b656a9d3f4c4c8ec894a1e6ca333b47df95df09bbe3633f45890100000000feffffffc81c55dde094af8105d779fda708c890d62589765e4ae2e5661bbf0b681707af0000000000feffffff3b664f0200000000001600140d6c887ce96acf1fdd900f24f4e5cbffbef4683cb0710b00000000001976a914282f1a1a6c76f5f9940aa40e3ca09b85facd922c88ac40420f00000000001976a91486500a0985f14434f767fee4da715c7a67e1cce188ac405102210000000017a9146e852f1a9d1fccf7da065819ce55542bb9ccdfa5873db3570800000000160014b78900c011ded11218b13f3af1af5b482762bacd08cc27000000000017a9140c47ddbc001da63a8e3c47ace05325a0a3a2248087903a1c000000000016001489a0b00a0299ea359655e368c7394a68ac1ea7148cb892000000000017a91460e5317aeeca07d012730840a3a641825cff222587fced29000000000016001455f8875e8e7ce370f822fb76d617c1a3735d255fa4410b000000000017a9141b0dc97c864f220c84af2d60e9a821b8ded2fa26879a9b0e0000000000160014022d86804d210a4e44ddb15192a7bdca67e9bbc3b0e78f41000000001976a9141f6d21d6a58cf152d3960744977ee2eb2a58239088aca0c620000000000017a9145e73a81be9a705498c7319bf05c647327bfec07387b01df5050000000017a914478161dbe92d770ad21f1fd79af0723064ae998687e1390a000000000017a91470552d0cd63ad0ed22030790df1ef2b2a47c37508788800300000000001976a914555382e9e7a1140e1eecaced43059064a56e68ae88ac843e470300000000160014a206598ce0144bbeeb45b66ee96ba90e594435224081ba01000000001600140b552bf38e6084dd2856b85cc91e3a631b3b25caf4f8bd000000000017a9142fab6147bae49ebb8d7dfdf73528a9c5467286d987db593f01000000001600146c7da38e13f416b16b12f5e39d8ad1844eb5d07dec180b000000000017a9140e76e5497ab6cf6f356ba907055a0809ea396bfa87559b0c000000000017a914f71609e303b4afdb4fa1af11bfbd9f9517ce8b6e8770a733000000000017a914dde60ca59565ea983c4f7b5dc4b241430987f04587e7658e000000000017a9149ee281527918e4d57e8335cdbb756c7bc25c09db876ad8330100000000160014cba130d48a98bd131e47ae4e25cb68b9638cb4c890410600000000001976a9148ba0533632e72f430c364c84720fe4c62cdc94a788ac36c20e00000000001976a91468420a6c5e3524cf99e2ec0b0547ffddaef3d5a388ac60b6430000000000160014b6451a23679a56fb5bdded963b6ddfc22869150162d9160000000000160014d205e186b8fc9ad8823393005f91add2db6a0ba07fd718000000000017a914035581dcee5b8c99bdeb0315346084c4f6b9f12687ec150800000000001976a91471847c78e721932b42f16a07f765c0994d0cbeed88ac185405000000000017a91411a69f45f30e102ddc9887f1abe673bb46c468e9877ff401000000000017a9149c2416c89dad1ffc5519bef7657b812c41730d008766624802000000001976a914b324454aea1fedb0f47b413f83e955d2d2175fd288ac603402000000000017a914db7f315be90b7022f31270697564e1c7a994e9b687d2022e000000000017a9144ebd9d354be95f957014c7292d63821ec979a2bf87ea2af5050000000017a9142c5aaf32151fd602443d44113826d8ca9e8a96bd87379a6d000000000017a91466e2a13a1f13f312057a20c3911436a637fd414d87deec20000000000017a914daf439ba256c4b3261886e5db1d4e24c90958c86875b5b7f000000000017a914d3f8fed0bda74b23591306e05c801e211d9a8ace870c2165020000000017a91415ba3236b3cb38aeacfaa208ede807e1f95fb4228751fe85000000000017a9141df20c75511cd6d8b32ae23e05cd61cfc99ae79a87c429a5040000000017a914a795abce313485c1999296454ed2d7dd1fc1adc8872e2d0e000000000017a9145601d74f984dc80570a909f10b6e2ed3c7e9836a87b7d0cb040000000017a914cbb25f0ddc4255223569238a3ccac00ace9d9378876ac71a00000000001976a914fb2ee33468821beee7891b303576209182336b7c88ac21b08e00000000001976a914de8ed7b455e874c3c609c68e723842f3e4b430e388ac3b581900000000001600148a192ae515d9e2e9604de41a5482fb10a3a3a4a75b160b00000000001600140de7ededcc35cd084df364ee188c194424b3525532090100000000001976a914f27840ad766eeef816ecc5342daa0df56e481d7488ac64d9590000000000160014a419699c712f3fd08b0cbae10fbaf485fb69754fa19a270000000000160014841b80d2cc75f5345c482af96294d04fdd66b2b764a30200000000001976a9148c6579b5132af36fe33ee1af53b897d062182d9388ac94d815000000000017a914b6c3339f250048e3b17c28c39078c5cb4757cefb87b0a1cc1d0000000017a9147f15850f842a085a07d1e8fbcde07b6a298759f287b210fa08000000001976a9140fd2127de1ff592139ecb3e5284dd2e35463afb888ac8e8bab000000000017a914c92e69aa102c52359b891b002de9d63bc999cd2c87b0069a3b0000000017a91408845b275c33e8065b9e785d23717f8355d7b75587ab917e020000000017a91419519448c3667f647c2f2269e96820716cc32a528720610a00";
    let bytes = hex_to_bytes(string);
    let transaction = Transaction::<2073, 4, 1, 165, 59, 1, 1900, 0, 0>::new(bytes, false);

    // script_pub_key should contain script_pub_key_size along with the script_pub_key
    let script_pub_key = "1976a914e8cea30989bd15530f819b766684b00dc7ba7cfa88ac";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let sighash = serialize_sighash_single_anyonecanpay::<2073, 4, 1, 165, 59, 1, 1900, 0, 0, 26, 34, 1, 1, 41>(
        transaction,
        1,
        script_pub_key_bytes,
    );

    assert(
        bytes_to_hex(sighash) == "e812aaac90b7bf21017dd3e6b543486efcfe276b0510dc05b8ad6f0a95da4023",
    );
}

// todo: Write proper test assertions - currently only checking that no panics occur
#[test]
fn test_serialize_legacy_transaction_sighash_none_anyonecanpay() {
    let string = "01000000056c499afac2e1a63bb6b9461a337319b970c13c2c77be53ebc1c7c870059334000800000000ffffffff00e16741107dcd7cfa2eaeb7d767e47edbec577511b3e10f16980754c3493b090900000000ffffffff078f6ec6d77fc7e0200e12fc1e2114e56e1c5bfc869d376a87b0a1bc5f8dc50e0800000000ffffffff64289405350c34a437566b764989b50381f68cf208531c54cb205f4e859e22100800000000ffffffff291cd5940ac16559eef5a2f2b4770271959f2007b45a0d850ef5d35d134df4100900000000ffffffff010000000000000000266a24e4b883e5bda9e7a59ee4bb99e9b1bcf09f909f426974636f696e20746f20506c75746f2100000000";
    let bytes = hex_to_bytes(string);
    let transaction = Transaction::<262, 5, 1, 206, 1, 1, 48, 1, 0>::new(bytes, false);

    // script_pub_key should contain script_pub_key_size along with the script_pub_key
    let script_pub_key = "1976a9140fb87a5071385b6976397d1c53ee16f09139a33488ac";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let sighash = serialize_sighash_none_anyonecanpay::<262, 5, 1, 206, 1, 1, 48, 1, 0, 26, 41>(
        transaction,
        0,
        script_pub_key_bytes,
    );

    assert(
        bytes_to_hex(sighash) == "35c22dea04126559fa211d7efd28c3bc16435d02e54f460d28c436d1c1a3c22f",
    );
}

use crate::legacy::Transaction;
use super::sig_types::{SIGHASH_ALL, SIGHASH_ANYONECANPAY, SIGHASH_NONE, SIGHASH_SINGLE};
use utils::convert::{bytes_to_hex, hex_to_bytes};

fn prepare_preimage_hash_for_sighash_all<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_CODE_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    script_code: [u8; SCRIPT_CODE_SIZE],
    prev_amount: [u8; 8],
) -> [u8; 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4] {
    let mut data = [0; 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4];
    let mut cur_pos = 0;

    // Version
    for i in 0..4 {
        data[cur_pos] = transaction.data[i];
        cur_pos += 1;
    }

    // Inputs ((txid, vout) + (txid, vout) + ...) hash
    let mut preimage_inputs = [0; INPUT_COUNT * (32 + 4)];
    for i in 0..INPUT_COUNT {
        let transaction_txid_offset = transaction.inputs[i].txid.offset;
        for j in 0..32 {
            preimage_inputs[i * (32 + 4) + j] = transaction.data[transaction_txid_offset + j];
        }

        let transaction_vout_offset = transaction.inputs[i].vout.offset;
        for j in 0..4 {
            preimage_inputs[i * (32 + 4) + 32 + j] = transaction.data[transaction_vout_offset + j];
        }
    }

    let inputs_hash = sha256::digest(sha256::digest(preimage_inputs));
    for i in 0..32 {
        data[cur_pos] = inputs_hash[i];
        cur_pos += 1;
    }

    // Sequences (sequence + sequence + ...) hash
    let mut preimage_sequences = [0; INPUT_COUNT * 4];
    for i in 0..INPUT_COUNT {
        let transaction_sequence_offset = transaction.inputs[i].sequence.offset;
        for j in 0..4 {
            preimage_sequences[i * 4 + j] = transaction.data[transaction_sequence_offset + j];
        }
    }

    let sequences_hash = sha256::digest(sha256::digest(preimage_sequences));
    for i in 0..32 {
        data[cur_pos] = sequences_hash[i];
        cur_pos += 1;
    }

    // Input to sign (txid, vout)
    let transaction_input_txid_offset = transaction.inputs[input_to_sign].txid.offset;
    for i in 0..32 {
        data[cur_pos] = transaction.data[transaction_input_txid_offset + i];
        cur_pos += 1;
    }

    let transaction_input_vout_offset = transaction.inputs[input_to_sign].vout.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_input_vout_offset + i];
        cur_pos += 1;
    }

    // Script code
    for i in 0..SCRIPT_CODE_SIZE {
        data[cur_pos] = script_code[i];
        cur_pos += 1;
    }

    // Previous amount
    for i in 0..8 {
        data[cur_pos] = prev_amount[i];
        cur_pos += 1;
    }

    // Sequence
    let transaction_input_sequence_offset = transaction.inputs[input_to_sign].sequence.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_input_sequence_offset + i];
        cur_pos += 1;
    }

    // Outputs
    let mut preimage_outputs = [0; OUTPUT_SIZE - OUTPUT_COUNT_LEN];

    let transaction_output_offset = transaction.output_count.offset + transaction.output_count.size;
    for i in 0..(OUTPUT_SIZE - OUTPUT_COUNT_LEN) {
        preimage_outputs[i] = transaction.data[transaction_output_offset + i];
    }

    let outputs_hash = sha256::digest(sha256::digest(preimage_outputs));
    for i in 0..32 {
        data[cur_pos] = outputs_hash[i];
        cur_pos += 1;
    }

    // Lock time
    let transaction_locktime_offset = transaction.lock_time.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_locktime_offset + i];
        cur_pos += 1;
    }

    // Hash type
    data[cur_pos] = 0x01;
    data[cur_pos + 1] = 0x00;
    data[cur_pos + 2] = 0x00;
    data[cur_pos + 3] = 0x00;
    cur_pos += 4;

    assert(cur_pos == 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4);

    data
}

fn prepare_preimage_hash_for_sighash_all_anyonecanpay<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_CODE_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    script_code: [u8; SCRIPT_CODE_SIZE],
    prev_amount: [u8; 8],
) -> [u8; 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4] {
    let mut data = [0; 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4];
    let mut cur_pos = 0;

    // Version
    for i in 0..4 {
        data[cur_pos] = transaction.data[i];
        cur_pos += 1;
    }

    // Inputs ((txid, vout) + (txid, vout) + ...) hash
    for _ in 0..32 {
        data[cur_pos] = 0;
        cur_pos += 1;
    }

    // Sequences (sequence + sequence + ...) hash
    for _ in 0..32 {
        data[cur_pos] = 0;
        cur_pos += 1;
    }

    // Input to sign (txid, vout)
    let transaction_input_txid_offset = transaction.inputs[input_to_sign].txid.offset;
    for i in 0..32 {
        data[cur_pos] = transaction.data[transaction_input_txid_offset + i];
        cur_pos += 1;
    }

    let transaction_input_vout_offset = transaction.inputs[input_to_sign].vout.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_input_vout_offset + i];
        cur_pos += 1;
    }

    // Script code
    for i in 0..SCRIPT_CODE_SIZE {
        data[cur_pos] = script_code[i];
        cur_pos += 1;
    }

    // Previous amount
    for i in 0..8 {
        data[cur_pos] = prev_amount[i];
        cur_pos += 1;
    }

    // Sequence
    let transaction_input_sequence_offset = transaction.inputs[input_to_sign].sequence.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_input_sequence_offset + i];
        cur_pos += 1;
    }

    // Outputs
    let mut preimage_outputs = [0; OUTPUT_SIZE - OUTPUT_COUNT_LEN];

    let transaction_output_offset = transaction.output_count.offset + transaction.output_count.size;
    for i in 0..(OUTPUT_SIZE - OUTPUT_COUNT_LEN) {
        preimage_outputs[i] = transaction.data[transaction_output_offset + i];
    }

    let outputs_hash = sha256::digest(sha256::digest(preimage_outputs));
    for i in 0..32 {
        data[cur_pos] = outputs_hash[i];
        cur_pos += 1;
    }

    // Lock time
    let transaction_locktime_offset = transaction.lock_time.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_locktime_offset + i];
        cur_pos += 1;
    }

    // Hash type
    data[cur_pos] = 0x81;
    data[cur_pos + 1] = 0x00;
    data[cur_pos + 2] = 0x00;
    data[cur_pos + 3] = 0x00;
    cur_pos += 4;

    assert(cur_pos == 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4);

    data
}

fn prepare_preimage_hash_for_sighash_none<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_CODE_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    script_code: [u8; SCRIPT_CODE_SIZE],
    prev_amount: [u8; 8],
) -> [u8; 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4] {
    let mut data = [0; 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4];
    let mut cur_pos = 0;

    // Version
    for i in 0..4 {
        data[cur_pos] = transaction.data[i];
        cur_pos += 1;
    }

    // Inputs ((txid, vout) + (txid, vout) + ...) hash
    let mut preimage_inputs = [0; INPUT_COUNT * (32 + 4)];
    for i in 0..INPUT_COUNT {
        let transaction_txid_offset = transaction.inputs[i].txid.offset;
        for j in 0..32 {
            preimage_inputs[i * (32 + 4) + j] = transaction.data[transaction_txid_offset + j];
        }

        let transaction_vout_offset = transaction.inputs[i].vout.offset;
        for j in 0..4 {
            preimage_inputs[i * (32 + 4) + 32 + j] = transaction.data[transaction_vout_offset + j];
        }
    }

    let inputs_hash = sha256::digest(sha256::digest(preimage_inputs));
    for i in 0..32 {
        data[cur_pos] = inputs_hash[i];
        cur_pos += 1;
    }

    // Sequences (sequence + sequence + ...) hash
    // let mut preimage_sequences = [0; INPUT_COUNT * 4];
    // for i in 0..INPUT_COUNT {
    //     let transaction_sequence_offset = transaction.inputs[i].sequence.offset;
    //     for j in 0..4 {
    //         preimage_sequences[i * 4 + j] = transaction.data[transaction_sequence_offset + j];
    //     }
    // }

    // let sequences_hash = sha256::digest(sha256::digest(preimage_sequences));
    // for i in 0..32 {
    //     data[cur_pos] = sequences_hash[i];
    //     cur_pos += 1;
    // }
    cur_pos += 32;

    // Input to sign (txid, vout)
    let transaction_input_txid_offset = transaction.inputs[input_to_sign].txid.offset;
    for i in 0..32 {
        data[cur_pos] = transaction.data[transaction_input_txid_offset + i];
        cur_pos += 1;
    }

    let transaction_input_vout_offset = transaction.inputs[input_to_sign].vout.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_input_vout_offset + i];
        cur_pos += 1;
    }

    // Script code
    for i in 0..SCRIPT_CODE_SIZE {
        data[cur_pos] = script_code[i];
        cur_pos += 1;
    }

    // Previous amount
    for i in 0..8 {
        data[cur_pos] = prev_amount[i];
        cur_pos += 1;
    }

    // Sequence
    let transaction_input_sequence_offset = transaction.inputs[input_to_sign].sequence.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_input_sequence_offset + i];
        cur_pos += 1;
    }

    // Outputs
    cur_pos += 32;

    // Lock time
    let transaction_locktime_offset = transaction.lock_time.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_locktime_offset + i];
        cur_pos += 1;
    }

    // Hash type
    data[cur_pos] = 0x02;
    data[cur_pos + 1] = 0x00;
    data[cur_pos + 2] = 0x00;
    data[cur_pos + 3] = 0x00;
    cur_pos += 4;

    assert(cur_pos == 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4);

    data
}

fn prepare_preimage_hash_for_sighash_none_anyonecanpay<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_CODE_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    script_code: [u8; SCRIPT_CODE_SIZE],
    prev_amount: [u8; 8],
) -> [u8; 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4] {
    let mut data = [0; 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4];
    let mut cur_pos = 0;

    // Version
    for i in 0..4 {
        data[cur_pos] = transaction.data[i];
        cur_pos += 1;
    }

    // Inputs ((txid, vout) + (txid, vout) + ...) hash
    cur_pos += 32;

    // Sequences (sequence + sequence + ...) hash
    cur_pos += 32;

    // Input to sign (txid, vout)
    let transaction_input_txid_offset = transaction.inputs[input_to_sign].txid.offset;
    for i in 0..32 {
        data[cur_pos] = transaction.data[transaction_input_txid_offset + i];
        cur_pos += 1;
    }

    let transaction_input_vout_offset = transaction.inputs[input_to_sign].vout.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_input_vout_offset + i];
        cur_pos += 1;
    }

    // Script code
    for i in 0..SCRIPT_CODE_SIZE {
        data[cur_pos] = script_code[i];
        cur_pos += 1;
    }

    // Previous amount
    for i in 0..8 {
        data[cur_pos] = prev_amount[i];
        cur_pos += 1;
    }

    // Sequence
    let transaction_input_sequence_offset = transaction.inputs[input_to_sign].sequence.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_input_sequence_offset + i];
        cur_pos += 1;
    }

    // Outputs
    cur_pos += 32;

    // Lock time
    let transaction_locktime_offset = transaction.lock_time.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_locktime_offset + i];
        cur_pos += 1;
    }

    // Hash type
    data[cur_pos] = 0x82;
    data[cur_pos + 1] = 0x00;
    data[cur_pos + 2] = 0x00;
    data[cur_pos + 3] = 0x00;
    cur_pos += 4;

    assert(cur_pos == 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4);

    data
}

fn prepare_preimage_hash_for_sighash_single<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_CODE_SIZE: u32, let N_OUTPUT_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    script_code: [u8; SCRIPT_CODE_SIZE],
    prev_amount: [u8; 8],
) -> [u8; 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4] {
    let mut data = [0; 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4];
    let mut cur_pos = 0;

    // Version
    for i in 0..4 {
        data[cur_pos] = transaction.data[i];
        cur_pos += 1;
    }

    // Inputs ((txid, vout) + (txid, vout) + ...) hash
    let mut preimage_inputs = [0; INPUT_COUNT * (32 + 4)];
    for i in 0..INPUT_COUNT {
        let transaction_txid_offset = transaction.inputs[i].txid.offset;
        for j in 0..32 {
            preimage_inputs[i * (32 + 4) + j] = transaction.data[transaction_txid_offset + j];
        }

        let transaction_vout_offset = transaction.inputs[i].vout.offset;
        for j in 0..4 {
            preimage_inputs[i * (32 + 4) + 32 + j] = transaction.data[transaction_vout_offset + j];
        }
    }

    let inputs_hash = sha256::digest(sha256::digest(preimage_inputs));
    for i in 0..32 {
        data[cur_pos] = inputs_hash[i];
        cur_pos += 1;
    }

    // Sequences (sequence + sequence + ...) hash
    // let mut preimage_sequences = [0; INPUT_COUNT * 4];
    // for i in 0..INPUT_COUNT {
    //     let transaction_sequence_offset = transaction.inputs[i].sequence.offset;
    //     for j in 0..4 {
    //         preimage_sequences[i * 4 + j] = transaction.data[transaction_sequence_offset + j];
    //     }
    // }

    // let sequences_hash = sha256::digest(sha256::digest(preimage_sequences));
    // for i in 0..32 {
    //     data[cur_pos] = sequences_hash[i];
    //     cur_pos += 1;
    // }
    cur_pos += 32;

    // Input to sign (txid, vout)
    let transaction_input_txid_offset = transaction.inputs[input_to_sign].txid.offset;
    for i in 0..32 {
        data[cur_pos] = transaction.data[transaction_input_txid_offset + i];
        cur_pos += 1;
    }

    let transaction_input_vout_offset = transaction.inputs[input_to_sign].vout.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_input_vout_offset + i];
        cur_pos += 1;
    }

    // Script code
    for i in 0..SCRIPT_CODE_SIZE {
        data[cur_pos] = script_code[i];
        cur_pos += 1;
    }

    // Previous amount
    for i in 0..8 {
        data[cur_pos] = prev_amount[i];
        cur_pos += 1;
    }

    // Sequence
    let transaction_input_sequence_offset = transaction.inputs[input_to_sign].sequence.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_input_sequence_offset + i];
        cur_pos += 1;
    }

    // Outputs
    let mut outputs_hash = [0 as u8; 32];

    if input_to_sign < OUTPUT_COUNT {
        let mut preimage_outputs = [0; N_OUTPUT_SIZE];

        let transaction_output_offset = transaction.outputs[input_to_sign].amount.offset;
        for i in 0..(N_OUTPUT_SIZE) {
            preimage_outputs[i] = transaction.data[transaction_output_offset + i];
        }
        outputs_hash = sha256::digest(sha256::digest(preimage_outputs));
    } else {
        let mut preimage_outputs = [0; OUTPUT_SIZE - OUTPUT_COUNT_LEN];

        let transaction_output_offset =
            transaction.output_count.offset + transaction.output_count.size;
        for i in 0..(OUTPUT_SIZE - OUTPUT_COUNT_LEN) {
            preimage_outputs[i] = transaction.data[transaction_output_offset + i];
        }
        outputs_hash = sha256::digest(sha256::digest(preimage_outputs));
    }
    for i in 0..32 {
        data[cur_pos] = outputs_hash[i];
        cur_pos += 1;
    }
    // Lock time
    let transaction_locktime_offset = transaction.lock_time.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_locktime_offset + i];
        cur_pos += 1;
    }

    // Hash type
    data[cur_pos] = 0x03;
    data[cur_pos + 1] = 0x00;
    data[cur_pos + 2] = 0x00;
    data[cur_pos + 3] = 0x00;
    cur_pos += 4;

    assert(cur_pos == 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4);

    data
}

fn prepare_preimage_hash_for_sighash_single_anyonecanpay<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_CODE_SIZE: u32, let N_OUTPUT_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    script_code: [u8; SCRIPT_CODE_SIZE],
    prev_amount: [u8; 8],
) -> [u8; 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4] {
    let mut data = [0; 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4];
    let mut cur_pos = 0;

    // Version
    for i in 0..4 {
        data[cur_pos] = transaction.data[i];
        cur_pos += 1;
    }

    // Inputs ((txid, vout) + (txid, vout) + ...) hash
    cur_pos += 32;

    // Sequences (sequence + sequence + ...) hash
    cur_pos += 32;

    // Input to sign (txid, vout)
    let transaction_input_txid_offset = transaction.inputs[input_to_sign].txid.offset;
    for i in 0..32 {
        data[cur_pos] = transaction.data[transaction_input_txid_offset + i];
        cur_pos += 1;
    }

    let transaction_input_vout_offset = transaction.inputs[input_to_sign].vout.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_input_vout_offset + i];
        cur_pos += 1;
    }

    // Script code
    for i in 0..SCRIPT_CODE_SIZE {
        data[cur_pos] = script_code[i];
        cur_pos += 1;
    }

    // Previous amount
    for i in 0..8 {
        data[cur_pos] = prev_amount[i];
        cur_pos += 1;
    }

    // Sequence
    let transaction_input_sequence_offset = transaction.inputs[input_to_sign].sequence.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_input_sequence_offset + i];
        cur_pos += 1;
    }

    // Outputs
    let mut outputs_hash = [0 as u8; 32];

    if input_to_sign < OUTPUT_COUNT {
        let mut preimage_outputs = [0; N_OUTPUT_SIZE];

        let transaction_output_offset = transaction.outputs[input_to_sign].amount.offset;
        for i in 0..(N_OUTPUT_SIZE) {
            preimage_outputs[i] = transaction.data[transaction_output_offset + i];
        }
        outputs_hash = sha256::digest(sha256::digest(preimage_outputs));
    } else {
        let mut preimage_outputs = [0; OUTPUT_SIZE - OUTPUT_COUNT_LEN];

        let transaction_output_offset =
            transaction.output_count.offset + transaction.output_count.size;
        for i in 0..(OUTPUT_SIZE - OUTPUT_COUNT_LEN) {
            preimage_outputs[i] = transaction.data[transaction_output_offset + i];
        }
        outputs_hash = sha256::digest(sha256::digest(preimage_outputs));
    }

    for i in 0..32 {
        data[cur_pos] = outputs_hash[i];
        cur_pos += 1;
    }

    // Lock time
    let transaction_locktime_offset = transaction.lock_time.offset;
    for i in 0..4 {
        data[cur_pos] = transaction.data[transaction_locktime_offset + i];
        cur_pos += 1;
    }

    // Hash type
    data[cur_pos] = 0x83;
    data[cur_pos + 1] = 0x00;
    data[cur_pos + 2] = 0x00;
    data[cur_pos + 3] = 0x00;
    cur_pos += 4;

    assert(cur_pos == 4 + 32 + 32 + (32 + 4) + SCRIPT_CODE_SIZE + 8 + 4 + 32 + 4 + 4);

    data
}

// 0x1976a914<public_key_hash>88ac
fn create_p2wpkh_script_code(public_key_hash: [u8; 20]) -> [u8; 26] {
    let mut script_code = [0; 26];
    script_code[0] = 0x19;
    script_code[1] = 0x76;
    script_code[2] = 0xa9;
    script_code[3] = 0x14;
    for i in 0..20 {
        script_code[i + 4] = public_key_hash[i];
    }
    script_code[24] = 0x88;
    script_code[25] = 0xac;

    script_code
}

pub fn serialize_p2wpkh_sighash_all<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    prev_amount: [u8; 8],
    script_code: [u8; 26],
) -> [u8; 32] {
    let preimage_data =
        prepare_preimage_hash_for_sighash_all(transaction, input_to_sign, script_code, prev_amount);

    let sighash_all = sha256::digest(sha256::digest(preimage_data));

    sighash_all
}

pub fn serialize_p2wpkh_sighash_all_anyonecanpay<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    prev_amount: [u8; 8],
    script_code: [u8; 26],
) -> [u8; 32] {
    let preimage_data = prepare_preimage_hash_for_sighash_all_anyonecanpay(
        transaction,
        input_to_sign,
        script_code,
        prev_amount,
    );

    let sighash_all = sha256::digest(sha256::digest(preimage_data));

    sighash_all
}

pub fn serialize_p2wpkh_sighash_none<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    prev_amount: [u8; 8],
    script_code: [u8; 26],
) -> [u8; 32] {
    let preimage_data = prepare_preimage_hash_for_sighash_none(
        transaction,
        input_to_sign,
        script_code,
        prev_amount,
    );

    let sighash_none = sha256::digest(sha256::digest(preimage_data));
    sighash_none
}

pub fn serialize_p2wpkh_sighash_none_anyonecanpay<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    prev_amount: [u8; 8],
    script_code: [u8; 26],
) -> [u8; 32] {
    let preimage_data = prepare_preimage_hash_for_sighash_none_anyonecanpay(
        transaction,
        input_to_sign,
        script_code,
        prev_amount,
    );
    let sighash_none = sha256::digest(sha256::digest(preimage_data));

    sighash_none
}

pub fn serialize_p2wpkh_sighash_single<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let N_OUTPUT_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    prev_amount: [u8; 8],
    script_code: [u8; 26],
) -> [u8; 32] {
    let preimage_data = prepare_preimage_hash_for_sighash_single::<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE, 26, N_OUTPUT_SIZE>(
        transaction,
        input_to_sign,
        script_code,
        prev_amount,
    );

    let sighash = sha256::digest(sha256::digest(preimage_data));
    sighash
}

pub fn serialize_p2wpkh_sighash_single_anyonecanpay<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let N_OUTPUT_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    prev_amount: [u8; 8],
    script_code: [u8; 26],
) -> [u8; 32] {
    let preimage_data = prepare_preimage_hash_for_sighash_single_anyonecanpay::<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE, 26, N_OUTPUT_SIZE>(
        transaction,
        input_to_sign,
        script_code,
        prev_amount,
    );
    let sighash = sha256::digest(sha256::digest(preimage_data));

    sighash
}

pub fn serialize_p2wsh_sighash_all<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_CODE_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    prev_amount: [u8; 8],
    script_code: [u8; SCRIPT_CODE_SIZE],
) -> [u8; 32] {
    let preimage_data =
        prepare_preimage_hash_for_sighash_all(transaction, input_to_sign, script_code, prev_amount);

    let sighash_all = sha256::digest(sha256::digest(preimage_data));

    sighash_all
}

pub fn serialize_p2wsh_sighash_all_anyonecanpay<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_CODE_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    prev_amount: [u8; 8],
    script_code: [u8; SCRIPT_CODE_SIZE],
) -> [u8; 32] {
    let preimage_data = prepare_preimage_hash_for_sighash_all_anyonecanpay(
        transaction,
        input_to_sign,
        script_code,
        prev_amount,
    );

    let sighash_all = sha256::digest(sha256::digest(preimage_data));

    sighash_all
}

pub fn serialize_p2wsh_sighash_none<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_CODE_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    prev_amount: [u8; 8],
    script_code: [u8; SCRIPT_CODE_SIZE],
) -> [u8; 32] {
    let preimage_data = prepare_preimage_hash_for_sighash_none(
        transaction,
        input_to_sign,
        script_code,
        prev_amount,
    );

    let sighash_none = sha256::digest(sha256::digest(preimage_data));
    sighash_none
}

pub fn serialize_p2wsh_sighash_none_anyonecanpay<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_CODE_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    prev_amount: [u8; 8],
    script_code: [u8; SCRIPT_CODE_SIZE],
) -> [u8; 32] {
    let preimage_data = prepare_preimage_hash_for_sighash_none_anyonecanpay(
        transaction,
        input_to_sign,
        script_code,
        prev_amount,
    );
    let sighash_none = sha256::digest(sha256::digest(preimage_data));

    sighash_none
}

pub fn serialize_p2wsh_sighash_single<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_CODE_SIZE: u32, let N_OUTPUT_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    prev_amount: [u8; 8],
    script_code: [u8; SCRIPT_CODE_SIZE],
) -> [u8; 32] {
    let preimage_data = prepare_preimage_hash_for_sighash_single::<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE, SCRIPT_CODE_SIZE, N_OUTPUT_SIZE>(
        transaction,
        input_to_sign,
        script_code,
        prev_amount,
    );

    let sighash = sha256::digest(sha256::digest(preimage_data));
    sighash
}

pub fn serialize_p2wsh_sighash_single_anyonecanpay<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32, let SCRIPT_CODE_SIZE: u32, let N_OUTPUT_SIZE: u32>(
    transaction: Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE>,
    input_to_sign: u32,
    prev_amount: [u8; 8],
    script_code: [u8; SCRIPT_CODE_SIZE],
) -> [u8; 32] {
    let preimage_data = prepare_preimage_hash_for_sighash_single_anyonecanpay::<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE, SCRIPT_CODE_SIZE, N_OUTPUT_SIZE>(
        transaction,
        input_to_sign,
        script_code,
        prev_amount,
    );
    let sighash = sha256::digest(sha256::digest(preimage_data));

    sighash
}

#[test]
fn test_serialize_p2wpkh_sighash_all() {
    let hex_string = "02000000000101ac4994014aa36b7f53375658ef595b3cb2891e1735fe5b441686f5e53338e76a0100000000ffffffff01204e0000000000001976a914ce72abfd0e6d9354a660c18f2825eb392f060fdc88ac0000000000";
    let bytes = hex_to_bytes(hex_string);
    let transaction = Transaction::<88, 1, 1, 42, 1, 1, 35, 1, 1>::new(bytes, true);

    let script_pub_key = "1976a914aa966f56de599b4094b61aa68a2b3df9e97e9c4888ac";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let prev_amount_hex = "3075000000000000";
    let prev_amount_bytes = hex_to_bytes(prev_amount_hex);

    let sighash_all_transaction_bytes =
        serialize_p2wpkh_sighash_all(transaction, 0, prev_amount_bytes, script_pub_key_bytes);

    let sighash_all_transaction = bytes_to_hex(sighash_all_transaction_bytes);

    assert(
        sighash_all_transaction
            == "d7b60220e1b9b2c1ab40845118baf515203f7b6f0ad83cbb68d3c89b5b3098a6",
    );
}

#[test]
fn test_serialize_p2wpkh_sighash_all_anyonecanpay() {
    let hex_string = "02000000000101ac4994014aa36b7f53375658ef595b3cb2891e1735fe5b441686f5e53338e76a0100000000ffffffff01204e0000000000001976a914ce72abfd0e6d9354a660c18f2825eb392f060fdc88ac0000000000";
    let bytes = hex_to_bytes(hex_string);
    let transaction = Transaction::<88, 1, 1, 42, 1, 1, 35, 1, 1>::new(bytes, true);

    let script_pub_key = "1976a914aa966f56de599b4094b61aa68a2b3df9e97e9c4888ac";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let prev_amount_hex = "3075000000000000";
    let prev_amount_bytes = hex_to_bytes(prev_amount_hex);

    let sighash_all_transaction_bytes = serialize_p2wpkh_sighash_all_anyonecanpay(
        transaction,
        0,
        prev_amount_bytes,
        script_pub_key_bytes,
    );

    let sighash_all_transaction = bytes_to_hex(sighash_all_transaction_bytes);

    assert(
        sighash_all_transaction
            == "d74d6caf8ee5103748ee3c5abc645decf5b893a494fdd38dc161d9bd306c357b",
    );
}

#[test]
fn test_serialize_p2wpkh_sighash_none() {
    let hex_string = "02000000000101ac4994014aa36b7f53375658ef595b3cb2891e1735fe5b441686f5e53338e76a0100000000ffffffff01204e0000000000001976a914ce72abfd0e6d9354a660c18f2825eb392f060fdc88ac0000000000";
    let bytes = hex_to_bytes(hex_string);
    let transaction = Transaction::<88, 1, 1, 42, 1, 1, 35, 1, 1>::new(bytes, true);

    let script_pub_key = "1976a914aa966f56de599b4094b61aa68a2b3df9e97e9c4888ac";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let prev_amount_hex = "3075000000000000";
    let prev_amount_bytes = hex_to_bytes(prev_amount_hex);

    let sighash_none_transaction_bytes =
        serialize_p2wpkh_sighash_none(transaction, 0, prev_amount_bytes, script_pub_key_bytes);

    let sighash_none_transaction = bytes_to_hex(sighash_none_transaction_bytes);

    assert(
        sighash_none_transaction
            == "21ff42b25080442d0beed801c658758bb5d5fa46d5868b3cddc94fd7e7db1168",
    );
}

#[test]
fn test_serialize_p2wpkh_sighash_none_anyonecanpay() {
    let hex_string = "02000000000101ac4994014aa36b7f53375658ef595b3cb2891e1735fe5b441686f5e53338e76a0100000000ffffffff01204e0000000000001976a914ce72abfd0e6d9354a660c18f2825eb392f060fdc88ac0000000000";
    let bytes = hex_to_bytes(hex_string);
    let transaction = Transaction::<88, 1, 1, 42, 1, 1, 35, 1, 1>::new(bytes, true);

    let script_pub_key = "1976a914aa966f56de599b4094b61aa68a2b3df9e97e9c4888ac";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let prev_amount_hex = "3075000000000000";
    let prev_amount_bytes = hex_to_bytes(prev_amount_hex);

    let sighash_none_transaction_bytes = serialize_p2wpkh_sighash_none_anyonecanpay(
        transaction,
        0,
        prev_amount_bytes,
        script_pub_key_bytes,
    );

    let sighash_none_transaction = bytes_to_hex(sighash_none_transaction_bytes);

    assert(
        sighash_none_transaction
            == "faac899582ea50bc2eb5d7ce3fb81b8e48e27ea2df3b66df4f4efefd988c76c3",
    );
}

#[test]
fn test_serialize_p2wpkh_sighash_single() {
    let hex_string = "02000000000101ac4994014aa36b7f53375658ef595b3cb2891e1735fe5b441686f5e53338e76a0100000000ffffffff01204e0000000000001976a914ce72abfd0e6d9354a660c18f2825eb392f060fdc88ac0000000000";
    let bytes = hex_to_bytes(hex_string);
    let transaction = Transaction::<88, 1, 1, 42, 1, 1, 35, 1, 1>::new(bytes, true);

    let script_pub_key = "1976a914aa966f56de599b4094b61aa68a2b3df9e97e9c4888ac";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let prev_amount_hex = "3075000000000000";
    let prev_amount_bytes = hex_to_bytes(prev_amount_hex);

    let sighash_single_transaction_bytes = serialize_p2wpkh_sighash_single::<88, 1, 1, 42, 1, 1, 35, 1, 1, 34>(
        transaction,
        0,
        prev_amount_bytes,
        script_pub_key_bytes,
    );

    let sighash_single_transaction = bytes_to_hex(sighash_single_transaction_bytes);

    assert(
        sighash_single_transaction
            == "68b43bc5a0491886929b9ba2ffd4ea35d61dc5cda6e876aa3b3af1dd7a3d5c8d",
    );
}

#[test]
fn test_serialize_p2wpkh_sighash_single_anyonecanpay() {
    let hex_string = "02000000000101ac4994014aa36b7f53375658ef595b3cb2891e1735fe5b441686f5e53338e76a0100000000ffffffff01204e0000000000001976a914ce72abfd0e6d9354a660c18f2825eb392f060fdc88ac0000000000";
    let bytes = hex_to_bytes(hex_string);
    let transaction = Transaction::<88, 1, 1, 42, 1, 1, 35, 1, 1>::new(bytes, true);

    let script_pub_key = "1976a914aa966f56de599b4094b61aa68a2b3df9e97e9c4888ac";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let prev_amount_hex = "3075000000000000";
    let prev_amount_bytes = hex_to_bytes(prev_amount_hex);

    let sighash_single_transaction_bytes = serialize_p2wpkh_sighash_single_anyonecanpay::<88, 1, 1, 42, 1, 1, 35, 1, 1, 34>(
        transaction,
        0,
        prev_amount_bytes,
        script_pub_key_bytes,
    );

    let sighash_single_transaction = bytes_to_hex(sighash_single_transaction_bytes);

    assert(
        sighash_single_transaction
            == "4bdc7cfd5682c7afa5ec13af501b3e6184079410bc053b6706209a2b111b7572",
    );
}

#[test]
fn test_serialize_p2wsh_sighash_all() {
    let hex_string = "02000000000101fc6a546ff4002beb916ec38598b078ac0df9de6b8668781042ec3bd12a4046130200000000fdffffff034a01000000000000225120fa01986fa1970def53c3092110c29cb0bc328563dcd2ef0fbecc3df8a90c9b0a0000000000000000096a5d06140114001602d296040000000000225120f89fe8f71757da0f8dfe06cdae974cc478913a368a5c4ff472c03f7c583af313034069e0b1a7ff75b5d50951cd1077ebfb6bd53263e9783e3200ea4da5575495c7bc4c8ce9bbda08b6e72d3c3913158b9eda6d05ae75d46cb3d2ba14ce03756641cb6d20356c007e36fb81f41ecc9708cf66f13c4fbbd1b13341b97199ec224730d8dfd2ac0063036f726401010a746578742f706c61696e00357b2270223a226272632d3230222c226f70223a226d696e74222c227469636b223a2263656c6c222c22616d74223a2231303030227d6821c1356c007e36fb81f41ecc9708cf66f13c4fbbd1b13341b97199ec224730d8dfd200000000";
    let bytes = hex_to_bytes(hex_string);
    let transaction = Transaction::<367, 1, 1, 42, 3, 1, 105, 3, 210>::new(bytes, true);

    let script_pub_key = "4b4aad4830450220487fb382c4974de3f7d834c1b617fe15860828c7f96454490edd6d891556dcc9022100baf95feb48f845d5bfc9882eb6aeefa1bc3790e39f59eaa46ff7f15ae626c53e01";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let prev_amount_hex = "d35fbf0100000000";
    let prev_amount_bytes = hex_to_bytes(prev_amount_hex);

    let sighash_transaction_bytes =
        serialize_p2wsh_sighash_all(transaction, 0, prev_amount_bytes, script_pub_key_bytes);

    let sighash_transaction = bytes_to_hex(sighash_transaction_bytes);

    assert(
        sighash_transaction == "44759b1ceae964cdfda8f1dc2a43fd925676b1489d418ac3c295dfdcb692502d",
    );
}

#[test]
fn test_serialize_p2wsh_sighash_all_anyonecanpay() {
    let hex_string = "01000000000108ac3c454bbf586fe34b62e0027659737624777a729f698007e57bda3e8d98fc8500000000171600145ef5fca044974b3ea448ed59e152d080859ce7c3ffffffff9f822bd9e87e119bf5557e9c9ff9099ec8f615399e069722660ad11d4fb6161a0100000000ffffffff18f7b375b061e97248e645070486d9101cefd9a9842117a3c5274b647c8f88620000000017160014c6cfd914fff5fb9258e14ee39308c8412bda192effffffff19d69dab2b37dabcf3e0ba7eb5835627e32e1861bcb78d5b7cd8b17baf5312a90100000000ffffffff5cf49fbac9b66d912312374a037f828aa179cb17b241ac4ac6598f47613c5fb60100000000ffffffff48407cde6ca77d3fc44ca9fa44eba9ab117009c58e912d719f4541403aa4f4490100000000ffffffffacd92e1ef8994c5fb38728f2564b394bff25d6e4dc74ecba07207f953cbf92530000000000ffffffff8d813824c33f06eafd6811c43683144e0ad8de7bdc2bc52c9522b786ac2b8c660000000000ffffffff02bb35000000000000160014b222b0e52fd0c8913b5d5926aa1d0b339ec93805540803000000000017a914bdf2c401e2e2a30a6e76e10d35f31068b2d651af8702483045022100c1440a8bb35d9fae4e463db22b07de75176f336ae31c4e8502f258bf8fd4e90402204cb3779e4258f1d66432ccfc608a75be7de6237bb5eb0da3c6b2389407263f9f01210366033eb2104178dab5b28922ad3ef052aa5fd705bcf60cdd0a297a6b624b8cd50247304402201f11805a4e978623ada1b5c8bf3db51ee20694f838e562262a8053591dea5d0502207fc08977d9f44980cf199c27f7920bd84dc3f23e0e60f339e1e9aaad9bb8a98d0121023ea48e8c23a3864822b8baac58cb3f16bce44b7f8bc1e7d5204ce1f4a24ebb6f02483045022100d43cbc204a91630ac59bdaa2d112d808d956bcc5dd064e22acf2d38eacd06b49022063d1da9f9c34915ad9d5ac0df40c83162204b85406251ee500c173318fccd39e01210206ecaab1626346f5a7aa5596d25ff2c030270a2e86940ffcc0c75c646f8c534502483045022100d69951fb5ceb5ea778dadfb389ad6c329695075077beb3f228dcadbcc9ee32af02201c4d986e5e7a6165e0d8ec2a54254a7e3c9e33e40f865b98561931facdd39f7201210201aff96af2e577c62f16644f390ac913697ade8a55727f86338b03e978c8453a02473044022100a6c4246c958777379df94dfca4d36cf59a04241622ba23cabf2202f5f23dcd15021f7909e6d0662cf190d03a0f0ba664a618e242de7b5144b54998abe4235ef9ed012102fe1acd303ff4051b5dcc834a83247aa696aec378b18805dca0c7e4bb873e6a65024730440220548e72104783bd10e338e316cfb47301d69a4f4c00976a8f7d2ccec6ecb766e702201fbc408af292b2d82a447d65e1a77683cf8eda6a4a8b67679f2e4a5728a3a6a9012102a7ac96a6a1621a918407ff72384adc944948de24d73bca37a274880d878581d702483045022100f50f294a34f1f3a5aa2764daa23012dfa07858b6234b024804dfe41eb8db0e0102200d60a35d06a60996837afc3e880345f020cab362f25e48c5433f806228cf170801210328853617c7481549b35181dcd5235f4a1d5bc5c5e09d7ddb2ff88818d69164e80247304402201d1b97dcd286faa4cb737be2ea4551c51c08f249c4be3e2b0d24f68d171152ce02202823575845b0da8328f78e8a037ac735e0244cf72f29803683c64e703b1fb0bb0121035f16045eaf8f1d615fcfa1947ad1244f815f9e17a0b14cc2b76c85fe42f2a79300000000";
    let bytes = hex_to_bytes(hex_string);
    let transaction = Transaction::<1309, 8, 1, 375, 2, 1, 64, 2, 860>::new(bytes, true);

    let script_pub_key =
        "2900e16741107dcd7cfa2eaeb7d767e47edbec577511b3e10f16980754c3273712843884328423748328";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let prev_amount_hex = "d5af920500000000";
    let prev_amount_bytes = hex_to_bytes(prev_amount_hex);

    let sighash_transaction_bytes = serialize_p2wsh_sighash_all_anyonecanpay(
        transaction,
        1,
        prev_amount_bytes,
        script_pub_key_bytes,
    );

    let sighash_transaction = bytes_to_hex(sighash_transaction_bytes);

    assert(
        sighash_transaction == "c0f01ec3f0809d523c5f1d303529970141771bf3f533d5c842c427a2cf0cf431",
    );
}

#[test]
fn test_serialize_p2wsh_sighash_none() {
    let hex_string = "010000000001017330689c88a3eac0228a2ad7b4fb5b349799d55a0bbae521daad2e6b3177e9890000000000ffffffff02f8ae05000000000016001418438dbcccf50446cdd34d7f84b0e9e5287f85050000000000000000536a4c50002cfff90002f86ae5474c52cf6a21742498bb7648e493d2e1f3f7469faba2bb68e19600f1b8479a2cf6d758a51bcc2c99f44d45620a193b052b2f4daaacddab941b423f1d7daccca4b19d20ca151ab202483045022100a943fd8486295d461884acf68eb3fb16f3eccc3f1d9d495a67cce9be100c455002203080102764f2466c9ea9222207ddf765e50d7133a80d459250107ba35da4a80b012103e9a8553319287b984c7d0a1dfda07d1587d2b7f2f46dba7cd51713c11b6572e800000000";
    let bytes = hex_to_bytes(hex_string);
    let transaction = Transaction::<284, 1, 1, 42, 2, 1, 124, 2, 108>::new(bytes, true);

    let script_pub_key =
        "266a24e4b883e5bda9e7a59ee4bb99e9b1bcf09f909f426974636f696e20746f20506c75746f21";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let prev_amount_hex = "69410e0000000000";
    let prev_amount_bytes = hex_to_bytes(prev_amount_hex);

    let sighash_transaction_bytes =
        serialize_p2wsh_sighash_none(transaction, 0, prev_amount_bytes, script_pub_key_bytes);

    let sighash_transaction = bytes_to_hex(sighash_transaction_bytes);

    assert(
        sighash_transaction == "a59b5231eb01caa998a5a20e79b15875163568c58208362b29bf83e678a15815",
    );
}

#[test]
fn test_serialize_p2wsh_sighash_none_anyonecanpay() {
    let hex_string = "01000000000101d4756e83b874ef7d3c5a23beb1d0e1c2241a6fdaa61c0f526e7e1fc6af29065505000000232200200921d9f5fdd4f149f20631eb1d7cf98466ff76eadef56ef1aa59e0b234bd3e41ffffffff0349d702000000000017a9143e3debe86d2a0716d9e7c59651e9688d4c8133c287121102000000000017a9145b636469c50463c8de2ad9a999517fec1b4ba45087d4a010050000000017a914ac95e9a12db212e8d6afe5df0c8378e023eb676a8704004830450221009e2906b94a81cdcef360d4d4dd65db91564722c0cee151413438626f124757db022017de8c425c7d3612b9d7b8f5431a9f224e67c9f9aeedf2843a006bf3d08f133e0147304402207f651d4f14fe90943f706bf089089f613d21b11c3a526a0254541b6f95dd2fa302204013ce93abee9540f45d5850935a798f4ec160762c5462c82b9f4b26ecd0535801475221029137565c4663e8eb711becf780548b0be8eab0ebf96487ffb516f9e591b8d5352102259dd307b62bb668d004dfa23363ffe17c0ee48e8c13993f0b25d38f0567c16c52ae00000000";
    let bytes = hex_to_bytes(hex_string);
    let transaction = Transaction::<403, 1, 1, 77, 3, 1, 97, 4, 219>::new(bytes, true);

    let script_pub_key = "6a4730440220159a87778205fbeef3fc7b776d043c2da442689ba47dc0f7525783ceef1beac8022032ece0716218282b50505529a27ae50398035bbbda48a59e707bf31f2016dd0a012103c9fa680677014ec5c749d03c7074c6cf5351bbb267326838118ec1f20cada665";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let prev_amount_hex = "79cf220000000000";
    let prev_amount_bytes = hex_to_bytes(prev_amount_hex);

    let sighash_transaction_bytes = serialize_p2wsh_sighash_none_anyonecanpay(
        transaction,
        0,
        prev_amount_bytes,
        script_pub_key_bytes,
    );

    let sighash_transaction = bytes_to_hex(sighash_transaction_bytes);

    assert(
        sighash_transaction == "0eef7df23f5ebc2edf2c1c682f2ea8a4ef3c23ef457279372b339d18318486d3",
    );
}

#[test]
fn test_serialize_p2wsh_sighash_single() {
    let hex_string = "02000000000103d672c9d8eef6f27f7cd2d95aaeb528352620b677d93c8e6906e22a95b3e4d17b010000006a47304402206265e1fab22a161f33122758f3b3e3d73d9756b102c99f525f97128b14a2c78202207c38aa4a3fa0e8042142446663713aa466ad15050b2fd7f2cb04bdf7cef47b5d01210376f67bf59b5386339be376868060601c6bdaa03a414bec5080d917f8ef9f6bc4fdffffff9d372dc2190f7ad555417e0b9af65c5585a52212beebd4cb3c6f83f95fa6b2e5010000006b483045022100806e597df3a15edf8e25cc43528753f2f43e45b674cc428a24d03459338f0168022021b8f760d2cbe0bf4f44aedd4e01cee4056854449cea2bbe649563be92a4639b01210376f67bf59b5386339be376868060601c6bdaa03a414bec5080d917f8ef9f6bc4fdffffffaf9c463745877ee20c920a776a2f2d5ec6ceb3e824d0fb62d76f7c59db51faff010000006a47304402207b5a99efdf55d653ad7bf2eb0890f80a843b356eb047b09d825a0325e1d48d9a02201e0f547e22ddb9d35c6a9f4e2be68002c21ae9cd681572aa6436bfbf3265606901210376f67bf59b5386339be376868060601c6bdaa03a414bec5080d917f8ef9f6bc4fdffffff0240420f00000000001976a914d694e0ff3a4ca94c520ca1f46fcf36bd6b25076e88ac46c30d29000000001976a914ed4e8d66d4d77a4a142179e64a1771b637d424ad88ac00000019000a00";
    let bytes = hex_to_bytes(hex_string);
    let transaction = Transaction::<525, 3, 1, 443, 2, 1, 69, 0, 3>::new(bytes, true);

    let script_pub_key = "8a47304402204b996199a1f51158629e3720cae4a8779ed2f8d50eca29ef3495b6d3d84264bf022063991e3a2b641f2f7e589a08f8df6dd53628e08edde088b7235f1fd4fee38f7a01410481860455fd1afbfb265d5aebfa8318a3525d693ca802e18a23933aff160982b3b96942cb4ac95bc14e4a5a580a87227e222240db92a177c2f049ed28f3edd8ae";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let prev_amount_hex = "43188e0000000000";
    let prev_amount_bytes = hex_to_bytes(prev_amount_hex);

    let sighash_transaction_bytes = serialize_p2wsh_sighash_single::<525, 3, 1, 443, 2, 1, 69, 0, 3, 139, 34>(
        transaction,
        1,
        prev_amount_bytes,
        script_pub_key_bytes,
    );

    let sighash_transaction = bytes_to_hex(sighash_transaction_bytes);

    assert(
        sighash_transaction == "40a2f915cb3337635df59c14468d68bcf1f22018caa26bc7be8b2e950a6b951c",
    );
}

#[test]
fn test_serialize_p2wsh_sighash_single_anyonecanpay() {
    let hex_string = "02000000000103fe9fbc3cb4f53ec9096b3eb4a41db50d83bed1081e65c0f9643792d4a5481eaf00000000171600146166fde1a004abccaf1a6fbf19ad0c6c5d695643fdffffff414628bee9f248d78f6fda493f6271bb0d4fc01da86910c1170eec39de21eda60100000017160014f28e8dcc259986417a79e80a01ad1e65ffd8ec54fdffffffd1fd4ac2ad39e059095d85b563649fc217581926ba8dc14864f02e5b06fb37840000000017160014ba1e6a29b56f4c34100cebf2370f366fd1a8a24cfdffffff0165d6f600000000001976a9147c9cf13cfd241a1eb388f1c2e34593d1d83c36c088ac024730440220029f7707f6d54c389a684ab2f679b4afc32f61513190ca2ef88f266eabcbbe44022014c424df059741a7d3f7ddc93aa46351d8d4285215611dd6d106e1c16bbec812012103b3cb727f3a2b6d9a3dd133fa1f1c9627ef26f270a8ba360b0ff8dd51dfedc00102473044022000e66901db6b5d158c41ecb3344319f539d915b503517c765e85c12884fb1fe0022004f4f917463a70775a6356e15e1287b31a94db25f4e439b46d53456e6b31cd4001210244b1ce056a9a032ccd83dd08a54f079d9b88ca2b44c1f895cc213951478b065f024730440220123138d8451c8155939bb8bf531b3b9a334bfc713ad05aff6d3cd7a9ab01a36302206336501b996fad9af7e8c459d6b1844720e4e219c5fe817ff8a9a6b93ca55dc50121023ebbfd88641b6c6f4af2f4b6b1715489b9523ee01e6534f5025210ddb7990e0500000000";
    let bytes = hex_to_bytes(hex_string);
    let transaction = Transaction::<559, 3, 1, 193, 1, 1, 35, 2, 321>::new(bytes, true);

    let script_pub_key = "8a47304402204b996199a1f51158629e3720cae4a8779ed2f8d50eca29ef3495b6d3d84264bf022063991e3a2b641f2f7e589a08f8df6dd53628e08edde088b7235f1fd4fee38f7a01410481860455fd1afbfb265d5aebfa8318a3525d693ca802e18a23933aff160982b3b96942cb4ac95bc14e4a5a580a87227e222240db92a177c2f049ed28f3edd8ae";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key);

    let prev_amount_hex = "63097b1700000000";
    let prev_amount_bytes = hex_to_bytes(prev_amount_hex);

    let sighash_transaction_bytes = serialize_p2wsh_sighash_single_anyonecanpay::<559, 3, 1, 193, 1, 1, 35, 2, 321, 139, 34>(
        transaction,
        0,
        prev_amount_bytes,
        script_pub_key_bytes,
    );

    let sighash_transaction = bytes_to_hex(sighash_transaction_bytes);

    assert(
        sighash_transaction == "f10411e394933d1b47bf12eb1d3e329a8c3954ca9fa0e753737c05e27ed0eea1",
    );
}

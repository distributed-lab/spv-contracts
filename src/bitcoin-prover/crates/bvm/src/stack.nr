use crypto::ecdsa::{
    ecdsa_verify, get_rs_from_signature, get_xy_from_compressed_pubkey,
    get_xy_from_uncompressed_pubkey,
};
use crypto::schnorr::{schnorr_verify, tagged_hash};
use ripemd160::ripemd160;
use sha1::sha1;
use sign::address::Address;
use sign::{
    legacy::{
        serialize_sighash_all, serialize_sighash_all_anyonecanpay, serialize_sighash_none,
        serialize_sighash_none_anyonecanpay, serialize_sighash_single,
        serialize_sighash_single_anyonecanpay,
    },
    segwit::{
        serialize_p2wpkh_sighash_all, serialize_p2wpkh_sighash_all_anyonecanpay,
        serialize_p2wpkh_sighash_none, serialize_p2wpkh_sighash_none_anyonecanpay,
        serialize_p2wpkh_sighash_single, serialize_p2wpkh_sighash_single_anyonecanpay,
        serialize_p2wsh_sighash_all, serialize_p2wsh_sighash_all_anyonecanpay,
        serialize_p2wsh_sighash_none, serialize_p2wsh_sighash_none_anyonecanpay,
        serialize_p2wsh_sighash_single, serialize_p2wsh_sighash_single_anyonecanpay,
    },
    taproot::{
        parse_outputs, serialize_p2tr_sighash_all, serialize_p2tr_sighash_all_anyonecanpay,
        serialize_p2tr_sighash_none, serialize_p2tr_sighash_none_anyonecanpay,
        serialize_p2tr_sighash_single, serialize_p2tr_sighash_single_anyonecanpay,
    },
    transaction::Transaction,
};
use sign::sig_types::{
    SIGHASH_ALL, SIGHASH_ANYONECANPAY, SIGHASH_DEFAULT, SIGHASH_NONE, SIGHASH_SINGLE,
};
use std::collections::bounded_vec::BoundedVec;
use utils::convert::{
    bytes_to_vec, hex_to_bytes, i32_to_le_bytes, i32_to_vec, u32_to_le_bytes, vec_to_array,
    vec_to_i32, vec_to_u32,
};

pub fn empty_stack_array<let MAX_STACK_ELEMENT_SIZE: u32, let MAX_STACK_SIZE: u32>() -> [BoundedVec<u8, MAX_STACK_ELEMENT_SIZE>; MAX_STACK_SIZE] {
    [BoundedVec::new(); MAX_STACK_SIZE]
}

pub struct Stack<let MAX_STACK_ELEMENT_SIZE: u32, let MAX_STACK_SIZE: u32, let CURRENT_TRANSACTION_SIZE: u32, let CURRENT_INPUT_COUNT: u32, let CURRENT_INPUT_COUNT_LEN: u32, let CURRENT_INPUT_SIZE: u32, let CURRENT_OUTPUT_COUNT: u32, let CURRENT_OUTPUT_COUNT_LEN: u32, let CURRENT_OUTPUT_SIZE: u32, let CURRENT_MAX_WITNESS_STACK_SIZE: u32, let CURRENT_WITNESS_SIZE: u32, let PREV_TRANSACTION_SIZE: u32, let PREV_INPUT_COUNT: u32, let PREV_INPUT_COUNT_LEN: u32, let PREV_INPUT_SIZE: u32, let PREV_OUTPUT_COUNT: u32, let PREV_OUTPUT_COUNT_LEN: u32, let PREV_OUTPUT_SIZE: u32, let PREV_MAX_WITNESS_STACK_SIZE: u32, let PREV_WITNESS_SIZE: u32, let REDEEM_SCRIPT_LEN: u32> {
    pub data: [BoundedVec<u8, MAX_STACK_ELEMENT_SIZE>; MAX_STACK_SIZE],
    pub stack_size: u32,
    alt_data: [BoundedVec<u8, MAX_STACK_ELEMENT_SIZE>; MAX_STACK_SIZE],
    alt_stack_size: u32,
    cur_transaction: Transaction<CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE>,
    prev_transaction: Transaction<PREV_TRANSACTION_SIZE, PREV_INPUT_COUNT, PREV_INPUT_COUNT_LEN, PREV_INPUT_SIZE, PREV_OUTPUT_COUNT, PREV_OUTPUT_COUNT_LEN, PREV_OUTPUT_SIZE, PREV_MAX_WITNESS_STACK_SIZE, PREV_WITNESS_SIZE>,
    input_to_sign: u32,
    output_to_unlock: u32,
    redeem_script: [u8; REDEEM_SCRIPT_LEN],
}

impl<let MAX_STACK_ELEMENT_SIZE: u32, let MAX_STACK_SIZE: u32> Stack<MAX_STACK_ELEMENT_SIZE, MAX_STACK_SIZE, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0> {
    pub fn new_test_stack() -> Stack<MAX_STACK_ELEMENT_SIZE, MAX_STACK_SIZE, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0> {
        Self {
            data: [BoundedVec::new(); MAX_STACK_SIZE],
            stack_size: 0,
            alt_data: [BoundedVec::new(); MAX_STACK_SIZE],
            alt_stack_size: 0,
            cur_transaction: Transaction::<0, 0, 0, 0, 0, 0, 0, 0, 0>::new_empty_transaction(),
            prev_transaction: Transaction::<0, 0, 0, 0, 0, 0, 0, 0, 0>::new_empty_transaction(),
            input_to_sign: 0,
            output_to_unlock: 0,
            redeem_script: [],
        }
    }
}

impl<let MAX_STACK_ELEMENT_SIZE: u32, let MAX_STACK_SIZE: u32, let CURRENT_TRANSACTION_SIZE: u32, let CURRENT_INPUT_COUNT: u32, let CURRENT_INPUT_COUNT_LEN: u32, let CURRENT_INPUT_SIZE: u32, let CURRENT_OUTPUT_COUNT: u32, let CURRENT_OUTPUT_COUNT_LEN: u32, let CURRENT_OUTPUT_SIZE: u32, let CURRENT_MAX_WITNESS_STACK_SIZE: u32, let CURRENT_WITNESS_SIZE: u32, let PREV_TRANSACTION_SIZE: u32, let PREV_INPUT_COUNT: u32, let PREV_INPUT_COUNT_LEN: u32, let PREV_INPUT_SIZE: u32, let PREV_OUTPUT_COUNT: u32, let PREV_OUTPUT_COUNT_LEN: u32, let PREV_OUTPUT_SIZE: u32, let PREV_MAX_WITNESS_STACK_SIZE: u32, let PREV_WITNESS_SIZE: u32, let REDEEM_SCRIPT_LEN: u32> Stack<MAX_STACK_ELEMENT_SIZE, MAX_STACK_SIZE, CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, PREV_TRANSACTION_SIZE, PREV_INPUT_COUNT, PREV_INPUT_COUNT_LEN, PREV_INPUT_SIZE, PREV_OUTPUT_COUNT, PREV_OUTPUT_COUNT_LEN, PREV_OUTPUT_SIZE, PREV_MAX_WITNESS_STACK_SIZE, PREV_WITNESS_SIZE, REDEEM_SCRIPT_LEN> {
    pub fn new(
        cur_transaction: Transaction<CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE>,
        prev_transaction: Transaction<PREV_TRANSACTION_SIZE, PREV_INPUT_COUNT, PREV_INPUT_COUNT_LEN, PREV_INPUT_SIZE, PREV_OUTPUT_COUNT, PREV_OUTPUT_COUNT_LEN, PREV_OUTPUT_SIZE, PREV_MAX_WITNESS_STACK_SIZE, PREV_WITNESS_SIZE>,
        input_to_sign: u32,
        output_to_unlock: u32,
        stack_array: [BoundedVec<u8, MAX_STACK_ELEMENT_SIZE>; MAX_STACK_SIZE],
        redeem_script: [u8; REDEEM_SCRIPT_LEN],
    ) -> Stack<MAX_STACK_ELEMENT_SIZE, MAX_STACK_SIZE, CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, PREV_TRANSACTION_SIZE, PREV_INPUT_COUNT, PREV_INPUT_COUNT_LEN, PREV_INPUT_SIZE, PREV_OUTPUT_COUNT, PREV_OUTPUT_COUNT_LEN, PREV_OUTPUT_SIZE, PREV_MAX_WITNESS_STACK_SIZE, PREV_WITNESS_SIZE, REDEEM_SCRIPT_LEN> {
        Stack {
            data: stack_array,
            stack_size: 0,
            alt_data: stack_array,
            alt_stack_size: 0,
            cur_transaction: cur_transaction,
            prev_transaction: prev_transaction,
            input_to_sign: input_to_sign,
            output_to_unlock: output_to_unlock,
            redeem_script: redeem_script,
        }
    }

    pub fn push(&mut self, value: BoundedVec<u8, MAX_STACK_ELEMENT_SIZE>) {
        self.data[self.stack_size] = value;
        self.stack_size += 1;
    }

    pub fn push_bytes<let N: u32>(&mut self, input: [u8; N]) {
        let value = bytes_to_vec(input);
        self.push(value)
    }

    fn pop(&mut self) -> BoundedVec<u8, MAX_STACK_ELEMENT_SIZE> {
        assert(self.stack_size > 0);
        self.stack_size -= 1;
        self.data[self.stack_size]
    }

    pub fn pop_bytes<let N: u32>(&mut self) -> [u8; N] {
        let value = self.pop();
        // println(value);
        // println(value.len());
        // assert(value.len() == N);
        let mut value_array = [0; N];
        for i in 0..N {
            value_array[i] = value.storage()[i];
        }
        value_array
    }

    pub fn pop_pubkey(&mut self) -> ([u8; 32], [u8; 32]) {
        let pubkey_bytes = self.pop();

        if pubkey_bytes.len() == 33 {
            get_xy_from_compressed_pubkey(vec_to_array::<MAX_STACK_ELEMENT_SIZE, 33>(pubkey_bytes))
        } else if pubkey_bytes.len() == 65 {
            get_xy_from_uncompressed_pubkey(vec_to_array::<MAX_STACK_ELEMENT_SIZE, 65>(pubkey_bytes))
        } else {
            assert(false, "Invalid pubkey length");
            ([0; 32], [0; 32])
        }
    }

    pub fn pop_signature(&mut self) -> ([u8; 64], u8, bool) {
        let encoded_signature_vec = self.pop();
        let is_empty = encoded_signature_vec.storage().all(|e| e == 0);

        let mut signature = [0; 64];
        let mut hash_type = 0;

        if encoded_signature_vec.len() - 1 == 71 {
            let encoded_signature_with_hash_type =
                vec_to_array::<MAX_STACK_ELEMENT_SIZE, 72>(encoded_signature_vec);
            hash_type = encoded_signature_with_hash_type[71];
            let mut encoded_signature = [0; 71];
            for i in 0..71 {
                encoded_signature[i] = encoded_signature_with_hash_type[i];
            }
            signature = get_rs_from_signature(encoded_signature);
        } else if encoded_signature_vec.len() - 1 == 70 {
            let encoded_signature_with_hash_type =
                vec_to_array::<MAX_STACK_ELEMENT_SIZE, 71>(encoded_signature_vec);
            hash_type = encoded_signature_with_hash_type[70];
            let mut encoded_signature = [0; 70];
            for i in 0..70 {
                encoded_signature[i] = encoded_signature_with_hash_type[i];
            }
            signature = get_rs_from_signature(encoded_signature);
        } else if encoded_signature_vec.len() - 1 == 72 {
            let encoded_signature_with_hash_type =
                vec_to_array::<MAX_STACK_ELEMENT_SIZE, 73>(encoded_signature_vec);
            hash_type = encoded_signature_with_hash_type[72];
            let mut encoded_signature = [0; 72];
            for i in 0..72 {
                encoded_signature[i] = encoded_signature_with_hash_type[i];
            }
            signature = get_rs_from_signature(encoded_signature);
        } else {
            assert(false, "Invalid signature length");
        }

        (signature, hash_type, is_empty)
    }

    pub fn pop_signature_p2tr(&mut self) -> ([u8; 64], u8, bool) {
        let signature_vec = self.pop();
        let is_empty = signature_vec.storage().all(|e| e == 0);

        let mut signature = [0; 64];
        let mut hash_type = 0;

        if signature_vec.len() == 64 {
            signature = vec_to_array::<MAX_STACK_ELEMENT_SIZE, 64>(signature_vec);
            hash_type = 1;
        } else if signature_vec.len() == 65 {
            let signature_with_hash_type =
                vec_to_array::<MAX_STACK_ELEMENT_SIZE, 65>(signature_vec);
            hash_type = signature_with_hash_type[64];
            assert(hash_type != 0, "Unspecified hash type");
            for i in 0..64 {
                signature[i] = signature_with_hash_type[i];
            }
        } else {
            assert(false, "Invalid signature length");
        }

        (signature, hash_type, is_empty)
    }

    // OP_0 ... OP_16 AND OP_1NEGATE
    pub fn op_num(&mut self, num: i8) {
        assert(num >= -1 & num <= 16);
        self.push(i32_to_vec(num as i32));
    }

    pub fn op_pushbytes<let N: u32>(&mut self, input: [u8; N]) {
        let value = bytes_to_vec(input);
        self.push(value);
    }

    pub fn op_equal(&mut self) {
        let value1 = self.pop().storage();
        let value2 = self.pop().storage();

        if value1 == value2 {
            self.push(bytes_to_vec([1]));
        } else {
            self.push(bytes_to_vec([0]));
        }
    }

    pub fn op_equalverify(&mut self) {
        let value1 = self.pop().storage();
        let value2 = self.pop().storage();

        assert(value1 == value2);
    }

    pub fn op_add(&mut self) {
        let value1 = self.pop();
        let value2 = self.pop();

        let value3 = vec_to_i32(value1) + vec_to_i32(value2);
        self.push(i32_to_vec(value3));
    }

    pub fn op_sub(&mut self) {
        let value1 = self.pop();
        let value2 = self.pop();

        let value3 = vec_to_i32(value2) - vec_to_i32(value1);
        self.push(i32_to_vec(value3));
    }

    pub fn op_verify(&mut self) -> bool {
        if self.data.len() == 0 {
            false
        } else {
            if vec_to_i32(self.pop()) == 0 {
                false
            } else {
                true
            }
        }
    }

    pub fn op_ifdup(&mut self) {
        let dup = self.data[self.stack_size - 1];
        if vec_to_i32(dup) != 0 {
            self.push(dup);
        }
    }

    pub fn op_fromaltstack(&mut self) {
        assert(self.alt_stack_size > 0);
        self.alt_stack_size -= 1;
        self.push(self.alt_data[self.alt_stack_size]);
    }

    pub fn op_toaltstack(&mut self) {
        let elem = self.pop();
        self.alt_data[self.alt_stack_size] = elem;
        self.alt_stack_size += 1;
    }

    pub fn op_depth(&mut self) {
        self.push(bytes_to_vec(u32_to_le_bytes(self.stack_size)));
    }

    pub fn op_drop(&mut self) {
        self.stack_size -= 1;
    }

    pub fn op_dup(&mut self) {
        self.push(self.data[self.stack_size - 1]);
    }

    pub fn op_nip(&mut self) {
        self.stack_size -= 1;
        self.data[self.stack_size - 1] = self.data[self.stack_size];
    }

    pub fn op_over(&mut self) {
        let dup = self.data[self.stack_size - 2];
        self.push(dup);
    }

    // !remove last element
    pub fn op_pick(&mut self) {
        let mut n = vec_to_u32(self.data[self.stack_size - 1]);
        assert(n < self.stack_size - 1);
        n = self.stack_size - n - 2;
        self.data[self.stack_size - 1] = self.data[n];
    }

    // !remove last element
    pub fn op_roll(&mut self) {
        let mut n = vec_to_u32(self.pop());
        assert(n < self.stack_size);
        n = self.stack_size - n - 1;
        let roll = self.data[n];
        for i in 0..MAX_STACK_SIZE {
            if i >= self.stack_size {
                // continue
            } else if i == self.stack_size - 1 {
                self.data[i] = roll;
            } else if i >= n {
                self.data[i] = self.data[i + 1];
            }
        }
    }

    pub fn op_rot(&mut self) {
        self.op_num(2);
        self.op_roll();
    }

    pub fn op_swap(&mut self) {
        let swap = self.data[self.stack_size - 2];
        self.data[self.stack_size - 2] = self.data[self.stack_size - 1];
        self.data[self.stack_size - 1] = swap;
    }

    pub fn op_tuck(&mut self) {
        self.op_swap();
        self.op_over();
    }

    pub fn op_2drop(&mut self) {
        self.op_drop();
        self.op_drop();
    }

    pub fn op_2dup(&mut self) {
        self.op_over();
        self.op_over();
    }

    pub fn op_3dup(&mut self) {
        self.op_num(2);
        self.op_pick();
        self.op_num(2);
        self.op_pick();
        self.op_num(2);
        self.op_pick();
    }

    pub fn op_2over(&mut self) {
        self.op_num(3);
        self.op_pick();
        self.op_num(3);
        self.op_pick();
    }

    pub fn op_2rot(&mut self) {
        self.op_num(5);
        self.op_roll();
        self.op_num(5);
        self.op_roll();
    }

    pub fn op_2swap(&mut self) {
        self.op_num(3);
        self.op_roll();
        self.op_num(3);
        self.op_roll();
    }

    pub fn op_1add(&mut self) {
        let num = vec_to_i32(self.data[self.stack_size - 1]);
        self.data[self.stack_size - 1] = i32_to_vec(num + 1);
    }

    pub fn op_1sub(&mut self) {
        let num = vec_to_i32(self.data[self.stack_size - 1]);
        self.data[self.stack_size - 1] = i32_to_vec(num - 1);
    }

    pub fn op_negate(&mut self) {
        let num = vec_to_i32(self.data[self.stack_size - 1]);
        self.data[self.stack_size - 1] = i32_to_vec(-num);
    }

    pub fn op_abs(&mut self) {
        let mut num = vec_to_i32(self.data[self.stack_size - 1]);
        if num < 0 {
            num = -num;
        }
        self.data[self.stack_size - 1] = i32_to_vec(num);
    }

    pub fn op_not(&mut self) {
        let mut num = vec_to_i32(self.data[self.stack_size - 1]);
        if num == 0 {
            num = 1;
        } else {
            num = 0;
        }
        self.data[self.stack_size - 1] = i32_to_vec(num);
    }

    pub fn op_0notequal(&mut self) {
        let mut num = vec_to_i32(self.data[self.stack_size - 1]);
        if num != 0 {
            num = 1;
        }
        self.data[self.stack_size - 1] = i32_to_vec(num);
    }

    pub fn op_booland(&mut self) {
        let value1 = vec_to_i32(self.pop());
        let value2 = vec_to_i32(self.pop());

        if (value1 != 0) & (value2 != 0) {
            self.push(i32_to_vec(1));
        } else {
            self.push(i32_to_vec(0));
        }
    }

    pub fn op_boolor(&mut self) {
        let value1 = vec_to_i32(self.pop());
        let value2 = vec_to_i32(self.pop());

        if (value1 != 0) | (value2 != 0) {
            self.push(i32_to_vec(1));
        } else {
            self.push(i32_to_vec(0));
        }
    }

    pub fn op_numequal(&mut self) {
        let value1 = vec_to_i32(self.pop());
        let value2 = vec_to_i32(self.pop());

        if value1 == value2 {
            self.push(i32_to_vec(1));
        } else {
            self.push(i32_to_vec(0));
        }
    }

    pub fn op_numnotequal(&mut self) {
        let value1 = vec_to_i32(self.pop());
        let value2 = vec_to_i32(self.pop());

        if value1 != value2 {
            self.push(i32_to_vec(1));
        } else {
            self.push(i32_to_vec(0));
        }
    }

    pub fn op_lessthan(&mut self) {
        let value1 = vec_to_i32(self.pop());
        let value2 = vec_to_i32(self.pop());

        if value1 > value2 {
            self.push(i32_to_vec(1));
        } else {
            self.push(i32_to_vec(0));
        }
    }

    pub fn op_greaterthan(&mut self) {
        let value1 = vec_to_i32(self.pop());
        let value2 = vec_to_i32(self.pop());

        if value1 < value2 {
            self.push(i32_to_vec(1));
        } else {
            self.push(i32_to_vec(0));
        }
    }

    pub fn op_lessthanorequal(&mut self) {
        let value1 = vec_to_i32(self.pop());
        let value2 = vec_to_i32(self.pop());

        if value1 >= value2 {
            self.push(i32_to_vec(1));
        } else {
            self.push(i32_to_vec(0));
        }
    }

    pub fn op_greaterthanorequal(&mut self) {
        let value1 = vec_to_i32(self.pop());
        let value2 = vec_to_i32(self.pop());

        if value1 <= value2 {
            self.push(i32_to_vec(1));
        } else {
            self.push(i32_to_vec(0));
        }
    }

    pub fn op_min(&mut self) {
        let value1 = vec_to_i32(self.pop());
        let value2 = vec_to_i32(self.pop());

        if value1 > value2 {
            self.push(i32_to_vec(value2));
        } else {
            self.push(i32_to_vec(value1));
        }
    }

    pub fn op_max(&mut self) {
        let value1 = vec_to_i32(self.pop());
        let value2 = vec_to_i32(self.pop());

        if value1 > value2 {
            self.push(i32_to_vec(value1));
        } else {
            self.push(i32_to_vec(value2));
        }
    }

    // !not sure about arguments order
    pub fn op_within(&mut self) {
        let max = vec_to_i32(self.pop());
        let min = vec_to_i32(self.pop());
        let x = vec_to_i32(self.pop());

        if (x >= min) & (x < max) {
            self.push(i32_to_vec(1));
        } else {
            self.push(i32_to_vec(0));
        }
    }

    pub fn op_ripemd160<let LEN: u32>(&mut self) {
        let hash = ripemd160(self.pop_bytes::<LEN>());
        let mut vec = BoundedVec::new();
        vec.extend_from_slice(hash);
        self.push(vec);
    }

    pub fn op_sha1<let LEN: u32>(&mut self) {
        let hash = sha1::digest(self.pop_bytes::<LEN>());
        let mut vec = BoundedVec::new();
        vec.extend_from_slice(hash);
        self.push(vec);
    }

    pub fn op_sha256<let LEN: u32>(&mut self) {
        let hash = sha256::digest(self.pop_bytes::<LEN>());
        let mut vec = BoundedVec::new();
        vec.extend_from_slice(hash);
        self.push(vec);
    }

    pub fn get_last_stack_element_length(&mut self) -> u32 {
        self.data[self.stack_size - 1].len()
    }

    pub fn op_hash160<let LEN: u32>(&mut self) {
        let hash = sha256::digest(self.pop_bytes::<LEN>());
        let dhash = ripemd160(hash);
        let mut vec = BoundedVec::new();
        vec.extend_from_slice(dhash);
        self.push(vec);
    }

    pub fn op_hash256<let LEN: u32>(&mut self) {
        let hash = sha256::digest(self.pop_bytes::<LEN>());
        let dhash = sha256::digest(hash);
        let mut vec = BoundedVec::new();
        vec.extend_from_slice(dhash);
        self.push(vec);
    }

    // todo: implement this opcode
    pub fn op_codeseparator(&mut self) {
        //
    }

    pub fn op_size(&mut self) {
        self.push_bytes(u32_to_le_bytes(self.get_last_stack_element_length()));
    }

    // todo: replace bit shifts with more efficient operations
    pub fn op_checklocktimeverify(&mut self) {
        let elem = self.data[self.stack_size - 1];
        let num = vec_to_i32(elem);
        let ltime_offset = self.cur_transaction.lock_time.offset;
        let sequence_offset = self.cur_transaction.inputs[self.input_to_sign].sequence.offset;
        let mut locktime = 0;
        let mut sequence = 0;
        for i in 0..4 {
            locktime += self.cur_transaction.data[ltime_offset + i] as i32 << (i * 8) as u8;
            sequence += self.cur_transaction.data[sequence_offset + i] as i32 << (i * 8) as u8;
        }

        if (num < 0)
            | (num > locktime)
            | ((num >= 500000000) & (locktime < 500000000))
            | ((num < 500000000) & (locktime >= 500000000))
            | (sequence as u32 == 0xffffffff) {
            assert(false);
        }
    }

    // todo: replace bit shifts with more efficiency operations
    pub fn op_checksequenceverify(&mut self) {
        let elem = self.data[self.stack_size - 1];
        let num = vec_to_i32(elem);
        let version_offset = self.cur_transaction.version.offset;
        let sequence_offset = self.cur_transaction.inputs[self.input_to_sign].sequence.offset;
        let mut version = 0;
        let mut sequence = 0;
        for i in 0..4 {
            version += self.cur_transaction.data[version_offset + i] as i32 << (i * 8) as u8;
            sequence += self.cur_transaction.data[sequence_offset + i] as i32 << (i * 8) as u8;
        }

        let types_are_equal = ((sequence >> 22) & 1) == ((num >> 22) & 1);
        let bip68_mask = 0xffff;

        if (num < 0)
            | (
                ((num as u32 >> 31) != 1)
                    & (
                        (version < 2)
                            | ((sequence as u32 >> 31) == 1)
                            | !types_are_equal
                            | ((num & bip68_mask) > (sequence & bip68_mask))
                    )
            ) {
            assert(false);
        }
    }

    pub fn get_script_code_size(&mut self, address: Address) -> u32 {
        let mut size = 0;
        if address.is_p2pk() | address.is_p2pkh() | address.is_p2ms() {
            size = self.prev_transaction.get_script_pub_key_size(self.output_to_unlock);
        } else if address.is_p2wpkh() {
            size = 26;
        } else {
            assert(false, "not implemented");
        }
        size
    }

    fn get_sighash_all_message_hash<let SCRIPT_CODE_LEN: u32>(
        &mut self,
        address: Address,
    ) -> [u8; 32] {
        let mut message_hash = [0; 32];
        if address.is_p2pk() | address.is_p2pkh() | address.is_p2ms() {
            let script_code = self.prev_transaction.get_script_pub_key_with_size::<SCRIPT_CODE_LEN>(
                self.output_to_unlock,
            );
            message_hash =
                serialize_sighash_all(self.cur_transaction, self.input_to_sign, script_code);
        } else if address.is_p2sh() {
            message_hash =
                serialize_sighash_all(self.cur_transaction, self.input_to_sign, self.redeem_script);
        } else if address.is_p2wpkh() {
            let amount = self.prev_transaction.get_amount(self.output_to_unlock);
            let script_code = if self.redeem_script.len() == 0 {
                self.prev_transaction.get_p2wpkh_script_code(self.output_to_unlock)
            } else {
                assert(REDEEM_SCRIPT_LEN == 26);
                self.redeem_script.as_slice().as_array::<26>()
            };
            message_hash = serialize_p2wpkh_sighash_all(
                self.cur_transaction,
                self.input_to_sign,
                amount,
                script_code,
            );
        } else if address.is_p2wsh() {
            let amount = self.prev_transaction.get_amount(self.output_to_unlock);
            // let script_code = self.cur_transaction.get_witness_script_with_size::<SCRIPT_CODE_LEN>(
            //     self.input_to_sign,
            // );
            message_hash = serialize_p2wsh_sighash_all(
                self.cur_transaction,
                self.input_to_sign,
                amount,
                self.redeem_script,
            );
        } else {
            assert(false, "not implemented");
        }
        message_hash
    }

    fn get_sighash_all_anyonecanpay_message_hash<let SCRIPT_CODE_LEN: u32, let N_INPUT_SIZE: u32>(
        &mut self,
        address: Address,
    ) -> [u8; 32] {
        let mut message_hash = [0; 32];
        if address.is_p2pk() | address.is_p2pkh() | address.is_p2ms() {
            let script_code = self.prev_transaction.get_script_pub_key_with_size::<SCRIPT_CODE_LEN>(
                self.output_to_unlock,
            );
            message_hash = serialize_sighash_all_anyonecanpay::<CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, SCRIPT_CODE_LEN, N_INPUT_SIZE>(
                self.cur_transaction,
                self.input_to_sign,
                script_code,
            );
        } else if address.is_p2sh() {
            message_hash = serialize_sighash_all_anyonecanpay::<CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, REDEEM_SCRIPT_LEN, N_INPUT_SIZE>(
                self.cur_transaction,
                self.input_to_sign,
                self.redeem_script,
            );
        } else if address.is_p2wpkh() {
            let amount = self.prev_transaction.get_amount(self.output_to_unlock);
            let script_code = if self.redeem_script.len() == 0 {
                self.prev_transaction.get_p2wpkh_script_code(self.output_to_unlock)
            } else {
                assert(REDEEM_SCRIPT_LEN == 26);
                self.redeem_script.as_slice().as_array::<26>()
            };
            message_hash = serialize_p2wpkh_sighash_all_anyonecanpay(
                self.cur_transaction,
                self.input_to_sign,
                amount,
                script_code,
            );
        } else if address.is_p2wsh() {
            let amount = self.prev_transaction.get_amount(self.output_to_unlock);
            // let script_code = self.cur_transaction.get_witness_script_with_size::<SCRIPT_CODE_LEN>(
            //     self.input_to_sign,
            // );
            message_hash = serialize_p2wsh_sighash_all_anyonecanpay(
                self.cur_transaction,
                self.input_to_sign,
                amount,
                self.redeem_script,
            );
        } else {
            assert(false, "not implemented");
        }
        message_hash
    }

    fn get_sighash_none_message_hash<let SCRIPT_CODE_LEN: u32>(
        &mut self,
        address: Address,
    ) -> [u8; 32] {
        let mut message_hash = [0; 32];
        if address.is_p2pk() | address.is_p2pkh() | address.is_p2ms() {
            let script_code = self.prev_transaction.get_script_pub_key_with_size::<SCRIPT_CODE_LEN>(
                self.output_to_unlock,
            );
            message_hash =
                serialize_sighash_none(self.cur_transaction, self.input_to_sign, script_code);
        } else if address.is_p2sh() {
            message_hash = serialize_sighash_none(
                self.cur_transaction,
                self.input_to_sign,
                self.redeem_script,
            );
        } else if address.is_p2wpkh() {
            let amount = self.prev_transaction.get_amount(self.output_to_unlock);
            let script_code = if self.redeem_script.len() == 0 {
                self.prev_transaction.get_p2wpkh_script_code(self.output_to_unlock)
            } else {
                assert(REDEEM_SCRIPT_LEN == 26);
                self.redeem_script.as_slice().as_array::<26>()
            };
            message_hash = serialize_p2wpkh_sighash_none(
                self.cur_transaction,
                self.input_to_sign,
                amount,
                script_code,
            );
        } else if address.is_p2wsh() {
            let amount = self.prev_transaction.get_amount(self.output_to_unlock);
            // let script_code = self.cur_transaction.get_witness_script_with_size::<SCRIPT_CODE_LEN>(
            //     self.input_to_sign,
            // );
            message_hash = serialize_p2wsh_sighash_none(
                self.cur_transaction,
                self.input_to_sign,
                amount,
                self.redeem_script,
            );
        } else {
            assert(false, "not implemented");
        }
        message_hash
    }

    fn get_sighash_none_anyonecanpay_message_hash<let SCRIPT_CODE_LEN: u32, let N_INPUT_SIZE: u32>(
        &mut self,
        address: Address,
    ) -> [u8; 32] {
        let mut message_hash = [0; 32];
        if address.is_p2pk() | address.is_p2pkh() | address.is_p2ms() {
            let script_code = self.prev_transaction.get_script_pub_key_with_size::<SCRIPT_CODE_LEN>(
                self.output_to_unlock,
            );
            message_hash = serialize_sighash_none_anyonecanpay::<CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, SCRIPT_CODE_LEN, N_INPUT_SIZE>(
                self.cur_transaction,
                self.input_to_sign,
                script_code,
            );
        } else if address.is_p2sh() {
            message_hash = serialize_sighash_none_anyonecanpay::<CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, REDEEM_SCRIPT_LEN, N_INPUT_SIZE>(
                self.cur_transaction,
                self.input_to_sign,
                self.redeem_script,
            );
        } else if address.is_p2wpkh() {
            let amount = self.prev_transaction.get_amount(self.output_to_unlock);
            let script_code = if self.redeem_script.len() == 0 {
                self.prev_transaction.get_p2wpkh_script_code(self.output_to_unlock)
            } else {
                assert(REDEEM_SCRIPT_LEN == 26);
                self.redeem_script.as_slice().as_array::<26>()
            };
            message_hash = serialize_p2wpkh_sighash_none_anyonecanpay(
                self.cur_transaction,
                self.input_to_sign,
                amount,
                script_code,
            );
        } else if address.is_p2wsh() {
            let amount = self.prev_transaction.get_amount(self.output_to_unlock);
            // let script_code = self.cur_transaction.get_witness_script_with_size::<SCRIPT_CODE_LEN>(
            //     self.input_to_sign,
            // );
            message_hash = serialize_p2wsh_sighash_none_anyonecanpay(
                self.cur_transaction,
                self.input_to_sign,
                amount,
                self.redeem_script,
            );
        } else {
            assert(false, "not implemented");
        }
        message_hash
    }

    fn get_sighash_single_message_hash<let SCRIPT_CODE_LEN: u32, let N_OUTPUT_SIZE: u32, let INPUT_TO_SIGN: u32, let INPUT_TO_SIGN_LEN: u32>(
        &mut self,
        address: Address,
    ) -> [u8; 32] {
        let mut message_hash = [0; 32];
        if address.is_p2pk() | address.is_p2pkh() | address.is_p2ms() {
            let script_code = self.prev_transaction.get_script_pub_key_with_size::<SCRIPT_CODE_LEN>(
                self.output_to_unlock,
            );
            message_hash = serialize_sighash_single::<CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, SCRIPT_CODE_LEN, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN>(
                self.cur_transaction,
                self.input_to_sign,
                script_code,
            );
        } else if address.is_p2sh() {
            message_hash = serialize_sighash_single::<CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, REDEEM_SCRIPT_LEN, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN>(
                self.cur_transaction,
                self.input_to_sign,
                self.redeem_script,
            );
        } else if address.is_p2wpkh() {
            let amount = self.prev_transaction.get_amount(self.output_to_unlock);
            let script_code = if self.redeem_script.len() == 0 {
                self.prev_transaction.get_p2wpkh_script_code(self.output_to_unlock)
            } else {
                assert(REDEEM_SCRIPT_LEN == 26);
                self.redeem_script.as_slice().as_array::<26>()
            };
            message_hash = serialize_p2wpkh_sighash_single::<CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, N_OUTPUT_SIZE>(
                self.cur_transaction,
                self.input_to_sign,
                amount,
                script_code,
            );
        } else if address.is_p2wsh() {
            let amount = self.prev_transaction.get_amount(self.output_to_unlock);
            // let script_code = self.cur_transaction.get_witness_script_with_size::<SCRIPT_CODE_LEN>(
            //     self.input_to_sign,
            // );
            message_hash = serialize_p2wsh_sighash_single::<CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, REDEEM_SCRIPT_LEN, N_OUTPUT_SIZE>(
                self.cur_transaction,
                self.input_to_sign,
                amount,
                self.redeem_script,
            );
        } else {
            assert(false, "not implemented");
        }
        message_hash
    }

    fn get_sighash_single_anyonecanpay_message_hash<let SCRIPT_CODE_LEN: u32, let N_OUTPUT_SIZE: u32, let INPUT_TO_SIGN: u32, let INPUT_TO_SIGN_LEN: u32, let N_INPUT_SIZE: u32>(
        &mut self,
        address: Address,
    ) -> [u8; 32] {
        let mut message_hash = [0; 32];
        if address.is_p2pk() | address.is_p2pkh() | address.is_p2ms() {
            let script_code = self.prev_transaction.get_script_pub_key_with_size::<SCRIPT_CODE_LEN>(
                self.output_to_unlock,
            );
            message_hash = serialize_sighash_single_anyonecanpay::<CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, SCRIPT_CODE_LEN, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN, N_INPUT_SIZE>(
                self.cur_transaction,
                self.input_to_sign,
                script_code,
            );
        } else if address.is_p2sh() {
            message_hash = serialize_sighash_single_anyonecanpay::<CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, REDEEM_SCRIPT_LEN, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN, N_INPUT_SIZE>(
                self.cur_transaction,
                self.input_to_sign,
                self.redeem_script,
            );
        } else if address.is_p2wpkh() {
            let amount = self.prev_transaction.get_amount(self.output_to_unlock);
            let script_code = if self.redeem_script.len() == 0 {
                self.prev_transaction.get_p2wpkh_script_code(self.output_to_unlock)
            } else {
                assert(REDEEM_SCRIPT_LEN == 26);
                self.redeem_script.as_slice().as_array::<26>()
            };
            message_hash = serialize_p2wpkh_sighash_single_anyonecanpay::<CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, N_OUTPUT_SIZE>(
                self.cur_transaction,
                self.input_to_sign,
                amount,
                script_code,
            );
        } else if address.is_p2wsh() {
            let amount = self.prev_transaction.get_amount(self.output_to_unlock);
            // let script_code = self.cur_transaction.get_witness_script_with_size::<SCRIPT_CODE_LEN>(
            //     self.input_to_sign,
            // );
            message_hash = serialize_p2wsh_sighash_single_anyonecanpay::<CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, REDEEM_SCRIPT_LEN, N_OUTPUT_SIZE>(
                self.cur_transaction,
                self.input_to_sign,
                amount,
                self.redeem_script,
            );
        } else {
            assert(false, "not implemented");
        }
        message_hash
    }

    fn _op_checksig<let SCRIPT_CODE_LEN: u32, let N_OUTPUT_SIZE: u32, let INPUT_TO_SIGN: u32, let INPUT_TO_SIGN_LEN: u32, let N_INPUT_SIZE: u32>(
        &mut self,
        address: Address,
        sigadd: bool,
    ) -> (bool, i32) {
        let mut message_hash = [0; 32];
        let mut n = 0;
        let mut res = true;

        let (pub_x, pub_y) = self.pop_pubkey();
        if sigadd {
            n = vec_to_i32(self.pop());
        }
        let (signature, hash_type, is_empty) = self.pop_signature();

        if !is_empty | !sigadd {
            if hash_type == SIGHASH_ALL {
                message_hash = self.get_sighash_all_message_hash::<SCRIPT_CODE_LEN>(address);
            } else if hash_type == SIGHASH_NONE {
                message_hash = self.get_sighash_none_message_hash::<SCRIPT_CODE_LEN>(address);
            } else if hash_type == SIGHASH_SINGLE {
                message_hash = self
                    .get_sighash_single_message_hash::<SCRIPT_CODE_LEN, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN>(
                        address,
                    );
            } else if hash_type == (SIGHASH_ALL | SIGHASH_ANYONECANPAY) {
                message_hash = self
                    .get_sighash_all_anyonecanpay_message_hash::<SCRIPT_CODE_LEN, N_INPUT_SIZE>(
                        address,
                    );
            } else if hash_type == (SIGHASH_NONE | SIGHASH_ANYONECANPAY) {
                message_hash = self
                    .get_sighash_none_anyonecanpay_message_hash::<SCRIPT_CODE_LEN, N_INPUT_SIZE>(
                        address,
                    );
            } else if hash_type == (SIGHASH_SINGLE | SIGHASH_ANYONECANPAY) {
                message_hash = self
                    .get_sighash_single_anyonecanpay_message_hash::<SCRIPT_CODE_LEN, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN, N_INPUT_SIZE>(
                        address,
                    );
            } else {
                assert(false, "Unsupported hash type");
            }

            res = ecdsa_verify(pub_x, pub_y, signature, message_hash);
            n += 1;
        }

        (res, n)
    }

    pub fn op_checksig<let SCRIPT_CODE_LEN: u32, let N_OUTPUT_SIZE: u32, let INPUT_TO_SIGN: u32, let INPUT_TO_SIGN_LEN: u32, let N_INPUT_SIZE: u32>(
        &mut self,
        address: Address,
        verify: bool,
        sigadd: bool,
    ) {
        let result = self
            ._op_checksig::<SCRIPT_CODE_LEN, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN, N_INPUT_SIZE>(
                address,
                sigadd,
            );
        if sigadd {
            assert(result.0);
            self.push(i32_to_vec(result.1));
        } else if verify {
            assert(result.0);
        } else {
            let integer = i32_to_vec(if result.0 { 1 } else { 0 });
            self.push(integer);
        }
    }

    fn _op_checksig_p2tr<let UTXO_SIZE: u32, let N_OUTPUT_SIZE: u32>(
        &mut self,
        utxo_data: [u8; UTXO_SIZE],
        sigadd: bool,
        leaf_script_hash: Option<[u8; 32]>,
        annex_hash: Option<[u8; 32]>,
    ) -> (bool, i32) {
        let mut message_hash = [0; 32];
        let mut n = 0;
        let mut res = false;

        let pubkey = self.pop();
        assert(pubkey.len() == 32, "Incorrect length of public key");

        if sigadd {
            n = vec_to_i32(self.pop());
        }
        let (signature, hash_type, is_empty) = self.pop_signature_p2tr();

        let outputs = parse_outputs::<UTXO_SIZE, CURRENT_INPUT_COUNT>(utxo_data);
        let mut n_utxo = [0 as u8; 43];

        let n_utxo_transaction_offset = outputs[self.input_to_sign].amount.offset;
        for i in 0..43 {
            n_utxo[i] = utxo_data[i + n_utxo_transaction_offset];
        }

        let mut extension_flag = 0;
        if (leaf_script_hash.is_some()) {
            extension_flag = 1;
        }

        if !is_empty | !sigadd {
            if (hash_type == SIGHASH_ALL) | (hash_type == SIGHASH_DEFAULT) {
                message_hash = serialize_p2tr_sighash_all(
                    self.cur_transaction,
                    self.input_to_sign,
                    extension_flag,
                    outputs,
                    utxo_data,
                    annex_hash,
                    leaf_script_hash,
                );
            } else if hash_type == SIGHASH_NONE {
                message_hash = serialize_p2tr_sighash_none(
                    self.cur_transaction,
                    self.input_to_sign,
                    extension_flag,
                    outputs,
                    utxo_data,
                    annex_hash,
                    leaf_script_hash,
                );
            } else if hash_type == SIGHASH_SINGLE {
                message_hash = serialize_p2tr_sighash_single::<CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, UTXO_SIZE, N_OUTPUT_SIZE>(
                    self.cur_transaction,
                    self.input_to_sign,
                    extension_flag,
                    outputs,
                    utxo_data,
                    annex_hash,
                    leaf_script_hash,
                );
            } else if hash_type == (SIGHASH_ALL | SIGHASH_ANYONECANPAY) {
                message_hash = serialize_p2tr_sighash_all_anyonecanpay(
                    self.cur_transaction,
                    self.input_to_sign,
                    extension_flag,
                    n_utxo,
                    annex_hash,
                    leaf_script_hash,
                );
            } else if hash_type == (SIGHASH_NONE | SIGHASH_ANYONECANPAY) {
                message_hash = serialize_p2tr_sighash_none_anyonecanpay(
                    self.cur_transaction,
                    self.input_to_sign,
                    extension_flag,
                    n_utxo,
                    annex_hash,
                    leaf_script_hash,
                );
            } else if hash_type == (SIGHASH_SINGLE | SIGHASH_ANYONECANPAY) {
                message_hash = serialize_p2tr_sighash_single_anyonecanpay::<CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, N_OUTPUT_SIZE>(
                    self.cur_transaction,
                    self.input_to_sign,
                    extension_flag,
                    n_utxo,
                    annex_hash,
                    leaf_script_hash,
                );
            } else {
                assert(false, "Unsupported hash type");
            }

            res = schnorr_verify(
                vec_to_array::<MAX_STACK_ELEMENT_SIZE, 32>(pubkey),
                message_hash,
                signature,
            );
            n += 1;
        }

        (res, n)
    }

    pub fn op_checksig_p2tr<let UTXO_SIZE: u32, let N_OUTPUT_SIZE: u32>(
        &mut self,
        utxo_data: [u8; UTXO_SIZE],
        verify: bool,
        sigadd: bool,
        annex_hash: Option<[u8; 32]>,
        leaf_script_hash: Option<[u8; 32]>,
    ) {
        let result = self._op_checksig_p2tr::<UTXO_SIZE, N_OUTPUT_SIZE>(
            utxo_data,
            sigadd,
            leaf_script_hash,
            annex_hash,
        );
        if sigadd {
            assert(result.0);
            self.push(i32_to_vec(result.1));
        } else if verify {
            assert(result.0);
        } else {
            let integer = i32_to_vec(if result.0 { 1 } else { 0 });
            self.push(integer);
        }
    }

    fn _op_checkmulsig<let SCRIPT_CODE_LEN: u32, let N_OUTPUT_SIZE: u32, let INPUT_TO_SIGN: u32, let INPUT_TO_SIGN_LEN: u32, let N_INPUT_SIZE: u32, let N: u32, let M: u32>(
        &mut self,
        address: Address,
    ) -> bool {
        let n = vec_to_u32(self.pop());
        assert(n == N, "Incorrect amount of keys");

        let mut keys = [([0; 32], [0; 32]); N];
        for i in 0..N {
            keys[i] = self.pop_pubkey();
        }

        let m = vec_to_u32(self.pop());
        assert(m == M, "Incorrect amount of signatures");

        let mut sigs = [([0; 64], 0, false); M];
        for i in 0..M {
            sigs[i] = self.pop_signature();
        }

        let o = vec_to_u32(self.pop());
        assert(o == 0, "Incorrect structure of mulsig");

        let mut sig_now = M as i32 - 1;
        for i in 0..N {
            if sig_now >= 0 {
                let mut message_hash = [0; 32];

                let (pub_x, pub_y) = keys[N - 1 - i];
                let (signature, hash_type, _) = sigs[sig_now];

                if hash_type == SIGHASH_ALL {
                    message_hash = self.get_sighash_all_message_hash::<SCRIPT_CODE_LEN>(address);
                } else if hash_type == SIGHASH_NONE {
                    message_hash = self.get_sighash_none_message_hash::<SCRIPT_CODE_LEN>(address);
                } else if hash_type == SIGHASH_SINGLE {
                    message_hash = self
                        .get_sighash_single_message_hash::<SCRIPT_CODE_LEN, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN>(
                            address,
                        );
                } else if hash_type == (SIGHASH_ALL | SIGHASH_ANYONECANPAY) {
                    message_hash = self
                        .get_sighash_all_anyonecanpay_message_hash::<SCRIPT_CODE_LEN, N_INPUT_SIZE>(
                            address,
                        );
                } else if hash_type == (SIGHASH_NONE | SIGHASH_ANYONECANPAY) {
                    message_hash = self
                        .get_sighash_none_anyonecanpay_message_hash::<SCRIPT_CODE_LEN, N_INPUT_SIZE>(
                            address,
                        );
                } else if hash_type == (SIGHASH_SINGLE | SIGHASH_ANYONECANPAY) {
                    message_hash = self
                        .get_sighash_single_anyonecanpay_message_hash::<SCRIPT_CODE_LEN, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN, N_INPUT_SIZE>(
                            address,
                        );
                } else {
                    assert(false, "Unsupported hash type");
                }

                if ecdsa_verify(pub_x, pub_y, signature, message_hash) {
                    sig_now -= 1;
                }
            }
        }

        sig_now == -1
    }

    pub fn op_checkmulsig<let SCRIPT_CODE_LEN: u32, let N_OUTPUT_SIZE: u32, let INPUT_TO_SIGN: u32, let INPUT_TO_SIGN_LEN: u32, let N_INPUT_SIZE: u32, let N: u32, let M: u32>(
        &mut self,
        address: Address,
        verify: bool,
    ) {
        let result = self
            ._op_checkmulsig::<SCRIPT_CODE_LEN, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN, N_INPUT_SIZE, N, M>(
                address,
            );
        if verify {
            assert(result);
        } else {
            let integer = i32_to_vec(if result { 1 } else { 0 });
            self.push(integer);
        }
    }
}

pub type TestStack<let MAX_STACK_ELEMENT_SIZE: u32, let MAX_STACK_SIZE: u32> = Stack<MAX_STACK_ELEMENT_SIZE, MAX_STACK_SIZE, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>;

#[test]
fn test_addition() {
    let mut stack: TestStack<100, 10> = Stack::new_test_stack();

    let a = 12345;
    let b = 4648;
    let c = a + b;

    let a_bytes = i32_to_le_bytes(a);
    let b_bytes = i32_to_le_bytes(b);
    let c_bytes = i32_to_le_bytes(c);

    stack.op_pushbytes(a_bytes);
    stack.op_pushbytes(b_bytes);
    stack.op_add();
    stack.op_pushbytes(c_bytes);

    stack.op_equal();

    assert(vec_to_i32(stack.pop()) == 1);
}

#[test]
fn test_op_num() {
    let mut stack: TestStack<100, 10> = Stack::new_test_stack();
    stack.op_num(2);
    stack.op_num(5);
    stack.op_add();
    stack.op_num(3);
    stack.op_add();
    stack.op_num(10);

    stack.op_equal();

    let bool_vec = stack.pop();
    let bool_value = vec_to_i32(bool_vec);

    assert(bool_value == 1);

    stack.op_num(-1);
    assert(vec_to_i32(stack.pop()) == -1);
}

#[test]
fn test_dups() {
    let mut stack: TestStack<100, 10> = Stack::new_test_stack();
    stack.op_num(2);
    stack.op_ifdup();
    assert(stack.stack_size == 2);
    stack.op_num(0);
    stack.op_ifdup();
    assert(stack.stack_size == 3);
    stack.op_dup();
    assert(stack.stack_size == 4);

    stack.op_equal();
    assert(vec_to_i32(stack.pop()) == 1);
    stack.op_equal();
    assert(vec_to_i32(stack.pop()) == 1);

    stack.op_num(2);
    stack.op_num(3);
    stack.op_2dup();
    assert(vec_to_i32(stack.pop()) == 3);
    stack.op_3dup();
    assert(vec_to_i32(stack.pop()) == 2);
    assert(vec_to_i32(stack.pop()) == 3);
    assert(vec_to_i32(stack.pop()) == 2);
    assert(vec_to_i32(stack.pop()) == 2);
    assert(vec_to_i32(stack.pop()) == 3);
    assert(vec_to_i32(stack.pop()) == 2);
}

#[test]
fn test_alt_stack() {
    let mut stack: TestStack<100, 10> = Stack::new_test_stack();
    stack.op_num(2);
    stack.op_toaltstack();
    assert(stack.stack_size == 0);
    assert(stack.alt_stack_size == 1);
    stack.op_fromaltstack();
    assert(stack.stack_size == 1);
    assert(stack.alt_stack_size == 0);
}

#[test]
fn test_depth_drops() {
    let mut stack: TestStack<100, 10> = Stack::new_test_stack();
    stack.op_num(2);
    stack.op_num(5);
    stack.op_depth();
    assert(vec_to_u32(stack.pop()) == 2);
    stack.op_2drop();
    stack.op_depth();
    assert(vec_to_u32(stack.pop()) == 0);
}

#[test]
fn test_nip_overs() {
    let mut stack: TestStack<100, 10> = Stack::new_test_stack();
    stack.op_num(2);
    stack.op_num(5);
    stack.op_over();
    stack.op_nip();
    stack.op_equal();
    assert(vec_to_i32(stack.pop()) == 1);

    stack.op_num(3);
    stack.op_num(4);
    stack.op_num(1);
    stack.op_num(2);
    stack.op_2over();
    assert(vec_to_i32(stack.pop()) == 4);
    assert(vec_to_i32(stack.pop()) == 3);
    assert(vec_to_i32(stack.pop()) == 2);
    assert(vec_to_i32(stack.pop()) == 1);
    assert(vec_to_i32(stack.pop()) == 4);
    assert(vec_to_i32(stack.pop()) == 3);
}

#[test]
fn test_pick() {
    let mut stack: TestStack<100, 10> = Stack::new_test_stack();
    stack.op_num(2);
    stack.op_num(5);
    stack.op_num(3);
    stack.op_num(1);
    stack.op_pick();
    assert(vec_to_u32(stack.pop()) == 5);
}

#[test]
fn test_roll() {
    let mut stack: TestStack<100, 10> = Stack::new_test_stack();
    stack.op_num(2);
    stack.op_num(5);
    stack.op_num(3);
    stack.op_num(2);
    stack.op_roll();
    assert(vec_to_u32(stack.pop()) == 2);
}

#[test]
fn test_swaps() {
    let mut stack: TestStack<100, 10> = Stack::new_test_stack();
    stack.op_num(2);
    stack.op_num(5);
    stack.op_swap();
    assert(vec_to_u32(stack.pop()) == 2);

    stack.op_num(2);
    stack.op_num(5);
    stack.op_num(3);
    stack.op_2swap();
    assert(vec_to_u32(stack.pop()) == 2);
    assert(vec_to_u32(stack.pop()) == 5);
    assert(vec_to_u32(stack.pop()) == 3);
    assert(vec_to_u32(stack.pop()) == 5);
}

#[test]
fn test_tuck() {
    let mut stack: TestStack<100, 10> = Stack::new_test_stack();
    stack.op_num(2);
    stack.op_num(5);
    stack.op_tuck();
    assert(vec_to_u32(stack.pop()) == 5);
    assert(vec_to_u32(stack.pop()) == 2);
    assert(vec_to_u32(stack.pop()) == 5);
}

#[test]
fn test_rots() {
    let mut stack: TestStack<100, 10> = Stack::new_test_stack();
    stack.op_num(1);
    stack.op_num(2);
    stack.op_num(3);
    stack.op_rot();
    assert(vec_to_u32(stack.pop()) == 1);
    assert(vec_to_u32(stack.pop()) == 3);
    assert(vec_to_u32(stack.pop()) == 2);

    stack.op_num(1);
    stack.op_num(2);
    stack.op_num(3);
    stack.op_num(4);
    stack.op_num(5);
    stack.op_num(6);
    stack.op_2rot();
    assert(vec_to_u32(stack.pop()) == 2);
    assert(vec_to_u32(stack.pop()) == 1);
    assert(vec_to_u32(stack.pop()) == 6);
    assert(vec_to_u32(stack.pop()) == 5);
    assert(vec_to_u32(stack.pop()) == 4);
    assert(vec_to_u32(stack.pop()) == 3);
}

#[test]
fn test_ripemd160() {
    let mut stack: TestStack<20, 10> = Stack::new_test_stack();
    stack.op_num(1);
    stack.op_ripemd160::<1>();
    assert(
        stack.pop().storage()
            == [
                0xf2, 0x91, 0xba, 0x50, 0x15, 0xdf, 0x34, 0x8c, 0x80, 0x85, 0x3f, 0xa5, 0xbb, 0x0f,
                0x79, 0x46, 0xf5, 0xc9, 0xe1, 0xb3,
            ],
    );
}

#[test]
fn test_sha1() {
    let mut stack: TestStack<20, 10> = Stack::new_test_stack();
    stack.op_num(1);
    stack.op_sha1::<1>();
    assert(
        stack.pop().storage()
            == [
                0xbf, 0x8b, 0x45, 0x30, 0xd8, 0xd2, 0x46, 0xdd, 0x74, 0xac, 0x53, 0xa1, 0x34, 0x71,
                0xbb, 0xa1, 0x79, 0x41, 0xdf, 0xf7,
            ],
    );
}

#[test]
fn test_sha256() {
    let mut stack: TestStack<32, 10> = Stack::new_test_stack();
    stack.op_num(1);
    stack.op_sha256::<1>();
    assert(
        stack.pop().storage()
            == [
                0x4b, 0xf5, 0x12, 0x2f, 0x34, 0x45, 0x54, 0xc5, 0x3b, 0xde, 0x2e, 0xbb, 0x8c, 0xd2,
                0xb7, 0xe3, 0xd1, 0x60, 0x0a, 0xd6, 0x31, 0xc3, 0x85, 0xa5, 0xd7, 0xcc, 0xe2, 0x3c,
                0x77, 0x85, 0x45, 0x9a,
            ],
    );
}

#[test]
fn test_hash160() {
    let mut stack: TestStack<20, 10> = Stack::new_test_stack();
    stack.op_num(1);
    stack.op_hash160::<1>();
    assert(
        stack.pop().storage()
            == [
                0xc5, 0x1b, 0x66, 0xbc, 0xed, 0x5e, 0x44, 0x91, 0x00, 0x1b, 0xd7, 0x02, 0x66, 0x97,
                0x70, 0xdc, 0xcf, 0x44, 0x09, 0x82,
            ],
    );
}

#[test]
fn test_hash256() {
    let mut stack: TestStack<32, 10> = Stack::new_test_stack();
    stack.op_num(1);
    stack.op_hash256::<1>();
    assert(
        stack.pop().storage()
            == [
                0x9c, 0x12, 0xcf, 0xdc, 0x04, 0xc7, 0x45, 0x84, 0xd7, 0x87, 0xac, 0x3d, 0x23, 0x77,
                0x21, 0x32, 0xc1, 0x85, 0x24, 0xbc, 0x7a, 0xb2, 0x8d, 0xec, 0x42, 0x19, 0xb8, 0xfc,
                0x5b, 0x42, 0x5f, 0x70,
            ],
    );
}

#[test]
fn test_arithmetic() {
    let mut stack: TestStack<100, 10> = Stack::new_test_stack();
    stack.op_num(10);
    stack.op_num(2);
    stack.op_sub();
    stack.op_1add();
    stack.op_negate();
    stack.op_1sub();
    stack.op_dup();
    stack.op_dup();
    assert(vec_to_i32(stack.pop()) == -10);
    stack.op_abs();
    assert(vec_to_i32(stack.pop()) == 10);
    stack.op_0notequal();
    assert(vec_to_i32(stack.pop()) == 1);
}

#[test]
fn test_logical() {
    let mut stack: TestStack<100, 10> = Stack::new_test_stack();
    stack.op_num(10);
    stack.op_num(0);
    stack.op_2dup();
    stack.op_booland();
    assert(vec_to_i32(stack.pop()) == 0);
    stack.op_boolor();
    stack.op_not();
    assert(vec_to_i32(stack.pop()) == 0);

    stack.op_num(10);
    stack.op_num(10);
    stack.op_2dup();
    stack.op_numequal();
    assert(vec_to_i32(stack.pop()) == 1);
    stack.op_numnotequal();
    assert(vec_to_i32(stack.pop()) == 0);

    stack.op_num(10);
    stack.op_num(13);
    stack.op_num(13);
    stack.op_num(10);
    stack.op_greaterthan();
    stack.op_toaltstack();
    stack.op_lessthan();
    stack.op_fromaltstack();
    stack.op_equal();
    assert(vec_to_i32(stack.pop()) == 1);

    stack.op_num(10);
    stack.op_num(10);
    stack.op_num(12);
    stack.op_num(10);
    stack.op_greaterthanorequal();
    stack.op_toaltstack();
    stack.op_lessthanorequal();
    stack.op_fromaltstack();
    stack.op_equal();
    assert(vec_to_i32(stack.pop()) == 1);
}

#[test]
fn test_max_min_range() {
    let mut stack: TestStack<100, 10> = Stack::new_test_stack();
    stack.op_num(10);
    stack.op_num(12);
    stack.op_max();
    assert(vec_to_i32(stack.pop()) == 12);

    stack.op_num(10);
    stack.op_num(12);
    stack.op_min();
    assert(vec_to_i32(stack.pop()) == 10);

    stack.op_num(10);
    stack.op_num(10);
    stack.op_num(15);
    stack.op_within();
    assert(vec_to_i32(stack.pop()) == 1);
}

#[test]
fn test_legacy_checksig_all() {
    // From here: https://www.blockchain.com/explorer/transactions/btc/12e753ef5cc30925a6eee2c457aa7f53022443ca013ea81882a6b59b69e342a6
    // Transaction with deleted script sigs
    let cur_tx_hex = "01000000030dd7891efbf67da47c651531db8aab3144ed7a524e4ae1e30b773525e27ddd7b0000000000ffffffff16851666962e37a75a246101f2e340c628b1db3c045d4d3cfb2d1c0f58f97c6f0000000000ffffffffffda5d38e91fd9a0d92872d51f83cb746fc7bf5d3ff13402f8d0d5ed60ddc79c0000000000ffffffff02c0c62d00000000001976a91417194e1bd175fb5b1b2a1f9d221f6f5c29e1928388ac00c817a8040000001976a91465bda9b05f7e9a8f96a7f4ba0996a877708ef90888ac00000000";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<201, 3, 1, 124, 2, 1, 69, 0, 0>::new(cur_tx_bytes, false);

    let input_to_sign = 1;

    // From here: https://www.blockchain.com/explorer/transactions/btc/6f7cf9580f1c2dfb3c4d5d043cdbb128c640e3f20161245aa7372e9666168516
    let prev_tx_hex = "0100000002f60b5e96f09422354ab150b0e506c4bffedaf20216d30059cc5a3061b4c83dff000000004a493046022100e26d9ff76a07d68369e5782be3f8532d25ecc8add58ee256da6c550b52e8006b022100b4431f5a9a4dcb51cbdcaae935218c0ae4cfc8aa903fe4e5bac4c208290b7d5d01fffffffff7272ef43189f5553c2baea50f59cde99b3220fd518884d932016d055895b62d000000004a493046022100a2ab7cdc5b67aca032899ea1b262f6e8181060f5a34ee667a82dac9c7b7db4c3022100911bc945c4b435df8227466433e56899fbb65833e4853683ecaa12ee840d16bf01ffffffff0100e40b54020000001976a91412ab8dc588ca9d5787dde7eb29569da63c3a238c88ac00000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<274, 2, 1, 231, 1, 1, 35, 0, 0>::new(prev_tx_bytes, false);

    let output_to_unlock = 0;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        [],
    );

    let signature_hex: str<144> = "304502203f004eeed0cef2715643e2f25a27a28f3c578e94c7f0f6a4df104e7d163f7f8f022100b8b248c1cfd8f77a0365107a9511d759b7544d979dd152a955c867afac0ef78601";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex: str<130> = "044d05240cfbd8a2786eda9dadd520c1609b8593ff8641018d57703d02ba687cf2f187f0cee2221c3afb1b5ff7888caced2423916b61444666ca1216f26181398c";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    //without 1 on N_INPUT_SIZE failing test
    stack.op_checksig::<26, 0, 0, 0, 1>(Address::new_p2pkh(), true, false);
}

#[test]
fn test_segwit_checksig_all() {
    // From here: https://www.blockchain.com/explorer/transactions/btc/ca7e89a098385f2053b88d4ef28974c17f2034b84116136705af366cb2a2d26f
    let cur_tx_hex = "02000000000101822952a47327be304809fb6b6c0e55a27321146e5151b1f1bccdce35bba99fb20000000000fdffffff0658020000000000002251208625054ae2eca687577e35ae70c6646fd47ff1276fe64b85a10e034f30b5136a4a010000000000001600148a8c751ab2a5fe26e68210b36019c6b0bfe024694a010000000000001600148a8c751ab2a5fe26e68210b36019c6b0bfe0246922020000000000001600148a8c751ab2a5fe26e68210b36019c6b0bfe024694a010000000000001600148a8c751ab2a5fe26e68210b36019c6b0bfe02469482b1101000000002251208625054ae2eca687577e35ae70c6646fd47ff1276fe64b85a10e034f30b5136a02483045022100acbc5aeef43fa19a7078d34e84177534c40e2ad8cee5ff4deb5aae2b4650f864022026288d3d694fdd6e592bfb5d200848206848bb0c8f0119ffee831ed7a7a148d001210310217ab07ffb6f90fb9dd925c3e950d74003ba26aad82d09b1da730ac2b3b8da00000000";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<371, 1, 1, 42, 6, 1, 211, 2, 108>::new(cur_tx_bytes, true);

    let input_to_sign = 0;

    // From here: https://www.blockchain.com/explorer/transactions/btc/b29fa9bb35cecdbcf1b151516e142173a2550e6c6bfb094830be2773a4522982
    let prev_tx_hex = "02000000000106be778a8d6493de9cae18155c3c761b9334d6223916310348c17c587f2fb7992c0500000000ffffffffb529dd3f119f36705bee141134aca6d1400fbf6ab22927ca1b16a6846ab351df0000000000ffffffffb0e5e81a0e4fa61bac8fa31f11eb0a4a58d97b6ca9b2445f36bfd26662c350000000000000ffffffffabd075d382452621f65a24d921ff4dcc813a300a9517ffb3e7a514197becb6da0000000000ffffffff4a01d9e9564bb99949ff91cc4554832f1c0c1bb37acaa02bc83f011f4a505da20000000000ffffffffcd39ad5bcb73b1c0c611dda48499c8963cb80725a2cb801d39b202558e13c3b80200000000ffffffff05e4381101000000001600148a8c751ab2a5fe26e68210b36019c6b0bfe0246900ee020000000000225120943e0e9878cf21609289994525741ddae45e83d73ffe73283c311cc65d11200fa0fd020000000000225120943e0e9878cf21609289994525741ddae45e83d73ffe73283c311cc65d11200fa062070000000000225120270da8a60c0d7f197e45cf49d3c0367c74739a9c49434ad6b491aaf88c7c57e384310900000000002251205674a20e0690c723138a032d5852fbee91f702ed83efd71f65b9b02224d34e680140c2907f4fd021b2ce513c7913d2d89692a4880a28a359f764935ff6474687547874cc2021cbc7ee97fe35040338c62311349c7fe6debdf12ea79c2122dfc7901001416027f838bc31e24523c83c9e9df04df6ba970348ae7bd5c0346062c562910a74ae4807a41dd41ac5bd83c69ce35165a6e7119d14e9c605b918ac766929599dd3830141cfee2552147af1f4112068197886359a25868cad9b17d2af7ae47784180a03f61b89bf54db4177e4db52755b2c2594314fd46850eca080c09813d12bfc699955830141ec28538e01eca31282dca1df1b018ba430a27bc8f0cd409ff4985f74bcde81e8e663bf3fe73b884bd69a54eb4c0e154552f9882b7d0f4db6db8b1d28d2edf1398301410029733548627ca3bc366575203481e94cc01ae9c03a535b40ce50d1a72472e077e6210cb227a6bc3efa4cf4bd63c94f4fdf9f523fac40eccc17e525600284b8830140ed4ba22ed2ba0eb1a21c941e261107c70942860ceccc9d69df816706e126eb7908c168c5c67f9d28993363656ecf836f889e34ada97ae6754e7dfee58d22f67000000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<861, 6, 1, 247, 5, 1, 204, 1, 400>::new(prev_tx_bytes, true);

    let output_to_unlock = 0;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        [],
    );

    let signature_hex = "3045022100acbc5aeef43fa19a7078d34e84177534c40e2ad8cee5ff4deb5aae2b4650f864022026288d3d694fdd6e592bfb5d200848206848bb0c8f0119ffee831ed7a7a148d001";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex = "0310217ab07ffb6f90fb9dd925c3e950d74003ba26aad82d09b1da730ac2b3b8da";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);

    stack.op_checksig::<22, 0, 0, 0, 1>(Address::new_p2wpkh(), true, false);
}

#[test]
fn test_legacy_checksig_all_anyonecanpay() {
    let cur_tx_hex = "01000000030dd7891efbf67da47c651531db8aab3144ed7a524e4ae1e30b773525e27ddd7b0000000000ffffffff16851666962e37a75a246101f2e340c628b1db3c045d4d3cfb2d1c0f58f97c6f0000000000ffffffffffda5d38e91fd9a0d92872d51f83cb746fc7bf5d3ff13402f8d0d5ed60ddc79c0000000000ffffffff02c0c62d00000000001976a91417194e1bd175fb5b1b2a1f9d221f6f5c29e1928388ac00c817a8040000001976a91465bda9b05f7e9a8f96a7f4ba0996a877708ef90888ac00000000";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<201, 3, 1, 124, 2, 1, 69, 0, 0>::new(cur_tx_bytes, false);

    let input_to_sign = 1;

    let prev_tx_hex = "0100000002f60b5e96f09422354ab150b0e506c4bffedaf20216d30059cc5a3061b4c83dff000000004a493046022100e26d9ff76a07d68369e5782be3f8532d25ecc8add58ee256da6c550b52e8006b022100b4431f5a9a4dcb51cbdcaae935218c0ae4cfc8aa903fe4e5bac4c208290b7d5d01fffffffff7272ef43189f5553c2baea50f59cde99b3220fd518884d932016d055895b62d000000004a493046022100a2ab7cdc5b67aca032899ea1b262f6e8181060f5a34ee667a82dac9c7b7db4c3022100911bc945c4b435df8227466433e56899fbb65833e4853683ecaa12ee840d16bf01ffffffff0100e40b54020000001976a91412ab8dc588ca9d5787dde7eb29569da63c3a238c88ac00000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<274, 2, 1, 231, 1, 1, 35, 0, 0>::new(prev_tx_bytes, false);

    let output_to_unlock = 0;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        [],
    );

    let signature_hex: str<144> = "3045022100dfd13b2aec3c6a96c550d9a51958f894ccd736dbad0013e8e722f93b5f93cce50220701f92efd753b3235d5d3c404ce263147123808bfd2b8fd4997b874105bced8381";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex: str<130> = "0424653eac434488002cc06bbfb7f10fe18991e35f9fe4302dbea6d2353dc0ab1c119fc5009a032aa9fe47f5e149bb8442f71f884ccb516590686d8ff6ab91c613";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<26, 0, 0, 0, 41>(Address::new_p2pkh(), true, false);
}

#[test]
fn test_legacy_checksig_none() {
    let cur_tx_hex = "01000000030dd7891efbf67da47c651531db8aab3144ed7a524e4ae1e30b773525e27ddd7b0000000000ffffffff16851666962e37a75a246101f2e340c628b1db3c045d4d3cfb2d1c0f58f97c6f0000000000ffffffffffda5d38e91fd9a0d92872d51f83cb746fc7bf5d3ff13402f8d0d5ed60ddc79c0000000000ffffffff02c0c62d00000000001976a91417194e1bd175fb5b1b2a1f9d221f6f5c29e1928388ac00c817a8040000001976a91465bda9b05f7e9a8f96a7f4ba0996a877708ef90888ac00000000";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<201, 3, 1, 124, 2, 1, 69, 0, 0>::new(cur_tx_bytes, false);

    let input_to_sign = 0;

    let prev_tx_hex = "0100000002f60b5e96f09422354ab150b0e506c4bffedaf20216d30059cc5a3061b4c83dff000000004a493046022100e26d9ff76a07d68369e5782be3f8532d25ecc8add58ee256da6c550b52e8006b022100b4431f5a9a4dcb51cbdcaae935218c0ae4cfc8aa903fe4e5bac4c208290b7d5d01fffffffff7272ef43189f5553c2baea50f59cde99b3220fd518884d932016d055895b62d000000004a493046022100a2ab7cdc5b67aca032899ea1b262f6e8181060f5a34ee667a82dac9c7b7db4c3022100911bc945c4b435df8227466433e56899fbb65833e4853683ecaa12ee840d16bf01ffffffff0100e40b54020000001976a91412ab8dc588ca9d5787dde7eb29569da63c3a238c88ac00000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<274, 2, 1, 231, 1, 1, 35, 0, 0>::new(prev_tx_bytes, false);

    let output_to_unlock = 0;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        [],
    );

    let signature_hex: str<144> = "304502210098a43f26f14d778c053b4dcd7df5de417b0432460bf3013d4faf0b4c46364641022000884b207007b22c7534c60c98d5f614b74ff34286c18e0b7e9e33f39cca494302";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex: str<130> = "045be5e9478209674a96e60f1f037f6176540fd001fa1d64694770c56a7709c42c035a88c3843dbf8b10d52cc71e26cce171e1aa1e32f8e193c9f6a6bd8f07b8bf";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<26, 0, 0, 0, 1>(Address::new_p2pkh(), true, false);
}

#[test]
fn test_legacy_checksig_none_anyonecanpay() {
    let cur_tx_hex = "01000000030dd7891efbf67da47c651531db8aab3144ed7a524e4ae1e30b773525e27ddd7b0000000000ffffffff16851666962e37a75a246101f2e340c628b1db3c045d4d3cfb2d1c0f58f97c6f0000000000ffffffffffda5d38e91fd9a0d92872d51f83cb746fc7bf5d3ff13402f8d0d5ed60ddc79c0000000000ffffffff02c0c62d00000000001976a91417194e1bd175fb5b1b2a1f9d221f6f5c29e1928388ac00c817a8040000001976a91465bda9b05f7e9a8f96a7f4ba0996a877708ef90888ac00000000";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<201, 3, 1, 124, 2, 1, 69, 0, 0>::new(cur_tx_bytes, false);

    let input_to_sign = 1;

    let prev_tx_hex = "0100000002f60b5e96f09422354ab150b0e506c4bffedaf20216d30059cc5a3061b4c83dff000000004a493046022100e26d9ff76a07d68369e5782be3f8532d25ecc8add58ee256da6c550b52e8006b022100b4431f5a9a4dcb51cbdcaae935218c0ae4cfc8aa903fe4e5bac4c208290b7d5d01fffffffff7272ef43189f5553c2baea50f59cde99b3220fd518884d932016d055895b62d000000004a493046022100a2ab7cdc5b67aca032899ea1b262f6e8181060f5a34ee667a82dac9c7b7db4c3022100911bc945c4b435df8227466433e56899fbb65833e4853683ecaa12ee840d16bf01ffffffff0100e40b54020000001976a91412ab8dc588ca9d5787dde7eb29569da63c3a238c88ac00000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<274, 2, 1, 231, 1, 1, 35, 0, 0>::new(prev_tx_bytes, false);

    let output_to_unlock = 0;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        [],
    );

    let signature_hex: str<144> = "3045022100de220a7cb022b3268f1d4d738527ccd128f9210aec48e8c001b96d638822730d0220092336b66c9f55925abac5d2b6a724b89c16bd167caf4f627b735d577d36e5da82";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex: str<130> = "04bb58b5feca505c74edc000d8282fc556e51a1024fc8e7d7e56c6f887c5c8d5f202f76f508a57ac2491af19c8e67e55133f8e1cd3f9ee2350071497085f7356f8";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<26, 0, 0, 0, 41>(Address::new_p2pkh(), true, false);
}

#[test]
fn test_legacy_checksig_single() {
    let cur_tx_hex = "01000000056c499afac2e1a63bb6b9461a337319b970c13c2c77be53ebc1c7c870059334000800000000ffffffff00e16741107dcd7cfa2eaeb7d767e47edbec577511b3e10f16980754c3493b090900000000ffffffff078f6ec6d77fc7e0200e12fc1e2114e56e1c5bfc869d376a87b0a1bc5f8dc50e0800000000ffffffff64289405350c34a437566b764989b50381f68cf208531c54cb205f4e859e22100800000000ffffffff291cd5940ac16559eef5a2f2b4770271959f2007b45a0d850ef5d35d134df4100900000000ffffffff010000000000000000266a24e4b883e5bda9e7a59ee4bb99e9b1bcf09f909f426974636f696e20746f20506c75746f2100000000";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<262, 5, 1, 206, 1, 1, 48, 1, 0>::new(cur_tx_bytes, false);

    let input_to_sign = 0;

    let prev_tx_hex = "0100000002f60b5e96f09422354ab150b0e506c4bffedaf20216d30059cc5a3061b4c83dff000000004a493046022100e26d9ff76a07d68369e5782be3f8532d25ecc8add58ee256da6c550b52e8006b022100b4431f5a9a4dcb51cbdcaae935218c0ae4cfc8aa903fe4e5bac4c208290b7d5d01fffffffff7272ef43189f5553c2baea50f59cde99b3220fd518884d932016d055895b62d000000004a493046022100a2ab7cdc5b67aca032899ea1b262f6e8181060f5a34ee667a82dac9c7b7db4c3022100911bc945c4b435df8227466433e56899fbb65833e4853683ecaa12ee840d16bf01ffffffff0100e40b54020000001976a91412ab8dc588ca9d5787dde7eb29569da63c3a238c88ac00000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<274, 2, 1, 231, 1, 1, 35, 0, 0>::new(prev_tx_bytes, false);

    let output_to_unlock = 0;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        [],
    );

    let signature_hex: str<144> = "3045022100bb5ccc97c010dabd6317bc85290ff3f9349d2d18bd9ad2e15d12a562c65b09d202205fcbd3ac628dc3515f6eb3ce1a8ded1de837e60a60214297cd2dc1e4f035dd2b03";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex: str<130> = "042c0b7cf95324a07d05398b240174dc0c2be444d96b159aa6c7f7b1e668680991ae31a9c671a36543f46cea8fce6984608aa316aa0472a7eed08847440218cb2f";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<26, 47, 0, 1, 1>(Address::new_p2pkh(), true, false);
}

#[test]
fn test_legacy_checksig_single_anyonecanpay() {
    let cur_tx_hex = "01000000056c499afac2e1a63bb6b9461a337319b970c13c2c77be53ebc1c7c870059334000800000000ffffffff00e16741107dcd7cfa2eaeb7d767e47edbec577511b3e10f16980754c3493b090900000000ffffffff078f6ec6d77fc7e0200e12fc1e2114e56e1c5bfc869d376a87b0a1bc5f8dc50e0800000000ffffffff64289405350c34a437566b764989b50381f68cf208531c54cb205f4e859e22100800000000ffffffff291cd5940ac16559eef5a2f2b4770271959f2007b45a0d850ef5d35d134df4100900000000ffffffff010000000000000000266a24e4b883e5bda9e7a59ee4bb99e9b1bcf09f909f426974636f696e20746f20506c75746f2100000000";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<262, 5, 1, 206, 1, 1, 48, 1, 0>::new(cur_tx_bytes, false);

    let input_to_sign = 0;

    let prev_tx_hex = "0100000002f60b5e96f09422354ab150b0e506c4bffedaf20216d30059cc5a3061b4c83dff000000004a493046022100e26d9ff76a07d68369e5782be3f8532d25ecc8add58ee256da6c550b52e8006b022100b4431f5a9a4dcb51cbdcaae935218c0ae4cfc8aa903fe4e5bac4c208290b7d5d01fffffffff7272ef43189f5553c2baea50f59cde99b3220fd518884d932016d055895b62d000000004a493046022100a2ab7cdc5b67aca032899ea1b262f6e8181060f5a34ee667a82dac9c7b7db4c3022100911bc945c4b435df8227466433e56899fbb65833e4853683ecaa12ee840d16bf01ffffffff0100e40b54020000001976a91412ab8dc588ca9d5787dde7eb29569da63c3a238c88ac00000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<274, 2, 1, 231, 1, 1, 35, 0, 0>::new(prev_tx_bytes, false);

    let output_to_unlock = 0;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        [],
    );

    let signature_hex: str<144> = "3045022100bb5ccc97c010dabd6317bc85290ff3f9349d2d18bd9ad2e15d12a562c65b09d202205fcbd3ac628dc3515f6eb3ce1a8ded1de837e60a60214297cd2dc1e4f035dd2b03";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex: str<130> = "042c0b7cf95324a07d05398b240174dc0c2be444d96b159aa6c7f7b1e668680991ae31a9c671a36543f46cea8fce6984608aa316aa0472a7eed08847440218cb2f";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<26, 47, 0, 1, 1>(Address::new_p2pkh(), true, false);
}

#[test]
fn test_p2wpkh_checksig_all() {
    let cur_tx_hex = "02000000000101ac4994014aa36b7f53375658ef595b3cb2891e1735fe5b441686f5e53338e76a0100000000ffffffff01204e0000000000001976a914ce72abfd0e6d9354a660c18f2825eb392f060fdc88ac0000000000";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<88, 1, 1, 42, 1, 1, 35, 1, 1>::new(cur_tx_bytes, true);

    let input_to_sign = 0;

    let prev_tx_hex = "0200000000010192f29384a956361b9b9ebc667d01489cb360068c22c7b89396e5fdc3ece0305a0100000000ffffffff023d0500000000000016001464193f85b629823f114c9d997ee68627d7395d5fe7a1000000000000160014d0446764c4f16f78ca0ce0b7f487cc5fe205835e024730440220598ef97f63f7648e39d03ff58383056322fa13effaee8d11c9c9e8789a72522002204dda5bbc9cba008682d62820395a2c43b9abae52d6ad81835e72bda09468fa21012103d9a4d0bbe47d58b68e366a380107ba3470f6893764a2d020127d36c169df850100000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<222, 1, 1, 42, 2, 1, 63, 2, 107>::new(prev_tx_bytes, true);

    let output_to_unlock = 1;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        [],
    );

    let signature_hex: str<144> = "304502210090a81cb4cef2ab75e89767f8c447db07371c4e1dfd5f489736badb1a65c8d5d002205f1e58c3cf97b4351278b22171f7124652af9f55c5585875971d7fbf201ae20301";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex: str<130> = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<26, 35, 0, 0, 1>(Address::new_p2wpkh(), true, false);
}

#[test]
fn test_p2wpkh_checksig_all_anyonecanpay() {
    let cur_tx_hex = "02000000000101ac4994014aa36b7f53375658ef595b3cb2891e1735fe5b441686f5e53338e76a0100000000ffffffff01204e0000000000001976a914ce72abfd0e6d9354a660c18f2825eb392f060fdc88ac0000000000";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<88, 1, 1, 42, 1, 1, 35, 1, 1>::new(cur_tx_bytes, true);

    let input_to_sign = 0;

    let prev_tx_hex = "0200000000010192f29384a956361b9b9ebc667d01489cb360068c22c7b89396e5fdc3ece0305a0100000000ffffffff023d0500000000000016001464193f85b629823f114c9d997ee68627d7395d5fe7a1000000000000160014d0446764c4f16f78ca0ce0b7f487cc5fe205835e024730440220598ef97f63f7648e39d03ff58383056322fa13effaee8d11c9c9e8789a72522002204dda5bbc9cba008682d62820395a2c43b9abae52d6ad81835e72bda09468fa21012103d9a4d0bbe47d58b68e366a380107ba3470f6893764a2d020127d36c169df850100000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<222, 1, 1, 42, 2, 1, 63, 2, 107>::new(prev_tx_bytes, true);

    let output_to_unlock = 1;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        [],
    );

    let signature_hex: str<144> = "3045022100d477f71331af459ecc84d0d721b0fc9d1914116f64ffff651747ffe0831c019b02206b06cb80968a3565108e395fd6972c482e6a86a36b17cf0dca736fe366471cdd81";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex: str<130> = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<26, 35, 0, 0, 1>(Address::new_p2wpkh(), true, false);
}

#[test]
fn test_p2wpkh_checksig_none() {
    let cur_tx_hex = "02000000000101ac4994014aa36b7f53375658ef595b3cb2891e1735fe5b441686f5e53338e76a0100000000ffffffff01204e0000000000001976a914ce72abfd0e6d9354a660c18f2825eb392f060fdc88ac0000000000";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<88, 1, 1, 42, 1, 1, 35, 1, 1>::new(cur_tx_bytes, true);

    let input_to_sign = 0;

    let prev_tx_hex = "0200000000010192f29384a956361b9b9ebc667d01489cb360068c22c7b89396e5fdc3ece0305a0100000000ffffffff023d0500000000000016001464193f85b629823f114c9d997ee68627d7395d5fe7a1000000000000160014d0446764c4f16f78ca0ce0b7f487cc5fe205835e024730440220598ef97f63f7648e39d03ff58383056322fa13effaee8d11c9c9e8789a72522002204dda5bbc9cba008682d62820395a2c43b9abae52d6ad81835e72bda09468fa21012103d9a4d0bbe47d58b68e366a380107ba3470f6893764a2d020127d36c169df850100000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<222, 1, 1, 42, 2, 1, 63, 2, 107>::new(prev_tx_bytes, true);

    let output_to_unlock = 1;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        [],
    );

    let signature_hex: str<144> = "3045022100d0564fa7e4f4b919d6de7a46479f7b55a792f8be277c0bf46f70c303ec695747022064424a45a7a812dcc5f698a8fb0e8927dc1b5c5bd1afa728f4176913f678fbd302";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex: str<130> = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<26, 35, 0, 0, 1>(Address::new_p2wpkh(), true, false);
}

#[test]
fn test_p2wpkh_checksig_none_anyonecanpay() {
    let cur_tx_hex = "02000000000101ac4994014aa36b7f53375658ef595b3cb2891e1735fe5b441686f5e53338e76a0100000000ffffffff01204e0000000000001976a914ce72abfd0e6d9354a660c18f2825eb392f060fdc88ac0000000000";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<88, 1, 1, 42, 1, 1, 35, 1, 1>::new(cur_tx_bytes, true);

    let input_to_sign = 0;

    let prev_tx_hex = "0200000000010192f29384a956361b9b9ebc667d01489cb360068c22c7b89396e5fdc3ece0305a0100000000ffffffff023d0500000000000016001464193f85b629823f114c9d997ee68627d7395d5fe7a1000000000000160014d0446764c4f16f78ca0ce0b7f487cc5fe205835e024730440220598ef97f63f7648e39d03ff58383056322fa13effaee8d11c9c9e8789a72522002204dda5bbc9cba008682d62820395a2c43b9abae52d6ad81835e72bda09468fa21012103d9a4d0bbe47d58b68e366a380107ba3470f6893764a2d020127d36c169df850100000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<222, 1, 1, 42, 2, 1, 63, 2, 107>::new(prev_tx_bytes, true);

    let output_to_unlock = 1;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        [],
    );

    let signature_hex: str<144> = "3045022100b40060a6736bca65871655f964bafc4e2f649025ae45acd498c9b42b53a0c54702207c6d1aa55af0974c76f16ecbb862d995dc723bb10013b2a03d11acbb3ecdc46482";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex: str<130> = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<26, 34, 0, 0, 1>(Address::new_p2wpkh(), true, false);
}

#[test]
fn test_p2wpkh_checksig_single() {
    let cur_tx_hex = "02000000000101ac4994014aa36b7f53375658ef595b3cb2891e1735fe5b441686f5e53338e76a0100000000ffffffff01204e0000000000001976a914ce72abfd0e6d9354a660c18f2825eb392f060fdc88ac0000000000";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<88, 1, 1, 42, 1, 1, 35, 1, 1>::new(cur_tx_bytes, true);

    let input_to_sign = 0;

    let prev_tx_hex = "0200000000010192f29384a956361b9b9ebc667d01489cb360068c22c7b89396e5fdc3ece0305a0100000000ffffffff023d0500000000000016001464193f85b629823f114c9d997ee68627d7395d5fe7a1000000000000160014d0446764c4f16f78ca0ce0b7f487cc5fe205835e024730440220598ef97f63f7648e39d03ff58383056322fa13effaee8d11c9c9e8789a72522002204dda5bbc9cba008682d62820395a2c43b9abae52d6ad81835e72bda09468fa21012103d9a4d0bbe47d58b68e366a380107ba3470f6893764a2d020127d36c169df850100000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<222, 1, 1, 42, 2, 1, 63, 2, 107>::new(prev_tx_bytes, true);

    let output_to_unlock = 1;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        [],
    );

    let signature_hex: str<144> = "3045022100a682b1ee033be45ce935aec6f0e9bbf1f4af069b376a9dc9a8eb1643d52b3843022078e307b6fc2988fe6b3d7b84fcc93bdace768c7fb7efa8c775127efe162528a103";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex: str<130> = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<26, 34, 0, 0, 1>(Address::new_p2wpkh(), true, false);
}

#[test]
fn test_p2wpkh_checksig_single_anyonecanpay() {
    let cur_tx_hex = "02000000000101ac4994014aa36b7f53375658ef595b3cb2891e1735fe5b441686f5e53338e76a0100000000ffffffff01204e0000000000001976a914ce72abfd0e6d9354a660c18f2825eb392f060fdc88ac0000000000";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<88, 1, 1, 42, 1, 1, 35, 1, 1>::new(cur_tx_bytes, true);

    let input_to_sign = 0;

    let prev_tx_hex = "0200000000010192f29384a956361b9b9ebc667d01489cb360068c22c7b89396e5fdc3ece0305a0100000000ffffffff023d0500000000000016001464193f85b629823f114c9d997ee68627d7395d5fe7a1000000000000160014d0446764c4f16f78ca0ce0b7f487cc5fe205835e024730440220598ef97f63f7648e39d03ff58383056322fa13effaee8d11c9c9e8789a72522002204dda5bbc9cba008682d62820395a2c43b9abae52d6ad81835e72bda09468fa21012103d9a4d0bbe47d58b68e366a380107ba3470f6893764a2d020127d36c169df850100000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<222, 1, 1, 42, 2, 1, 63, 2, 107>::new(prev_tx_bytes, true);

    let output_to_unlock = 1;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        [],
    );

    let signature_hex: str<144> = "3045022100aac857ecbc5a35c079a923eddc78650bae6036a47b626e3c4089166e2747c76902203641ff9721d47134d2eafb6523df00d0dd37103143479243b6c63a920ec4146883";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex: str<130> = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<26, 34, 0, 0, 1>(Address::new_p2wpkh(), true, false);
}

#[test]
fn test_p2wsh_checksig_all() {
    let cur_tx_hex: str<760> = "010000000001016542b657eea04a75b1582969b5b532b3110b392b4b553297435a11b064e2eb460100000000ffffffff02c454fd000000000017a9145e7be6ec3e2382c669aaf3c71da1056f47b9024d875b07330200000000220020ea166bf0492c6f908e45404932e0f39c0571a71007c22b872548cd20f19a92f504004730440220415899bbee08e42376d06e8f86c92b4987613c2816352fe09cd1479fd639f18c02200db57f508f69e266d76c23891708158bda18690c165a41b0aa88303b97609f780147304402203973de2303e8787767090dd25c8a4dc97ce1aa7eb4c0962f13952ed4e856ff8e02203f1bb425def789eea8be46407d10b3c8730407176aef4dc2c29865eb5e5542bf0169522103848e308569b644372a5eb26665f1a8c34ca393c130b376db2fae75c43500013c2103cec1ee615c17e06d4f4b0a08617dffb8e568936bdff18fb057832a58ad4d1b752103eed7ae80c34d70f5ba93f93965f69f3c691da0f4607f242f4fd6c7a48789233e53aeee9c0900";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<380, 1, 1, 42, 2, 1, 76, 4, 252>::new(cur_tx_bytes, true);

    let input_to_sign = 0;

    let prev_tx_hex = "0200000000010192f29384a956361b9b9ebc667d01489cb360068c22c7b89396e5fdc3ece0305a0100000000ffffffff023d0500000000000016001464193f85b629823f114c9d997ee68627d7395d5fe7a1000000000000160014d0446764c4f16f78ca0ce0b7f487cc5fe205835e024730440220598ef97f63f7648e39d03ff58383056322fa13effaee8d11c9c9e8789a72522002204dda5bbc9cba008682d62820395a2c43b9abae52d6ad81835e72bda09468fa21012103d9a4d0bbe47d58b68e366a380107ba3470f6893764a2d020127d36c169df850100000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<222, 1, 1, 42, 2, 1, 63, 2, 107>::new(prev_tx_bytes, true);

    let output_to_unlock = 1;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        hex_to_bytes(
            "69522103848e308569b644372a5eb26665f1a8c34ca393c130b376db2fae75c43500013c2103cec1ee615c17e06d4f4b0a08617dffb8e568936bdff18fb057832a58ad4d1b752103eed7ae80c34d70f5ba93f93965f69f3c691da0f4607f242f4fd6c7a48789233e53ae",
        ),
    );

    let pubkey_hex: str<130> = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    let signature_hex: str<142> = "304402207adbdf42cafbecb813a8e483fa277ffa779a31fb661792693765660195182e790220044eeddd3fa1895627c988827b8ac8edad7c084c5e998a96805b62e656510d4901";
    let signature_bytes = hex_to_bytes(signature_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<106, 0, 0, 0, 1>(Address::new_p2wsh(), true, false);
}

#[test]
fn test_p2wsh_checksig_all_anyonecanpay() {
    let cur_tx_hex: str<760> = "010000000001016542b657eea04a75b1582969b5b532b3110b392b4b553297435a11b064e2eb460100000000ffffffff02c454fd000000000017a9145e7be6ec3e2382c669aaf3c71da1056f47b9024d875b07330200000000220020ea166bf0492c6f908e45404932e0f39c0571a71007c22b872548cd20f19a92f504004730440220415899bbee08e42376d06e8f86c92b4987613c2816352fe09cd1479fd639f18c02200db57f508f69e266d76c23891708158bda18690c165a41b0aa88303b97609f780147304402203973de2303e8787767090dd25c8a4dc97ce1aa7eb4c0962f13952ed4e856ff8e02203f1bb425def789eea8be46407d10b3c8730407176aef4dc2c29865eb5e5542bf0169522103848e308569b644372a5eb26665f1a8c34ca393c130b376db2fae75c43500013c2103cec1ee615c17e06d4f4b0a08617dffb8e568936bdff18fb057832a58ad4d1b752103eed7ae80c34d70f5ba93f93965f69f3c691da0f4607f242f4fd6c7a48789233e53aeee9c0900";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<380, 1, 1, 42, 2, 1, 76, 4, 252>::new(cur_tx_bytes, true);

    let input_to_sign = 0;

    let prev_tx_hex = "0200000000010192f29384a956361b9b9ebc667d01489cb360068c22c7b89396e5fdc3ece0305a0100000000ffffffff023d0500000000000016001464193f85b629823f114c9d997ee68627d7395d5fe7a1000000000000160014d0446764c4f16f78ca0ce0b7f487cc5fe205835e024730440220598ef97f63f7648e39d03ff58383056322fa13effaee8d11c9c9e8789a72522002204dda5bbc9cba008682d62820395a2c43b9abae52d6ad81835e72bda09468fa21012103d9a4d0bbe47d58b68e366a380107ba3470f6893764a2d020127d36c169df850100000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<222, 1, 1, 42, 2, 1, 63, 2, 107>::new(prev_tx_bytes, true);

    let output_to_unlock = 1;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        hex_to_bytes(
            "69522103848e308569b644372a5eb26665f1a8c34ca393c130b376db2fae75c43500013c2103cec1ee615c17e06d4f4b0a08617dffb8e568936bdff18fb057832a58ad4d1b752103eed7ae80c34d70f5ba93f93965f69f3c691da0f4607f242f4fd6c7a48789233e53ae",
        ),
    );

    let signature_hex: str<144> = "3045022100e9e6b18959753dfe84da3e81ed2849dca4a31174b010f732f6ab083f137cedc60220073bafd23de099311bc515a80f863a3009b990ba715c73fb7316f2e3eec4a28a81";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex: str<130> = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<106, 0, 0, 0, 1>(Address::new_p2wsh(), true, false);
}

#[test]
fn test_p2wsh_checksig_none() {
    let cur_tx_hex: str<760> = "010000000001016542b657eea04a75b1582969b5b532b3110b392b4b553297435a11b064e2eb460100000000ffffffff02c454fd000000000017a9145e7be6ec3e2382c669aaf3c71da1056f47b9024d875b07330200000000220020ea166bf0492c6f908e45404932e0f39c0571a71007c22b872548cd20f19a92f504004730440220415899bbee08e42376d06e8f86c92b4987613c2816352fe09cd1479fd639f18c02200db57f508f69e266d76c23891708158bda18690c165a41b0aa88303b97609f780147304402203973de2303e8787767090dd25c8a4dc97ce1aa7eb4c0962f13952ed4e856ff8e02203f1bb425def789eea8be46407d10b3c8730407176aef4dc2c29865eb5e5542bf0169522103848e308569b644372a5eb26665f1a8c34ca393c130b376db2fae75c43500013c2103cec1ee615c17e06d4f4b0a08617dffb8e568936bdff18fb057832a58ad4d1b752103eed7ae80c34d70f5ba93f93965f69f3c691da0f4607f242f4fd6c7a48789233e53aeee9c0900";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<380, 1, 1, 42, 2, 1, 76, 4, 252>::new(cur_tx_bytes, true);

    let input_to_sign = 0;

    let prev_tx_hex = "0200000000010192f29384a956361b9b9ebc667d01489cb360068c22c7b89396e5fdc3ece0305a0100000000ffffffff023d0500000000000016001464193f85b629823f114c9d997ee68627d7395d5fe7a1000000000000160014d0446764c4f16f78ca0ce0b7f487cc5fe205835e024730440220598ef97f63f7648e39d03ff58383056322fa13effaee8d11c9c9e8789a72522002204dda5bbc9cba008682d62820395a2c43b9abae52d6ad81835e72bda09468fa21012103d9a4d0bbe47d58b68e366a380107ba3470f6893764a2d020127d36c169df850100000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<222, 1, 1, 42, 2, 1, 63, 2, 107>::new(prev_tx_bytes, true);

    let output_to_unlock = 1;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        hex_to_bytes(
            "69522103848e308569b644372a5eb26665f1a8c34ca393c130b376db2fae75c43500013c2103cec1ee615c17e06d4f4b0a08617dffb8e568936bdff18fb057832a58ad4d1b752103eed7ae80c34d70f5ba93f93965f69f3c691da0f4607f242f4fd6c7a48789233e53ae",
        ),
    );

    let signature_hex: str<144> = "3045022100c291193a2967796c726a5dccda6b4b019747b90ba94f29dac53d463381eb241a02200a762b1208d1d8092003d5c9e19cb9b33a1b05b38432397adcbeeb55fba58f9402";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex: str<130> = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<106, 0, 0, 0, 1>(Address::new_p2wsh(), true, false);
}

#[test]
fn test_p2wsh_checksig_none_anyonecanpay() {
    let cur_tx_hex: str<760> = "010000000001016542b657eea04a75b1582969b5b532b3110b392b4b553297435a11b064e2eb460100000000ffffffff02c454fd000000000017a9145e7be6ec3e2382c669aaf3c71da1056f47b9024d875b07330200000000220020ea166bf0492c6f908e45404932e0f39c0571a71007c22b872548cd20f19a92f504004730440220415899bbee08e42376d06e8f86c92b4987613c2816352fe09cd1479fd639f18c02200db57f508f69e266d76c23891708158bda18690c165a41b0aa88303b97609f780147304402203973de2303e8787767090dd25c8a4dc97ce1aa7eb4c0962f13952ed4e856ff8e02203f1bb425def789eea8be46407d10b3c8730407176aef4dc2c29865eb5e5542bf0169522103848e308569b644372a5eb26665f1a8c34ca393c130b376db2fae75c43500013c2103cec1ee615c17e06d4f4b0a08617dffb8e568936bdff18fb057832a58ad4d1b752103eed7ae80c34d70f5ba93f93965f69f3c691da0f4607f242f4fd6c7a48789233e53aeee9c0900";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<380, 1, 1, 42, 2, 1, 76, 4, 252>::new(cur_tx_bytes, true);

    let input_to_sign = 0;

    let prev_tx_hex = "0200000000010192f29384a956361b9b9ebc667d01489cb360068c22c7b89396e5fdc3ece0305a0100000000ffffffff023d0500000000000016001464193f85b629823f114c9d997ee68627d7395d5fe7a1000000000000160014d0446764c4f16f78ca0ce0b7f487cc5fe205835e024730440220598ef97f63f7648e39d03ff58383056322fa13effaee8d11c9c9e8789a72522002204dda5bbc9cba008682d62820395a2c43b9abae52d6ad81835e72bda09468fa21012103d9a4d0bbe47d58b68e366a380107ba3470f6893764a2d020127d36c169df850100000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<222, 1, 1, 42, 2, 1, 63, 2, 107>::new(prev_tx_bytes, true);

    let output_to_unlock = 1;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        hex_to_bytes(
            "69522103848e308569b644372a5eb26665f1a8c34ca393c130b376db2fae75c43500013c2103cec1ee615c17e06d4f4b0a08617dffb8e568936bdff18fb057832a58ad4d1b752103eed7ae80c34d70f5ba93f93965f69f3c691da0f4607f242f4fd6c7a48789233e53ae",
        ),
    );

    let signature_hex: str<144> = "3045022100a24292b7e40a5b3dfe67b32e9c0f144c2ad8266403798d3f1f07a559407d1718022028719cc52625eb85d79ca387a1b31d3e622c87092759a8dd8eea5f8e1c93023482";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex: str<130> = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<106, 0, 0, 0, 1>(Address::new_p2wsh(), true, false);
}

#[test]
fn test_p2wsh_checksig_single() {
    let cur_tx_hex: str<760> = "010000000001016542b657eea04a75b1582969b5b532b3110b392b4b553297435a11b064e2eb460100000000ffffffff02c454fd000000000017a9145e7be6ec3e2382c669aaf3c71da1056f47b9024d875b07330200000000220020ea166bf0492c6f908e45404932e0f39c0571a71007c22b872548cd20f19a92f504004730440220415899bbee08e42376d06e8f86c92b4987613c2816352fe09cd1479fd639f18c02200db57f508f69e266d76c23891708158bda18690c165a41b0aa88303b97609f780147304402203973de2303e8787767090dd25c8a4dc97ce1aa7eb4c0962f13952ed4e856ff8e02203f1bb425def789eea8be46407d10b3c8730407176aef4dc2c29865eb5e5542bf0169522103848e308569b644372a5eb26665f1a8c34ca393c130b376db2fae75c43500013c2103cec1ee615c17e06d4f4b0a08617dffb8e568936bdff18fb057832a58ad4d1b752103eed7ae80c34d70f5ba93f93965f69f3c691da0f4607f242f4fd6c7a48789233e53aeee9c0900";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<380, 1, 1, 42, 2, 1, 76, 4, 252>::new(cur_tx_bytes, true);

    let input_to_sign = 0;

    let prev_tx_hex = "0200000000010192f29384a956361b9b9ebc667d01489cb360068c22c7b89396e5fdc3ece0305a0100000000ffffffff023d0500000000000016001464193f85b629823f114c9d997ee68627d7395d5fe7a1000000000000160014d0446764c4f16f78ca0ce0b7f487cc5fe205835e024730440220598ef97f63f7648e39d03ff58383056322fa13effaee8d11c9c9e8789a72522002204dda5bbc9cba008682d62820395a2c43b9abae52d6ad81835e72bda09468fa21012103d9a4d0bbe47d58b68e366a380107ba3470f6893764a2d020127d36c169df850100000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<222, 1, 1, 42, 2, 1, 63, 2, 107>::new(prev_tx_bytes, true);

    let output_to_unlock = 1;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        hex_to_bytes(
            "69522103848e308569b644372a5eb26665f1a8c34ca393c130b376db2fae75c43500013c2103cec1ee615c17e06d4f4b0a08617dffb8e568936bdff18fb057832a58ad4d1b752103eed7ae80c34d70f5ba93f93965f69f3c691da0f4607f242f4fd6c7a48789233e53ae",
        ),
    );

    let signature_hex: str<142> = "304402204272771cb6fcad4c3f7ecbb6f5924d33831b4ea0861545b17a39f1c643aac43b02200379233b5228fcff3020dfb281ac411bb0bfeee06051af34020c13adf7ce14ef03";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex: str<130> = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<106, 32, 0, 0, 1>(Address::new_p2wsh(), true, false);
}

#[test]
fn test_p2wsh_checksig_single_anyonecanpay() {
    let cur_tx_hex: str<760> = "010000000001016542b657eea04a75b1582969b5b532b3110b392b4b553297435a11b064e2eb460100000000ffffffff02c454fd000000000017a9145e7be6ec3e2382c669aaf3c71da1056f47b9024d875b07330200000000220020ea166bf0492c6f908e45404932e0f39c0571a71007c22b872548cd20f19a92f504004730440220415899bbee08e42376d06e8f86c92b4987613c2816352fe09cd1479fd639f18c02200db57f508f69e266d76c23891708158bda18690c165a41b0aa88303b97609f780147304402203973de2303e8787767090dd25c8a4dc97ce1aa7eb4c0962f13952ed4e856ff8e02203f1bb425def789eea8be46407d10b3c8730407176aef4dc2c29865eb5e5542bf0169522103848e308569b644372a5eb26665f1a8c34ca393c130b376db2fae75c43500013c2103cec1ee615c17e06d4f4b0a08617dffb8e568936bdff18fb057832a58ad4d1b752103eed7ae80c34d70f5ba93f93965f69f3c691da0f4607f242f4fd6c7a48789233e53aeee9c0900";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<380, 1, 1, 42, 2, 1, 76, 4, 252>::new(cur_tx_bytes, true);

    let input_to_sign = 0;

    let prev_tx_hex = "0200000000010192f29384a956361b9b9ebc667d01489cb360068c22c7b89396e5fdc3ece0305a0100000000ffffffff023d0500000000000016001464193f85b629823f114c9d997ee68627d7395d5fe7a1000000000000160014d0446764c4f16f78ca0ce0b7f487cc5fe205835e024730440220598ef97f63f7648e39d03ff58383056322fa13effaee8d11c9c9e8789a72522002204dda5bbc9cba008682d62820395a2c43b9abae52d6ad81835e72bda09468fa21012103d9a4d0bbe47d58b68e366a380107ba3470f6893764a2d020127d36c169df850100000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<222, 1, 1, 42, 2, 1, 63, 2, 107>::new(prev_tx_bytes, true);

    let output_to_unlock = 1;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        hex_to_bytes(
            "69522103848e308569b644372a5eb26665f1a8c34ca393c130b376db2fae75c43500013c2103cec1ee615c17e06d4f4b0a08617dffb8e568936bdff18fb057832a58ad4d1b752103eed7ae80c34d70f5ba93f93965f69f3c691da0f4607f242f4fd6c7a48789233e53ae",
        ),
    );

    let signature_hex: str<142> = "3044022019a8d4e1903373f8cf13732280b73595cfaa80f77b8f563834dcda5c0d17d6510220674dc6e6fecdc4db36c92910efe8bb7ba1522e7cf44896757e848294046af68b83";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex: str<130> = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<106, 32, 0, 0, 1>(Address::new_p2wsh(), true, false);
}

//////////////////////////////////////////
#[test]
fn test_p2sh_checksig_all() {
    let cur_tx_hex: str<1068> = "010000000c3e10e0814786d6e02dfab4e2569d01a63191b8449bb0f5b9af580fc754ae83b90000000000ffffffff40629a5c656e8a9fb80ae8a5d55b80fbb598a059bad06c50fcddf404e932d59e0000000000ffffffff5763070e224f18dbc8211e60c05ae31543958b248eb08c9e5989167c60b3c5700000000000ffffffff5b4e96a245f6fbc2efb910e25e9dd7a26e0ef8486eebd50dc658ae7d9719e5fd0000000000ffffffff6889fe551cb869bf20284c64fc3adc229fded6e11fc8b79ec11bb2e499bd0d6c2900000000ffffffff6a1c310490053bfc791ec646907941d3df59bfa8db1b21789d8780c7489695c10000000000ffffffff79d87f7daedaee7c6e80059b38cde214fec5e4546fbdccc7c24c01c47dce1c232000000000ffffffff9a19e8ede8836c192fe816d80d392bb7bb5453f320a78854a83e46bd9f27bf1e0000000000ffffffffd3090eb0855eee3d1dba53d68edeca6c368a37d3bba9579da3ac675ece42d7680e00000000fffffffff61ff40c78b3e12e7d1f9a9db04a7b7736510014fc15a950d575c159b4b0b7a50000000000ffffffff4471e66e1622bf197ba49ab31d1bd29b4917af60ce103bb6713ffb709b300c450000000000ffffffff4471e66e1622bf197ba49ab31d1bd29b4917af60ce103bb6713ffb709b300c450100000000ffffffff0196e756080000000017a914748284390f9e263a4b766a75d0633c50426eb8758700000000";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<534, 12, 1, 493, 1, 1, 33, 0, 0>::new(cur_tx_bytes, false);

    let input_to_sign = 11;

    let prev_tx_hex = "0100000001fe2f51ca8a0b98afd3ea0b6ee44778f64e22895f1a00a6f8b37cb3a8789be5a92300000000ffffffff027a7c5903000000001976a91443a8a7d224aeb9709fb7edc136e2e95d06cdd4c288ac809698000000000017a914748284390f9e263a4b766a75d0633c50426eb8758700000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<117, 1, 1, 42, 2, 1, 67, 0, 0>::new(prev_tx_bytes, false);

    let output_to_unlock = 1;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        hex_to_bytes(
            "475121022afc20bf379bc96a2f4e9e63ffceb8652b2b6a097f63fbee6ecec2a49a48010e2103a767c7221e9f15f870f1ad9311f5ab937d79fcaeee15bb2c722bca515581b4c052ae",
        ),
    );

    let pubkey_hex = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    let signature_hex = "304402201443fe29b90b083acf61a1728a23a3d0b4f74691a4e42e6acc01852ebca5ca5d02205eb852eda5fe65060e545d4023a527a3904990a64c316aa050ab5a0cbc57028f01";
    let signature_bytes = hex_to_bytes(signature_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<72, 1, 11, 1, 1>(Address::new_p2sh(), true, false);
}

#[test]
fn test_p2sh_checksig_all_anyonecanpay() {
    let cur_tx_hex: str<1068> = "010000000c3e10e0814786d6e02dfab4e2569d01a63191b8449bb0f5b9af580fc754ae83b90000000000ffffffff40629a5c656e8a9fb80ae8a5d55b80fbb598a059bad06c50fcddf404e932d59e0000000000ffffffff5763070e224f18dbc8211e60c05ae31543958b248eb08c9e5989167c60b3c5700000000000ffffffff5b4e96a245f6fbc2efb910e25e9dd7a26e0ef8486eebd50dc658ae7d9719e5fd0000000000ffffffff6889fe551cb869bf20284c64fc3adc229fded6e11fc8b79ec11bb2e499bd0d6c2900000000ffffffff6a1c310490053bfc791ec646907941d3df59bfa8db1b21789d8780c7489695c10000000000ffffffff79d87f7daedaee7c6e80059b38cde214fec5e4546fbdccc7c24c01c47dce1c232000000000ffffffff9a19e8ede8836c192fe816d80d392bb7bb5453f320a78854a83e46bd9f27bf1e0000000000ffffffffd3090eb0855eee3d1dba53d68edeca6c368a37d3bba9579da3ac675ece42d7680e00000000fffffffff61ff40c78b3e12e7d1f9a9db04a7b7736510014fc15a950d575c159b4b0b7a50000000000ffffffff4471e66e1622bf197ba49ab31d1bd29b4917af60ce103bb6713ffb709b300c450000000000ffffffff4471e66e1622bf197ba49ab31d1bd29b4917af60ce103bb6713ffb709b300c450100000000ffffffff0196e756080000000017a914748284390f9e263a4b766a75d0633c50426eb8758700000000";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<534, 12, 1, 493, 1, 1, 33, 0, 0>::new(cur_tx_bytes, false);

    let input_to_sign = 11;

    let prev_tx_hex = "0100000001fe2f51ca8a0b98afd3ea0b6ee44778f64e22895f1a00a6f8b37cb3a8789be5a92300000000ffffffff027a7c5903000000001976a91443a8a7d224aeb9709fb7edc136e2e95d06cdd4c288ac809698000000000017a914748284390f9e263a4b766a75d0633c50426eb8758700000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<117, 1, 1, 42, 2, 1, 67, 0, 0>::new(prev_tx_bytes, false);

    let output_to_unlock = 1;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        hex_to_bytes(
            "475121022afc20bf379bc96a2f4e9e63ffceb8652b2b6a097f63fbee6ecec2a49a48010e2103a767c7221e9f15f870f1ad9311f5ab937d79fcaeee15bb2c722bca515581b4c052ae",
        ),
    );

    let pubkey_hex = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    let signature_hex = "304402207fde56751d265c9992b4e41c03ba437a399c1979c9c822a00e526e513c6ca4f90220377b34605c12fa9405b2fb905b3c1c8849b1747a6dec9a96026e66dbb9e218b581";
    let signature_bytes = hex_to_bytes(signature_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<72, 1, 11, 1, 41>(Address::new_p2sh(), true, false);
}

#[test]
fn test_p2sh_checksig_none() {
    let cur_tx_hex: str<1068> = "010000000c3e10e0814786d6e02dfab4e2569d01a63191b8449bb0f5b9af580fc754ae83b90000000000ffffffff40629a5c656e8a9fb80ae8a5d55b80fbb598a059bad06c50fcddf404e932d59e0000000000ffffffff5763070e224f18dbc8211e60c05ae31543958b248eb08c9e5989167c60b3c5700000000000ffffffff5b4e96a245f6fbc2efb910e25e9dd7a26e0ef8486eebd50dc658ae7d9719e5fd0000000000ffffffff6889fe551cb869bf20284c64fc3adc229fded6e11fc8b79ec11bb2e499bd0d6c2900000000ffffffff6a1c310490053bfc791ec646907941d3df59bfa8db1b21789d8780c7489695c10000000000ffffffff79d87f7daedaee7c6e80059b38cde214fec5e4546fbdccc7c24c01c47dce1c232000000000ffffffff9a19e8ede8836c192fe816d80d392bb7bb5453f320a78854a83e46bd9f27bf1e0000000000ffffffffd3090eb0855eee3d1dba53d68edeca6c368a37d3bba9579da3ac675ece42d7680e00000000fffffffff61ff40c78b3e12e7d1f9a9db04a7b7736510014fc15a950d575c159b4b0b7a50000000000ffffffff4471e66e1622bf197ba49ab31d1bd29b4917af60ce103bb6713ffb709b300c450000000000ffffffff4471e66e1622bf197ba49ab31d1bd29b4917af60ce103bb6713ffb709b300c450100000000ffffffff0196e756080000000017a914748284390f9e263a4b766a75d0633c50426eb8758700000000";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<534, 12, 1, 493, 1, 1, 33, 0, 0>::new(cur_tx_bytes, false);

    let input_to_sign = 11;

    let prev_tx_hex = "0100000001fe2f51ca8a0b98afd3ea0b6ee44778f64e22895f1a00a6f8b37cb3a8789be5a92300000000ffffffff027a7c5903000000001976a91443a8a7d224aeb9709fb7edc136e2e95d06cdd4c288ac809698000000000017a914748284390f9e263a4b766a75d0633c50426eb8758700000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<117, 1, 1, 42, 2, 1, 67, 0, 0>::new(prev_tx_bytes, false);

    let output_to_unlock = 1;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        hex_to_bytes(
            "475121022afc20bf379bc96a2f4e9e63ffceb8652b2b6a097f63fbee6ecec2a49a48010e2103a767c7221e9f15f870f1ad9311f5ab937d79fcaeee15bb2c722bca515581b4c052ae",
        ),
    );

    let pubkey_hex = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    let signature_hex = "30450221008f349b0688db13e45567c81ab0864ed933aa74b7a645e550105f60cdcade205b022067a7cd928968b1d6c331bc2e00a9f1bff174d407fe1851662796f71973607ec002";
    let signature_bytes = hex_to_bytes(signature_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<72, 1, 11, 1, 1>(Address::new_p2sh(), true, false);
}

#[test]
fn test_p2sh_checksig_none_anyonecanpay() {
    let cur_tx_hex: str<1068> = "010000000c3e10e0814786d6e02dfab4e2569d01a63191b8449bb0f5b9af580fc754ae83b90000000000ffffffff40629a5c656e8a9fb80ae8a5d55b80fbb598a059bad06c50fcddf404e932d59e0000000000ffffffff5763070e224f18dbc8211e60c05ae31543958b248eb08c9e5989167c60b3c5700000000000ffffffff5b4e96a245f6fbc2efb910e25e9dd7a26e0ef8486eebd50dc658ae7d9719e5fd0000000000ffffffff6889fe551cb869bf20284c64fc3adc229fded6e11fc8b79ec11bb2e499bd0d6c2900000000ffffffff6a1c310490053bfc791ec646907941d3df59bfa8db1b21789d8780c7489695c10000000000ffffffff79d87f7daedaee7c6e80059b38cde214fec5e4546fbdccc7c24c01c47dce1c232000000000ffffffff9a19e8ede8836c192fe816d80d392bb7bb5453f320a78854a83e46bd9f27bf1e0000000000ffffffffd3090eb0855eee3d1dba53d68edeca6c368a37d3bba9579da3ac675ece42d7680e00000000fffffffff61ff40c78b3e12e7d1f9a9db04a7b7736510014fc15a950d575c159b4b0b7a50000000000ffffffff4471e66e1622bf197ba49ab31d1bd29b4917af60ce103bb6713ffb709b300c450000000000ffffffff4471e66e1622bf197ba49ab31d1bd29b4917af60ce103bb6713ffb709b300c450100000000ffffffff0196e756080000000017a914748284390f9e263a4b766a75d0633c50426eb8758700000000";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<534, 12, 1, 493, 1, 1, 33, 0, 0>::new(cur_tx_bytes, false);

    let input_to_sign = 11;

    let prev_tx_hex = "0100000001fe2f51ca8a0b98afd3ea0b6ee44778f64e22895f1a00a6f8b37cb3a8789be5a92300000000ffffffff027a7c5903000000001976a91443a8a7d224aeb9709fb7edc136e2e95d06cdd4c288ac809698000000000017a914748284390f9e263a4b766a75d0633c50426eb8758700000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<117, 1, 1, 42, 2, 1, 67, 0, 0>::new(prev_tx_bytes, false);

    let output_to_unlock = 1;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        hex_to_bytes(
            "475121022afc20bf379bc96a2f4e9e63ffceb8652b2b6a097f63fbee6ecec2a49a48010e2103a767c7221e9f15f870f1ad9311f5ab937d79fcaeee15bb2c722bca515581b4c052ae",
        ),
    );

    let pubkey_hex = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    let signature_hex = "304402201f87621fbc24ffe1979aaa7e26c3e631e041fdfde7e661e1b7c5eb6f747635c402205ed21b70733fad7dd99f6670d9783527374b595057210b27811e859e7460d03682";
    let signature_bytes = hex_to_bytes(signature_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);
    stack.op_checksig::<72, 1, 11, 1, 41>(Address::new_p2sh(), true, false);
}

#[test]
fn test_p2tr_checksig() {
    let cur_tx_hex = "020000000001023cfe8b95d22502698fd98837f83d8d4be31ee3eddd9d1ab1a95654c64604c4d10100000000feffffff3cfe8b95d22502698fd98837f83d8d4be31ee3eddd9d1ab1a95654c64604c4d10000000000ffffffff023acf00000000000017a914453acd285e0b84ce01be507e1de19ebc2494c28d8734a8cc2e0000000017a9146fc16fc2550e819d837d5cc5b37237642ab131978701430141b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae010188034101769105cbcbdcaaee5e58cd201ba3152477fda31410df8b91b4aee2c4864c7700615efb425e002f146a39ca0a4f2924566762d9213bd33f825fad83977fba7f0122206d4ddc0e47d2e8f82cbe2fc2d0d749e7bd3338112cecdc76d8f831ae6620dbe0ac21c0924c163b385af7093440184af6fd6244936d1288cbb41cc3812286d3f83a33294fd80900";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<365, 2, 1, 83, 2, 1, 65, 1, 207>::new(cur_tx_bytes, true);

    let input_to_sign = 0;

    let prev_tx_hex = "0200000000010192f29384a956361b9b9ebc667d01489cb360068c22c7b89396e5fdc3ece0305a0100000000ffffffff023d0500000000000016001464193f85b629823f114c9d997ee68627d7395d5fe7a1000000000000160014d0446764c4f16f78ca0ce0b7f487cc5fe205835e024730440220598ef97f63f7648e39d03ff58383056322fa13effaee8d11c9c9e8789a72522002204dda5bbc9cba008682d62820395a2c43b9abae52d6ad81835e72bda09468fa21012103d9a4d0bbe47d58b68e366a380107ba3470f6893764a2d020127d36c169df850100000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<222, 1, 1, 42, 2, 1, 63, 2, 107>::new(prev_tx_bytes, true);

    let output_to_unlock = 1;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        [],
    );

    let signature_hex = "d974287f8670912c0ed5b1446f702f5d0ac8394d5a4160b59d548bf777c0174d06cdc910226b456967da09efa6795963f9dcb8ae4b915cf8cd74a04c86961a1303";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex = "35a6a71fdcfef1ed8c29c0c896a23fd21333fbab12e2a85165f9ced3afb5ce12";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);

    let utxo_data: [u8; 86] = hex_to_bytes(
        "983a0000000000002251203daaca9b82a51aca960c1491588246029d7e0fc49e0abdbcc8fd17574be5c74b983a3400000000002251200f0c8db753acbd17343a39c2f3f4e35e4be6da749f9e35137ab220e7b238a667",
    );

    stack.op_checksig_p2tr::<86, 32>(utxo_data, true, false, Option::none(), Option::none());
}

#[test]
fn test_p2tr_checksig_leaf() {
    let cur_tx_hex = "020000000001023cfe8b95d22502698fd98837f83d8d4be31ee3eddd9d1ab1a95654c64604c4d10100000000feffffff3cfe8b95d22502698fd98837f83d8d4be31ee3eddd9d1ab1a95654c64604c4d10000000000ffffffff023acf00000000000017a914453acd285e0b84ce01be507e1de19ebc2494c28d8734a8cc2e0000000017a9146fc16fc2550e819d837d5cc5b37237642ab131978701430141b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae010188034101769105cbcbdcaaee5e58cd201ba3152477fda31410df8b91b4aee2c4864c7700615efb425e002f146a39ca0a4f2924566762d9213bd33f825fad83977fba7f0122206d4ddc0e47d2e8f82cbe2fc2d0d749e7bd3338112cecdc76d8f831ae6620dbe0ac21c0924c163b385af7093440184af6fd6244936d1288cbb41cc3812286d3f83a33294fd80900";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<365, 2, 1, 83, 2, 1, 65, 1, 207>::new(cur_tx_bytes, true);

    let input_to_sign = 0;

    let prev_tx_hex = "0200000000010192f29384a956361b9b9ebc667d01489cb360068c22c7b89396e5fdc3ece0305a0100000000ffffffff023d0500000000000016001464193f85b629823f114c9d997ee68627d7395d5fe7a1000000000000160014d0446764c4f16f78ca0ce0b7f487cc5fe205835e024730440220598ef97f63f7648e39d03ff58383056322fa13effaee8d11c9c9e8789a72522002204dda5bbc9cba008682d62820395a2c43b9abae52d6ad81835e72bda09468fa21012103d9a4d0bbe47d58b68e366a380107ba3470f6893764a2d020127d36c169df850100000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<222, 1, 1, 42, 2, 1, 63, 2, 107>::new(prev_tx_bytes, true);

    let output_to_unlock = 0;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        [],
    );

    let signature_hex = "ddd8a9c0adc6aff7c9b370e44d700f8967638c6d348084066091ed514f956d612e876b69a048baf2d350fe22f56217c3c8bf948043b0809aa69ce5c173fc519581";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex = "35a6a71fdcfef1ed8c29c0c896a23fd21333fbab12e2a85165f9ced3afb5ce12";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);

    let leaf_script = hex_to_bytes(
        "c022206d4ddc0e47d2e8f82cbe2fc2d0d749e7bd3338112cecdc76d8f831ae6620dbe0ac",
    );
    let leaf_script_hash = tagged_hash(leaf_script, "TapLeaf".as_bytes());

    let utxo_data: [u8; 86] = hex_to_bytes(
        "983a0000000000002251203daaca9b82a51aca960c1491588246029d7e0fc49e0abdbcc8fd17574be5c74b983a3400000000002251200f0c8db753acbd17343a39c2f3f4e35e4be6da749f9e35137ab220e7b238a667",
    );

    stack.op_checksig_p2tr::<86, 32>(
        utxo_data,
        true,
        false,
        Option::none(),
        Option::some(leaf_script_hash),
    );
}

#[test]
fn test_p2tr_checksig_annex() {
    let cur_tx_hex = "020000000001023cfe8b95d22502698fd98837f83d8d4be31ee3eddd9d1ab1a95654c64604c4d10100000000feffffff3cfe8b95d22502698fd98837f83d8d4be31ee3eddd9d1ab1a95654c64604c4d10000000000ffffffff023acf00000000000017a914453acd285e0b84ce01be507e1de19ebc2494c28d8734a8cc2e0000000017a9146fc16fc2550e819d837d5cc5b37237642ab131978701430141b693a0797b24bae12ed0516a2f5ba765618dca89b75e498ba5b745b71644362298a45ca39230d10a02ee6290a91cebf9839600f7e35158a447ea182ea0e022ae010188034101769105cbcbdcaaee5e58cd201ba3152477fda31410df8b91b4aee2c4864c7700615efb425e002f146a39ca0a4f2924566762d9213bd33f825fad83977fba7f0122206d4ddc0e47d2e8f82cbe2fc2d0d749e7bd3338112cecdc76d8f831ae6620dbe0ac21c0924c163b385af7093440184af6fd6244936d1288cbb41cc3812286d3f83a33294fd80900";
    let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
    let cur_tx = Transaction::<365, 2, 1, 83, 2, 1, 65, 1, 207>::new(cur_tx_bytes, true);

    let input_to_sign = 1;

    let prev_tx_hex = "0200000000010192f29384a956361b9b9ebc667d01489cb360068c22c7b89396e5fdc3ece0305a0100000000ffffffff023d0500000000000016001464193f85b629823f114c9d997ee68627d7395d5fe7a1000000000000160014d0446764c4f16f78ca0ce0b7f487cc5fe205835e024730440220598ef97f63f7648e39d03ff58383056322fa13effaee8d11c9c9e8789a72522002204dda5bbc9cba008682d62820395a2c43b9abae52d6ad81835e72bda09468fa21012103d9a4d0bbe47d58b68e366a380107ba3470f6893764a2d020127d36c169df850100000000";
    let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
    let prev_tx = Transaction::<222, 1, 1, 42, 2, 1, 63, 2, 107>::new(prev_tx_bytes, true);

    let output_to_unlock = 0;

    let mut stack = Stack::new(
        cur_tx,
        prev_tx,
        input_to_sign,
        output_to_unlock,
        empty_stack_array::<80, 7>(),
        [],
    );

    let signature_hex = "5b622bf04baa62e0ee8c2179ba85579b3af0fd8916576437266b483f5f8c3b1e67bce7dc84d6ce0611b539c45c66dcf90db142d343f54dc0ed8d1fc65dc55e4f82";
    let signature_bytes = hex_to_bytes(signature_hex);

    let pubkey_hex = "35a6a71fdcfef1ed8c29c0c896a23fd21333fbab12e2a85165f9ced3afb5ce12";
    let pubkey_bytes = hex_to_bytes(pubkey_hex);

    stack.push_bytes(signature_bytes);
    stack.push_bytes(pubkey_bytes);

    let annex = hex_to_bytes(
        "215085c0ee8f7b6df70c6994bead41e15f9437fc5215bbbe2fd59cd730f8d9945b00",
    );
    let annex_hash = sha256::digest(annex);

    let utxo_data: [u8; 86] = hex_to_bytes(
        "983a0000000000002251203daaca9b82a51aca960c1491588246029d7e0fc49e0abdbcc8fd17574be5c74b983a3400000000002251200f0c8db753acbd17343a39c2f3f4e35e4be6da749f9e35137ab220e7b238a667",
    );

    stack.op_checksig_p2tr::<86, 32>(
        utxo_data,
        true,
        false,
        Option::some(annex_hash),
        Option::none(),
    );
}

// #[test]
// fn test_p2sh_checksig_single() {
//     let cur_tx_hex: str<1068> = "010000000c3e10e0814786d6e02dfab4e2569d01a63191b8449bb0f5b9af580fc754ae83b90000000000ffffffff40629a5c656e8a9fb80ae8a5d55b80fbb598a059bad06c50fcddf404e932d59e0000000000ffffffff5763070e224f18dbc8211e60c05ae31543958b248eb08c9e5989167c60b3c5700000000000ffffffff5b4e96a245f6fbc2efb910e25e9dd7a26e0ef8486eebd50dc658ae7d9719e5fd0000000000ffffffff6889fe551cb869bf20284c64fc3adc229fded6e11fc8b79ec11bb2e499bd0d6c2900000000ffffffff6a1c310490053bfc791ec646907941d3df59bfa8db1b21789d8780c7489695c10000000000ffffffff79d87f7daedaee7c6e80059b38cde214fec5e4546fbdccc7c24c01c47dce1c232000000000ffffffff9a19e8ede8836c192fe816d80d392bb7bb5453f320a78854a83e46bd9f27bf1e0000000000ffffffffd3090eb0855eee3d1dba53d68edeca6c368a37d3bba9579da3ac675ece42d7680e00000000fffffffff61ff40c78b3e12e7d1f9a9db04a7b7736510014fc15a950d575c159b4b0b7a50000000000ffffffff4471e66e1622bf197ba49ab31d1bd29b4917af60ce103bb6713ffb709b300c450000000000ffffffff4471e66e1622bf197ba49ab31d1bd29b4917af60ce103bb6713ffb709b300c450100000000ffffffff0196e756080000000017a914748284390f9e263a4b766a75d0633c50426eb8758700000000";
//     let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
//     let cur_tx = Transaction::<534, 12, 1, 493, 1, 1, 33, 0, 0>::new(cur_tx_bytes, false);

//     let input_to_sign = 0;

//     let prev_tx_hex = "01000000025b3291ab367112d7e261fda0ec1f27a376a203bbccae03fdb4955a55bade4cf60100000000ffffffff68b6f3e41374c0ccc20cb0bc7df59356827f1fd9f610b2f3fa886b901a8873a00100000000ffffffff028e020000000000001976a914e9445df9d7e9ecf48ba660c196e14979254bfb0e88ac5ab5d30e000000001976a9145c0e4c053bf77b1670a83d4197f78bc85b24ba7588ac00000000";
//     let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
//     let prev_tx = Transaction::<160, 2, 1, 83, 2, 1, 69, 0, 0>::new(prev_tx_bytes, false);

//     let output_to_unlock = 1;

//     let mut stack = Stack::new(
//         cur_tx,
//         prev_tx,
//         input_to_sign,
//         output_to_unlock,
//         empty_stack_array::<80, 7>(), []
//     );

//     let pubkey_hex = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
//     let pubkey_bytes = hex_to_bytes(pubkey_hex);

//     let signature_hex = "304402202fe002a35c3dd255c5c9e10cdede86ae5f49180e1dff645a4d25f22f0abd65be0220765b844a9078e56e606632ceafc1cfa2872c26e8dfb6e79bc8533f8546af508e03";
//     let signature_bytes = hex_to_bytes(signature_hex);

//     stack.push_bytes(signature_bytes);
//     stack.push_bytes(pubkey_bytes);
//     stack.op_checksig::<72, 34, 0, 1, 41>(Address::new_p2sh(), true, false);
// }

// #[test]
// fn test_p2sh_checksig_single_anyonecanpay() {
//     let cur_tx_hex: str<1068> = "010000000c3e10e0814786d6e02dfab4e2569d01a63191b8449bb0f5b9af580fc754ae83b90000000000ffffffff40629a5c656e8a9fb80ae8a5d55b80fbb598a059bad06c50fcddf404e932d59e0000000000ffffffff5763070e224f18dbc8211e60c05ae31543958b248eb08c9e5989167c60b3c5700000000000ffffffff5b4e96a245f6fbc2efb910e25e9dd7a26e0ef8486eebd50dc658ae7d9719e5fd0000000000ffffffff6889fe551cb869bf20284c64fc3adc229fded6e11fc8b79ec11bb2e499bd0d6c2900000000ffffffff6a1c310490053bfc791ec646907941d3df59bfa8db1b21789d8780c7489695c10000000000ffffffff79d87f7daedaee7c6e80059b38cde214fec5e4546fbdccc7c24c01c47dce1c232000000000ffffffff9a19e8ede8836c192fe816d80d392bb7bb5453f320a78854a83e46bd9f27bf1e0000000000ffffffffd3090eb0855eee3d1dba53d68edeca6c368a37d3bba9579da3ac675ece42d7680e00000000fffffffff61ff40c78b3e12e7d1f9a9db04a7b7736510014fc15a950d575c159b4b0b7a50000000000ffffffff4471e66e1622bf197ba49ab31d1bd29b4917af60ce103bb6713ffb709b300c450000000000ffffffff4471e66e1622bf197ba49ab31d1bd29b4917af60ce103bb6713ffb709b300c450100000000ffffffff0196e756080000000017a914748284390f9e263a4b766a75d0633c50426eb8758700000000";
//     let cur_tx_bytes = hex_to_bytes(cur_tx_hex);
//     let cur_tx = Transaction::<534, 12, 1, 493, 1, 1, 33, 0, 0>::new(cur_tx_bytes, false);

//     let input_to_sign = 0;

//     let prev_tx_hex = "01000000025b3291ab367112d7e261fda0ec1f27a376a203bbccae03fdb4955a55bade4cf60100000000ffffffff68b6f3e41374c0ccc20cb0bc7df59356827f1fd9f610b2f3fa886b901a8873a00100000000ffffffff028e020000000000001976a914e9445df9d7e9ecf48ba660c196e14979254bfb0e88ac5ab5d30e000000001976a9145c0e4c053bf77b1670a83d4197f78bc85b24ba7588ac00000000";
//     let prev_tx_bytes = hex_to_bytes(prev_tx_hex);
//     let prev_tx = Transaction::<160, 2, 1, 83, 2, 1, 69, 0, 0>::new(prev_tx_bytes, false);

//     let output_to_unlock = 1;

//     let mut stack = Stack::new(
//         cur_tx,
//         prev_tx,
//         input_to_sign,
//         output_to_unlock,
//         empty_stack_array::<80, 7>(), []
//     );

//     let pubkey_hex = "041428f3a3532ff4f1cac70f7292bfad06d1037f800ee8839b56ebba917a22e900ac5879295520ae5690ab668f57f8fdf6d06e410e7de064b676ce8561ec626f57";
//     let pubkey_bytes = hex_to_bytes(pubkey_hex);

//     let signature_hex = "304402206e3efede75a539de846916c82383a17388663f6b95285d4c21c4ab0cd29b55f902204319333855d6badc7ffafc384bfdc2c6ee89cb1d0e1403d8a0d8f076b153539883";
//     let signature_bytes = hex_to_bytes(signature_hex);

//     stack.push_bytes(signature_bytes);
//     stack.push_bytes(pubkey_bytes);
//     stack.op_checksig::<72, 34, 0, 1, 41>(Address::new_p2sh(), true, false);
// }

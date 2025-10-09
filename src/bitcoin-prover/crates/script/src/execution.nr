use super::{
    generated::{
        checkmulsig, checksig, hash160, hash256, pushbytes, pushdata1, pushdata2, pushdata4,
        ripemd160, sha1, sha256,
    },
    opcode::{
        DISABLED, OP_0, OP_0NOTEQUAL, OP_1, OP_16, OP_1ADD, OP_1NEGATE, OP_1SUB, OP_2DROP, OP_2DUP,
        OP_2OVER, OP_2ROT, OP_2SWAP, OP_3DUP, OP_ABS, OP_ADD, OP_BOOLAND, OP_BOOLOR,
        OP_CHECKLOCKTIMEVERIFY, OP_CHECKMULSIG, OP_CHECKMULSIGVERIFY, OP_CHECKSEQUENCEVERIFY,
        OP_CHECKSIG, OP_CHECKSIGADD, OP_CHECKSIGVERIFY, OP_CODESEPARATOR, OP_DEPTH, OP_DROP, OP_DUP,
        OP_ELSE, OP_ENDIF, OP_EQUAL, OP_EQUALVERIFY, OP_FROMALTSTACK, OP_GREATERTHAN,
        OP_GREATERTHANOREQUAL, OP_HASH160, OP_HASH256, OP_IF, OP_IFDUP, OP_LESSTHAN,
        OP_LESSTHANOREQUAL, OP_MAX, OP_MIN, OP_NEGATE, OP_NIP, OP_NOT, OP_NOTIF, OP_NUMENOTQUAL,
        OP_NUMEQUAL, OP_NUMEQUALVERIFY, OP_OVER, OP_PICK, OP_PUSHBYTES1, OP_PUSHBYTES75,
        OP_PUSHDATA1, OP_PUSHDATA2, OP_PUSHDATA4, OP_RESERVED, OP_RESERVED1, OP_RESERVED2,
        OP_RETURN, OP_RIPEMD160, OP_ROLL, OP_ROT, OP_SHA1, OP_SHA256, OP_SIZE, OP_SUB, OP_SWAP,
        OP_TOALTSTACK, OP_TUCK, OP_VER, OP_WITHIN, SUCCESSX,
    },
};
use bvm::stack::{Stack, TestStack};
use sign::{address::Address, compact_size};
use utils::convert::{hex_to_bytes, vec_to_u32};

pub struct ScriptExecutionEngine<let MAX_STACK_ELEMENT_SIZE: u32, let MAX_STACK_SIZE: u32, let CURRENT_TRANSACTION_SIZE: u32, let CURRENT_INPUT_COUNT: u32, let CURRENT_INPUT_COUNT_LEN: u32, let CURRENT_INPUT_SIZE: u32, let CURRENT_OUTPUT_COUNT: u32, let CURRENT_OUTPUT_COUNT_LEN: u32, let CURRENT_OUTPUT_SIZE: u32, let CURRENT_MAX_WITNESS_STACK_SIZE: u32, let CURRENT_WITNESS_SIZE: u32, let PREV_TRANSACTION_SIZE: u32, let PREV_INPUT_COUNT: u32, let PREV_INPUT_COUNT_LEN: u32, let PREV_INPUT_SIZE: u32, let PREV_OUTPUT_COUNT: u32, let PREV_OUTPUT_COUNT_LEN: u32, let PREV_OUTPUT_SIZE: u32, let PREV_MAX_WITNESS_STACK_SIZE: u32, let PREV_WITNESS_SIZE: u32, let REDEEM_SCRIPT_LEN: u32> {
    pub stack: Stack<MAX_STACK_ELEMENT_SIZE, MAX_STACK_SIZE, CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, PREV_TRANSACTION_SIZE, PREV_INPUT_COUNT, PREV_INPUT_COUNT_LEN, PREV_INPUT_SIZE, PREV_OUTPUT_COUNT, PREV_OUTPUT_COUNT_LEN, PREV_OUTPUT_SIZE, PREV_MAX_WITNESS_STACK_SIZE, PREV_WITNESS_SIZE, REDEEM_SCRIPT_LEN>,
}

impl<let MAX_STACK_ELEMENT_SIZE: u32, let MAX_STACK_SIZE: u32, let CURRENT_TRANSACTION_SIZE: u32, let CURRENT_INPUT_COUNT: u32, let CURRENT_INPUT_COUNT_LEN: u32, let CURRENT_INPUT_SIZE: u32, let CURRENT_OUTPUT_COUNT: u32, let CURRENT_OUTPUT_COUNT_LEN: u32, let CURRENT_OUTPUT_SIZE: u32, let CURRENT_MAX_WITNESS_STACK_SIZE: u32, let CURRENT_WITNESS_SIZE: u32, let PREV_TRANSACTION_SIZE: u32, let PREV_INPUT_COUNT: u32, let PREV_INPUT_COUNT_LEN: u32, let PREV_INPUT_SIZE: u32, let PREV_OUTPUT_COUNT: u32, let PREV_OUTPUT_COUNT_LEN: u32, let PREV_OUTPUT_SIZE: u32, let PREV_MAX_WITNESS_STACK_SIZE: u32, let PREV_WITNESS_SIZE: u32, let REDEEM_SCRIPT_LEN: u32> ScriptExecutionEngine<MAX_STACK_ELEMENT_SIZE, MAX_STACK_SIZE, CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, PREV_TRANSACTION_SIZE, PREV_INPUT_COUNT, PREV_INPUT_COUNT_LEN, PREV_INPUT_SIZE, PREV_OUTPUT_COUNT, PREV_OUTPUT_COUNT_LEN, PREV_OUTPUT_SIZE, PREV_MAX_WITNESS_STACK_SIZE, PREV_WITNESS_SIZE, REDEEM_SCRIPT_LEN> {
    pub fn new(
        stack: Stack<MAX_STACK_ELEMENT_SIZE, MAX_STACK_SIZE, CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, PREV_TRANSACTION_SIZE, PREV_INPUT_COUNT, PREV_INPUT_COUNT_LEN, PREV_INPUT_SIZE, PREV_OUTPUT_COUNT, PREV_OUTPUT_COUNT_LEN, PREV_OUTPUT_SIZE, PREV_MAX_WITNESS_STACK_SIZE, PREV_WITNESS_SIZE, REDEEM_SCRIPT_LEN>,
    ) -> Self {
        Self { stack: stack }
    }

    pub fn add_witness_to_stack<let LEN: u32>(&mut self, witness: [u8; LEN]) {
        let mut vec: BoundedVec<u8, MAX_STACK_ELEMENT_SIZE> = BoundedVec::new();

        let mut cur_pos = 0;
        for _ in 0..CURRENT_MAX_WITNESS_STACK_SIZE {
            if cur_pos < LEN {
                let size = compact_size::get_compact_size(witness, cur_pos);
                cur_pos += size.size;
                let size_u32 = compact_size::compact_size_to_u32(witness, size);
                for i in 0..MAX_STACK_ELEMENT_SIZE {
                    if i < size_u32 {
                        vec.push(witness[cur_pos + i]);
                    }
                }

                cur_pos += size_u32;
                self.stack.push(vec);
                vec = BoundedVec::new();
            }
        }
    }

    pub fn execute<let SCRIPT_SIZE: u32, let N_OUTPUT_SIZE: u32, let INPUT_TO_SIGN: u32, let INPUT_TO_SIGN_LEN: u32, let N_INPUT_SIZE: u32, let MAX_NUMBER_OF_OPCODES: u32, let SCRIPT_PUB_KEY_LEN: u32, let UTXOS_LEN: u32>(
        &mut self,
        script: [u8; SCRIPT_SIZE],
        address: Address,
        utxo_data: [u8; UTXOS_LEN],
        leaf_script_hash: Option<[u8; 32]>,
    ) {
        let mut cur_pos: u32 = 0;
        let mut ifs_len: u32 = 1;
        let mut ifs_active: u32 = 1;
        let mut ifs_slice: [bool] = [true].as_slice();
        let mut codesep = false;
        let mut csp_pos = 0;
        let mut op_successx = false;

        for _ in 0..MAX_NUMBER_OF_OPCODES {
            if (cur_pos < SCRIPT_SIZE) & !op_successx {
                let opcode = script[cur_pos];
                cur_pos += 1;

                if DISABLED.any(|e| e == opcode)
                    & !(address.is_p2tr() & SUCCESSX.any(|e| e == opcode)) {
                    assert(false, "Disabled or reserved opcode!");
                } else if (opcode == OP_IF) | (opcode == OP_NOTIF) {
                    let top = if ifs_slice[ifs_len - 1] {
                        self.stack.op_verify()
                    } else {
                        false
                    };
                    ifs_slice = ifs_slice.push_back(if opcode == OP_IF { top } else { !top });
                    ifs_active += ifs_slice[ifs_len] as u32;
                    ifs_len += 1;
                } else if opcode == OP_ENDIF {
                    assert(ifs_len > 1);
                    ifs_len -= 1;
                    ifs_active -= ifs_slice[ifs_len] as u32;
                    ifs_slice = ifs_slice.pop_back().0;
                } else if opcode == OP_ELSE {
                    assert(ifs_len > 1);
                    ifs_slice[ifs_len - 1] = !ifs_slice[ifs_len - 1];
                    if ifs_slice[ifs_len - 1] {
                        ifs_active += 1;
                    } else {
                        ifs_active -= 1;
                    }
                } else if opcode >= OP_PUSHBYTES1 & opcode <= OP_PUSHBYTES75 {
                    let push_length = opcode as u32;
                    let res = pushbytes(self.stack, push_length, script, cur_pos);
                    if ifs_active == ifs_len {
                        self.stack = res.0;
                    }
                    cur_pos = res.1;
                } else if opcode == OP_PUSHDATA1 {
                    let res = pushdata1(self.stack, script, cur_pos);
                    if ifs_active == ifs_len {
                        self.stack = res.0;
                    }
                    cur_pos = res.1;
                } else if opcode == OP_PUSHDATA2 {
                    let res = pushdata2(self.stack, script, cur_pos);
                    if ifs_active == ifs_len {
                        self.stack = res.0;
                    }
                    cur_pos = res.1;
                } else if opcode == OP_PUSHDATA4 {
                    let res = pushdata4(self.stack, script, cur_pos);
                    if ifs_active == ifs_len {
                        self.stack = res.0;
                    }
                    cur_pos = res.1;
                } else if (ifs_active == ifs_len) {
                    if opcode == OP_0 {
                        self.stack.op_num(0);
                    } else if opcode == OP_1NEGATE {
                        self.stack.op_num(-1);
                    } else if opcode >= OP_1 & opcode <= OP_16 {
                        self.stack.op_num(opcode as i8 - 80);
                    } else if opcode == OP_RETURN {
                        assert(false, "OP_RETURN");
                    } else if opcode == OP_TOALTSTACK {
                        self.stack.op_toaltstack();
                    } else if opcode == OP_FROMALTSTACK {
                        self.stack.op_fromaltstack();
                    } else if opcode == OP_2DROP {
                        self.stack.op_2drop();
                    } else if opcode == OP_2DUP {
                        self.stack.op_2dup();
                    } else if opcode == OP_3DUP {
                        self.stack.op_3dup();
                    } else if opcode == OP_2OVER {
                        self.stack.op_2over();
                    } else if opcode == OP_2ROT {
                        self.stack.op_2rot();
                    } else if opcode == OP_2SWAP {
                        self.stack.op_2swap();
                    } else if opcode == OP_IFDUP {
                        self.stack.op_ifdup();
                    } else if opcode == OP_DEPTH {
                        self.stack.op_depth();
                    } else if opcode == OP_DROP {
                        self.stack.op_drop();
                    } else if opcode == OP_DUP {
                        self.stack.op_dup();
                    } else if opcode == OP_NIP {
                        self.stack.op_nip();
                    } else if opcode == OP_OVER {
                        self.stack.op_over();
                    } else if opcode == OP_PICK {
                        self.stack.op_pick();
                    } else if opcode == OP_ROLL {
                        self.stack.op_roll();
                    } else if opcode == OP_ROT {
                        self.stack.op_rot();
                    } else if opcode == OP_SWAP {
                        self.stack.op_swap();
                    } else if opcode == OP_TUCK {
                        self.stack.op_tuck();
                    } else if opcode == OP_SIZE {
                        self.stack.op_size();
                    } else if opcode == OP_1ADD {
                        self.stack.op_1add();
                    } else if opcode == OP_1SUB {
                        self.stack.op_1sub();
                    } else if opcode == OP_NEGATE {
                        self.stack.op_negate();
                    } else if opcode == OP_ABS {
                        self.stack.op_abs();
                    } else if opcode == OP_NOT {
                        self.stack.op_not();
                    } else if opcode == OP_0NOTEQUAL {
                        self.stack.op_0notequal();
                    } else if opcode == OP_ADD {
                        self.stack.op_add();
                    } else if opcode == OP_SUB {
                        self.stack.op_sub();
                    } else if opcode == OP_BOOLAND {
                        self.stack.op_booland();
                    } else if opcode == OP_BOOLOR {
                        self.stack.op_boolor();
                    } else if opcode == OP_NUMEQUAL {
                        self.stack.op_numequal();
                    } else if opcode == OP_NUMEQUALVERIFY {
                        self.stack.op_numequal();
                        assert(self.stack.op_verify());
                    } else if opcode == OP_NUMENOTQUAL {
                        self.stack.op_numnotequal();
                    } else if opcode == OP_LESSTHAN {
                        self.stack.op_lessthan();
                    } else if opcode == OP_GREATERTHAN {
                        self.stack.op_greaterthan();
                    } else if opcode == OP_LESSTHANOREQUAL {
                        self.stack.op_lessthanorequal();
                    } else if opcode == OP_GREATERTHANOREQUAL {
                        self.stack.op_greaterthanorequal();
                    } else if opcode == OP_MIN {
                        self.stack.op_min();
                    } else if opcode == OP_MAX {
                        self.stack.op_max();
                    } else if opcode == OP_WITHIN {
                        self.stack.op_within();
                    } else if opcode == OP_RIPEMD160 {
                        let last_stack_element_length = self.stack.get_last_stack_element_length();
                        self.stack = ripemd160(self.stack, last_stack_element_length);
                    } else if opcode == OP_SHA1 {
                        let last_stack_element_length = self.stack.get_last_stack_element_length();
                        self.stack = sha1(self.stack, last_stack_element_length);
                    } else if opcode == OP_SHA256 {
                        let last_stack_element_length = self.stack.get_last_stack_element_length();
                        self.stack = sha256(self.stack, last_stack_element_length);
                    } else if opcode == OP_HASH160 {
                        let last_stack_element_length = self.stack.get_last_stack_element_length();
                        self.stack = hash160(self.stack, last_stack_element_length);
                    } else if opcode == OP_HASH256 {
                        let last_stack_element_length = self.stack.get_last_stack_element_length();
                        self.stack = hash256(self.stack, last_stack_element_length);
                    } else if opcode == OP_CODESEPARATOR {
                        csp_pos = cur_pos;
                        codesep = true;
                    } else if opcode == OP_EQUAL {
                        self.stack.op_equal();
                    } else if opcode == OP_EQUALVERIFY {
                        self.stack.op_equalverify();
                    } else if (opcode == OP_CHECKSIG) | (opcode == OP_CHECKSIGVERIFY) {
                        let verify = opcode == OP_CHECKSIGVERIFY;
                        let sigadd = opcode == OP_CHECKSIGADD;
                        self.stack = checksig::<MAX_STACK_ELEMENT_SIZE, MAX_STACK_SIZE, CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, PREV_TRANSACTION_SIZE, PREV_INPUT_COUNT, PREV_INPUT_COUNT_LEN, PREV_INPUT_SIZE, PREV_OUTPUT_COUNT, PREV_OUTPUT_COUNT_LEN, PREV_OUTPUT_SIZE, PREV_MAX_WITNESS_STACK_SIZE, PREV_WITNESS_SIZE, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN, N_INPUT_SIZE, SCRIPT_PUB_KEY_LEN, REDEEM_SCRIPT_LEN, UTXOS_LEN>(
                            self.stack,
                            utxo_data,
                            leaf_script_hash,
                            verify,
                            sigadd,
                            address,
                        );
                    } else if (opcode == OP_CHECKMULSIG) | (opcode == OP_CHECKMULSIGVERIFY) {
                        if address.is_p2tr() {
                            assert(false, "OP_CHECKMULSIG is disabled in p2tr");
                        }
                        let verify = opcode == OP_CHECKMULSIGVERIFY;
                        let n = vec_to_u32(self.stack.data[self.stack.stack_size - 1]);
                        let m = vec_to_u32(self.stack.data[self.stack.stack_size - 2 - n]);
                        self.stack = checkmulsig::<MAX_STACK_ELEMENT_SIZE, MAX_STACK_SIZE, CURRENT_TRANSACTION_SIZE, CURRENT_INPUT_COUNT, CURRENT_INPUT_COUNT_LEN, CURRENT_INPUT_SIZE, CURRENT_OUTPUT_COUNT, CURRENT_OUTPUT_COUNT_LEN, CURRENT_OUTPUT_SIZE, CURRENT_MAX_WITNESS_STACK_SIZE, CURRENT_WITNESS_SIZE, PREV_TRANSACTION_SIZE, PREV_INPUT_COUNT, PREV_INPUT_COUNT_LEN, PREV_INPUT_SIZE, PREV_OUTPUT_COUNT, PREV_OUTPUT_COUNT_LEN, PREV_OUTPUT_SIZE, PREV_MAX_WITNESS_STACK_SIZE, PREV_WITNESS_SIZE, N_OUTPUT_SIZE, INPUT_TO_SIGN, INPUT_TO_SIGN_LEN, N_INPUT_SIZE, SCRIPT_PUB_KEY_LEN, REDEEM_SCRIPT_LEN>(
                            self.stack,
                            n,
                            m,
                            verify,
                            address,
                        );
                    } else if opcode == OP_CHECKLOCKTIMEVERIFY {
                        self.stack.op_checklocktimeverify();
                    } else if opcode == OP_CHECKSEQUENCEVERIFY {
                        self.stack.op_checksequenceverify();
                    } else if address.is_p2tr() & (SUCCESSX.any(|e| e == opcode) | (opcode >= 187)) {
                        op_successx = true;
                    } else if (opcode == OP_RESERVED)
                        | (opcode == OP_RESERVED1)
                        | (opcode == OP_RESERVED2)
                        | (opcode == OP_VER) {
                        assert(false, "Reserved opcode!");
                    }
                }
            }
        }

        // Script is always successful if we execute op_successx
        if op_successx {
            self.stack.op_num(1);
        } else {
            assert(ifs_len == 1);
            if codesep & !address.is_p2tr() {
                assert(REDEEM_SCRIPT_LEN == SCRIPT_SIZE - csp_pos);
            }
        }
    }
}

// Tests fail because of empty test tx if you want to run it - comment:
// self.stack.op_checklocktimeverify();
// self.stack.op_checksequenceverify();
// at the execute method

#[test]
fn test_if_opcodes() {
    let stack: TestStack<4, 10> = Stack::new_test_stack();
    // OP_NOTIF OP_3 OP_ELSE OP_IF OP_2 OP_ELSE OP_4 OP_ENDIF OP_ENDIF OP_ADD OP_5 OP_EQUALVERIFY
    let script_else_else = hex_to_bytes("510051645367635267546868935588");
    let mut engine = ScriptExecutionEngine::new(stack);
    engine.execute::<15, 0, 0, 0, 0, 15, 0, 0>(
        script_else_else,
        Address::new_p2sh(),
        [0; 0],
        Option::none(),
    );

    let script_if = hex_to_bytes("5200645367635267546868935588");
    engine.execute::<14, 0, 0, 0, 0, 14, 0, 0>(
        script_if,
        Address::new_p2sh(),
        [0; 0],
        Option::none(),
    );

    let script_else_if = hex_to_bytes("535151645367635267546868935588");
    engine.execute::<15, 0, 0, 0, 0, 15, 0, 0>(
        script_else_if,
        Address::new_p2sh(),
        [0; 0],
        Option::none(),
    );
}

#[test(should_fail_with = "Disabled or reserved opcode!")]
fn test_disabled_opcodes() {
    let stack: TestStack<4, 10> = Stack::new_test_stack();
    // OP_1 OP_2 OP_MUL
    let script_else_else = hex_to_bytes("515295");
    let mut engine = ScriptExecutionEngine::new(stack);
    engine.execute::<3, 0, 0, 0, 0, 3, 0, 0>(
        script_else_else,
        Address::new_p2sh(),
        [0; 0],
        Option::none(),
    );
}

#[test(should_fail_with = "Reserved opcode!")]
fn test_reserved_opcodes() {
    let stack: TestStack<4, 10> = Stack::new_test_stack();
    // OP_1 OP_2 OP_RESERVED
    let script_else_else = hex_to_bytes("515250");
    let mut engine = ScriptExecutionEngine::new(stack);
    engine.execute::<3, 0, 0, 0, 0, 3, 0, 0>(
        script_else_else,
        Address::new_p2sh(),
        [0; 0],
        Option::none(),
    );
}

/*
global TEST_SCRIPT_SIG_SIZE: u32 = 139;
global TEST_SCRIPT_PUB_KEY_SIZE: u32 = 25;
global TEST_MAX_NUMBER_OF_OPCODES: u32 = 7;
global TEST_STACK_ELEMENT_LENGTH_1: u32 = 65;
global TEST_STACK_ELEMENT_LENGTH_2: u32 = 72;
global TEST_STACK_ELEMENT_LENGTH_3: u32 = 20;
global TEST_STACK_ELEMENT_LENGTH_4: u32 = 1;
global TEST_STACK_ELEMENT_LENGTH_5: u32 = 1;
global TEST_STACK_ELEMENT_LENGTH_6: u32 = 1;
global TEST_SCRIPT_CODE_LEN_1: u32 = 26;
global TEST_SCRIPT_CODE_LEN_2: u32 = 1;
global TEST_SCRIPT_CODE_LEN_3: u32 = 1;
global TEST_SCRIPT_CODE_LEN_4: u32 = 1;
global TEST_SCRIPT_CODE_LEN_5: u32 = 1;

#[test]
fn test_p2pkh_execution() {
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
    );

    let mut script_execution_engine = ScriptExecutionEngine::new(stack);

    let script_sig_key_hex = "48304502203f004eeed0cef2715643e2f25a27a28f3c578e94c7f0f6a4df104e7d163f7f8f022100b8b248c1cfd8f77a0365107a9511d759b7544d979dd152a955c867afac0ef7860141044d05240cfbd8a2786eda9dadd520c1609b8593ff8641018d57703d02ba687cf2f187f0cee2221c3afb1b5ff7888caced2423916b61444666ca1216f26181398c";
    let script_sig_key_bytes = hex_to_bytes(script_sig_key_hex);

    script_execution_engine
        .execute::<TEST_SCRIPT_SIG_SIZE, 34, 1, 1, 41, TEST_MAX_NUMBER_OF_OPCODES, TEST_STACK_ELEMENT_LENGTH_1, TEST_STACK_ELEMENT_LENGTH_2, TEST_STACK_ELEMENT_LENGTH_3, TEST_STACK_ELEMENT_LENGTH_4, TEST_STACK_ELEMENT_LENGTH_5, TEST_STACK_ELEMENT_LENGTH_6, TEST_SCRIPT_CODE_LEN_1, TEST_SCRIPT_CODE_LEN_2, TEST_SCRIPT_CODE_LEN_3, TEST_SCRIPT_CODE_LEN_4, TEST_SCRIPT_CODE_LEN_5, 0, 0>(
            script_sig_key_bytes,
            Address::new_script_sig(),
        );

    let script_pub_key_hex = "76a91412ab8dc588ca9d5787dde7eb29569da63c3a238c88ac";
    let script_pub_key_bytes = hex_to_bytes(script_pub_key_hex);

    script_execution_engine
        .execute::<TEST_SCRIPT_PUB_KEY_SIZE, 34, 1, 1, 41, TEST_MAX_NUMBER_OF_OPCODES, TEST_STACK_ELEMENT_LENGTH_1, TEST_STACK_ELEMENT_LENGTH_2, TEST_STACK_ELEMENT_LENGTH_3, TEST_STACK_ELEMENT_LENGTH_4, TEST_STACK_ELEMENT_LENGTH_5, TEST_STACK_ELEMENT_LENGTH_6, TEST_SCRIPT_CODE_LEN_1, TEST_SCRIPT_CODE_LEN_2, TEST_SCRIPT_CODE_LEN_3, TEST_SCRIPT_CODE_LEN_4, TEST_SCRIPT_CODE_LEN_5, 0, 0>(
            script_pub_key_bytes,
            Address::new_p2pkh(),
        );
}
*/

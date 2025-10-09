use std::collections::map::HashMap;
use std::hash::BuildHasherDefault;
use std::hash::poseidon2::Poseidon2Hasher;

use crate::compact_size;
use utils::convert::{bytes_to_hex, hex_to_bytes, reverse_bytes};

pub struct PositionField {
    pub offset: u32,
    pub size: u32,
}

pub struct Input {
    pub txid: PositionField,
    pub vout: PositionField,
    pub script_sig_size: PositionField,
    pub script_sig: PositionField,
    pub sequence: PositionField,
}

impl Input {
    pub fn default() -> Self {
        Self {
            txid: PositionField { offset: 0, size: 0 },
            vout: PositionField { offset: 0, size: 0 },
            script_sig_size: PositionField { offset: 0, size: 0 },
            script_sig: PositionField { offset: 0, size: 0 },
            sequence: PositionField { offset: 0, size: 0 },
        }
    }
}

pub struct Output {
    pub amount: PositionField,
    pub script_pub_key_size: PositionField,
    pub script_pub_key: PositionField,
}

impl Output {
    pub fn default() -> Self {
        Self {
            amount: PositionField { offset: 0, size: 0 },
            script_pub_key_size: PositionField { offset: 0, size: 0 },
            script_pub_key: PositionField { offset: 0, size: 0 },
        }
    }
}

pub struct WitnessItem {
    pub size: PositionField,
    pub item: PositionField,
}

impl WitnessItem {
    pub fn default() -> Self {
        Self {
            size: PositionField { offset: 0, size: 0 },
            item: PositionField { offset: 0, size: 0 },
        }
    }
}

pub struct Witness {
    pub stack_size: PositionField,
    pub items: HashMap<u32, WitnessItem, 100, BuildHasherDefault<Poseidon2Hasher>>,
}

impl Witness {
    pub fn default() -> Self {
        Self { stack_size: PositionField { offset: 0, size: 0 }, items: HashMap::default() }
    }
}

pub struct Transaction<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32> {
    pub data: [u8; TRANSACTION_SIZE],
    pub version: PositionField,
    pub marker: Option<PositionField>,
    pub flag: Option<PositionField>,
    pub input_count: PositionField,
    pub inputs: [Input; INPUT_COUNT],
    pub output_count: PositionField,
    pub outputs: [Output; OUTPUT_COUNT],
    pub witness: Option<[Witness; INPUT_COUNT]>,
    pub lock_time: PositionField,
}

impl<let TRANSACTION_SIZE: u32, let INPUT_COUNT: u32, let INPUT_COUNT_LEN: u32, let INPUT_SIZE: u32, let OUTPUT_COUNT: u32, let OUTPUT_COUNT_LEN: u32, let OUTPUT_SIZE: u32, let MAX_WITNESS_STACK_SIZE: u32, let WITNESS_SIZE: u32> Transaction<TRANSACTION_SIZE, INPUT_COUNT, INPUT_COUNT_LEN, INPUT_SIZE, OUTPUT_COUNT, OUTPUT_COUNT_LEN, OUTPUT_SIZE, MAX_WITNESS_STACK_SIZE, WITNESS_SIZE> {
    pub fn new(data: [u8; TRANSACTION_SIZE], segwit: bool) -> Self {
        let mut cur_pos: u32 = 0;

        let version = PositionField { offset: cur_pos, size: 4 };
        cur_pos += 4;

        let mut marker = Option::none();
        if segwit {
            marker = Option::some(PositionField { offset: cur_pos, size: 1 });
            cur_pos += 1;
        }

        let mut flag = Option::none();
        if segwit {
            flag = Option::some(PositionField { offset: cur_pos, size: 1 });
            cur_pos += 1;
        }

        let input_count = compact_size::get_compact_size(data, cur_pos);
        cur_pos += input_count.size;

        assert(INPUT_COUNT_LEN == input_count.size);

        let mut inputs: [Input; INPUT_COUNT] = [Input::default(); INPUT_COUNT];
        for i in 0..INPUT_COUNT {
            let txid = PositionField { offset: cur_pos, size: 32 };
            cur_pos += 32;

            let vout = PositionField { offset: cur_pos, size: 4 };
            cur_pos += 4;

            let script_sig_size = compact_size::get_compact_size(data, cur_pos);
            cur_pos += script_sig_size.size;

            let script_sig_size_u32 = compact_size::compact_size_to_u32(data, script_sig_size);
            let script_sig = PositionField { offset: cur_pos, size: script_sig_size_u32 };
            cur_pos += script_sig_size_u32;

            let sequence = PositionField { offset: cur_pos, size: 4 };
            cur_pos += 4;

            inputs[i] = Input { txid, vout, script_sig_size, script_sig, sequence };
        }

        assert(INPUT_SIZE == cur_pos - input_count.offset);

        let output_count = compact_size::get_compact_size(data, cur_pos);
        cur_pos += output_count.size;

        assert(OUTPUT_COUNT_LEN == output_count.size);

        let mut outputs: [Output; OUTPUT_COUNT] = [Output::default(); OUTPUT_COUNT];
        for i in 0..OUTPUT_COUNT {
            let amount = PositionField { offset: cur_pos, size: 8 };
            cur_pos += 8;

            let script_pub_key_size = compact_size::get_compact_size(data, cur_pos);
            cur_pos += script_pub_key_size.size;

            let script_pub_key_size_u32 =
                compact_size::compact_size_to_u32(data, script_pub_key_size);
            let script_pub_key = PositionField { offset: cur_pos, size: script_pub_key_size_u32 };
            cur_pos += script_pub_key_size_u32;

            outputs[i] = Output { amount, script_pub_key_size, script_pub_key };
        }

        assert(OUTPUT_SIZE == cur_pos - output_count.offset);

        let mut witness = Option::none();
        if segwit {
            let mut all_witness: [Witness; INPUT_COUNT] = [Witness::default(); INPUT_COUNT];
            for i in 0..INPUT_COUNT {
                let stack_size = compact_size::get_compact_size(data, cur_pos);
                cur_pos += stack_size.size;

                let stack_size_u32 = compact_size::compact_size_to_u32(data, stack_size);
                let mut items: HashMap<u32, WitnessItem, 100, BuildHasherDefault<Poseidon2Hasher>> =
                    HashMap::default();

                assert(stack_size_u32 <= MAX_WITNESS_STACK_SIZE);
                for j in 0..MAX_WITNESS_STACK_SIZE {
                    if j < stack_size_u32 {
                        let size = compact_size::get_compact_size(data, cur_pos);
                        cur_pos += size.size;

                        let size_u32 = compact_size::compact_size_to_u32(data, size);
                        let item = PositionField { offset: cur_pos, size: size_u32 };
                        cur_pos += size_u32;

                        items.insert(j, WitnessItem { size, item });
                    }
                }

                all_witness[i] = Witness { stack_size, items };
            }

            witness = Option::some(all_witness);
        }

        if segwit {
            assert(WITNESS_SIZE == (cur_pos - witness.unwrap()[0].stack_size.offset));
        } else {
            assert(WITNESS_SIZE == 0);
        }

        let lock_time = PositionField { offset: cur_pos, size: 4 };
        cur_pos += 4;

        assert(TRANSACTION_SIZE == cur_pos);

        Self {
            data,
            version,
            marker,
            flag,
            input_count,
            inputs,
            output_count,
            outputs,
            witness,
            lock_time,
        }
    }

    pub fn is_segwit(self) -> bool {
        self.marker.is_some()
    }

    pub fn new_empty_transaction() -> Self {
        assert(TRANSACTION_SIZE == 0);
        assert(INPUT_COUNT == 0);
        assert(INPUT_SIZE == 0);
        assert(OUTPUT_COUNT == 0);
        assert(OUTPUT_SIZE == 0);
        assert(MAX_WITNESS_STACK_SIZE == 0);
        assert(WITNESS_SIZE == 0);

        Self {
            data: [0; TRANSACTION_SIZE],
            version: PositionField { offset: 0, size: 0 },
            marker: Option::none(),
            flag: Option::none(),
            input_count: PositionField { offset: 0, size: 0 },
            inputs: [Input::default(); INPUT_COUNT],
            output_count: PositionField { offset: 0, size: 0 },
            outputs: [Output::default(); OUTPUT_COUNT],
            witness: Option::none(),
            lock_time: PositionField { offset: 0, size: 0 },
        }
    }

    // transaction hash (what is used in txid)
    pub fn txid(self) -> [u8; 32] {
        let mut preimage_hash = [0; 4 + INPUT_SIZE + OUTPUT_SIZE + 4];

        // version
        for i in 0..4 {
            preimage_hash[i] = self.data[i];
        }

        let mut transaction_data_offset = self.input_count.offset;
        let mut preimage_hash_offset = 4;

        // input and output
        for i in 0..(INPUT_SIZE + OUTPUT_SIZE) {
            preimage_hash[preimage_hash_offset + i] = self.data[transaction_data_offset + i];
        }

        transaction_data_offset = self.lock_time.offset;
        preimage_hash_offset += INPUT_SIZE + OUTPUT_SIZE;

        // lock time
        for i in 0..4 {
            preimage_hash[preimage_hash_offset + i] = self.data[transaction_data_offset + i];
        }

        sha256::digest(sha256::digest(preimage_hash))
    }

    pub fn get_input_txid(self, input_index: u32) -> [u8; 32] {
        let txid_offset = self.inputs[input_index].txid.offset;

        let mut txid_bytes = [0; 32];
        for i in 0..32 {
            txid_bytes[i] = self.data[txid_offset + i];
        }

        txid_bytes
    }

    pub fn get_script_pub_key_with_size<let SCRIPT_PUB_KEY_SIZE: u32>(
        self,
        output_index: u32,
    ) -> [u8; SCRIPT_PUB_KEY_SIZE] {
        let mut script_pub_key = [0; SCRIPT_PUB_KEY_SIZE];
        let output = self.outputs[output_index];
        let transaction_offset = output.script_pub_key_size.offset;

        assert(
            output.script_pub_key.offset + output.script_pub_key.size - transaction_offset
                == SCRIPT_PUB_KEY_SIZE,
        );

        for i in 0..SCRIPT_PUB_KEY_SIZE {
            script_pub_key[i] = self.data[transaction_offset + i];
        }

        script_pub_key
    }

    pub fn get_witness_script_with_size<let WITNESS_SCRIPT_SIZE: u32>(
        self,
        input_index: u32,
    ) -> [u8; WITNESS_SCRIPT_SIZE] {
        let mut witness_script = [0; WITNESS_SCRIPT_SIZE];
        let witness = self.witness.unwrap()[input_index];

        let witness_stack_size = compact_size::compact_size_to_u32(self.data, witness.stack_size);
        let witness_item = witness.items.get(witness_stack_size - 1).unwrap();

        let transaction_offset = witness_item.size.offset;

        assert(
            witness_item.item.offset + witness_item.item.size - transaction_offset
                == WITNESS_SCRIPT_SIZE,
        );

        for i in 0..WITNESS_SCRIPT_SIZE {
            witness_script[i] = self.data[transaction_offset + i];
        }

        witness_script
    }

    pub fn get_amount(self, output_index: u32) -> [u8; 8] {
        let amount_offset = self.outputs[output_index].amount.offset;

        let mut amount = [0; 8];
        for i in 0..8 {
            amount[i] = self.data[amount_offset + i];
        }

        amount
    }

    pub fn get_p2wpkh_script_code(self, output_index: u32) -> [u8; 26] {
        let mut script_code = [0; 26];

        let script_pub_key = self.outputs[output_index].script_pub_key;
        assert(script_pub_key.size == 22);

        let offset = script_pub_key.offset;

        assert(self.data[offset] == 0x00);
        assert(self.data[offset + 1] == 0x14);

        for i in 0..22 {
            script_code[i + 4] = self.data[offset + i + 2];
        }

        script_code[0] = 0x19;
        script_code[1] = 0x76;
        script_code[2] = 0xa9;
        script_code[3] = 0x14;

        script_code[24] = 0x88;
        script_code[25] = 0xac;

        script_code
    }

    pub fn get_script_pub_key_size(self, output_index: u32) -> u32 {
        self.outputs[output_index].script_pub_key.size
            + self.outputs[output_index].script_pub_key_size.size
    }
}

#[test]
fn test_transaction_creation_legacy() {
    let string: str<446> = "0100000001a77618edf4b1b47885f643ea7c6349598053eb1b1b879dd698085aa97bc03fb4010000006a473044022000dc119d89dc8499dbfb7e0361e78a450013bfadc20ef8e011a444750c467aaa02200637fe44dd4950f16f4fea64b59fcc2980eb4650c582b5da5bf4b2134474dcd2012102d20b39b3b90f53677e953f39ad3a61655a1c57f98635ea70933839ce3e4e416affffffff02a08601000000000017a91499b5a29770085fc856f717cc7e52a46b2361aa9a8786960c00000000001976a91440a64639e2fbcbc593e7c257c33ea615c83c8c6788ac00000000";

    let bytes = hex_to_bytes(string);
    let transaction = Transaction::<223, 1, 1, 148, 2, 1, 67, 2, 0>::new(bytes, false);

    assert(transaction.is_segwit() == false);

    let txid_offset = transaction.inputs[0].txid.offset;
    let txid_size = transaction.inputs[0].txid.size;

    assert(txid_size == 32);
    let mut txid_bytes = [0; 32];
    for i in 0..32 {
        txid_bytes[i] = bytes[txid_offset + i];
    }

    let txid = bytes_to_hex(txid_bytes);

    assert(txid == "a77618edf4b1b47885f643ea7c6349598053eb1b1b879dd698085aa97bc03fb4");
}

#[test]
fn test_transaction_creation_segwit() {
    let string: str<702> = "0100000000010248fc3350b6d46da2b1a9f686bce993fe9c4e99e20dec6bf535e2b0451c89edff0100000000ffffffff00a3291c04a983fd0dd888442315b1eca0ae90e338e03bd95c89e8b858213fe90100000000ffffffff017a8b3b0000000000220020e2d0744b20aa3319d5e7a6220296fb7fd2f73ac934456f155ec98da41f4918030247304402207980264b54284b4b762e3284d70477d19e5156d27603c2b4a54669dbc0b4c62d0220488ca70a5892f0fbc915f9b26e987d30151710ab295bc88c4ff824dfc73f3990012102c2f3e2a446815b7cb8f0b0390fada48fefc4bc45026414cc8d1aec33574afcd50247304402203724093d7d059f65a6bcec1d4dc85620f2cdc24824c9b9897aa34d1d2c76f7a4022073ef3d58c106e50431df3f103aa045edafe4d5c7e300546752fcde2f64bb705f012102317fbf9a0f8e2b0071879850b5c703f3c22e926ae3c36d7bf2236e49701718f800000000";

    let bytes = hex_to_bytes(string);
    let transaction = Transaction::<351, 2, 1, 83, 1, 1, 44, 2, 214>::new(bytes, true);

    assert(transaction.is_segwit() == true);

    let witness_stack_item_position = transaction.witness.unwrap()[0].items.get(1).unwrap().item;

    assert(witness_stack_item_position.size == 33);
    let mut witness_stack_item_bytes = [0; 33];
    for i in 0..33 {
        witness_stack_item_bytes[i] = bytes[witness_stack_item_position.offset + i];
    }

    let witness_stack_item = bytes_to_hex(witness_stack_item_bytes);
    assert(
        witness_stack_item == "02c2f3e2a446815b7cb8f0b0390fada48fefc4bc45026414cc8d1aec33574afcd5",
    );
}

#[test]
fn test_transaction_hash() {
    let string: str<634> = "020000000001016d16731b9e16c2b8ac3499935af3f4f02a3e5b2bcb22376ef48e9fea5987fc052e00000000fdffffff012202000000000000225120079041570ca421321409eb2a3f9dab81e4445ea73004467170660ba890eafc680340d118072a8ff004a87c607d1e7042cc8b624d8132d143d9d86d24a09ec6df66080842916d7bebce70611627d536519c630a3306ebaafbf1531aca28e4fe84ce0a78202cea7e08b4a583bc246c332aa00e79c1150e798e0b197a4462b42181b47f2a1cac0063036f7264010118746578742f706c61696e3b636861727365743d7574662d3800327b2270223a226272632d3230222c226f70223a226d696e74222c227469636b223a2275666f78222c22616d74223a2233227d6821c12cea7e08b4a583bc246c332aa00e79c1150e798e0b197a4462b42181b47f2a1c00000000";
    let bytes = hex_to_bytes(string);
    let transaction = Transaction::<317, 1, 1, 42, 1, 1, 44, 3, 221>::new(bytes, true);

    let txid = transaction.txid();
    let txid_hex = bytes_to_hex(txid);

    assert(txid_hex == "9f7af38feb87c8ea7a5f572ea44fde9378b1d188eee4fd5f5f1e0aa15d8eccd5");
}

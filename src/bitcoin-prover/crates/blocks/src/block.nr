use convert::convert::{bytes_to_hex, reverse_bytes, sha256_to_le_bytes, u32_to_le_bytes};

pub struct BlockHeader {
    pub version: u32,
    pub prev_block: str<64>,
    pub merkle_root: str<64>,
    pub timestamp: u32,
    pub bits: u32,
    pub nonce: u32,
}

impl BlockHeader {
    pub fn to_byte_array(self) -> [u8; 80] {
        let mut res = u32_to_le_bytes(self.version).as_slice();

        res = res.append(sha256_to_le_bytes(self.prev_block));

        res = res.append(sha256_to_le_bytes(self.merkle_root));

        res = res.append(u32_to_le_bytes(self.timestamp));

        res = res.append(u32_to_le_bytes(self.bits));

        res = res.append(u32_to_le_bytes(self.nonce));

        res.as_array()
    }
}

pub fn get_block_hash(value: BlockHeader) -> str<64> {
    bytes_to_hex(
        reverse_bytes(sha256::digest(sha256::digest(value.to_byte_array()))),
    )
}

pub fn tagged_sha256<let TAG_SIZE: u32, let MESSAGE_SIZE: u32>(
    tag: str<TAG_SIZE>,
    message: [u8; MESSAGE_SIZE],
) -> [u8; 32] {
    sha256::digest(
        tag.as_bytes().as_slice().append(message).as_array::<TAG_SIZE + MESSAGE_SIZE>(),
    )
}

pub fn calc_merkle_state<let SIZE: u32>(
    mut prev_merkle_state: [[u8; 32]; SIZE],
    mut new_node: [u8; 32],
) -> [[u8; 32]; SIZE] {
    let mut change = true;
    new_node = tagged_sha256("leaf2", new_node);
    for i in 0..SIZE {
        if change {
            if prev_merkle_state[i].all(|e| e == 0) {
                prev_merkle_state[i] = new_node;
                change = false;
            } else {
                new_node = tagged_sha256(
                    "node2",
                    prev_merkle_state[i].as_slice().append(new_node).as_array::<64>(),
                );
                prev_merkle_state[i] = [0; 32];
            }
        }
    }

    prev_merkle_state
}

pub fn finalize_merkle_state<let SIZE: u32>(mut merkle_state: [[u8; 32]; SIZE]) -> [u8; 32] {
    let mut tmp_node = [0; 32];
    for i in 0..(SIZE - 1) {
        if !merkle_state[i].all(|e| e == 0) {
            let right = if tmp_node.all(|e| e == 0) {
                merkle_state[i]
            } else {
                tmp_node
            };

            tmp_node = tagged_sha256(
                "node2",
                merkle_state[i].as_slice().append(right).as_array::<64>(),
            );
            merkle_state[i] = [0; 32];
        } else if !tmp_node.all(|e| e == 0) {
            tmp_node = tagged_sha256(
                "node2",
                tmp_node.as_slice().append(tmp_node).as_array::<64>(),
            );
        }
    }

    if tmp_node.all(|e| e == 0) {
        merkle_state[SIZE - 1]
    } else {
        tmp_node
    }
}

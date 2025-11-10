mod constants;

use blocks_lib::block::{BlockHeader, get_block_hash, tagged_sha256};
use constants::MERKLE_ROOT_ARRAY_LEN;
use utils::convert::hex_to_bytes;

fn main(
    block: BlockHeader,
    address: [u8; 20],
) -> pub ([u8; 32], [u32; 11], u32, u32, Field, [[u8; 32]; MERKLE_ROOT_ARRAY_LEN], u32, [u8; 32]) {
    let block_hash = get_block_hash(block);
    assert(block_hash == "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f");

    let block_hash = hex_to_bytes(block_hash);

    let mut timestamps = [0; 11];
    timestamps[0] = block.timestamp;

    let address_commitment = tagged_sha256(
        "address",
        block_hash.as_slice().append(address).as_array::<52>(),
    );

    let merkle_branch = tagged_sha256("leaf2", tagged_sha256("leaf1", block_hash));

    let mut merkle_state = [[0; 32]; MERKLE_ROOT_ARRAY_LEN];
    merkle_state[0] = merkle_branch;

    (block_hash, timestamps, 1, 0, 0x100010001, merkle_state, block.timestamp, address_commitment)
}

mod constants;

use dep::std;
use blocks_lib::{
    block::{BlockHeader, calc_merkle_state, get_block_hash, tagged_sha256},
    chain::check_chain,
};
use constants::{
    HONK_IDENTIFIER, HONK_PROOF_SIZE, HONK_VK_SIZE, MERKLE_ROOT_ARRAY_LEN, PUBLIC_INPUTS,
};
use utils::convert::{bytes_to_hex, hex_to_bytes};

fn main(
    verification_key: [Field; HONK_VK_SIZE],
    proof: [Field; HONK_PROOF_SIZE],
    public_inputs: [Field; PUBLIC_INPUTS],
    block: BlockHeader,
    prev_block: BlockHeader,
    address: [u8; 20],
) -> pub ([u8; 32], [u32; 11], u32, u32, Field, [[u8; 32]; MERKLE_ROOT_ARRAY_LEN], u32, [u8; 32]) {
    std::verify_proof_with_type(verification_key, proof, public_inputs, 0x0, HONK_IDENTIFIER);

    let mut prev_block_hash = [0; 32];
    for i in 0..32 {
        prev_block_hash[i] = public_inputs[i] as u8;
    }

    let mut timestamps = [0; 11];
    for i in 0..11 {
        timestamps[i] = public_inputs[32 + i] as u32;
    }

    let time_idx = public_inputs[43] as u32;

    let last_block_height = public_inputs[44] as u32;

    let chainwork = public_inputs[45];

    let mut idx = 46;

    let mut merkle_state = [[0; 32]; MERKLE_ROOT_ARRAY_LEN];

    for i in 0..MERKLE_ROOT_ARRAY_LEN {
        for j in 0..32 {
            merkle_state[i][j] = public_inputs[idx] as u8;
            idx += 1;
        }
    }

    let prev_timestamp = public_inputs[idx] as u32;
    idx += 1;

    assert(bytes_to_hex(prev_block_hash) == get_block_hash(prev_block));

    let checked = check_chain(
        block,
        prev_block,
        timestamps,
        time_idx,
        last_block_height,
        chainwork,
        prev_timestamp,
    );

    assert(checked.0);

    let block_hash = hex_to_bytes(get_block_hash(block));
    let address_commitment = tagged_sha256(
        "address",
        block_hash.as_slice().append(address).as_array::<52>(),
    );

    let merkle_branch = tagged_sha256("leaf1", block_hash);

    merkle_state = calc_merkle_state(merkle_state, merkle_branch);

    (
        block_hash, checked.1, checked.2, checked.3, checked.4, merkle_state, checked.5,
        address_commitment,
    )
}

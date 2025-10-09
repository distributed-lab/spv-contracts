use super::schnorr::tagged_hash;
use dep::bignum::{BigNum, U256};
use utils::convert::{bytes_to_hex, hex_to_bytes};

/// First element in merkle_path must be leaf script hash
pub fn calc_merkle_root<let MERKLE_PATH_LEN: u32>(
    merkle_path: [[u8; 32]; MERKLE_PATH_LEN],
) -> [u8; 32] {
    assert(MERKLE_PATH_LEN > 0);
    if MERKLE_PATH_LEN == 1 {
        merkle_path[0]
    } else {
        let tag = "TapBranch".as_bytes();

        let mut res = merkle_path[0];
        let mut second = merkle_path[1];
        for i in 0..(MERKLE_PATH_LEN - 1) {
            if U256::from_be_bytes(res.as_slice().push_front(0).as_array::<33>())
                > U256::from_be_bytes(merkle_path[i + 1].as_slice().push_front(0).as_array::<33>()) {
                second = res;
                res = merkle_path[i + 1];
            } else {
                second = merkle_path[i + 1];
            }

            res = tagged_hash(res.as_slice().append(second).as_array::<64>(), tag);
        }

        res
    }
}

#[test]
fn calc_merkle_root_test() {
    let merkle_path = [
        hex_to_bytes(
            "6b13becdaf0eee497e2f304adcfa1c0c9e84561c9989b7f2b5fc39f5f90a60f6",
        ),
        hex_to_bytes(
            "ed5af8352e2a54cce8d3ea326beb7907efa850bdfe3711cef9060c7bb5bcf59e",
        ),
        hex_to_bytes(
            "160bd30406f8d5333be044e6d2d14624470495da8a3f91242ce338599b233931",
        ),
        hex_to_bytes(
            "bf2c4bf1ca72f7b8538e9df9bdfd3ba4c305ad11587f12bbfafa00d58ad6051d",
        ),
        hex_to_bytes(
            "54962df196af2827a86f4bde3cf7d7c1a9dcb6e17f660badefbc892309bb145f",
        ),
    ];

    assert(
        bytes_to_hex(calc_merkle_root(merkle_path))
            == "b5b72eea07b3e338962944a752a98772bbe1f1b6550e6fb6ab8c6e6adb152e7c",
    );
}

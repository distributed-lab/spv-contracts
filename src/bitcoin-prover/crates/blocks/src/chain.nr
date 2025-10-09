use super::{block::{BlockHeader, get_block_hash}, target::{check_target, uncompres_target}};
use dep::bignum::{BigNum, U256, U512};
use std::ops::Mul;

global expected_time: Field = 1209600;
global max_target: Field = 0x00000000FFFF0000000000000000000000000000000000000000000000000000;

pub fn check_chain<let SIZE: u32>(
    block: BlockHeader,
    prev_block: BlockHeader,
    mut timestamps: [u32; 11],
    mut time_idx: u32,
    mut block_height: u32,
    mut chainwork: Field,
    mut prev_timestamp: u32,
) -> (bool, [u32; 11], u32, u32, Field, u32) {
    let mut is_correct = true;

    block_height += 1;
    // prev block hash
    if block.prev_block != get_block_hash(prev_block) {
        is_correct = false;
        println("prev hash fail");
    }

    let idx = if (block_height < 11) {
        block_height / 2 + 11 - block_height
    } else {
        5
    };

    // timestamp
    if !(block.timestamp > timestamps.sort()[idx]) {
        is_correct = false;
        println("timestamp fail");
    }

    timestamps[time_idx] = block.timestamp;
    time_idx = (time_idx + 1) % 11;

    // if new target
    if block_height % 2016 == 0 {
        let actual_time = (prev_block.timestamp - prev_timestamp);

        let targ = uncompres_target(prev_block.bits);
        let mut target =
            targ.mul(U256::from((actual_time) as Field)).udiv(U256::from(expected_time));

        if target < targ.udiv(U256::from(4)) {
            target = targ.udiv(U256::from(4));
        } else if targ.mul(U256::from(4)) < target {
            target = targ.mul(U256::from(4));
        }

        target = if U256::from(max_target) < target {
            U256::from(max_target)
        } else {
            // Safety: the target will be cut using shift and compared to the res
            let (res, shift) = unsafe { cut(target) };

            assert(
                target.udiv(U256::from(2.pow_32(shift as Field))).mul(U256::from(2.pow_32(
                    shift as Field,
                )))
                    == res,
            );

            res
        };

        if target != uncompres_target(block.bits) {
            is_correct = false;
            println("target eq fail");
        }
        prev_timestamp = block.timestamp;
    } else {
        if prev_block.bits != block.bits {
            is_correct = false;
            println("prev bits fail");
        }
    }

    // hash <= target
    if !check_target(block) {
        is_correct = false;
        println("target check fail");
    }

    let new_chainwork = calc_chainwork(chainwork, block.bits);

    (is_correct, timestamps, time_idx, block_height, new_chainwork, prev_timestamp)
}

fn calc_chainwork(mut old_chainwork: Field, target: u32) -> Field {
    let two_pow = U512::from_be_bytes([
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00,
    ]);

    let work = Field::from_be_bytes(two_pow
        .udiv(U512::from_be_bytes([0; 32]
            .as_slice()
            .append(uncompres_target(target).to_be_bytes())
            .as_array::<65>()))
        .to_be_bytes());

    old_chainwork + work
}

pub(crate) unconstrained fn cut(mut value: U256) -> (U256, u8) {
    let mut count: u8 = 0;
    for _ in 0..256 {
        if value.udiv(U256::from(2.pow_32(24))).is_zero() {
            break;
        }

        value = value.udiv(U256::from(2.pow_32(8)));
        count += 8;
    }

    if U256::from(7) < value.udiv(U256::from(2.pow_32(20))) {
        value = value.udiv(U256::from(2.pow_32(8)));
        count += 8;
    }

    (value.mul(U256::from(2.pow_32(count as Field))), count)
}

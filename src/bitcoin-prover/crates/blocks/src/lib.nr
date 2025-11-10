use bignum::{BigNum, fields::U256::U256};
use chain::cut;
use std::ops::Mul;

pub mod block;
pub mod target;
pub mod chain;

#[test]
fn test() {
    let actual_time = (1458291885 - 1457133956);
    let expected_time = 1209600;

    let max_target = U256::from(
        0x00000000FFFF0000000000000000000000000000000000000000000000000000,
    );

    let targ = U256::from(
        0x000000000000000006f0a8000000000000000000000000000000000000000000,
    );
    let mut target = targ.mul(U256::from(actual_time as Field)).udiv(U256::from(expected_time));

    if target < targ.udiv(U256::from(4)) {
        target = targ.udiv(U256::from(4));
    } else if targ.mul(U256::from(4)) < target {
        target = targ.mul(U256::from(4));
    }

    target = if max_target < target {
        max_target
    } else {
        target
    };

    // Safety:
    target = unsafe { cut(target).0 };

    assert(
        target
            == U256::from(
                0x000000000000000006a4c3000000000000000000000000000000000000000000,
            ),
    );
}

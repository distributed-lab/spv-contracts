use dep::bignum::{BigNum, U768};
use dep::bignum::fields::secp256k1Fq::Secp256k1_Fq;
use std::ops::{Add, Div, Mul, Sub};

pub struct I768 {
    pub num: U768,
    pub is_neg: bool,
}

impl I768 {
    pub fn from(value: Field) -> Self {
        I768 { num: U768::from(value), is_neg: false }
    }

    pub fn umod(self, modulo: U768) -> Self {
        if (self.is_neg) {
            I768 { num: (modulo - U768::umod(self.num, modulo)), is_neg: false }
        } else {
            I768 { num: U768::umod(self.num, modulo), is_neg: false }
        }
    }
}

impl Add for I768 {
    fn add(self, other: Self) -> Self {
        if self.is_neg & other.is_neg {
            I768 { num: self.num + other.num, is_neg: true }
        } else if !self.is_neg & !other.is_neg {
            I768 { num: self.num + other.num, is_neg: false }
        } else {
            if self.num > other.num {
                I768 { num: self.num - other.num, is_neg: self.is_neg }
            } else {
                I768 { num: other.num - self.num, is_neg: other.is_neg }
            }
        }
    }
}

impl Sub for I768 {
    fn sub(self, other: Self) -> Self {
        if self.is_neg & other.is_neg {
            if self.num > other.num {
                I768 { num: self.num - other.num, is_neg: true }
            } else {
                I768 { num: other.num - self.num, is_neg: false }
            }
        } else if !self.is_neg & !other.is_neg {
            if self.num >= other.num {
                I768 { num: self.num - other.num, is_neg: false }
            } else {
                I768 { num: other.num - self.num, is_neg: true }
            }
        } else {
            if self.is_neg {
                I768 { num: self.num + other.num, is_neg: true }
            } else {
                I768 { num: self.num + other.num, is_neg: false }
            }
        }
    }
}

impl Mul for I768 {
    fn mul(self, other: Self) -> Self {
        let result = self.num * other.num;
        let is_neg = self.is_neg ^ other.is_neg;

        I768 { num: result, is_neg }
    }
}

impl Div for I768 {
    fn div(self, other: Self) -> Self {
        let quotient = self.num.udiv(other.num);
        let is_neg = self.is_neg ^ other.is_neg;

        I768 { num: quotient, is_neg }
    }
}

pub fn sqrt_secp256k1(value: Secp256k1_Fq) -> Secp256k1_Fq {
    // Safety:
    let mut res = unsafe { value.__tonelli_shanks_sqrt().unwrap() };
    assert(res * res == value);

    if res.get_limb(0) % 2 == 1 {
        res = -res;
    }

    res
}

// Tonelli-Shanks algorithm
// unconstrained fn _sqrt_secp256k(value: Secp256k1_Fq) -> Secp256k1_Fq {
//     let mut e = U256::from_be_bytes([0 as u8].as_slice().append(Secp256k1_Fq::modulus().to_be_bytes()).as_array::<33>());
//     e = (e + U256::from(1)).udiv(U256::from(4));
//     let mut res1 = Secp256k1_Fq::one();
//     let mut res2 = value;

//     for _ in 0..256 {
//         if !e.is_zero() {
//             if e.get_limb(0) % 2 == 1 {
//                 res1 = (res1 * res2);
//             }
//             res2 = (res2 * res2);
//             e = e.udiv(U256::from(2));
//         }
//     }
//     res1
// }

#[test]
fn sqrt_test() {
    // We don't need to check the result (check only odd or even) because of assert into this function
    let num = sqrt_secp256k1(Secp256k1_Fq::from(34));
    assert(num.get_limb(0) % 2 == 0);
}

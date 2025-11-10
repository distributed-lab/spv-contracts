use super::convert::bytes_to_hex;
use dep::bignum::{BigNum, U256};
use std::ops::Mul;

global base58: [u8; 58] = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz".as_bytes();

pub fn encode_base58<let LEN: u32>(ripemd: [u8; 20]) -> str<LEN> {
    let mut res = [0; LEN];
    let mut bytes = [5; 1].as_slice();
    bytes = bytes.append(ripemd);
    let checksum = sha256::digest(sha256::digest(bytes.as_array::<21>()));
    for i in 0..4 {
        bytes = bytes.push_back(checksum[i]);
    }

    let divider = U256::from(58);
    let mut divided = U256::from_be_bytes([0; 8].as_slice().append(bytes).as_array::<33>());

    let mut quotient = U256::zero();
    let mut remainder = U256::zero();

    for i in 0..LEN {
        quotient = divided.udiv(divider);
        remainder = divided - quotient.mul(divider);
        res[LEN - i - 1] = base58[remainder.get_limb(0)];

        divided = quotient;
    }

    res.as_str_unchecked()
}

global bech32m: [u8; 32] = "qpzry9x8gf2tvdw0s3jn54khce6mua7l".as_bytes();

pub fn encode_bech32m(value: [u8; 32]) -> str<62> {
    let mut res = [0; 0].as_slice();

    let data = bytes_to_bits(value).as_slice().append([0, 0, 0, 0]);

    let mut nums = [0; 0].as_slice();
    for i in 0..52 {
        nums = nums.push_back(bits_5_to_num([
            data[i * 5],
            data[i * 5 + 1],
            data[i * 5 + 2],
            data[i * 5 + 3],
            data[i * 5 + 4],
        ]));
    }

    res = res.append(nums);

    nums = bech32m_hrp_expand("bc").as_slice().push_back(1).append(nums).append([0, 0, 0, 0, 0, 0]);

    let mut chk: u32 = 1;

    let generator: [u32; 5] = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3];

    for i in 0..64 {
        let top = chk >> 25;
        chk = ((chk & 0x1FFFFFF) << 5) ^ nums[i] as u32;
        for j in 0..5 {
            if (top >> j) as u1 == 1 {
                chk ^= generator[j];
            }
        }
    }

    chk = chk ^ 0x2bc830a3;

    for i in 0..6 {
        res = res.push_back((chk >> (5 * (5 - i)) & 0x1f) as u8);
    }

    for i in 0..58 {
        res[i] = bech32m[res[i]];
    }

    "bc1p".as_bytes().as_slice().append(res).as_array().as_str_unchecked()
}

fn bech32m_hrp_expand(value: str<2>) -> [u8; 5] {
    let b = value.as_bytes();
    [b[0] >> 5, b[1] >> 5, 0, b[0] % 32, b[1] % 32]
}

fn bytes_to_bits<let N: u32>(value: [u8; N]) -> [u1; N * 8] {
    let mut res = [0; 0].as_slice();
    for i in 0..N {
        for j in 0..8 {
            res = res.push_back((value[i] >> (7 - j)) as u1);
        }
    }

    res.as_array()
}

fn bits_5_to_num(value: [u1]) -> u8 {
    let mut res = 0;

    for i in 0..5 {
        res += (value[i] as u8 << (4 - i));
    }

    res
}

// Always return array with 72 elements, if it should be less - cut zeros from the end of array
// First return parameter - der encoding, second - actual len of encoded data
pub fn encode_der(r: U256, s: U256) -> ([u8; 72], u8) {
    let res = [48].as_slice();
    // First bytes of r and s
    let rf = r.to_be_bytes()[1];
    let sf = s.to_be_bytes()[1];

    if (rf >= 128) & (sf >= 128) {
        (
            res
                .append([70, 2, 33])
                .append(r.to_be_bytes())
                .append([2, 33])
                .append(s.to_be_bytes())
                .as_array(), 72,
        )
    } else if rf >= 128 {
        (
            res
                .append([69, 2, 33])
                .append(r.to_be_bytes())
                .append([2, 32])
                .append(s.to_be_bytes().as_slice().pop_front().1)
                .push_back(0)
                .as_array(), 71,
        )
    } else if sf >= 128 {
        (
            res
                .append([69, 2, 32])
                .append(r.to_be_bytes().as_slice().pop_front().1)
                .append([2, 33])
                .append(s.to_be_bytes())
                .push_back(0)
                .as_array(), 71,
        )
    } else {
        (
            res
                .append([68, 2, 32])
                .append(r.to_be_bytes().as_slice().pop_front().1)
                .append([2, 32])
                .append(s.to_be_bytes().as_slice().pop_front().1)
                .append([0, 0])
                .as_array(), 70,
        )
    }
}

#[test]
fn bech32m_hrp_expand_test() {
    assert(bech32m_hrp_expand("bc") == [3, 3, 0, 2, 3]);
}

#[test]
fn bech32m_test() {
    // 3e2a04301a44f3e709011a24112deca591412a97d9c673acb15ceac031779f42
    assert(
        encode_bech32m([
            0x3e, 0x2a, 0x04, 0x30, 0x1a, 0x44, 0xf3, 0xe7, 0x09, 0x01, 0x1a, 0x24, 0x11, 0x2d,
            0xec, 0xa5, 0x91, 0x41, 0x2a, 0x97, 0xd9, 0xc6, 0x73, 0xac, 0xb1, 0x5c, 0xea, 0xc0,
            0x31, 0x77, 0x9f, 0x42,
        ])
            == "bc1p8c4qgvq6gne7wzgprgjpzt0v5kg5z25hm8r88t93tn4vqvthnapqhffa0r",
    );
}

#[test]
fn base58_test() {
    assert(encode_base58::<34>([0; 20]) == "31h1vYVSYuKP6AhS86fbRdMw9XHieotbST");

    assert(
        encode_base58::<34>([
            184, 144, 114, 199, 223, 158, 97, 157, 0, 164, 89, 62, 138, 251, 161, 231, 184, 186, 30,
            168,
        ])
            == "3JWuJHhVg3s84J2JfMcA59doNqdCFvH6jb",
    );

    assert(
        encode_base58::<34>([
            216, 5, 100, 220, 11, 49, 60, 93, 156, 161, 35, 216, 193, 131, 186, 222, 82, 255, 17,
            65,
        ])
            == "3MPELm1Zt83sMD63zBDUioX4AY6W4nFB1q",
    );
}

#[test]
fn der_test() {
    let r = U256::from_be_bytes([
        0x00, 0xD9, 0x2D, 0xB2, 0x0B, 0xF9, 0xF8, 0xBD, 0xB4, 0xF7, 0x41, 0xBD, 0x33, 0x35, 0x7B,
        0x3A, 0xC0, 0x26, 0x90, 0xDA, 0x19, 0xED, 0x7F, 0xF3, 0xCC, 0x3F, 0x50, 0x70, 0x15, 0x16,
        0x90, 0x77, 0xE3,
    ]);

    let s = U256::from_be_bytes([
        0x00, 0x01, 0x9B, 0xC2, 0x2A, 0x3C, 0x4A, 0x0B, 0xA2, 0x36, 0x8D, 0x2F, 0x4F, 0xCC, 0xB2,
        0xA0, 0x5A, 0x1A, 0x19, 0x24, 0xD3, 0x54, 0x12, 0x62, 0x47, 0x74, 0xC1, 0xDC, 0xAC, 0x54,
        0xD7, 0x4A, 0x46,
    ]);

    assert(
        bytes_to_hex(encode_der(r, s).0.as_slice().pop_back().0.as_array())
            == "3045022100d92db20bf9f8bdb4f741bd33357b3ac02690da19ed7ff3cc3f507015169077e30220019bc22a3c4a0ba2368d2f4fccb2a05a1a1924d35412624774c1dcac54d74a46",
    );
}

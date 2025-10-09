use dep::bignum::{BigNum, U256, U768};
use std::collections::bounded_vec::BoundedVec;

pub fn u32_to_le_bytes(value: u32) -> [u8; 4] {
    let mut res = [0; 4];
    for i in 0..4 {
        res[i] = (value >> (i << 3)) as u8;
    }

    res
}

pub fn u32_to_be_bytes(value: u32) -> [u8; 4] {
    let mut res = [0; 4];
    for i in 0..4 {
        res[i] = (value >> ((3 - i) << 3)) as u8;
    }

    res
}

pub fn sha256_to_le_bytes(value: str<64>) -> [u8; 32] {
    let mut res = [0; 32];
    let value = value.as_bytes();
    for i in 0..32 {
        res[31 - i] =
            (hex_symbol_to_byte(value[i << 1]) << 4) + hex_symbol_to_byte(value[(i << 1) + 1]);
    }

    res
}

pub fn bytes_to_hex<let N: u32>(value: [u8; N]) -> str<N * 2> {
    let mut res = [0; N * 2];
    for i in 0..N {
        res[i << 1] = byte_to_hex_symbol(value[i] >> 4);
        res[(i << 1) + 1] = byte_to_hex_symbol(value[i] & 0xf);
    }

    res.as_str_unchecked()
}

pub fn byte_to_hex_symbol(value: u8) -> u8 {
    if value <= 9 {
        value + 48
    } else {
        value + 87
    }
}

pub fn hex_symbol_to_byte(value: u8) -> u8 {
    if value < 58 {
        value - 48
    } else {
        value - 87
    }
}

pub fn reverse_bytes<let N: u32>(bytes: [u8; N]) -> [u8; N] {
    let mut res = [0; N];
    for i in 0..N {
        res[i] = bytes[N - 1 - i];
    }
    res
}

pub fn hex_to_bytes<let LEN: u32>(hex: str<LEN>) -> [u8; LEN / 2] {
    let raw_bytes = hex.as_bytes();
    let mut res = [0; LEN / 2];

    for i in 0..(LEN / 2) {
        res[i] = (hex_symbol_to_byte(raw_bytes[i * 2]) * 16)
            + hex_symbol_to_byte(raw_bytes[(i * 2) + 1]);
    }

    res
}

pub fn bytes_to_vec<let N: u32, let MAX_STACK_ELEMENT_SIZE: u32>(
    bytes: [u8; N],
) -> BoundedVec<u8, MAX_STACK_ELEMENT_SIZE> {
    let mut vec = BoundedVec::new();
    for i in 0..N {
        vec.push(bytes[i]);
    }
    vec
}

pub fn vec_to_i32<let MAX_STACK_ELEMENT_SIZE: u32>(
    v: BoundedVec<u8, MAX_STACK_ELEMENT_SIZE>,
) -> i32 {
    assert(v.len() <= 4);
    let mut result: [u8; 4] = [0; 4];
    let N = v.len();
    for i in 0..4 {
        if i < N {
            result[i] = v.get(i);
        }
    }
    le_bytes_to_i32(result)
}

pub fn i32_to_vec<let N: u32, let MAX_STACK_ELEMENT_SIZE: u32>(
    number: i32,
) -> BoundedVec<u8, MAX_STACK_ELEMENT_SIZE> {
    let bytes = i32_to_le_bytes(number);
    bytes_to_vec(bytes)
}

pub fn i32_to_le_bytes(number: i32) -> [u8; 4] {
    let unsigned_number: u32 = number as u32;
    let mut bytes = [0; 4];
    for i in 0..4 {
        bytes[i as u32] = ((unsigned_number >> (i * 8)) & 0xff) as u8;
    }
    bytes
}

pub fn le_bytes_to_i32(bytes: [u8; 4]) -> i32 {
    let mut result: u32 = 0;
    for i in 0..4 {
        result |= (bytes[i as u32] as u32) << (i * 8);
    }

    result as i32
}

pub fn vec_to_u32<let MAX_STACK_ELEMENT_SIZE: u32>(
    v: BoundedVec<u8, MAX_STACK_ELEMENT_SIZE>,
) -> u32 {
    assert(v.len() <= 4);
    let mut result: [u8; 4] = [0; 4];
    let N = v.len();
    for i in 0..4 {
        if i < N {
            result[i] = v.get(i);
        }
    }
    le_bytes_to_u32(result)
}

pub fn le_bytes_to_u32(bytes: [u8; 4]) -> u32 {
    let mut result: u32 = 0;
    for i in 0..4 {
        result |= (bytes[i as u32] as u32) << (i * 8);
    }
    result
}

pub fn u32_to_vec<let N: u32, let MAX_STACK_ELEMENT_SIZE: u32>(
    number: u32,
) -> BoundedVec<u8, MAX_STACK_ELEMENT_SIZE> {
    let bytes = u32_to_le_bytes(number);
    bytes_to_vec(bytes)
}

pub fn get_256_bits_from_768(value: U768) -> U256 {
    let mut res = [0; 0].as_slice();
    let val = value.to_le_bytes();
    for i in 0..32 {
        res = res.push_back(val[i]);
    }

    res = res.push_back(0);

    U256::from_le_bytes(res.as_array::<33>())
}

pub fn vec_to_array<let MAX_STACK_ELEMENT_SIZE: u32, let NEW_LEN: u32>(
    v: BoundedVec<u8, MAX_STACK_ELEMENT_SIZE>,
) -> [u8; NEW_LEN] {
    assert(v.len() == NEW_LEN);

    let mut res = [0; NEW_LEN];
    for i in 0..NEW_LEN {
        res[i] = v.get(i);
    }

    res
}

#[test]
fn test_bytes_to_hex() {
    let bytes: [u8; 4] = [0xab, 0x2f, 0x12, 0x34];
    let hex = bytes_to_hex(bytes);
    assert(hex == "ab2f1234");
}

#[test]
fn test_hex_to_bytes() {
    let hex = "ab2f1234";
    let bytes = hex_to_bytes(hex);
    assert(bytes == [0xab, 0x2f, 0x12, 0x34]);
}

#[test]
fn test_i32_to_vec_to_i32() {
    let number = 123456789;
    let vec: BoundedVec<u8, 10> = i32_to_vec(number);
    let i32_number = vec_to_i32(vec);
    assert(i32_number == number);
}

#[test]
fn test_u32_to_vec_to_u32() {
    let number = 123456789;
    let vec: BoundedVec<u8, 10> = u32_to_vec(number);
    let u32_number = vec_to_u32(vec);
    assert(u32_number == number);
}

use super::point::{add_point, mul_point, Point};
use dep::bignum::{BigNum, U256};
use dep::bignum::fields::{secp256k1Fq::Secp256k1_Fq, secp256k1Fr::Secp256k1_Fr};
use utils::convert::{bytes_to_hex, hex_to_bytes};

fn xor_bytes_array(a: [u8; 32], b: [u8; 32]) -> [u8; 32] {
    let mut result = [0 as u8; 32];
    for i in 0..32 {
        result[i] = a[i] ^ b[i];
    }

    result
}

pub fn tagged_hash<let N: u32, let M: u32>(message: [u8; N], tag: [u8; M]) -> [u8; 32] {
    let mut hash_of_tag = sha256::digest(tag);
    let mut double_hash_of_tag = [0 as u8; 64 + N];

    for i in 0..64 {
        double_hash_of_tag[i] = hash_of_tag[i % 32];
    }
    for i in 0..N {
        double_hash_of_tag[i + 64] = message[i];
    }

    hash_of_tag = sha256::digest(double_hash_of_tag);

    hash_of_tag
}

pub fn tagged_hash_from_U256<let M: u32>(message: U256, tag: [u8; M]) -> [u8; 32] {
    let mut hash_of_tag = sha256::digest(tag);
    let mut double_hash_of_tag = [0 as u8; 64 + 32];

    for i in 0..64 {
        double_hash_of_tag[i] = hash_of_tag[i % 32];
    }
    let message_to_bytes = message.to_be_bytes();
    for i in 0..32 {
        double_hash_of_tag[i + 64] = message_to_bytes[i + 1];
    }

    hash_of_tag = sha256::digest(double_hash_of_tag);

    hash_of_tag
}

pub fn get_r_and_s_from_signature(signature: [u8; 64]) -> ([u8; 32], [u8; 32]) {
    let mut r = [0 as u8; 32];
    let mut s = [0 as u8; 32];

    for i in 0..32 {
        r[i] = signature[i];
    }
    for i in 0..32 {
        s[i] = signature[i + 32];
    }

    (r, s)
}

pub fn schnorr_sign(message: [u8; 32], priv_key: [u8; 32], aux_rand_data: [u8; 32]) -> [u8; 64] {
    //can be represented as hash already
    let tag_nonce = "BIP0340/nonce";
    let tag_aux = "BIP0340/aux";
    let tag_challenge = "BIP0340/challenge";

    // Base point
    let G = Point {
        x: Secp256k1_Fq::from_be_bytes([
            0x79, 0xBE, 0x66, 0x7E, 0xF9, 0xDC, 0xBB, 0xAC, 0x55, 0xA0, 0x62, 0x95, 0xCE, 0x87,
            0x0B, 0x07, 0x02, 0x9B, 0xFC, 0xDB, 0x2D, 0xCE, 0x28, 0xD9, 0x59, 0xF2, 0x81, 0x5B,
            0x16, 0xF8, 0x17, 0x98,
        ]),
        y: Secp256k1_Fq::from_be_bytes([
            0x48, 0x3A, 0xDA, 0x77, 0x26, 0xA3, 0xC4, 0x65, 0x5D, 0xA4, 0xFB, 0xFC, 0x0E, 0x11,
            0x08, 0xA8, 0xFD, 0x17, 0xB4, 0x48, 0xA6, 0x85, 0x54, 0x19, 0x9C, 0x47, 0xD0, 0x8F,
            0xFB, 0x10, 0xD4, 0xB8,
        ]),
        is_O: false,
    };

    let priv_key_num = Secp256k1_Fr::from_be_bytes(priv_key);

    let pub_key: Point = mul_point(priv_key_num, G);
    let mut d = priv_key_num;

    Secp256k1_Fr::validate_in_field(d);

    if pub_key.y.get_limb(0) % 2 != 0 {
        d = -priv_key_num;
    }

    let aux_rand_hash = tagged_hash(aux_rand_data, tag_aux.as_bytes());

    let t = xor_bytes_array(d.to_be_bytes(), aux_rand_hash);

    let rand = tagged_hash(
        t.as_slice().append(pub_key.x.to_be_bytes()).append(message).as_array::<96>(),
        tag_nonce.as_bytes(),
    );

    let mut k = Secp256k1_Fr::from_be_bytes(rand);

    let R = mul_point(k, G);

    if R.y.get_limb(0) % 2 != 0 {
        k = -k;
    }

    let e_hash = tagged_hash(
        R.x.to_be_bytes().as_slice().append(pub_key.x.to_be_bytes()).append(message).as_array::<96>(),
        tag_challenge.as_bytes(),
    );

    let e = Secp256k1_Fr::from_be_bytes(e_hash);

    let signature = R.x.to_be_bytes().as_slice().append((k + e * d).to_be_bytes()).as_array::<64>();

    signature
}

pub fn schnorr_verify(pub_key_x: [u8; 32], message: [u8; 32], signature: [u8; 64]) -> bool {
    let tag_challenge = "BIP0340/challenge";

    let G = Point {
        x: Secp256k1_Fq::from_be_bytes([
            0x79, 0xBE, 0x66, 0x7E, 0xF9, 0xDC, 0xBB, 0xAC, 0x55, 0xA0, 0x62, 0x95, 0xCE, 0x87,
            0x0B, 0x07, 0x02, 0x9B, 0xFC, 0xDB, 0x2D, 0xCE, 0x28, 0xD9, 0x59, 0xF2, 0x81, 0x5B,
            0x16, 0xF8, 0x17, 0x98,
        ]),
        y: Secp256k1_Fq::from_be_bytes([
            0x48, 0x3A, 0xDA, 0x77, 0x26, 0xA3, 0xC4, 0x65, 0x5D, 0xA4, 0xFB, 0xFC, 0x0E, 0x11,
            0x08, 0xA8, 0xFD, 0x17, 0xB4, 0x48, 0xA6, 0x85, 0x54, 0x19, 0x9C, 0x47, 0xD0, 0x8F,
            0xFB, 0x10, 0xD4, 0xB8,
        ]),
        is_O: false,
    };

    let pub_key_x_num = Secp256k1_Fq::from_be_bytes(pub_key_x);

    let c = pub_key_x_num * pub_key_x_num * pub_key_x_num + Secp256k1_Fq::from(7);
    // Safety: sqrt of x^3 + 7
    let mut pub_key_y = unsafe { c.__tonelli_shanks_sqrt().unwrap() };
    assert((pub_key_y * pub_key_y) == c);

    if (pub_key_y.get_limb(0) % 2 != 0) {
        pub_key_y = -pub_key_y;
    }

    let mut pub_key =
        Point { x: Secp256k1_Fq::from_be_bytes(pub_key_x), y: pub_key_y, is_O: false };

    let (r, s) = get_r_and_s_from_signature(signature);

    let e_hash = tagged_hash(
        r.as_slice().append(pub_key.x.to_be_bytes()).append(message).as_array::<96>(),
        tag_challenge.as_bytes(),
    );

    let e = Secp256k1_Fr::from_be_bytes(e_hash);

    pub_key = mul_point(e, pub_key);
    pub_key.y = -pub_key.y;

    let mut point_r = add_point(mul_point(Secp256k1_Fr::from_be_bytes(s), G), pub_key);

    assert(!point_r.is_O);
    assert(point_r.y.get_limb(0) % 2 == 0);

    point_r.x == Secp256k1_Fq::from_be_bytes(r)
}

#[test]
fn test_schnorr_sign() {
    let message: [u8; 32] = [
        0x47, 0xB2, 0x08, 0x90, 0x89, 0xBB, 0x28, 0x5F, 0xF0, 0xD7, 0xE6, 0x7D, 0x6F, 0xE4, 0xC2,
        0x77, 0x9D, 0x22, 0x6F, 0xD4, 0x0F, 0x81, 0x5B, 0x50, 0xFB, 0x91, 0xB9, 0xB3, 0xAF, 0xAA,
        0x80, 0xFD,
    ];

    let nonce: [u8; 32] = [
        0x2A, 0xBE, 0x2F, 0x9F, 0xA6, 0x97, 0x1E, 0x62, 0x1E, 0xFC, 0x3D, 0xD6, 0x18, 0x61, 0x79,
        0x10, 0x76, 0xDB, 0x3B, 0x3F, 0xFC, 0x5A, 0x8F, 0xF1, 0xCA, 0xD9, 0x13, 0x8D, 0xBD, 0xE9,
        0x83, 0x1A,
    ];

    let priv_key: [u8; 32] = [
        0x74, 0x52, 0xC2, 0x07, 0x1E, 0x16, 0x3E, 0x22, 0x60, 0x75, 0x4A, 0xA9, 0x8E, 0xFA, 0x90,
        0x69, 0x71, 0xCC, 0x56, 0xDD, 0x6A, 0xD8, 0x96, 0x72, 0xDC, 0x5B, 0x4C, 0x49, 0x6D, 0x4A,
        0x15, 0x9E,
    ];
    let signature = schnorr_sign(message, priv_key, nonce);

    assert(
        bytes_to_hex(signature)
            == "2bdaec19c876cc8b4fdc39f2319783c5008dfa810593fff3d7b5008033318b9b80392d48aa79f13600d45717a97dfec721149ea37b9bdc67b0d0de8987077101",
    );
}

#[test]
fn test_schnorr_sign_2() {
    let message = hex_to_bytes(
        "a2c03ff351fd112d21c304c762ebb1029090cd905e8c5f1c674f15ebd219c7e0",
    );

    let nonce = hex_to_bytes(
        "2549ec4c66426df139a29760070cfa7ac0c4df4c7f7656219bbc3333300cdc4a",
    );
    let priv_key = hex_to_bytes(
        "d5ef0e4537bad9005a69774f0a2dfed81e9cc19959bb53e0962c9a42646a315a",
    );
    let signature = schnorr_sign(message, priv_key, nonce);

    assert(
        bytes_to_hex(signature)
            == "a95b410cc1a82759b4d3b43cbd69b23a4d6d27e7cbd637ffc3531ac044a0836af5f961209bd0cb4a6f79aed361e559bbd6bcad21795da940a745108dba0f5587",
    );
}

#[test]
fn test_schnorr_verify() {
    let message: [u8; 32] = [
        0x47, 0xB2, 0x08, 0x90, 0x89, 0xBB, 0x28, 0x5F, 0xF0, 0xD7, 0xE6, 0x7D, 0x6F, 0xE4, 0xC2,
        0x77, 0x9D, 0x22, 0x6F, 0xD4, 0x0F, 0x81, 0x5B, 0x50, 0xFB, 0x91, 0xB9, 0xB3, 0xAF, 0xAA,
        0x80, 0xFD,
    ];

    let pub_key_x = hex_to_bytes(
        "8f31ff5365d9f84ffe813ca3d430cc41de82317db7490b61f36e5188e7f5bf13",
    );

    let signature = hex_to_bytes(
        "2bdaec19c876cc8b4fdc39f2319783c5008dfa810593fff3d7b5008033318b9b80392d48aa79f13600d45717a97dfec721149ea37b9bdc67b0d0de8987077101",
    );

    assert(schnorr_verify(pub_key_x, message, signature))
}

#[test]
fn test_schnorr_verify_2() {
    let message = hex_to_bytes(
        "50ff47562d61fcc69793f3472ce606b74558006ac39c8028786c3b3844e7cccd",
    );

    let pub_key_x = hex_to_bytes(
        "646462116eeab64f9301bec28832746ddad9b83fee0e947a102d052dccd2e5a6",
    );

    let signature = hex_to_bytes(
        "b95e34e2967b7f938bd8185dbbf0922ed6b1ef8c854816d0b63a16fe2ed7d3cc6cc5201553f1fe14bd19e55e7f4daab15d7e19125c4c805073e99afee4ac3169",
    );

    assert(schnorr_verify(pub_key_x, message, signature))
}

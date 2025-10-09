use super::point::{get_low_s_if_needed, get_y_from_x, mul_point, Point};
use dep::bignum::BigNum;
use dep::bignum::fields::{secp256k1Fq::Secp256k1_Fq, secp256k1Fr::Secp256k1_Fr};
use std::ecdsa_secp256k1;
use utils::{convert::bytes_to_hex, decode::decode_der};

pub fn ecdsa_sign(
    message: [u8; 32],
    priv_key: Secp256k1_Fr,
    nonce: Secp256k1_Fr,
) -> (Secp256k1_Fq, Secp256k1_Fr) {
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

    let message_num = Secp256k1_Fr::from_be_bytes(message);
    let rand_point = mul_point(nonce, G);
    // Safety: inverse modulo
    let inv_nonce = unsafe { nonce.__invmod() };
    assert((inv_nonce * nonce) == Secp256k1_Fr::from(1));

    let r = Secp256k1_Fr::from_be_bytes(rand_point.x.to_be_bytes());
    let mut s = (inv_nonce * (message_num + r * priv_key));

    let half_modulus = Secp256k1_Fq::from_be_bytes((Secp256k1_Fr::modulus().to_be_bytes()))
        / Secp256k1_Fq::from(2);

    if s > Secp256k1_Fr::from_be_bytes(half_modulus.to_be_bytes()) {
        s = -s;
    }

    (rand_point.x, s)
}

pub fn get_xy_from_compressed_pubkey(pubkey: [u8; 33]) -> ([u8; 32], [u8; 32]) {
    let mut pub_x = [0; 32];
    let mut pub_y = [0; 32];

    if (pubkey[0] != 0x02) & (pubkey[0] != 0x03) {
        assert(false, "Invalid pubkey");
    }
    pub_y = get_y_from_x(pubkey.as_slice().as_array());
    pub_x = pubkey.as_slice().pop_front().1.as_array::<32>();

    (pub_x, pub_y)
}

pub fn get_xy_from_uncompressed_pubkey(pubkey: [u8; 65]) -> ([u8; 32], [u8; 32]) {
    let mut pub_x = [0; 32];
    let mut pub_y = [0; 32];

    if pubkey[0] != 0x04 {
        assert(false, "Invalid pubkey");
    }
    for i in 0..32 {
        pub_x[i] = pubkey[i + 1];
    }
    for i in 0..32 {
        pub_y[i] = pubkey[i + 33];
    }

    (pub_x, pub_y)
}

pub fn get_rs_from_signature<let DER_SIGNATURE_LEN: u32>(
    encoded_signature: [u8; DER_SIGNATURE_LEN],
) -> [u8; 64] {
    let (sign_r, sign_s) = decode_der(encoded_signature);
    let sign_s = get_low_s_if_needed(sign_s);

    let sign_r = sign_r.to_be_bytes().as_slice().pop_front().1.as_array::<32>();
    let sign_s = sign_s.to_be_bytes().as_slice().pop_front().1.as_array::<32>();

    let signature = sign_r.as_slice().append(sign_s).as_array::<64>();

    signature
}

pub fn ecdsa_verify(
    pub_x: [u8; 32],
    pub_y: [u8; 32],
    signature: [u8; 64],
    message_hash: [u8; 32],
) -> bool {
    ecdsa_secp256k1::verify_signature(pub_x, pub_y, signature, message_hash)
}

// pub fn ecdsa_verify(
//     pub_x: [u8; 32],
//     pub_y: [u8; 32],
//     signature: [u8; 64],
//     message_hash: [u8; 32],
// ) -> bool {
//     let pub_x = Secp256k1_Fq::from_limbs(U256::from_be_bytes([0; 1]
//         .as_slice()
//         .append(pub_x)
//         .as_array())
//         .get_limbs());
//     let pub_y = Secp256k1_Fq::from_limbs(U256::from_be_bytes([0; 1]
//         .as_slice()
//         .append(pub_y)
//         .as_array())
//         .get_limbs());

//     let mut r_bytes = [0; 32];
//     let mut s_bytes = [0; 32];
//     for i in 0..32 {
//         r_bytes[i] = signature[i];
//         s_bytes[i] = signature[32 + i]
//     }

//     let r = Secp256k1_Fr::from_limbs(U256::from_be_bytes([0; 1].as_slice().append(r_bytes).as_array())
//         .get_limbs());
//     let s = Secp256k1_Fr::from_limbs(U256::from_be_bytes([0; 1].as_slice().append(s_bytes).as_array())
//         .get_limbs());

//     verify_ecdsa::<32, 65, Secp256k1_Fq, Secp256k1_Fr, Secp256k1_Params>(
//         pub_x,
//         pub_y,
//         message_hash,
//         (r, s),
//     )
// }

#[test]
fn ecdsa_sign_test() {
    let message = [
        0x47, 0xB2, 0x08, 0x90, 0x89, 0xBB, 0x28, 0x5F, 0xF0, 0xD7, 0xE6, 0x7D, 0x6F, 0xE4, 0xC2,
        0x77, 0x9D, 0x22, 0x6F, 0xD4, 0x0F, 0x81, 0x5B, 0x50, 0xFB, 0x91, 0xB9, 0xB3, 0xAF, 0xAA,
        0x80, 0xFD,
    ];

    let nonce = [
        0x2A, 0xBE, 0x2F, 0x9F, 0xA6, 0x97, 0x1E, 0x62, 0x1E, 0xFC, 0x3D, 0xD6, 0x18, 0x61, 0x79,
        0x10, 0x76, 0xDB, 0x3B, 0x3F, 0xFC, 0x5A, 0x8F, 0xF1, 0xCA, 0xD9, 0x13, 0x8D, 0xBD, 0xE9,
        0x83, 0x1A,
    ];

    let priv_key = [
        0x74, 0x52, 0xC2, 0x07, 0x1E, 0x16, 0x3E, 0x22, 0x60, 0x75, 0x4A, 0xA9, 0x8E, 0xFA, 0x90,
        0x69, 0x71, 0xCC, 0x56, 0xDD, 0x6A, 0xD8, 0x96, 0x72, 0xDC, 0x5B, 0x4C, 0x49, 0x6D, 0x4A,
        0x15, 0x9E,
    ];

    let pub_key_x = [
        0x8F, 0x31, 0xFF, 0x53, 0x65, 0xD9, 0xF8, 0x4F, 0xFE, 0x81, 0x3C, 0xA3, 0xD4, 0x30, 0xCC,
        0x41, 0xDE, 0x82, 0x31, 0x7D, 0xB7, 0x49, 0x0B, 0x61, 0xF3, 0x6E, 0x51, 0x88, 0xE7, 0xF5,
        0xBF, 0x13,
    ];

    let pub_key_y = [
        0xC6, 0x35, 0xD3, 0x73, 0x23, 0x6B, 0x57, 0x74, 0x62, 0x90, 0xB9, 0x9F, 0xDC, 0x80, 0xDB,
        0x65, 0xBB, 0x77, 0x72, 0x39, 0x7C, 0x0D, 0x16, 0xC7, 0xFA, 0x5F, 0xD4, 0x48, 0x4B, 0xDE,
        0xF7, 0x72,
    ];

    let (r, s) = ecdsa_sign(
        message,
        Secp256k1_Fr::from_be_bytes(priv_key),
        Secp256k1_Fr::from_be_bytes(nonce),
    );

    let signature = r.to_be_bytes().as_slice().append(s.to_be_bytes()).as_array::<64>();
    println(bytes_to_hex(r.to_be_bytes()));
    println(bytes_to_hex(s.to_be_bytes()));

    assert(ecdsa_secp256k1::verify_signature(pub_key_x, pub_key_y, signature, message));
}

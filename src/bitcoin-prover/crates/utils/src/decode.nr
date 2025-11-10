use super::convert::hex_to_bytes;
use dep::bignum::{BigNum, U256};

pub fn decode_der(der: [u8]) -> (U256, U256) {
    let mut r_b = [0].as_slice();
    let mut r_s = 0;
    if der[3] == 32 {
        r_s = 4;
    } else if der[3] == 33 {
        r_s = 5;
    } else {
        assert(false);
    }

    for i in 0..32 {
        r_b = r_b.push_back(der[r_s + i]);
    }

    let mut s_b = [0].as_slice();
    let mut s_s = 0;
    if der[r_s + 32 + 1] == 32 {
        s_s = r_s + 32 + 2;
    } else if der[r_s + 32 + 1] == 33 {
        s_s = r_s + 32 + 3;
    } else {
        assert(false);
    }

    for i in 0..32 {
        s_b = s_b.push_back(der[s_s + i]);
    }

    (U256::from_be_bytes(r_b.as_array::<33>()), U256::from_be_bytes(s_b.as_array::<33>()))
}

#[test]
fn decode_der_test() {
    let der = "3045022100d92db20bf9f8bdb4f741bd33357b3ac02690da19ed7ff3cc3f507015169077e30220019bc22a3c4a0ba2368d2f4fccb2a05a1a1924d35412624774c1dcac54d74a46";

    let sign = decode_der(hex_to_bytes(der));
    assert(
        sign.0.to_be_bytes()
            == [
                0x00, 0xD9, 0x2D, 0xB2, 0x0B, 0xF9, 0xF8, 0xBD, 0xB4, 0xF7, 0x41, 0xBD, 0x33, 0x35,
                0x7B, 0x3A, 0xC0, 0x26, 0x90, 0xDA, 0x19, 0xED, 0x7F, 0xF3, 0xCC, 0x3F, 0x50, 0x70,
                0x15, 0x16, 0x90, 0x77, 0xE3,
            ],
    );

    assert(
        sign.1.to_be_bytes()
            == [
                0x00, 0x01, 0x9B, 0xC2, 0x2A, 0x3C, 0x4A, 0x0B, 0xA2, 0x36, 0x8D, 0x2F, 0x4F, 0xCC,
                0xB2, 0xA0, 0x5A, 0x1A, 0x19, 0x24, 0xD3, 0x54, 0x12, 0x62, 0x47, 0x74, 0xC1, 0xDC,
                0xAC, 0x54, 0xD7, 0x4A, 0x46,
            ],
    );
}

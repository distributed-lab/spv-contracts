use super::{schnorr::tagged_hash, types::sqrt_secp256k1};
use dep::bignum::{BigNum, U256};
use dep::bignum::fields::{secp256k1Fq::Secp256k1_Fq, secp256k1Fr::Secp256k1_Fr};
use utils::convert::{bytes_to_hex, hex_to_bytes};

// Modulo: FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F

pub struct Point {
    pub x: Secp256k1_Fq,
    pub y: Secp256k1_Fq,
    pub is_O: bool,
}

pub fn get_y_from_x(mut x: [u8; 33]) -> [u8; 32] {
    let sign = x[0];
    x[0] = 0;

    let pub_x = Secp256k1_Fq::from_be_bytes(x.as_slice().pop_front().1.as_array::<32>());

    let mut pub_y = sqrt_secp256k1(pub_x * pub_x * pub_x + Secp256k1_Fq::from(7));

    if sign == 3 {
        pub_y = -pub_y;
    } else if sign != 2 {
        assert(false, "Invalid sign");
    }

    pub_y.to_be_bytes()
}

pub fn get_low_s_if_needed(y: U256) -> U256 {
    let modulo: U256 = U256::from_be_bytes([
        0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFE, 0xBA, 0xAE, 0xDC, 0xE6, 0xAF, 0x48, 0xA0, 0x3B, 0xBF, 0xD2, 0x5E, 0x8C, 0xD0,
        0x36, 0x41, 0x41,
    ]);

    if y > modulo.udiv(U256::from(2)) {
        modulo - y
    } else {
        y
    }
}

pub fn add_point(p1: Point, p2: Point) -> Point {
    if p1.is_O {
        p2
    } else if p2.is_O {
        p1
    } else if (p1.x == p2.x) & (p1.y == p2.y) {
        double_point(p1)
    } else if (p2.x == p1.x) {
        Point { x: Secp256k1_Fq::from(0), y: Secp256k1_Fq::from(0), is_O: true }
    } else {
        // Safety: xinv * (p2.x - p1.x) == 1 mod modulo
        let xinv = unsafe { inv_mod((p2.x - p1.x)) };
        assert((xinv * (p2.x - p1.x)) == Secp256k1_Fq::from(1));

        let lm = ((p2.y - p1.y) * xinv);
        let x = (lm * lm - p1.x - p2.x);
        let y = ((p1.x - x) * lm - p1.y);

        Point { x, y, is_O: false }
    }
}

pub fn double_point(p: Point) -> Point {
    if p.is_O {
        p
    } else if p.y.is_zero() {
        Point { x: Secp256k1_Fq::from(0), y: Secp256k1_Fq::from(0), is_O: true }
    } else {
        // Safety: ypow * 2y == 1 mod modulo
        let yd = unsafe { inv_mod(p.y * Secp256k1_Fq::from(2)) };
        assert(yd * (p.y * Secp256k1_Fq::from(2)) == Secp256k1_Fq::from(1));

        let lm = (Secp256k1_Fq::from(3) * (p.x * p.x) * yd);
        let x = (lm * lm - Secp256k1_Fq::from(2) * p.x);
        let y = ((p.x - x) * lm - p.y);
        Point { x, y, is_O: false }
    }
}

pub unconstrained fn inv_mod(num: Secp256k1_Fq) -> Secp256k1_Fq {
    num.__invmod()
}

fn gcd(a: Secp256k1_Fq, b: Secp256k1_Fq) -> (Secp256k1_Fq, Secp256k1_Fq) {
    if (a.is_zero()) {
        (Secp256k1_Fq::from(0), Secp256k1_Fq::from(1))
    } else {
        let (x1, y1) = gcd(b.umod(a), a);
        let x = y1 - (b / a) * x1;
        let y = x1;

        (x, y)
    }
}

pub fn mul_point(mut scalar: Secp256k1_Fr, mut point: Point) -> Point {
    let mut res1 = Point { x: Secp256k1_Fq::from(0), y: Secp256k1_Fq::from(0), is_O: true };

    for _ in 0..256 {
        if !scalar.is_zero() {
            if scalar.get_limb(0) % 2 == 1 {
                res1 = add_point(res1, point);
            }
            point = double_point(point);
            scalar = scalar.udiv(Secp256k1_Fr::from(2));
        }
    }

    res1
}

pub fn check_tweaked_pub_key(
    pub_key_x: [u8; 32],
    pub_key_is_even: bool,
    merkle_root: [u8; 32],
    tweaked_pub_key: [u8; 32],
) -> bool {
    let tag = "TapTweak".as_bytes();
    // Base point
    let g = Point {
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

    let tweak = Secp256k1_Fr::from_be_bytes(tagged_hash(
        pub_key_x.as_slice().append(merkle_root).as_array::<64>(),
        tag,
    ));

    let tweak_point = mul_point(tweak, g);

    let sign = if pub_key_is_even { 2 } else { 3 };

    let pub_key_y = get_y_from_x(pub_key_x.as_slice().push_front(sign).as_array::<33>());
    let pub_key = Point {
        x: Secp256k1_Fq::from_be_bytes(pub_key_x),
        y: Secp256k1_Fq::from_be_bytes(pub_key_y),
        is_O: false,
    };

    let calculated_tweaked_pub_key = add_point(tweak_point, pub_key).x;

    Secp256k1_Fq::from_be_bytes(tweaked_pub_key) == calculated_tweaked_pub_key
}

#[test]
fn get_pub_key_test() {
    // Base point
    let g = Point {
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

    // 93646593437684168348644705416347933030071581704920546907172345418605260946112
    let priv_key = Secp256k1_Fr::from_be_bytes([
        0xcf, 0x0a, 0x17, 0xf3, 0xb3, 0x27, 0xaf, 0x72, 0x94, 0xa9, 0xf7, 0x03, 0x35, 0xd1, 0x59,
        0x0c, 0xdc, 0x11, 0xf9, 0xe0, 0xaf, 0x17, 0xc6, 0x9e, 0x65, 0x7c, 0x7d, 0x29, 0x8b, 0x73,
        0xba, 0xc0,
    ]);

    let x = mul_point(priv_key, g).x.to_be_bytes();

    assert(
        x
            == [
                0xD4, 0x16, 0x85, 0xA0, 0xA2, 0xAF, 0x78, 0xB3, 0x38, 0xAD, 0xDD, 0xD5, 0xF0, 0xEB,
                0x2C, 0xD9, 0x31, 0x81, 0x2E, 0xE6, 0x12, 0xA3, 0xA1, 0x2D, 0x4E, 0x02, 0xAD, 0xDA,
                0xAE, 0x05, 0x45, 0xB7,
            ],
    );
}

#[test]
fn inv_test() {
    let a = Secp256k1_Fq::from(1234567890123456789012345678901234567890);
    // Safety: it's a test
    let b = unsafe { inv_mod(a) };
    assert((a * b) == Secp256k1_Fq::from(1));
}

#[test]
fn double_add_point_test() {
    // Double
    // x: 55066263022277343669578718895168534326250603453777594175500187360389116729240
    // y: 32670510020758816978083085130507043184471273380659243275938904335757337482424
    let g = Point {
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

    // x: 89565891926547004231252920425935692360644145829622209833684329913297188986597
    // y: 12158399299693830322967808612713398636155367887041628176798871954788371653930
    let d = double_point(g);
    assert(
        d.x
            == Secp256k1_Fq::from_be_bytes([
                0xC6, 0x04, 0x7F, 0x94, 0x41, 0xED, 0x7D, 0x6D, 0x30, 0x45, 0x40, 0x6E, 0x95, 0xC0,
                0x7C, 0xD8, 0x5C, 0x77, 0x8E, 0x4B, 0x8C, 0xEF, 0x3C, 0xA7, 0xAB, 0xAC, 0x09, 0xB9,
                0x5C, 0x70, 0x9E, 0xE5,
            ]),
    );

    assert(
        d.y
            == Secp256k1_Fq::from_be_bytes([
                0x1A, 0xE1, 0x68, 0xFE, 0xA6, 0x3D, 0xC3, 0x39, 0xA3, 0xC5, 0x84, 0x19, 0x46, 0x6C,
                0xEA, 0xEE, 0xF7, 0xF6, 0x32, 0x65, 0x32, 0x66, 0xD0, 0xE1, 0x23, 0x64, 0x31, 0xA9,
                0x50, 0xCF, 0xE5, 0x2A,
            ]),
    );

    // Add
    // x: 17747932292208320336984730399201053581644640876966738635000662625257781433452
    // y: 30269137777519390959291681406422817450367061697454558436961949185376148299679
    let a = Point {
        x: Secp256k1_Fq::from_be_bytes([
            0x27, 0x3C, 0xF9, 0x44, 0x33, 0xD2, 0x75, 0x06, 0x0A, 0x5B, 0x4D, 0xC8, 0x92, 0x52,
            0x5C, 0x0C, 0xBD, 0x2A, 0x27, 0xE4, 0x61, 0x0D, 0xA1, 0x5A, 0xF0, 0x48, 0xD2, 0x29,
            0x0E, 0x23, 0x94, 0x6C,
        ]),
        y: Secp256k1_Fq::from_be_bytes([
            0x42, 0xEB, 0xB9, 0x90, 0x34, 0x2C, 0x2D, 0x68, 0x85, 0xD2, 0xA6, 0xDF, 0xA7, 0x09,
            0xFD, 0x40, 0x4B, 0xB0, 0x3D, 0x16, 0xC0, 0xD8, 0x9B, 0xFB, 0x8F, 0x28, 0x03, 0x8B,
            0x38, 0x34, 0x9F, 0x9F,
        ]),
        is_O: false,
    };

    // x: 77344730300839354696818953815458307181184769288353228668542799165886446804947
    // y: 113103504027004781256850662495511009879853304497952790659007194588522000440383
    let b = Point {
        x: Secp256k1_Fq::from_be_bytes([
            0xAA, 0xFF, 0x90, 0xE5, 0x8D, 0x24, 0x08, 0x54, 0x3F, 0xD1, 0xC6, 0xD0, 0x99, 0x2D,
            0x88, 0x08, 0x94, 0x24, 0x8B, 0xE6, 0xDA, 0x70, 0xA6, 0x7D, 0x32, 0x7F, 0x16, 0x02,
            0x55, 0x7D, 0x9F, 0xD3,
        ]),
        y: Secp256k1_Fq::from_be_bytes([
            0xFA, 0x0E, 0x50, 0x90, 0x03, 0x3D, 0x77, 0xE2, 0xB1, 0x8A, 0x12, 0x96, 0xEF, 0xB3,
            0x98, 0x0B, 0x9D, 0x47, 0xC6, 0x1F, 0x1C, 0x9A, 0xF8, 0x5E, 0x39, 0xFC, 0x51, 0xC4,
            0x52, 0xD0, 0x5C, 0x3F,
        ]),
        is_O: false,
    };

    // x: 24365175738418157851015984197408728417264987822898663307966610103110128181156
    // y: 47693669628987188103031692419078020228917122287739883771422547227590201702424
    let c = add_point(a, b);
    assert(
        c.x
            == Secp256k1_Fq::from_be_bytes([
                0x35, 0xDE, 0x33, 0x65, 0x1D, 0x7E, 0x1E, 0x1D, 0x79, 0x44, 0x91, 0x02, 0x7F, 0x86,
                0xC8, 0x38, 0x37, 0x39, 0xB9, 0x22, 0xED, 0xA5, 0x6F, 0x4B, 0x0F, 0x8B, 0x21, 0x88,
                0xB7, 0xC5, 0x1F, 0xA4,
            ]),
    );

    assert(
        c.y
            == Secp256k1_Fq::from_be_bytes([
                0x69, 0x71, 0xA9, 0x0F, 0x5D, 0xEF, 0x38, 0x2B, 0x2E, 0x05, 0xA1, 0x7A, 0x31, 0x6B,
                0x38, 0x92, 0x82, 0xE6, 0x3F, 0x6E, 0xAF, 0xF0, 0x6E, 0x59, 0xD0, 0xCE, 0x2D, 0xD1,
                0x42, 0xFB, 0xF8, 0x18,
            ]),
    );
}

#[test]
fn check_tweaked_pub_key_test() {
    let pub_key_x = hex_to_bytes(
        "a2fc329a085d8cfc4fa28795993d7b666cee024e94c40115141b8e9be4a29fa4",
    );

    let merkle_root = hex_to_bytes(
        "b5b72eea07b3e338962944a752a98772bbe1f1b6550e6fb6ab8c6e6adb152e7c",
    );

    let expected_tweaked_pub_key = hex_to_bytes(
        "562529047f476b9a833a5a780a75845ec32980330d76d1ac9f351dc76bce5d72",
    );

    assert(check_tweaked_pub_key(pub_key_x, true, merkle_root, expected_tweaked_pub_key));
}

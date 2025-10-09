pub global OP_0: u8 = 0;

pub global OP_PUSHBYTES1: u8 = 1;
pub global OP_PUSHBYTES75: u8 = 75;

pub global OP_PUSHDATA1: u8 = 76;
pub global OP_PUSHDATA2: u8 = 77;
pub global OP_PUSHDATA4: u8 = 78;

pub global OP_1NEGATE: u8 = 79;
pub global OP_1: u8 = 81;
pub global OP_16: u8 = 96;

pub global OP_IF: u8 = 99;
pub global OP_NOTIF: u8 = 100;
pub global OP_ELSE: u8 = 103;
pub global OP_ENDIF: u8 = 104;
pub global OP_RETURN: u8 = 106;

pub global OP_TOALTSTACK: u8 = 107;
pub global OP_FROMALTSTACK: u8 = 108;
pub global OP_2DROP: u8 = 109;
pub global OP_2DUP: u8 = 110;
pub global OP_3DUP: u8 = 111;
pub global OP_2OVER: u8 = 112;
pub global OP_2ROT: u8 = 113;
pub global OP_2SWAP: u8 = 114;
pub global OP_IFDUP: u8 = 115;
pub global OP_DEPTH: u8 = 116;
pub global OP_DROP: u8 = 117;
pub global OP_DUP: u8 = 118;
pub global OP_NIP: u8 = 119;
pub global OP_OVER: u8 = 120;
pub global OP_PICK: u8 = 121;
pub global OP_ROLL: u8 = 122;
pub global OP_ROT: u8 = 123;
pub global OP_SWAP: u8 = 124;
pub global OP_TUCK: u8 = 125;

pub global OP_SIZE: u8 = 130;

pub global OP_1ADD: u8 = 139;
pub global OP_1SUB: u8 = 140;
pub global OP_NEGATE: u8 = 143;
pub global OP_ABS: u8 = 144;
pub global OP_NOT: u8 = 145;
pub global OP_0NOTEQUAL: u8 = 146;
pub global OP_ADD: u8 = 147;
pub global OP_SUB: u8 = 148;
pub global OP_BOOLAND: u8 = 154;
pub global OP_BOOLOR: u8 = 155;
pub global OP_NUMEQUAL: u8 = 156;
pub global OP_NUMEQUALVERIFY: u8 = 157;
pub global OP_NUMENOTQUAL: u8 = 158;
pub global OP_LESSTHAN: u8 = 159;
pub global OP_GREATERTHAN: u8 = 160;
pub global OP_LESSTHANOREQUAL: u8 = 161;
pub global OP_GREATERTHANOREQUAL: u8 = 162;
pub global OP_MIN: u8 = 163;
pub global OP_MAX: u8 = 164;
pub global OP_WITHIN: u8 = 165;

pub global OP_RIPEMD160: u8 = 166;
pub global OP_SHA1: u8 = 167;
pub global OP_SHA256: u8 = 168;
pub global OP_HASH160: u8 = 169;
pub global OP_HASH256: u8 = 170;
pub global OP_CODESEPARATOR: u8 = 171;

pub global OP_EQUAL: u8 = 135;
pub global OP_EQUALVERIFY: u8 = 136;

pub global OP_CHECKSIG: u8 = 172;
pub global OP_CHECKSIGVERIFY: u8 = 173;
pub global OP_CHECKMULSIG: u8 = 174;
pub global OP_CHECKMULSIGVERIFY: u8 = 175;
pub global OP_CHECKSIGADD: u8 = 186;

pub global OP_CHECKLOCKTIMEVERIFY: u8 = 177;
pub global OP_CHECKSEQUENCEVERIFY: u8 = 178;

// Reserved

// Fails unless located inside an unexecuted branch of an IF block
pub global OP_RESERVED: u8 = 80;
pub global OP_VER: u8 = 98;
pub global OP_RESERVED1: u8 = 137;
pub global OP_RESERVED2: u8 = 138;

// These opcodes always fail when executed, like disabled opcodes
// pub global OP_VERIF: u8 = 101;
// pub global OP_VERNOTIF: u8 = 102;

pub global DISABLED: [u8; 17] =
    [101, 102, 126, 127, 128, 129, 131, 132, 133, 134, 141, 142, 149, 150, 151, 152, 153];

pub global SUCCESSX: [u8; 19] =
    [80, 98, 126, 127, 128, 129, 131, 132, 133, 134, 137, 138, 141, 142, 149, 150, 151, 152, 153];

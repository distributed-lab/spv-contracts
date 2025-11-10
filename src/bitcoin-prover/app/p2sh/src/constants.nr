pub global CURRENT_TX_SIZE: u32 = 254;
pub global PREV_TX_SIZE: u32 = 256;
pub global SCRIPT_SIG_SIZE: u32 = 1;
pub global SCRIPT_PUB_KEY_SIZE: u32 = 35;
pub global INPUT_WITNESS_SIZE: u32 = 39;
pub global REDEEM_SCRIPT_SIZE: u32 = 35;
pub global CODESEPARATOR_REDEEM_SCRIPT_SIZE: u32 = 35;
pub global CODESEPARATOR_REDEEM_SCRIPT_SIZE_SIZE: u32 = 1;
pub global REDEEM_SCRIPT_OPCODES_COUNT: u32 = 3;

pub global CURRENT_TX_IN_COUNT: u32 = 1;
pub global CURRENT_TX_IN_COUNT_SIZE: u32 = 1;
pub global CURRENT_TX_IN_SIZE: u32 = 42;
pub global CURRENT_TX_OUT_COUNT: u32 = 1;
pub global CURRENT_TX_OUT_COUNT_SIZE: u32 = 1;
pub global CURRENT_TX_OUT_SIZE: u32 = 35;
pub global CURRENT_TX_MAX_WITNESS_STACK_SIZE: u32 = 2;
pub global CURRENT_TX_WITNESS_SIZE: u32 = 40;
pub global IS_CURRENT_SEGWIT: bool = true;

pub global PREV_TX_IN_COUNT: u32 = 1;
pub global PREV_TX_IN_COUNT_SIZE: u32 = 1;
pub global PREV_TX_IN_SIZE: u32 = 42;
pub global PREV_TX_OUT_COUNT: u32 = 2;
pub global PREV_TX_OUT_COUNT_SIZE: u32 = 1;
pub global PREV_TX_OUT_SIZE: u32 = 78;
pub global PREV_TX_MAX_WITNESS_STACK_SIZE: u32 = 0;
pub global PREV_TX_WITNESS_SIZE: u32 = 0;
pub global IS_PREV_SEGWIT: bool = false;

pub global OPCODES_COUNT: u32 = 0;
pub global STACK_SIZE: u32 = 9;
pub global MAX_STACK_ELEMENT_SIZE: u32 = 35;
pub global N_OUTPUT_SIZE: u32 = 34;
pub global INPUT_TO_SIGN: u32 = 0;
pub global INPUT_TO_SIGN_SIZE: u32 = 1;
pub global N_INPUT_SIZE: u32 = 41;

use crate::transaction::PositionField;

pub fn compact_size_to_u32<let N: u32>(data: [u8; N], position: PositionField) -> u32 {
    let mut result: u32 = 0;
    if position.size == 1 {
        result = data[position.offset] as u32;
    } else if position.size == 3 {
        for i in 1..3 {
            result += data[position.offset + i] as u32 << (8 * (i - 1) as u8);
        }
    } else if position.size == 5 {
        for i in 1..5 {
            result += data[position.offset + i] as u32 << (8 * (i - 1) as u8);
        }
    } else if position.size == 9 {
        assert(false, "Compact size type FF is not supported");
    } else {
        assert(false, "Invalid compact size type");
    }
    result
}

pub fn get_compact_size<let N: u32>(data: [u8; N], offset: u32) -> PositionField {
    let compact_size_type = data[offset];
    let mut result = PositionField { offset: 0, size: 0 };
    if compact_size_type <= 252 {
        result = PositionField { offset: offset, size: 1 };
    } else if compact_size_type == 253 {
        result = PositionField { offset: offset, size: 3 };
    } else if compact_size_type == 254 {
        result = PositionField { offset: offset, size: 5 };
    } else {
        result = PositionField { offset: offset, size: 9 };
    }
    result
}

pub fn u32_to_compact_size_array<let ARRAY_SIZE: u32>(size: u32) -> [u8; ARRAY_SIZE] {
    let mut res = [0; ARRAY_SIZE];
    if size <= 252 {
        assert(ARRAY_SIZE == 1);
        res[0] = size as u8;
    } else if size <= 65535 {
        assert(ARRAY_SIZE == 3);
        res[0] = 253;
        res[1] = size as u8;
        res[2] = (size >> 8) as u8;
    } else if size == 254 {
        assert(ARRAY_SIZE == 5);
        res[0] = 254;
        res[1] = size as u8;
        res[2] = (size >> 8) as u8;
        res[3] = (size >> 16) as u8;
        res[4] = (size >> 24) as u8;
    } else {
        assert(false, "not implemented");
    }

    res
}

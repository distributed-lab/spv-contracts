from bitcoin.core.script import *
from bitcoin.core import CScript, CTransaction, lx
from bitcoin.core.scripteval import _EvalScript
from bitcoin.core import x
from binascii import unhexlify
from generators.utils.tx import Transaction

HASHES = [OP_SHA1, OP_SHA256, OP_RIPEMD160, OP_HASH160, OP_HASH256]

add_1_element = [0, 79, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90,
                 91, 92, 93, 94, 95, 96, 108, 115, 116, 118, 120, 125, 130]
add_2_elements = [110, 112]
add_3_elements = [111]
remove_1_element = [105, 107, 117, 119, 122, 135, 147, 148,
                    154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 172]
remove_2_elements = [109, 136, 165, 173, 186]


class Script:
    def __init__(self, hex: str, tx: Transaction, inIdx, stack=[]):
        self.script_info(hex, tx, inIdx, stack)

    def script_info(self, hex: str, tx: Transaction, inIdx, stack):
        bytes = unhexlify(hex)
        script = CScript(bytes)

        self.script_elements = format_script_elements(script)
        self.opcodes = 0
        self.require_stack_size = 0
        self.max_element_size = 0
        self.sizes = get_hashed_data_sizes(
            bytes, tx.to_hex(), inIdx, stack, tuple())
        self.script_len_codeseparator = 0

        cur_stack_size = 0
        require_alt_stack_size = 0
        alt_stack_size = 0

        i = 0
        j = 0
        while i < len(bytes):
            self.opcodes += 1

            if bytes[i] == 107:
                alt_stack_size += 1
            elif bytes[i] == 108:
                alt_stack_size -= 1

            if bytes[i] == 171:
                self.script_len_codeseparator = -1

            if bytes[i] == 172 or bytes[i] == 173:
                self.sizes.add((bytes[i], 0, 0, 0))

            if bytes[i] == 174 or bytes[i] == 175:
                n = self.script_elements[j - 1]
                m = self.script_elements[j - 2 - n]
                self.sizes.add((bytes[i], 0, n, m))

            if bytes[i] >= 1 and bytes[i] <= 75:
                self.sizes.add((bytes[i], 0, 0, 0))
                if self.max_element_size < bytes[i]:
                    self.max_element_size = bytes[i]
                self.script_len_codeseparator += bytes[i]
                i += bytes[i]
                cur_stack_size += 1
            elif bytes[i] == 76:
                size = bytes[i + 1]
                self.sizes.add((bytes[i], size, 0, 0))
                self.script_len_codeseparator += size + 1
                i += size + 1
                cur_stack_size += 1
                if self.max_element_size < size:
                    self.max_element_size = size
            elif bytes[i] == 77:
                size = bytes[i + 1] + (bytes[i + 2] << 8)
                self.sizes.add((bytes[i], size, 0, 0))
                self.script_len_codeseparator += size + 2
                i += size + 2
                cur_stack_size += 1
                if self.max_element_size < size:
                    self.max_element_size = size
            elif bytes[i] == 78:
                size = bytes[i + 1] + (bytes[i + 2] << 8) + \
                    (bytes[i + 3] << 16) + (bytes[i + 4] << 24)
                self.sizes.add((bytes[i], size, 0, 0))
                self.script_len_codeseparator += size + 4
                i += size + 4
                cur_stack_size += 1
                if self.max_element_size < size:
                    self.max_element_size = size
            elif bytes[i] in add_1_element:
                cur_stack_size += 1
            elif bytes[i] in add_2_elements:
                cur_stack_size += 2
            elif bytes[i] in add_3_elements:
                cur_stack_size += 3
            elif bytes[i] in remove_1_element:
                cur_stack_size -= 1
            elif bytes[i] in remove_2_elements:
                cur_stack_size -= 2

            if cur_stack_size > self.require_stack_size:
                self.require_stack_size = cur_stack_size
            if alt_stack_size > require_alt_stack_size:
                require_alt_stack_size = alt_stack_size

            # todo: if we have IF opcodes we can try minimize amount of opcodes

            i += 1
            j += 1
            self.script_len_codeseparator += 1

        if require_alt_stack_size > self.require_stack_size:
            self.require_stack_size = require_alt_stack_size

        # due to the specifics of implementation using noir
        self.require_stack_size += 3


def get_hashed_data_sizes(script, txTo, inIdx, stack, flags=()):
    sizes = set()
    tx = CTransaction.deserialize(unhexlify(txTo))
    stack = [to_bytes_or_keep(op) for op in stack]
    parts = split_list_by_hash(CScript(script))
    if parts[0][0] in HASHES:
        sizes.add((parts[0][0], len(stack[len(stack) - 1]), 0, 0))

    for idx, part in enumerate(parts):
        part_fixed = [ensure_bytes_or_opcode(el) for el in part]
        _EvalScript(stack, CScript(part_fixed), tx, inIdx, flags)
        if (idx != len(parts) - 1):
            sizes.add((parts[idx + 1][0], len(stack[len(stack) - 1]), 0, 0))

    return sizes


def to_bytes_or_keep(op):
    if isinstance(op, str):
        return x(op)
    elif isinstance(op, int):
        return op.to_bytes((op.bit_length() + 7) //
                           8 or 1, 'little', signed=True)
    else:
        return op


def ensure_bytes_or_opcode(el):
    if isinstance(el, str):
        return bytes.fromhex(el)
    return el


def split_list_by_hash(script):
    result = []
    current = []

    script = format_script_elements(script)
    for item in script:
        if item in HASHES:
            if current:
                result.append(current)
            current = [item]
        else:
            current.append(item)

    if current:
        result.append(current)

    return result


def format_script_elements(script):
    elements = []
    for el in script:
        if isinstance(el, int):
            elements.append(el)
        else:
            elements.append(el.hex())
    return elements

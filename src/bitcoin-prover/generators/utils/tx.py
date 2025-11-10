from typing import Dict, Union, Tuple
from collections import namedtuple

Input = namedtuple(
    'Input', [
        'txid', 'vout', 'script_sig_size', 'script_sig', 'sequence'])
Output = namedtuple(
    'Output', [
        'value', 'script_pub_key_size', 'script_pub_key'])
Witness = namedtuple('Witness', ['stack_items'])
WitnessStackItem = namedtuple('WitnessStackItem', ['item_size', 'item'])


class Transaction:
    def __init__(self, data: Union[str, Dict]):
        if isinstance(data, str):
            self._parse_from_hex(data)
        elif isinstance(data, Dict):
            self._parse_from_json(data)
        else:
            raise ValueError("Invalid data type")

    def _parse_from_hex(self, hex_tx: str) -> 'Transaction':
        """
        hex_tx: raw hex of the transaction
        """
        raw_bytes = bytes.fromhex(hex_tx)

        # this is optimization for the _get_compact_size function
        self._cache_raw_bytes = raw_bytes

        cur_pos = 0
        self.version = int.from_bytes(
            raw_bytes[cur_pos:cur_pos + 4], byteorder='little')
        cur_pos += 4

        if raw_bytes[cur_pos] == 0:
            self.marker = 0
            cur_pos += 1
            self.flag = raw_bytes[cur_pos]
            cur_pos += 1
        else:
            self.marker = None
            self.flag = None

        self.input_count, cur_pos = self._get_compact_size(cur_pos)

        self.inputs = []
        for _ in range(self.input_count):
            txid = raw_bytes[cur_pos:cur_pos + 32]
            cur_pos += 32
            vout = int.from_bytes(
                raw_bytes[cur_pos:cur_pos + 4], byteorder='little')
            cur_pos += 4
            script_sig_size, cur_pos = self._get_compact_size(cur_pos)
            script_sig = raw_bytes[cur_pos:cur_pos + script_sig_size]
            cur_pos += script_sig_size
            sequence = int.from_bytes(
                raw_bytes[cur_pos:cur_pos + 4], byteorder='little')
            cur_pos += 4
            self.inputs.append(
                Input(
                    txid,
                    vout,
                    script_sig_size,
                    script_sig,
                    sequence))

        self.output_count, cur_pos = self._get_compact_size(cur_pos)

        self.outputs = []
        for _ in range(self.output_count):
            value = int.from_bytes(
                raw_bytes[cur_pos:cur_pos + 8], byteorder='little')
            cur_pos += 8
            script_pub_key_size, cur_pos = self._get_compact_size(cur_pos)
            script_pub_key = raw_bytes[cur_pos:cur_pos + script_pub_key_size]
            cur_pos += script_pub_key_size
            self.outputs.append(
                Output(
                    value,
                    script_pub_key_size,
                    script_pub_key))

        if isinstance(self.flag, int):
            self.witness = []
            for _ in range(self.input_count):
                witness_stack = []
                stack_items, cur_pos = self._get_compact_size(cur_pos)
                for i in range(stack_items):
                    item_size, cur_pos = self._get_compact_size(cur_pos)
                    item = raw_bytes[cur_pos:cur_pos + item_size]
                    cur_pos += item_size
                    witness_stack.append(WitnessStackItem(item_size, item))
                self.witness.append(Witness(witness_stack))
        else:
            self.witness = None

        self.lock_time = int.from_bytes(
            raw_bytes[cur_pos:cur_pos + 4], byteorder='little')

        # clear the cache
        self._cache_raw_bytes = None

    def _parse_from_json(self, data: Dict):
        """
        json_data: data from blockchain.com
        """

        self.version = data['version']

        has_witness = any(
            'witness' in inp and inp['witness'] for inp in data['inputs'])

        if has_witness:
            self.marker = 0
            self.flag = 1
        else:
            self.marker = None
            self.flag = None

        self.input_count = len(data['inputs'])
        self.inputs = []
        for inp in data['inputs']:
            txid = bytes.fromhex(inp['txid'])[::-1]
            vout = inp['output']
            script_sig_size = len(inp['sigscript']) // 2
            script_sig = bytes.fromhex(inp['sigscript'])
            sequence = inp['sequence']
            self.inputs.append(
                Input(
                    txid,
                    vout,
                    script_sig_size,
                    script_sig,
                    sequence))

        self.output_count = len(data['outputs'])
        self.outputs = []
        for out in data['outputs']:
            value = out['value']
            script_pub_key_size = len(out['pkscript']) // 2
            script_pub_key = bytes.fromhex(out['pkscript'])
            self.outputs.append(
                Output(
                    value,
                    script_pub_key_size,
                    script_pub_key))

        if isinstance(self.marker, int):
            self.witness = []
            for inp in data['inputs']:
                json_witness_stack = inp['witness']
                witness_stack = []
                for json_item in json_witness_stack:
                    item_size = len(json_item) // 2
                    item = bytes.fromhex(json_item)
                    witness_stack.append(WitnessStackItem(item_size, item))
                self.witness.append(Witness(witness_stack))
        else:
            self.witness = None

        self.lock_time = data['locktime']

    def cut_script_sigs(self):
        for i in range(self.input_count):
            old_input = self.inputs[i]
            new_input = Input(
                txid=old_input.txid,
                vout=old_input.vout,
                script_sig_size=0,
                script_sig=b'',
                sequence=old_input.sequence,
            )
            self.inputs[i] = new_input

    def to_hex(self) -> str:
        version_hex = self.version.to_bytes(4, byteorder='little').hex()

        if isinstance(self.marker, int):
            marker_hex = self.marker.to_bytes(1, byteorder='little').hex()
        else:
            marker_hex = ""

        if isinstance(self.flag, int):
            flag_hex = self.flag.to_bytes(1, byteorder='little').hex()
        else:
            flag_hex = ""

        input_count_hex = self._get_hex_from_compact_size(self.input_count)

        input_hex = "".join([self._get_input_hex(input)
                            for input in self.inputs])

        output_count_hex = self._get_hex_from_compact_size(self.output_count)

        output_hex = "".join([self._get_output_hex(output)
                             for output in self.outputs])

        if isinstance(self.flag, int):
            witness_hex = "".join([self._get_witness_hex(witness)
                                  for witness in self.witness])
        else:
            witness_hex = ""

        lock_time_hex = self.lock_time.to_bytes(4, byteorder='little').hex()

        return version_hex + marker_hex + flag_hex + input_count_hex + \
            input_hex + output_count_hex + output_hex + witness_hex + lock_time_hex

    def _get_input_hex(self, _input: Input) -> str:
        txid_hex = _input.txid.hex()
        vout_hex = _input.vout.to_bytes(4, byteorder='little').hex()
        script_sig_size_hex = self._get_hex_from_compact_size(
            _input.script_sig_size)
        script_sig_hex = _input.script_sig.hex()
        sequence_hex = _input.sequence.to_bytes(4, byteorder='little').hex()
        return txid_hex + vout_hex + script_sig_size_hex + script_sig_hex + sequence_hex

    def _get_output_hex(self, output: Output) -> str:
        value_hex = output.value.to_bytes(8, byteorder='little').hex()
        script_pub_key_size_hex = self._get_hex_from_compact_size(
            output.script_pub_key_size)
        script_pub_key_hex = output.script_pub_key.hex()
        return value_hex + script_pub_key_size_hex + script_pub_key_hex

    def _get_witness_hex(self, witness: Witness) -> str:
        stack_size_hex = self._get_hex_from_compact_size(
            len(witness.stack_items))
        stack_items_hex = "".join([
            self._get_hex_from_compact_size(
                stack_item.item_size) + stack_item.item.hex()
            for stack_item in witness.stack_items
        ])
        return stack_size_hex + stack_items_hex

    def _get_hex_from_compact_size(self, int_val: int) -> str:
        if int_val <= 0xfc:
            return int_val.to_bytes(1, byteorder='little').hex()
        elif int_val <= 0xffff:
            return "fd" + int_val.to_bytes(2, byteorder='little').hex()
        elif int_val <= 0xffffffff:
            return "fe" + int_val.to_bytes(4, byteorder='little').hex()
        elif int_val <= 0xffffffffffffffff:
            return "ff" + int_val.to_bytes(8, byteorder='little').hex()
        else:
            raise ValueError("Invalid compact size value")

    def _get_compact_size(self, cur_pos: int) -> Tuple[int, int]:
        """
        cur_pos: the position of the first byte of the compact size
        return: (compact size, updated cur_pos)
        """
        if self._cache_raw_bytes[cur_pos] <= 0xfc:
            return self._cache_raw_bytes[cur_pos], cur_pos + 1
        elif self._cache_raw_bytes[cur_pos] == 0xfd:
            return int.from_bytes(
                self._cache_raw_bytes[cur_pos + 1:cur_pos + 3], byteorder='little'), cur_pos + 3
        elif self._cache_raw_bytes[cur_pos] == 0xfe:
            return int.from_bytes(
                self._cache_raw_bytes[cur_pos + 1:cur_pos + 5], byteorder='little'), cur_pos + 5
        elif self._cache_raw_bytes[cur_pos] == 0xff:
            return int.from_bytes(
                self._cache_raw_bytes[cur_pos + 1:cur_pos + 9], byteorder='little'), cur_pos + 9
        else:
            raise ValueError("Invalid compact size first byte")

    def _get_input_size(self, _input: Input) -> int:
        return 32 + 4 + \
            self._get_compact_size_size(
                _input.script_sig_size) + len(_input.script_sig) + 4

    def _get_output_size(self, output: Output) -> int:
        return 8 + \
            self._get_compact_size_size(
                output.script_pub_key_size) + len(output.script_pub_key)

    def _get_witness_size(self, witness: Witness) -> int:
        return self._get_compact_size_size(len(witness.stack_items)) + sum([
            self._get_compact_size_size(
                stack_item.item_size) + len(stack_item.item)
            for stack_item in witness.stack_items
        ])

    def _get_compact_size_size(self, int_val: int) -> int:
        return len(self._get_hex_from_compact_size(int_val)) // 2

    def _get_transaction_size(self) -> int:
        input_count_len = self._get_compact_size_size(self.input_count)
        input_size = sum(self._get_input_size(inp) for inp in self.inputs)
        output_count_len = self._get_compact_size_size(self.output_count)
        output_size = sum(self._get_output_size(out) for out in self.outputs)
        if isinstance(self.flag, int):
            witness_size = sum(self._get_witness_size(witness)
                               for witness in self.witness)
            marker_size = 1
            flag_size = 1
        else:
            witness_size = 0
            marker_size = 0
            flag_size = 0
        return 4 + marker_size + flag_size + input_count_len + \
            input_size + output_count_len + output_size + witness_size + 4

    def witness_to_hex_script(self, input_to_sign, end_ignore=0) -> str:
        res = bytearray()

        for i in range(
                len(self.witness[input_to_sign].stack_items) - end_ignore):
            item = self.witness[input_to_sign].stack_items[i]
            if item.item_size >= 1 and item.item_size <= 75:
                res.append(item.item_size)
            elif item.item_size <= 255:
                res.append(76)
                res.append(item.item_size)
            elif item.item_size <= 65535:
                res.append(77)
                res.extend(item.item_size.to_bytes(2, 'little'))
            else:
                res.append(78)
                res.extend(item.item_size.to_bytes(4, 'little'))

            res.extend(item.item)

        return res.hex()

    def print_noir_template(self) -> str:
        transaction_size = self._get_transaction_size()
        input_count = self.input_count
        input_count_len = self._get_compact_size_size(self.input_count)
        input_size = sum(self._get_input_size(inp)
                         for inp in self.inputs) + input_count_len
        output_count = self.output_count
        output_count_len = self._get_compact_size_size(self.output_count)
        output_size = sum(self._get_output_size(out)
                          for out in self.outputs) + output_count_len
        if isinstance(self.flag, int):
            max_witness_stack_size = max(
                len(witness.stack_items) for witness in self.witness)
            witness_size = sum(self._get_witness_size(witness)
                               for witness in self.witness)
        else:
            max_witness_stack_size = 0
            witness_size = 0

        return "Transaction::<{}, {}, {}, {}, {}, {}, {}, {}, {}>".format(
            transaction_size,
            input_count,
            input_count_len,
            input_size,
            output_count,
            output_count_len,
            output_size,
            max_witness_stack_size,
            witness_size,
        )

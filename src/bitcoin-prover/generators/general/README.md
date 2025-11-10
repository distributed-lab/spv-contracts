# Transaction Proof Generator

Implements a proof generator for validating transaction spendability at the input level.  
It produces a proof showing that a specific transaction input is authorized to spend the output it references.

## Configuration

Each spending type requires specific [config](config.json) fields.

If some fields are not applicable, leave them empty — **do not remove them**.

### Common configuration parameters

All spending types must include the following:

- `tx` — Hex-encoded current transaction
- `input_to_sign` — Index of the input that spends a previous transaction output

### P2MS, P2SH, P2SH-P2WPKH, P2SH-P2WSH, P2PKH, P2PK

- `script_sig` — Input data and/or the corresponding script needed to spend the output

### P2TR, P2WSH, P2WPKH

No additional configuration fields are required.  
All necessary data must be provided in the `witness` section of the `tx` hex.

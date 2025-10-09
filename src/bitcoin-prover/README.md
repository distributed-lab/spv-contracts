# Bitcoin prover

This project contains implementations in Noir and corresponding Python generators that allow proving the validity of the Bitcoin block header chain and the possibility of using the corresponding output as the input of a transaction.

## Overview

The typical workflow is as follows:
1. Python generators create configuration files.
2. Noir code in the `app/` directory is compiled and executed.
3. Proofs are generated and verified using the `bb` tool.
4. All outputs are stored in the `target/` directory.

## Requirements

- [Noir](https://noir-lang.org/) `1.0.0-beta.6`
- Python `3.12.3`
- [bb](https://github.com/AztecProtocol/barretenberg) `0.84.0`

## Usage

> [!IMPORTANT]
> All commands must be run from the root directory of the repository.

After running any script, you need to install the Python dependencies.
To do that, create a virtual environment and install the dependencies from `requirements.txt` using the following commands:

```bash
python3 -m venv ./generators/venv
source ./generators/venv/bin/activate
pip install -r requirements.txt
```

To create the blocks proof run this command:
```bash
./scripts/blocks.sh [--config ./config.json --address 0x0000000000000000000000000000000000000000]
```
| Parameter | Description | Default |
|------------|-------------|----------|
| `--config` | Path to the configuration JSON file (see example `./generators/blocks/config.json`). | `./generators/blocks/config.json` |
| `--address` | Ethereum address that will receive award (if the default address is set, anyone can receive the reward) | `0x0000000000000000000000000000000000000000` | 

To create any spending proof, edit [config](generators/general/config.json) and run:
```bash
python3 -m generators.general.main
```

## License

This project is licensed under the [MIT License](LICENSE).

#!/bin/bash

# Exit on error
set -e  

# Create required folders
mkdir -p ./target/blocks_bin
mkdir -p ./target/blocks_bin/recursive

if ! pip show electrum_client >/dev/null 2>&1; then
    echo -e "Pakage 'electrum_client' is not installed yet.\nRun:\n\tpip3 install electrum_client==0.0.1"
    exit 1
fi

# Generate Prover.toml
python3 -m generators.blocks.main "$@"
#!/bin/bash

# Exit on error
set -e

if ! pip show python-bitcoinlib >/dev/null 2>&1; then
    echo -e "Pakage 'python-bitcoinlib' is not installed yet.\nRun:\n\tpip3 install python-bitcoinlib==0.12.2"
    exit 1
fi

# Generate Prover.toml
python3 -m generators.p2sh.main

# Format noir code
nargo fmt

# Execute the binary
nargo execute --package p2sh

# Prove the proof
mkdir -p target
mkdir -p target/p2sh
bb prove -b ./target/p2sh.json -w ./target/p2sh.gz -o ./target/p2sh

# Write the VK
bb write_vk -b ./target/p2sh.json -o ./target/p2sh

# Verify the proof
bb verify -k ./target/p2sh/vk -p ./target/p2sh/proof -i ./target/p2sh/public_inputs
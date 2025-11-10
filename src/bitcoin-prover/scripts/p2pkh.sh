#!/bin/bash

# Exit on error
set -e

if ! pip show python-bitcoinlib >/dev/null 2>&1; then
    echo -e "Pakage 'python-bitcoinlib' is not installed yet.\nRun:\n\tpip3 install python-bitcoinlib==0.12.2"
    exit 1
fi

# Generate Prover.toml
python3 -m generators.p2pkh.main

# Format noir code
nargo fmt

# Execute the binary
nargo execute --package p2pkh

# Prove the proof
mkdir -p target
mkdir -p target/p2pkh
bb prove -b ./target/p2pkh.json -w ./target/p2pkh.gz -o ./target/p2pkh

# Write the VK
bb write_vk -b ./target/p2pkh.json -o ./target/p2pkh

# Verify the proof
bb verify -k ./target/p2pkh/vk -p ./target/p2pkh/proof -i ./target/p2pkh/public_inputs
#!/bin/bash

# Exit on error
set -e

if ! pip show python-bitcoinlib >/dev/null 2>&1; then
    echo -e "Pakage 'python-bitcoinlib' is not installed yet.\nRun:\n\tpip3 install python-bitcoinlib==0.12.2"
    exit 1
fi

# Generate Prover.toml
python3 -m generators.p2ms.main

# Format noir code
nargo fmt

# Execute the binary
nargo execute --package p2ms

# Prove the proof
mkdir -p target
mkdir -p target/p2ms
bb prove -b ./target/p2ms.json -w ./target/p2ms.gz -o ./target/p2ms

# Write the VK
bb write_vk -b ./target/p2ms.json -o ./target/p2ms

# Verify the proof
bb verify -k ./target/p2ms/vk -p ./target/p2ms/proof -i ./target/p2ms/public_inputs
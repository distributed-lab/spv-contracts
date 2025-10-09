#!/bin/bash

# Exit on error
set -e

if ! pip show python-bitcoinlib >/dev/null 2>&1; then
    echo -e "Pakage 'python-bitcoinlib' is not installed yet.\nRun:\n\tpip3 install python-bitcoinlib==0.12.2"
    exit 1
fi

# Generate Prover.toml
python3 -m generators.p2pk.main

# Format noir code
nargo fmt

# Execute the binary
nargo execute --package p2pk

# Prove the proof
mkdir -p target
mkdir -p target/p2pk
bb prove -b ./target/p2pk.json -w ./target/p2pk.gz -o ./target/p2pk

# Write the VK
bb write_vk -b ./target/p2pk.json -o ./target/p2pk

# Verify the proof
bb verify -k ./target/p2pk/vk -p ./target/p2pk/proof -i ./target/p2pk/public_inputs
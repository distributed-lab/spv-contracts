#!/bin/bash

# Exit on error
set -e

if ! pip show python-bitcoinlib >/dev/null 2>&1; then
    echo -e "Pakage 'python-bitcoinlib' is not installed yet.\nRun:\n\tpip3 install python-bitcoinlib==0.12.2"
    exit 1
fi

# Generate Prover.toml
python3 -m generators.p2sh_p2wpkh.main

# Format noir code
nargo fmt

# Execute the binary
nargo execute --package p2sh_p2wpkh

# Prove the proof
mkdir -p target
mkdir -p target/p2sh_p2wpkh
bb prove -b ./target/p2sh_p2wpkh.json -w ./target/p2sh_p2wpkh.gz -o ./target/p2sh_p2wpkh

# Write the VK
bb write_vk -b ./target/p2sh_p2wpkh.json -o ./target/p2sh_p2wpkh

# Verify the proof
bb verify -k ./target/p2sh_p2wpkh/vk -p ./target/p2sh_p2wpkh/proof -i ./target/p2sh_p2wpkh/public_inputs
#!/bin/bash

# Exit on error
set -e

if ! pip show python-bitcoinlib >/dev/null 2>&1; then
    echo -e "Pakage 'python-bitcoinlib' is not installed yet.\nRun:\n\tpip3 install python-bitcoinlib==0.12.2"
    exit 1
fi

if ! pip show requests >/dev/null 2>&1; then
    echo -e "Pakage 'requests' is not installed yet.\nRun:\n\tpip3 install requests==2.32.5"
    exit 1
fi

# Generate Prover.toml
python3 -m generators.p2tr_script.main

# Format noir code
nargo fmt

# Execute the binary
nargo execute --package p2tr_script

# Prove the proof
mkdir -p target
mkdir -p target/p2tr_script
bb prove -b ./target/p2tr_script.json -w ./target/p2tr_script.gz -o ./target/p2tr_script

# Write the VK
bb write_vk -b ./target/p2tr_script.json -o ./target/p2tr_script

# Verify the proof
bb verify -k ./target/p2tr_script/vk -p ./target/p2tr_script/proof -i ./target/p2tr_script/public_inputs
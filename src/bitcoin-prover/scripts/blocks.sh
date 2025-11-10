#!/bin/bash

# Exit on error
set -e  

# Create required folders
mkdir -p ./target/blocks_bin
mkdir -p ./target/blocks_bin/recursive

# Generate Prover.toml
python3 -m generators.blocks.main "$@"
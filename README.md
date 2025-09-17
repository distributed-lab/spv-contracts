# ERC-8002: SPV Gateway

This repository contains the smart contracts and services for the `SPV Gateway` — protocol that enables the trustless on-chain verification of transactions that happened on the Bitcoin network.

The protocol functions as a permissionless Simplified Payment Verification (SPV) gateway. Anyone can submit Bitcoin block headers to the gateway, which then validates them against Bitcoin's consensus rules. The gateway maintains the mainchain and allows dApps to verify a transaction's existence using Merkle proofs.

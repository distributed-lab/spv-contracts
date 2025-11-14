# SPV Gateway Examples

This directory contains example integrations with the SPV Gateway V2 contract, demonstrating how to leverage SPV (Simple Payment Verification) proofs for Bitcoin blockchain verification on Ethereum.

## Overview

The examples showcase practical use cases that utilize the SPV Gateway V2 contract to verify Bitcoin transactions and blocks on-chain. These contracts demonstrate key patterns and best practices for integrating SPV verification into Ethereum-based applications.

## Examples

### 1. BTC Whitelist

A contract that manages a whitelist of Ethereum addresses based on Bitcoin transactions. Any user can join the whitelist by providing an SPV proof of a Bitcoin transaction containing at least one output with a value exceeding the contract's configured minimum threshold.

**Key Features:**
- Whitelisting based on Bitcoin transaction verification
- Configurable minimum transaction amount
- Confirmation count requirements for security
- Paginated retrieval of whitelisted accounts

**How it works:**
1. A user submits a Bitcoin transaction alongside an SPV proof
2. The contract verifies the transaction was included in the Bitcoin blockchain
3. If the transaction meets the whitelist rules (minimum amount), the user's Ethereum address is added to the whitelist
4. The contract enforces a minimum confirmation count before considering a transaction valid

## Getting Started

### Installation

```bash
npm install
```

### Compiling

```bash
npm run compile
```

### Testing

```bash
npm run test
```

## Contract Architecture

Each example contract integrates with `ISPVGatewayV2`, which provides the core functionality for verifying Bitcoin blockchain proofs. The examples implement specific business logic on top of this base verification layer.

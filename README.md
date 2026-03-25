# SentinelGuard: Real-Time DeFi Fraud Scoring AI

## Description

**SentinelGuard** is a sophisticated, decentralized fraud prevention layer designed for the Stacks blockchain. In an era where DeFi exploits, flash loan attacks, and wash trading can drain protocols in seconds, SentinelGuard provides a real-time, on-chain immune system. 

By leveraging authorized AI oracles, the contract maintains a dynamic "Fraud Score" for every user interacting with the ecosystem. If a user's behavior—analyzed off-chain and reported on-chain—exceeds a customizable safety threshold, SentinelGuard automatically freezes the account, preventing further malicious interactions. 

This contract is designed to be integrated as a middleware for decentralized exchanges (DEXs), lending protocols, and NFT marketplaces, ensuring that only "healthy" actors can participate in the liquidity pool.

---

## Table of Contents
* Introduction
* Features
* Architecture
* Error Codes
* Administrative Functions
* Technical Specification
* Installation and Deployment
* Contributing
* License

---

## Features

### 1. Real-Time Scoring
Authorized AI Oracles can update user fraud scores (0-100) based on off-chain machine learning models that detect suspicious patterns such as circular trading or rapid-fire contract interactions.

### 2. Automatic Account Freezing
Once a user's score hits the `fraud-threshold`, the contract automatically flags the account as frozen. Any integrated DeFi protocol can then query this status to block incoming transactions instantly.

### 3. Dynamic Threshold Management
The protocol owner can adjust the sensitivity of the entire ecosystem by raising or lowering the fraud threshold in response to market volatility or increased attack vectors.

### 4. Trusted Whitelisting (VIP)
Critical infrastructure, such as governance contracts, liquidity pool routers, or verified institutional partners, can be whitelisted to ensure they are never accidentally frozen by automated heuristics.

### 5. Behavioral Redemption
The contract supports `reduce-fraud-score` logic, allowing users to improve their standing over time through consistent, non-malicious behavior, fostering a "Proof of Reputation" model.

### 6. Transaction Heuristics
A built-in simulation function, `process-defi-tx-with-scoring`, calculates risk in-flight. It applies penalties for high-value transfers or risky transaction types (e.g., Flash Loans) before the transaction is finalized.

---

## Architecture

SentinelGuard operates on a hub-and-spoke model where the smart contract acts as the "Single Source of Truth" for user reputation.

1.  **Oracles:** Off-chain AI engines scan the mempool and historical data.
2.  **Reporting:** Oracles call `report-fraud-score` to update the on-chain Map.
3.  **Enforcement:** The contract checks scores against the `fraud-threshold`.
4.  **Integration:** Third-party dApps call `get-user-full-status` to decide whether to permit a swap or loan.

---

## Error Codes

| Code | Constant | Description |
| :--- | :--- | :--- |
| u100 | `err-unauthorized` | The caller is not the contract owner or an authorized oracle. |
| u101 | `err-invalid-score` | The provided score is outside the allowed range (0-100). |
| u102 | `err-account-frozen` | The account has been frozen due to high fraud risk. |
| u103 | `err-invalid-input` | Provided parameters (like new threshold) are invalid. |
| u104 | `err-already-trusted` | The user is already on the trusted whitelist. |
| u105 | `err-not-trusted` | Attempted to remove a user who is not on the whitelist. |

---

## Technical Specification

### Data Structures
* **user-scores (map):** `principal => uint`. Tracks the current risk level.
* **frozen-accounts (map):** `principal => bool`. Tracks global lockout status.
* **ai-oracles (map):** `principal => bool`. Permissions for off-chain data providers.
* **fraud-threshold (var):** `uint`. The global limit (default 80).

### Key Functions
* `report-fraud-score`: The primary write method for oracles.
* `process-defi-tx-with-scoring`: A hybrid function that calculates risk based on transaction volume and type ($amount$ and $type$).
* `get-user-full-status`: A comprehensive read-only function providing 8 different data points about a user's standing.

---

## Installation and Deployment

### Prerequisites
* Clarinet (for local development and testing)
* A Stacks wallet with sufficient STX for deployment
* Access to an AI Oracle node (optional for local testing)

### Deployment Steps
1.  Clone the repository: `git clone https://github.com/your-repo/SentinelGuard.git`
2.  Check the contract: `clarinet check`
3.  Run the test suite: `clarinet test`
4.  Deploy to Mainnet/Testnet:
    ```bash
    stx deploy ./contracts/sentinel-guard.clar --private-key <your-key>
    ```

---

## Contributing

We welcome contributions from the DeFi security community. To contribute:
1.  Fork the Project.
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the Branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

Please ensure your code follows the Clarity Style Guide and includes comprehensive unit tests for any new logic.

---

## License

```text
MIT License

Copyright (c) 2026 SentinelGuard Protocol

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

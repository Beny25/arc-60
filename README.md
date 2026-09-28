# ARC 60

A simple 60-second BTC prediction market built on Arc Testnet.

## Overview

ARC 60 lets users predict whether BTC will move **UP** or **DOWN** over a 60-second round.

- Network: Arc Testnet
- Asset: USDC
- Market: BTC / USDC
- Round duration: 60 seconds
- Model: Parimutuel pool
- Status: Testnet / Experimental

ARC 60 is being developed as an experimental prediction-market prototype on Arc, with V1 serving as the initial testnet implementation.

## V1 Architecture

ARC 60 V1 uses an **operator/resolver-driven round lifecycle**.

The current flow is:

1. The operator creates a round.
2. The operator starts the round.
3. Users place UP or DOWN positions using USDC.
4. The operator locks the round after the betting period.
5. The operator resolves the round using the settlement data.
6. Winning users claim their proportional payout.

This architecture was intentionally kept simple for the initial Arc Testnet prototype and validation.

### V1 Contract

**PredictionPool**

`0xac26f01427a4b9cc0f05a58760f0312694527134`

The contract source is verified on the Arc Testnet explorer.

## Run Locally

Clone the repository and install the dependencies:

```bash
git clone https://github.com/Beny25/arc-60.git
cd arc-60
npm install
npm run dev

```
Then open:

`http://localhost:3000`

### Wallet Configuration

The frontend uses Reown AppKit for wallet connection.

To run the wallet functionality locally, create your own `.env.local` with the required Reown Project ID.

Do not commit `.env.local` or any private credentials to the repository.

## Tech Stack

- Next.js
- TypeScript
- Reown AppKit
- ethers
- Solidity
- Foundry
- Arc
- USDC

## V2 Roadmap

ARC 60 V2 is planned as the next iteration of the project.

The goal is to evolve the initial operator-driven prototype into a **continuous 60-second prediction-market experience**.

Planned improvements include:

- Continuous 60-second rounds
- Users entering during a round are automatically assigned to the next round
- No user-facing Create Round or Start Round workflow
- Improved pool and position tracking
- Estimated payout and profit display
- Improved settlement architecture
- Smoother USDC-based user experience on Arc
- Testnet faucet access directly from the UI

V2 will be developed in a separate repository while V1 remains available as the initial prototype and milestone.

## Disclaimer

This project is experimental and intended for testing on Arc Testnet. It is not financial advice.

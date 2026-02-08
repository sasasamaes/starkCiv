# StarkCiv – Diplomacy Edition

> "A Civilization-style strategy game where diplomacy and trust live on-chain — powered by Starknet and made frictionless with Account Abstraction."

## 🌟 Overview

**StarkCiv – Diplomacy Edition** is an asynchronous, turn-based strategy game built on **Starknet**. Inspired by the classic Civilization series, this game shifts the focus from conquest to **diplomacy, treaties, reputation, and governance**.

Designed as a hackathon-ready MVP, StarkCiv leverages **Account Abstraction** via Cavos to provide a frictionless UX, allowing players to jump into the action without the hurdles of traditional Web3 onboarding.

## 🚀 Key Features

- **Diplomatic Victory:** Win by building trust and reputation rather than just force.
- **Async Turn-Based Gameplay:** Play at your own pace with 1 action per turn levels.
- **Account Abstraction (AA):** Social/email login and gasless gameplay powered by Cavos Aegis.
- **On-Chain Governance:** Participate in global votes at the end of each Era to shape the game's rules.
- **Economic Strategy:** Manage resources (Food, Wood, Reputation) to build your civilization and its influence.

## 🎮 Gameplay Mechanics

- **Map:** A 5x5 grid where 4 players compete for influence.
- **Turns & Eras:** Each player performs one action per turn. Every 5 turns mark a new Era, triggering a global voting phase.
- **Actions:**
  - **Expand:** Claim adjacent tiles to grow your territory.
  - **Build:** Construct Farms, Markets, and Embassies.
  - **Train Guard:** Defensive units to protect your tiles.
  - **Send Aid:** Gain reputation by helping other players.
  - **Diplomacy:** Propose and manage treaties (Non-Aggression, Trade, Alliance).
- **Victory Conditions:** Reach 10 Reputation, have at least one Embassy, and complete 2 successful treaties.

## 🛠 Tech Stack

- **L2 Blockchain:** [Starknet](https://www.starknet.io/) (Sepolia Testnet)
- **Smart Contracts:** Cairo
- **Account Abstraction:** [Cavos](https://cavos.io/) (Social Login, Gasless, Session Keys)
- **Frontend:** Next.js, Tailwind CSS
- **Wallet/Auth:** Cavos Aegis SDK

## 📦 Getting Started

### Prerequisites

- Node.js (v18+)
- npm or yarn

### Installation

```bash
git clone https://github.com/your-repo/starkCiv.git
cd starkCiv
npm install
```

### Development

```bash
npm run dev
```

*Note: As this is a hackathon MVP, some features are currently under active development.*

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

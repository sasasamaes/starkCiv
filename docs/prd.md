# StarkCiv – Diplomacy Edition (PRD)

## 1. Overview
**StarkCiv – Diplomacy Edition** is an async, turn-based strategy game inspired by Civilization, built on **Starknet** with **Account Abstraction** via Cavos. Players compete through **diplomacy, treaties, reputation, and governance**, not constant warfare.

Designed as a **hackathon-ready MVP** with strong Web3 narrative and frictionless UX (social login + gasless gameplay).

---

## 2. Goals
### Product Goals
- Civilization-style **diplomatic victory**
- Showcase **Account Abstraction** on Starknet
- Fully playable demo in 48–72h

### Hackathon Goals
- Starknet-native state & async gameplay
- Clear Cavos integration
- Easy-to-understand demo for judges

---

## 3. Target Users
- Web3-curious users (no wallet needed)
- Hackathon judges & developers
- Strategy game players

---

## 4. Core Gameplay
### Players
- 4 players per match
- 1 Starknet Smart Account (via Cavos) = 1 Civilization

### Map
- Grid **5x5**
- Each player starts in a corner with 1 **City**

### Turn & Era System
- Async turn-based
- 1 action per player per turn
- 1 Era = 5 turns
- 1 global vote per Era

---

## 5. Resources
- **Food**
- **Wood**
- **Reputation** (diplomatic power)

---

## 6. Buildings (MVP)
- **City** – core building (lose it = elimination)
- **Farm** – +1 Food / turn
- **Market** – 2 Food → 1 Wood
- **Embassy** – enables treaties & increases vote power

---

## 7. Player Actions
- Expand (claim adjacent tile)
- Build (Farm / Market / Embassy)
- Train Guard (defensive, symbolic)
- Propose Treaty
- Send Aid (gain reputation)
- Vote (if proposal active)

---

## 8. Diplomacy System
### Treaties
- Non-Aggression Pact
- Trade Agreement
- Alliance

Breaking a treaty:
- −2 Reputation
- Resource penalty

### Global Proposals
- Sanction player
- Agricultural subsidy
- Open borders
- Global tax

Voting:
- Majority (3/4)
- Vote weight influenced by Reputation & Embassy

---

## 9. Victory Condition
**Diplomatic Victory**
- Reputation ≥ 10
- At least 1 Embassy
- 2 treaties completed successfully

---

## 10. Web3 & Cavos
- Social/email login
- Smart Accounts (AA)
- Gasless gameplay via Paymaster
- Session keys per Era

---

## 11. Out of Scope
- Real-time combat
- Large maps
- Token economy

---

## 12. Demo Pitch
> “A Civilization-style strategy game where diplomacy and trust live on-chain — powered by Starknet and made frictionless with Account Abstraction.”
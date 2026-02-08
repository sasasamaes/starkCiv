# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**StarkCiv – Diplomacy Edition** is an async, turn-based strategy game (Civilization-style diplomacy) for 4 players on Starknet. Players compete through diplomacy, treaties, reputation, and governance — not warfare. Built as a hackathon MVP (48–72h).

Key game mechanics: 5x5 grid map, 1 action per turn, Eras of 5 turns with global votes, diplomatic victory (Rep ≥ 10 + Embassy + 2 completed treaties).

## Tech Stack

- **Frontend:** Next.js (App Router), React + TypeScript
- **Auth/AA:** Cavos Aegis SDK (social/email login, gasless txs, session keys)
- **Blockchain:** Starknet Sepolia, Cairo 1.0, Starknet.js
- **Contract:** Single `StarkCivGame` Cairo contract

## Architecture

```
Next.js UI
  └── Cavos Aegis SDK (Account Abstraction)
        └── Starknet Smart Account (per player)
              └── StarkCivGame (Cairo contract on Sepolia)
```

## Smart Contract Design

Single Cairo contract with these core functions:
- **Lobby:** `join_game`, `start_game`
- **Gameplay:** `end_turn`, `expand`, `build`, `train_guard`, `send_aid`
- **Diplomacy:** `propose_treaty`, `accept_treaty`, `break_treaty`
- **Governance:** `create_proposal`, `vote`, `execute_proposal`

Key structs: `Player` (addr, food, wood, reputation, city_tile, embassy_built, treaties_completed, alive, last_action_turn), `Tile` (owner, building, guard), `Treaty`, `Proposal`.

Storage uses `Map<>` for players (by address), tiles (by u32 id), treaties, and proposals with nonce counters.

## Frontend Routes

- `/` — Landing + Cavos login (social/email, no wallet needed)
- `/lobby` — Matchmaking (4 players, public or code-based)
- `/game` — Main game screen (5x5 map + resource panel + actions)
- `/diplomacy` — Treaty management (incoming, active, history)

## Feature Specification Workflow

This project uses a structured spec workflow defined in `docs/FDSystem.md` (in Spanish). Specs live in `project-specs/{feature-name}/[requirements|design|tasks].md` using kebab-case. The workflow has 3 gated phases:
1. **Requirements** — EARS format with user stories and acceptance criteria
2. **Design** — Technical architecture with data models and test strategy
3. **Tasks** — Code-only implementation tasks (TDD, incremental, max 2 levels of hierarchy)

Each phase requires explicit user approval before proceeding. Always read all three spec documents before implementing any task.

## Key Constraints

- 4 players per match, 1 Smart Account = 1 civilization
- All transactions are gasless via Cavos Paymaster
- Session keys scoped per Era
- Anti-spam: 1 action per turn per address (enforced by `last_action_turn`)
- Breaking a treaty costs -2 Reputation + resource penalty
- Voting requires majority (3/4), weight influenced by Reputation and Embassy count

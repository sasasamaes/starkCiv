# StarkCiv – Tech Flow (End-to-End)

## 0) High-level Architecture
```
User (Browser)
  ↓
Next.js Frontend (React)
  ↓                ↘
Cavos Aegis SDK      (optional indexer/cache)
  ↓
Starknet Smart Account (AA)
  ↓
StarkCivGame Contract (Cairo)
  ↓
Starknet Sepolia
```

---

## 1) Boot & Config
- Frontend loads env vars:
  - NEXT_PUBLIC_GAME_CONTRACT_ADDRESS
  - NEXT_PUBLIC_CAVOS_APP_ID
  - NEXT_PUBLIC_NETWORK=SN_SEPOLIA
- Cavos AegisProvider initializes auth + tx pipeline.

---

## 2) Authentication & Account Abstraction (Cavos)
1. User clicks **Login**
2. Cavos handles social/email auth
3. Smart Account is created or restored
4. Frontend receives `playerAddress`

Result: user has a Starknet account without installing a wallet.

---

## 3) Join Game Flow
1. UI calls `join_game()` via `aegisAccount.execute()`
2. Contract:
   - checks available slots
   - registers player
   - emits `PlayerJoined`
3. When 4 players joined → `start_game()`
4. Game state initialized on-chain

---

## 4) State Read Flow
Frontend reads state using view functions:
- get_game_state
- get_player
- get_tile
- get_active_proposal
- list_treaties_for

UI re-renders after each tx confirmation.

---

## 5) Action Execution (Gasless)
1. Player selects action (expand/build/etc)
2. UI builds calldata
3. Cavos executes tx gasless
4. Contract validates rules and updates state
5. Event emitted (`ActionExecuted`)

---

## 6) Turn System
- Each player can execute **1 action per turn**
- Enforced with `last_action_turn`
- `end_turn()` advances the turn
- Every 5 turns → new Era

---

## 7) Diplomacy Flow (Treaties)
### Propose
- Player A → `propose_treaty(B, type, duration)`
- Treaty stored as pending

### Accept
- Player B → `accept_treaty(id)`
- Treaty becomes active

### Complete / Break
- On expiration → reputation reward
- On break → reputation penalty

---

## 8) Governance Flow (Voting)
1. At end of Era → proposal created
2. Players vote (`vote(proposal_id)`)
3. When voting ends → `execute_proposal`
4. Global effects applied (sanction, subsidy, tax)

---

## 9) Victory Check
After each turn/action:
- reputation >= 10
- embassy built
- treaties_completed >= 2

If true → emit `GameEnded(winner)`

---

## 10) Observability
Events emitted for:
- PlayerJoined
- GameStarted
- ActionExecuted
- Treaty lifecycle
- Proposal lifecycle
- GameEnded

Used by UI for event feed and sync.

---

## 11) Security (MVP)
- 1 account = 1 civilization
- 1 action per turn
- All tx are O(1)
- Gasless abuse prevented by AA + rules

# StarkCiv – Diplomacy Edition (Plan)

## 1. Scope
Hackathon MVP (48–72h) para un **Civilization diplomático async**:
- **4 jugadores**
- Mapa **5x5**
- **1 acción por turno**
- Victoria por **Reputación + Embajada + Tratados**
- **Cavos (AA)**: login social/email + gasless + session keys

---

## 2. Tech Stack
### Frontend
- Next.js (App Router)
- React + TypeScript
- Cavos Aegis SDK
- Starknet.js

### Blockchain
- Starknet **Sepolia**
- Cairo 1.0
- 1 contrato principal: `StarkCivGame`

---

## 3. Arquitectura
```
Next.js UI
  └── Cavos (AA)
        └── Starknet Smart Account (player)
              └── StarkCivGame (Cairo contract)
```

---

## 4. Smart Contract (Cairo) – Diseño MVP
### Storage
- game_started: bool
- max_players: u8
- player_count: u8
- current_turn: u32
- current_era: u32
- players: Map<ContractAddress, Player>
- tiles: Map<u32, Tile>
- treaties: Map<u32, Treaty>
- treaty_nonce: u32
- proposals: Map<u32, Proposal>
- proposal_nonce: u32

### Structs
**Player**
- addr
- food
- wood
- reputation
- city_tile
- embassy_built
- treaties_completed
- alive
- last_action_turn

**Tile**
- owner
- building
- guard

---

## 5. Reglas del Juego
- 1 Era = 5 turnos
- 1 acción por jugador por turno
- Votación global al final de cada Era

---

## 6. Funciones del Contrato
- join_game
- start_game
- end_turn
- expand
- build
- train_guard
- send_aid
- propose_treaty
- accept_treaty
- break_treaty
- create_proposal
- vote
- execute_proposal

---

## 7. Cavos (AA)
- Login social/email
- Smart Account por jugador
- Transacciones gasless
- Session keys por Era

---

## 8. Frontend
- / Landing + Login
- /lobby
- /game
- /diplomacy

---

## 9. Timeline
**Día 1:** Contratos base  
**Día 2:** Diplomacia + votaciones  
**Día 3:** Frontend + Cavos + Demo

---

## 10. Demo Checklist
- 4 jugadores logueados
- Acciones gasless
- Tratado firmado
- Votación ejecutada
- Victoria diplomática

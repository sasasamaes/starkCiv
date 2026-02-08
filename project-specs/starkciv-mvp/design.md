# Documento de Diseno — StarkCiv MVP

## Resumen General

El sistema se compone de tres capas: un frontend Next.js (App Router) que renderiza el juego y gestiona la interaccion del usuario, el SDK Cavos Aegis que abstrae la autenticacion y ejecucion de transacciones gasless, y un contrato Cairo unico (`StarkCivGame`) desplegado en Starknet Sepolia que contiene toda la logica del juego y estado on-chain.

El flujo principal es: el usuario interactua con la UI → el frontend construye calldata → Cavos firma y envia la transaccion gasless → el contrato valida reglas y actualiza estado → el frontend lee el nuevo estado via funciones view y re-renderiza.

No hay backend ni base de datos. Todo el estado del juego vive on-chain. El frontend es un cliente ligero que lee estado y construye transacciones.

---

## Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                   Browser (User)                     │
├─────────────────────────────────────────────────────┤
│                                                      │
│  Next.js App (App Router)                            │
│  ┌────────────┐ ┌──────────┐ ┌───────────────────┐  │
│  │ /          │ │ /lobby   │ │ /game             │  │
│  │ Landing    │ │ Matching │ │ Map + Actions     │  │
│  │ + Login    │ │          │ │ + Feed + Tutorial │  │
│  └────────────┘ └──────────┘ └───────────────────┘  │
│                               ┌───────────────────┐  │
│                               │ /diplomacy        │  │
│                               │ Treaties + Voting │  │
│                               └───────────────────┘  │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │  Capa de Servicios (hooks / utils)           │    │
│  │  ┌──────────────┐  ┌──────────────────────┐  │    │
│  │  │ useGameState │  │ useContractActions    │  │    │
│  │  │ (view reads) │  │ (tx builders)        │  │    │
│  │  └──────┬───────┘  └──────────┬───────────┘  │    │
│  │         │                     │               │    │
│  │  ┌──────▼─────────────────────▼───────────┐  │    │
│  │  │        Cavos Aegis SDK                 │  │    │
│  │  │  - Auth (social/email)                 │  │    │
│  │  │  - Smart Account management            │  │    │
│  │  │  - Gasless tx execution (Paymaster)    │  │    │
│  │  │  - Session keys per Era                │  │    │
│  │  └──────────────────┬─────────────────────┘  │    │
│  └─────────────────────┼────────────────────────┘    │
│                        │                              │
└────────────────────────┼──────────────────────────────┘
                         │ JSON-RPC
                         ▼
┌────────────────────────────────────────────────┐
│           Starknet Sepolia                      │
│  ┌──────────────────────────────────────────┐  │
│  │         StarkCivGame (Cairo)              │  │
│  │                                           │  │
│  │  Storage:                                 │  │
│  │  ├── game_started, current_turn,          │  │
│  │  │   current_era, player_count            │  │
│  │  ├── players: Map<Address, Player>        │  │
│  │  ├── tiles: Map<u32, Tile>                │  │
│  │  ├── treaties: Map<u32, Treaty>           │  │
│  │  └── proposals: Map<u32, Proposal>        │  │
│  │                                           │  │
│  │  Externals:                               │  │
│  │  ├── join_game, start_game, end_turn      │  │
│  │  ├── expand, build, train_guard, send_aid │  │
│  │  ├── propose_treaty, accept_treaty,       │  │
│  │  │   break_treaty                         │  │
│  │  └── create_proposal, vote,               │  │
│  │      execute_proposal                     │  │
│  │                                           │  │
│  │  Views:                                   │  │
│  │  ├── get_game_state, get_player, get_tile │  │
│  │  ├── get_active_proposal                  │  │
│  │  └── list_treaties_for                    │  │
│  │                                           │  │
│  │  Events:                                  │  │
│  │  ├── PlayerJoined, GameStarted            │  │
│  │  ├── ActionExecuted                       │  │
│  │  ├── TreatyProposed, TreatyAccepted,      │  │
│  │  │   TreatyBroken, TreatyCompleted        │  │
│  │  ├── ProposalCreated, VoteCast,           │  │
│  │  │   ProposalExecuted                     │  │
│  │  └── GameEnded                            │  │
│  └──────────────────────────────────────────┘  │
└────────────────────────────────────────────────┘
```

---

## Componentes e Interfaces

### A. Contrato Cairo — `StarkCivGame`

#### A.1 Interfaz Externa (trait)

```cairo
#[starknet::interface]
trait IStarkCivGame<TContractState> {
    // Lobby
    fn join_game(ref self: TContractState);
    fn start_game(ref self: TContractState);

    // Turn
    fn end_turn(ref self: TContractState);

    // Actions
    fn expand(ref self: TContractState, tile_id: u32);
    fn build(ref self: TContractState, tile_id: u32, building_type: u8);
    fn train_guard(ref self: TContractState, tile_id: u32);
    fn send_aid(ref self: TContractState, to: ContractAddress, resource: u8, amount: u32);

    // Diplomacy
    fn propose_treaty(ref self: TContractState, to: ContractAddress, treaty_type: u8, duration: u32);
    fn accept_treaty(ref self: TContractState, treaty_id: u32);
    fn break_treaty(ref self: TContractState, treaty_id: u32);

    // Governance
    fn create_proposal(ref self: TContractState, kind: u8, target: ContractAddress);
    fn vote(ref self: TContractState, proposal_id: u32, support: bool);
    fn execute_proposal(ref self: TContractState, proposal_id: u32);

    // Views
    fn get_game_state(self: @TContractState) -> GameState;
    fn get_player(self: @TContractState, addr: ContractAddress) -> Player;
    fn get_tile(self: @TContractState, tile_id: u32) -> Tile;
    fn get_active_proposal(self: @TContractState) -> Proposal;
    fn list_treaties_for(self: @TContractState, addr: ContractAddress) -> Array<Treaty>;
}
```

#### A.2 Constantes del Juego

```
MAX_PLAYERS = 4
MAP_SIZE = 5  (grid 5x5, tiles 0-24)
TURNS_PER_ERA = 5
VICTORY_REP = 10
VICTORY_TREATIES = 2
TREATY_BREAK_REP_PENALTY = 2
```

#### A.3 Spawn Positions (esquinas del grid 5x5)

```
Player 0 → tile 0  (0,0)
Player 1 → tile 4  (4,0)
Player 2 → tile 20 (0,4)
Player 3 → tile 24 (4,4)
```

Tile ID = y * 5 + x

#### A.4 Logica de Validacion por Funcion

| Funcion | Validaciones |
|---------|-------------|
| `join_game` | game not started, player_count < 4, caller not already joined |
| `start_game` | player_count == 4, game not started |
| `end_turn` | game started, caller is valid player (o cualquier caller en MVP) |
| `expand` | game started, caller is alive, last_action_turn < current_turn, tile adjacent to owned tile, tile has no owner |
| `build` | game started, caller is alive, last_action_turn < current_turn, tile owned by caller, tile has no building |
| `train_guard` | game started, caller is alive, last_action_turn < current_turn, tile owned by caller, tile has no guard |
| `send_aid` | game started, caller is alive, last_action_turn < current_turn, sufficient resources, target is valid player |
| `propose_treaty` | game started, caller is alive, last_action_turn < current_turn, caller has embassy, target is valid player |
| `accept_treaty` | treaty exists, treaty is pending, caller is treaty target |
| `break_treaty` | treaty exists, treaty is active, caller is party to treaty |
| `create_proposal` | game started, current_turn is start of new Era |
| `vote` | proposal is active, caller hasn't voted, caller is valid player |
| `execute_proposal` | all voted or limit reached, proposal is active |

#### A.5 Logica de Recursos por Turno (en `end_turn`)

```
Para cada jugador alive:
  - Por cada tile con Farm: player.food += 1
```

Nota: Market no genera automaticamente. Es una accion manual (post-MVP) o simplemente habilita el ratio de conversion. En MVP, Market otorga +1 Wood por turno como simplificacion.

#### A.6 Logica de Victoria (check despues de cada accion)

```
fn check_victory(player: Player) -> bool {
    player.reputation >= VICTORY_REP
    && player.embassy_built
    && player.treaties_completed >= VICTORY_TREATIES
}
```

*Refs: Req 4, 5, 6, 7, 8, 9, 10, 11*

---

### B. Frontend — Componentes React

#### B.1 Estructura de Directorios

```
src/
├── app/
│   ├── layout.tsx          # Root layout con AegisProvider
│   ├── page.tsx            # Landing + Login (Req 1)
│   ├── lobby/
│   │   └── page.tsx        # Lobby matchmaking (Req 2)
│   ├── game/
│   │   └── page.tsx        # Game screen principal (Req 3-8, 11, 13, 14)
│   └── diplomacy/
│       └── page.tsx        # Treaty management (Req 9, 10)
├── components/
│   ├── map/
│   │   ├── GameMap.tsx     # Grid 5x5 renderer
│   │   └── Tile.tsx        # Tile individual (owner, building, guard)
│   ├── panels/
│   │   ├── ResourcePanel.tsx   # Food, Wood, Rep, Turn, Era
│   │   ├── ActionPanel.tsx     # Acciones disponibles
│   │   └── EventFeed.tsx       # World Events feed (Req 13)
│   ├── diplomacy/
│   │   ├── TreatyModal.tsx     # Propose treaty form
│   │   ├── TreatyList.tsx      # Incoming/Active/History tabs
│   │   └── VotingModal.tsx     # Proposal voting UI (Req 10)
│   ├── lobby/
│   │   └── LobbySlots.tsx      # Player slots 1/4 - 4/4
│   ├── overlays/
│   │   ├── TutorialOverlay.tsx # One-minute tutorial (Req 14)
│   │   └── VictoryModal.tsx    # Win screen (Req 11)
│   └── ui/
│       ├── Toast.tsx           # Action submitted feedback
│       └── ConfirmDialog.tsx   # Confirm expand/build/etc
├── hooks/
│   ├── useGameState.ts     # Polling de estado on-chain
│   ├── useContractActions.ts   # Builders de calldata + execute
│   ├── usePlayer.ts       # Estado del jugador actual
│   └── useTreaties.ts     # Tratados del jugador
├── lib/
│   ├── constants.ts        # Contract address, enums, config
│   ├── types.ts            # TypeScript types mirroring Cairo structs
│   ├── contract.ts         # ABI + Contract instance
│   └── grid.ts             # Utilidades de grid (adjacency, tile_id <-> coords)
└── providers/
    └── CavosProvider.tsx   # Wrapper de AegisProvider con config
```

#### B.2 Componentes Clave

**GameMap** *(Req 3)*
- Props: `tiles: Tile[], currentPlayer: Address, onTileClick: (tileId) => void`
- Renderiza grid 5x5 usando CSS Grid
- Cada Tile muestra color de owner, icono de building, indicador de guard
- Tiles clickeables para acciones (expand/build/train)

**ActionPanel** *(Req 5-8)*
- Props: `player: Player, selectedTile: Tile | null, isMyTurn: boolean, onAction: (action) => void`
- Muestra acciones contextuales segun tile seleccionado y estado del jugador
- Deshabilitado si `isMyTurn === false` (cooldown)

**VotingModal** *(Req 10)*
- Props: `proposal: Proposal, onVote: (support: boolean) => void`
- Aparece como modal al final de cada Era
- Muestra descripcion de la propuesta y botones Vote For / Vote Against

**VictoryModal** *(Req 11)*
- Props: `winner: Player, gameStats: GameStats`
- Modal de pantalla completa con resumen de victoria
- Botones: Play Again, View On-chain History

#### B.3 Hooks Principales

**useGameState** *(Req 3, 4)*
```typescript
// Polling cada N segundos del estado on-chain
function useGameState(contractAddress: string) {
  // Llama get_game_state, get_player (x4), get_tile (x25)
  // Retorna: { gameState, players, tiles, isLoading, refetch }
  // Refetch automatico tras cada tx confirmada
}
```

**useContractActions** *(Req 5-10)*
```typescript
// Construye calldata y ejecuta via Cavos
function useContractActions(aegisAccount: AegisAccount) {
  // Retorna funciones: expand, build, trainGuard, sendAid,
  //   proposeTreaty, acceptTreaty, breakTreaty,
  //   createProposal, vote, executeProposal
  // Cada funcion: construye calldata → aegisAccount.execute() → refetch state
}
```

*Refs: Req 1-14*

---

### C. Integracion Cavos

#### C.1 Configuracion

```typescript
// providers/CavosProvider.tsx
<AegisProvider
  appId={process.env.NEXT_PUBLIC_CAVOS_APP_ID}
  network="SN_SEPOLIA"
>
  {children}
</AegisProvider>
```

#### C.2 Flujo de Login

1. Usuario clickea "Play" → `aegis.login({ method: 'social' | 'email' })`
2. Cavos maneja OAuth/email verification
3. Retorna `AegisAccount` con `address` y metodos `execute()`
4. Frontend almacena `playerAddress` en contexto React

#### C.3 Ejecucion de Transacciones

```typescript
// Todas las tx siguen este patron:
const result = await aegisAccount.execute({
  contractAddress: GAME_CONTRACT,
  entrypoint: 'expand',
  calldata: [tileId],
});
// Cavos maneja gas via Paymaster
// Session keys reducen prompts de firma
```

*Refs: Req 1, 12*

---

## Modelos de Datos

### Cairo Structs

```cairo
#[derive(Drop, Serde, starknet::Store)]
struct Player {
    addr: ContractAddress,
    food: u32,
    wood: u32,
    reputation: i32,    // puede ser negativo por penalizaciones
    city_tile: u32,
    embassy_built: bool,
    treaties_completed: u32,
    alive: bool,
    last_action_turn: u32,
}

#[derive(Drop, Serde, starknet::Store)]
struct Tile {
    owner: ContractAddress,     // 0x0 = sin owner
    building: u8,               // 0=None, 1=City, 2=Farm, 3=Market, 4=Embassy
    guard: bool,
}

#[derive(Drop, Serde, starknet::Store)]
struct Treaty {
    id: u32,
    from: ContractAddress,
    to: ContractAddress,
    treaty_type: u8,            // 0=NonAggression, 1=TradeAgreement, 2=Alliance
    status: u8,                 // 0=Pending, 1=Active, 2=Completed, 3=Broken
    start_turn: u32,
    end_turn: u32,
}

#[derive(Drop, Serde, starknet::Store)]
struct Proposal {
    id: u32,
    kind: u8,                   // 0=Sanction, 1=Subsidy, 2=OpenBorders, 3=GlobalTax
    target: ContractAddress,    // jugador objetivo (para Sanction)
    votes_for: u32,
    votes_against: u32,
    executed: bool,
    era: u32,
}

#[derive(Drop, Serde)]
struct GameState {
    game_started: bool,
    player_count: u8,
    current_turn: u32,
    current_era: u32,
    winner: ContractAddress,    // 0x0 = no winner yet
}
```

### TypeScript Types (mirror)

```typescript
interface Player {
  addr: string;
  food: number;
  wood: number;
  reputation: number;
  cityTile: number;
  embassyBuilt: boolean;
  treatiesCompleted: number;
  alive: boolean;
  lastActionTurn: number;
}

interface Tile {
  owner: string;
  building: BuildingType;
  guard: boolean;
}

enum BuildingType { None, City, Farm, Market, Embassy }
enum TreatyType { NonAggression, TradeAgreement, Alliance }
enum TreatyStatus { Pending, Active, Completed, Broken }
enum ProposalKind { Sanction, Subsidy, OpenBorders, GlobalTax }

interface Treaty {
  id: number;
  from: string;
  to: string;
  treatyType: TreatyType;
  status: TreatyStatus;
  startTurn: number;
  endTurn: number;
}

interface Proposal {
  id: number;
  kind: ProposalKind;
  target: string;
  votesFor: number;
  votesAgainst: number;
  executed: boolean;
  era: number;
}

interface GameState {
  gameStarted: boolean;
  playerCount: number;
  currentTurn: number;
  currentEra: number;
  winner: string;
}
```

### Relaciones entre Entidades

```
GameState (1) ─── contains ──→ (4) Player
GameState (1) ─── contains ──→ (25) Tile
Player    (1) ─── owns ──────→ (N) Tile
Player    (1) ─── party to ──→ (N) Treaty
Player    (1) ─── votes on ──→ (N) Proposal
Treaty    (1) ─── between ───→ (2) Player
Proposal  (1) ─── targets ───→ (0..1) Player
```

*Refs: Req 3, 4, 9, 10, 11*

---

## Manejo de Errores

### Contrato (Cairo)

| Escenario | Funcion | Respuesta |
|-----------|---------|-----------|
| Juego no iniciado | Todas las acciones | `assert(game_started, 'Game not started')` |
| Jugador no registrado | Todas las acciones | `assert(player.alive, 'Not a valid player')` |
| Ya actuo este turno | expand, build, train_guard, send_aid, propose_treaty | `assert(player.last_action_turn < current_turn, 'Already acted')` |
| Tile no adyacente | expand | `assert(is_adjacent(tile_id, caller_tiles), 'Not adjacent')` |
| Tile ocupado | expand | `assert(tile.owner == 0x0, 'Tile occupied')` |
| Tile no es propio | build, train_guard | `assert(tile.owner == caller, 'Not your tile')` |
| Tile ya tiene edificio | build | `assert(tile.building == 0, 'Already built')` |
| Recursos insuficientes | send_aid | `assert(player.food >= amount, 'Insufficient resources')` |
| Sin embajada | propose_treaty | `assert(player.embassy_built, 'No embassy')` |
| Ya voto | vote | `assert(!has_voted(caller, proposal_id), 'Already voted')` |
| Juego terminado | Todas las acciones | `assert(winner == 0x0, 'Game ended')` |
| Lobby lleno | join_game | `assert(player_count < MAX_PLAYERS, 'Lobby full')` |

### Frontend

| Escenario | Componente | Respuesta |
|-----------|-----------|-----------|
| Tx rechazada por contrato | useContractActions | Toast con mensaje de error parseado del revert reason |
| Conexion Cavos perdida | CavosProvider | Mostrar banner "Reconnecting..." e intentar reconexion |
| Estado desactualizado | useGameState | Polling periodico (cada 5s) + refetch tras cada tx |
| Jugador sin sesion | Layout | Redirect a `/` para re-login |

### Funcion de Adyacencia (critica para expand)

```
fn is_adjacent(tile_a: u32, tile_b: u32) -> bool {
    let (ax, ay) = (tile_a % 5, tile_a / 5);
    let (bx, by) = (tile_b % 5, tile_b / 5);
    let dx = if ax > bx { ax - bx } else { bx - ax };
    let dy = if ay > by { ay - by } else { by - ay };
    (dx + dy) == 1  // solo ortogonal, no diagonal
}
```

*Refs: Req 4, 5, 6, 7, 8, 9, 10, 15*

---

## Estrategia de Pruebas

### Contrato Cairo (pruebas unitarias con `snforge`)

**Cobertura objetivo: todas las funciones externas y validaciones.**

| Suite | Alcance | Casos |
|-------|---------|-------|
| `test_lobby` | join_game, start_game | Join 4 players, reject 5th, reject double join, start game |
| `test_turns` | end_turn, era progression | Turn increment, era increment cada 5 turnos, resource generation |
| `test_expand` | expand | Expand adjacent, reject non-adjacent, reject occupied, reject already acted |
| `test_build` | build | Build each type, reject on occupied tile, reject on enemy tile, reject already built |
| `test_guard` | train_guard | Train guard, reject duplicate, reject enemy tile |
| `test_aid` | send_aid | Send food/wood, reject insufficient, verify rep gain |
| `test_treaties` | propose/accept/break_treaty | Full lifecycle, reject without embassy, break penalty |
| `test_governance` | create/vote/execute_proposal | Full voting cycle, majority check, reject double vote, each proposal effect |
| `test_victory` | check_victory | Win condition met, not met (partial), game ends after victory |
| `test_edge_cases` | Varios | Unregistered player, action after game end, skip turn |

**Utilidades de test:**
- `setup_game()`: crea un juego con 4 jugadores ya iniciado
- `advance_turns(n)`: avanza N turnos
- `setup_with_embassy(player)`: configura un jugador con embajada para tests de diplomacia

### Frontend (pruebas con Vitest + React Testing Library)

| Suite | Alcance |
|-------|---------|
| `grid.test.ts` | Utilidades: tile_id ↔ coords, adjacency check |
| `GameMap.test.tsx` | Renderizado correcto del grid, click events |
| `ActionPanel.test.tsx` | Acciones habilitadas/deshabilitadas segun estado |
| `useGameState.test.ts` | Mock de contract calls, refetch |
| `useContractActions.test.ts` | Calldata correcto para cada accion |

### Pruebas de Integracion

- **Flujo completo de partida:** join → expand → build → treaty → vote → victory
- Ejecutado en Starknet devnet local con `katana`

*Refs: Req 1-15*

---

## Decisiones de Diseno y Justificacion

| Decision | Justificacion | Reqs |
|----------|---------------|------|
| Contrato unico vs multiples | MVP hackathon: simplicidad sobre modularidad. Un contrato reduce deploys y complejidad de interaccion. | Todos |
| Polling vs WebSocket para state | Polling cada 5s es suficiente para juego async. Evita complejidad de infra WebSocket. | 3, 13 |
| Reputation como i32 | Puede ser negativo por penalizaciones de romper tratados. | 8, 9 |
| Adjacency solo ortogonal | Simplifica validacion y estrategia. 4 direcciones vs 8. | 5 |
| Market como +1 Wood/turno | Simplificacion MVP. La mecanica original (2 Food → 1 Wood manual) requiere una accion adicional. En MVP, Market genera pasivamente. | 6 |
| Session keys por Era | Alinea la renovacion de permisos con el ciclo de juego. Cada Era = nuevo scope de sesion. | 12 |
| No backend/indexer | MVP: el frontend lee directamente del contrato. Suficiente para 4 jugadores y 25 tiles. | 3 |
| has_voted como Map<(proposal_id, address), bool> | Previene doble voto de forma simple y gas-eficiente. | 10 |
| end_turn callable por cualquiera | En MVP, cualquier jugador o un mecanismo externo puede avanzar el turno. Evita bloqueos por inactividad. | 4, 15 |

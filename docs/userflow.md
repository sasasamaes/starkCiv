# StarkCiv – Diplomacy Edition (User Flow)

## 0) Contexto
Juego async tipo Civilization (diplomacia) para 4 jugadores en Starknet.
Onboarding y gameplay sin fricción usando **Cavos (AA)**: social/email login + gasless + session keys.

---

## 1) Landing → Login (Cavos)
**Pantalla:** `/`
1. Usuario abre el link del juego.
2. CTA: **“Play (No wallet needed)”**
3. Cavos:
   - Login con Email / Google / Social
   - Se crea/recupera **Smart Account**
4. UI muestra:
   - `Connected as: 0x...`
   - Botón: **“Enter Lobby”**

**Success:** Usuario autenticado y tiene address AA.

---

## 2) Lobby (Matchmaking 4P)
**Pantalla:** `/lobby`
1. Usuario elige:
   - **Join Public Match** (default) o
   - **Join with Code** (opcional, para demo)
2. Acción: `join_game()`
3. Lobby muestra:
   - Slots: `1/4, 2/4, 3/4, 4/4`
   - Lista de addresses (abreviado)
4. Cuando llega a 4/4:
   - Se ejecuta `start_game()` automáticamente (o por host)
   - Se asignan spawns (esquinas)
   - Navega a `/game`

**Success:** Match creado e iniciado con 4 jugadores.

---

## 3) Tutorial “One-Minute” (Overlay)
**Pantalla:** `/game` (overlay)
- “1 acción por turno”
- “Ganas por reputación + tratados + embajada”
- “Votas al final de cada Era”
- Botón: **“Got it”**

**Success:** Usuario entiende el loop en <60s.

---

## 4) Game Screen (Mapa + Estado)
**Pantalla:** `/game`
Layout:
- **Mapa 5x5**
- Panel lateral:
  - Recursos (Food, Wood)
  - Reputación (Rep)
  - Turn / Era
  - Cooldown (si ya hizo acción este turno)

---

## 5) Turn Flow (1 Acción por Turno)
**Pantalla:** `/game`
### Paso A — Inicio de turno
1. UI detecta `current_turn` y si el usuario ya actuó (`last_action_turn`).
2. Si NO actuó:
   - Se habilita el panel **Actions**

### Paso B — Elegir acción (solo 1)
Acciones MVP:
1) **Expand**
- Usuario toca tile adyacente
- Confirm: “Claim tile?”
- Tx: `expand(tile_id)`

2) **Build**
- Usuario toca tile propio
- Selecciona: Farm / Market / Embassy
- Tx: `build(tile_id, building_type)`

3) **Train Guard**
- Usuario toca tile propio
- Tx: `train_guard(tile_id)` (solo marcador/defensa simbólica)

4) **Propose Treaty**
- Abre modal diplomacia
- Selecciona jugador + tipo + duración
- Tx: `propose_treaty(to, type, duration)`

5) **Send Aid**
- Selecciona jugador + recurso + cantidad
- Tx: `send_aid(to, resource, amount)`
- Resultado: +Rep para quien envía (según regla)

### Paso C — Confirmación (Cavos)
- Cavos ejecuta gasless.
- (Opcional) Session key activa → menos prompts.
- UI muestra toast: “Action submitted ✅”

**Success:** Acción registrada on-chain. Usuario queda “Done for this turn”.

---

## 6) Diplomacy Screen (Tratados)
**Pantalla:** `/diplomacy`
Tabs:
- **Incoming Treaties**
- **Active Treaties**
- **History**

### Incoming Treaties
1. Usuario ve propuestas recibidas.
2. Puede:
   - **Accept** → `accept_treaty(treaty_id)`
   - **Reject** → (opcional MVP: simplemente expira)
3. Al aceptar:
   - Se crea treaty activo con start/end turn.

### Breaking a Treaty (opcional MVP)
- Botón “Break”
- Tx: `break_treaty(treaty_id)`
- Aplica penalty: −Rep + resource fee

**Success:** Tratados firmados y visibles para todos.

---

## 7) Era Council (Votación Global)
**Trigger:** fin de Era (cada 5 turnos)
**Pantalla:** modal en `/game` o `/diplomacy`
1. Se crea una `proposal`:
   - `create_proposal(kind, target)`
2. UI muestra:
   - Descripción clara
   - Botones: **Vote For / Vote Against**
3. Usuario vota:
   - Tx: `vote(proposal_id, support)`
4. Cuando votan 4 (o pasa límite):
   - Se ejecuta `execute_proposal(proposal_id)`
5. UI muestra resultado:
   - “Passed / Rejected”
   - Efecto aplicado (subsidy, sanction, etc.)

**Success:** Gobernanza sucede on-chain y afecta el siguiente turno.

---

## 8) Progression & Feedback
**Pantalla:** `/game`
Después de cada turno/era:
- UI actualiza recursos
- UI actualiza Rep
- Feed corto “World Events”:
  - “Player A sent aid to Player B (+1 Rep)”
  - “Sanction passed: Player C cannot Expand next turn”

**Success:** El mundo se siente vivo y político.

---

## 9) Win Condition (Diplomatic Victory)
**Trigger:** después de cada acción / fin de turno
Si jugador cumple:
- Rep ≥ 10
- Tiene Embassy
- 2 tratados completados

→ `declare_winner(player)` (o check on read)

**Pantalla:** `/game` winner modal
- “Diplomatic Victory 🏛️”
- Resumen:
  - Rep final
  - Tratados completados
  - Proposals clave
- Botones:
  - “Play Again”
  - “View On-chain History” (link explorer opcional)

**Success:** Fin del match + cierre épico para demo.

---

## 10) Demo Script (2 minutos)
1) Login (Cavos) sin wallet
2) Entrar lobby 4/4
3) Expand + Build Farm (gasless)
4) Proponer tratado y aceptar
5) Votar proposal de Era
6) Mostrar reputación subiendo y condición de victoria

---

## 11) Edge Cases (MVP)
- Si un jugador no actúa: el turno puede avanzar igual (host/end_turn) o “skip”.
- Si alguien abandona: sigue alive pero no actúa; se puede auto-skip tras N turnos (post-MVP).
- Anti-spam: 1 acción por turn por address (last_action_turn).
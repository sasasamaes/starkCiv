# Documento de Requisitos — StarkCiv MVP

## Introduccion

StarkCiv – Diplomacy Edition es un juego de estrategia async por turnos para 4 jugadores en Starknet. Los jugadores compiten a traves de diplomacia, tratados, reputacion y gobernanza en un mapa 5x5. El objetivo es lograr una victoria diplomatica acumulando reputacion, construyendo una embajada y completando tratados.

El MVP esta disenado para un hackathon de 48-72h. Usa Account Abstraction via Cavos (login social/email, transacciones gasless, session keys) para eliminar la friccion Web3. La arquitectura consiste en un frontend Next.js, el SDK Cavos Aegis para AA, y un contrato Cairo unico (`StarkCivGame`) desplegado en Starknet Sepolia.

El alcance se limita a: lobby de 4 jugadores, mapa 5x5 estatico, sistema de turnos con Eras, 6 acciones por turno, sistema de tratados, votacion global por Era, y condicion de victoria diplomatica.

---

## Requisitos

### Requisito 1: Autenticacion y Account Abstraction

**Historia de Usuario:** Como jugador, quiero iniciar sesion con email o red social sin necesidad de wallet, para poder jugar inmediatamente sin friccion Web3.

#### Criterios de Aceptacion

1. CUANDO el usuario abre la aplicacion ENTONCES EL sistema DEBERA mostrar una landing page con un CTA "Play (No wallet needed)".
2. CUANDO el usuario hace clic en el CTA ENTONCES EL sistema DEBERA iniciar el flujo de autenticacion de Cavos (email/Google/social).
3. CUANDO Cavos completa la autenticacion ENTONCES EL sistema DEBERA crear o recuperar un Smart Account (AA) para el usuario.
4. CUANDO el Smart Account esta listo ENTONCES EL sistema DEBERA mostrar la direccion abreviada del jugador (`0x...`) y un boton "Enter Lobby".
5. MIENTRAS el usuario tenga una sesion activa EL sistema DEBERA mantener la conexion con el Smart Account sin requerir re-autenticacion.

---

### Requisito 2: Lobby y Matchmaking

**Historia de Usuario:** Como jugador, quiero unirme a una partida publica o privada con otros 3 jugadores, para poder iniciar un match rapidamente.

#### Criterios de Aceptacion

1. CUANDO el usuario entra al lobby ENTONCES EL sistema DEBERA mostrar opciones "Join Public Match" y "Join with Code".
2. CUANDO el usuario elige unirse ENTONCES EL sistema DEBERA ejecutar `join_game()` via el Smart Account.
3. CUANDO un jugador se une ENTONCES EL contrato DEBERA registrar al jugador, verificar que hay slots disponibles y emitir el evento `PlayerJoined`.
4. MIENTRAS el lobby no este lleno EL sistema DEBERA mostrar los slots ocupados (`1/4`, `2/4`, `3/4`, `4/4`) con las direcciones abreviadas.
5. CUANDO el lobby alcanza 4/4 jugadores ENTONCES EL sistema DEBERA ejecutar `start_game()`, asignar spawns en las 4 esquinas del mapa 5x5 e inicializar el estado del juego on-chain.
6. CUANDO el juego inicia ENTONCES EL sistema DEBERA navegar a todos los jugadores a `/game` y emitir el evento `GameStarted`.

---

### Requisito 3: Mapa y Estado del Juego

**Historia de Usuario:** Como jugador, quiero ver el mapa 5x5 con mis territorios, edificios y recursos, para poder tomar decisiones estrategicas informadas.

#### Criterios de Aceptacion

1. CUANDO el juego inicia ENTONCES EL sistema DEBERA renderizar un mapa grid 5x5 (25 tiles) con cada jugador posicionado en una esquina con 1 City.
2. MIENTRAS el juego este activo EL sistema DEBERA mostrar un panel lateral con: Food, Wood, Reputation, turno actual, Era actual, y estado de cooldown (si ya actuo este turno).
3. CUANDO el usuario consulta el estado ENTONCES EL frontend DEBERA leer el estado on-chain via las funciones view: `get_game_state`, `get_player`, `get_tile`.
4. CUANDO una transaccion es confirmada ENTONCES EL frontend DEBERA re-renderizar el mapa y panel con el estado actualizado.
5. CADA tile DEBERA mostrar visualmente: owner (color por jugador), tipo de edificio (Farm/Market/Embassy/City), y presencia de guardia.

---

### Requisito 4: Sistema de Turnos y Eras

**Historia de Usuario:** Como jugador, quiero un sistema de turnos async donde cada jugador tiene 1 accion por turno, para que el juego progrese de forma ordenada.

#### Criterios de Aceptacion

1. MIENTRAS sea el turno activo del jugador y no haya actuado (`last_action_turn < current_turn`) EL sistema DEBERA habilitar el panel de acciones.
2. CUANDO el jugador ejecuta una accion ENTONCES EL contrato DEBERA actualizar `last_action_turn` al turno actual, impidiendo mas acciones ese turno.
3. SI un jugador intenta ejecutar una segunda accion en el mismo turno ENTONCES EL contrato DEBERA rechazar la transaccion.
4. CUANDO se ejecuta `end_turn()` ENTONCES EL contrato DEBERA incrementar `current_turn` y aplicar generacion de recursos (Farm: +1 Food/turno).
5. CUANDO `current_turn` es multiplo de 5 ENTONCES EL contrato DEBERA incrementar `current_era` y activar la fase de votacion global.
6. MIENTRAS el jugador ya haya actuado este turno EL sistema DEBERA mostrar un indicador de cooldown y deshabilitar el panel de acciones.

---

### Requisito 5: Accion — Expand

**Historia de Usuario:** Como jugador, quiero expandir mi territorio reclamando tiles adyacentes, para controlar mas area del mapa.

#### Criterios de Aceptacion

1. CUANDO el jugador selecciona un tile adyacente a su territorio ENTONCES EL sistema DEBERA mostrar un dialogo de confirmacion "Claim tile?".
2. CUANDO el jugador confirma ENTONCES EL sistema DEBERA ejecutar `expand(tile_id)` via Cavos (gasless).
3. SI el tile no es adyacente al territorio del jugador ENTONCES EL contrato DEBERA rechazar la transaccion.
4. SI el tile ya tiene owner ENTONCES EL contrato DEBERA rechazar la transaccion.
5. CUANDO el expand es exitoso ENTONCES EL contrato DEBERA asignar el tile al jugador y emitir `ActionExecuted`.

---

### Requisito 6: Accion — Build

**Historia de Usuario:** Como jugador, quiero construir edificios en mis tiles, para generar recursos y habilitar diplomacia.

#### Criterios de Aceptacion

1. CUANDO el jugador selecciona un tile propio ENTONCES EL sistema DEBERA mostrar las opciones de construccion: Farm, Market, Embassy.
2. CUANDO el jugador selecciona Farm y confirma ENTONCES EL contrato DEBERA ejecutar `build(tile_id, Farm)` y el tile generara +1 Food por turno.
3. CUANDO el jugador selecciona Market y confirma ENTONCES EL contrato DEBERA ejecutar `build(tile_id, Market)`, habilitando la conversion 2 Food → 1 Wood.
4. CUANDO el jugador selecciona Embassy y confirma ENTONCES EL contrato DEBERA ejecutar `build(tile_id, Embassy)`, habilitando tratados e incrementando el peso de voto.
5. SI el tile ya tiene un edificio ENTONCES EL contrato DEBERA rechazar la construccion.
6. SI el tile no pertenece al jugador ENTONCES EL contrato DEBERA rechazar la transaccion.
7. CUANDO el build es exitoso ENTONCES EL contrato DEBERA emitir `ActionExecuted`.

---

### Requisito 7: Accion — Train Guard

**Historia de Usuario:** Como jugador, quiero entrenar una guardia en mi tile, como unidad defensiva simbolica.

#### Criterios de Aceptacion

1. CUANDO el jugador selecciona un tile propio ENTONCES EL sistema DEBERA ofrecer la opcion "Train Guard".
2. CUANDO el jugador confirma ENTONCES EL contrato DEBERA ejecutar `train_guard(tile_id)` y marcar el tile con `guard = true`.
3. SI el tile ya tiene guardia ENTONCES EL contrato DEBERA rechazar la transaccion.
4. SI el tile no pertenece al jugador ENTONCES EL contrato DEBERA rechazar la transaccion.
5. CUANDO el train es exitoso ENTONCES EL contrato DEBERA emitir `ActionExecuted`.

---

### Requisito 8: Accion — Send Aid

**Historia de Usuario:** Como jugador, quiero enviar recursos a otro jugador, para ganar reputacion diplomatica.

#### Criterios de Aceptacion

1. CUANDO el jugador selecciona "Send Aid" ENTONCES EL sistema DEBERA mostrar un formulario con: jugador destino, tipo de recurso (Food/Wood), cantidad.
2. CUANDO el jugador confirma ENTONCES EL contrato DEBERA ejecutar `send_aid(to, resource, amount)`.
3. SI el jugador no tiene suficientes recursos ENTONCES EL contrato DEBERA rechazar la transaccion.
4. CUANDO el aid es exitoso ENTONCES EL contrato DEBERA transferir los recursos y otorgar +Rep al jugador que envia (segun regla definida).
5. CUANDO el aid es exitoso ENTONCES EL contrato DEBERA emitir `ActionExecuted`.

---

### Requisito 9: Sistema de Tratados

**Historia de Usuario:** Como jugador, quiero proponer, aceptar y gestionar tratados con otros jugadores, para construir alianzas diplomaticas.

#### Criterios de Aceptacion

1. CUANDO el jugador selecciona "Propose Treaty" ENTONCES EL sistema DEBERA mostrar un modal con: jugador destino, tipo de tratado (Non-Aggression Pact / Trade Agreement / Alliance) y duracion.
2. CUANDO el jugador confirma ENTONCES EL contrato DEBERA ejecutar `propose_treaty(to, type, duration)` y almacenar el tratado como pendiente.
3. CUANDO el jugador destino ve la propuesta en `/diplomacy` → "Incoming Treaties" ENTONCES EL sistema DEBERA permitir Accept o dejar expirar.
4. CUANDO el jugador destino acepta ENTONCES EL contrato DEBERA ejecutar `accept_treaty(treaty_id)` y el tratado se activa con start/end turn.
5. CUANDO un tratado activo expira naturalmente ENTONCES EL contrato DEBERA otorgar reputacion a ambas partes e incrementar `treaties_completed`.
6. CUANDO un jugador rompe un tratado activo ENTONCES EL contrato DEBERA ejecutar `break_treaty(treaty_id)`, aplicar -2 Reputation y una penalizacion de recursos.
7. MIENTRAS haya tratados activos EL sistema DEBERA mostrarlos en `/diplomacy` → "Active Treaties".
8. SI el jugador no tiene Embassy ENTONCES EL contrato DEBERA rechazar la propuesta de tratado.

---

### Requisito 10: Gobernanza — Votacion Global

**Historia de Usuario:** Como jugador, quiero participar en votaciones globales al final de cada Era, para influir en las reglas del juego mediante gobernanza on-chain.

#### Criterios de Aceptacion

1. CUANDO una Era termina (cada 5 turnos) ENTONCES EL sistema DEBERA habilitar la creacion de propuestas globales via `create_proposal(kind, target)`.
2. CUANDO existe una propuesta activa ENTONCES EL sistema DEBERA mostrar un modal con la descripcion y botones "Vote For" / "Vote Against".
3. CUANDO el jugador vota ENTONCES EL contrato DEBERA ejecutar `vote(proposal_id, support)` y registrar el voto con peso influenciado por Reputation y cantidad de Embassies.
4. SI el jugador ya voto en esta propuesta ENTONCES EL contrato DEBERA rechazar un segundo voto.
5. CUANDO los 4 jugadores han votado (o se alcanza el limite) ENTONCES EL sistema DEBERA ejecutar `execute_proposal(proposal_id)`.
6. SI la propuesta obtiene mayoria (3/4) ENTONCES EL contrato DEBERA aplicar el efecto global (sancion, subsidio agricola, fronteras abiertas, impuesto global).
7. CUANDO la propuesta se ejecuta ENTONCES EL sistema DEBERA mostrar el resultado ("Passed" / "Rejected") y emitir el evento correspondiente.

Tipos de propuestas MVP:
- **Sanction player:** el jugador objetivo no puede Expand el siguiente turno.
- **Agricultural subsidy:** todos los jugadores reciben +1 Food.
- **Open borders:** todos pueden expandir sin restriccion de adyacencia por 1 turno.
- **Global tax:** todos los jugadores pierden 1 Wood.

---

### Requisito 11: Condicion de Victoria

**Historia de Usuario:** Como jugador, quiero que el juego detecte automaticamente al ganador, para que la victoria diplomatica sea clara y verificable on-chain.

#### Criterios de Aceptacion

1. CUANDO un jugador completa una accion o un turno termina ENTONCES EL contrato DEBERA verificar la condicion de victoria para todos los jugadores.
2. SI un jugador tiene Reputation >= 10 Y tiene al menos 1 Embassy construida Y tiene >= 2 tratados completados exitosamente ENTONCES EL contrato DEBERA declarar al jugador como ganador.
3. CUANDO se declara un ganador ENTONCES EL contrato DEBERA emitir `GameEnded(winner)` y bloquear futuras acciones.
4. CUANDO hay un ganador ENTONCES EL frontend DEBERA mostrar un modal de victoria con: "Diplomatic Victory", reputacion final, tratados completados, y propuestas clave.
5. CUANDO el modal de victoria se muestra ENTONCES EL sistema DEBERA ofrecer "Play Again" y opcionalmente "View On-chain History".

---

### Requisito 12: Transacciones Gasless y Session Keys

**Historia de Usuario:** Como jugador, quiero que todas mis acciones se ejecuten sin pagar gas, para tener una experiencia de juego fluida.

#### Criterios de Aceptacion

1. MIENTRAS el jugador tenga sesion activa EL sistema DEBERA ejecutar todas las transacciones via Cavos Paymaster (gasless).
2. CUANDO inicia una nueva Era ENTONCES EL sistema DEBERA gestionar session keys scoped a esa Era.
3. CUANDO el jugador ejecuta una accion ENTONCES Cavos DEBERA firmar y enviar la transaccion sin prompts adicionales si hay session key activa.
4. CUANDO una transaccion es enviada ENTONCES EL frontend DEBERA mostrar un toast "Action submitted" como confirmacion.

---

### Requisito 13: Feed de Eventos del Mundo

**Historia de Usuario:** Como jugador, quiero ver un feed de eventos del juego, para entender lo que esta pasando en la partida.

#### Criterios de Aceptacion

1. MIENTRAS el juego este activo EL frontend DEBERA mostrar un feed de "World Events" en `/game`.
2. CUANDO se emite un evento on-chain (PlayerJoined, ActionExecuted, Treaty lifecycle, Proposal lifecycle, GameEnded) ENTONCES EL frontend DEBERA agregar una entrada legible al feed.
3. CADA entrada del feed DEBERA ser legible para el usuario (ej: "Player A sent aid to Player B (+1 Rep)", "Sanction passed: Player C cannot Expand next turn").

---

### Requisito 14: Tutorial Overlay

**Historia de Usuario:** Como jugador nuevo, quiero una explicacion rapida del juego al iniciar, para entender las mecanicas basicas en menos de 60 segundos.

#### Criterios de Aceptacion

1. CUANDO el jugador entra a `/game` por primera vez en una partida ENTONCES EL sistema DEBERA mostrar un overlay tutorial con las reglas basicas.
2. EL overlay DEBERA incluir: "1 accion por turno", "Ganas por reputacion + tratados + embajada", "Votas al final de cada Era".
3. CUANDO el jugador hace clic en "Got it" ENTONCES EL sistema DEBERA cerrar el overlay y habilitar la interaccion con el juego.

---

### Requisito 15: Edge Cases MVP

**Historia de Usuario:** Como sistema, necesito manejar situaciones excepcionales, para que la partida no se bloquee.

#### Criterios de Aceptacion

1. SI un jugador no actua en un turno ENTONCES EL sistema DEBERA permitir avanzar el turno igualmente (via host o `end_turn()`).
2. SI un jugador abandona ENTONCES EL sistema DEBERA mantenerlo como `alive` pero inactivo; sus tiles y recursos permanecen.
3. MIENTRAS un jugador no haya actuado EL sistema DEBERA poder hacer skip de su turno tras un mecanismo definido (post-MVP: auto-skip tras N turnos).
4. SI se intenta una accion con una direccion que no esta registrada en la partida ENTONCES EL contrato DEBERA rechazar la transaccion.
5. CADA transaccion del contrato DEBERA ser O(1) en complejidad para prevenir abuso.

#!/bin/bash
# End-to-end integration test for StarkCivGame on local devnet
#
# Prerequisites:
#   - katana running on http://localhost:5050
#   - Contract deployed (run deploy-devnet.sh first)
#   - sncast available in PATH
#
# Usage: ./scripts/test-integration.sh <contract_address>

set -e

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

CONTRACT="${1:-$NEXT_PUBLIC_GAME_CONTRACT_ADDRESS}"
RPC_URL="${RPC_URL:-http://localhost:5050}"

if [ -z "$CONTRACT" ]; then
  # Try reading from .env.local
  ENV_FILE="$(cd "$(dirname "$0")/../client" && pwd)/.env.local"
  if [ -f "$ENV_FILE" ]; then
    CONTRACT=$(grep NEXT_PUBLIC_GAME_CONTRACT_ADDRESS "$ENV_FILE" | cut -d= -f2)
  fi
fi

if [ -z "$CONTRACT" ]; then
  echo "Usage: $0 <contract_address>"
  echo "  or set NEXT_PUBLIC_GAME_CONTRACT_ADDRESS env var"
  exit 1
fi

# Katana default prefunded accounts
ACCOUNTS=(
  "0xb3ff441a68610b30fd5e2abbf3a1548eb6ba6f3559f2862bf2dc757e5828ca"
  "0xe29882a1fcba1e7e10cad46212257fea5c752a4f9b1b1ec683c503a2cf5c8a"
  "0x29873c310fbefde666dc32a1554fea6bb45eecc84f680f8a2b0a8fbb8cb89af"
  "0x1d98d835e43b032254ffbef0f150c5606fa9c5c9310b1fae370ab956a7919f5"
)

KEYS=(
  "0x2bbf4f9fd0bbd1008d1c74a40b2e18c2038733c8db8e185b73c98ced83b6012"
  "0x1c9053c053edf324aec366a34c6901b1095b07af69495bffec7d7fe21effb1b"
  "0x18a439bcbb1b3535a6145c1dc9bc6366267d923f60a84bd0c7618f33c81d1da"
  "0x300001800000000300000180000000000030000000000003006001800006600"
)

PASS=0
FAIL=0

call() {
  local account_idx=$1
  local function=$2
  shift 2
  local calldata="$@"

  sncast --url "$RPC_URL" \
    --account "account${account_idx}" \
    invoke \
    --contract-address "$CONTRACT" \
    --function "$function" \
    --calldata "$calldata" \
    --fee-token eth 2>&1
}

view() {
  local function=$1
  shift
  local calldata="$@"

  sncast --url "$RPC_URL" \
    call \
    --contract-address "$CONTRACT" \
    --function "$function" \
    --calldata "$calldata" 2>&1
}

assert_contains() {
  local output="$1"
  local expected="$2"
  local test_name="$3"

  if echo "$output" | grep -q "$expected"; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name (expected '$expected')"
    echo "    Got: $output"
    FAIL=$((FAIL + 1))
  fi
}

assert_success() {
  local output="$1"
  local test_name="$2"

  if echo "$output" | grep -qiE "error|fail|revert"; then
    echo "  FAIL: $test_name"
    echo "    Got: $output"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  fi
}

echo "==========================================="
echo "  StarkCiv Integration Test"
echo "==========================================="
echo "Contract: $CONTRACT"
echo "RPC: $RPC_URL"
echo ""

# Create sncast accounts config
echo "[1] Setting up accounts..."
for i in 0 1 2 3; do
  sncast --url "$RPC_URL" \
    account add \
    --name "account${i}" \
    --address "${ACCOUNTS[$i]}" \
    --private-key "${KEYS[$i]}" \
    --type oz 2>/dev/null || true
done
echo "  Accounts configured."
echo ""

# ===== LOBBY PHASE =====
echo "[2] Lobby Phase - Join 4 players"
for i in 0 1 2 3; do
  OUTPUT=$(call $i "join_game")
  assert_success "$OUTPUT" "Player $i joins game"
done
echo ""

# Verify game state
echo "[3] Verify lobby state"
OUTPUT=$(view "get_game_state")
assert_contains "$OUTPUT" "4" "Player count is 4"
echo ""

# Start game
echo "[4] Start game"
OUTPUT=$(call 0 "start_game")
assert_success "$OUTPUT" "Game started"
echo ""

# Verify game started
echo "[5] Verify game started"
OUTPUT=$(view "get_game_state")
echo "  Game state: $OUTPUT"
echo ""

# ===== GAMEPLAY PHASE =====
echo "[6] Player 0: Expand to tile 1 (adjacent to spawn 0)"
OUTPUT=$(call 0 "expand" "1")
assert_success "$OUTPUT" "P0 expands to tile 1"
echo ""

# End turn to allow next action
echo "[7] End turn 1"
OUTPUT=$(call 0 "end_turn")
assert_success "$OUTPUT" "End turn 1"
echo ""

# Build farm on tile 1
echo "[8] Player 0: Build Farm on tile 1"
OUTPUT=$(call 0 "build" "1 2")
assert_success "$OUTPUT" "P0 builds Farm"
echo ""

echo "[9] End turn 2"
OUTPUT=$(call 0 "end_turn")
assert_success "$OUTPUT" "End turn 2"
echo ""

# Expand to tile 5 and build embassy
echo "[10] Player 0: Expand to tile 5"
OUTPUT=$(call 0 "expand" "5")
assert_success "$OUTPUT" "P0 expands to tile 5"
echo ""

echo "[11] End turn 3"
OUTPUT=$(call 0 "end_turn")
assert_success "$OUTPUT" "End turn 3"
echo ""

echo "[12] Player 0: Build Embassy on tile 5"
OUTPUT=$(call 0 "build" "5 4")
assert_success "$OUTPUT" "P0 builds Embassy"
echo ""

echo "[13] End turn 4"
OUTPUT=$(call 0 "end_turn")
assert_success "$OUTPUT" "End turn 4"
echo ""

# ===== AID PHASE =====
echo "[14] Player 0: Send 1 food aid to Player 1"
OUTPUT=$(call 0 "send_aid" "${ACCOUNTS[1]} 0 1")
assert_success "$OUTPUT" "P0 sends aid to P1"
echo ""

echo "[15] End turn 5 (era change)"
OUTPUT=$(call 0 "end_turn")
assert_success "$OUTPUT" "End turn 5"
echo ""

# ===== TREATY PHASE =====
echo "[16] Player 0: Propose treaty to Player 1 (type=0, duration=2)"
OUTPUT=$(call 0 "propose_treaty" "${ACCOUNTS[1]} 0 2")
assert_success "$OUTPUT" "P0 proposes treaty"
echo ""

echo "[17] End turn 6"
OUTPUT=$(call 0 "end_turn")
assert_success "$OUTPUT" "End turn 6"
echo ""

echo "[18] Player 1: Accept treaty (id=0)"
OUTPUT=$(call 1 "accept_treaty" "0")
assert_success "$OUTPUT" "P1 accepts treaty"
echo ""

# Advance turns to complete treaty
echo "[19-20] Advance turns for treaty completion"
OUTPUT=$(call 1 "send_aid" "${ACCOUNTS[0]} 0 1")
assert_success "$OUTPUT" "P1 sends aid (turn 7 action)"
OUTPUT=$(call 0 "end_turn")
assert_success "$OUTPUT" "End turn 7"
OUTPUT=$(call 0 "send_aid" "${ACCOUNTS[1]} 0 1")
assert_success "$OUTPUT" "P0 sends aid (turn 8 action)"
OUTPUT=$(call 0 "end_turn")
assert_success "$OUTPUT" "End turn 8"
echo ""

# ===== GOVERNANCE PHASE =====
# Need to be at era start for proposal
# Era 2 starts at turn 6, era 3 at turn 11
# Let's advance to turn 11
echo "[21] Advancing to era start..."
for turn in 9 10; do
  OUTPUT=$(call 0 "send_aid" "${ACCOUNTS[1]} 0 1")
  OUTPUT=$(call 0 "end_turn")
done
echo "  Advanced to turn 11 (era 3)"
echo ""

echo "[22] Create proposal (Subsidy)"
OUTPUT=$(call 0 "create_proposal" "1 ${ACCOUNTS[0]}")
assert_success "$OUTPUT" "Proposal created"
echo ""

echo "[23] All players vote"
for i in 0 1 2 3; do
  OUTPUT=$(call $i "vote" "0 1")
  assert_success "$OUTPUT" "P$i votes for"
done
echo ""

echo "[24] Execute proposal"
OUTPUT=$(call 0 "execute_proposal" "0")
assert_success "$OUTPUT" "Proposal executed"
echo ""

# ===== VERIFY STATE =====
echo "[25] Verify Player 0 state"
OUTPUT=$(view "get_player" "${ACCOUNTS[0]}")
echo "  Player 0 state: $OUTPUT"
echo ""

echo "[26] Verify game state"
OUTPUT=$(view "get_game_state")
echo "  Game state: $OUTPUT"
echo ""

echo "==========================================="
echo "  Results: $PASS passed, $FAIL failed"
echo "==========================================="

if [ $FAIL -gt 0 ]; then
  exit 1
fi

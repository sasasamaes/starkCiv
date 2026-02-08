#!/bin/bash
# Deploy StarkCivGame contract to local Starknet devnet (katana)
#
# Prerequisites:
#   - katana running on http://localhost:5050
#   - sncast available in PATH
#   - Contract compiled (scarb build)
#
# Usage: ./scripts/deploy-devnet.sh

set -e

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

CONTRACTS_DIR="$(cd "$(dirname "$0")/../contracts" && pwd)"
SIERRA_FILE="$CONTRACTS_DIR/target/dev/starkciv_StarkCivGame.contract_class.json"
CASM_FILE="$CONTRACTS_DIR/target/dev/starkciv_StarkCivGame.compiled_contract_class.json"
RPC_URL="${RPC_URL:-http://localhost:5050}"

# Katana prefunded accounts (default)
ACCOUNT_ADDRESS="0xb3ff441a68610b30fd5e2abbf3a1548eb6ba6f3559f2862bf2dc757e5828ca"
PRIVATE_KEY="0x2bbf4f9fd0bbd1008d1c74a40b2e18c2038733c8db8e185b73c98ced83b6012"

echo "=== StarkCiv Devnet Deployment ==="
echo "RPC: $RPC_URL"
echo ""

# Step 1: Build contract
echo "[1/3] Building contract..."
cd "$CONTRACTS_DIR"
scarb build
echo "  Built successfully."
echo ""

# Step 2: Declare contract
echo "[2/3] Declaring contract class..."
DECLARE_OUTPUT=$(sncast --url "$RPC_URL" \
  declare \
  --contract-name StarkCivGame \
  --fee-token eth 2>&1) || true

# Extract class hash
CLASS_HASH=$(echo "$DECLARE_OUTPUT" | grep -oE 'class_hash: 0x[0-9a-fA-F]+' | head -1 | cut -d' ' -f2)

if [ -z "$CLASS_HASH" ]; then
  # Class might already be declared, try to extract from error
  CLASS_HASH=$(echo "$DECLARE_OUTPUT" | grep -oE '0x[0-9a-fA-F]{60,}' | head -1)
fi

if [ -z "$CLASS_HASH" ]; then
  echo "  Error: Could not get class hash"
  echo "  Output: $DECLARE_OUTPUT"
  exit 1
fi

echo "  Class hash: $CLASS_HASH"
echo ""

# Step 3: Deploy contract
echo "[3/3] Deploying contract..."
DEPLOY_OUTPUT=$(sncast --url "$RPC_URL" \
  deploy \
  --class-hash "$CLASS_HASH" \
  --fee-token eth 2>&1) || true

CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oE 'contract_address: 0x[0-9a-fA-F]+' | head -1 | cut -d' ' -f2)

if [ -z "$CONTRACT_ADDRESS" ]; then
  CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oE '0x[0-9a-fA-F]{60,}' | head -1)
fi

if [ -z "$CONTRACT_ADDRESS" ]; then
  echo "  Error: Could not get contract address"
  echo "  Output: $DEPLOY_OUTPUT"
  exit 1
fi

echo "  Contract address: $CONTRACT_ADDRESS"
echo ""

# Write contract address to .env file
ENV_FILE="$(cd "$(dirname "$0")/../client" && pwd)/.env.local"
echo "NEXT_PUBLIC_GAME_CONTRACT_ADDRESS=$CONTRACT_ADDRESS" > "$ENV_FILE"
echo "NEXT_PUBLIC_CAVOS_APP_ID=devnet" >> "$ENV_FILE"
echo "NEXT_PUBLIC_NETWORK=LOCAL" >> "$ENV_FILE"
echo "  Updated $ENV_FILE"

echo ""
echo "=== Deployment Complete ==="
echo "Contract: $CONTRACT_ADDRESS"
echo ""
echo "Katana prefunded accounts for testing:"
echo "  Account 0: $ACCOUNT_ADDRESS"
echo ""
echo "Next steps:"
echo "  1. Run the integration test: ./scripts/test-integration.sh"
echo "  2. Start frontend: cd client && npm run dev"

import { RpcProvider, Contract } from "starknet";

const GAME_CONTRACT_ADDRESS =
  process.env.NEXT_PUBLIC_GAME_CONTRACT_ADDRESS || "0x0";
const NETWORK = process.env.NEXT_PUBLIC_NETWORK || "SN_SEPOLIA";

// ABI for StarkCivGame contract (simplified for the functions we use)
export const GAME_ABI = [
  {
    type: "function",
    name: "join_game",
    inputs: [],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "start_game",
    inputs: [],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "end_turn",
    inputs: [],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "expand",
    inputs: [{ name: "tile_id", type: "core::integer::u32" }],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "build",
    inputs: [
      { name: "tile_id", type: "core::integer::u32" },
      { name: "building_type", type: "core::integer::u8" },
    ],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "train_guard",
    inputs: [{ name: "tile_id", type: "core::integer::u32" }],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "send_aid",
    inputs: [
      { name: "to", type: "core::starknet::contract_address::ContractAddress" },
      { name: "resource", type: "core::integer::u8" },
      { name: "amount", type: "core::integer::u32" },
    ],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "propose_treaty",
    inputs: [
      { name: "to", type: "core::starknet::contract_address::ContractAddress" },
      { name: "treaty_type", type: "core::integer::u8" },
      { name: "duration", type: "core::integer::u32" },
    ],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "accept_treaty",
    inputs: [{ name: "treaty_id", type: "core::integer::u32" }],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "break_treaty",
    inputs: [{ name: "treaty_id", type: "core::integer::u32" }],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "create_proposal",
    inputs: [
      { name: "kind", type: "core::integer::u8" },
      {
        name: "target",
        type: "core::starknet::contract_address::ContractAddress",
      },
    ],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "vote",
    inputs: [
      { name: "proposal_id", type: "core::integer::u32" },
      { name: "support", type: "core::bool" },
    ],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "execute_proposal",
    inputs: [{ name: "proposal_id", type: "core::integer::u32" }],
    outputs: [],
    state_mutability: "external",
  },
  {
    type: "function",
    name: "get_game_state",
    inputs: [],
    outputs: [{ type: "starkciv::starkciv_game::GameState" }],
    state_mutability: "view",
  },
  {
    type: "function",
    name: "get_player",
    inputs: [
      {
        name: "addr",
        type: "core::starknet::contract_address::ContractAddress",
      },
    ],
    outputs: [{ type: "starkciv::starkciv_game::Player" }],
    state_mutability: "view",
  },
  {
    type: "function",
    name: "get_tile",
    inputs: [{ name: "tile_id", type: "core::integer::u32" }],
    outputs: [{ type: "starkciv::starkciv_game::Tile" }],
    state_mutability: "view",
  },
  {
    type: "function",
    name: "get_active_proposal",
    inputs: [],
    outputs: [{ type: "starkciv::starkciv_game::Proposal" }],
    state_mutability: "view",
  },
  {
    type: "function",
    name: "list_treaties_for",
    inputs: [
      {
        name: "addr",
        type: "core::starknet::contract_address::ContractAddress",
      },
    ],
    outputs: [
      {
        type: "core::array::Array::<starkciv::starkciv_game::Treaty>",
      },
    ],
    state_mutability: "view",
  },
] as const;

function getNodeUrl(): string {
  if (NETWORK === "SN_SEPOLIA") {
    return "https://starknet-sepolia.public.blastapi.io/rpc/v0_7";
  }
  return "http://localhost:5050";
}

let providerInstance: RpcProvider | null = null;

export function getProvider(): RpcProvider {
  if (!providerInstance) {
    providerInstance = new RpcProvider({ nodeUrl: getNodeUrl() });
  }
  return providerInstance;
}

export function getContract(): Contract {
  const provider = getProvider();
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return new (Contract as any)(GAME_ABI, GAME_CONTRACT_ADDRESS, provider);
}

export { GAME_CONTRACT_ADDRESS };

// Game constants matching Cairo contract
export const MAX_PLAYERS = 4;
export const MAP_SIZE = 5;
export const TOTAL_TILES = MAP_SIZE * MAP_SIZE;
export const TURNS_PER_ERA = 5;
export const VICTORY_REP = 10;
export const VICTORY_TREATIES = 2;
export const TREATY_BREAK_REP_PENALTY = 2;

// Spawn positions (corners of 5x5 grid)
export const SPAWN_TILES = [0, 4, 20, 24] as const;

// Building types matching Cairo u8 values
export enum BuildingType {
  None = 0,
  City = 1,
  Farm = 2,
  Market = 3,
  Embassy = 4,
}

// Treaty types
export enum TreatyType {
  NonAggression = 0,
  TradeAgreement = 1,
  Alliance = 2,
}

// Treaty status
export enum TreatyStatus {
  Pending = 0,
  Active = 1,
  Completed = 2,
  Broken = 3,
}

// Proposal kinds
export enum ProposalKind {
  Sanction = 0,
  Subsidy = 1,
  OpenBorders = 2,
  GlobalTax = 3,
}

// Resource types for send_aid
export enum ResourceType {
  Food = 0,
  Wood = 1,
}

// Building type display names
export const BUILDING_NAMES: Record<BuildingType, string> = {
  [BuildingType.None]: "Empty",
  [BuildingType.City]: "City",
  [BuildingType.Farm]: "Farm",
  [BuildingType.Market]: "Market",
  [BuildingType.Embassy]: "Embassy",
};

// Treaty type display names
export const TREATY_NAMES: Record<TreatyType, string> = {
  [TreatyType.NonAggression]: "Non-Aggression Pact",
  [TreatyType.TradeAgreement]: "Trade Agreement",
  [TreatyType.Alliance]: "Alliance",
};

// Proposal kind display names
export const PROPOSAL_NAMES: Record<ProposalKind, string> = {
  [ProposalKind.Sanction]: "Sanction",
  [ProposalKind.Subsidy]: "Subsidy",
  [ProposalKind.OpenBorders]: "Open Borders",
  [ProposalKind.GlobalTax]: "Global Tax",
};

import { BuildingType, TreatyType, TreatyStatus, ProposalKind } from "./constants";

export interface Player {
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

export interface Tile {
  owner: string;
  building: BuildingType;
  guard: boolean;
}

export interface Treaty {
  id: number;
  from: string;
  to: string;
  treatyType: TreatyType;
  status: TreatyStatus;
  startTurn: number;
  endTurn: number;
}

export interface Proposal {
  id: number;
  kind: ProposalKind;
  target: string;
  votesFor: number;
  votesAgainst: number;
  executed: boolean;
  era: number;
}

export interface GameState {
  gameStarted: boolean;
  playerCount: number;
  currentTurn: number;
  currentEra: number;
  winner: string;
}

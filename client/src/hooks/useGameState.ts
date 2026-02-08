"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { getContract } from "@/lib/contract";
import { TOTAL_TILES, MAX_PLAYERS } from "@/lib/constants";
import type { GameState, Player, Tile } from "@/lib/types";

const POLL_INTERVAL = 5000;
const ZERO_ADDRESS = "0x0";

interface UseGameStateReturn {
  gameState: GameState | null;
  players: Player[];
  tiles: Tile[];
  isLoading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
}

function parseGameState(raw: Record<string, unknown>): GameState {
  return {
    gameStarted: Boolean(raw.game_started),
    playerCount: Number(raw.player_count),
    currentTurn: Number(raw.current_turn),
    currentEra: Number(raw.current_era),
    winner: String(raw.winner ?? ZERO_ADDRESS),
  };
}

function parsePlayer(raw: Record<string, unknown>): Player {
  return {
    addr: String(raw.addr ?? ZERO_ADDRESS),
    food: Number(raw.food ?? 0),
    wood: Number(raw.wood ?? 0),
    reputation: Number(raw.reputation ?? 0),
    cityTile: Number(raw.city_tile ?? 0),
    embassyBuilt: Boolean(raw.embassy_built),
    treatiesCompleted: Number(raw.treaties_completed ?? 0),
    alive: Boolean(raw.alive),
    lastActionTurn: Number(raw.last_action_turn ?? 0),
  };
}

function parseTile(raw: Record<string, unknown>): Tile {
  return {
    owner: String(raw.owner ?? ZERO_ADDRESS),
    building: Number(raw.building ?? 0),
    guard: Boolean(raw.guard),
  };
}

export function useGameState(playerAddresses: string[] = []): UseGameStateReturn {
  const [gameState, setGameState] = useState<GameState | null>(null);
  const [players, setPlayers] = useState<Player[]>([]);
  const [tiles, setTiles] = useState<Tile[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval>>(undefined);

  const fetchState = useCallback(async () => {
    try {
      const contract = getContract();

      // Fetch game state
      const rawState = await contract.get_game_state();
      const state = parseGameState(rawState as Record<string, unknown>);
      setGameState(state);

      // Fetch players (up to 4)
      const addresses =
        playerAddresses.length > 0
          ? playerAddresses.slice(0, MAX_PLAYERS)
          : [];
      const playerPromises = addresses.map((addr) =>
        contract.get_player(addr).then((raw: unknown) => parsePlayer(raw as Record<string, unknown>))
      );
      const fetchedPlayers = await Promise.all(playerPromises);
      setPlayers(fetchedPlayers);

      // Fetch all 25 tiles
      const tilePromises = Array.from({ length: TOTAL_TILES }, (_, i) =>
        contract.get_tile(i).then((raw: unknown) => parseTile(raw as Record<string, unknown>))
      );
      const fetchedTiles = await Promise.all(tilePromises);
      setTiles(fetchedTiles);

      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to fetch game state");
    } finally {
      setIsLoading(false);
    }
  }, [playerAddresses]);

  useEffect(() => {
    fetchState();
    intervalRef.current = setInterval(fetchState, POLL_INTERVAL);
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [fetchState]);

  return { gameState, players, tiles, isLoading, error, refetch: fetchState };
}

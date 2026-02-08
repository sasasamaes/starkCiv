"use client";

import { useState, useEffect, useCallback } from "react";
import { useCavos } from "@/providers/CavosProvider";
import { getContract } from "@/lib/contract";
import type { Player } from "@/lib/types";

const ZERO_ADDRESS = "0x0";

interface UsePlayerReturn {
  player: Player | null;
  isLoading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
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

export function usePlayer(): UsePlayerReturn {
  const { account } = useCavos();
  const [player, setPlayer] = useState<Player | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPlayer = useCallback(async () => {
    if (!account) {
      setPlayer(null);
      setIsLoading(false);
      return;
    }
    try {
      const contract = getContract();
      const raw = await contract.get_player(account.address);
      setPlayer(parsePlayer(raw as Record<string, unknown>));
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to fetch player");
    } finally {
      setIsLoading(false);
    }
  }, [account]);

  useEffect(() => {
    fetchPlayer();
  }, [fetchPlayer]);

  return { player, isLoading, error, refetch: fetchPlayer };
}

"use client";

import { useState, useEffect, useCallback } from "react";
import { useCavos } from "@/providers/CavosProvider";
import { getContract } from "@/lib/contract";
import { TreatyStatus } from "@/lib/constants";
import type { Treaty } from "@/lib/types";

const POLL_INTERVAL = 5000;

function parseTreaty(raw: Record<string, unknown>): Treaty {
  return {
    id: Number(raw.id ?? 0),
    from: String(raw.from ?? "0x0"),
    to: String(raw.to ?? "0x0"),
    treatyType: Number(raw.treaty_type ?? 0),
    status: Number(raw.status ?? 0),
    startTurn: Number(raw.start_turn ?? 0),
    endTurn: Number(raw.end_turn ?? 0),
  };
}

interface UseTreatiesReturn {
  incoming: Treaty[];
  active: Treaty[];
  history: Treaty[];
  allTreaties: Treaty[];
  isLoading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
}

export function useTreaties(): UseTreatiesReturn {
  const { account } = useCavos();
  const [allTreaties, setAllTreaties] = useState<Treaty[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTreaties = useCallback(async () => {
    if (!account) {
      setAllTreaties([]);
      setIsLoading(false);
      return;
    }
    try {
      const contract = getContract();
      const raw = await contract.list_treaties_for(account.address);
      const treaties = Array.isArray(raw)
        ? raw.map((r: unknown) => parseTreaty(r as Record<string, unknown>))
        : [];
      setAllTreaties(treaties);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to fetch treaties");
    } finally {
      setIsLoading(false);
    }
  }, [account]);

  useEffect(() => {
    fetchTreaties();
    const interval = setInterval(fetchTreaties, POLL_INTERVAL);
    return () => clearInterval(interval);
  }, [fetchTreaties]);

  const myAddr = account?.address?.toLowerCase() ?? "";

  // Incoming: pending treaties where I am the "to" address
  const incoming = allTreaties.filter(
    (t) =>
      t.status === TreatyStatus.Pending &&
      t.to.toLowerCase() === myAddr
  );

  // Active: active treaties
  const active = allTreaties.filter(
    (t) => t.status === TreatyStatus.Active
  );

  // History: completed or broken
  const history = allTreaties.filter(
    (t) =>
      t.status === TreatyStatus.Completed ||
      t.status === TreatyStatus.Broken
  );

  return {
    incoming,
    active,
    history,
    allTreaties,
    isLoading,
    error,
    refetch: fetchTreaties,
  };
}

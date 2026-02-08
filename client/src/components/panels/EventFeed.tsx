"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { getProvider } from "@/lib/contract";
import { GAME_CONTRACT_ADDRESS } from "@/lib/contract";
import { abbreviateAddress } from "@/lib/utils";

const MAX_EVENTS = 20;
const POLL_INTERVAL = 8000;

interface GameEvent {
  id: string;
  type: string;
  message: string;
  timestamp: number;
}

/**
 * Translate raw event keys/data into human-readable text.
 * Event keys[0] is typically the event selector hash.
 */
function translateEvent(
  keys: string[],
  data: string[],
  index: number
): GameEvent | null {
  // Attempt to infer event type from key patterns
  // In production, these would match actual Cairo event selectors
  const selector = keys[0] ?? "";

  // Use simple heuristics based on data length and key patterns
  // This is a simplified approach for the MVP
  const eventMap: Record<string, (d: string[]) => string> = {
    player_joined: (d) =>
      `${abbreviateAddress(d[0] ?? "?")} joined the game`,
    game_started: () => "Game has started!",
    turn_ended: (d) =>
      `${abbreviateAddress(d[0] ?? "?")} ended their turn`,
    territory_expanded: (d) =>
      `${abbreviateAddress(d[0] ?? "?")} expanded to tile ${Number(d[1] ?? 0)}`,
    building_built: (d) =>
      `${abbreviateAddress(d[0] ?? "?")} built on tile ${Number(d[1] ?? 0)}`,
    guard_trained: (d) =>
      `${abbreviateAddress(d[0] ?? "?")} trained a guard on tile ${Number(d[1] ?? 0)}`,
    aid_sent: (d) =>
      `${abbreviateAddress(d[0] ?? "?")} sent aid to ${abbreviateAddress(d[1] ?? "?")}`,
    treaty_proposed: (d) =>
      `${abbreviateAddress(d[0] ?? "?")} proposed a treaty to ${abbreviateAddress(d[1] ?? "?")}`,
    treaty_accepted: (d) =>
      `${abbreviateAddress(d[0] ?? "?")} accepted treaty #${Number(d[1] ?? 0)}`,
    treaty_broken: (d) =>
      `${abbreviateAddress(d[0] ?? "?")} broke treaty #${Number(d[1] ?? 0)}`,
    proposal_created: (d) =>
      `New proposal created targeting ${abbreviateAddress(d[0] ?? "?")}`,
    vote_cast: (d) =>
      `${abbreviateAddress(d[0] ?? "?")} voted on proposal #${Number(d[1] ?? 0)}`,
    victory: (d) =>
      `${abbreviateAddress(d[0] ?? "?")} achieved diplomatic victory!`,
  };

  // Try to match event -- for hackathon MVP we generate descriptive messages
  // from whatever data we can extract
  let message = `Event from contract (${data.length} data fields)`;
  let type = "unknown";

  // Check if selector matches any known pattern (simplified matching)
  for (const [eventType, formatter] of Object.entries(eventMap)) {
    if (selector.toLowerCase().includes(eventType.replace(/_/g, ""))) {
      message = formatter(data);
      type = eventType;
      break;
    }
  }

  // If we could not match, create a generic event message
  if (type === "unknown" && data.length > 0) {
    const addr = data[0] ?? "";
    if (addr.startsWith("0x") && addr.length > 10) {
      message = `Activity from ${abbreviateAddress(addr)}`;
    }
  }

  return {
    id: `${selector}-${index}-${Date.now()}`,
    type,
    message,
    timestamp: Date.now(),
  };
}

export function EventFeed() {
  const [events, setEvents] = useState<GameEvent[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const seenBlockRef = useRef<number>(0);

  const fetchEvents = useCallback(async () => {
    try {
      const provider = getProvider();

      // Get latest block
      const block = await provider.getBlockNumber();

      // Only fetch events from recent blocks (last 50 blocks or from last seen)
      const fromBlock = seenBlockRef.current > 0
        ? seenBlockRef.current + 1
        : Math.max(0, block - 50);

      if (fromBlock > block) {
        setIsLoading(false);
        return;
      }

      // Fetch events from the game contract
      const contractAddress = GAME_CONTRACT_ADDRESS;
      if (contractAddress === "0x0") {
        setIsLoading(false);
        return;
      }

      try {
        const result = await provider.getEvents({
          address: contractAddress,
          from_block: { block_number: fromBlock },
          to_block: { block_number: block },
          keys: [],
          chunk_size: 50,
        });

        if (result.events && result.events.length > 0) {
          const newEvents = result.events
            .map((e: { keys: string[]; data: string[] }, i: number) =>
              translateEvent(e.keys, e.data, i)
            )
            .filter((e: GameEvent | null): e is GameEvent => e !== null);

          setEvents((prev) => {
            const combined = [...newEvents, ...prev];
            return combined.slice(0, MAX_EVENTS);
          });
        }
      } catch {
        // Events API may not be available in all environments
      }

      seenBlockRef.current = block;
    } catch {
      // Silently handle polling errors
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchEvents();
    const interval = setInterval(fetchEvents, POLL_INTERVAL);
    return () => clearInterval(interval);
  }, [fetchEvents]);

  return (
    <div className="rounded-xl border border-slate-700 bg-[#141825] p-4">
      <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider text-slate-400">
        Event Feed
      </h2>

      {isLoading ? (
        <div className="flex items-center justify-center py-4">
          <span className="inline-block h-4 w-4 animate-spin rounded-full border-2 border-blue-500 border-t-transparent" />
        </div>
      ) : events.length === 0 ? (
        <p className="py-4 text-center text-xs text-slate-600">
          No events yet. Actions will appear here.
        </p>
      ) : (
        <div className="flex flex-col gap-1.5 max-h-48 overflow-y-auto">
          {events.map((event) => (
            <div
              key={event.id}
              className="rounded-lg bg-[#0b0e17] px-3 py-2 text-xs text-slate-300"
            >
              <span className="text-slate-500">
                {new Date(event.timestamp).toLocaleTimeString([], {
                  hour: "2-digit",
                  minute: "2-digit",
                })}
              </span>{" "}
              {event.message}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

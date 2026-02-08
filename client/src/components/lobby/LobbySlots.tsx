"use client";

import { MAX_PLAYERS } from "@/lib/constants";
import { abbreviateAddress, PLAYER_COLORS } from "@/lib/utils";

interface LobbySlotsProps {
  playerAddresses: string[];
  currentPlayerAddress?: string;
}

export function LobbySlots({
  playerAddresses,
  currentPlayerAddress,
}: LobbySlotsProps) {
  const slots = Array.from({ length: MAX_PLAYERS }, (_, i) => ({
    index: i,
    address: playerAddresses[i] ?? null,
    color: PLAYER_COLORS[i],
  }));

  return (
    <div className="flex flex-col gap-3">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-semibold uppercase tracking-wider text-slate-400">
          Players
        </h3>
        <span className="font-mono text-sm text-slate-500">
          {playerAddresses.length}/{MAX_PLAYERS}
        </span>
      </div>
      <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
        {slots.map((slot) => {
          const isCurrentPlayer =
            slot.address &&
            currentPlayerAddress &&
            slot.address.toLowerCase() === currentPlayerAddress.toLowerCase();

          return (
            <div
              key={slot.index}
              className={`flex items-center gap-3 rounded-lg border px-4 py-3 transition-all ${
                slot.address
                  ? `border-${slot.color.name === "blue" ? "blue" : slot.color.name === "red" ? "red" : slot.color.name === "green" ? "green" : "yellow"}-500/30 bg-[#141825]`
                  : "border-slate-700/50 bg-[#141825]/50"
              }`}
            >
              {/* Player color indicator */}
              <div
                className="h-8 w-8 flex-shrink-0 rounded-full"
                style={{
                  backgroundColor: slot.address ? slot.color.hex : "#1e2333",
                  opacity: slot.address ? 1 : 0.3,
                }}
              />

              <div className="flex flex-col">
                <span className="text-xs font-medium text-slate-500">
                  Player {slot.index + 1}
                </span>
                {slot.address ? (
                  <span className="font-mono text-sm text-slate-200">
                    {abbreviateAddress(slot.address)}
                    {isCurrentPlayer && (
                      <span className="ml-2 text-xs text-green-400">
                        (you)
                      </span>
                    )}
                  </span>
                ) : (
                  <span className="text-sm italic text-slate-600">
                    Waiting...
                  </span>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

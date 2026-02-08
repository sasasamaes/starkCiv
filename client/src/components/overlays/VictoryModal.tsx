"use client";

import { useRouter } from "next/navigation";
import { abbreviateAddress, getPlayerColor } from "@/lib/utils";
import type { Player } from "@/lib/types";

interface VictoryModalProps {
  winner: string;
  player: Player | null;
  playerAddresses: string[];
}

export function VictoryModal({
  winner,
  player,
  playerAddresses,
}: VictoryModalProps) {
  const router = useRouter();
  const winnerColor = getPlayerColor(winner, playerAddresses);
  const isMe =
    player && player.addr.toLowerCase() === winner.toLowerCase();

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm">
      <div className="mx-4 w-full max-w-md rounded-xl border border-yellow-500/30 bg-[#141825] p-8 shadow-xl text-center">
        {/* Trophy */}
        <div className="text-5xl">{"\u{1F3C6}"}</div>

        <h2 className="mt-4 text-2xl font-bold text-yellow-400">
          {isMe ? "Victory!" : "Game Over"}
        </h2>

        <p className="mt-2 text-sm text-slate-400">
          {isMe
            ? "Congratulations! You achieved a diplomatic victory!"
            : "A player has achieved diplomatic victory."}
        </p>

        {/* Winner info */}
        <div className="mt-4 rounded-lg border border-slate-700 bg-[#0b0e17] p-4">
          <p className="text-xs text-slate-500">Winner</p>
          <p
            className="mt-1 font-mono text-lg font-bold"
            style={{ color: winnerColor?.hex ?? "#eab308" }}
          >
            {abbreviateAddress(winner)}
          </p>
        </div>

        {/* Stats */}
        {player && isMe && (
          <div className="mt-4 grid grid-cols-2 gap-3">
            <div className="rounded-lg bg-[#0b0e17] px-3 py-2">
              <span className="block text-lg font-bold text-white">
                {player.reputation}
              </span>
              <span className="text-[10px] uppercase text-slate-500">
                Reputation
              </span>
            </div>
            <div className="rounded-lg bg-[#0b0e17] px-3 py-2">
              <span className="block text-lg font-bold text-white">
                {player.treatiesCompleted}
              </span>
              <span className="text-[10px] uppercase text-slate-500">
                Treaties
              </span>
            </div>
          </div>
        )}

        {/* Actions */}
        <div className="mt-6 flex gap-3">
          <button
            onClick={() => router.push("/")}
            className="flex-1 rounded-lg bg-blue-600 px-4 py-3 text-sm font-semibold text-white hover:bg-blue-500"
          >
            Play Again
          </button>
          <button
            onClick={() => router.push("/diplomacy")}
            className="flex-1 rounded-lg border border-slate-600 px-4 py-3 text-sm text-slate-300 hover:bg-[#1e2333]"
          >
            View History
          </button>
        </div>
      </div>
    </div>
  );
}

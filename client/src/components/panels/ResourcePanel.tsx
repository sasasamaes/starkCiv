"use client";

import type { Player, GameState } from "@/lib/types";
import { TURNS_PER_ERA, VICTORY_REP, VICTORY_TREATIES } from "@/lib/constants";

interface ResourcePanelProps {
  player: Player | null;
  gameState: GameState | null;
}

export function ResourcePanel({ player, gameState }: ResourcePanelProps) {
  const hasActedThisTurn =
    player && gameState
      ? player.lastActionTurn >= gameState.currentTurn
      : false;

  const turnsLeftInEra = gameState
    ? TURNS_PER_ERA - ((gameState.currentTurn - 1) % TURNS_PER_ERA)
    : 0;

  return (
    <div className="rounded-xl border border-slate-700 bg-[#141825] p-4">
      <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider text-slate-400">
        Resources
      </h2>

      {/* Resource grid */}
      <div className="grid grid-cols-2 gap-2">
        <ResourceItem
          icon={"\u{1F33E}"}
          label="Food"
          value={player?.food ?? 0}
        />
        <ResourceItem
          icon={"\u{1FAB5}"}
          label="Wood"
          value={player?.wood ?? 0}
        />
        <ResourceItem
          icon={"\u{2B50}"}
          label="Reputation"
          value={player?.reputation ?? 0}
          highlight={
            player && player.reputation >= VICTORY_REP
          }
        />
        <ResourceItem
          icon={"\u{1F4DC}"}
          label="Treaties"
          value={player?.treatiesCompleted ?? 0}
          highlight={
            player && player.treatiesCompleted >= VICTORY_TREATIES
          }
        />
      </div>

      {/* Divider */}
      <div className="my-3 border-t border-slate-700" />

      {/* Game state */}
      <div className="grid grid-cols-2 gap-2">
        <div className="flex items-center gap-2 rounded-lg bg-[#0b0e17] px-3 py-2">
          <span className="text-xs text-slate-500">Turn</span>
          <span className="font-mono text-sm font-bold text-white">
            {gameState?.currentTurn ?? 0}
          </span>
        </div>
        <div className="flex items-center gap-2 rounded-lg bg-[#0b0e17] px-3 py-2">
          <span className="text-xs text-slate-500">Era</span>
          <span className="font-mono text-sm font-bold text-white">
            {gameState?.currentEra ?? 0}
          </span>
        </div>
      </div>

      {/* Era progress */}
      <div className="mt-2 rounded-lg bg-[#0b0e17] px-3 py-2">
        <div className="flex items-center justify-between text-xs">
          <span className="text-slate-500">Era ends in</span>
          <span className="font-mono text-yellow-400">
            {turnsLeftInEra} turn{turnsLeftInEra !== 1 ? "s" : ""}
          </span>
        </div>
      </div>

      {/* Action cooldown */}
      <div className="mt-2">
        {hasActedThisTurn ? (
          <div className="flex items-center gap-2 rounded-lg border border-yellow-500/30 bg-yellow-900/20 px-3 py-2 text-xs text-yellow-400">
            <span className="inline-block h-2 w-2 rounded-full bg-yellow-500" />
            Cooldown -- wait for next turn
          </div>
        ) : (
          <div className="flex items-center gap-2 rounded-lg border border-green-500/30 bg-green-900/20 px-3 py-2 text-xs text-green-400">
            <span className="inline-block h-2 w-2 rounded-full bg-green-500" />
            Ready to act
          </div>
        )}
      </div>

      {/* Embassy status */}
      {player?.embassyBuilt && (
        <div className="mt-2 flex items-center gap-2 rounded-lg bg-[#0b0e17] px-3 py-2 text-xs text-blue-400">
          {"\u{1F3F0}"} Embassy built
        </div>
      )}
    </div>
  );
}

function ResourceItem({
  icon,
  label,
  value,
  highlight,
}: {
  icon: string;
  label: string;
  value: number;
  highlight?: boolean | null;
}) {
  return (
    <div
      className={`flex items-center gap-2 rounded-lg px-3 py-2 ${
        highlight
          ? "border border-yellow-500/30 bg-yellow-900/10"
          : "bg-[#0b0e17]"
      }`}
    >
      <span className="text-base">{icon}</span>
      <div className="flex flex-col">
        <span className="text-[10px] uppercase text-slate-500">{label}</span>
        <span
          className={`font-mono text-sm font-bold ${
            highlight ? "text-yellow-400" : "text-white"
          }`}
        >
          {value}
        </span>
      </div>
    </div>
  );
}

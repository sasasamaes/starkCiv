"use client";

import { useState, useMemo } from "react";
import { useRouter } from "next/navigation";
import { useContractActions } from "@/hooks/useContractActions";
import { BuildingType, ResourceType, BUILDING_NAMES } from "@/lib/constants";
import { getAdjacentTiles } from "@/lib/grid";
import { BUILDING_ICONS, abbreviateAddress } from "@/lib/utils";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { Toast } from "@/components/ui/Toast";
import type { Tile, Player, GameState } from "@/lib/types";

const ZERO_ADDRESS = "0x0";

interface ActionPanelProps {
  selectedTile: number | null;
  tiles: Tile[];
  player: Player | null;
  gameState: GameState | null;
  playerAddresses: string[];
  onActionComplete: () => void;
}

interface PendingAction {
  type: string;
  title: string;
  message: string;
  execute: () => Promise<unknown>;
}

export function ActionPanel({
  selectedTile,
  tiles,
  player,
  gameState,
  playerAddresses,
  onActionComplete,
}: ActionPanelProps) {
  const router = useRouter();
  const {
    expand,
    build,
    trainGuard,
    sendAid,
    endTurn,
  } = useContractActions();

  const [pendingAction, setPendingAction] = useState<PendingAction | null>(null);
  const [isExecuting, setIsExecuting] = useState(false);
  const [toast, setToast] = useState<{
    message: string;
    type: "success" | "error";
  } | null>(null);

  // Send aid form state
  const [aidTarget, setAidTarget] = useState("");
  const [aidResource, setAidResource] = useState<ResourceType>(ResourceType.Food);
  const [aidAmount, setAidAmount] = useState(1);

  const hasActedThisTurn =
    player && gameState
      ? player.lastActionTurn >= gameState.currentTurn
      : false;

  const myAddress = player?.addr ?? "";

  // Determine which actions are available for the selected tile
  const tileActions = useMemo(() => {
    if (selectedTile === null || !player || !tiles.length) return [];

    const tile = tiles[selectedTile];
    if (!tile) return [];

    const actions: { label: string; icon: string; onClick: () => void }[] = [];

    const isOwnTile =
      tile.owner &&
      tile.owner !== ZERO_ADDRESS &&
      tile.owner.toLowerCase() === myAddress.toLowerCase();

    const isEmptyTile = !tile.owner || tile.owner === ZERO_ADDRESS;

    // Check if this tile is adjacent to any of our owned tiles
    const isAdjacentToOwned = isEmptyTile && tiles.some((t, idx) => {
      const isOwned =
        t.owner &&
        t.owner !== ZERO_ADDRESS &&
        t.owner.toLowerCase() === myAddress.toLowerCase();
      if (!isOwned) return false;
      try {
        return getAdjacentTiles(idx).includes(selectedTile);
      } catch {
        return false;
      }
    });

    // Empty adjacent tile -> Expand
    if (isEmptyTile && isAdjacentToOwned) {
      actions.push({
        label: "Expand",
        icon: "\u{1F30D}",
        onClick: () =>
          setPendingAction({
            type: "expand",
            title: "Expand Territory",
            message: `Expand to tile ${selectedTile}? Costs 2 Food + 1 Wood.`,
            execute: () => expand(selectedTile),
          }),
      });
    }

    // Own tile with no building -> Build options
    if (isOwnTile && tile.building === BuildingType.None) {
      const buildOptions = [
        { type: BuildingType.Farm, cost: "2 Wood" },
        { type: BuildingType.Market, cost: "3 Wood" },
        { type: BuildingType.Embassy, cost: "5 Wood + 3 Food" },
      ];

      for (const opt of buildOptions) {
        actions.push({
          label: `Build ${BUILDING_NAMES[opt.type]}`,
          icon: BUILDING_ICONS[opt.type],
          onClick: () =>
            setPendingAction({
              type: "build",
              title: `Build ${BUILDING_NAMES[opt.type]}`,
              message: `Build a ${BUILDING_NAMES[opt.type]} on tile ${selectedTile}? Costs ${opt.cost}.`,
              execute: () => build(selectedTile, opt.type),
            }),
        });
      }
    }

    // Own tile with no guard -> Train Guard
    if (isOwnTile && !tile.guard) {
      actions.push({
        label: "Train Guard",
        icon: "\u{1F6E1}\u{FE0F}",
        onClick: () =>
          setPendingAction({
            type: "train_guard",
            title: "Train Guard",
            message: `Place a guard on tile ${selectedTile}? Costs 2 Food + 1 Wood.`,
            execute: () => trainGuard(selectedTile),
          }),
      });
    }

    return actions;
  }, [selectedTile, player, tiles, myAddress, expand, build, trainGuard]);

  const handleConfirm = async () => {
    if (!pendingAction) return;
    setIsExecuting(true);
    try {
      await pendingAction.execute();
      setToast({ message: "Action submitted", type: "success" });
      onActionComplete();
    } catch (err) {
      setToast({
        message: err instanceof Error ? err.message : "Action failed",
        type: "error",
      });
    } finally {
      setIsExecuting(false);
      setPendingAction(null);
    }
  };

  const handleSendAid = () => {
    if (!aidTarget) return;
    setPendingAction({
      type: "send_aid",
      title: "Send Aid",
      message: `Send ${aidAmount} ${aidResource === ResourceType.Food ? "Food" : "Wood"} to ${abbreviateAddress(aidTarget)}?`,
      execute: () => sendAid(aidTarget, aidResource, aidAmount),
    });
  };

  const handleEndTurn = () => {
    setPendingAction({
      type: "end_turn",
      title: "End Turn",
      message: "End your turn? You will collect resources from your buildings.",
      execute: () => endTurn(),
    });
  };

  return (
    <>
      <div className="rounded-xl border border-slate-700 bg-[#141825] p-4">
        <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider text-slate-400">
          Actions
        </h2>

        {hasActedThisTurn && (
          <p className="mb-3 text-xs text-yellow-400">
            You have already acted this turn. Wait for the next turn.
          </p>
        )}

        {/* Tile-specific actions */}
        {selectedTile !== null && tileActions.length > 0 && (
          <div className="mb-3 flex flex-col gap-2">
            <p className="text-xs text-slate-500">
              Tile {selectedTile} actions:
            </p>
            {tileActions.map((action) => (
              <button
                key={action.label}
                onClick={action.onClick}
                disabled={hasActedThisTurn || false}
                className="flex items-center gap-2 rounded-lg border border-slate-600 px-3 py-2 text-sm text-slate-200 transition-colors hover:bg-[#1e2333] disabled:cursor-not-allowed disabled:opacity-40"
              >
                <span>{action.icon}</span>
                <span>{action.label}</span>
              </button>
            ))}
          </div>
        )}

        {selectedTile !== null && tileActions.length === 0 && (
          <p className="mb-3 text-xs text-slate-500">
            No actions available for tile {selectedTile}.
          </p>
        )}

        {selectedTile === null && (
          <p className="mb-3 text-xs text-slate-500">
            Select a tile on the map to see available actions.
          </p>
        )}

        {/* Divider */}
        <div className="my-3 border-t border-slate-700" />

        {/* Send Aid section */}
        <div className="mb-3">
          <p className="mb-2 text-xs font-medium text-slate-400">Send Aid</p>
          <div className="flex flex-col gap-2">
            <input
              type="text"
              value={aidTarget}
              onChange={(e) => setAidTarget(e.target.value)}
              placeholder="Recipient address (0x...)"
              className="rounded-lg border border-slate-600 bg-[#0b0e17] px-3 py-2 font-mono text-xs text-white placeholder-slate-500 outline-none focus:border-blue-500"
            />
            {/* Other players as quick select */}
            {playerAddresses.length > 1 && (
              <div className="flex flex-wrap gap-1">
                {playerAddresses
                  .filter((a) => a.toLowerCase() !== myAddress.toLowerCase())
                  .map((addr) => (
                    <button
                      key={addr}
                      onClick={() => setAidTarget(addr)}
                      className="rounded border border-slate-600 px-2 py-0.5 font-mono text-[10px] text-slate-400 hover:bg-[#1e2333]"
                    >
                      {abbreviateAddress(addr)}
                    </button>
                  ))}
              </div>
            )}
            <div className="flex gap-2">
              <select
                value={aidResource}
                onChange={(e) => setAidResource(Number(e.target.value))}
                className="flex-1 rounded-lg border border-slate-600 bg-[#0b0e17] px-3 py-2 text-xs text-white outline-none"
              >
                <option value={ResourceType.Food}>Food</option>
                <option value={ResourceType.Wood}>Wood</option>
              </select>
              <input
                type="number"
                min={1}
                max={99}
                value={aidAmount}
                onChange={(e) => setAidAmount(Math.max(1, Number(e.target.value)))}
                className="w-16 rounded-lg border border-slate-600 bg-[#0b0e17] px-3 py-2 text-xs text-white outline-none"
              />
            </div>
            <button
              onClick={handleSendAid}
              disabled={hasActedThisTurn || !aidTarget}
              className="rounded-lg bg-blue-600 px-3 py-2 text-xs font-medium text-white hover:bg-blue-500 disabled:cursor-not-allowed disabled:opacity-40"
            >
              Send Aid
            </button>
          </div>
        </div>

        {/* Divider */}
        <div className="my-3 border-t border-slate-700" />

        {/* Global actions */}
        <div className="flex flex-col gap-2">
          <button
            onClick={() => router.push("/diplomacy")}
            className="flex items-center gap-2 rounded-lg border border-slate-600 px-3 py-2 text-sm text-slate-200 transition-colors hover:bg-[#1e2333]"
          >
            <span>{"\u{1F4DC}"}</span>
            <span>Propose Treaty</span>
          </button>
          <button
            onClick={handleEndTurn}
            disabled={hasActedThisTurn || false}
            className="rounded-lg bg-yellow-600 px-3 py-2 text-sm font-medium text-white transition-colors hover:bg-yellow-500 disabled:cursor-not-allowed disabled:opacity-40"
          >
            End Turn
          </button>
        </div>
      </div>

      {/* Confirm dialog */}
      {pendingAction && (
        <ConfirmDialog
          title={pendingAction.title}
          message={pendingAction.message}
          onConfirm={handleConfirm}
          onCancel={() => setPendingAction(null)}
          isLoading={isExecuting}
        />
      )}

      {/* Toast */}
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
    </>
  );
}

"use client";

import { useState, useEffect, useMemo } from "react";
import { useRouter } from "next/navigation";
import { useCavos } from "@/providers/CavosProvider";
import { useGameState } from "@/hooks/useGameState";
import { usePlayer } from "@/hooks/usePlayer";
import { GameMap } from "@/components/map/GameMap";
import { ResourcePanel } from "@/components/panels/ResourcePanel";
import { ActionPanel } from "@/components/panels/ActionPanel";
import { EventFeed } from "@/components/panels/EventFeed";
import { TutorialOverlay } from "@/components/overlays/TutorialOverlay";
import { VictoryModal } from "@/components/overlays/VictoryModal";
import { VotingModal } from "@/components/diplomacy/VotingModal";

const ZERO_ADDRESS = "0x0";

export default function GamePage() {
  const { account, isConnected } = useCavos();
  const router = useRouter();
  const [selectedTile, setSelectedTile] = useState<number | null>(null);
  const [showVoting, setShowVoting] = useState(false);

  // For the MVP, we use a mock list of player addresses.
  // In production this would come from on-chain data.
  const playerAddresses = useMemo(() => {
    if (!account) return [];
    return [account.address];
  }, [account]);

  const { gameState, tiles, isLoading, error, refetch } =
    useGameState(playerAddresses);
  const { player } = usePlayer();

  // Redirect if not connected
  useEffect(() => {
    if (!isConnected) {
      router.push("/");
    }
  }, [isConnected, router]);

  // Check for winner
  const hasWinner =
    gameState?.winner && gameState.winner !== ZERO_ADDRESS;

  if (!isConnected) return null;

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-[#0b0e17]">
        <div className="flex flex-col items-center gap-4">
          <span className="inline-block h-8 w-8 animate-spin rounded-full border-2 border-blue-500 border-t-transparent" />
          <span className="text-sm text-slate-400">Loading game state...</span>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-[#0b0e17]">
        <div className="flex flex-col items-center gap-4 text-center">
          <p className="text-red-400">{error}</p>
          <button
            onClick={refetch}
            className="rounded-lg bg-blue-600 px-4 py-2 text-sm text-white hover:bg-blue-500"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#0b0e17]">
      {/* Tutorial overlay (shown once) */}
      <TutorialOverlay />

      {/* Victory modal */}
      {hasWinner && gameState && (
        <VictoryModal
          winner={gameState.winner}
          player={player}
          playerAddresses={playerAddresses}
        />
      )}

      {/* Voting modal */}
      {showVoting && (
        <VotingModal
          onClose={() => setShowVoting(false)}
          playerAddresses={playerAddresses}
        />
      )}

      {/* Top bar */}
      <header className="flex items-center justify-between border-b border-slate-700 bg-[#141825] px-4 py-3">
        <h1 className="text-lg font-bold text-white">
          Stark<span className="text-blue-400">Civ</span>
        </h1>
        <div className="flex items-center gap-3">
          <button
            onClick={() => setShowVoting(true)}
            className="rounded-lg border border-slate-600 px-3 py-1.5 text-xs text-slate-300 hover:bg-[#1e2333]"
          >
            Voting
          </button>
          <button
            onClick={() => router.push("/diplomacy")}
            className="rounded-lg border border-slate-600 px-3 py-1.5 text-xs text-slate-300 hover:bg-[#1e2333]"
          >
            Diplomacy
          </button>
        </div>
      </header>

      {/* Main content */}
      <div className="flex flex-col gap-4 p-4 lg:flex-row">
        {/* Left: Map */}
        <div className="flex flex-1 justify-center">
          <GameMap
            tiles={tiles}
            selectedTile={selectedTile}
            playerAddresses={playerAddresses}
            onTileClick={setSelectedTile}
          />
        </div>

        {/* Right: Panels */}
        <div className="flex w-full flex-col gap-4 lg:w-80">
          <ResourcePanel player={player} gameState={gameState} />
          <ActionPanel
            selectedTile={selectedTile}
            tiles={tiles}
            player={player}
            gameState={gameState}
            playerAddresses={playerAddresses}
            onActionComplete={() => {
              refetch();
              setSelectedTile(null);
            }}
          />
          <EventFeed />
        </div>
      </div>
    </div>
  );
}

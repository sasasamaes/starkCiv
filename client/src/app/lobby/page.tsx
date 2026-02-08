"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { useRouter } from "next/navigation";
import { useCavos } from "@/providers/CavosProvider";
import { useContractActions } from "@/hooks/useContractActions";
import { MAX_PLAYERS } from "@/lib/constants";
import { LobbySlots } from "@/components/lobby/LobbySlots";
import { getContract } from "@/lib/contract";

const POLL_INTERVAL = 3000;
const ZERO_ADDRESS = "0x0";

export default function LobbyPage() {
  const { account, isConnected } = useCavos();
  const { joinGame, startGame } = useContractActions();
  const router = useRouter();

  const [playerAddresses, setPlayerAddresses] = useState<string[]>([]);
  const [hasJoined, setHasJoined] = useState(false);
  const [isJoining, setIsJoining] = useState(false);
  const [isStarting, setIsStarting] = useState(false);
  const [joinCode, setJoinCode] = useState("");
  const [joinMode, setJoinMode] = useState<"public" | "code" | null>(null);
  const [error, setError] = useState<string | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval>>(undefined);

  // Redirect if not connected
  useEffect(() => {
    if (!isConnected) {
      router.push("/");
    }
  }, [isConnected, router]);

  // Poll for player count
  const pollLobby = useCallback(async () => {
    try {
      const contract = getContract();
      const rawState = await contract.get_game_state();
      const state = rawState as Record<string, unknown>;
      const playerCount = Number(state.player_count ?? 0);
      const gameStarted = Boolean(state.game_started);

      // Fetch player addresses from the contract for each slot
      const addresses: string[] = [];
      for (let i = 0; i < playerCount; i++) {
        try {
          const raw = await contract.get_player_address(i);
          const addr = String(raw);
          if (addr && addr !== ZERO_ADDRESS) {
            addresses.push(addr);
          }
        } catch {
          // If get_player_address is not available, use mock addresses
          // For hackathon MVP we simulate lobby polling
          break;
        }
      }

      // If we couldn't fetch individual addresses, generate placeholder list
      if (addresses.length === 0 && playerCount > 0) {
        for (let i = 0; i < playerCount; i++) {
          if (account && i === 0 && hasJoined) {
            addresses.push(account.address);
          } else {
            addresses.push(`0x${(i + 1).toString(16).padStart(64, "0")}`);
          }
        }
      }

      setPlayerAddresses(addresses);

      // If game has started, redirect to game
      if (gameStarted) {
        router.push("/game");
      }
    } catch {
      // Silently handle polling errors -- contract may not be deployed yet
    }
  }, [account, hasJoined, router]);

  useEffect(() => {
    if (hasJoined) {
      pollLobby();
      intervalRef.current = setInterval(pollLobby, POLL_INTERVAL);
      return () => {
        if (intervalRef.current) clearInterval(intervalRef.current);
      };
    }
  }, [hasJoined, pollLobby]);

  const handleJoin = async () => {
    setIsJoining(true);
    setError(null);
    try {
      await joinGame();
      setHasJoined(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to join game");
    } finally {
      setIsJoining(false);
    }
  };

  const handleStartGame = async () => {
    setIsStarting(true);
    setError(null);
    try {
      await startGame();
      router.push("/game");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to start game");
    } finally {
      setIsStarting(false);
    }
  };

  const isFull = playerAddresses.length >= MAX_PLAYERS;

  if (!isConnected) return null;

  return (
    <div className="flex min-h-screen flex-col items-center bg-[#0b0e17] px-4 py-12">
      <div className="w-full max-w-lg">
        {/* Header */}
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-white">
            Game <span className="text-blue-400">Lobby</span>
          </h1>
          <p className="mt-2 text-sm text-slate-400">
            Waiting for players to join the match
          </p>
        </div>

        {/* Join options (if not yet joined) */}
        {!hasJoined && (
          <div className="mb-8 rounded-xl border border-slate-700 bg-[#141825] p-6">
            <h2 className="mb-4 text-lg font-semibold text-white">
              Join a Match
            </h2>

            {joinMode === null && (
              <div className="flex flex-col gap-3">
                <button
                  onClick={() => {
                    setJoinMode("public");
                    handleJoin();
                  }}
                  disabled={isJoining}
                  className="w-full rounded-lg bg-blue-600 px-6 py-3 font-medium text-white transition-colors hover:bg-blue-500 disabled:opacity-50"
                >
                  Join Public Match
                </button>
                <button
                  onClick={() => setJoinMode("code")}
                  className="w-full rounded-lg border border-slate-600 px-6 py-3 font-medium text-slate-300 transition-colors hover:bg-[#1e2333]"
                >
                  Join with Code
                </button>
              </div>
            )}

            {joinMode === "code" && !hasJoined && (
              <div className="flex flex-col gap-3">
                <input
                  type="text"
                  value={joinCode}
                  onChange={(e) => setJoinCode(e.target.value)}
                  placeholder="Enter game code"
                  className="rounded-lg border border-slate-600 bg-[#0b0e17] px-4 py-3 font-mono text-sm text-white placeholder-slate-500 outline-none focus:border-blue-500"
                />
                <div className="flex gap-2">
                  <button
                    onClick={() => setJoinMode(null)}
                    className="flex-1 rounded-lg border border-slate-600 px-4 py-2 text-sm text-slate-400 hover:bg-[#1e2333]"
                  >
                    Back
                  </button>
                  <button
                    onClick={handleJoin}
                    disabled={isJoining || !joinCode}
                    className="flex-1 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-500 disabled:opacity-50"
                  >
                    {isJoining ? "Joining..." : "Join"}
                  </button>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Error message */}
        {error && (
          <div className="mb-4 rounded-lg border border-red-500/30 bg-red-900/20 px-4 py-3 text-sm text-red-400">
            {error}
          </div>
        )}

        {/* Lobby Slots */}
        {hasJoined && (
          <div className="mb-6 rounded-xl border border-slate-700 bg-[#141825] p-6">
            <LobbySlots
              playerAddresses={playerAddresses}
              currentPlayerAddress={account?.address}
            />

            {/* Waiting indicator */}
            {!isFull && (
              <div className="mt-4 flex items-center justify-center gap-2 text-sm text-slate-500">
                <span className="inline-block h-3 w-3 animate-pulse rounded-full bg-yellow-500/50" />
                Waiting for players...
              </div>
            )}

            {/* Start game button */}
            {isFull && (
              <button
                onClick={handleStartGame}
                disabled={isStarting}
                className="mt-4 w-full rounded-lg bg-green-600 px-6 py-3 font-semibold text-white transition-colors hover:bg-green-500 disabled:opacity-50"
              >
                {isStarting ? (
                  <span className="flex items-center justify-center gap-2">
                    <span className="inline-block h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                    Starting...
                  </span>
                ) : (
                  "Start Game"
                )}
              </button>
            )}
          </div>
        )}

        {/* Back to home */}
        <div className="text-center">
          <button
            onClick={() => router.push("/")}
            className="text-sm text-slate-500 hover:text-slate-300"
          >
            Back to Home
          </button>
        </div>
      </div>
    </div>
  );
}

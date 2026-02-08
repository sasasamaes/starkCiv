"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useCavos } from "@/providers/CavosProvider";
import { abbreviateAddress } from "@/lib/utils";

export default function Home() {
  const { account, isConnected, isConnecting, login, signup, logout } =
    useCavos();
  const router = useRouter();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isSignUp, setIsSignUp] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    try {
      if (isSignUp) {
        await signup(email, password);
      } else {
        await login(email, password);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Authentication failed");
    }
  };

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-[#0b0e17]">
      {/* Background pattern */}
      <div className="pointer-events-none absolute inset-0 opacity-5">
        <div
          className="h-full w-full"
          style={{
            backgroundImage:
              "linear-gradient(rgba(59,130,246,0.3) 1px, transparent 1px), linear-gradient(90deg, rgba(59,130,246,0.3) 1px, transparent 1px)",
            backgroundSize: "60px 60px",
          }}
        />
      </div>

      <main className="relative z-10 flex flex-col items-center gap-8 px-6 text-center">
        {/* Title */}
        <div className="flex flex-col items-center gap-3">
          <h1 className="text-5xl font-bold tracking-tight text-white sm:text-6xl">
            Stark<span className="text-blue-400">Civ</span>
          </h1>
          <p className="text-lg font-medium text-yellow-400">
            Diplomacy Edition
          </p>
        </div>

        {/* Subtitle */}
        <p className="max-w-md text-base leading-relaxed text-slate-400">
          Async turn-based strategy on Starknet. Forge alliances, negotiate
          treaties, and govern your way to victory -- no warfare, pure
          diplomacy.
        </p>

        {/* Game features */}
        <div className="flex flex-wrap justify-center gap-4 text-sm text-slate-500">
          <span className="rounded-full border border-slate-700 px-3 py-1">
            4 Players
          </span>
          <span className="rounded-full border border-slate-700 px-3 py-1">
            5x5 Map
          </span>
          <span className="rounded-full border border-slate-700 px-3 py-1">
            Gasless Txs
          </span>
          <span className="rounded-full border border-slate-700 px-3 py-1">
            On-chain
          </span>
        </div>

        {/* Auth / CTA Section */}
        <div className="mt-4 flex flex-col items-center gap-4">
          {!isConnected ? (
            <form
              onSubmit={handleSubmit}
              className="flex w-full max-w-sm flex-col gap-3"
            >
              <input
                type="email"
                placeholder="Email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="rounded-lg border border-slate-700 bg-[#141825] px-4 py-3 text-sm text-white placeholder-slate-500 outline-none focus:border-blue-500"
              />
              <input
                type="password"
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                minLength={6}
                className="rounded-lg border border-slate-700 bg-[#141825] px-4 py-3 text-sm text-white placeholder-slate-500 outline-none focus:border-blue-500"
              />

              {error && (
                <p className="text-sm text-red-400">{error}</p>
              )}

              <button
                type="submit"
                disabled={isConnecting}
                className="rounded-lg bg-blue-600 px-8 py-3 text-base font-semibold text-white transition-all hover:bg-blue-500 hover:shadow-lg hover:shadow-blue-600/25 disabled:cursor-not-allowed disabled:opacity-50"
              >
                {isConnecting ? (
                  <span className="flex items-center justify-center gap-2">
                    <span className="inline-block h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                    {isSignUp ? "Creating account..." : "Signing in..."}
                  </span>
                ) : isSignUp ? (
                  "Sign Up"
                ) : (
                  "Sign In"
                )}
              </button>

              <button
                type="button"
                onClick={() => {
                  setIsSignUp(!isSignUp);
                  setError("");
                }}
                className="text-sm text-slate-400 transition-colors hover:text-blue-400"
              >
                {isSignUp
                  ? "Already have an account? Sign in"
                  : "New here? Create an account"}
              </button>
            </form>
          ) : (
            <div className="flex flex-col items-center gap-4">
              <div className="flex items-center gap-2 rounded-lg border border-slate-700 bg-[#141825] px-4 py-2">
                <div className="h-2 w-2 rounded-full bg-green-400" />
                <span className="font-mono text-sm text-slate-300">
                  {abbreviateAddress(account?.address ?? "")}
                </span>
              </div>
              <button
                onClick={() => router.push("/lobby")}
                className="rounded-lg bg-green-600 px-8 py-4 text-lg font-semibold text-white transition-all hover:bg-green-500 hover:shadow-lg hover:shadow-green-600/25"
              >
                Enter Lobby
              </button>
              <button
                onClick={logout}
                className="text-sm text-slate-500 transition-colors hover:text-slate-300"
              >
                Sign out
              </button>
            </div>
          )}
        </div>

        {/* Footer info */}
        <p className="mt-8 text-xs text-slate-600">
          Built on Starknet Sepolia -- Powered by Cavos Aegis SDK
        </p>
      </main>
    </div>
  );
}

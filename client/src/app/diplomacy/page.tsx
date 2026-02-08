"use client";

import { useState, useEffect, useMemo } from "react";
import { useRouter } from "next/navigation";
import { useCavos } from "@/providers/CavosProvider";
import { useTreaties } from "@/hooks/useTreaties";
import { TreatyList } from "@/components/diplomacy/TreatyList";
import { TreatyModal } from "@/components/diplomacy/TreatyModal";

type Tab = "incoming" | "active" | "history";

export default function DiplomacyPage() {
  const { account, isConnected } = useCavos();
  const router = useRouter();
  const { incoming, active, history, isLoading, refetch } = useTreaties();
  const [activeTab, setActiveTab] = useState<Tab>("incoming");
  const [showPropose, setShowPropose] = useState(false);

  const myAddress = account?.address ?? "";

  // For MVP, generate player addresses list
  const playerAddresses = useMemo(() => {
    if (!account) return [];
    return [account.address];
  }, [account]);

  // Redirect if not connected
  useEffect(() => {
    if (!isConnected) {
      router.push("/");
    }
  }, [isConnected, router]);

  if (!isConnected) return null;

  const tabs: { key: Tab; label: string; count: number }[] = [
    { key: "incoming", label: "Incoming", count: incoming.length },
    { key: "active", label: "Active", count: active.length },
    { key: "history", label: "History", count: history.length },
  ];

  const currentTreaties =
    activeTab === "incoming"
      ? incoming
      : activeTab === "active"
        ? active
        : history;

  return (
    <div className="min-h-screen bg-[#0b0e17]">
      {/* Header */}
      <header className="flex items-center justify-between border-b border-slate-700 bg-[#141825] px-4 py-3">
        <div className="flex items-center gap-4">
          <button
            onClick={() => router.push("/game")}
            className="text-sm text-slate-400 hover:text-white"
          >
            &larr; Back to Game
          </button>
          <h1 className="text-lg font-bold text-white">
            {"\u{1F4DC}"} Diplomacy
          </h1>
        </div>
        <button
          onClick={() => setShowPropose(true)}
          className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-500"
        >
          Propose Treaty
        </button>
      </header>

      {/* Main content */}
      <div className="mx-auto max-w-2xl px-4 py-6">
        {/* Tabs */}
        <div className="mb-6 flex gap-1 rounded-lg bg-[#141825] p-1">
          {tabs.map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={`flex-1 rounded-lg px-4 py-2.5 text-sm font-medium transition-colors ${
                activeTab === tab.key
                  ? "bg-blue-600 text-white"
                  : "text-slate-400 hover:text-white"
              }`}
            >
              {tab.label}
              {tab.count > 0 && (
                <span
                  className={`ml-2 inline-flex h-5 w-5 items-center justify-center rounded-full text-[10px] ${
                    activeTab === tab.key
                      ? "bg-blue-400/30 text-white"
                      : "bg-slate-700 text-slate-300"
                  }`}
                >
                  {tab.count}
                </span>
              )}
            </button>
          ))}
        </div>

        {/* Loading */}
        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <span className="inline-block h-6 w-6 animate-spin rounded-full border-2 border-blue-500 border-t-transparent" />
          </div>
        ) : (
          <TreatyList
            treaties={currentTreaties}
            tab={activeTab}
            myAddress={myAddress}
            onActionComplete={refetch}
          />
        )}
      </div>

      {/* Propose treaty modal */}
      {showPropose && (
        <TreatyModal
          playerAddresses={playerAddresses}
          myAddress={myAddress}
          onClose={() => setShowPropose(false)}
          onComplete={() => {
            setShowPropose(false);
            refetch();
          }}
        />
      )}
    </div>
  );
}

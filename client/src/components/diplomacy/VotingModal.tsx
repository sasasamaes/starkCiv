"use client";

import { useState, useEffect, useCallback } from "react";
import { useContractActions } from "@/hooks/useContractActions";
import { getContract } from "@/lib/contract";
import { PROPOSAL_NAMES, ProposalKind } from "@/lib/constants";
import { abbreviateAddress } from "@/lib/utils";
import { Toast } from "@/components/ui/Toast";
import type { Proposal } from "@/lib/types";

interface VotingModalProps {
  onClose: () => void;
  playerAddresses: string[];
}

function parseProposal(raw: Record<string, unknown>): Proposal {
  return {
    id: Number(raw.id ?? 0),
    kind: Number(raw.kind ?? 0),
    target: String(raw.target ?? "0x0"),
    votesFor: Number(raw.votes_for ?? 0),
    votesAgainst: Number(raw.votes_against ?? 0),
    executed: Boolean(raw.executed),
    era: Number(raw.era ?? 0),
  };
}

export function VotingModal({ onClose, playerAddresses }: VotingModalProps) {
  const { vote, executeProposal } = useContractActions();
  const [proposal, setProposal] = useState<Proposal | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isVoting, setIsVoting] = useState(false);
  const [toast, setToast] = useState<{
    message: string;
    type: "success" | "error";
  } | null>(null);

  const fetchProposal = useCallback(async () => {
    try {
      const contract = getContract();
      const raw = await contract.get_active_proposal();
      const p = parseProposal(raw as Record<string, unknown>);
      // If proposal id is 0 and not executed, there may be no active proposal
      setProposal(p.id > 0 ? p : null);
    } catch {
      setProposal(null);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchProposal();
  }, [fetchProposal]);

  const handleVote = async (support: boolean) => {
    if (!proposal) return;
    setIsVoting(true);
    try {
      await vote(proposal.id, support);
      setToast({
        message: `Vote ${support ? "for" : "against"} submitted`,
        type: "success",
      });
      fetchProposal();
    } catch (err) {
      setToast({
        message: err instanceof Error ? err.message : "Vote failed",
        type: "error",
      });
    } finally {
      setIsVoting(false);
    }
  };

  const handleExecute = async () => {
    if (!proposal) return;
    setIsVoting(true);
    try {
      await executeProposal(proposal.id);
      setToast({ message: "Proposal executed", type: "success" });
      fetchProposal();
    } catch (err) {
      setToast({
        message: err instanceof Error ? err.message : "Execution failed",
        type: "error",
      });
    } finally {
      setIsVoting(false);
    }
  };

  const totalVotes = proposal
    ? proposal.votesFor + proposal.votesAgainst
    : 0;
  const majority = playerAddresses.length > 0
    ? Math.ceil((playerAddresses.length * 3) / 4)
    : 3;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
      <div className="mx-4 w-full max-w-md rounded-xl border border-slate-700 bg-[#141825] p-6 shadow-xl">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold text-white">
            {"\u{1F5F3}\u{FE0F}"} Active Proposal
          </h3>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-white"
          >
            X
          </button>
        </div>

        {isLoading ? (
          <div className="flex items-center justify-center py-8">
            <span className="inline-block h-6 w-6 animate-spin rounded-full border-2 border-blue-500 border-t-transparent" />
          </div>
        ) : !proposal ? (
          <div className="py-8 text-center text-sm text-slate-500">
            No active proposals this era.
          </div>
        ) : (
          <div className="mt-4 flex flex-col gap-4">
            {/* Proposal info */}
            <div className="rounded-lg border border-slate-700 bg-[#0b0e17] p-4">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium text-white">
                  {PROPOSAL_NAMES[proposal.kind as ProposalKind] ?? "Unknown"}
                </span>
                <span className="text-xs text-slate-500">
                  Era {proposal.era}
                </span>
              </div>
              <p className="mt-1 font-mono text-xs text-slate-400">
                Target: {abbreviateAddress(proposal.target)}
              </p>
            </div>

            {/* Vote counts */}
            <div className="grid grid-cols-2 gap-3">
              <div className="rounded-lg border border-green-500/30 bg-green-900/10 px-4 py-3 text-center">
                <span className="block text-2xl font-bold text-green-400">
                  {proposal.votesFor}
                </span>
                <span className="text-xs text-green-400/60">For</span>
              </div>
              <div className="rounded-lg border border-red-500/30 bg-red-900/10 px-4 py-3 text-center">
                <span className="block text-2xl font-bold text-red-400">
                  {proposal.votesAgainst}
                </span>
                <span className="text-xs text-red-400/60">Against</span>
              </div>
            </div>

            {/* Progress */}
            <div className="text-center text-xs text-slate-500">
              {totalVotes} / {majority} votes needed for majority
            </div>

            {/* Voting buttons */}
            {!proposal.executed && (
              <div className="flex gap-3">
                <button
                  onClick={() => handleVote(true)}
                  disabled={isVoting}
                  className="flex-1 rounded-lg bg-green-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-green-500 disabled:opacity-50"
                >
                  Vote For
                </button>
                <button
                  onClick={() => handleVote(false)}
                  disabled={isVoting}
                  className="flex-1 rounded-lg bg-red-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-red-500 disabled:opacity-50"
                >
                  Vote Against
                </button>
              </div>
            )}

            {/* Execute button (if enough votes) */}
            {!proposal.executed && proposal.votesFor >= majority && (
              <button
                onClick={handleExecute}
                disabled={isVoting}
                className="rounded-lg bg-yellow-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-yellow-500 disabled:opacity-50"
              >
                Execute Proposal
              </button>
            )}

            {proposal.executed && (
              <div className="rounded-lg border border-blue-500/30 bg-blue-900/20 px-4 py-2 text-center text-sm text-blue-400">
                Proposal has been executed
              </div>
            )}
          </div>
        )}
      </div>

      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
    </div>
  );
}

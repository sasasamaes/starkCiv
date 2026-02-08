"use client";

import { useState } from "react";
import { useContractActions } from "@/hooks/useContractActions";
import { TreatyStatus, TreatyType, TREATY_NAMES } from "@/lib/constants";
import { abbreviateAddress } from "@/lib/utils";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { Toast } from "@/components/ui/Toast";
import type { Treaty } from "@/lib/types";

interface TreatyListProps {
  treaties: Treaty[];
  tab: "incoming" | "active" | "history";
  myAddress: string;
  onActionComplete: () => void;
}

const STATUS_LABELS: Record<TreatyStatus, string> = {
  [TreatyStatus.Pending]: "Pending",
  [TreatyStatus.Active]: "Active",
  [TreatyStatus.Completed]: "Completed",
  [TreatyStatus.Broken]: "Broken",
};

const STATUS_COLORS: Record<TreatyStatus, string> = {
  [TreatyStatus.Pending]: "text-yellow-400 bg-yellow-900/20 border-yellow-500/30",
  [TreatyStatus.Active]: "text-green-400 bg-green-900/20 border-green-500/30",
  [TreatyStatus.Completed]: "text-blue-400 bg-blue-900/20 border-blue-500/30",
  [TreatyStatus.Broken]: "text-red-400 bg-red-900/20 border-red-500/30",
};

export function TreatyList({
  treaties,
  tab,
  myAddress,
  onActionComplete,
}: TreatyListProps) {
  const { acceptTreaty, breakTreaty } = useContractActions();
  const [pendingAction, setPendingAction] = useState<{
    title: string;
    message: string;
    execute: () => Promise<unknown>;
  } | null>(null);
  const [isExecuting, setIsExecuting] = useState(false);
  const [toast, setToast] = useState<{
    message: string;
    type: "success" | "error";
  } | null>(null);

  const handleConfirm = async () => {
    if (!pendingAction) return;
    setIsExecuting(true);
    try {
      await pendingAction.execute();
      setToast({ message: "Treaty action submitted", type: "success" });
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

  if (treaties.length === 0) {
    return (
      <div className="py-8 text-center text-sm text-slate-500">
        No {tab} treaties.
      </div>
    );
  }

  return (
    <>
      <div className="flex flex-col gap-2">
        {treaties.map((treaty) => {
          const isFrom = treaty.from.toLowerCase() === myAddress.toLowerCase();
          const otherParty = isFrom ? treaty.to : treaty.from;
          const treatyName =
            TREATY_NAMES[treaty.treatyType as TreatyType] ?? "Unknown";

          return (
            <div
              key={treaty.id}
              className="rounded-lg border border-slate-700 bg-[#0b0e17] p-4"
            >
              <div className="flex items-start justify-between">
                <div className="flex flex-col gap-1">
                  <span className="text-sm font-medium text-white">
                    {treatyName}
                  </span>
                  <span className="font-mono text-xs text-slate-400">
                    {isFrom ? "To" : "From"}: {abbreviateAddress(otherParty)}
                  </span>
                  <span className="text-xs text-slate-500">
                    Turns {treaty.startTurn} - {treaty.endTurn}
                  </span>
                </div>
                <span
                  className={`rounded-full border px-2 py-0.5 text-[10px] font-medium ${
                    STATUS_COLORS[treaty.status as TreatyStatus] ?? ""
                  }`}
                >
                  {STATUS_LABELS[treaty.status as TreatyStatus] ?? "Unknown"}
                </span>
              </div>

              {/* Actions */}
              <div className="mt-3 flex gap-2">
                {tab === "incoming" && (
                  <button
                    onClick={() =>
                      setPendingAction({
                        title: "Accept Treaty",
                        message: `Accept ${treatyName} from ${abbreviateAddress(otherParty)}?`,
                        execute: () => acceptTreaty(treaty.id),
                      })
                    }
                    className="rounded-lg bg-green-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-green-500"
                  >
                    Accept
                  </button>
                )}
                {tab === "active" && (
                  <button
                    onClick={() =>
                      setPendingAction({
                        title: "Break Treaty",
                        message: `Break ${treatyName} with ${abbreviateAddress(otherParty)}? This costs -2 Reputation.`,
                        execute: () => breakTreaty(treaty.id),
                      })
                    }
                    className="rounded-lg bg-red-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-red-500"
                  >
                    Break Treaty
                  </button>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {pendingAction && (
        <ConfirmDialog
          title={pendingAction.title}
          message={pendingAction.message}
          onConfirm={handleConfirm}
          onCancel={() => setPendingAction(null)}
          isLoading={isExecuting}
        />
      )}

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

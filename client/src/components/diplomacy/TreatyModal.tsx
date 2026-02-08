"use client";

import { useState } from "react";
import { useContractActions } from "@/hooks/useContractActions";
import { TreatyType, TREATY_NAMES } from "@/lib/constants";
import { abbreviateAddress } from "@/lib/utils";
import { Toast } from "@/components/ui/Toast";

interface TreatyModalProps {
  playerAddresses: string[];
  myAddress: string;
  onClose: () => void;
  onComplete: () => void;
}

export function TreatyModal({
  playerAddresses,
  myAddress,
  onClose,
  onComplete,
}: TreatyModalProps) {
  const { proposeTreaty } = useContractActions();
  const [targetAddr, setTargetAddr] = useState("");
  const [treatyType, setTreatyType] = useState<TreatyType>(
    TreatyType.NonAggression
  );
  const [duration, setDuration] = useState(5);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [toast, setToast] = useState<{
    message: string;
    type: "success" | "error";
  } | null>(null);

  const otherPlayers = playerAddresses.filter(
    (a) => a.toLowerCase() !== myAddress.toLowerCase()
  );

  const handleSubmit = async () => {
    if (!targetAddr) return;
    setIsSubmitting(true);
    try {
      await proposeTreaty(targetAddr, treatyType, duration);
      setToast({ message: "Treaty proposed!", type: "success" });
      onComplete();
    } catch (err) {
      setToast({
        message: err instanceof Error ? err.message : "Failed to propose treaty",
        type: "error",
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm">
      <div className="mx-4 w-full max-w-md rounded-xl border border-slate-700 bg-[#141825] p-6 shadow-xl">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold text-white">Propose Treaty</h3>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-white"
          >
            X
          </button>
        </div>

        <div className="mt-4 flex flex-col gap-4">
          {/* Target player */}
          <div>
            <label className="mb-1 block text-xs font-medium text-slate-400">
              Target Player
            </label>
            <input
              type="text"
              value={targetAddr}
              onChange={(e) => setTargetAddr(e.target.value)}
              placeholder="Player address (0x...)"
              className="w-full rounded-lg border border-slate-600 bg-[#0b0e17] px-3 py-2 font-mono text-xs text-white placeholder-slate-500 outline-none focus:border-blue-500"
            />
            {otherPlayers.length > 0 && (
              <div className="mt-2 flex flex-wrap gap-1">
                {otherPlayers.map((addr) => (
                  <button
                    key={addr}
                    onClick={() => setTargetAddr(addr)}
                    className={`rounded border px-2 py-0.5 font-mono text-[10px] transition-colors ${
                      targetAddr === addr
                        ? "border-blue-500 bg-blue-900/30 text-blue-300"
                        : "border-slate-600 text-slate-400 hover:bg-[#1e2333]"
                    }`}
                  >
                    {abbreviateAddress(addr)}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Treaty type */}
          <div>
            <label className="mb-1 block text-xs font-medium text-slate-400">
              Treaty Type
            </label>
            <select
              value={treatyType}
              onChange={(e) => setTreatyType(Number(e.target.value))}
              className="w-full rounded-lg border border-slate-600 bg-[#0b0e17] px-3 py-2 text-sm text-white outline-none"
            >
              <option value={TreatyType.NonAggression}>
                {TREATY_NAMES[TreatyType.NonAggression]}
              </option>
              <option value={TreatyType.TradeAgreement}>
                {TREATY_NAMES[TreatyType.TradeAgreement]}
              </option>
              <option value={TreatyType.Alliance}>
                {TREATY_NAMES[TreatyType.Alliance]}
              </option>
            </select>
          </div>

          {/* Duration */}
          <div>
            <label className="mb-1 block text-xs font-medium text-slate-400">
              Duration (turns)
            </label>
            <input
              type="number"
              min={1}
              max={25}
              value={duration}
              onChange={(e) => setDuration(Math.max(1, Number(e.target.value)))}
              className="w-full rounded-lg border border-slate-600 bg-[#0b0e17] px-3 py-2 text-sm text-white outline-none"
            />
          </div>

          {/* Buttons */}
          <div className="flex gap-3">
            <button
              onClick={onClose}
              className="flex-1 rounded-lg border border-slate-600 px-4 py-2 text-sm text-slate-300 hover:bg-[#1e2333]"
            >
              Cancel
            </button>
            <button
              onClick={handleSubmit}
              disabled={isSubmitting || !targetAddr}
              className="flex-1 rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-500 disabled:opacity-50"
            >
              {isSubmitting ? "Proposing..." : "Propose"}
            </button>
          </div>
        </div>
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

"use client";

import { useState, useEffect } from "react";

const STORAGE_KEY = "starkciv_tutorial_seen";

export function TutorialOverlay() {
  const [show, setShow] = useState(false);

  useEffect(() => {
    const seen = localStorage.getItem(STORAGE_KEY);
    if (!seen) {
      setShow(true);
    }
  }, []);

  const handleDismiss = () => {
    localStorage.setItem(STORAGE_KEY, "1");
    setShow(false);
  };

  if (!show) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm">
      <div className="mx-4 w-full max-w-lg rounded-xl border border-slate-700 bg-[#141825] p-6 shadow-xl">
        <h2 className="text-xl font-bold text-white">
          Welcome to Stark<span className="text-blue-400">Civ</span>
        </h2>
        <p className="mt-1 text-sm text-yellow-400">Diplomacy Edition</p>

        <div className="mt-4 flex flex-col gap-3 text-sm text-slate-300">
          <div className="rounded-lg bg-[#0b0e17] p-3">
            <span className="font-medium text-white">Goal:</span> Reach 10
            Reputation + build an Embassy + complete 2 treaties to win.
          </div>

          <div className="rounded-lg bg-[#0b0e17] p-3">
            <span className="font-medium text-white">Turns:</span> 1 action per
            turn. Each Era lasts 5 turns with a global vote at the end.
          </div>

          <div className="rounded-lg bg-[#0b0e17] p-3">
            <span className="font-medium text-white">Actions:</span>
            <ul className="mt-1 ml-4 list-disc text-slate-400">
              <li>
                <span className="text-white">Expand</span> -- claim adjacent empty tiles
              </li>
              <li>
                <span className="text-white">Build</span> -- Farm ({"\u{1F33E}"}), Market ({"\u{1F3EA}"}), Embassy ({"\u{1F3F0}"})
              </li>
              <li>
                <span className="text-white">Train Guard</span> ({"\u{1F6E1}\u{FE0F}"}) -- defend your tiles
              </li>
              <li>
                <span className="text-white">Send Aid</span> -- share resources, gain reputation
              </li>
            </ul>
          </div>

          <div className="rounded-lg bg-[#0b0e17] p-3">
            <span className="font-medium text-white">Diplomacy:</span> Propose
            treaties, vote on global proposals, and cooperate (or betray) your
            way to victory. Breaking treaties costs -2 Reputation.
          </div>
        </div>

        <button
          onClick={handleDismiss}
          className="mt-6 w-full rounded-lg bg-blue-600 py-3 text-sm font-semibold text-white transition-colors hover:bg-blue-500"
        >
          Got it!
        </button>
      </div>
    </div>
  );
}

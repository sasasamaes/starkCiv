"use client";

import { useCallback } from "react";
import { useCavos } from "@/providers/CavosProvider";
import { GAME_CONTRACT_ADDRESS } from "@/lib/contract";

export function useContractActions() {
  const { account } = useCavos();

  const execute = useCallback(
    async (entrypoint: string, calldata: (string | number)[] = []) => {
      if (!account) throw new Error("Not connected");
      return account.execute({
        contractAddress: GAME_CONTRACT_ADDRESS,
        entrypoint,
        calldata,
      });
    },
    [account]
  );

  const joinGame = useCallback(() => execute("join_game"), [execute]);
  const startGame = useCallback(() => execute("start_game"), [execute]);
  const endTurn = useCallback(() => execute("end_turn"), [execute]);

  const expand = useCallback(
    (tileId: number) => execute("expand", [tileId]),
    [execute]
  );

  const build = useCallback(
    (tileId: number, buildingType: number) =>
      execute("build", [tileId, buildingType]),
    [execute]
  );

  const trainGuard = useCallback(
    (tileId: number) => execute("train_guard", [tileId]),
    [execute]
  );

  const sendAid = useCallback(
    (to: string, resource: number, amount: number) =>
      execute("send_aid", [to, resource, amount]),
    [execute]
  );

  const proposeTreaty = useCallback(
    (to: string, treatyType: number, duration: number) =>
      execute("propose_treaty", [to, treatyType, duration]),
    [execute]
  );

  const acceptTreaty = useCallback(
    (treatyId: number) => execute("accept_treaty", [treatyId]),
    [execute]
  );

  const breakTreaty = useCallback(
    (treatyId: number) => execute("break_treaty", [treatyId]),
    [execute]
  );

  const createProposal = useCallback(
    (kind: number, target: string) =>
      execute("create_proposal", [kind, target]),
    [execute]
  );

  const vote = useCallback(
    (proposalId: number, support: boolean) =>
      execute("vote", [proposalId, support ? 1 : 0]),
    [execute]
  );

  const executeProposal = useCallback(
    (proposalId: number) => execute("execute_proposal", [proposalId]),
    [execute]
  );

  return {
    joinGame,
    startGame,
    endTurn,
    expand,
    build,
    trainGuard,
    sendAid,
    proposeTreaty,
    acceptTreaty,
    breakTreaty,
    createProposal,
    vote,
    executeProposal,
  };
}

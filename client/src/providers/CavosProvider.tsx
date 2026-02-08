"use client";

import React, {
  createContext,
  useContext,
  useState,
  useCallback,
  useMemo,
  ReactNode,
} from "react";
import { AegisProvider, useAegis } from "@cavos/aegis";
import type { TransactionResult } from "@cavos/aegis";

interface AegisAccount {
  address: string;
  execute: (call: {
    contractAddress: string;
    entrypoint: string;
    calldata: (string | number)[];
  }) => Promise<{ transaction_hash: string }>;
}

interface CavosContextType {
  account: AegisAccount | null;
  isConnected: boolean;
  isConnecting: boolean;
  login: (email: string, password: string) => Promise<void>;
  signup: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
}

const CavosContext = createContext<CavosContextType>({
  account: null,
  isConnected: false,
  isConnecting: false,
  login: async () => {},
  signup: async () => {},
  logout: async () => {},
});

export function useCavos() {
  return useContext(CavosContext);
}

function CavosInner({ children }: { children: ReactNode }) {
  const { aegisAccount, isConnected, currentAddress, signIn, signUp, signOut } =
    useAegis();
  const [isConnecting, setIsConnecting] = useState(false);

  const account: AegisAccount | null = useMemo(() => {
    if (!isConnected || !currentAddress) return null;
    return {
      address: currentAddress,
      execute: async (call) => {
        const result: TransactionResult = await aegisAccount.execute(
          call.contractAddress,
          call.entrypoint,
          call.calldata
        );
        return { transaction_hash: result.transactionHash };
      },
    };
  }, [isConnected, currentAddress, aegisAccount]);

  const login = useCallback(
    async (email: string, password: string) => {
      setIsConnecting(true);
      try {
        await signIn(email, password);
      } finally {
        setIsConnecting(false);
      }
    },
    [signIn]
  );

  const signup = useCallback(
    async (email: string, password: string) => {
      setIsConnecting(true);
      try {
        await signUp(email, password);
      } finally {
        setIsConnecting(false);
      }
    },
    [signUp]
  );

  const handleLogout = useCallback(async () => {
    await signOut();
  }, [signOut]);

  return (
    <CavosContext.Provider
      value={{
        account,
        isConnected: !!account,
        isConnecting,
        login,
        signup,
        logout: handleLogout,
      }}
    >
      {children}
    </CavosContext.Provider>
  );
}

interface CavosProviderProps {
  children: ReactNode;
}

export function CavosProvider({ children }: CavosProviderProps) {
  const network = (process.env.NEXT_PUBLIC_NETWORK as "SN_MAINNET" | "SN_SEPOLIA" | "SN_DEVNET") ?? "SN_SEPOLIA";

  return (
    <AegisProvider
      config={{
        network,
        appName: "StarkCiv",
        appId: process.env.NEXT_PUBLIC_CAVOS_APP_ID ?? "",
        walletMode: "social-login",
      }}
    >
      <CavosInner>{children}</CavosInner>
    </AegisProvider>
  );
}

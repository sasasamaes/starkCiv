"use client";

import React, { createContext, useContext, useState, useCallback, ReactNode } from "react";

// Cavos Aegis SDK types (simplified for MVP)
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
  login: () => Promise<void>;
  logout: () => void;
}

const CavosContext = createContext<CavosContextType>({
  account: null,
  isConnected: false,
  isConnecting: false,
  login: async () => {},
  logout: () => {},
});

export function useCavos() {
  return useContext(CavosContext);
}

interface CavosProviderProps {
  children: ReactNode;
}

export function CavosProvider({ children }: CavosProviderProps) {
  const [account, setAccount] = useState<AegisAccount | null>(null);
  const [isConnecting, setIsConnecting] = useState(false);

  const login = useCallback(async () => {
    setIsConnecting(true);
    try {
      // In production, this would use the actual Cavos Aegis SDK:
      // const aegis = new AegisSDK({ appId: process.env.NEXT_PUBLIC_CAVOS_APP_ID });
      // const account = await aegis.login({ method: 'social' });
      // For now, we simulate the connection
      const mockAccount: AegisAccount = {
        address: "0x0",
        execute: async (call) => {
          console.log("Executing:", call);
          return { transaction_hash: "0x0" };
        },
      };
      setAccount(mockAccount);
    } finally {
      setIsConnecting(false);
    }
  }, []);

  const logout = useCallback(() => {
    setAccount(null);
  }, []);

  return (
    <CavosContext.Provider
      value={{
        account,
        isConnected: !!account,
        isConnecting,
        login,
        logout,
      }}
    >
      {children}
    </CavosContext.Provider>
  );
}

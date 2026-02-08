/**
 * Abbreviate a hex address: 0x1234...abcd
 */
export function abbreviateAddress(addr: string): string {
  if (!addr || addr.length < 10) return addr;
  return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
}

/**
 * Player colors indexed by player slot (0-3).
 * Player 1 = blue, Player 2 = red, Player 3 = green, Player 4 = yellow
 */
export const PLAYER_COLORS = [
  { name: "blue", bg: "bg-blue-600", border: "border-blue-500", text: "text-blue-400", hex: "#3b82f6", bgLight: "bg-blue-900/40" },
  { name: "red", bg: "bg-red-600", border: "border-red-500", text: "text-red-400", hex: "#ef4444", bgLight: "bg-red-900/40" },
  { name: "green", bg: "bg-green-600", border: "border-green-500", text: "text-green-400", hex: "#22c55e", bgLight: "bg-green-900/40" },
  { name: "yellow", bg: "bg-yellow-600", border: "border-yellow-500", text: "text-yellow-400", hex: "#eab308", bgLight: "bg-yellow-900/40" },
] as const;

const ZERO_ADDRESS = "0x0";

/**
 * Get the player index (0-3) for an address from a list of player addresses.
 * Returns -1 if not found.
 */
export function getPlayerIndex(addr: string, playerAddresses: string[]): number {
  if (!addr || addr === ZERO_ADDRESS) return -1;
  return playerAddresses.findIndex((a) => a.toLowerCase() === addr.toLowerCase());
}

/**
 * Get color config for a player address given the list of player addresses.
 */
export function getPlayerColor(addr: string, playerAddresses: string[]) {
  const idx = getPlayerIndex(addr, playerAddresses);
  if (idx < 0 || idx >= PLAYER_COLORS.length) return null;
  return PLAYER_COLORS[idx];
}

/**
 * Building emoji icons
 */
export const BUILDING_ICONS: Record<number, string> = {
  0: "",        // None
  1: "\u{1F3DB}\u{FE0F}", // City
  2: "\u{1F33E}",         // Farm
  3: "\u{1F3EA}",         // Market
  4: "\u{1F3F0}",         // Embassy
};

/**
 * Guard icon
 */
export const GUARD_ICON = "\u{1F6E1}\u{FE0F}";

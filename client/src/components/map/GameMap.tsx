"use client";

import { MAP_SIZE } from "@/lib/constants";
import type { Tile as TileType } from "@/lib/types";
import { Tile } from "./Tile";

interface GameMapProps {
  tiles: TileType[];
  selectedTile: number | null;
  playerAddresses: string[];
  onTileClick: (tileId: number) => void;
}

export function GameMap({
  tiles,
  selectedTile,
  playerAddresses,
  onTileClick,
}: GameMapProps) {
  return (
    <div className="flex flex-col items-center gap-2">
      <h2 className="text-sm font-semibold uppercase tracking-wider text-slate-400">
        World Map
      </h2>
      <div
        className="grid gap-1"
        style={{
          gridTemplateColumns: `repeat(${MAP_SIZE}, 1fr)`,
        }}
      >
        {tiles.map((tile, idx) => (
          <Tile
            key={idx}
            tileId={idx}
            tile={tile}
            isSelected={selectedTile === idx}
            playerAddresses={playerAddresses}
            onClick={onTileClick}
          />
        ))}
      </div>
    </div>
  );
}

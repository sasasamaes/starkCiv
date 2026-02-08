"use client";

import type { Tile as TileType } from "@/lib/types";
import { BUILDING_ICONS, GUARD_ICON, getPlayerColor } from "@/lib/utils";
import { BuildingType, BUILDING_NAMES } from "@/lib/constants";

interface TileProps {
  tileId: number;
  tile: TileType;
  isSelected: boolean;
  playerAddresses: string[];
  onClick: (tileId: number) => void;
}

const ZERO_ADDRESS = "0x0";

export function Tile({
  tileId,
  tile,
  isSelected,
  playerAddresses,
  onClick,
}: TileProps) {
  const isOwned = tile.owner && tile.owner !== ZERO_ADDRESS;
  const color = isOwned ? getPlayerColor(tile.owner, playerAddresses) : null;
  const buildingIcon = BUILDING_ICONS[tile.building] ?? "";
  const buildingName = BUILDING_NAMES[tile.building as BuildingType] ?? "";

  return (
    <button
      onClick={() => onClick(tileId)}
      title={
        isOwned
          ? `Tile ${tileId} | ${buildingName}${tile.guard ? " + Guard" : ""}`
          : `Tile ${tileId} | Unclaimed`
      }
      className={`relative flex h-16 w-16 flex-col items-center justify-center rounded border text-xs transition-all sm:h-20 sm:w-20 ${
        isSelected
          ? "border-white ring-2 ring-white/50"
          : "border-slate-700 hover:border-slate-500"
      } ${
        isOwned && color
          ? ""
          : "bg-[#1a1f2e]"
      }`}
      style={
        isOwned && color
          ? { backgroundColor: `${color.hex}20`, borderColor: `${color.hex}60` }
          : undefined
      }
    >
      {/* Building icon */}
      {tile.building !== BuildingType.None && (
        <span className="text-base sm:text-lg leading-none">{buildingIcon}</span>
      )}

      {/* Guard icon */}
      {tile.guard && (
        <span className="text-[10px] leading-none">{GUARD_ICON}</span>
      )}

      {/* Tile ID (faded) */}
      <span className="absolute bottom-0.5 right-1 text-[9px] text-slate-600">
        {tileId}
      </span>

      {/* Ownership dot */}
      {isOwned && color && (
        <span
          className="absolute left-1 top-1 h-2 w-2 rounded-full"
          style={{ backgroundColor: color.hex }}
        />
      )}
    </button>
  );
}

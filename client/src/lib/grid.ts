import { MAP_SIZE, TOTAL_TILES } from "./constants";

/**
 * Convert a tile ID (0-24) to grid coordinates {x, y}.
 * tile_id = y * MAP_SIZE + x
 */
export function tileToCoords(tileId: number): { x: number; y: number } {
  if (tileId < 0 || tileId >= TOTAL_TILES) {
    throw new Error(`Invalid tile ID: ${tileId}. Must be 0-${TOTAL_TILES - 1}`);
  }
  return {
    x: tileId % MAP_SIZE,
    y: Math.floor(tileId / MAP_SIZE),
  };
}

/**
 * Convert grid coordinates to a tile ID.
 */
export function coordsToTile(x: number, y: number): number {
  if (x < 0 || x >= MAP_SIZE || y < 0 || y >= MAP_SIZE) {
    throw new Error(`Invalid coordinates: (${x}, ${y}). Must be 0-${MAP_SIZE - 1}`);
  }
  return y * MAP_SIZE + x;
}

/**
 * Check if two tiles are orthogonally adjacent (no diagonals).
 */
export function isAdjacent(a: number, b: number): boolean {
  if (a < 0 || a >= TOTAL_TILES || b < 0 || b >= TOTAL_TILES) {
    return false;
  }
  const coordsA = tileToCoords(a);
  const coordsB = tileToCoords(b);
  const dx = Math.abs(coordsA.x - coordsB.x);
  const dy = Math.abs(coordsA.y - coordsB.y);
  return dx + dy === 1;
}

/**
 * Get all orthogonally adjacent tile IDs for a given tile.
 */
export function getAdjacentTiles(tileId: number): number[] {
  if (tileId < 0 || tileId >= TOTAL_TILES) {
    throw new Error(`Invalid tile ID: ${tileId}. Must be 0-${TOTAL_TILES - 1}`);
  }
  const { x, y } = tileToCoords(tileId);
  const adjacent: number[] = [];

  if (x > 0) adjacent.push(coordsToTile(x - 1, y));           // left
  if (x < MAP_SIZE - 1) adjacent.push(coordsToTile(x + 1, y)); // right
  if (y > 0) adjacent.push(coordsToTile(x, y - 1));           // up
  if (y < MAP_SIZE - 1) adjacent.push(coordsToTile(x, y + 1)); // down

  return adjacent;
}

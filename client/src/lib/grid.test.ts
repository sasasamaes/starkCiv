import { describe, it, expect } from "vitest";
import { tileToCoords, coordsToTile, isAdjacent, getAdjacentTiles } from "./grid";

describe("tileToCoords", () => {
  it("converts tile 0 to (0,0)", () => {
    expect(tileToCoords(0)).toEqual({ x: 0, y: 0 });
  });

  it("converts tile 4 to (4,0)", () => {
    expect(tileToCoords(4)).toEqual({ x: 4, y: 0 });
  });

  it("converts tile 12 to (2,2) - center", () => {
    expect(tileToCoords(12)).toEqual({ x: 2, y: 2 });
  });

  it("converts tile 20 to (0,4)", () => {
    expect(tileToCoords(20)).toEqual({ x: 0, y: 4 });
  });

  it("converts tile 24 to (4,4)", () => {
    expect(tileToCoords(24)).toEqual({ x: 4, y: 4 });
  });

  it("throws for negative tile ID", () => {
    expect(() => tileToCoords(-1)).toThrow("Invalid tile ID");
  });

  it("throws for tile ID >= 25", () => {
    expect(() => tileToCoords(25)).toThrow("Invalid tile ID");
  });
});

describe("coordsToTile", () => {
  it("converts (0,0) to tile 0", () => {
    expect(coordsToTile(0, 0)).toBe(0);
  });

  it("converts (4,0) to tile 4", () => {
    expect(coordsToTile(4, 0)).toBe(4);
  });

  it("converts (2,2) to tile 12 - center", () => {
    expect(coordsToTile(2, 2)).toBe(12);
  });

  it("converts (0,4) to tile 20", () => {
    expect(coordsToTile(0, 4)).toBe(20);
  });

  it("converts (4,4) to tile 24", () => {
    expect(coordsToTile(4, 4)).toBe(24);
  });

  it("throws for out of bounds x", () => {
    expect(() => coordsToTile(5, 0)).toThrow("Invalid coordinates");
  });

  it("throws for out of bounds y", () => {
    expect(() => coordsToTile(0, 5)).toThrow("Invalid coordinates");
  });

  it("throws for negative coordinates", () => {
    expect(() => coordsToTile(-1, 0)).toThrow("Invalid coordinates");
  });

  it("is inverse of tileToCoords", () => {
    for (let i = 0; i < 25; i++) {
      const { x, y } = tileToCoords(i);
      expect(coordsToTile(x, y)).toBe(i);
    }
  });
});

describe("isAdjacent", () => {
  it("returns true for horizontally adjacent tiles", () => {
    expect(isAdjacent(0, 1)).toBe(true);
    expect(isAdjacent(1, 0)).toBe(true);
  });

  it("returns true for vertically adjacent tiles", () => {
    expect(isAdjacent(0, 5)).toBe(true);
    expect(isAdjacent(5, 0)).toBe(true);
  });

  it("returns false for diagonal tiles", () => {
    expect(isAdjacent(0, 6)).toBe(false);
    expect(isAdjacent(6, 0)).toBe(false);
  });

  it("returns false for same tile", () => {
    expect(isAdjacent(0, 0)).toBe(false);
  });

  it("returns false for non-adjacent tiles", () => {
    expect(isAdjacent(0, 2)).toBe(false);
    expect(isAdjacent(0, 24)).toBe(false);
  });

  it("returns false for invalid tile IDs", () => {
    expect(isAdjacent(-1, 0)).toBe(false);
    expect(isAdjacent(0, 25)).toBe(false);
  });

  it("handles edge wrapping correctly (tiles on opposite edges are NOT adjacent)", () => {
    // tile 4 (4,0) and tile 5 (0,1) should NOT be adjacent
    expect(isAdjacent(4, 5)).toBe(false);
    // tile 9 (4,1) and tile 10 (0,2) should NOT be adjacent
    expect(isAdjacent(9, 10)).toBe(false);
  });

  it("center tile is adjacent to 4 neighbors", () => {
    // tile 12 (2,2) center
    expect(isAdjacent(12, 7)).toBe(true);  // up (2,1)
    expect(isAdjacent(12, 17)).toBe(true); // down (2,3)
    expect(isAdjacent(12, 11)).toBe(true); // left (1,2)
    expect(isAdjacent(12, 13)).toBe(true); // right (3,2)
  });
});

describe("getAdjacentTiles", () => {
  it("returns 2 neighbors for corner tile 0", () => {
    const adj = getAdjacentTiles(0);
    expect(adj).toHaveLength(2);
    expect(adj).toContain(1);  // right
    expect(adj).toContain(5);  // down
  });

  it("returns 2 neighbors for corner tile 24", () => {
    const adj = getAdjacentTiles(24);
    expect(adj).toHaveLength(2);
    expect(adj).toContain(23); // left
    expect(adj).toContain(19); // up
  });

  it("returns 3 neighbors for edge tile 1", () => {
    const adj = getAdjacentTiles(1);
    expect(adj).toHaveLength(3);
    expect(adj).toContain(0);  // left
    expect(adj).toContain(2);  // right
    expect(adj).toContain(6);  // down
  });

  it("returns 4 neighbors for center tile 12", () => {
    const adj = getAdjacentTiles(12);
    expect(adj).toHaveLength(4);
    expect(adj).toContain(11); // left
    expect(adj).toContain(13); // right
    expect(adj).toContain(7);  // up
    expect(adj).toContain(17); // down
  });

  it("throws for invalid tile ID", () => {
    expect(() => getAdjacentTiles(-1)).toThrow("Invalid tile ID");
    expect(() => getAdjacentTiles(25)).toThrow("Invalid tile ID");
  });

  it("all returned tiles are adjacent to the input", () => {
    for (let i = 0; i < 25; i++) {
      const adj = getAdjacentTiles(i);
      adj.forEach((neighbor) => {
        expect(isAdjacent(i, neighbor)).toBe(true);
      });
    }
  });
});

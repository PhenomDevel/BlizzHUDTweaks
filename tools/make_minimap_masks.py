#!/usr/bin/env python3
"""Writes the minimap fade masks to BlizzHUDTweaks/Media/MinimapMasks/.

The minimap is faded through its mask texture (Core/MinimapAlpha.lua), so
there is one mask per alpha step: white, with the step's alpha in every
visible pixel.
  round<N>.tga   64x64, a circle with an antialiased edge (round minimap)
  square<N>.tga  8x8, every pixel visible (square minimap)
N is 0..STEPS, the alpha is N / STEPS. Run from the repository root:
  python3 tools/make_minimap_masks.py
"""
import os
import struct

STEPS = 20
ROUND_SIZE = 64
SQUARE_SIZE = 8
SUPERSAMPLE = 4
OUT_DIR = os.path.join("BlizzHUDTweaks", "Media", "MinimapMasks")


def write_tga(path, size, coverage):
    # Uncompressed 32 bit true color, origin top left (descriptor 0x28).
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, size, size, 32, 0x28)
    pixels = bytearray()
    for value in coverage:
        pixels += bytes((255, 255, 255, value))
    with open(path, "wb") as f:
        f.write(header)
        f.write(pixels)


def circle_coverage(size):
    radius = size / 2
    result = []
    for y in range(size):
        for x in range(size):
            inside = 0
            for sy in range(SUPERSAMPLE):
                for sx in range(SUPERSAMPLE):
                    px = x + (sx + 0.5) / SUPERSAMPLE - radius
                    py = y + (sy + 0.5) / SUPERSAMPLE - radius
                    if px * px + py * py <= radius * radius:
                        inside += 1
            result.append(inside / (SUPERSAMPLE * SUPERSAMPLE))
    return result


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    circle = circle_coverage(ROUND_SIZE)
    for step in range(STEPS + 1):
        alpha = step / STEPS
        write_tga(os.path.join(OUT_DIR, "round%d.tga" % step), ROUND_SIZE,
                  [round(c * alpha * 255) for c in circle])
        write_tga(os.path.join(OUT_DIR, "square%d.tga" % step), SQUARE_SIZE,
                  [round(alpha * 255)] * (SQUARE_SIZE * SQUARE_SIZE))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Renderiza un nivel .txt a PNG con el arte real (para revisarlo sin abrir Godot).
Uso: python3 tools/preview_level.py 1 [salida.png]"""
import os, sys
from PIL import Image
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
A = lambda *p: os.path.join(ROOT, "assets", *p)

def main():
    n = int(sys.argv[1])
    out = sys.argv[2] if len(sys.argv) > 2 else "preview_%02d.png" % n
    world = (n - 1) // 4 + 1
    rows = [l.rstrip("\n") for l in open(os.path.join(ROOT, "levels", "data", "level_%02d.txt" % n), encoding="utf-8") if not l.startswith(";")]
    w = max(len(r) for r in rows)
    tiles = Image.open(A("tiles", "tiles_w%d.png" % world)).convert("RGBA")
    T = lambda i: tiles.crop((i * 16, 0, i * 16 + 16, 16))
    en = Image.open(A("enemies", "enemies_w%d.png" % world)).convert("RGBA")
    E = lambda r: en.crop((0, r * 16, 16, r * 16 + 16))
    items = {k: Image.open(A("items", k + ".png")).convert("RGBA") for k in ("coin", "gem", "heart", "life", "spring", "goal", "checkpoint")}
    bg = Image.open(A("backgrounds", "bg_w%d_far.png" % world)).convert("RGBA")
    im = Image.new("RGBA", (w * 16, 20 * 16))
    for x in range(0, w * 16, 480):
        im.paste(bg.crop((0, 0, 480, 320)), (x, 0))
    mid = Image.open(A("backgrounds", "bg_w%d_mid.png" % world)).convert("RGBA")
    for x in range(0, w * 16, 480):
        im.alpha_composite(mid.crop((0, 0, 480, 320)), (x, 0))
    solid = lambda x, y: 0 <= y < len(rows) and 0 <= x < len(rows[y]) and rows[y][x] == "#"
    hero = Image.open(A("player", "wilmen.png")).convert("RGBA").crop((0, 0, 24, 24))
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            px, py = x * 16, y * 16
            if c == "#":
                im.alpha_composite(T(0 if not solid(x, y - 1) else (1 + (x * 7 + y * 3) % 2)), (px, py))
            elif c == "=": im.alpha_composite(T(3), (px, py))
            elif c == "B": im.alpha_composite(T(4), (px, py))
            elif c in "?+": im.alpha_composite(T(5), (px, py))
            elif c in "HK":
                t = T(6).copy(); t.putalpha(70); im.alpha_composite(t, (px, py))
            elif c == "^": im.alpha_composite(T(7), (px, py))
            elif c == "L": im.alpha_composite(T(8), (px, py))
            elif c == "o": im.alpha_composite(items["coin"].crop((0, 0, 16, 16)), (px, py))
            elif c == "*": im.alpha_composite(items["gem"].crop((0, 0, 16, 16)), (px, py))
            elif c == "h": im.alpha_composite(items["heart"], (px, py))
            elif c == "S": im.alpha_composite(items["spring"].crop((0, 0, 16, 16)), (px, py))
            elif c == "C": im.alpha_composite(items["checkpoint"].crop((0, 0, 16, 32)), (px, py - 16))
            elif c == "F": im.alpha_composite(items["goal"].crop((0, 0, 16, 48)), (px, py - 32))
            elif c == "P": im.alpha_composite(hero, (px - 4, py - 8))
            elif c in "wsjft": im.alpha_composite(E("wsjft".index(c)), (px, py))
            elif c == "m": im.alpha_composite(Image.open(A("tiles", "mplatform_w%d.png" % world)).convert("RGBA"), (px, py))
            elif c == "v": im.alpha_composite(Image.open(A("tiles", "mplatform_w%d.png" % world)).convert("RGBA"), (px, py))
            elif c == "X":
                b = Image.open(A("bosses", "boss_%d.png" % world)).convert("RGBA").crop((0, 0, 64, 64)); im.alpha_composite(b, (px - 24, py - 24))
            elif c == "G":
                for yy in range(0, 15 * 16, 6): im.putpixel((px + 8, yy), (255, 255, 0, 255))
    im.save(out)
    print(out, im.size)

main()

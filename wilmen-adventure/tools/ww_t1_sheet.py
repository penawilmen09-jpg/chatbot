#!/usr/bin/env python3
"""Hoja comparativa de los niveles nuevos de WILMEN WORLD: una tira por nivel (3 px por celda) con colores por tipo de elemento.
Uso: python3 tools/ww_t1_sheet.py salida.png [n1 n2 ...]"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
import ww_check as wc

COL = {"#": (92, 70, 50), "=": (200, 160, 90), "B": (200, 120, 60), "_": (230, 140, 40), "-": (120, 200, 160), "c": (170, 140, 100),
       "$": (70, 190, 70), "%": (240, 70, 70), "{": (170, 90, 240), "}": (170, 90, 240), "&": (120, 80, 40), "'": (120, 80, 40),
       "(": (90, 90, 230), ")": (150, 150, 255), "[": (230, 90, 200), "]": (255, 160, 230), "/": (255, 255, 0), "\\": (255, 255, 0),
       ":": (90, 160, 255), ".": (90, 160, 255), ",": (170, 230, 255), "\"": (255, 120, 40), "`": (255, 120, 40), "!": (200, 200, 200),
       "n": (255, 200, 60), "b": (255, 200, 60), "m": (255, 200, 60), "v": (255, 200, 60), "S": (255, 120, 200),
       "w": (255, 0, 120), "s": (255, 0, 120), "j": (255, 0, 120), "f": (255, 0, 120), "t": (255, 0, 120),
       "z": (255, 0, 120), "D": (255, 0, 120), "Y": (255, 0, 120), "0": (255, 0, 120), "^": (255, 60, 60),
       "U": (255, 215, 0), "A": (255, 160, 0), "T": (0, 255, 200), "*": (60, 255, 255), "C": (80, 255, 120), "F": (255, 255, 255),
       "P": (80, 160, 255), "O": (190, 80, 255), "I": (120, 210, 255), "M": (255, 190, 40), "o": (150, 130, 50),
       "u": (255, 100, 100), "h": (255, 100, 100), "k": (255, 255, 120), "i": (255, 255, 120), "l": (255, 255, 120), "q": (255, 255, 120)}


def main():
    out = sys.argv[1]
    nums = [int(a) for a in sys.argv[2:]] or [1, 2, 3, 4, 5]
    S = 3
    levels = []
    for n in nums:
        rows, meta, warps = wc.parse(os.path.join(wc.WORLD_DIR, "ww_%03d.txt" % n))
        levels.append((n, rows, meta))
    W = max(len(r[1][0]) for r in levels) * S + 220
    H = sum(len(r[1]) * S + 34 for r in levels) + 10
    im = Image.new("RGB", (W, H), (28, 34, 60))
    d = ImageDraw.Draw(im)
    f = ImageFont.load_default()
    y0 = 6
    for n, rows, meta in levels:
        w = len(rows[0])
        d.text((6, y0 + 4), "1-%d  %s" % (n, meta.get("title", "")), fill=(255, 255, 255), font=f)
        d.text((6, y0 + 18), "%dx%d  %s  tiempo %d s  par %d" % (w, len(rows), meta.get("kind", ""), meta.get("time", 0), meta.get("par", 0)), fill=(190, 200, 230), font=f)
        oy = y0 + 32
        d.rectangle([210, oy - 2, 210 + w * S + 1, oy + len(rows) * S + 1], fill=(60, 80, 120))
        for y, r in enumerate(rows):
            for x, c in enumerate(r):
                if c in COL:
                    d.rectangle([211 + x * S, oy + y * S, 211 + x * S + S - 1, oy + y * S + S - 1], fill=COL[c])
        y0 = oy + len(rows) * S + 6
    im.save(out)
    print("hoja:", out, im.size)


if __name__ == "__main__":
    main()

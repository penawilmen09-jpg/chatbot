#!/usr/bin/env python3
"""Vista general de un nivel de WILMEN WORLD en una imagen (una casilla = 5 px; tiras de 230 columnas).
Uso: python3 tools/ww_preview.py N salida.png"""
import sys, os
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(__file__))
import ww_check as wc

COL = {"#": (90, 70, 50), "=": (170, 130, 80), "B": (190, 110, 60), "?": (255, 210, 60), "^": (255, 60, 60), "L": (255, 120, 20),
       "o": (255, 230, 90), "*": (60, 255, 255), "C": (80, 255, 120), "F": (255, 255, 255), "P": (80, 160, 255),
       "w": (170, 60, 200), "s": (200, 40, 120), "j": (230, 90, 200), "f": (120, 120, 255), "t": (255, 150, 60),
       "m": (60, 200, 200), "v": (60, 200, 140), "c": (200, 160, 100), "g": (255, 100, 40), "p": (150, 150, 170), "W": (160, 220, 255),
       "<": (120, 120, 120), ">": (120, 120, 120), "S": (255, 200, 120), "T": (0, 255, 200), "A": (255, 160, 0), "Q": (255, 255, 0),
       "U": (255, 215, 0), "I": (120, 210, 255), "M": (255, 190, 40), "d": (60, 110, 60)}


def main():
    n = int(sys.argv[1])
    lv = wc.Level(os.path.join(wc.WORLD_DIR, "ww_%03d.txt" % n))
    S, STRIP = 5, 230
    strips = (lv.w + STRIP - 1) // STRIP
    im = Image.new("RGB", (STRIP * S, strips * (lv.rows.__len__() * S + 8)), (30, 40, 70))
    d = ImageDraw.Draw(im)
    for si in range(strips):
        oy = si * (len(lv.rows) * S + 8)
        for y, r in enumerate(lv.rows):
            for x in range(si * STRIP, min(lv.w, (si + 1) * STRIP)):
                ch = r[x]
                if ch in COL:
                    px = (x - si * STRIP) * S
                    d.rectangle([px, oy + y * S, px + S - 1, oy + y * S + S - 1], fill=COL[ch])
        d.text((2, oy + 1), "x=%d" % (si * STRIP), fill=(255, 255, 255))
    im.save(sys.argv[2])


main()

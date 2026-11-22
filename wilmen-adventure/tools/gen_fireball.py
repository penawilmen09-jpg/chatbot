#!/usr/bin/env python3
"""Genera el arte de la bola de fuego del Pulso Eléctrico (Mundo 9):
  assets/items/fireball.png       4 fotogramas 16x16 (vuelo, la cola apunta a la izquierda; el juego la voltea)
  assets/items/fireball_boom.png  6 fotogramas 32x32 (explosión)
Misma paleta que projectiles.png: contorno #1a1226, naranja #ff5a1a, amarillo #ffd23a."""
import math, os, random
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "items")
OL = (26, 18, 38, 255)
RED = (200, 52, 26, 255)
OR = (255, 90, 26, 255)
YE = (255, 210, 58, 255)
WH = (255, 243, 160, 255)


def disc(d, cx, cy, r, col):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)


def flight(f):
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 11, 8
    # cola de llamas: una gota larga con tres capas (contorno, rojo/naranja, amarillo) que ondula por fotograma
    for k in range(0, 10):
        x = cx - 3 - k
        if x < 0:
            break
        w = max(0, 3 - (k * 3) // 8)                 # se afina hacia atrás
        sway = round(math.sin((k * 0.9) + f * 1.57) * (0.6 + k * 0.12))
        d.rectangle([x, cy + sway - w - 1, x, cy + sway + w + 1], fill=OL)
    for k in range(0, 10):
        x = cx - 3 - k
        if x < 0:
            break
        w = max(0, 3 - (k * 3) // 8)
        sway = round(math.sin((k * 0.9) + f * 1.57) * (0.6 + k * 0.12))
        col = OR if k < 5 else RED
        d.rectangle([x, cy + sway - w, x, cy + sway + w], fill=col)
        if k < 4:
            d.rectangle([x, cy + sway - max(0, w - 1), x, cy + sway + max(0, w - 1)], fill=YE if k < 3 else OR)
    disc(d, cx, cy, 5, OL)
    disc(d, cx, cy, 4, OR)
    disc(d, cx + 1, cy, 3, YE)
    disc(d, cx + 1, cy - 1, 1, WH)
    for (ox, oy) in [(-1, -6), (3, -5), (0, 6), (4, 5)][f % 2::2]:
        if 0 <= cx + ox < 16 and 0 <= cy + oy < 16:
            d.point((cx + ox, cy + oy), fill=YE)
    return im


def boom(f):
    n = 6
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rnd = random.Random(7 + f)
    t = f / (n - 1)
    r = 4 + int(11 * math.sin(min(1.0, t * 1.15) * math.pi / 2))
    if f <= 3:
        pts = []
        for k in range(10):
            a = 2 * math.pi * k / 10 + f * 0.3
            rr = r * (0.55 + 0.45 * rnd.random())
            pts.append((16 + math.cos(a) * rr * 0.7, 16 + math.sin(a) * rr * 0.7, max(2, int(r * 0.42))))
        for (x, y, s) in pts:
            disc(d, x, y, s + 1, OL)
        disc(d, 16, 16, r, OL)
        for (x, y, s) in pts:
            disc(d, x, y, s, OR)
        disc(d, 16, 16, r - 1, OR)
        if r > 6:
            disc(d, 16, 16, max(1, r - 4), OR)
        disc(d, 16, 16, max(1, int((r - 3) * (1.0 - t * 0.6))), YE)
        if f < 3:
            disc(d, 16, 16, max(1, int((r - 6) * 0.9)), WH)
    else:
        # fin: un aro roto de brasas que se abre y se desvanece (sin masa sólida)
        alpha = 230 if f == 4 else 140
        rad = 12 + (f - 4) * 2
        for k in range(26):
            if k % 3 == 2:
                continue
            a = 2 * math.pi * k / 26 + rnd.random() * 0.2
            x, y = 16 + math.cos(a) * rad, 16 + math.sin(a) * rad
            col = (RED if k % 2 else OR)[:3] + (alpha,)
            d.rectangle([int(x) - 1, int(y) - 1, int(x), int(y)], fill=col)
    for k in range(8):
        a = 2 * math.pi * k / 8 + 0.4 + f * 0.15
        dist = r + 2 + f * 1.6
        x, y = 16 + math.cos(a) * dist, 16 + math.sin(a) * dist
        if 1 <= x < 31 and 1 <= y < 31 and f < 5:
            d.point((int(x), int(y)), fill=YE if f < 3 else OR)
    return im


def main():
    sheet = Image.new("RGBA", (16 * 4, 16), (0, 0, 0, 0))
    for f in range(4):
        sheet.paste(flight(f), (f * 16, 0))
    sheet.save(os.path.join(OUT, "fireball.png"))
    sheet = Image.new("RGBA", (32 * 6, 32), (0, 0, 0, 0))
    for f in range(6):
        sheet.paste(boom(f), (f * 32, 0))
    sheet.save(os.path.join(OUT, "fireball_boom.png"))
    print("fireball.png y fireball_boom.png generados")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Arte de los objetos nuevos de WILMEN WORLD (hito 2), en el mismo estilo que el resto del juego
(contorno #1a1226, colores vivos, píxel art con Pillow). Salida:
  assets/items/ww_items.png  10 casillas de 16x16: reloj (2), reloj grande (2), llave (2), boca de túnel (2), candado de verja (2)
  assets/items/ww_door.png   2 casillas de 16x32: puerta cerrada y puerta abierta
"""
import math, os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "items")
OL = (26, 18, 38, 255)
GOLD = (255, 210, 58, 255)
GOLD2 = (214, 150, 30, 255)
WHITE = (255, 255, 255, 255)
CREAM = (255, 243, 200, 255)
RED = (230, 60, 60, 255)
TEAL = (60, 200, 190, 255)
TEAL2 = (30, 130, 140, 255)
STONE = (120, 120, 140, 255)
STONE2 = (80, 80, 100, 255)
WOOD = (150, 90, 50, 255)
WOOD2 = (100, 58, 34, 255)


def disc(d, cx, cy, r, col):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)


def clock(f, big):
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    r = 7 if big else 6
    disc(d, 8, 8, r, OL)
    disc(d, 8, 8, r - 1, GOLD if big else (120, 210, 255, 255))
    disc(d, 8, 8, r - 2, CREAM)
    # manecillas: giran un poco entre fotogramas (tictac)
    a = (-math.pi / 2) + (0.0 if f == 0 else 0.5)
    d.line([8, 8, 8 + int(round(math.cos(a) * (r - 3))), 8 + int(round(math.sin(a) * (r - 3)))], fill=OL)
    d.line([8, 8, 8 + (r - 4), 8], fill=RED if big else OL)
    d.point((8, 8), fill=OL)
    if big:
        for ang in range(0, 360, 90):
            x = 8 + int(round(math.cos(math.radians(ang)) * (r - 2)))
            y = 8 + int(round(math.sin(math.radians(ang)) * (r - 2)))
            d.point((x, y), fill=GOLD2)
        d.rectangle([6, 0, 9, 1], fill=OL)  # corona
    else:
        d.rectangle([7, 1, 8, 2], fill=OL)
    return im


def key(f):
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    disc(d, 5, 5, 4, OL)
    disc(d, 5, 5, 3, GOLD)
    disc(d, 5, 5, 1, OL)
    d.rectangle([7, 7, 13, 9], fill=OL)
    d.rectangle([7, 7, 12, 8], fill=GOLD)
    d.rectangle([11, 9, 13, 12], fill=OL)
    d.rectangle([11, 9, 12, 11], fill=GOLD2)
    d.rectangle([8, 9, 9, 11], fill=OL)
    d.rectangle([8, 9, 8, 10], fill=GOLD2)
    if f == 1:
        for (x, y) in [(1, 1), (12, 3), (3, 12)]:
            d.point((x, y), fill=WHITE)
    d.point((4, 4), fill=WHITE)
    return im


def tunnel(f):
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([1, 4, 14, 15], fill=OL)
    d.rectangle([2, 5, 13, 15], fill=STONE)
    d.rectangle([2, 5, 13, 6], fill=STONE2)
    d.ellipse([3, 6, 12, 18], fill=OL)
    d.ellipse([4, 7, 11, 17], fill=TEAL2 if f == 0 else TEAL)
    d.ellipse([5, 9, 10, 16], fill=TEAL if f == 0 else (170, 255, 245, 255))
    d.point((7 + f, 11), fill=WHITE)
    d.point((8 - f, 13), fill=WHITE)
    d.rectangle([0, 3, 15, 4], fill=OL)
    d.rectangle([1, 3, 14, 3], fill=STONE)
    return im


def gate(f):
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 15, 15], fill=OL)
    d.rectangle([1, 0, 14, 15], fill=STONE2)
    d.rectangle([2, 0, 13, 15], fill=STONE)
    for y in (3, 11):
        d.rectangle([1, y, 14, y + 1], fill=OL)
    d.rectangle([5, 4, 10, 11], fill=OL)
    d.rectangle([6, 5, 9, 10], fill=GOLD if f == 0 else (255, 235, 130, 255))
    d.arc([5, 1, 10, 6], 180, 360, fill=OL, width=2)
    d.rectangle([7, 7, 8, 8], fill=OL)
    return im


def door(opened):
    im = Image.new("RGBA", (16, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([1, 3, 14, 31], fill=OL)
    d.pieslice([1, 0, 14, 12], 180, 360, fill=OL)
    d.rectangle([2, 6, 13, 31], fill=STONE)
    d.pieslice([2, 1, 13, 11], 180, 360, fill=STONE)
    d.rectangle([4, 9, 11, 31], fill=OL)
    d.pieslice([4, 4, 11, 14], 180, 360, fill=OL)
    if not opened:
        d.rectangle([5, 10, 10, 31], fill=WOOD)
        d.pieslice([5, 5, 10, 14], 180, 360, fill=WOOD)
        d.line([7, 8, 7, 31], fill=WOOD2)
        d.line([5, 20, 10, 20], fill=WOOD2)
        d.rectangle([9, 21, 10, 22], fill=GOLD)
    else:
        d.rectangle([5, 10, 10, 31], fill=(40, 30, 70, 255))
        d.pieslice([5, 5, 10, 14], 180, 360, fill=(40, 30, 70, 255))
        d.rectangle([5, 10, 6, 31], fill=WOOD)  # hoja entreabierta
        d.line([8, 14, 8, 30], fill=(255, 220, 120, 255))
        d.point((9, 20), fill=(255, 240, 180, 255))
    return im


def main():
    sheet = Image.new("RGBA", (16 * 10, 16), (0, 0, 0, 0))
    tiles = [clock(0, False), clock(1, False), clock(0, True), clock(1, True), key(0), key(1), tunnel(0), tunnel(1), gate(0), gate(1)]
    for i, t in enumerate(tiles):
        sheet.paste(t, (i * 16, 0))
    sheet.save(os.path.join(OUT, "ww_items.png"))
    ds = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    ds.paste(door(False), (0, 0))
    ds.paste(door(True), (16, 0))
    ds.save(os.path.join(OUT, "ww_door.png"))
    print("ww_items.png y ww_door.png generados")


if __name__ == "__main__":
    main()

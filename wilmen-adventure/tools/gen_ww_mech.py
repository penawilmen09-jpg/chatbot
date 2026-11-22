#!/usr/bin/env python3
"""Arte de las mecánicas nuevas de WILMEN WORLD (tanda 0): setas, lianas, troncos, plataformas que desaparecen, puentes,
interruptores, dardos, péndulo, plataformas orbitales, ascensor y corrientes. Estilo del resto del juego (contorno #1a1226).
Salida: assets/items/ww_mech.png (casillas de 16x16 en una tira; ver INDEX)."""
import math, os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "items", "ww_mech.png")
OL = (26, 18, 38, 255)
INDEX = ["mush_up", "mush_up_p", "mush_dg", "mush_dg_p", "vine_handle", "vine_anchor", "log", "chute", "chute_warn", "phase", "phase_ghost",
         "plank", "sw1_off", "sw1_on", "sw2_off", "sw2_on", "blk1", "blk1_ghost", "blk2", "blk2_ghost", "dart_shooter", "dart",
         "pend_anchor", "pend_blade", "orbit", "elevator", "cur_arrow", "bubble"]


def disc(d, cx, cy, r, c):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=c)


def cell(fn):
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    fn(ImageDraw.Draw(im))
    return im


def mush(pressed, diag):
    def f(d):
        top = 8 if pressed else 5
        cap = (230, 70, 70, 255) if not diag else (120, 90, 230, 255)
        d.rectangle([6, 10, 9, 15], fill=OL)
        d.rectangle([7, 10, 8, 15], fill=(240, 226, 190, 255))
        d.ellipse([1, top, 14, 13], fill=OL)
        d.ellipse([2, top + 1, 13, 12], fill=cap)
        for (x, y) in ((5, top + 3), (9, top + 2), (11, top + 4)):
            d.point((x, y), fill=(255, 255, 255, 255))
        if diag:
            d.polygon([(7, 3), (12, 3), (12, 8)], fill=(255, 235, 120, 255)) if not pressed else None
    return f


def vine_handle(d):
    d.ellipse([3, 3, 12, 12], fill=OL)
    d.ellipse([5, 5, 10, 10], fill=(110, 170, 70, 255))
    d.ellipse([7, 7, 8, 8], fill=OL)


def vine_anchor(d):
    d.rectangle([3, 3, 12, 8], fill=OL)
    d.rectangle([4, 4, 11, 7], fill=(120, 84, 50, 255))
    d.rectangle([7, 8, 8, 12], fill=OL)


def log(d):
    disc(d, 8, 8, 7, OL)
    disc(d, 8, 8, 6, (150, 100, 56, 255))
    disc(d, 8, 8, 4, (200, 150, 90, 255))
    disc(d, 8, 8, 2, (150, 100, 56, 255))
    d.point((8, 8), fill=OL)


def chute(warn):
    def f(d):
        d.rectangle([0, 4, 15, 15], fill=OL)
        d.rectangle([1, 5, 14, 14], fill=(110, 76, 46, 255))
        d.rectangle([3, 7, 12, 14], fill=(40, 28, 20, 255))
        if warn:
            d.rectangle([3, 7, 12, 14], fill=(200, 70, 40, 255))
        for x in (2, 7, 12):
            d.line([x, 5, x, 6], fill=OL)
    return f


def phase(ghost):
    def f(d):
        if ghost:
            d.rectangle([0, 4, 15, 9], outline=(140, 220, 160, 255))
            for x in range(1, 15, 3):
                d.point((x, 6), fill=(140, 220, 160, 255))
        else:
            d.rectangle([0, 4, 15, 10], fill=OL)
            d.rectangle([0, 5, 15, 9], fill=(90, 190, 110, 255))
            d.rectangle([0, 5, 15, 6], fill=(160, 240, 170, 255))
            for x in (3, 8, 12):
                d.point((x, 8), fill=(50, 130, 70, 255))
    return f


def plank(d):
    d.rectangle([0, 5, 15, 10], fill=OL)
    d.rectangle([1, 6, 14, 9], fill=(190, 140, 80, 255))
    d.line([4, 6, 4, 9], fill=(120, 80, 44, 255))
    d.line([11, 6, 11, 9], fill=(120, 80, 44, 255))


def switch(color, on):
    c = (230, 60, 60, 255) if color == 1 else (70, 130, 240, 255)

    def f(d):
        d.rectangle([2, 12, 13, 15], fill=OL)
        d.rectangle([3, 13, 12, 14], fill=(140, 140, 156, 255))
        x = 11 if on else 4
        d.line([8, 13, x, 4], fill=OL, width=3)
        d.line([8, 13, x, 4], fill=(200, 200, 210, 255), width=1)
        disc(d, x, 4, 3, OL)
        disc(d, x, 4, 2, c)
    return f


def block(color, ghost):
    c = (230, 60, 60, 255) if color == 1 else (70, 130, 240, 255)

    def f(d):
        if ghost:
            d.rectangle([0, 0, 15, 15], outline=c)
            d.point((4, 4), fill=c)
            d.point((11, 11), fill=c)
        else:
            d.rectangle([0, 0, 15, 15], fill=OL)
            d.rectangle([1, 1, 14, 14], fill=c)
            d.rectangle([2, 2, 13, 5], fill=tuple(min(255, v + 50) for v in c[:3]) + (255,))
            d.line([2, 13, 13, 2], fill=OL)
    return f


def dart_shooter(d):
    d.rectangle([0, 0, 15, 15], fill=OL)
    d.rectangle([1, 1, 14, 14], fill=(120, 116, 132, 255))
    d.rectangle([0, 6, 5, 9], fill=OL)
    d.rectangle([0, 7, 4, 8], fill=(20, 12, 28, 255))
    d.rectangle([9, 3, 12, 12], fill=(90, 86, 104, 255))


def dart(d):
    d.polygon([(0, 8), (5, 5), (5, 11)], fill=OL)
    d.polygon([(1, 8), (5, 6), (5, 10)], fill=(240, 240, 250, 255))
    d.rectangle([5, 7, 14, 9], fill=OL)
    d.rectangle([5, 8, 14, 8], fill=(190, 120, 60, 255))
    d.rectangle([12, 5, 15, 11], fill=OL)
    d.rectangle([13, 6, 14, 10], fill=(230, 80, 80, 255))


def pend_anchor(d):
    d.rectangle([2, 2, 13, 7], fill=OL)
    d.rectangle([3, 3, 12, 6], fill=(150, 150, 166, 255))
    d.rectangle([7, 7, 8, 12], fill=OL)


def pend_blade(d):
    d.ellipse([1, 1, 14, 14], fill=OL)
    d.ellipse([2, 2, 13, 13], fill=(200, 205, 220, 255))
    d.polygon([(8, 3), (12, 8), (8, 13), (4, 8)], fill=(120, 126, 144, 255))
    d.ellipse([6, 6, 9, 9], fill=OL)


def orbit(d):
    d.rectangle([0, 3, 15, 11], fill=OL)
    d.rectangle([1, 4, 14, 10], fill=(210, 150, 70, 255))
    d.rectangle([1, 4, 14, 5], fill=(250, 200, 110, 255))
    disc(d, 8, 8, 2, OL)
    disc(d, 8, 8, 1, (250, 220, 150, 255))


def elevator(d):
    d.rectangle([0, 3, 15, 11], fill=OL)
    d.rectangle([1, 4, 14, 10], fill=(110, 170, 210, 255))
    d.rectangle([1, 4, 14, 5], fill=(180, 220, 250, 255))
    d.polygon([(8, 6), (5, 9), (11, 9)], fill=OL)


def cur_arrow(d):
    d.polygon([(2, 5), (9, 5), (9, 2), (14, 8), (9, 14), (9, 11), (2, 11)], fill=(255, 255, 255, 120))


def bubble(d):
    d.ellipse([3, 3, 12, 12], outline=(255, 255, 255, 200))
    d.point((5, 5), fill=(255, 255, 255, 255))


def main():
    fns = [mush(False, False), mush(True, False), mush(False, True), mush(True, True), vine_handle, vine_anchor, log, chute(False), chute(True),
           phase(False), phase(True), plank, switch(1, False), switch(1, True), switch(2, False), switch(2, True), block(1, False), block(1, True),
           block(2, False), block(2, True), dart_shooter, dart, pend_anchor, pend_blade, orbit, elevator, cur_arrow, bubble]
    assert len(fns) == len(INDEX)
    sheet = Image.new("RGBA", (16 * len(fns), 16), (0, 0, 0, 0))
    for i, f in enumerate(fns):
        sheet.paste(cell(f), (i * 16, 0))
    sheet.save(OUT)
    print("ww_mech.png:", len(fns), "casillas")


if __name__ == "__main__":
    main()

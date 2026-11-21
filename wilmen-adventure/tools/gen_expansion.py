#!/usr/bin/env python3
"""Arte de la gran expansión (todo procedural con Pillow): cofres, orbes de poder, gema especial, puerta secreta,
vehículos, perseguidor, sombreros, armaduras y efectos.

Salidas en assets/items/ y assets/player/.   Uso: python3 tools/gen_expansion.py
"""
import math
import os
import random

from PIL import Image, ImageDraw

import gen_art as ga
from gen_art import C, CLEAR, OUTLINE, newc, outline, px, rect, save


def shade(col, t):
    if t >= 0:
        return tuple(int(col[i] + (255 - col[i]) * t) for i in range(3)) + (col[3],)
    return tuple(int(col[i] * (1 + t)) for i in range(3)) + (col[3],)


# ------------------------------------------------------------------ cofres ---
CHEST = {
    "normal": ("#9a6230", "#d8d8d8", "#ffd23a"),
    "rare": ("#3a6ad0", "#eef2ff", "#9ad4ff"),
    "special": ("#8a3ad0", "#ffd23a", "#ff9aff"),
    "secret": ("#2a1a3a", "#ff5a5a", "#ff3a6a"),
}


def chest_frame(kind, open_):
    body, band, glow = (C(x) for x in CHEST[kind])
    im, d = newc(16, 16)
    # cuerpo
    rect(d, 1, 8, 14, 7, body)
    rect(d, 1, 8, 14, 1, shade(body, 0.3))
    rect(d, 1, 13, 14, 2, shade(body, -0.3))
    rect(d, 2, 8, 2, 7, band)
    rect(d, 12, 8, 2, 7, band)
    if not open_:
        d.pieslice([1, 1, 14, 15], 180, 360, fill=body)
        rect(d, 1, 8, 14, 1, band)
        rect(d, 2, 5, 2, 4, band)
        rect(d, 12, 5, 2, 4, band)
        rect(d, 7, 8, 2, 3, glow)
        px(d, 7, 9, C("#1a1226"))
    else:
        # tapa levantada hacia atrás y resplandor
        d.polygon([(1, 8), (3, 2), (13, 2), (15, 8)], fill=shade(body, -0.15))
        rect(d, 3, 2, 10, 1, band)
        rect(d, 3, 3, 10, 5, shade(body, 0.1))
        for (x, y) in ((5, 6), (8, 4), (10, 7), (6, 9)):
            px(d, x, y, glow)
        rect(d, 3, 9, 10, 2, shade(glow, 0.2))
    return outline(im)


def gen_chests():
    frames = []
    for k in CHEST:
        frames += [chest_frame(k, False), chest_frame(k, True)]
    save(ga.sheet(frames, 16, 16), "items", "chests.png")


# ------------------------------------------------------ orbes de poder -------
ORB = {
    "flame": ("#ff6a1a", "#ffd23a"), "freeze": ("#59d0ff", "#ffffff"), "pulse": ("#ffe05a", "#ffffff"),
    "barrier": ("#ffb030", "#fff0a0"), "giant": ("#5adf7a", "#d8ffd8"),
}


def orb_frame(kind, f):
    c1, c2 = (C(x) for x in ORB[kind])
    im, d = newc(16, 16)
    r = 6 + f
    d.ellipse([8 - r, 8 - r, 8 + r - 1, 8 + r - 1], fill=shade(c1, -0.25))
    d.ellipse([8 - r + 1, 8 - r + 1, 8 + r - 2, 8 + r - 2], fill=c1)
    d.ellipse([4, 3, 8, 6], fill=shade(c1, 0.55))
    ic = c2
    if kind == "flame":
        d.polygon([(8, 3), (5, 9), (6, 12), (10, 12), (11, 9)], fill=c2)
        d.polygon([(8, 7), (7, 11), (9, 11)], fill=C("#ff3a1a"))
    elif kind == "freeze":
        for a in range(3):
            ang = a * math.pi / 3
            d.line([(8 + math.cos(ang) * 5, 8 + math.sin(ang) * 5), (8 - math.cos(ang) * 5, 8 - math.sin(ang) * 5)], fill=ic, width=1)
    elif kind == "pulse":
        d.polygon([(9, 3), (5, 9), (8, 9), (7, 13), (11, 7), (8, 7)], fill=ic)
    elif kind == "barrier":
        d.polygon([(8, 3), (12, 5), (11, 10), (8, 13), (5, 10), (4, 5)], fill=ic)
        d.polygon([(8, 5), (10, 6), (9, 10), (8, 11), (7, 10), (6, 6)], fill=c1)
    else:
        d.polygon([(8, 3), (12, 8), (9, 8), (9, 12), (7, 12), (7, 8), (4, 8)], fill=ic)
    return outline(im)


def gen_orbs():
    frames = []
    for k in ORB:
        frames += [orb_frame(k, 0), orb_frame(k, 1)]
    save(ga.sheet(frames, 16, 16), "items", "orbs.png")


def gen_sgem():
    frames = []
    for f in range(2):
        im, d = newc(16, 16)
        cy = 8 + f
        d.polygon([(8, 1 + f), (14, 6 + f), (8, 15), (2, 6 + f)], fill=C("#c04aff"))
        d.polygon([(8, 1 + f), (14, 6 + f), (8, 15)], fill=C("#8a2ad0"))
        d.polygon([(8, 1 + f), (11, 6 + f), (8, 6 + f)], fill=C("#f0b0ff"))
        px(d, 5, 5 + f, C("#ffffff"))
        px(d, 12 - 7 + 8, 3, C("#ffe05a")) if f else None
        frames.append(outline(im))
    save(ga.sheet(frames, 16, 16), "items", "sgem.png")


def gen_door():
    im, d = newc(16, 32)
    rect(d, 1, 4, 14, 28, C("#4a3d60"))
    d.pieslice([1, 0, 14, 14], 180, 360, fill=C("#4a3d60"))
    rect(d, 3, 6, 10, 26, C("#7a4a26"))
    d.pieslice([3, 2, 12, 14], 180, 360, fill=C("#7a4a26"))
    for y in (10, 18, 26):
        rect(d, 3, y, 10, 1, C("#a06a3a"))
    rect(d, 7, 2, 1, 30, C("#1a1226"))
    blob = lambda x, y: d.ellipse([x - 1, y - 1, x + 1, y + 1], fill=C("#ffd23a"))
    blob(5, 18)
    blob(10, 18)
    save(outline(im), "items", "secret_door.png")


# ---------------------------------------------------------------- vehículos ---
def gen_vehicles():
    # carrito minero 32x24 (2 fotogramas: ruedas)
    cart = []
    for f in range(2):
        im, d = newc(32, 24)
        rect(d, 2, 6, 28, 12, C("#6a5a52"))
        rect(d, 2, 6, 28, 2, C("#9a8a82"))
        rect(d, 4, 9, 24, 7, C("#4a3d3a"))
        for x in (6, 12, 18, 24):
            rect(d, x, 8, 2, 9, C("#8a7a72"))
        for wx in (9, 23):
            d.ellipse([wx - 4, 15, wx + 4, 23], fill=C("#2a2230"))
            d.ellipse([wx - 2, 17, wx + 2, 21], fill=C("#9a9aaa"))
            px(d, wx + (1 if f else -1), 18 + f, C("#ffffff"))
        rect(d, 0, 4, 3, 3, C("#c8c8d8"))
        rect(d, 29, 4, 3, 3, C("#c8c8d8"))
        cart.append(outline(im))
    save(ga.sheet(cart, 32, 24), "items", "v_cart.png")
    # barco 40x24 (2 fotogramas: balanceo)
    boat = []
    for f in range(2):
        im, d = newc(40, 24)
        oy = f
        d.polygon([(2, 12 + oy), (38, 12 + oy), (32, 22 + oy), (8, 22 + oy)], fill=C("#8a5a2a"))
        d.polygon([(2, 12 + oy), (38, 12 + oy), (37, 14 + oy), (3, 14 + oy)], fill=C("#b07a3a"))
        rect(d, 19, 1 + oy, 2, 12, C("#5a3a1a"))
        d.polygon([(21, 2 + oy), (35, 10 + oy), (21, 11 + oy)], fill=C("#f4f4ff"))
        d.polygon([(21, 2 + oy), (28, 6 + oy), (21, 11 + oy)], fill=C("#d0d8f0"))
        for x in (9, 17, 25):
            px(d, x, 17 + oy, C("#5a3a1a"))
        boat.append(outline(im))
    save(ga.sheet(boat, 40, 24), "items", "v_boat.png")
    # plataforma voladora 40x20 (hélices)
    fly = []
    for f in range(2):
        im, d = newc(40, 20)
        rect(d, 4, 8, 32, 6, C("#9aa6b6"))
        rect(d, 4, 8, 32, 2, C("#d0d8e0"))
        rect(d, 8, 14, 24, 3, C("#4a5666"))
        for x in (6, 32):
            rect(d, x, 3, 2, 6, C("#4a5666"))
            w = 7 if f == 0 else 3
            rect(d, x + 1 - w // 2 - 2, 2, w + 4, 2, C("#ffffff"))
        d.ellipse([16, 4, 24, 12], fill=C("#59d0ff"))
        px(d, 18, 6, C("#ffffff"))
        for x in (10, 20, 30):
            px(d, x, 18 + f, C("#ffb02a"))
        fly.append(outline(im))
    save(ga.sheet(fly, 40, 20), "items", "v_flyer.png")
    # mecha 32x32 (2 fotogramas: paso)
    mech = []
    for f in range(2):
        im, d = newc(32, 32)
        rect(d, 6, 6, 20, 14, C("#9aa6b6"))
        rect(d, 6, 6, 20, 3, C("#d0d8e0"))
        rect(d, 9, 9, 14, 7, C("#2a3a4a"))
        rect(d, 11, 11, 4, 3, C("#ff3a3a"))
        rect(d, 17, 11, 4, 3, C("#ff3a3a"))
        rect(d, 2, 10, 4, 10, C("#7a8696"))
        rect(d, 26, 10, 4, 10, C("#7a8696"))
        rect(d, 1, 19, 6, 4, C("#ffb02a"))
        rect(d, 25, 19, 6, 4, C("#ffb02a"))
        lo = 2 if f else 0
        rect(d, 8, 20, 6, 8 - lo, C("#5a6a7a"))
        rect(d, 18, 20, 6, 6 + lo, C("#5a6a7a"))
        rect(d, 6, 27 - lo, 10, 4, C("#3a4654"))
        rect(d, 16, 25 + lo, 10, 4, C("#3a4654"))
        rect(d, 15, 2, 2, 5, C("#4a5666"))
        d.ellipse([13, 0, 19, 5], fill=C("#ffd23a"))
        mech.append(outline(im))
    save(ga.sheet(mech, 32, 32), "items", "v_mech.png")
    # perseguidor: roca con pinchos (2 giros)
    for name, col in (("rock", "#6a5a52"),):
        ch = []
        for f in range(2):
            im, d = newc(36, 36)
            d.ellipse([2, 2, 33, 33], fill=C(col))
            d.ellipse([6, 5, 20, 16], fill=shade(C(col), 0.2))
            for k in range(8):
                a = k * math.pi / 4 + f * math.pi / 8
                x, y = 18 + math.cos(a) * 16, 18 + math.sin(a) * 16
                d.polygon([(x + math.cos(a) * 4, y + math.sin(a) * 4), (x + math.cos(a + 1.5) * 3, y + math.sin(a + 1.5) * 3),
                           (x + math.cos(a - 1.5) * 3, y + math.sin(a - 1.5) * 3)], fill=C("#c8c8d8"))
            d.ellipse([11, 13, 16, 18], fill=C("#ff3a3a"))
            d.ellipse([20, 13, 25, 18], fill=C("#ff3a3a"))
            rect(d, 12, 23, 12, 3, C("#1a1226"))
            ch.append(outline(im))
        save(ga.sheet(ch, 36, 36), "items", "chaser.png")


# --------------------------------------------------- sombreros y armaduras ---
HATS = ["gorra", "corona", "mago", "explorador", "orejas", "lazo", "halo", "antena", "minero", "flor"]


def hat_img(name):
    im, d = newc(16, 16)
    if name == "gorra":
        d.pieslice([2, 6, 13, 18], 180, 360, fill=C("#e03a3a"))
        rect(d, 8, 11, 8, 2, C("#a02020"))
        px(d, 6, 8, C("#ff9a9a"))
    elif name == "corona":
        rect(d, 3, 9, 10, 4, C("#ffd23a"))
        for x in (3, 7, 11):
            d.polygon([(x, 9), (x + 1, 5), (x + 2, 9)], fill=C("#ffd23a"))
        px(d, 7, 11, C("#ff3a6a"))
        px(d, 4, 11, C("#59d0ff"))
        px(d, 11, 11, C("#59d0ff"))
    elif name == "mago":
        d.polygon([(2, 13), (8, 0), (14, 13)], fill=C("#5a3ab0"))
        rect(d, 1, 12, 14, 2, C("#3a2a80"))
        px(d, 8, 6, C("#ffd23a"))
        px(d, 6, 9, C("#ffd23a"))
    elif name == "explorador":
        d.pieslice([4, 5, 12, 15], 180, 360, fill=C("#c8a060"))
        rect(d, 0, 11, 16, 2, C("#a07a3a"))
        rect(d, 4, 10, 8, 1, C("#5a3a1a"))
    elif name == "orejas":
        d.polygon([(3, 12), (4, 4), (7, 12)], fill=C("#f0a070"))
        d.polygon([(9, 12), (12, 4), (13, 12)], fill=C("#f0a070"))
        d.polygon([(4, 11), (4, 6), (6, 11)], fill=C("#ff9ab0"))
        d.polygon([(10, 11), (12, 6), (12, 11)], fill=C("#ff9ab0"))
    elif name == "lazo":
        d.polygon([(2, 7), (7, 10), (2, 13)], fill=C("#ff5aa0"))
        d.polygon([(14, 7), (9, 10), (14, 13)], fill=C("#ff5aa0"))
        rect(d, 7, 9, 3, 3, C("#c02070"))
    elif name == "halo":
        d.ellipse([3, 7, 12, 11], outline=C("#ffe05a"), width=1)
        px(d, 5, 8, C("#ffffff"))
    elif name == "antena":
        rect(d, 7, 5, 2, 8, C("#9aa6b6"))
        d.ellipse([5, 2, 10, 7], fill=C("#ff3a3a"))
        px(d, 6, 3, C("#ffffff"))
        rect(d, 5, 12, 6, 2, C("#4a5666"))
    elif name == "minero":
        d.pieslice([2, 6, 13, 18], 180, 360, fill=C("#f0c030"))
        rect(d, 1, 12, 14, 2, C("#c08a10"))
        rect(d, 6, 8, 4, 3, C("#fff8c0"))
        px(d, 7, 9, C("#ffffff"))
    elif name == "flor":
        for (x, y) in ((6, 8), (10, 8), (8, 6), (8, 10)):
            d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=C("#ff7ab0"))
        d.ellipse([6, 8, 10, 12], fill=C("#ffe05a"))
    return outline(im)


def gen_hats():
    save(ga.sheet([hat_img(n) for n in HATS], 16, 16), "player", "hats.png")


ARMORS = {"bronce": ("#b8763a", "#e8a060"), "plata": ("#c8d0d8", "#f0f4ff"), "oro": ("#f0c030", "#fff0a0"),
          "cristal": ("#59d0ff", "#d8f8ff"), "obsidiana": ("#3a2a4a", "#9a5ae0")}


def armor_img(name):
    c1, c2 = (C(x) for x in ARMORS[name])
    im, d = newc(16, 16)
    rect(d, 4, 5, 8, 7, c1)
    rect(d, 4, 5, 8, 1, c2)
    rect(d, 6, 7, 4, 3, shade(c1, -0.3))
    px(d, 7, 8, c2)
    d.ellipse([1, 3, 5, 7], fill=c1)
    d.ellipse([11, 3, 15, 7], fill=c1)
    px(d, 2, 4, c2)
    px(d, 12, 4, c2)
    rect(d, 4, 11, 8, 1, shade(c1, -0.4))
    return outline(im)


def gen_armors():
    save(ga.sheet([armor_img(n) for n in ARMORS], 16, 16), "player", "armors.png")


def main():
    gen_chests()
    gen_orbs()
    gen_sgem()
    gen_door()
    gen_vehicles()
    gen_hats()
    gen_armors()
    print("expansión: arte generado")


if __name__ == "__main__":
    main()

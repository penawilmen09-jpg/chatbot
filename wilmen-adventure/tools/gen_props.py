#!/usr/bin/env python3
"""Atrezo (props) por mundo, líquidos/cascadas/pared de fondo y texturas de efectos. Todo procedural (Pillow).

Salidas:
  assets/decor/props_w{1..10}.png   atlas horizontal con los 9 elementos de cada mundo (ver worlds_def.PROPS)
  levels/props_data.gd              rectángulos del atlas (lo lee terrain_chunk.gd)
  assets/tiles/tiles_w{N}.png       se amplía con 6 tiles: 20-21 superficie del líquido, 22 cuerpo, 23-24 cascada, 25 pared
  assets/fx/*.png                   nubes y engranaje para los fondos animados
"""
import math
import os
import random

from PIL import Image, ImageDraw

import gen_art as ga
from gen_art import C, CLEAR, OUTLINE, newc, outline, px, rect, save
from worlds_def import PROPS

ROOT = ga.ROOT


def shade(col, t):
    """t > 0 aclara, t < 0 oscurece (col es una tupla RGBA)."""
    if t >= 0:
        return tuple(int(col[i] + (255 - col[i]) * t) for i in range(3)) + (col[3],)
    return tuple(int(col[i] * (1 + t)) for i in range(3)) + (col[3],)


def blob(d, cx, cy, rx, ry, col):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=col)


# ---------------------------------------------------------------- paleta ---
# Colores por mundo para los elementos: (principal, claro, oscuro, acento, luz)
PAL = {
    1: dict(a="#2f9a44", b="#58c84a", c="#1e6a30", wood="#7a4a26", wood_l="#a06a3a", acc="#ff7ab0", glow="#ffe05a", stone="#8a8a8a"),
    2: dict(a="#59e0f0", b="#b8f4ff", c="#2a7a9a", wood="#6a5a3a", wood_l="#8a7a52", acc="#b080ff", glow="#9af0ff", stone="#6a5cb0"),
    3: dict(a="#e8c070", b="#f8e0a0", c="#b27a30", wood="#8a5a2a", wood_l="#b07a3a", acc="#3a9a4a", glow="#ffb04a", stone="#d9a350"),
    4: dict(a="#dff0ff", b="#ffffff", c="#7ab4e0", wood="#6a4026", wood_l="#8a5a33", acc="#6ac8ff", glow="#ffd04a", stone="#9cc4e8"),
    5: dict(a="#6a5a82", b="#8a7aa2", c="#3d3150", wood="#4a3d60", wood_l="#6a5c82", acc="#b0f0c0", glow="#ff8a2a", stone="#6a5c82"),
    6: dict(a="#f4faff", b="#ffffff", c="#9cc0e8", wood="#c8b896", wood_l="#e8dcc0", acc="#ff7ab0", glow="#fff2a0", stone="#e0e8f0"),
    7: dict(a="#5a4646", b="#7a6060", c="#2a1c1c", wood="#3a2a28", wood_l="#5a4646", acc="#ff6a1a", glow="#ffb02a", stone="#4a3a3a"),
    8: dict(a="#2fa04a", b="#58d868", c="#146a2c", wood="#6a4a26", wood_l="#8a6a3a", acc="#ff7ab0", glow="#c8ff6a", stone="#7a8a6a"),
    9: dict(a="#9aa6b6", b="#d0d8e0", c="#4a5666", wood="#8a5a3a", wood_l="#b08060", acc="#ff3a3a", glow="#ffb02a", stone="#5a6a7a"),
    10: dict(a="#6a3ab0", b="#a07ae8", c="#2a1058", wood="#4a3a7a", wood_l="#6a5aa0", acc="#ffd23a", glow="#ffe05a", stone="#4a3a7a"),
}


def pal(w):
    return {k: C(v) for k, v in PAL[w].items()}


# ------------------------------------------------------------ pintores ---
def p_tree(d, w, h, P, f, style="round"):
    cx = w // 2
    if style == "round":
        tw = max(4, w // 6)
        ga.rect(d, cx - tw // 2, h // 3, tw, h - h // 3, P["wood"])
        ga.rect(d, cx - tw // 2, h // 3, 1, h - h // 3, P["wood_l"])
        ga.rect(d, cx - tw // 2 - 2, h - 5, tw + 4, 5, P["wood"])
        for (ox, oy, r, c) in ((0, 0.28, 0.46, "a"), (-0.3, 0.42, 0.3, "c"), (0.3, 0.42, 0.3, "a"), (0, 0.16, 0.32, "b")):
            blob(d, cx + int(ox * w), int(oy * h), int(r * w * 0.95), int(r * h * 0.55), P[c])
        for k in range(5):
            px(d, cx - w // 5 + k * (w // 8), int(h * 0.2) + (k % 2) * 4, shade(P["b"], 0.4))
    elif style == "palm":
        tw = 4
        for y in range(h // 4, h):
            off = int(math.sin(y / 9.0) * 2)
            ga.rect(d, cx - 2 + off, y, tw, 1, P["wood"] if y % 6 else P["wood_l"])
        top = h // 4
        for ang in (-2.6, -2.1, -1.6, -1.0, -0.5):
            ex = cx + int(math.cos(ang) * w * 0.48)
            ey = top + int(-math.sin(ang) * h * 0.1) + 6
            d.line([(cx, top), (ex, ey)], fill=P["a"], width=3)
            d.line([(cx, top), ((cx + ex) // 2, top - 3)], fill=P["b"], width=2)
        blob(d, cx, top + 2, 3, 3, P["wood_l"])
    elif style == "dead":
        ga.rect(d, cx - 3, h // 3, 6, h - h // 3, P["wood"])
        for (bx, by, dx, dy) in ((cx, h // 3 + 6, -12, -10), (cx, h // 2, 11, -9), (cx, h // 3 + 14, -9, -14), (cx, h // 4 + 8, 8, -8)):
            d.line([(bx, by), (bx + dx, by + dy)], fill=P["wood"], width=2)
            d.line([(bx + dx, by + dy), (bx + dx + (-3 if dx < 0 else 3), by + dy - 5)], fill=P["wood"], width=1)
    elif style == "pine":
        ga.rect(d, cx - 2, h - 8, 4, 8, P["wood"])
        layers = 4
        for k in range(layers):
            y1 = int(h * 0.1 + k * (h * 0.2))
            hw = int(w * (0.22 + 0.07 * k))
            col = P["c"] if k % 2 else shade(P["c"], 0.12)
            d.polygon([(cx - hw, y1 + int(h * 0.26)), (cx, y1), (cx + hw, y1 + int(h * 0.26))], fill=col)
            d.polygon([(cx - hw + 2, y1 + int(h * 0.13)), (cx, y1), (cx + hw - 2, y1 + int(h * 0.13))], fill=P["b"])
    elif style == "cloud":
        ga.rect(d, cx - 2, h // 2, 4, h // 2, P["wood"])
        for (ox, oy, r) in ((0, 0.3, 0.4), (-0.3, 0.4, 0.28), (0.3, 0.4, 0.28)):
            blob(d, cx + int(ox * w), int(oy * h), int(r * w), int(r * h * 0.6), P["b"])
        blob(d, cx - 4, int(h * 0.22), 6, 4, shade(P["acc"], 0.2))
    elif style == "burnt":
        ga.rect(d, cx - 3, h // 3, 6, h - h // 3, P["c"])
        for (dx, dy, l) in ((-1, 0.4, 9), (1, 0.3, 11), (-1, 0.22, 7)):
            d.line([(cx, int(h * dy) + 6), (cx + dx * l, int(h * dy) - 4)], fill=P["c"], width=2)
        px(d, cx - 2, h // 2, P["acc"])
        px(d, cx + 2, h // 2 + 6, P["glow"])


def p_jungle_tree(d, w, h, P, f):
    cx = w // 2
    tw = 12
    ga.rect(d, cx - tw // 2, 14, tw, h - 14, P["wood"])
    ga.rect(d, cx - tw // 2, 14, 2, h - 14, P["wood_l"])
    ga.rect(d, cx - tw // 2 - 4, h - 8, tw + 8, 8, P["wood"])  # raíces
    d.polygon([(cx - tw // 2, h - 14), (cx - 16, h), (cx - tw // 2, h)], fill=P["wood"])
    d.polygon([(cx + tw // 2, h - 14), (cx + 16, h), (cx + tw // 2, h)], fill=P["wood"])
    for (ox, oy, rx, ry, c) in ((0, 12, 22, 12, "a"), (-14, 22, 12, 8, "c"), (14, 22, 12, 8, "a"), (0, 6, 14, 8, "b")):
        blob(d, cx + ox, oy, rx, ry, P[c])
    for vx in (cx - 8, cx + 7):  # lianas
        d.line([(vx, 22), (vx + 2, 52)], fill=P["c"], width=1)


def p_crystals(d, w, h, P, f, n=3, big=False):
    base = h - 1
    cols = [P["a"], P["b"], P["acc"]]
    for i in range(n):
        x = int((i + 0.5) * w / n)
        ch = int(h * (0.55 + 0.45 * (1 if i == n // 2 else 0.6)))
        cw = max(3, int(w / n * 0.55))
        c = cols[i % 3]
        d.polygon([(x - cw, base), (x - cw // 2, base - ch + 5), (x, base - ch), (x + cw // 2, base - ch + 5), (x + cw, base)], fill=c)
        d.polygon([(x, base - ch), (x + cw // 2, base - ch + 5), (x + cw, base), (x, base)], fill=shade(c, -0.28))
        d.line([(x - cw // 2, base - ch // 2), (x - cw // 2 + 1, base - ch + 8)], fill=shade(c, 0.6), width=1)


def p_hang_crystal(d, w, h, P, f, col="c", points=2):
    cx = w // 2
    for (dx, l, ww) in ((0, h - 1, 5), (-5, int(h * 0.55), 3), (5, int(h * 0.7), 3)):
        d.polygon([(cx + dx - ww, 0), (cx + dx, l), (cx + dx + ww, 0)], fill=P[col])
        d.polygon([(cx + dx, 0), (cx + dx, l), (cx + dx + ww, 0)], fill=shade(P[col], -0.25))


def p_rocks(d, w, h, P, f, col="stone"):
    c = P[col]
    for (ox, oy, rx, ry, t) in ((0.3, 0.7, 0.3, 0.5, 0), (0.6, 0.75, 0.26, 0.42, -0.15), (0.82, 0.8, 0.18, 0.3, 0.1)):
        d.ellipse([int(ox * w - rx * w), int(oy * h - ry * h), int(ox * w + rx * w), h - 1], fill=shade(c, t))
        d.arc([int(ox * w - rx * w) + 1, int(oy * h - ry * h) + 1, int(ox * w + rx * w) - 1, h - 3], 200, 290, fill=shade(c, 0.4))


def p_tuft(d, w, h, P, f, col="b", acc=None):
    for i in range(int(w / 3)):
        x = 2 + i * 3
        l = h - 2 - (i % 3) * 2
        d.line([(x, h - 1), (x + (i % 3) - 1, h - 1 - l)], fill=P[col] if i % 2 else P["a"], width=1)
    if acc:
        for i in range(2):
            px(d, 5 + i * (w - 12), h // 3, P[acc])


def p_bush(d, w, h, P, f):
    blob(d, w // 2, h - 5, w // 2 - 1, 5, P["a"])
    blob(d, w // 2 - 3, h - 7, 4, 4, P["b"])
    for (x, y) in ((3, h - 7), (w - 5, h - 6), (w // 2, h - 9)):
        px(d, x, y, P["acc"])
        px(d, x + 1, y, shade(P["acc"], 0.5))


def p_mushroom(d, w, h, P, f, glow=True):
    cx = w // 2
    ga.rect(d, cx - 1, h // 2, 3, h // 2, shade(P["b"], 0.2))
    cap = P["acc"] if not glow else P["a"]
    d.pieslice([2, 1, w - 3, h - 2 + (h // 2)], 180, 360, fill=cap)
    px(d, cx - 3, 4, shade(cap, 0.6))
    px(d, cx + 2, 5, shade(cap, 0.6))
    if glow and f == 1:
        px(d, cx - 5, 2, P["glow"])
        px(d, cx + 5, 3, P["glow"])
        px(d, cx, 0, P["glow"])


def p_flower(d, w, h, P, f):
    cx = w // 2 + (1 if f else -1)
    d.line([(cx, h - 1), (w // 2, h // 2 + 3)], fill=P["c"], width=1)
    for (ox, oy) in ((-2, 0), (2, 0), (0, -2), (0, 2)):
        px(d, cx + ox, h // 2 + 1 + oy, P["acc"])
    px(d, cx, h // 2 + 1, P["glow"])
    d.line([(1, h - 1), (4 + f, h - 6)], fill=P["a"], width=1)
    d.line([(w - 2, h - 1), (w - 5 - f, h - 7)], fill=P["a"], width=1)


def p_torch(d, w, h, P, f, style="torch"):
    cx = w // 2
    if style == "torch":
        ga.rect(d, cx - 1, h // 2, 3, h // 2, P["wood"])
        ga.rect(d, cx - 3, h // 2 - 2, 7, 3, P["stone"])
    else:  # brasero
        ga.rect(d, cx - 4, h - 8, 9, 3, P["stone"])
        ga.rect(d, cx - 1, h - 6, 3, 6, P["wood"])
        ga.rect(d, cx - 5, h - 10, 11, 3, P["stone"])
    fy = h // 2 - 3 if style == "torch" else h - 12
    fh = 8 + (2 if f else 0)
    d.polygon([(cx, fy - fh), (cx - 4, fy + 1), (cx + 4, fy + 1)], fill=C("#ff8a2a") if "glow" not in P else shade(P["acc"] if style == "braz" else C("#ff8a2a"), 0))
    d.polygon([(cx, fy - fh + 3), (cx - 2, fy + 1), (cx + 2, fy + 1)], fill=P["glow"])
    if f:
        px(d, cx - 5, fy - fh // 2, P["glow"])


def p_flame(d, w, h, P, f, col):
    cx = w // 2
    ga.rect(d, cx - 4, h - 8, 9, 3, P["stone"])
    ga.rect(d, cx - 1, h - 6, 3, 6, P["wood"])
    ga.rect(d, cx - 5, h - 11, 11, 3, P["stone"])
    fh = 10 + 2 * f
    d.polygon([(cx, h - 12 - fh), (cx - 5, h - 11), (cx + 5, h - 11)], fill=col)
    d.polygon([(cx, h - 12 - fh + 4), (cx - 2, h - 11), (cx + 2, h - 11)], fill=P["glow"])


def p_lantern(d, w, h, P, f):
    cx = w // 2
    ga.rect(d, cx - 1, 6, 3, h - 6, P["wood"])
    ga.rect(d, cx - 4, 2, 9, 7, P["stone"])
    ga.rect(d, cx - 3, 3, 7, 5, P["glow"] if f == 0 else shade(P["glow"], 0.4))
    d.line([(cx - 4, 2), (cx, 0), (cx + 4, 2)], fill=P["wood"])


def p_hang(d, w, h, P, f, kind):
    cx = w // 2
    if kind == "vines":
        for i, dx in enumerate((-4, 0, 4)):
            l = h - 2 - i * 6
            d.line([(cx + dx, 0), (cx + dx + (i - 1), l)], fill=P["a"], width=2)
            for k in range(2, l, 7):
                blob(d, cx + dx + (i - 1) * k // max(1, l), k, 2, 2, P["b"])
            px(d, cx + dx + (i - 1), l, P["acc"])
    elif kind == "icicle":
        for (dx, l, ww) in ((0, h - 1, 3), (-5, int(h * 0.6), 2), (5, int(h * 0.75), 2)):
            d.polygon([(cx + dx - ww, 0), (cx + dx, l), (cx + dx + ww, 0)], fill=P["b"])
            d.polygon([(cx + dx, 0), (cx + dx, l), (cx + dx + ww, 0)], fill=P["acc"])
    elif kind == "cloth":
        ga.rect(d, cx - 6, 0, 12, 2, P["wood"])
        d.polygon([(cx - 5, 2), (cx + 5, 2), (cx + 5, h - 6), (cx, h - 1), (cx - 5, h - 6)], fill=P["acc"])
        ga.rect(d, cx - 5, 8, 10, 2, P["glow"])
    elif kind == "chain":
        for y in range(0, h - 10, 4):
            ga.rect(d, cx, y, 2, 3, P["stone"])
        ga.rect(d, cx - 5, h - 12, 12, 11, P["acc"] if f == 0 else P["acc"])
        d.polygon([(cx - 5, h - 1), (cx + 6, h - 1), (cx + 1, h - 5)], fill=OUTLINE)
        ga.rect(d, cx - 3, h - 9, 8, 2, P["glow"])
    elif kind == "basket":
        d.line([(cx - 5, 0), (cx - 4, 10)], fill=P["wood"])
        d.line([(cx + 5, 0), (cx + 4, 10)], fill=P["wood"])
        ga.rect(d, cx - 6, 10, 12, 8, P["wood_l"])
        blob(d, cx - 2, 9, 4, 3, P["a"])
        blob(d, cx + 3, 8, 3, 3, P["acc"])
    elif kind == "cable":
        for i, dx in enumerate((-3, 3)):
            d.line([(cx + dx, 0), (cx + dx + (i * 2 - 1), h - 4)], fill=P["stone"], width=2)
        ga.rect(d, cx - 5, h - 8, 10, 6, P["acc"])
        px(d, cx, h - 6, P["glow"])
    elif kind == "banner":
        ga.rect(d, cx - 6, 0, 12, 2, P["glow"])
        d.polygon([(cx - 5, 2), (cx + 5, 2), (cx + 5, h - 8), (cx, h - 1), (cx - 5, h - 8)], fill=P["a"])
        d.polygon([(cx - 2, 8), (cx, 5), (cx + 2, 8), (cx, 14)], fill=P["acc"])


def p_spire(d, w, h, P, f, gothic=True):
    cx = w // 2
    bw = w - 10
    ga.rect(d, cx - bw // 2, h // 3, bw, h - h // 3, P["a"])
    ga.rect(d, cx - bw // 2, h // 3, 3, h - h // 3, P["b"])
    ga.rect(d, cx + bw // 2 - 3, h // 3, 3, h - h // 3, P["c"])
    d.polygon([(cx - bw // 2 - 3, h // 3 + 2), (cx, 2), (cx + bw // 2 + 3, h // 3 + 2)], fill=P["c"])
    d.polygon([(cx, 2), (cx + bw // 2 + 3, h // 3 + 2), (cx, h // 3 + 2)], fill=shade(P["c"], -0.3))
    for k in range(3):
        ga.rect(d, cx - 2, h // 3 + 8 + k * 16, 4, 8, P["glow"])
        px(d, cx - 1, h // 3 + 8 + k * 16 - 1, P["glow"])
    ga.rect(d, cx - bw // 2 - 3, h - 6, bw + 6, 6, P["a"])
    d.line([(cx, 2), (cx, -0)], fill=P["glow"])


def p_obelisk(d, w, h, P, f):
    cx = w // 2
    d.polygon([(cx - 5, h), (cx - 4, 8), (cx, 0), (cx + 4, 8), (cx + 5, h)], fill=P["a"])
    d.polygon([(cx, 0), (cx + 4, 8), (cx + 5, h), (cx, h)], fill=P["c"])
    for y in range(14, h - 6, 8):
        ga.rect(d, cx - 1, y, 3, 3, P["glow"])


def p_column(d, w, h, P, f, broken=True):
    cx = w // 2
    cw = w - 8
    top = 8 if broken else 0
    ga.rect(d, cx - cw // 2, top, cw, h - top, P["a"])
    ga.rect(d, cx - cw // 2, top, 2, h - top, P["b"])
    ga.rect(d, cx + cw // 2 - 2, top, 2, h - top, P["c"])
    ga.rect(d, cx - cw // 2 - 3, h - 5, cw + 6, 5, P["b"])
    ga.rect(d, cx - cw // 2 - 3, top - 3, cw + 6, 4, P["b"])
    if broken:
        d.polygon([(cx - cw // 2, top - 3), (cx - 2, top - 8), (cx + 1, top - 4), (cx + cw // 2, top - 6), (cx + cw // 2, top - 3)], fill=P["b"])


def p_pyramid(d, w, h, P, f):
    cx = w // 2
    d.polygon([(2, h - 1), (cx, 3), (w - 3, h - 1)], fill=P["a"])
    d.polygon([(cx, 3), (w - 3, h - 1), (cx, h - 1)], fill=P["c"])
    for k in range(5):
        y = 12 + k * 10
        d.line([(cx - (y - 3) * (cx - 2) // (h - 4), y), (cx + (y - 3) * (cx - 2) // (h - 4), y)], fill=shade(P["a"], -0.2))
    ga.rect(d, cx - 4, h - 14, 8, 13, OUTLINE)
    ga.rect(d, cx - 3, h - 13, 6, 12, shade(P["glow"], -0.3))
    px(d, cx, 8, P["glow"])


def p_arch(d, w, h, P, f, moss=False):
    cw = 9
    for xx in (2, w - cw - 2):
        ga.rect(d, xx, 10, cw, h - 10, P["a"])
        ga.rect(d, xx, 10, 2, h - 10, P["b"])
        ga.rect(d, xx - 2, h - 5, cw + 4, 5, P["b"])
    d.pieslice([2, 0, w - 3, 26], 180, 360, fill=P["a"])
    d.pieslice([2 + cw, 8, w - 3 - cw, 24], 180, 360, fill=CLEAR)
    ga.rect(d, 0, 0, 0, 0, CLEAR)
    d.line([(w // 2, 0), (w // 2, 4)], fill=P["b"])
    if moss:
        for x in range(3, w - 3, 4):
            blob(d, x, 8 + (x % 3), 2, 2, P["acc"])
    else:
        ga.rect(d, w // 2 - 1, 6, 3, 4, P["glow"])


def p_cabin(d, w, h, P, f, igloo=False):
    cx = w // 2
    if igloo:
        d.pieslice([2, 2, w - 3, h * 2 - 4], 180, 360, fill=P["b"])
        for k in range(1, 4):
            d.arc([2 + k * 3, 2 + k * 3, w - 3 - k * 3, h * 2 - 4 - k * 3], 180, 360, fill=P["c"])
        ga.rect(d, cx - 4, h - 10, 8, 9, OUTLINE)
        return
    ga.rect(d, 3, h // 2, w - 6, h // 2, P["wood_l"])
    for y in range(h // 2 + 3, h, 5):
        ga.rect(d, 3, y, w - 6, 1, P["wood"])
    d.polygon([(0, h // 2 + 2), (cx, 1), (w - 1, h // 2 + 2)], fill=P["b"])
    d.polygon([(2, h // 2 + 2), (cx, 4), (w - 3, h // 2 + 2)], fill=P["c"])
    ga.rect(d, cx - 3, h - 12, 6, 11, P["wood"])
    ga.rect(d, 6, h // 2 + 4, 5, 5, P["glow"])


def p_crypt(d, w, h, P, f):
    cx = w // 2
    ga.rect(d, 3, 8, w - 6, h - 8, P["a"])
    d.polygon([(0, 10), (cx, 0), (w - 1, 10)], fill=P["c"])
    ga.rect(d, cx - 6, h - 20, 12, 19, OUTLINE)
    d.pieslice([cx - 6, h - 26, cx + 6, h - 14], 180, 360, fill=OUTLINE)
    ga.rect(d, cx - 5, h - 18, 10, 17, shade(P["c"], -0.5))
    px(d, cx + 2, h - 10, P["glow"])
    for xx in (5, w - 8):
        ga.rect(d, xx, 14, 3, h - 18, P["b"])


def p_tomb(d, w, h, P, f, cross=False):
    cx = w // 2
    if cross:
        ga.rect(d, cx - 1, 2, 3, h - 2, P["a"])
        ga.rect(d, cx - 5, 6, 11, 3, P["a"])
        ga.rect(d, cx - 5, 6, 11, 1, P["b"])
    else:
        d.pieslice([cx - 6, 0, cx + 6, 14], 180, 360, fill=P["a"])
        ga.rect(d, cx - 6, 7, 12, h - 7, P["a"])
        ga.rect(d, cx - 6, 7, 2, h - 7, P["b"])
        ga.rect(d, cx - 2, 7, 4, 1, P["c"])
        ga.rect(d, cx - 1, 6, 2, 5, P["c"])


def p_ghost(d, w, h, P, f):
    cx = w // 2
    oy = f * 2
    col = shade(P["acc"], 0.5)
    d.pieslice([cx - 6, 2 + oy, cx + 6, 16 + oy], 180, 360, fill=col)
    ga.rect(d, cx - 6, 9 + oy, 12, 9, col)
    for k in range(3):
        d.polygon([(cx - 6 + k * 4, 18 + oy), (cx - 4 + k * 4, 22 + oy - (k % 2) * 2), (cx - 2 + k * 4, 18 + oy)], fill=col)
    ga.rect(d, cx - 3, 8 + oy, 2, 3, OUTLINE)
    ga.rect(d, cx + 1, 8 + oy, 2, 3, OUTLINE)


def p_totem(d, w, h, P, f):
    cx = w // 2
    ga.rect(d, cx - 5, 2, 10, h - 2, P["wood"])
    ga.rect(d, cx - 5, 2, 2, h - 2, P["wood_l"])
    for k in range(3):
        y = 4 + k * 9
        ga.rect(d, cx - 4, y, 8, 7, P["a"] if k % 2 else P["wood_l"])
        ga.rect(d, cx - 3, y + 2, 2, 2, OUTLINE)
        ga.rect(d, cx + 1, y + 2, 2, 2, OUTLINE)
        ga.rect(d, cx - 2, y + 5, 4, 1, P["acc"])
    d.polygon([(cx - 6, 4), (cx - 9, 0), (cx - 5, 8)], fill=P["acc"])
    d.polygon([(cx + 6, 4), (cx + 9, 0), (cx + 5, 8)], fill=P["acc"])


def p_snowman(d, w, h, P, f):
    cx = w // 2
    blob(d, cx, h - 6, 6, 6, P["b"])
    blob(d, cx, h - 14, 4, 4, P["b"])
    px(d, cx - 1, h - 15, OUTLINE)
    px(d, cx + 2, h - 15, OUTLINE)
    px(d, cx + 1, h - 13, C("#ff8a2a"))
    ga.rect(d, cx - 4, h - 19, 8, 2, P["acc"])
    px(d, cx, h - 8, OUTLINE)
    px(d, cx, h - 5, OUTLINE)


def p_pole(d, w, h, P, f, kind="post"):
    cx = w // 2
    ga.rect(d, cx - 1, 4, 3, h - 4, P["wood"])
    ga.rect(d, cx - 1, 4, 1, h - 4, P["wood_l"])
    if kind == "post":
        ga.rect(d, cx - 3, 2, 7, 3, P["wood_l"])
        ga.rect(d, cx - 5, h - 4, 11, 4, P["wood"])
        d.line([(cx + 2, 6), (w - 1, 12)], fill=P["stone"])
    elif kind == "lamp":
        blob(d, cx, 4, 4, 4, P["glow"])
        ga.rect(d, cx - 4, h - 3, 9, 3, P["wood_l"])
    elif kind == "flag":
        ga.rect(d, cx - 5, 8, 11, h - 8, P["a"])
        for xx in (cx - 5, cx - 1, cx + 3):
            ga.rect(d, xx, 5, 3, 3, P["a"])
        d.polygon([(cx + 1, 0), (cx + 8, 3), (cx + 1, 6)], fill=P["acc"])
        ga.rect(d, cx, 0, 1, 8, P["stone"])


def p_log(d, w, h, P, f):
    ga.rect(d, 1, h - 8, w - 2, 8, P["wood"])
    ga.rect(d, 1, h - 8, w - 2, 1, P["wood_l"])
    blob(d, 3, h - 4, 2, 3, P["wood_l"])
    for (x, y, c) in ((10, h - 10, "acc"), (18, h - 9, "acc"), (24, h - 10, "glow")):
        d.pieslice([x - 3, y - 3, x + 3, y + 4], 180, 360, fill=P[c])
        ga.rect(d, x - 1, y, 2, 2, shade(P["b"], 0.3))


def p_cactus(d, w, h, P, f):
    cx = w // 2
    ga.rect(d, cx - 3, 4, 6, h - 4, P["acc"])
    ga.rect(d, cx - 3, 4, 1, h - 4, shade(P["acc"], 0.3))
    ga.rect(d, cx - 9, 10, 6, 3, P["acc"])
    ga.rect(d, cx - 9, 5, 3, 7, P["acc"])
    ga.rect(d, cx + 3, 13, 6, 3, P["acc"])
    ga.rect(d, cx + 6, 8, 3, 8, P["acc"])
    px(d, cx, 2, C("#ff6a8a"))


def p_bones(d, w, h, P, f, pot=False):
    if pot:
        blob(d, 5, h - 5, 4, 5, P["wood_l"])
        ga.rect(d, 3, h - 11, 5, 2, P["wood"])
        d.line([(10, h - 2), (15, h - 5)], fill=P["b"], width=2)
        blob(d, 12, h - 4, 2, 2, P["b"])
    else:
        for xx in range(2, w - 2, 7):
            d.line([(xx, h - 1), (xx + 5, h - 3)], fill=P["b"], width=2)
        blob(d, w // 2, h - 4, 3, 3, P["b"])
        px(d, w // 2 - 1, h - 4, OUTLINE)
        px(d, w // 2 + 1, h - 4, OUTLINE)


def p_smokestack(d, w, h, P, f):
    cx = w // 2
    ga.rect(d, cx - 7, 24, 14, h - 24, P["a"])
    ga.rect(d, cx - 7, 24, 3, h - 24, P["b"])
    ga.rect(d, cx + 4, 24, 3, h - 24, P["c"])
    ga.rect(d, cx - 9, 20, 18, 5, P["c"])
    for y in range(34, h - 6, 12):
        ga.rect(d, cx - 7, y, 14, 2, P["acc"])
    ga.rect(d, cx - 10, h - 6, 20, 6, P["c"])
    sx = f * 2
    for (ox, oy, r, a) in ((0, 12, 6, 200), (3 + sx, 5, 5, 160), (-2 - sx, -1, 4, 120)):
        blob(d, cx + ox, max(r, oy), r, r, shade(P["b"], 0.1)[:3] + (a,))


def p_pipes(d, w, h, P, f, tower=False):
    if tower:
        cx = w // 2
        ga.rect(d, cx - 8, 6, 16, h - 6, P["a"])
        ga.rect(d, cx - 8, 6, 3, h - 6, P["b"])
        for y in (12, 26, 40):
            ga.rect(d, cx - 10, y, 20, 3, P["c"])
        ga.rect(d, cx - 4, 0, 8, 7, P["c"])
        px(d, cx, 20, P["glow"])
        px(d, cx, 34, P["acc"])
    else:
        ga.rect(d, 0, h - 6, w, 5, P["a"])
        ga.rect(d, 0, h - 6, w, 1, P["b"])
        ga.rect(d, 6, h - 11, 5, 6, P["a"])
        ga.rect(d, w - 11, h - 11, 5, 6, P["a"])
        for xx in (8, 18, 26):
            ga.rect(d, xx, h - 7, 2, 7, P["c"])


def p_crate(d, w, h, P, f, barrel=False):
    if barrel:
        blob(d, w // 2, h // 2, w // 2 - 1, h // 2 - 1, P["wood_l"])
        ga.rect(d, 1, 4, w - 2, 2, P["stone"])
        ga.rect(d, 1, h - 6, w - 2, 2, P["stone"])
        return
    ga.rect(d, 1, 1, w - 2, h - 2, P["wood_l"])
    ga.rect(d, 1, 1, w - 2, 2, P["wood"])
    ga.rect(d, 1, h - 3, w - 2, 2, P["wood"])
    d.line([(2, 2), (w - 3, h - 3)], fill=P["wood"])
    d.line([(w - 3, 2), (2, h - 3)], fill=P["wood"])


def p_vent(d, w, h, P, f, steam=True):
    cx = w // 2
    ga.rect(d, cx - 5, h - 7, 10, 7, P["stone"])
    ga.rect(d, cx - 3, h - 8, 6, 2, P["c"])
    for k in range(3):
        blob(d, cx + (k % 2) * 2 - 1 + f, h - 12 - k * 5 - f * 2, 3 + k, 3 + k // 2, shade(P["b"], 0.2)[:3] + (210 - k * 50,))


def p_machine(d, w, h, P, f):
    ga.rect(d, 1, 6, w - 2, h - 6, P["a"])
    ga.rect(d, 1, 6, w - 2, 2, P["b"])
    ga.rect(d, 1, h - 3, w - 2, 3, P["c"])
    ga.rect(d, 5, 11, 12, 9, OUTLINE)
    ga.rect(d, 6, 12, 10, 7, P["glow"])
    for k in range(3):
        blob(d, 24 + k * 5, 14, 2, 2, P["acc"] if k == 0 else P["stone"])
    ga.rect(d, 8, 0, 4, 6, P["stone"])
    ga.rect(d, 28, 2, 6, 4, P["c"])


def p_gear(d, w, h, P, f):
    cx, cy = w // 2, h // 2
    r = w // 2 - 3
    rot = f * math.pi / 8
    for k in range(8):
        a = k * math.pi / 4 + rot
        x = cx + math.cos(a) * (r + 1)
        y = cy + math.sin(a) * (r + 1)
        d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=P["c"])
    blob(d, cx, cy, r, r, P["a"])
    blob(d, cx, cy, r - 4, r - 4, P["b"])
    for k in range(4):
        a = k * math.pi / 2 + rot
        d.line([(cx, cy), (cx + math.cos(a) * (r - 4), cy + math.sin(a) * (r - 4))], fill=P["c"], width=2)
    blob(d, cx, cy, 3, 3, P["acc"])


def p_windmill(d, w, h, P, f, small=False):
    cx = w // 2
    top = 10 if not small else 7
    d.polygon([(cx - w // 5, h), (cx - w // 8, top), (cx + w // 8, top), (cx + w // 5, h)], fill=P["wood_l"])
    d.polygon([(cx, top), (cx + w // 8, top), (cx + w // 5, h), (cx, h)], fill=P["wood"])
    d.polygon([(cx - w // 7, top), (cx, top - 6), (cx + w // 7, top)], fill=P["acc"])
    bl = w // 2 - 2
    rot = f * math.pi / 4 + 0.3
    for k in range(4):
        a = k * math.pi / 2 + rot
        ex, ey = cx + math.cos(a) * bl, top + math.sin(a) * bl
        d.line([(cx, top), (ex, ey)], fill=P["b"], width=3 if not small else 2)
        d.line([(cx, top), (ex, ey)], fill=P["wood"], width=1)
    blob(d, cx, top, 2, 2, P["acc"])
    if not small:
        ga.rect(d, cx - 3, h - 12, 6, 11, P["wood"])


def p_pagoda(d, w, h, P, f):
    cx = w // 2
    for k in range(3):
        y = 18 + k * 20
        ww = 11 - k * 2
        ga.rect(d, cx - ww, y, ww * 2, 14, P["b"])
        ga.rect(d, cx - ww, y, 3, 14, P["c"])
        ga.rect(d, cx - 2, y + 4, 4, 6, P["glow"])
        d.polygon([(cx - ww - 6, y + 1), (cx, y - 9), (cx + ww + 6, y + 1)], fill=P["acc"])
        d.polygon([(cx, y - 9), (cx + ww + 6, y + 1), (cx, y + 1)], fill=shade(P["acc"], -0.25))
    ga.rect(d, cx - 1, 0, 2, 12, P["wood"])
    blob(d, cx, 2, 2, 2, P["glow"])
    d.polygon([(cx - 22, h - 6), (cx + 22, h - 6), (cx + 12, h - 1), (cx - 12, h - 1)], fill=P["wood_l"])


def p_volcano(d, w, h, P, f):
    cx = w // 2
    d.polygon([(0, h), (cx - 7, 12), (cx + 7, 12), (w - 1, h)], fill=P["a"])
    d.polygon([(cx, 12), (cx + 7, 12), (w - 1, h), (cx, h)], fill=P["c"])
    d.polygon([(cx - 7, 12), (cx - 4, 8), (cx + 4, 8), (cx + 7, 12)], fill=P["acc"])
    d.polygon([(cx - 4, 8), (cx, 3), (cx + 4, 8)], fill=P["glow"])
    d.line([(cx, 14), (cx - 5, h - 8)], fill=P["acc"], width=2)
    d.line([(cx + 3, 18), (cx + 8, h - 12)], fill=P["acc"], width=1)


def p_obsidian(d, w, h, P, f):
    p_crystals(d, w, h, dict(P, a=C("#2a1a3a"), b=C("#5a3a7a"), acc=C("#ff6a1a")), f, n=2)


def p_anvil(d, w, h, P, f):
    ga.rect(d, 6, h - 8, 20, 8, P["wood"])
    ga.rect(d, 3, h - 14, 26, 6, P["a"])
    d.polygon([(26, h - 14), (31, h - 13), (26, h - 9)], fill=P["a"])
    ga.rect(d, 3, h - 14, 26, 1, P["b"])
    px(d, 20, h - 16, P["glow"])
    px(d, 22, h - 18, P["acc"])


def p_vent_ember(d, w, h, P, f):
    cx = w // 2
    d.polygon([(1, h), (4, h - 6), (w - 5, h - 6), (w - 2, h)], fill=P["a"])
    ga.rect(d, 4, h - 8, w - 8, 3, P["acc"] if f == 0 else P["glow"])
    px(d, cx - 2, h - 10 - f * 2, P["glow"])
    px(d, cx + 3, h - 13 + f, P["acc"])
    px(d, cx, h - 15 - f * 2, P["glow"])


def p_giant_mushroom(d, w, h, P, f):
    cx = w // 2
    ga.rect(d, cx - 3, h // 2, 6, h // 2, shade(P["b"], 0.35))
    d.pieslice([1, 1, w - 2, h], 180, 360, fill=P["acc"])
    for (x, y) in ((6, 8), (14, 5), (w - 8, 9), (cx, 12)):
        blob(d, x, y, 2, 2, shade(P["b"], 0.6))


def p_glow_flower(d, w, h, P, f):
    cx = w // 2
    d.line([(cx, h - 1), (cx, 7)], fill=P["a"], width=2)
    for k in range(5):
        a = k * 2 * math.pi / 5
        blob(d, cx + math.cos(a) * 4, 6 + math.sin(a) * 4, 2, 2, P["acc"])
    blob(d, cx, 6, 2, 2, P["glow"] if f == 0 else shade(P["glow"], 0.5))
    d.line([(1, h - 1), (cx - 2, h - 8)], fill=P["a"], width=1)


def p_orb(d, w, h, P, f):
    cx = w // 2
    ga.rect(d, cx - 6, h - 8, 12, 8, P["a"])
    ga.rect(d, cx - 4, h - 14, 8, 6, P["b"])
    oy = f * 2
    blob(d, cx, h - 22 - oy, 5, 5, P["acc"])
    blob(d, cx - 1, h - 24 - oy, 2, 2, shade(P["glow"], 0.6))
    px(d, cx - 7, h - 24 - oy, P["glow"])
    px(d, cx + 7, h - 20 - oy, P["glow"])


def p_gem_float(d, w, h, P, f):
    cx = w // 2
    oy = f * 2
    d.polygon([(cx, 1 + oy), (cx + 6, 7 + oy), (cx, 14 + oy), (cx - 6, 7 + oy)], fill=P["acc"])
    d.polygon([(cx, 1 + oy), (cx + 6, 7 + oy), (cx, 14 + oy)], fill=shade(P["acc"], -0.25))
    px(d, cx - 2, 5 + oy, C("#ffffff"))


def p_portal(d, w, h, P, f):
    cx = w // 2
    for xx in (3, w - 12):
        ga.rect(d, xx, 10, 9, h - 10, P["a"])
        ga.rect(d, xx, 10, 2, h - 10, P["b"])
        ga.rect(d, xx - 2, h - 6, 13, 6, P["b"])
        ga.rect(d, xx - 2, 6, 13, 5, P["acc"])
    d.pieslice([3, 0, w - 4, 30], 180, 360, fill=P["a"])
    d.pieslice([12, 8, w - 13, 28], 180, 360, fill=P["c"])
    ga.rect(d, 12, 18, w - 24, h - 24, P["c"])
    for k in range(5):
        px(d, 15 + k * 4, 22 + (k * 7) % 14, P["glow"])
    blob(d, cx, 5, 3, 3, P["glow"])


def p_island_tree(d, w, h, P, f):
    p_tree(d, w, h, P, f, style="cloud")


# ------------------------------------------------------- tabla por mundo ---
def painter(world, slot):
    """Devuelve (función de dibujo (d,w,h,P,f)) para el elemento `slot` (1-9) del mundo."""
    T = lambda fn, **kw: (lambda d, w, h, P, f: fn(d, w, h, P, f, **kw))
    t = {
        1: [T(p_tree, style="round"), T(p_tree, style="round"), p_bush, T(p_tuft, col="b", acc="acc"),
            p_flower, T(p_pole, kind="post"), T(p_hang, kind="vines"), p_log, T(p_tuft, col="b")],
        2: [T(p_crystals, n=3, big=True), T(p_crystals, n=2), T(p_crystals, n=3), p_mushroom, T(p_crystals, n=1),
            T(p_pole, kind="post"), T(p_hang_crystal, col="a"), p_lantern, T(p_rocks, col="stone")],
        3: [p_pyramid, T(p_tree, style="palm"), p_cactus, T(p_bones, pot=True), T(p_torch, style="torch"), T(p_arch, moss=False),
            T(p_hang, kind="cloth"), p_obelisk, T(p_rocks, col="stone")],
        4: [T(p_crystals, n=3, big=True), T(p_tree, style="pine"), T(p_rocks, col="b"), T(p_crystals, n=2), p_lantern,
            T(p_cabin, igloo=False), T(p_hang, kind="icicle"), p_snowman, T(p_rocks, col="stone")],
        5: [p_spire, T(p_tree, style="dead"), T(p_tomb, cross=False), T(p_tomb, cross=True), T(p_torch, style="braz"), p_crypt,
            T(p_hang, kind="chain"), p_ghost, T(p_bones, pot=False)],
        6: [p_pagoda, T(p_tree, style="cloud"), p_bush, T(p_pole, kind="flag"), T(p_windmill, small=True), T(p_pole, kind="lamp"),
            T(p_hang, kind="basket"), p_windmill, T(p_rocks, col="b")],
        7: [p_volcano, p_obsidian, T(p_rocks, col="stone"), p_vent_ember, T(p_flame, col=C("#ff5a1a")), p_anvil,
            T(p_hang_crystal, col="acc"), T(p_tree, style="burnt"), T(p_rocks, col="stone")],
        8: [p_jungle_tree, T(p_tree, style="palm"), T(p_tuft, col="b", acc="acc"), p_totem, p_glow_flower, T(p_arch, moss=True),
            T(p_hang, kind="vines"), p_giant_mushroom, T(p_tuft, col="a")],
        9: [p_smokestack, T(p_pipes, tower=True), T(p_crate), T(p_crate, barrel=True), p_vent, p_machine,
            T(p_hang, kind="cable"), p_gear, T(p_pipes)],
        10: [p_spire, T(p_column, broken=True), T(p_crystals, n=2), p_gem_float, T(p_flame, col=C("#a04aff")), p_portal,
             T(p_hang, kind="banner"), p_orb, T(p_rocks, col="stone")],
    }
    return t[world][slot - 1]


def gen_props():
    data = {}
    for w in PROPS:
        P = pal(w)
        specs = PROPS[w]
        tw = sum(s[1] * s[3] for s in specs)
        th = max(s[2] for s in specs)
        atlas = Image.new("RGBA", (tw, th), CLEAR)
        x = 0
        entries = []
        for slot, (name, pw, ph, frames, anchor) in enumerate(specs, start=1):
            for f in range(frames):
                im, d = newc(pw, ph)
                painter(w, slot)(d, pw, ph, P, f)
                im = outline(im)
                atlas.paste(im, (x + f * pw, 0))
            entries.append([x, 0, pw, ph, frames, 1 if anchor == "h" else 0])
            x += pw * frames
        save(atlas, "decor", "props_w%d.png" % w)
        data[w] = entries
    lines = ["extends RefCounted", "## Generado por tools/gen_props.py: rectángulos [x, y, ancho, alto, fotogramas, colgante] del atlas de atrezo de cada mundo.", "", "const PROPS := {"]
    for w, ents in data.items():
        lines.append("\t%d: %s," % (w, str(ents)))
    lines.append("}")
    with open(os.path.join(ROOT, "levels", "props_data.gd"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print("atrezo: %d mundos" % len(data))


# ------------------------------------------------- tiles de líquido etc. ---
FLUID = {
    1: ("#3a8ee0", "#8ad0ff", "#2a6ec0"),   # agua de río
    2: ("#2ac8d8", "#b0f8ff", "#1a7a9a"),   # lago subterráneo luminoso
    3: ("#c89850", "#f0d090", "#a07830"),   # arenas movedizas
    4: ("#4a8ad0", "#d8f0ff", "#2a5a9a"),   # agua helada
    5: ("#5a3a7a", "#a0f0b0", "#3a2050"),   # niebla/ectoplasma
    6: ("#e8f4ff", "#ffffff", "#bcd8f4"),   # mar de nubes
    7: ("#ff6a1a", "#ffe05a", "#d03a0a"),   # lava
    8: ("#4a7a3a", "#a8d870", "#2f5a2a"),   # pantano
    9: ("#2a3a2a", "#6aff8a", "#1a2a1a"),   # líquido industrial
    10: ("#3a1a7a", "#c08aff", "#1a0a4a"),  # vacío energético
}
FALL = {
    1: ("#9ad4ff", "#ffffff"), 2: ("#7af0ff", "#e8ffff"), 3: ("#f0d090", "#fff0c0"), 4: ("#cfe8ff", "#ffffff"),
    5: ("#8a6ac0", "#d8c0ff"), 6: ("#e8f4ff", "#ffffff"), 7: ("#ff8a2a", "#ffe05a"), 8: ("#9ad4ff", "#e8ffff"),
    9: ("#6aff8a", "#d0ffd8"), 10: ("#c08aff", "#fff0a0"),
}


def fluid_tiles(w):
    body, hi, dk = FLUID[w]
    out = []
    for fr in range(2):
        im, d = newc(16, 16)
        ga.rect(d, 0, 4, 16, 12, C(body, 235))
        # ola superior
        for x in range(16):
            y = 3 + int(round(1.4 * math.sin((x + fr * 4) * math.pi / 4.0)))
            ga.rect(d, x, y, 1, 2, C(hi, 245))
            ga.rect(d, x, y + 2, 1, 1, C(body, 240))
        for (x, y) in ((3, 8), (10, 11), (13, 7)):
            px(d, x + fr, y, C(hi, 160))
        out.append(im)
    im, d = newc(16, 16)
    ga.rect(d, 0, 0, 16, 16, C(body, 235))
    for (x, y) in ((2, 3), (9, 6), (5, 11), (13, 13)):
        px(d, x, y, C(hi, 150))
    ga.rect(d, 0, 12, 16, 4, C(dk, 90))
    out.append(im)
    # cascada (2 fotogramas): corrientes verticales
    col, hi2 = FALL[w]
    for fr in range(2):
        im, d = newc(16, 16)
        ga.rect(d, 2, 0, 12, 16, C(col, 215))
        for xx in (4, 8, 12):
            for y in range(0, 16, 5):
                yy = (y + fr * 3 + xx) % 16
                ga.rect(d, xx, yy, 1, 3, C(hi2, 235))
        ga.rect(d, 2, 0, 1, 16, C(hi2, 180))
        ga.rect(d, 13, 0, 1, 16, C(col, 120))
        out.append(im)
    return out


def backwall_tile(w):
    P = ga.WORLDS[w]
    base = ga.lerp(C(P["fill_d"]), (0, 0, 0, 255), 0.45)
    im, d = newc(16, 16)
    ga.rect(d, 0, 0, 16, 16, base)
    rnd = random.Random(w * 7)
    line = ga.lerp(base, (0, 0, 0, 255), 0.35)
    lite = ga.lerp(base, C(P["fill_l"]), 0.25)
    if w in (5, 9, 10, 6):  # ladrillos / placas
        for y in (0, 8):
            ga.rect(d, 0, y, 16, 1, line)
        for (x, y) in ((4, 0), (12, 8)):
            ga.rect(d, x, y, 1, 8, line)
        px(d, 2, 3, lite)
        px(d, 9, 11, lite)
    else:  # roca
        for _ in range(10):
            px(d, rnd.randint(0, 15), rnd.randint(0, 15), line)
        for _ in range(5):
            px(d, rnd.randint(0, 15), rnd.randint(0, 15), lite)
    return im


def extend_tiles():
    for w in range(1, 11):
        p = os.path.join(ga.ASSETS, "tiles", "tiles_w%d.png" % w)
        im = Image.open(p).convert("RGBA")
        n = im.size[0] // 16
        if n > 20:  # ya ampliado: se rehace desde los 20 originales
            im = im.crop((0, 0, 20 * 16, 16))
        new = fluid_tiles(w) + [backwall_tile(w)]
        out = Image.new("RGBA", (16 * (20 + len(new)), 16), CLEAR)
        out.paste(im.crop((0, 0, 20 * 16, 16)), (0, 0))
        for i, t in enumerate(new):
            out.paste(t, ((20 + i) * 16, 0))
        out.save(p)
    print("tiles ampliados (líquido, cascada, pared de fondo)")


def gen_fx():
    # nubes suaves (3 en una tira) y un engranaje de fondo
    im = Image.new("RGBA", (192, 32), CLEAR)
    d = ImageDraw.Draw(im)
    specs = [(0, 64, 22), (64, 48, 18), (112, 80, 26)]
    for (ox, cw, ch) in specs:
        rnd = random.Random(ox)
        for k in range(6):
            cx = ox + 8 + k * (cw - 16) // 5
            cy = 22 - (k % 3) * 3
            d.ellipse([cx - 9, cy - 8, cx + 9, cy + 6], fill=(255, 255, 255, 235))
        d.rectangle([ox + 6, 18, ox + cw - 6, 26], fill=(255, 255, 255, 235))
        d.rectangle([ox + 6, 24, ox + cw - 6, 27], fill=(200, 220, 245, 235))
    save(im, "fx", "clouds.png")
    g = Image.new("RGBA", (96, 96), CLEAR)
    d = ImageDraw.Draw(g)
    cx = cy = 48
    for k in range(12):
        a = k * math.pi / 6
        x, y = cx + math.cos(a) * 40, cy + math.sin(a) * 40
        d.ellipse([x - 8, y - 8, x + 8, y + 8], fill=(90, 110, 125, 255))
    d.ellipse([cx - 38, cy - 38, cx + 38, cy + 38], fill=(90, 110, 125, 255))
    d.ellipse([cx - 28, cy - 28, cx + 28, cy + 28], fill=(60, 78, 92, 255))
    for k in range(6):
        a = k * math.pi / 3
        d.line([(cx, cy), (cx + math.cos(a) * 30, cy + math.sin(a) * 30)], fill=(90, 110, 125, 255), width=7)
    d.ellipse([cx - 9, cy - 9, cx + 9, cy + 9], fill=(40, 52, 62, 255))
    save(g, "fx", "gear.png")


def main():
    gen_props()
    extend_tiles()
    gen_fx()


if __name__ == "__main__":
    main()

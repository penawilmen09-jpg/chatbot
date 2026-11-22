#!/usr/bin/env python3
"""Niveles de WILMEN WORLD (hito 2): tres niveles largos y difíciles, COMPUESTOS A MANO pieza a pieza.

No hay generación aleatoria: cada nivel es una secuencia explícita de «piezas» (funciones de este archivo) con parámetros
escogidos para ese nivel, más piezas exclusivas. Se escriben en levels/world/ww_NNN.txt (formato en levels/world/README.md) y
se comprueban con tools/ww_check.py (alcanzabilidad real con llaves, túneles y puertas, reloj y variedad).

Glifos nuevos (además de los de WILMEN ADVENTURE):  T boca de túnel · A puerta · Q verja con candado (columna de Q) ·
U llave · I reloj +15 s · M reloj +30 s.   Directivas: @title @region @theme @time @difficulty @warp
Uso: python3 tools/ww_levels.py
"""
import os

R = 20
OUT = os.path.join(os.path.dirname(__file__), "..", "levels", "world")


class Cv:
    def __init__(self):
        self.g = [[] for _ in range(R)]
        self.w = 0
        self.warps = []

    def ensure(self, w):
        if w > self.w:
            for r in self.g:
                r.extend([" "] * (w - self.w))
            self.w = w

    def set(self, x, y, ch):
        if y < 0 or y >= R or x < 0:
            return
        self.ensure(x + 1)
        self.g[y][x] = ch

    def get(self, x, y):
        if y < 0 or y >= R or x < 0 or x >= self.w:
            return " "
        return self.g[y][x]

    def fill(self, x0, y0, x1, y1, ch):
        for y in range(y0, y1):
            for x in range(x0, x1):
                self.set(x, y, ch)

    def rows(self):
        return ["".join(r).rstrip() for r in self.g]


# ------------------------------------------------------------------ utilidades --
def ground(c, x0, x1, gt=15):
    c.fill(x0, gt, x1, R, "#")


def coins(c, x0, x1, y):
    for x in range(x0, x1):
        if c.get(x, y) == " ":
            c.set(x, y, "o")


def arc(c, x0, x1, y, h):
    n = x1 - x0
    for i in range(n):
        t = (i + 0.5) / n
        yy = y - int(round(h * 4 * t * (1 - t)))
        if c.get(x0 + i, yy) == " ":
            c.set(x0 + i, yy, "o")


def foes(c, x, gt, spec):
    """spec: lista de (dx, tipo). Voladores (f) a 5 celdas del suelo."""
    for dx, k in spec:
        c.set(x + dx, gt - (5 if k == "f" else 1), k)


def deco(c, x0, x1, gt, every=7, ch="d", offset=3):
    for x in range(x0 + offset, x1 - 1, every):
        if c.get(x, gt - 1) == " " and c.get(x, gt) == "#":
            c.set(x, gt - 1, ch)


# ------------------------------------------------------------------- piezas ----
def flat(c, x, w, gt=15, foe=(), coin=(), prop=7):
    ground(c, x, x + w, gt)
    for (a, b, dy) in coin:
        coins(c, x + a, x + b, gt - dy)
    foes(c, x, gt, foe)
    if prop:
        deco(c, x, x + w, gt, prop)
    return x + w


def checkpoint(c, x, gt=15, w=6):
    ground(c, x, x + w, gt)
    c.set(x + w // 2, gt - 1, "C")
    return x + w


def stepping_pits(c, x, seq, gt=15, foe_on=()):
    """Foso con islotes. seq: [(foso, ancho_isla, altura_isla)] altura 0..3 sobre el suelo."""
    ground(c, x, x + 4, gt)
    cx = x + 4
    for i, (pit, iw, rise) in enumerate(seq):
        arc(c, cx, cx + pit, gt - 2 - rise, 2)
        cx += pit
        top = gt - rise
        c.fill(cx, top, cx + iw, R, "#")
        if i in foe_on:
            c.set(cx + iw // 2, top - 1, "w")
        cx += iw
    ground(c, cx, cx + 4, gt)
    return cx + 4


def oneway_pits(c, x, seq, gt=15):
    """Foso cruzado por plataformas de un solo sentido. seq: [(avance, y_plataforma, largo)]"""
    ground(c, x, x + 3, gt)
    cx = x + 3
    for (adv, y, ln) in seq:
        cx += adv
        for k in range(ln):
            c.set(cx + k, y, "=")
        coins(c, cx, cx + ln, y - 2)
        cx += ln
    cx += 2
    ground(c, cx, cx + 3, gt)
    return cx + 3


def spike_run(c, x, w, patches, gt=15, shelf=None, foe=()):
    """Suelo con tramos de pinchos. patches: [(dx, largo)]. shelf: [(dx, y, largo)] plataformas altas con monedas."""
    ground(c, x, x + w, gt)
    for (dx, ln) in patches:
        for k in range(ln):
            c.set(x + dx + k, gt - 1, "^")
    if shelf:
        for (dx, y, ln) in shelf:
            for k in range(ln):
                c.set(x + dx + k, y, "=")
            coins(c, x + dx, x + dx + ln, y - 2)
    foes(c, x, gt, foe)
    return x + w


def tower(c, x, steps, gt=15, top_y=6, ledge=5, reward="o"):
    """Torre de plataformas (un solo sentido) hasta una repisa alta y bajada en escalera. steps: [(dx, y)]"""
    ground(c, x, x + 3, gt)
    for (dx, y) in steps:
        for k in range(3):
            c.set(x + 3 + dx + k, y, "=")
    lx = x + 3 + max(d for d, _ in steps) + 4
    c.fill(lx, top_y, lx + ledge, R, "#")
    if reward == "o":
        coins(c, lx, lx + ledge, top_y - 2)
    cx = lx + ledge
    cur = top_y
    while cur < gt:
        cur += 2 if gt - cur >= 2 else 1
        c.fill(cx, min(cur, gt), cx + 2, R, "#")
        cx += 2
    c.fill(cx, gt, cx + 3, R, "#")
    return cx + 3, lx, top_y


def mover_gap(c, x, gap, kind="m", gt=15, lava=False, coin_y=3):
    ground(c, x, x + 3, gt)
    ground(c, x + 3 + gap, x + 6 + gap, gt)
    mx = x + 3 + gap // 2 - 1
    c.set(mx, gt, kind)
    if lava:
        for xx in range(x + 3, x + 3 + gap):
            c.set(xx, R - 2, "L")
            c.set(xx, R - 1, "L")
    coins(c, mx - 1, mx + 3, gt - coin_y)
    return x + 6 + gap


def crumble_run(c, x, plats, gt=15, lava=False):
    """plats: [(hueco, largo)]"""
    ground(c, x, x + 3, gt)
    cx = x + 3
    for (gap, ln) in plats:
        cx += gap
        for k in range(ln):
            c.set(cx + k, gt, "c")
        coins(c, cx, cx + ln, gt - 2)
        cx += ln
    cx += 2
    if lava:
        for xx in range(x + 3, cx):
            c.set(xx, R - 2, "L")
            c.set(xx, R - 1, "L")
    ground(c, cx, cx + 3, gt)
    return cx + 3


def crusher_hall(c, x, w, crushers, gt=15, ceil=4, foe=()):
    ground(c, x, x + w, gt)
    top = gt - ceil
    c.fill(x + 2, 0, x + w - 2, top + 1, "#")
    for dx in crushers:
        c.set(x + dx, top + 1, "p")
    coins(c, x + 3, x + w - 3, gt - 2)
    foes(c, x, gt, foe)
    return x + w


def geyser_field(c, x, w, geysers, gt=15, foe=()):
    ground(c, x, x + w, gt)
    for dx in geysers:
        c.set(x + dx, gt - 1, "g")
    coins(c, x + 2, x + w - 2, gt - 5)
    foes(c, x, gt, foe)
    return x + w


def wind_lift(c, x, gt=15, w=15):
    ground(c, x, x + w, gt)
    wx = x + 4
    for yy in range(gt - 10, gt):
        for k in range(3):
            c.set(wx + k, yy, "W")
    for k in range(5):
        c.set(wx + 4 + k, gt - 9, "=")
    coins(c, wx + 4, wx + 9, gt - 11)
    arc(c, wx - 1, wx + 4, gt - 3, 4)
    return x + w


def conveyor(c, x, w, belt, gt=15, hazard=None, foe=()):
    """belt: (dx0, dx1, '<' o '>'); hazard: (dx, largo) pinchos."""
    ground(c, x, x + w, gt)
    d0, d1, ch = belt
    for xx in range(x + d0, x + d1):
        c.set(xx, gt, ch)
    if hazard:
        for k in range(hazard[1]):
            c.set(x + hazard[0] + k, gt - 1, "^")
    coins(c, x + d0, x + d1, gt - 3)
    foes(c, x, gt, foe)
    return x + w


def plateau(c, x, w, h, gt=15, foe=(), coin=True):
    """Meseta elevada h celdas, con escalones de subida y de bajada de 2 celdas de ancho."""
    cx = x
    for i in range(h):
        c.fill(cx, gt - 1 - i, cx + 2, R, "#")
        cx += 2
    c.fill(cx, gt - h, cx + w, R, "#")
    if coin:
        coins(c, cx + 1, cx + w - 1, gt - h - 2)
    foes(c, cx, gt - h, foe)
    cx += w
    for i in range(h):
        c.fill(cx, gt - h + 1 + i, cx + 2, R, "#")
        cx += 2
    return cx


def gate_wall(c, x, gt=15, h=3, thick=2):
    """Muro hasta el techo con un hueco de h celdas cerrado por una verja de candado (columna de Q)."""
    c.fill(x, 0, x + thick, gt - h, "#")
    c.fill(x, gt, x + thick, R, "#")  # suelo bajo la verja: se atraviesa andando
    # la verja ocupa la primera columna del hueco
    for y in range(gt - h, gt):
        c.set(x, y, "Q")
    return x + thick


def room(c, x, w, floor=15, top=3):
    """Sala cerrada (cueva) con suelo a `floor`; devuelve el hueco interior."""
    c.fill(x, 0, x + w, R, "#")
    c.fill(x + 2, top, x + w - 2, floor, " ")
    return x + 2, x + w - 2


def warp(c, a, b, kind, key=0, d=1):
    s = "@warp %d,%d -> %d,%d %s" % (a[0], a[1], b[0], b[1], kind)
    if key:
        s += " key=%d" % key
    if d != 1:
        s += " dir=%d" % d
    c.warps.append(s)
    glyph = "T" if kind == "tunnel" else "A"
    c.set(a[0], a[1], glyph)
    c.set(b[0], b[1], glyph)


def write(n, c, title, region, theme, time_s, diff, notes, kind="normal", zone=None, boss=0, pieces=()):
    rows = c.rows()
    w = c.w
    path = os.path.join(OUT, "ww_%03d.txt" % n)
    with open(path, "w") as f:
        f.write("; WILMEN WORLD - nivel %d: %s\n" % (n, title))
        for line in notes:
            f.write("; %s\n" % line)
        if pieces:
            f.write("; piezas: %s\n" % ",".join(pieces))
        f.write("@title %s\n@region %d\n@theme %d\n@time %d\n@difficulty %d\n@kind %s\n" % (title, region, theme, time_s, diff, kind))
        if zone is not None:
            f.write("@zone %d\n" % zone)
        if boss:
            f.write("@boss %d\n" % boss)
        for s_ in c.warps:
            f.write(s_ + "\n")
        for r in rows:
            f.write(r.ljust(w) + "\n")
    return w


# ===================================================================== NIVELES ==
if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    import ww_r1_defs
    ww_r1_defs.build_all()

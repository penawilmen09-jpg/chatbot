#!/usr/bin/env python3
"""Generador + validador de los 20 niveles de WILMEN ADVENTURE.

Cada nivel se ensambla con fragmentos de diseño (huecos, escaleras, túneles,
plataformas móviles, secretos...) y se comprueba con un validador de
alcanzabilidad (inicio -> meta y las 3 gemas) basado en los saltos que permite
el jugador (salto simple y doble salto, con márgenes conservadores).

El resultado son ficheros de texto editables a mano en levels/data/.
Leyenda de caracteres en levels/README.md.

Uso:  python3 tools/levelgen.py            # genera y valida
      python3 tools/levelgen.py --check    # solo valida los .txt existentes
"""
import math
import os
import random
import sys
from collections import deque

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "levels", "data")
R = 20  # filas
GT0 = 15  # fila de superficie por defecto

SOLID = set("#B?+><~")
SUPPORT_EXTRA = set("=HK")  # sostienen al jugador pero no bloquean saltos desde abajo
PASS_THROUGH = set("BHK?+")  # se rompen / se revelan al golpearlos con la cabeza
HAZARD = set("^L")

LEVEL_NAMES_V1 = [
    "Claro del Bosque", "Sendero de las Raíces", "Copas de los Árboles", "Guarida del Rey Tronco",
    "Galería Brillante", "Lago Subterráneo", "Mina Abandonada", "Corazón de Cristal",
    "Dunas Doradas", "Oasis Espejismo", "Ruinas de Arena", "Tumba del Escarabajo",
    "Llanura Helada", "Cumbres Nevadas", "Cavernas de Escarcha", "Trono del Yeti",
    "Puente Sombrío", "Salón de Antorchas", "Torre del Vacío", "El Señor de las Sombras",
]


def _names():
    import re
    src = open(os.path.join(ROOT, "autoload", "game.gd"), encoding="utf-8").read()
    block = src[src.index("const LEVEL_NAMES := ["):src.index("const BOSS_NAMES")]
    return re.findall(r'"([^"]+)"', block)


LEVEL_NAMES = _names()


class Lv:
    def __init__(self, w):
        self.w = w
        self.g = [[" "] * w for _ in range(R)]

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < R:
            return self.g[y][x]
        return "#" if (y >= R or x < 0 or x >= self.w) and y < R else " "

    def set(self, x, y, ch, force=True):
        if 0 <= x < self.w and 0 <= y < R:
            if force or self.g[y][x] == " ":
                self.g[y][x] = ch

    def rows(self):
        return ["".join(r).rstrip() for r in self.g]


# --------------------------------------------------------------- CHUNKS ---
def ground(lv, x0, x1, gt):
    for x in range(x0, x1):
        for y in range(gt, R):
            lv.set(x, y, "#")


def coin_arc(lv, x0, x1, y_base, h):
    n = x1 - x0
    for i in range(n):
        t = (i + 0.5) / n
        y = y_base - int(round(h * 4 * t * (1 - t)))
        if lv.get(x0 + i, y) == " ":
            lv.set(x0 + i, y, "o")


def coin_line(lv, x0, x1, y):
    for x in range(x0, x1):
        if lv.get(x, y) == " ":
            lv.set(x, y, "o")


def place_enemy(lv, x, gt, kind, rnd):
    if kind == "f":
        y = gt - rnd.randint(4, 6)
    else:
        y = gt - 1
    if lv.get(x, y) == " ":
        lv.set(x, y, kind)


def enemies_on(lv, x0, x1, gt, ctx, count, avoid_edge=2):
    pool = ctx["pool"]
    if not pool or count <= 0 or x1 - x0 < 2 * avoid_edge + 2:
        return
    used = []
    for _ in range(count):
        for _try in range(6):
            x = ctx["rnd"].randint(x0 + avoid_edge, x1 - avoid_edge - 1)
            if all(abs(x - u) >= 3 for u in used) and lv.get(x, gt - 1) == " " and lv.get(x, gt) == "#":
                kind = ctx["rnd"].choice(pool)
                place_enemy(lv, x, gt, kind, ctx["rnd"])
                used.append(x)
                break


def decor(lv, x0, x1, gt, ctx):
    rnd = ctx["rnd"]
    for x in range(x0, x1):
        if rnd.random() < 0.10 and lv.get(x, gt - 1) == " " and lv.get(x, gt) == "#":
            lv.set(x, gt - 1, "d")


def c_flat(lv, x, ctx):
    rnd, gt, d = ctx["rnd"], ctx["gt"], ctx["d"]
    w = rnd.randint(8, 12)
    ground(lv, x, x + w, gt)
    if rnd.random() < 0.6:
        coin_line(lv, x + 2, x + w - 2, gt - rnd.choice([2, 3]))
    enemies_on(lv, x, x + w, gt, ctx, rnd.randint(1, 2 + int(d * 2)))
    decor(lv, x, x + w, gt, ctx)
    return w


def c_gap(lv, x, ctx):
    rnd, gt, d = ctx["rnd"], ctx["gt"], ctx["d"]
    wmax = 3 if d < 0.25 else (4 if d < 0.6 else 5)
    g = rnd.randint(2, wmax)
    pre, post = 3, 3
    ground(lv, x, x + pre, gt)
    ground(lv, x + pre + g, x + pre + g + post, gt)
    if ctx["lava"]:
        for xx in range(x + pre, x + pre + g):
            lv.set(xx, R - 2, "L")
            lv.set(xx, R - 1, "L")
    coin_arc(lv, x + pre - 1, x + pre + g + 1, gt - 2, 2)
    if ctx["rnd"].random() < 0.3 + 0.3 * d:
        enemies_on(lv, x + pre + g, x + pre + g + post, gt, ctx, 1, 1)
    return pre + g + post


def c_stairs(lv, x, ctx):
    rnd, gt = ctx["rnd"], ctx["gt"]
    n = rnd.randint(2, 4)
    up = gt > 12 and (gt >= 16 or rnd.random() < 0.55)
    cur = gt
    xx = x
    ground(lv, xx, xx + 2, cur)
    xx += 2
    for _ in range(n):
        cur = cur - 1 if up else cur + 1
        cur = max(11, min(17, cur))
        ground(lv, xx, xx + 2, cur)
        coin_line(lv, xx, xx + 2, cur - 2)
        xx += 2
    ground(lv, xx, xx + 3, cur)
    xx += 3
    ctx["gt"] = cur
    return xx - x


def c_platforms(lv, x, ctx):
    """Plataformas flotantes sobre un foso."""
    rnd, gt, d = ctx["rnd"], ctx["gt"], ctx["d"]
    n = rnd.randint(3, 5)
    ground(lv, x, x + 3, gt)
    xx = x + 3
    y = gt
    for i in range(n):
        gap = rnd.randint(2, 3) if d < 0.5 else rnd.randint(2, 4)
        xx += gap
        y = max(gt - 3, min(gt + 1, y + rnd.choice([-2, -1, 0, 1, 2])))
        w = rnd.choice([2, 3])
        for k in range(w):
            lv.set(xx + k, y, "=")
        coin_line(lv, xx, xx + w, y - 2)
        if ctx["lava"]:
            pass
        if rnd.random() < 0.15 and ctx["pool"] and "f" in ctx["pool"]:
            lv.set(xx + 1, y - 4, "f")
        xx += w
    xx += rnd.randint(2, 3)
    # el suelo de salida vuelve a la altura gt
    ground(lv, xx, xx + 3, gt)
    if ctx["lava"]:
        for x2 in range(x + 3, xx):
            lv.set(x2, R - 2, "L")
            lv.set(x2, R - 1, "L")
    return xx + 3 - x


def c_blocks(lv, x, ctx):
    rnd, gt, d = ctx["rnd"], ctx["gt"], ctx["d"]
    w = rnd.randint(9, 12)
    ground(lv, x, x + w, gt)
    start = x + 2
    pattern = rnd.choice(["B?B?B", "B?B", "?B?B?", "BBB?B", "B+B"])
    for i, ch in enumerate(pattern):
        lv.set(start + i, gt - 4, ch)
    if "+" not in pattern and rnd.random() < 0.4:
        lv.set(start + 1, gt - 4, "+")
    coin_line(lv, start, start + len(pattern), gt - 6)
    enemies_on(lv, x, x + w, gt, ctx, rnd.randint(1, 2 + int(d * 2)))
    return w


def c_wall(lv, x, ctx):
    rnd, gt, d = ctx["rnd"], ctx["gt"], ctx["d"]
    h = rnd.randint(2, 3)
    w = 11
    ground(lv, x, x + w, gt)
    wx = x + 5
    for k in range(2):
        for hh in range(1, h + 1):
            lv.set(wx + k, gt - hh, "#")
    coin_line(lv, wx, wx + 2, gt - h - 2)
    enemies_on(lv, x, wx - 1, gt, ctx, 1, 1)
    enemies_on(lv, wx + 3, x + w, gt, ctx, 1, 1)
    return w


def c_spikes(lv, x, ctx):
    rnd, gt, d = ctx["rnd"], ctx["gt"], ctx["d"]
    n = rnd.randint(2, 3 if d < 0.5 else 4)
    ground(lv, x, x + 4 + n + 4, gt)
    for i in range(n):
        lv.set(x + 4 + i, gt - 1, "^")
    coin_arc(lv, x + 3, x + 5 + n, gt - 2, 2)
    return 8 + n


def c_tunnel(lv, x, ctx, niche=False):
    rnd, gt, d = ctx["rnd"], ctx["gt"], ctx["d"]
    w = rnd.randint(14, 18) if niche else rnd.randint(10, 15)
    ground(lv, x, x + w, gt)
    top = gt - 4  # el techo ocupa filas 0..top
    ceil_x0, ceil_x1 = x + 2, x + w - 2
    for xx in range(ceil_x0, ceil_x1):
        for y in range(0, top + 1):
            lv.set(xx, y, "#")
    if niche:
        nx = x + w // 2 - 1
        for k in range(3):
            lv.set(nx + k, top, "B")  # ladrillos que cierran el nicho
        for k in range(3):
            for y in range(top - 3, top):
                lv.set(nx + k, y, " ")
        lv.set(nx + 1, top - 1, "*")
        lv.set(nx, top - 1, "o")
        lv.set(nx + 2, top - 1, "o")
        lv.set(nx + 1, top - 2, "o")
        coin_line(lv, nx, nx + 3, gt - 2)  # pista: monedas bajo el nicho
        ctx["gems"] += 1
    enemies_on(lv, x + 2, x + w - 2, gt, ctx, rnd.randint(1, 2 + int(d * 2)), 1)
    return w


def c_hidden(lv, x, ctx):
    """Bloques ocultos que forman escalones hacia una gema."""
    gt = ctx["gt"]
    w = 12
    ground(lv, x, x + w, gt)
    bx = x + 3
    lv.set(bx, gt - 3, "H")        # 1UP oculto: primer escalon (a un salto)
    lv.set(bx + 1, gt - 6, "K")    # bloque oculto de monedas: segundo escalon
    coin_line(lv, bx - 1, bx + 1, gt - 2)
    for k in range(3):
        lv.set(bx + 3 + k, gt - 8, "=")
    lv.set(bx + 4, gt - 9, "*")
    ctx["gems"] += 1
    return w


def c_spring(lv, x, ctx):
    gt = ctx["gt"]
    w = 12
    ground(lv, x, x + w, gt)
    sx = x + 4
    lv.set(sx, gt - 1, "S")
    for k in range(4):
        lv.set(sx - 1 + k, gt - 6, "=")
    lv.set(sx + 1, gt - 7, "*")
    coin_line(lv, sx - 1, sx + 3, gt - 8)
    ctx["gems"] += 1
    return w


def c_moving(lv, x, ctx):
    """Hueco ancho con plataforma móvil horizontal."""
    gt = ctx["gt"]
    g = 8
    ground(lv, x, x + 3, gt)
    ground(lv, x + 3 + g, x + 6 + g, gt)
    # la plataforma ocupa 2 celdas; su centro queda en el centro del hueco
    mx = x + 3 + g // 2 - 1
    lv.set(mx, gt, "m")
    if ctx["lava"]:
        for xx in range(x + 3, x + 3 + g):
            lv.set(xx, R - 2, "L")
            lv.set(xx, R - 1, "L")
    coin_line(lv, mx - 1, mx + 3, gt - 3)
    return 6 + g


def c_vertical(lv, x, ctx):
    """Ascensor vertical que sube a una repisa alta; se baja por el otro lado."""
    gt = ctx["gt"]
    ground(lv, x, x + 4, gt)
    pit = 5
    top = gt - 5
    # repisa alta de salida (mismo nivel que 'top'), con columna sólida debajo
    for xx in range(x + 4 + pit, x + 4 + pit + 5):
        for y in range(top, R):
            lv.set(xx, y, "#")
    # escalera de bajada hasta gt
    for k, yy in enumerate(range(top + 1, gt + 1)):
        pass
    xx = x + 4 + pit + 5
    cur = top
    while cur < gt:
        cur += 1
        for x2 in range(xx, xx + 2):
            for y in range(cur, R):
                lv.set(x2, y, "#")
        xx += 2
    for x2 in range(xx, xx + 3):
        for y in range(gt, R):
            lv.set(x2, y, "#")
    xx += 3
    lv.set(x + 4 + 1, gt - 3, "v")  # centro 3 filas sobre el suelo
    coin_line(lv, x + 4 + pit + 1, x + 4 + pit + 4, top - 2)
    return xx - x


def c_checkpoint(lv, x, ctx):
    gt = ctx["gt"]
    w = 6
    ground(lv, x, x + w, gt)
    lv.set(x + 3, gt - 1, "C")
    return w


def c_gauntlet(lv, x, ctx):
    rnd, gt, d = ctx["rnd"], ctx["gt"], ctx["d"]
    w = rnd.randint(14, 18)
    ground(lv, x, x + w, gt)
    enemies_on(lv, x, x + w, gt, ctx, 2 + int(d * 3), 2)
    coin_line(lv, x + 2, x + w - 2, gt - 3)
    return w


def c_ice(lv, x, ctx):
    rnd, gt, d = ctx["rnd"], ctx["gt"], ctx["d"]
    w = 20
    ground(lv, x, x + w, gt)
    for sx in (x + 5, x + 11):
        for i in range(rnd.randint(1, 2)):
            lv.set(sx + i, gt - 1, "^")
    enemies_on(lv, x + 2, x + w - 2, gt, ctx, 2, 3)
    coin_line(lv, x + 2, x + w - 2, gt - 4)
    return w



# ------------------------------------------------ fragmentos nuevos (mundos 6-10)
def c_crumble(lv, x, ctx):
    """Foso cruzado por plataformas frágiles ('c'): caen poco después de pisarlas."""
    rnd, gt, d = ctx["rnd"], ctx["gt"], ctx["d"]
    n = rnd.randint(3, 5)
    ground(lv, x, x + 3, gt)
    xx = x + 3
    for i in range(n):
        gap = rnd.randint(1, 2) if d < 0.6 else rnd.randint(2, 3)
        xx += gap
        w = rnd.choice([2, 3])
        for k in range(w):
            lv.set(xx + k, gt, "c")
        coin_line(lv, xx, xx + w, gt - 2)
        xx += w
    xx += 2
    ground(lv, xx, xx + 3, gt)
    if ctx["lava"]:
        for x2 in range(x + 3, xx):
            lv.set(x2, R - 2, "L")
            lv.set(x2, R - 1, "L")
    return xx + 3 - x


def c_wind(lv, x, ctx):
    """Corriente de aire ascendente ('W') que lleva a una repisa alta con monedas."""
    gt = ctx["gt"]
    w = 15
    ground(lv, x, x + w, gt)
    wx = x + 4
    for yy in range(gt - 10, gt):
        for k in range(3):
            lv.set(wx + k, yy, "W")
    for k in range(5):
        lv.set(wx + 4 + k, gt - 9, "=")
    coin_line(lv, wx + 4, wx + 9, gt - 11)
    coin_arc(lv, wx - 1, wx + 4, gt - 3, 4)
    return w


def c_geyser(lv, x, ctx):
    """Suelo con géiseres de lava ('g') que entran en erupción por turnos."""
    rnd, gt, d = ctx["rnd"], ctx["gt"], ctx["d"]
    w = rnd.randint(16, 20)
    ground(lv, x, x + w, gt)
    n = 2 + (1 if d > 0.5 else 0)
    pos = [x + 4 + i * (w - 8) // max(1, n - 1) if n > 1 else x + w // 2 for i in range(n)]
    for px_ in pos:
        lv.set(px_, gt - 1, "g")
    coin_line(lv, x + 2, x + w - 2, gt - 5)
    enemies_on(lv, x, x + w, gt, ctx, 1, 3)
    return w


def c_mud(lv, x, ctx):
    """Tramo de barro ('~'): frena al jugador; con enemigos."""
    rnd, gt, d = ctx["rnd"], ctx["gt"], ctx["d"]
    w = rnd.randint(16, 20)
    ground(lv, x, x + w, gt)
    for xx in range(x + 3, x + w - 3):
        lv.set(xx, gt, "~")
    coin_line(lv, x + 3, x + w - 3, gt - 3)
    enemies_on(lv, x + 2, x + w - 2, gt, ctx, 2 + int(d * 2), 2)
    return w


def c_conveyor(lv, x, ctx):
    """Cinta transportadora ('<' / '>') que arrastra al jugador; a veces hacia pinchos."""
    rnd, gt, d = ctx["rnd"], ctx["gt"], ctx["d"]
    w = 20
    ground(lv, x, x + w, gt)
    ch = rnd.choice(["<", ">"])
    for xx in range(x + 4, x + 14):
        lv.set(xx, gt, ch)
    if d > 0.45:
        sx = x + 14 if ch == ">" else x + 2
        for k in range(2):
            lv.set(sx + k, gt - 1, "^")
    coin_line(lv, x + 4, x + 14, gt - 3)
    enemies_on(lv, x + 14, x + w, gt, ctx, 1, 1)
    return w


def c_crusher(lv, x, ctx):
    """Túnel con prensas ('p') que bajan y suben."""
    rnd, gt, d = ctx["rnd"], ctx["gt"], ctx["d"]
    w = rnd.randint(16, 22)
    ground(lv, x, x + w, gt)
    top = gt - 4
    for xx in range(x + 2, x + w - 2):
        for y in range(0, top + 1):
            lv.set(xx, y, "#")
    for px_ in range(x + 5, x + w - 4, 5):
        lv.set(px_, top + 1, "p")
    coin_line(lv, x + 3, x + w - 3, gt - 2)
    enemies_on(lv, x + 2, x + w - 2, gt, ctx, 1, 2)
    return w


def c_islands(lv, x, ctx):
    """Islas flotantes sólidas separadas por saltos sobre el vacío."""
    rnd, gt, d = ctx["rnd"], ctx["gt"], ctx["d"]
    n = rnd.randint(3, 5)
    ground(lv, x, x + 3, gt)
    xx = x + 3
    y = gt
    for i in range(n):
        gap = rnd.randint(2, 3) if d < 0.5 else rnd.randint(2, 4)
        xx += gap
        y = max(11, min(16, y + rnd.choice([-2, -1, 0, 1])))
        w = rnd.randint(3, 5)
        for k in range(w):
            for yy in range(y, y + 3):
                lv.set(xx + k, yy, "#")
        coin_line(lv, xx, xx + w, y - 2)
        if rnd.random() < 0.35 and "f" in ctx["pool"]:
            lv.set(xx + w // 2, y - 5, "f")
        if rnd.random() < 0.2:
            lv.set(xx + 1, y - 1, "d")
        xx += w
    xx += rnd.randint(2, 3)
    ground(lv, xx, xx + 3, gt)
    return xx + 3 - x


def c_treasure(lv, x, ctx):
    """Cámara del tesoro (niveles secretos): muchas monedas en formas y bloques ocultos."""
    rnd, gt = ctx["rnd"], ctx["gt"]
    w = 16
    ground(lv, x, x + w, gt)
    cx = x + w // 2
    for (dx, dy) in ((0, 6), (-1, 5), (1, 5), (-2, 4), (2, 4), (-1, 4), (1, 4), (0, 3), (0, 4), (0, 5)):
        lv.set(cx + dx, gt - dy, "o")
    for k in range(4):
        lv.set(x + 2 + k * 3, gt - 4, rnd.choice(["B", "?"]))
    lv.set(cx - 5, gt - 3, "K")
    lv.set(cx + 5, gt - 3, "K")
    coin_line(lv, x + 2, x + w - 2, gt - 2)
    return w


CHUNKS = {
    "flat": c_flat, "gap": c_gap, "stairs": c_stairs, "platforms": c_platforms,
    "blocks": c_blocks, "wall": c_wall, "spikes": c_spikes, "tunnel": c_tunnel,
    "moving": c_moving, "vertical": c_vertical, "gauntlet": c_gauntlet, "ice": c_ice,
    "crumble": c_crumble, "wind": c_wind, "geyser": c_geyser, "mud": c_mud,
    "conveyor": c_conveyor, "crusher": c_crusher, "islands": c_islands, "treasure": c_treasure,
}

_Z = dict(flat=0, gap=0, stairs=0, platforms=0, blocks=0, wall=0, spikes=0, tunnel=0, moving=0, vertical=0,
          gauntlet=0, ice=0, crumble=0, wind=0, geyser=0, mud=0, conveyor=0, crusher=0, islands=0, treasure=0)


def _w(**kw):
    d = dict(_Z)
    d.update(kw)
    return d


WORLD_WEIGHTS = {
    1: _w(flat=1, gap=3, stairs=3, platforms=4, blocks=4, wall=2, spikes=1, gauntlet=1),
    2: _w(flat=1, gap=2, stairs=2, platforms=3, blocks=2, wall=2, spikes=3, tunnel=3, moving=2, vertical=2, gauntlet=2, crumble=1),
    3: _w(flat=1, gap=3, stairs=3, platforms=2, blocks=2, wall=3, spikes=3, tunnel=1, moving=3, vertical=1, gauntlet=2, crumble=1),
    4: _w(flat=1, gap=2, stairs=2, platforms=3, blocks=2, wall=2, spikes=2, tunnel=1, moving=1, vertical=2, gauntlet=2, ice=3, crumble=1),
    5: _w(flat=1, gap=3, stairs=2, platforms=3, blocks=1, wall=2, spikes=3, tunnel=2, moving=3, vertical=3, gauntlet=3, crumble=1),
    6: _w(gap=2, platforms=3, blocks=2, spikes=1, moving=2, vertical=1, crumble=3, wind=3, islands=4, stairs=1, gauntlet=1),
    7: _w(gap=2, stairs=2, platforms=3, wall=2, spikes=3, tunnel=1, moving=3, vertical=2, gauntlet=3, crumble=2, geyser=4),
    8: _w(gap=2, stairs=2, platforms=3, blocks=2, wall=2, spikes=2, tunnel=2, moving=1, gauntlet=3, crumble=3, mud=4),
    9: _w(gap=2, platforms=2, wall=2, spikes=3, moving=3, vertical=2, gauntlet=3, conveyor=4, crusher=4),
    10: _w(gap=3, platforms=2, spikes=3, moving=2, vertical=2, gauntlet=3, ice=1, crumble=2, wind=2, geyser=2, mud=1,
           conveyor=2, crusher=2, islands=2, wall=2),
}
SECRET_WEIGHTS = _w(platforms=3, blocks=3, stairs=2, gap=2, treasure=5, flat=1, crumble=1)


def enemy_pool(world, idx):
    pool = ["w"]
    if idx >= 1 or world >= 2:
        pool.append("j")
    if idx >= 2 or world >= 2:
        pool.append("f")
    if idx >= 2 or world >= 3:
        pool.append("t")
    if world >= 2:
        pool.append("s")
    if idx == 0 and world == 1:
        pool = ["w"]
    return pool


def ensure_enemies(lv, ctx, minimum, x_from, x_to):
    """Rellena con enemigos sobre suelo llano si el azar dejó el nivel vacío."""
    rnd = ctx["rnd"]
    have = sum("".join(r).count(k) for r in lv.g for k in "wsjft")
    cands = []
    for x in range(x_from, x_to - 3):
        for y in range(4, R - 1):
            if lv.get(x, y) == "#" and lv.get(x, y - 1) == " " and lv.get(x, y - 2) == " " and lv.get(x, y - 3) == " ":
                if all(lv.get(x + k, y) == "#" and lv.get(x + k, y - 1) == " " for k in (-1, 1)):
                    cands.append((x, y))
                break
    rnd.shuffle(cands)
    used = [x for x in range(lv.w) for y in range(R) if lv.g[y][x] in "wsjftC"]
    for (x, y) in cands:
        if have >= minimum:
            break
        if all(abs(x - u) >= 6 for u in used):
            lv.set(x, y - 1, rnd.choice(ctx["pool"][:2] if len(ctx["pool"]) > 1 else ctx["pool"]))
            used.append(x)
            have += 1


GEM_CHUNKS = ["tunnel_niche", "hidden", "spring"]


def run_chunk(lv, x, ctx, name):
    if name == "tunnel_niche":
        return c_tunnel(lv, x, ctx, niche=True)
    if name == "hidden":
        return c_hidden(lv, x, ctx)
    if name == "spring":
        return c_spring(lv, x, ctx)
    if name == "checkpoint":
        return c_checkpoint(lv, x, ctx)
    if name == "vertical" and ctx["gt"] < 14:
        name = "flat"
    return CHUNKS[name](lv, x, ctx)


def level_params(n):
    world = (n - 1) // 10 + 1
    idx = (n - 1) % 10 + 1
    d = min(1.0, (n - 1) / 99.0 * 0.85 + 0.15 * (idx - 1) / 9.0)
    return world, idx, d


def build_regular(n, seed, secret=False):
    world, idx, d = level_params(n)
    rnd = random.Random(seed)
    target = 150 + int(d * 170)
    if secret:
        target = 170
    pool = enemy_pool(world, min(idx - 1, 5))
    if secret:
        pool = ["w", "j"][: 1 + (world > 3)]
    ctx = dict(rnd=rnd, gt=GT0, d=d, world=world, pool=pool, gems=0, lava=(world in (5, 7)) or (world == 10 and rnd.random() < 0.5))
    w_max = target * 2 + 120
    lv = Lv(w_max)
    ground(lv, 0, 14, GT0)
    lv.set(3, GT0 - 1, "P")
    x = 14
    wts = dict(SECRET_WEIGHTS if secret else WORLD_WEIGHTS[world])
    # estilo propio del nivel: 3 fragmentos "favoritos" pesan x3
    keys = [k for k, v in wts.items() if v > 0]
    for k in rnd.sample(keys, min(3, len(keys))):
        wts[k] *= 3
    names = [k for k, v in wts.items() for _ in range(v)]
    plan = []
    total_est = 14
    while total_est < target:
        plan.append(rnd.choice(names))
        total_est += 21
    # tramo "ritmo": un fragmento favorito repetido 3 veces en el centro del nivel
    fav = max(wts, key=lambda k: (wts[k], rnd.random()))
    if fav not in ("flat",):
        mid = len(plan) // 2
        plan[mid:mid] = [fav, fav, fav]
    gem_chunks = list(GEM_CHUNKS)
    rnd.shuffle(gem_chunks)
    for i, gc in enumerate(gem_chunks):
        pos = int((i + 1) * len(plan) / 4)
        plan.insert(pos + i, gc)
    plan.insert(len(plan) // 3, "checkpoint")
    plan.insert(2 * len(plan) // 3 + 1, "checkpoint")
    for name in plan:
        wd = run_chunk(lv, x, ctx, name)
        x += wd
        ground(lv, x, x + 2, ctx["gt"])
        x += 2
    ground(lv, x, x + 16, ctx["gt"])
    lv.set(x + 9, ctx["gt"] - 1, "F")
    for xx in (x + 3, x + 6):
        lv.set(xx, ctx["gt"] - 1, "d")
    coin_line(lv, x + 2, x + 8, ctx["gt"] - 3)
    total = x + 16
    ensure_enemies(lv, ctx, (2 if secret else 4 + int(d * 14)), 22, total - 18)
    out = Lv(total)
    for y in range(R):
        for xx in range(total):
            out.g[y][xx] = lv.g[y][xx]
    return out, ctx


def build_boss(n, seed):
    world, idx, d = level_params(n)
    rnd = random.Random(seed)
    ctx = dict(rnd=rnd, gt=GT0, d=d * 0.7, world=world, pool=enemy_pool(world, 2)[:3] + (["s"] if world > 2 else []),
               gems=0, lava=(world in (5, 7)))
    approach = 74 + 2 * world
    arena_w = 46
    total = approach + arena_w
    lv = Lv(total + 200)
    ground(lv, 0, 14, GT0)
    lv.set(3, GT0 - 1, "P")
    x = 14
    wts = dict(WORLD_WEIGHTS[world])
    wts["gauntlet"] = 0
    names = [k for k, v in wts.items() if v > 0 for _ in range(v)]
    gem_chunks = list(GEM_CHUNKS)
    rnd.shuffle(gem_chunks)
    plan = [rnd.choice(names) for _ in range(2 + world // 3)]
    for gc in gem_chunks:
        plan.append(gc)
        plan.append(rnd.choice(names))
    for name in plan:
        if x > approach - 24 and name not in gem_chunks:
            continue
        wd = run_chunk(lv, x, ctx, name)
        x += wd
        ground(lv, x, x + 2, ctx["gt"])
        x += 2
    approach = max(approach, x + 14)
    total = approach + arena_w
    big = Lv(total)
    for y in range(R):
        for xx in range(min(lv.w, total)):
            big.g[y][xx] = lv.g[y][xx]
    lv = big
    ensure_enemies(lv, ctx, 5, 22, approach - 20)
    cur = ctx["gt"]
    ground(lv, x, x + 2, cur)
    x += 2
    while cur != GT0:
        cur += 1 if cur < GT0 else -1
        ground(lv, x, x + 2, cur)
        x += 2
    ground(lv, x, approach, GT0)
    lv.set(approach - 8, GT0 - 1, "C")
    ground(lv, approach, total, GT0)
    lv.set(approach, GT0 - 2, "G")
    for y in range(0, GT0):
        lv.set(total - 1, y, "#")
        lv.set(total - 2, y, "#")
    # plataformas para esquivar: la disposición cambia según el mundo
    layouts = [(8, 20, 32), (6, 22, 36), (10, 18, 30), (7, 24, 34), (12, 21, 33)]
    for px_ in layouts[world % len(layouts)]:
        for k in range(4):
            lv.set(approach + px_ + k, GT0 - 3, "=")
    if world >= 6:  # en los mundos avanzados hay además una repisa alta con corazón
        for k in range(4):
            lv.set(approach + 20 + k, GT0 - 7, "=")
        lv.set(approach + 21, GT0 - 8, "h")
    lv.set(total - 14, GT0 - 3, "X")
    lv.set(total - 5, GT0 - 1, "F")
    lv.set(approach + 6, GT0 - 1, "h")
    lv.set(approach + 38, GT0 - 1, "h")
    return lv, ctx


# ------------------------------------------------------------ VALIDADOR ---
class Check:
    def __init__(self, rows):
        self.w = max(len(r) for r in rows)
        self.rows = [r.ljust(self.w) for r in rows]
        while len(self.rows) < R:
            self.rows.append(" " * self.w)
        self.h = len(self.rows)

    def ch(self, x, y):
        if x < 0 or x >= self.w:
            return "#"
        if y < 0:
            return " "
        if y >= self.h:
            return " "  # vacío bajo el nivel: caer = morir, no es suelo
        return self.rows[y][x]

    def solid(self, x, y):
        return self.ch(x, y) in "#?+><~"

    def blocking(self, x, y):
        """Bloquea el arco de un salto (los bloques golpeables no)."""
        return self.ch(x, y) in "#><~"

    def supported(self, x, y):
        """Hay algo sobre lo que apoyarse bajo la celda (x, y)."""
        c = self.ch(x, y + 1)
        return c in "#B?+=HKc><~"

    def mover_cells(self):
        extra = set()
        for y in range(self.h):
            for x in range(self.w):
                c = self.rows[y][x]
                if c == "m":
                    for xx in range(x - 2, x + 4):
                        extra.add((xx, y - 1))
                elif c == "v":
                    for yy in range(y - 3, y + 2):
                        for xx in (x, x + 1):
                            extra.add((xx, yy))
        return extra

    def standable(self):
        movers = self.mover_cells()
        st = set()
        for y in range(1, self.h):
            for x in range(self.w):
                c = self.rows[y][x]
                if c in "#B?+=^LHKc><~":
                    continue
                if self.solid(x, y - 1):
                    continue  # sin espacio para la cabeza (el jugador mide 1.25 celdas)
                if self.ch(x, y + 1) in "^L":
                    continue
                if self.supported(x, y) or (x, y) in movers:
                    st.add((x, y))
        return st


def arc_ok(ck, ax, ay, bx, by, apex_cap):
    """Comprueba que el arco desde (ax,ay) a (bx,by) no choca con sólidos ni peligros."""
    dyu = ay - by
    apex = max(dyu, 0) + (1.4 if apex_cap < 4 else 2.2)
    apex = min(apex, apex_cap)
    if apex < dyu + 0.2 and dyu > 0:
        return False
    if apex <= 0.01:
        apex = 0.01
    q = math.sqrt(max(0.0, (apex - dyu) / apex))
    tpk = 1.0 / (1.0 + q)
    k = apex / (tpk * tpk)
    for i in range(0, 41):
        t = i / 40.0
        h = apex - k * (t - tpk) ** 2
        cx = ax + 0.5 + (bx - ax) * t
        feet = ay + 1 - h
        for xo in (-0.3, 0.3):
            x = cx + xo
            y_lo = feet - 0.05
            y_hi = feet - 1.25
            for yy in (y_lo, (y_lo + y_hi) / 2, y_hi):
                cxi, cyi = int(math.floor(x)), int(math.floor(yy))
                if ck.blocking(cxi, cyi):
                    return False
                if ck.ch(cxi, cyi) in "^L" and yy == y_lo and i > 0:
                    return False
    return True


def reach(rows):
    ck = Check(rows)
    st = ck.standable()
    start = goal = None
    gems = []
    for y in range(ck.h):
        for x in range(ck.w):
            c = ck.rows[y][x]
            if c == "P":
                start = (x, y)
            elif c == "F":
                goal = (x, y)
            elif c == "*":
                gems.append((x, y))
    if start is None or goal is None:
        return None
    # normaliza inicio/meta a celdas de pie
    def stand_for(p):
        x, y = p
        while y < ck.h and (x, y) not in st:
            y += 1
        return (x, y)
    s0 = stand_for(start)
    visited = {s0}
    dq = deque([s0])
    sset = st
    while dq:
        ax, ay = dq.popleft()
        for dx in range(-8, 9):
            bx = ax + dx
            for by in range(ay - 10, ay + 13):
                if (bx, by) in visited or (bx, by) not in sset:
                    continue
                dyu = ay - by
                adx = abs(dx)
                ok = False
                if adx == 1 and dyu == 0:
                    # caminar (sin peligros entre ellas)
                    ok = ck.ch(bx, by) not in "^L"
                if not ok:
                    # salto simple
                    lim = 3 if dyu >= 2 else (4 if dyu >= 0 else 5)
                    if dyu <= 3 and adx <= lim:
                        ok = arc_ok(ck, ax, ay, bx, by, 3.2)
                if not ok and ck.ch(ax, ay) == "S" and dyu <= 6 and adx <= 3:
                    ok = arc_ok(ck, ax, ay, bx, by, 7.4)
                if not ok and (ck.ch(ax, ay) == "W" or ck.ch(ax, ay - 1) == "W") and dyu <= 9 and adx <= 3:
                    ok = arc_ok(ck, ax, ay, bx, by, 10.5)  # corriente de aire ascendente
                if not ok:
                    lim2 = 4 if dyu >= 4 else (5 if dyu == 3 else (7 if dyu >= 0 else 8))
                    if dyu <= 5 and adx <= lim2:
                        ok = arc_ok(ck, ax, ay, bx, by, 5.6)
                if ok:
                    visited.add((bx, by))
                    dq.append((bx, by))
    g0 = stand_for(goal)
    goal_ok = g0 in visited
    gem_ok = []
    for (gx, gy) in gems:
        found = False
        # alcanzable si algún nodo visitado permite llegar a la celda de la gema
        for (ax, ay) in visited:
            if abs(ax - gx) > 8 or ay - gy > 7 or gy - ay > 12:
                continue
            dyu = ay - gy
            adx = abs(ax - gx)
            if adx <= 1 and dyu >= 0 and dyu <= 6 and arc_ok(ck, ax, ay, gx, gy + 1, 5.6):
                found = True
                break
            if arc_ok(ck, ax, ay, gx, gy + 1, 5.6) and adx <= 6 and dyu <= 5:
                found = True
                break
            if (gx, gy) in sset and (gx, gy) in visited:
                found = True
                break
        gem_ok.append(found)
    return dict(goal=goal_ok, gems=gem_ok, n_gems=len(gems), visited=len(visited))


def count(rows, ch):
    return sum(r.count(ch) for r in rows)


def validate(rows, n):
    errs = []
    if count(rows, "P") != 1:
        errs.append("debe haber exactamente 1 'P'")
    if count(rows, "F") != 1:
        errs.append("debe haber exactamente 1 'F'")
    if count(rows, "*") != 3:
        errs.append("debe haber 3 gemas (hay %d)" % count(rows, "*"))
    if n % 10 == 0:
        if count(rows, "X") != 1 or count(rows, "G") != 1:
            errs.append("nivel de jefe: falta 'X' o 'G'")
    elif count(rows, "X") or count(rows, "G"):
        errs.append("jefe/puerta en un nivel que no es de jefe")
    if count(rows, "C") < 1:
        errs.append("sin punto de control")
    if len(rows) != R:
        errs.append("el nivel debe tener %d filas (tiene %d)" % (R, len(rows)))
    res = reach(rows)
    if res is None:
        errs.append("sin inicio o meta")
    else:
        if not res["goal"]:
            errs.append("la meta no es alcanzable")
        if not all(res["gems"]):
            errs.append("gemas inalcanzables: %s" % res["gems"])
    return errs


# ----------------------------------------------------------------- MAIN ---
LEGACY = {1, 2, 3, 10, 11, 12, 13, 20, 21, 22, 23, 30, 31, 32, 33, 40, 41, 42, 43, 50}  # niveles de la versión 1


def level_text(n, rows, seed):
    w, i, _ = level_params(n)
    head = [
        "; WILMEN ADVENTURE - nivel %d (%d-%d): %s%s" % (n, w, i, LEVEL_NAMES[n - 1], "  [SECRETO]" if i == 7 else ""),
        "; semilla de generacion: %d (edita este fichero a mano si quieres retocar el nivel)" % seed,
    ]
    return "\n".join(head + rows) + "\n"


def read_rows(n):
    with open(os.path.join(OUT, "level_%02d.txt" % n), encoding="utf-8") as f:
        rows = [l.rstrip("\n") for l in f if not l.startswith(";")]
    while rows and rows[-1] == "":
        rows.pop()
    while len(rows) < R:
        rows.append("")
    return rows


def generate(only_missing=True):
    os.makedirs(OUT, exist_ok=True)
    for n in range(1, 101):
        path = os.path.join(OUT, "level_%02d.txt" % n)
        if n in LEGACY or (only_missing and os.path.exists(path)):
            continue
        boss = n % 10 == 0
        secret = (n - 1) % 10 + 1 == 7
        seed = 5000 + n * 131
        ok = False
        for attempt in range(80):
            s = seed + attempt
            if boss:
                lv, ctx = build_boss(n, s)
            else:
                lv, ctx = build_regular(n, s, secret)
            rows = lv.rows()
            while len(rows) < R:
                rows.append("")
            errs = validate(rows, n)
            if not errs:
                ok = True
                break
        if not ok:
            print("NIVEL %d no válido tras 80 intentos: %s" % (n, errs))
            sys.exit(1)
        with open(path, "w", encoding="utf-8") as f:
            f.write(level_text(n, rows, s))
        print("nivel %3d  ancho %3d  intentos %2d" % (n, lv.w, attempt + 1))


def check_only():
    bad = 0
    import hashlib
    seen = {}
    for n in range(1, 101):
        rows = read_rows(n)
        errs = validate(rows, n)
        h = hashlib.md5("\n".join(rows).encode()).hexdigest()
        if h in seen:
            errs.append("duplicado del nivel %d" % seen[h])
        seen[h] = n
        if errs:
            print("nivel %3d: %s" % (n, errs))
            bad += 1
    print("niveles revisados: 100 | con errores: %d" % bad)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    if "--check" in sys.argv:
        check_only()
    else:
        generate(only_missing="--all" not in sys.argv)
        check_only()

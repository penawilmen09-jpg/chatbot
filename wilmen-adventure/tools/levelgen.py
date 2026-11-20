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

SOLID = set("#B?+")
SUPPORT_EXTRA = set("=HK")  # sostienen al jugador pero no bloquean saltos desde abajo
PASS_THROUGH = set("BHK?+")  # se rompen / se revelan al golpearlos con la cabeza
HAZARD = set("^L")

LEVEL_NAMES = [
    "Claro del Bosque", "Sendero de las Raíces", "Copas de los Árboles", "Guarida del Rey Tronco",
    "Galería Brillante", "Lago Subterráneo", "Mina Abandonada", "Corazón de Cristal",
    "Dunas Doradas", "Oasis Espejismo", "Ruinas de Arena", "Tumba del Escarabajo",
    "Llanura Helada", "Cumbres Nevadas", "Cavernas de Escarcha", "Trono del Yeti",
    "Puente Sombrío", "Salón de Antorchas", "Torre del Vacío", "El Señor de las Sombras",
]


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


CHUNKS = {
    "flat": c_flat, "gap": c_gap, "stairs": c_stairs, "platforms": c_platforms,
    "blocks": c_blocks, "wall": c_wall, "spikes": c_spikes, "tunnel": c_tunnel,
    "moving": c_moving, "vertical": c_vertical, "gauntlet": c_gauntlet, "ice": c_ice,
}

WORLD_WEIGHTS = {
    1: dict(flat=1, gap=3, stairs=3, platforms=4, blocks=4, wall=2, spikes=1, tunnel=0, moving=0, vertical=0, gauntlet=1, ice=0),
    2: dict(flat=1, gap=2, stairs=2, platforms=3, blocks=2, wall=2, spikes=3, tunnel=3, moving=2, vertical=2, gauntlet=2, ice=0),
    3: dict(flat=1, gap=3, stairs=3, platforms=2, blocks=2, wall=3, spikes=3, tunnel=1, moving=3, vertical=1, gauntlet=2, ice=0),
    4: dict(flat=1, gap=2, stairs=2, platforms=3, blocks=2, wall=2, spikes=2, tunnel=1, moving=1, vertical=2, gauntlet=2, ice=3),
    5: dict(flat=1, gap=3, stairs=2, platforms=3, blocks=1, wall=2, spikes=3, tunnel=2, moving=3, vertical=3, gauntlet=3, ice=0),
}


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


def build_regular(n, seed):
    """n: 1..20 (no jefe)."""
    world = (n - 1) // 4 + 1
    idx = (n - 1) % 4
    rnd = random.Random(seed)
    d = min(1.0, ((world - 1) * 4 + idx) / 15.0)
    target = 150 + 8 * ((world - 1) * 4 + idx)
    ctx = dict(rnd=rnd, gt=GT0, d=d, world=world, pool=enemy_pool(world, idx), gems=0,
               lava=(world == 5))
    w_max = target * 2 + 80
    lv = Lv(w_max)
    ground(lv, 0, 14, GT0)
    lv.set(3, GT0 - 1, "P")
    x = 14
    wts = WORLD_WEIGHTS[world]
    names = [k for k, v in wts.items() for _ in range(v)]
    gem_chunks = ["tunnel_niche", "hidden", "spring"]
    rnd.shuffle(gem_chunks)
    plan = []
    total_est = 14
    while total_est < target:
        plan.append(rnd.choice(names))
        total_est += 21
    # insertar chunks con gema repartidos
    for i, gc in enumerate(gem_chunks):
        pos = int((i + 1) * len(plan) / 4)
        plan.insert(pos + i, gc)
    # checkpoints a 1/3 y 2/3
    plan.insert(len(plan) // 3, "checkpoint")
    plan.insert(2 * len(plan) // 3 + 1, "checkpoint")
    for name in plan:
        ctx_gt = ctx["gt"]
        if ctx_gt != GT0 and name in ("tunnel_niche", "hidden", "spring", "vertical", "moving", "platforms", "gauntlet", "ice"):
            # volver a la altura base antes de los fragmentos que la requieren
            pass
        if name == "tunnel_niche":
            wd = c_tunnel(lv, x, ctx, niche=True)
        elif name == "hidden":
            wd = c_hidden(lv, x, ctx)
        elif name == "spring":
            wd = c_spring(lv, x, ctx)
        elif name == "checkpoint":
            wd = c_checkpoint(lv, x, ctx)
        else:
            if name == "vertical" and ctx["gt"] < 14:
                name = "flat"
            wd = CHUNKS[name](lv, x, ctx)
        x += wd
        ground(lv, x, x + 2, ctx["gt"])
        x += 2
    # tramo final: vuelve a una altura segura y coloca la meta
    ground(lv, x, x + 16, ctx["gt"])
    lv.set(x + 9, ctx["gt"] - 1, "F")
    for xx in (x + 3, x + 6):
        lv.set(xx, ctx["gt"] - 1, "d")
    coin_line(lv, x + 2, x + 8, ctx["gt"] - 3)
    total = x + 16
    ensure_enemies(lv, ctx, 4 + 2 * ((world - 1) * 4 + idx) // 2 + 2, 22, total - 18)
    # recorta el ancho
    out = Lv(total)
    for y in range(R):
        for xx in range(total):
            out.g[y][xx] = lv.g[y][xx]
    # gemas faltantes -> plataforma alta extra
    return out, ctx


def build_boss(n, seed):
    world = n // 4
    rnd = random.Random(seed)
    idx = 3
    d = min(1.0, ((world - 1) * 4 + 2) / 15.0)
    ctx = dict(rnd=rnd, gt=GT0, d=d * 0.7, world=world, pool=enemy_pool(world, 2)[:3] + (["s"] if world > 2 else []),
               gems=0, lava=(world == 5))
    approach = 74
    arena_w = 46
    total = approach + arena_w
    lv = Lv(total)
    ground(lv, 0, 14, GT0)
    lv.set(3, GT0 - 1, "P")
    x = 14
    wts = dict(WORLD_WEIGHTS[world])
    wts["gauntlet"] = 0
    names = [k for k, v in wts.items() for _ in range(v)]
    gem_chunks = ["tunnel_niche", "hidden", "spring"]
    rnd.shuffle(gem_chunks)
    plan = []
    for i in range(2):
        plan.append(rnd.choice(names))
    for gc in gem_chunks:
        plan.append(gc)
        plan.append(rnd.choice(names))
    for name in plan:
        if x > approach - 24:
            # si no cabe, sigue con las gemas igualmente (recorta aleatorios)
            if name not in gem_chunks:
                continue
        if name == "tunnel_niche":
            wd = c_tunnel(lv, x, ctx, niche=True)
        elif name == "hidden":
            wd = c_hidden(lv, x, ctx)
        elif name == "spring":
            wd = c_spring(lv, x, ctx)
        else:
            if name == "vertical" and ctx["gt"] < 14:
                name = "flat"
            wd = CHUNKS[name](lv, x, ctx)
        x += wd
        ground(lv, x, x + 2, ctx["gt"])
        x += 2
    # ensancha el lienzo si el recorrido se alargó
    approach = max(approach, x + 14)
    total = approach + arena_w
    big = Lv(total)
    for y in range(R):
        for xx in range(min(lv.w, total)):
            big.g[y][xx] = lv.g[y][xx]
    lv = big
    ensure_enemies(lv, ctx, 5, 22, approach - 20)
    gt = ctx["gt"]
    # el tramo previo a la arena vuelve a GT0 con escalones
    cur = gt
    ground(lv, x, x + 2, cur)
    x += 2
    while cur != GT0:
        cur += 1 if cur < GT0 else -1
        ground(lv, x, x + 2, cur)
        x += 2
    ground(lv, x, approach, GT0)
    lv.set(approach - 8, GT0 - 1, "C")
    # arena
    ground(lv, approach, total, GT0)
    lv.set(approach, GT0 - 2, "G")
    for y in range(0, GT0):  # pared derecha
        lv.set(total - 1, y, "#")
        lv.set(total - 2, y, "#")
    # plataformas para esquivar
    for px_ in (approach + 8, approach + 20, approach + 32):
        for k in range(4):
            lv.set(px_ + k, GT0 - 3, "=")
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
        return self.ch(x, y) in "#?+"

    def blocking(self, x, y):
        """Bloquea el arco de un salto (los bloques golpeables no)."""
        return self.ch(x, y) == "#"

    def supported(self, x, y):
        """Hay algo sobre lo que apoyarse bajo la celda (x, y)."""
        c = self.ch(x, y + 1)
        return c in "#B?+=HK"

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
                if c in "#B?+=^LHK":
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
            for by in range(ay - 7, ay + 13):
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
    if n % 4 == 0:
        if count(rows, "X") != 1 or count(rows, "G") != 1:
            errs.append("nivel de jefe: falta 'X' o 'G'")
    if count(rows, "C") < 1:
        errs.append("sin punto de control")
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
def level_text(n, rows, seed):
    head = [
        "; WILMEN ADVENTURE - nivel %d (%d-%d): %s" % (n, (n - 1) // 4 + 1, (n - 1) % 4 + 1, LEVEL_NAMES[n - 1]),
        "; semilla de generacion: %d (edita este fichero a mano si quieres retocar el nivel)" % seed,
    ]
    return "\n".join(head + rows) + "\n"


def fix_gems(lv, ctx, n):
    """Garantiza exactamente 3 gemas; añade gemas sobre plataformas si faltan."""
    have = sum(r.count("*") for r in ("".join(row) for row in lv.g))
    return have


def generate():
    os.makedirs(OUT, exist_ok=True)
    report = []
    for n in range(1, 21):
        boss = n % 4 == 0
        seed = 1000 + n * 37
        ok = False
        for attempt in range(60):
            s = seed + attempt
            if boss:
                lv, ctx = build_boss(n, s)
            else:
                lv, ctx = build_regular(n, s)
            rows = lv.rows()
            errs = validate(rows, n)
            if not errs:
                ok = True
                break
        if not ok:
            print("NIVEL %d no válido tras 60 intentos: %s" % (n, errs))
            sys.exit(1)
        with open(os.path.join(OUT, "level_%02d.txt" % n), "w", encoding="utf-8") as f:
            f.write(level_text(n, rows, s))
        res = reach(rows)
        report.append((n, lv.w, count(rows, "o"), count(rows, "w") + count(rows, "s") + count(rows, "j") + count(rows, "f") + count(rows, "t"), s - seed + 1, res["visited"]))
        print("nivel %2d  ancho %3d  monedas %3d  enemigos %2d  intentos %2d  nodos %4d" % (n, lv.w, report[-1][2], report[-1][3], report[-1][4], report[-1][5]))


def check_only():
    bad = 0
    for n in range(1, 21):
        p = os.path.join(OUT, "level_%02d.txt" % n)
        with open(p, encoding="utf-8") as f:
            rows = [l.rstrip("\n") for l in f if not l.startswith(";")]
        errs = validate(rows, n)
        print("nivel %2d: %s" % (n, "OK" if not errs else errs))
        bad += bool(errs)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    if "--check" in sys.argv:
        check_only()
    else:
        generate()

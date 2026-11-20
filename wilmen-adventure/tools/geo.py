"""Geometría de los niveles (v3): colinas, montañas, puentes, lagos, cascadas, torres, cavernas, doseles...

Se usa desde levelgen.py (bind(L) le pasa las utilidades comunes) y deja dígitos '1'..'9' (atrezo del mundo),
'a' (agua/líquido del mundo, decorativo) y '|' (cascada, decorativa) en el texto del nivel.
Todos los trozos respetan las reglas de salto del validador (subidas <= 3 filas con un salto, huecos <= 4 columnas)
y siguen comprobándose con la prueba de alcanzabilidad de levelgen.
"""
from worlds_def import ABBR, FILLER, PROPS, RECIPES

L = None
R = 20


def bind(mod):
    global L, R
    L = mod
    R = mod.R


# ------------------------------------------------------------- utilidades ---
def solid_col(lv, x, top):
    for y in range(max(0, top), R):
        lv.set(x, y, "#")


def adj(lv, x, ctx, lo, hi):
    """Lleva el suelo a [lo, hi] con escalones de 1 fila. Devuelve el ancho usado."""
    w = 0
    while ctx["gt"] < lo or ctx["gt"] > hi:
        L.ground(lv, x + w, x + w + 2, ctx["gt"])
        ctx["gt"] += 1 if ctx["gt"] < lo else -1
        w += 2
    return w


def sprinkle_enemies(lv, ctx, x0, x1, count):
    """Enemigos sobre la superficie real de cada columna (sirve en terreno con desniveles)."""
    pool = ctx["pool"]
    rnd = ctx["rnd"]
    if not pool or count <= 0:
        return
    used = []
    for _ in range(count):
        for _t in range(8):
            x = rnd.randint(x0 + 1, max(x0 + 1, x1 - 2))
            y = surface_y(lv, x)
            if y is None or y < 3:
                continue
            if lv.get(x - 1, y) != "#" or lv.get(x + 1, y) != "#":
                continue
            if lv.get(x - 1, y - 1) != " " or lv.get(x + 1, y - 1) != " " or lv.get(x, y - 1) != " ":
                continue
            if any(abs(x - u) < 4 for u in used):
                continue
            kind = rnd.choice(pool)
            L.place_enemy(lv, x, y, kind, rnd)
            used.append(x)
            break


def surface_y(lv, x):
    """Fila de la superficie transitable más baja de la columna (primer '#' con aire encima, desde abajo)."""
    for y in range(R - 1, 2, -1):
        if lv.get(x, y) == "#" and lv.get(x, y - 1) == " ":
            return y
    return None


# ----------------------------------------------------------------- trozos ---
def c_hills(lv, x, ctx):
    """Colinas: el suelo ondula con subidas y bajadas de hasta 4 filas (nunca más de 2 filas de golpe)."""
    import math
    rnd = ctx["rnd"]
    x0 = x
    x += adj(lv, x, ctx, 11, 16)
    base = ctx["gt"]
    cur = base
    amp = rnd.choice([2, 3, 3, 4])
    lam = rnd.randint(16, 26)
    ph = rnd.random() * 6.28
    total = rnd.randint(26, 36)
    xs = x
    while x - xs < total:
        seg = rnd.randint(2, 4)
        want = base + int(round(amp * math.sin(2 * math.pi * (x - xs) / lam + ph)))
        want = max(9, min(16, want))
        cur = cur + max(-2, min(2, want - cur))
        L.ground(lv, x, x + seg, cur)
        if rnd.random() < 0.45:
            L.coin_line(lv, x, x + seg, cur - 2)
        if seg >= 3 and rnd.random() < 0.4 + 0.3 * ctx["d"]:
            sprinkle_enemies(lv, ctx, x, x + seg, 1)
        x += seg
    L.ground(lv, x, x + 3, cur)
    ctx["gt"] = cur
    return x + 3 - x0


def c_mountain(lv, x, ctx):
    """Montaña: se sube por escalones, cima estrecha y bajada por escalones o por un risco."""
    rnd = ctx["rnd"]
    x0 = x
    x += adj(lv, x, ctx, 12, 16)
    gt = ctx["gt"]
    H = rnd.randint(5, min(8, gt - 5))
    L.ground(lv, x, x + 3, gt)
    x += 3
    cur = gt
    rise = 0
    steps = []
    while rise < H:
        r = min(rnd.choice([1, 2, 2]), H - rise)
        rise += r
        steps.append(r)
    for r in steps:
        cur -= r
        wd = 2 if r == 1 else 3
        L.ground(lv, x, x + wd, cur)
        if rnd.random() < 0.5:
            L.coin_line(lv, x, x + wd, cur - 2)
        x += wd
    pw = rnd.randint(3, 6)
    L.ground(lv, x, x + pw, cur)
    L.coin_line(lv, x, x + pw, cur - 3)
    if rnd.random() < 0.5:
        sprinkle_enemies(lv, ctx, x, x + pw, 1)
    x += pw
    if rnd.random() < 0.5:  # bajada escalonada
        for r in reversed(steps):
            cur += r
            wd = 2 if r == 1 else 3
            L.ground(lv, x, x + wd, cur)
            x += wd
    else:  # risco: se cae hasta el suelo
        L.ground(lv, x, x + 4, gt)
        x += 4
        cur = gt
    L.ground(lv, x, x + 3, gt)
    x += 3
    ctx["gt"] = gt
    return x - x0


def c_bridge(lv, x, ctx):
    """Puente de tablones sobre el vacío (abajo, el líquido del mundo)."""
    rnd = ctx["rnd"]
    x0 = x
    x += adj(lv, x, ctx, 11, 16)
    gt = ctx["gt"]
    L.ground(lv, x, x + 3, gt)
    n = rnd.randint(7, 11)
    for k in range(n):
        lv.set(x + 3 + k, gt, "=")
    lv.set(x + 3, gt - 1, "6")
    lv.set(x + 3 + n - 1, gt - 1, "6")
    L.coin_line(lv, x + 4, x + 3 + n - 1, gt - 3)
    if ctx["lava"]:
        for xx in range(x + 3, x + 3 + n):
            lv.set(xx, R - 2, "L")
            lv.set(xx, R - 1, "L")
    if rnd.random() < 0.35 and "f" in ctx["pool"]:
        lv.set(x + 3 + n // 2, gt - 5, "f")
    L.ground(lv, x + 3 + n, x + 6 + n, gt)
    return x + 6 + n - x0


def c_valley(lv, x, ctx):
    """Lago: se baja por escalones a una cuenca con agua poco profunda y piedras para cruzar."""
    rnd = ctx["rnd"]
    x0 = x
    x += adj(lv, x, ctx, 9, 14)
    gt = ctx["gt"]
    bw = rnd.randint(6, 10)
    L.ground(lv, x, x + 3, gt)
    L.ground(lv, x + 3, x + 5, gt + 1)
    L.ground(lv, x + 5, x + 7, gt + 2)
    fx = x + 7
    L.ground(lv, fx, fx + bw, gt + 3)
    ex = fx + bw
    L.ground(lv, ex, ex + 2, gt + 2)
    L.ground(lv, ex + 2, ex + 4, gt + 1)
    L.ground(lv, ex + 4, ex + 7, gt)
    for xx in range(x + 3, ex + 4):  # agua: dos filas sobre el fondo
        for yy in (gt + 1, gt + 2):
            if lv.get(xx, yy) == " ":
                lv.set(xx, yy, "a")
    # piedras para cruzar por arriba (a la altura del suelo)
    sx = x + 3
    while sx < ex + 2:
        wd = rnd.choice([2, 3])
        for k in range(wd):
            if lv.get(sx + k, gt) == " ":
                lv.set(sx + k, gt, "=")
        L.coin_line(lv, sx, sx + wd, gt - 2)
        sx += wd + rnd.randint(1, 2)
    if rnd.random() < 0.5:
        sprinkle_enemies(lv, ctx, fx, ex, 1)
    ctx["gt"] = gt
    return ex + 7 - x0


def c_waterfall(lv, x, ctx):
    """Cascada: un arroyo llega al borde de un risco y cae a una poza."""
    rnd = ctx["rnd"]
    x0 = x
    x += adj(lv, x, ctx, 9, 13)
    gt = ctx["gt"]
    D = rnd.randint(3, 4)
    up = rnd.randint(7, 9)
    L.ground(lv, x, x + up, gt)
    for xx in range(x + up - 4, x + up):  # el arroyo
        lv.set(xx, gt - 1, "a")
    lip = x + up
    gt2 = gt + D
    for yy in range(gt, gt2):
        lv.set(lip, yy, "|")
    L.ground(lv, lip, lip + 11, gt2)
    for xx in range(lip, lip + 4):  # la poza
        lv.set(xx, gt2 - 1, "a")
    L.coin_arc(lv, lip - 2, lip + 3, gt - 1, 3)
    sprinkle_enemies(lv, ctx, lip + 4, lip + 10, 1)
    ctx["gt"] = gt2
    return lip + 11 - x0


def c_canopy(lv, x, ctx):
    """Dos caminos: abajo el suelo, arriba una ruta de plataformas a la que se sube con un resorte."""
    rnd = ctx["rnd"]
    x0 = x
    x += adj(lv, x, ctx, 12, 16)
    gt = ctx["gt"]
    W = rnd.randint(24, 28)
    L.ground(lv, x, x + W, gt)
    lv.set(x + 2, gt - 1, "S")
    xx = x + 4
    y = gt - 5
    while xx < x + W - 6:
        wd = rnd.choice([3, 3, 4])
        for k in range(wd):
            lv.set(xx + k, y, "=")
        L.coin_line(lv, xx, xx + wd, y - 2)
        if rnd.random() < 0.3 and "f" in ctx["pool"]:
            lv.set(xx + 1, y - 4, "f")
        xx += wd + rnd.randint(2, 3)
        y = max(gt - 6, min(gt - 4, y + rnd.choice([-1, 0, 1])))
    sprinkle_enemies(lv, ctx, x + 6, x + W - 3, 2 + int(ctx["d"] * 2))
    return W + x - x0


def c_tower(lv, x, ctx):
    """Torre: se sube con dos plataformas en zigzag a una azotea con vistas y se baja saltando."""
    rnd = ctx["rnd"]
    x0 = x
    x += adj(lv, x, ctx, 13, 16)
    gt = ctx["gt"]
    tw = rnd.randint(4, 6)
    L.ground(lv, x, x + 8 + tw + 6, gt)
    lv.set(x + 3, gt - 3, "=")
    lv.set(x + 4, gt - 3, "=")
    lv.set(x + 5, gt - 3, "=")
    lv.set(x + 6, gt - 6, "=")
    lv.set(x + 7, gt - 6, "=")
    xt = x + 8
    top = gt - 7
    for xx in range(xt, xt + tw):
        solid_col(lv, xx, top)
    L.coin_line(lv, xt + 1, xt + tw - 1, top - 3)
    lv.set(xt + tw // 2, top - 1, "6")
    sprinkle_enemies(lv, ctx, x + 10 + tw, x + 14 + tw, 1)
    return 8 + tw + 6 + x - x0


def c_pillars(lv, x, ctx):
    """Columnas de distinta altura separadas por huecos."""
    rnd = ctx["rnd"]
    x0 = x
    x += adj(lv, x, ctx, 11, 16)
    gt = ctx["gt"]
    L.ground(lv, x, x + 3, gt)
    x += 3
    h = 1
    for i in range(rnd.randint(4, 6)):
        gap = rnd.randint(2, 3)
        x += gap
        h = max(0, min(4, h + rnd.choice([-3, -2, -1, 1, 2, 3])))
        top = gt - h
        for xx in (x, x + 1):
            solid_col(lv, xx, top)
        L.coin_line(lv, x, x + 2, top - 2)
        if h >= 2 and rnd.random() < 0.3 and "f" in ctx["pool"]:
            lv.set(x, top - 5, "f")
        x += 2
    x += rnd.randint(2, 3)
    L.ground(lv, x, x + 3, gt)
    if ctx["lava"]:
        pass
    return x + 3 - x0


def c_cavern(lv, x, ctx):
    """Caverna: techo irregular con estalactitas y suelo con pequeños desniveles."""
    rnd = ctx["rnd"]
    x0 = x
    x += adj(lv, x, ctx, 14, 16)
    gt = ctx["gt"]
    W = rnd.randint(24, 30)
    cb = 3
    cur = gt
    for i in range(W):
        if i < 3:
            c = i  # entrada: el techo baja suavemente
        elif i >= W - 3:
            c = W - 1 - i
        else:
            cb = max(3, min(gt - 7, cb + rnd.choice([-1, 0, 0, 0, 1])))
            c = cb
        for y in range(0, c + 1):
            lv.set(x + i, y, "#")
        if 3 <= i < W - 3 and rnd.random() < 0.18 and gt - (c + 3) >= 5:
            lv.set(x + i, c + 1, "#")
            if rnd.random() < 0.5:
                lv.set(x + i, c + 2, "#")
        if i % rnd.randint(4, 6) == 0 and 2 < i < W - 4:
            cur = max(gt - 1, min(gt, cur + rnd.choice([-1, 1])))
        if i >= W - 4:
            cur = gt
        L.ground(lv, x + i, x + i + 1, cur)
        if i % 7 == 3 and rnd.random() < 0.5:
            L.coin_line(lv, x + i, x + i + 2, gt - 3)
    sprinkle_enemies(lv, ctx, x + 4, x + W - 4, 2 + int(ctx["d"] * 2))
    ctx["gt"] = gt
    return W + x - x0


def c_lavariver(lv, x, ctx):
    """Río de lava (mundo 7): piedras sobre la lava y una cascada de lava al fondo."""
    rnd = ctx["rnd"]
    x0 = x
    x += adj(lv, x, ctx, 11, 15)
    gt = ctx["gt"]
    L.ground(lv, x, x + 3, gt)
    n = rnd.randint(4, 6)
    xx = x + 3
    for i in range(n):
        gap = rnd.randint(2, 3)
        y = max(gt - 2, min(gt + 1, gt + rnd.choice([-1, 0, 0, 1])))
        wd = rnd.choice([2, 3])
        xx += gap
        for k in range(wd):
            lv.set(xx + k, y, "=")
        L.coin_line(lv, xx, xx + wd, y - 2)
        xx += wd
    xx += rnd.randint(2, 3)
    for x2 in range(x + 3, xx):
        lv.set(x2, R - 3, "L")
        lv.set(x2, R - 2, "L")
        lv.set(x2, R - 1, "L")
    L.ground(lv, xx, xx + 3, gt)
    return xx + 3 - x0


NEW_CHUNKS = {
    "hills": c_hills, "mountain": c_mountain, "bridge": c_bridge, "valley": c_valley,
    "waterfall": c_waterfall, "canopy": c_canopy, "tower": c_tower, "pillars": c_pillars,
    "cavern": c_cavern, "lavariver": c_lavariver,
}


# --------------------------------------------------------------- atrezo ---
SLOT_W = {1: 1, 2: 3, 3: 6, 4: 6, 5: 2, 6: 1, 7: 3, 8: 1, 9: 3}
SPACING = {1: 12, 2: 6, 3: 3, 4: 3, 5: 8, 6: 14, 7: 4, 8: 10, 9: 5}
ZONE_BOOST = {0: {3: 2, 4: 2, 9: 2}, 1: {2: 2, 1: 2, 8: 2}, 2: {5: 3, 6: 2, 8: 2, 7: 2}, 3: {5: 3, 2: 2, 6: 2}}
FLAT_NEED = {1: 2, 2: 1, 6: 2, 8: 1, 9: 1}


def scenery(lv, ctx, world, zone, total, protect_x=()):
    """Reparte el atrezo del mundo (dígitos 1-9) sobre el nivel: cada nivel favorece unos elementos distintos."""
    rnd = ctx["rnd"]
    fav = rnd.sample([2, 3, 4, 6, 8, 9], 2)
    last = {}
    placed = []
    dens = 0.16 + 0.06 * rnd.random()
    boost = ZONE_BOOST.get(zone, {})
    for x in range(4, total - 4):
        if any(abs(x - p) < 3 for p in protect_x):
            continue
        if rnd.random() > dens:
            continue
        # candidatos de suelo en esta columna y de techo
        ys = [y for y in range(3, R - 1) if lv.get(x, y) == "#" and lv.get(x, y - 1) == " "]
        ceil = [y for y in range(0, R - 3) if lv.get(x, y) == "#" and lv.get(x, y + 1) == " " and (y == 0 or lv.get(x, y - 1) == "#")]
        opts = []
        for s in range(1, 10):
            wgt = SLOT_W[s] * (3 if s in fav else 1) * boost.get(s, 1)
            opts.extend([s] * wgt)
        s = rnd.choice(opts)
        if s == 7:
            if not ceil:
                continue
            y = ceil[0] + 1
            if lv.get(x, y) != " ":
                continue
        else:
            if not ys:
                continue
            y = rnd.choice(ys) - 1
            if lv.get(x, y) != " ":
                continue
            need = FLAT_NEED.get(s, 0)
            if need:
                base = y + 1
                if not all(lv.get(x + k, base) == "#" and lv.get(x + k, base - 1) == " " for k in range(-need, need + 1)):
                    continue
        if x - last.get(s, -99) < SPACING[s]:
            continue
        if any(abs(x - px) < 2 for px in placed):
            continue
        # no pisar entidades
        if lv.get(x, y) != " " or lv.get(x, y - 1) in "wsjftXC":
            continue
        lv.set(x, y, str(s))
        last[s] = x
        placed.append(x)
    return fav


# ------------------------------------------------------------ composición ---
def recipe_plan(world, idx, d, rnd):
    zones = []
    for z in RECIPES[world][idx]:
        names = [ABBR[a] for a in z.split()]
        if d < 0.30 and idx != 7:
            names = names[:2]  # los primeros niveles son más cortos
        zones.append(names)
    if d > 0.75:
        for zi in range(1, 3):
            zones[zi].append(rnd.choice([ABBR[a] for a in FILLER[world]]))
    return zones


def map_chunk(world, name):
    """Adaptaciones por mundo de un trozo genérico."""
    if name == "valley" and world == 7:
        return "lavariver"
    return name


LOW_NEED = {"vertical": (14, 17)}
NEW_NEED = {"hills": None, "mountain": None, "bridge": None, "valley": None, "waterfall": None, "canopy": None,
            "tower": None, "pillars": None, "cavern": None, "lavariver": None}


def pre_adjust(lv, x, ctx, name):
    """Los trozos clásicos suponen un suelo bajo (filas 12-17): si el terreno venía alto, se baja con escalones."""
    if name in NEW_NEED or name == "checkpoint":
        return 0
    lo, hi = LOW_NEED.get(name, (12, 17))
    return adj(lv, x, ctx, lo, hi)


# --- escenario del jefe ------------------------------------------------------
def arena_props(lv, ctx, world, approach, total):
    """Arena de combate con identidad propia: braseros/antorchas en los extremos, columnas y estructuras al fondo."""
    gt = L.GT0
    rnd = ctx["rnd"]
    def put(x, slot, y=None):
        yy = gt - 1 if y is None else y
        if lv.get(x, yy) == " ":
            lv.set(x, yy, str(slot))
    put(approach + 3, 5)
    put(approach + 41, 5)
    for k, xx in enumerate((approach + 10, approach + 27, approach + 36)):
        put(xx, 2 if k != 1 else 6)
    put(approach + 18, 8)
    put(approach + 31, 3)
    put(approach + 14, 4)
    put(approach + 22, 9)
    for xx in (approach + 6, approach + 17, approach + 29, approach + 40):
        if lv.get(xx, 2) in " ":
            lv.set(xx, 2, "7") if lv.get(xx, 1) == "#" else None
    if lv.get(approach + 22, 0) == " ":
        pass

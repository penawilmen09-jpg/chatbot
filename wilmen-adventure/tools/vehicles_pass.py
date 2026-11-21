"""Post-proceso: intercala secciones de vehículos y persecuciones en los niveles (expansión).

Se corta el nivel en un punto de suelo llano y despejado y se inserta un tramo (geo.slab) con la misma altura de
suelo en ambos extremos. El resultado se valida igual que cualquier nivel (se puede cruzar a pie), así que las
secciones nunca bloquean la partida; el vehículo es la vía más rápida y divertida, no la única.
"""
import random

R = 20
# mundo -> vehículo propio del mundo
WORLD_VEHICLE = {1: "boat", 2: "cart", 3: "cart", 4: "boat", 5: "cart", 6: "flyer", 7: "cart", 8: "boat", 9: "mech", 10: "flyer"}


def plan(world, idx):
    """Lista de tramos ('vehículo' o 'chase') que lleva un nivel."""
    if idx in (2, 8):
        return [WORLD_VEHICLE[world]]
    if idx == 5:
        return ["chase"]
    if idx == 3 and world == 9:
        return ["mech"]
    return []


def _surf(g, x):
    if g[R - 1][x] != "#":
        return None
    y = R - 1
    while y >= 3 and g[y][x] == "#":
        y -= 1
    return y + 1


def _cut_sites(g, w, xmin, xmax):
    sites = []
    for x in range(xmin, min(xmax, w - 40)):
        s = [_surf(g, x + k) for k in range(-3, 4)]
        if any(v is None for v in s) or len(set(s)) != 1 or s[0] > 16 or s[0] < 10:
            continue
        gt = s[0]
        ok = True
        for k in range(-4, 6):
            xx = x + k
            if not 0 <= xx < w:
                ok = False
                break
            for y in range(0, gt):
                allowed = " 123456789o" if y >= gt - 7 else " 123456789"
                if g[y][xx] not in allowed:
                    ok = False
                    break
            if not ok:
                break
        if ok:
            sites.append((x, gt))
    return sites


def apply(n, rows, world, idx, slab_fn, gate_x=None, ok_fn=None):
    kinds = plan(world, idx)
    if not kinds or idx == 10:
        return rows, []
    rnd = random.Random(15000 + n * 13)
    w = max(len(r) for r in rows)
    g = [list(r.ljust(w)) for r in rows]
    placed = []
    for kind in kinds:
        w = len(g[0])
        sites = _cut_sites(g, w, 34, (gate_x - 12) if gate_x else w)
        if not sites:
            continue
        rnd.shuffle(sites)
        for (x, gt) in sites[:12]:
            slab, sw = slab_fn(kind, world, gt, rnd)
            trial = [row[:x + 1] + slab[y] + row[x + 1:] for y, row in enumerate(g)]
            if ok_fn is None or ok_fn(["".join(r).rstrip() for r in trial]):
                g = trial
                placed.append(kind)
                break
    return ["".join(r).rstrip() for r in g], placed

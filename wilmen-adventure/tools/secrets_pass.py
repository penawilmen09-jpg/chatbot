"""Post-proceso de los niveles: cofres y habitaciones secretas (expansión).

Se aplica DESPUÉS de generar y validar el nivel y no toca su recorrido: solo talla cámaras dentro de terreno macizo
(paredes falsas 'Y', puertas secretas 'D', bóvedas con ladrillos 'B' + orbe gigante, sótanos con trampilla 'Y')
y deja cofres N/R/E/Z, gemas especiales 'J' y marcadores 'x'. Con una semilla propia por nivel (determinista).
"""
import random

R = 20


def _grid(rows):
    w = max(len(r) for r in rows)
    return [list(r.ljust(w)) for r in rows], w


def _out(g):
    return ["".join(r).rstrip() for r in g]


def _surf(g, x):
    if g[R - 1][x] != "#":
        return None
    y = R - 1
    while y >= 3 and g[y][x] == "#":
        y -= 1
    return y + 1


def _free(g, w, x0, x1, y0, y1, allowed=" "):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if x < 0 or x >= w or y < 0 or y >= R or g[y][x] not in allowed:
                return False
    return True


def _solid(g, w, x0, x1, y0, y1):
    return all(0 <= x < w and 0 <= y < R and g[y][x] == "#" for y in range(y0, y1 + 1) for x in range(x0, x1 + 1))


def _cliff_sites(g, w, xmax):
    """Caras verticales de >= 5 filas con un bloque macizo detrás: (x_entrada, dir, s0, s1)."""
    sites = []
    for x in range(22, min(w - 24, xmax)):
        s0, s1 = _surf(g, x), _surf(g, x + 1)
        if s0 is None or s1 is None:
            continue
        if s0 - s1 >= 5:  # el bloque está a la derecha
            # cámara: columnas x+1..x+7, filas s0-3..s0-1 (la entrada es la columna x+1)
            if _solid(g, w, x + 1, x + 8, s0 - 5, s0 - 1) and _free(g, w, x - 3, x, s0 - 3, s0 - 1):
                if all((_surf(g, x + k) or 99) <= s0 - 4 for k in range(1, 9)):
                    sites.append((x, 1, s0))
        s0b, s1b = _surf(g, x + 1), _surf(g, x)
        if s0b is not None and s1b is not None and s0b - s1b >= 5:  # el bloque está a la izquierda
            if _solid(g, w, x - 7, x, s0b - 5, s0b - 1) and _free(g, w, x + 1, x + 4, s0b - 3, s0b - 1):
                if all((_surf(g, x - k) or 99) <= s0b - 4 for k in range(0, 8)):
                    sites.append((x + 1, -1, s0b))
    return sites


def _carve_cliff(g, x, d, s0, style, kind):
    """Cámara de 6x3 junto a una cara: x es la columna de aire junto a la cara; d = lado del bloque."""
    e = x + d  # columna de la cara (entrada)
    cols = [e + d * k for k in range(0, 7)]  # e, e+d, ... (6 de interior + la entrada)
    for cx in cols[1:]:
        for y in range(s0 - 3, s0):
            g[y][cx] = " "
    ent = {"wall": "Y", "door": "D", "vault": "B"}[style]
    for y in (s0 - 2, s0 - 1):
        g[y][e] = ent
    g[s0 - 3][e] = "#"
    chest_x = cols[5]
    g[s0 - 1][chest_x] = kind
    g[s0 - 1][cols[3]] = "J" if kind in "REZ" else "o"
    for cx in (cols[2], cols[4]):
        g[s0 - 1][cx] = "o"
    if style == "vault":
        g[s0 - 1][cols[2]] = "x"
    return (e, s0)


def _cellar_sites(g, w, xmax):
    sites = []
    for x in range(26, min(w - 30, xmax), 3):
        s = [_surf(g, x + k) for k in range(10)]
        if any(v is None for v in s) or len(set(s)) != 1:
            continue
        gt = s[0]
        if gt > 16 or gt < 8:
            continue
        if not _solid(g, w, x, x + 9, gt, gt + 3 if gt + 3 < R else R - 1):
            continue
        if not _free(g, w, x - 1, x + 10, gt - 4, gt - 1, allowed=" 123456789"):
            continue
        sites.append((x, gt))
    return sites


def _carve_cellar(g, x, gt, kind):
    for y in (gt + 1, gt + 2):
        for cx in range(x + 1, x + 9):
            g[y][cx] = " "
    for cx in (x + 4, x + 5):
        g[gt][cx] = "Y"
    g[gt + 2][x + 7] = kind
    g[gt + 2][x + 3] = "J" if kind in "REZ" else "o"
    g[gt + 2][x + 2] = "o"
    g[gt + 2][x + 5] = "o"
    # quitar atrezo que quedara sobre la trampilla
    for cx in range(x + 3, x + 7):
        if g[gt - 1][cx] in "123456789":
            g[gt - 1][cx] = " "


def _visible_chest(g, w, rnd, kind, xmax):
    cands = []
    for x in range(24, min(w - 26, xmax)):
        s = _surf(g, x)
        if s is None or s > 16:
            continue
        if not _free(g, w, x - 2, x + 2, s - 4, s - 1, allowed=" 123456789o"):
            continue
        if any(_surf(g, x + k) != s for k in (-2, -1, 1, 2)):
            continue
        cands.append((x, s))
    rnd.shuffle(cands)
    for (x, s) in cands:
        if all(g[yy][xx] not in "CFPSG" for yy in range(R) for xx in range(x - 5, x + 6) if 0 <= xx < w):
            g[s - 1][x] = kind
            return True
    return False


def plan(n, world, idx):
    """(cofre visible, [tipos de cámara secreta])."""
    rnd = random.Random(9000 + n * 17)
    if idx == 10:
        return ("N" if rnd.random() < 0.7 else None), ["E"]
    if idx == 7:
        return "N", ["Z", "E"]
    vis = "R" if (world >= 6 and idx % 2 == 0) else "N"
    if rnd.random() < 0.2:
        vis = None
    rooms = ["E" if (world >= 3 and idx in (3, 6, 9)) else "R"]
    if rnd.random() < 0.35 or idx in (2, 5, 8):
        rooms.append("R" if rooms[0] == "E" else "E" if world >= 4 else "R")
    return vis, rooms


def apply(n, rows, world, idx, gate_x=None):
    """Devuelve (filas nuevas, resumen). Si no encuentra sitio para algo, lo omite."""
    g, w = _grid(rows)
    rnd = random.Random(7000 + n * 31)
    xmax = (gate_x - 10) if gate_x else w
    vis, rooms = plan(n, world, idx)
    summary = {"visible": 0, "rooms": [], "styles": []}
    used_x = []
    for kind in rooms:
        done = False
        cliffs = [s for s in _cliff_sites(g, w, xmax) if all(abs(s[0] - u) > 16 for u in used_x)]
        cellars = [s for s in _cellar_sites(g, w, xmax) if all(abs(s[0] - u) > 16 for u in used_x)]
        rnd.shuffle(cliffs)
        rnd.shuffle(cellars)
        order = []
        if cliffs:
            order.append("cliff")
        if cellars:
            order.append("cellar")
        if cellars and cliffs and rnd.random() < 0.3:
            order.reverse()
        for site_kind in order:
            if site_kind == "cliff":
                x, d, s0 = cliffs[0]
                style = rnd.choice(["wall", "wall", "door", "vault"])
                if style == "vault":
                    # el orbe gigante («llave» de la bóveda: rompe los ladrillos) a unos pasos de la pared, en el suelo bajo
                    ox = x - 5 if d == 1 else x + 5
                    if not (0 <= ox < w and _surf(g, ox) == s0 and g[s0 - 1][ox] == " "):
                        style = "wall"
                    else:
                        g[s0 - 1][ox] = "q"
                _carve_cliff(g, x, d, s0, style, kind)
                used_x.append(x)
                summary["styles"].append(style)
            else:
                x, gt = cellars[0]
                _carve_cellar(g, x, gt, kind)
                used_x.append(x)
                summary["styles"].append("cellar")
            summary["rooms"].append(kind)
            done = True
            break
        if not done:
            continue
    if vis and _visible_chest(g, w, rnd, vis, xmax):
        summary["visible"] = 1
    return _out(g), summary

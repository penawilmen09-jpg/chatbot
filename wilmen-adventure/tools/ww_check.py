#!/usr/bin/env python3
"""Comprobador de los niveles de WILMEN WORLD (levels/world/ww_NNN.txt).

Reutiliza la física del validador de WILMEN ADVENTURE (tools/levelgen.py: alcance de saltos, apoyos, peligros) y le añade lo
nuevo: túneles y puertas (aristas del grafo), llaves (se recogen, se gastan en verjas y puertas con candado), reloj
(tiempo mínimo estimado de la ruta frente al límite) y variedad/longitud. Sale con código 1 si algún nivel no es jugable.
Uso: python3 tools/ww_check.py [--summary]
"""
import glob, heapq, math, os, sys
from collections import deque

sys.path.insert(0, os.path.dirname(__file__))
import levelgen as lg

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
WORLD_DIR = os.path.join(ROOT, "levels", "world")
CELL_RUN = 16.0 / 125.0  # segundos por celda corriendo (125 px/s)


def parse(path):
    rows, meta, warps = [], {"time": 300, "difficulty": 1}, []
    for line in open(path).read().split("\n"):
        line = line.rstrip("\r")
        if line.startswith(";"):
            continue
        if line.startswith("@"):
            k, _, v = line[1:].partition(" ")
            if k in ("time", "difficulty", "region", "theme", "zone", "boss"):
                meta[k] = int(v)
            elif k in ("title", "kind"):
                meta[k] = v
            elif k == "warp":
                p = v.split()
                a = tuple(int(t) for t in p[0].split(","))
                b = tuple(int(t) for t in p[2].split(","))
                w = {"a": a, "b": b, "kind": p[3], "key": 0, "dir": 1}
                for extra in p[4:]:
                    kk, _, vv = extra.partition("=")
                    w[kk] = int(vv)
                warps.append(w)
            continue
        rows.append(line)
    while rows and rows[-1] == "":
        rows.pop()
    w = max(len(r) for r in rows)
    rows = [r.ljust(w) for r in rows]
    while len(rows) < lg.R:
        rows.append(" " * w)
    return rows, meta, warps


def sim_rows(rows, open_gates):
    """Mapa para el validador de saltos: glifos nuevos son aire; las verjas son sólidas salvo las abiertas."""
    out = []
    for y, r in enumerate(rows):
        s = []
        for x, ch in enumerate(r):
            if ch in "TAUIM":
                s.append(" ")
            elif ch == "Q":
                s.append(" " if (x, y) in open_gates else "#")
            else:
                s.append(ch)
        out.append("".join(s))
    return out


class Level:
    def __init__(self, path):
        self.path = path
        self.rows, self.meta, self.warps = parse(path)
        self.w = len(self.rows[0])
        self.errors, self.notes = [], []

    def cells(self, ch):
        return [(x, y) for y, r in enumerate(self.rows) for x, c in enumerate(r) if c == ch]

    def gates(self):
        """Verjas: columnas de Q (celda superior -> lista de celdas)."""
        seen, out = set(), []
        for (x, y) in self.cells("Q"):
            if (x, y) in seen:
                continue
            col = []
            yy = y
            while yy < len(self.rows) and self.rows[yy][x] == "Q":
                col.append((x, yy))
                seen.add((x, yy))
                yy += 1
            out.append(col)
        return out


def neighbors(ck, st, node):
    """Mismas transiciones que levelgen.reach: caminar, salto, resorte, viento, doble salto."""
    ax, ay = node
    res = []
    for dx in range(-8, 9):
        bx = ax + dx
        for by in range(ay - 10, ay + 13):
            if (bx, by) == node or (bx, by) not in st:
                continue
            dyu = ay - by
            adx = abs(dx)
            ok = False
            if adx == 1 and dyu == 0:
                ok = ck.ch(bx, by) not in "^L"
            if not ok:
                lim = 3 if dyu >= 2 else (4 if dyu >= 0 else 5)
                if dyu <= 3 and adx <= lim:
                    ok = lg.arc_ok(ck, ax, ay, bx, by, 3.2)
            if not ok and ck.ch(ax, ay) == "S" and dyu <= 6 and adx <= 3:
                ok = lg.arc_ok(ck, ax, ay, bx, by, 7.4)
            if not ok and (ck.ch(ax, ay) == "W" or ck.ch(ax, ay - 1) == "W") and dyu <= 9 and adx <= 3:
                ok = lg.arc_ok(ck, ax, ay, bx, by, 10.5)
            if not ok:
                lim2 = 4 if dyu >= 4 else (5 if dyu == 3 else (7 if dyu >= 0 else 8))
                if dyu <= 5 and adx <= lim2:
                    ok = lg.arc_ok(ck, ax, ay, bx, by, 5.6)
            if ok:
                cost = adx * CELL_RUN if (adx == 1 and dyu == 0) else max(0.55, adx * CELL_RUN + 0.35 + 0.1 * max(0, dyu))
                res.append(((bx, by), cost))
    return res


def stand_near(st, x, y, maxdy=4):
    """Celda de pie más cercana (misma columna, hacia abajo o arriba)."""
    for d in range(0, maxdy + 1):
        for yy in (y + d, y - d):
            if (x, yy) in st:
                return (x, yy)
    return None


def door_arrival(cell, side):
    return int(math.floor(cell[0] + 0.5 + side * 22.0 / 16.0))


def kind_of(lv):
    return lv.meta.get("kind", "normal")


def analyse(lv):
    errs = lv.errors
    rows = lv.rows
    n_p, n_f = len(lv.cells("P")), len(lv.cells("F"))
    if n_p != 1:
        errs.append("debe haber exactamente 1 'P' (hay %d)" % n_p)
    if n_f != 1:
        errs.append("debe haber exactamente 1 'F' (hay %d)" % n_f)
    gems = lv.cells("*")
    if len(gems) != 3:
        errs.append("debe haber 3 gemas (hay %d)" % len(gems))
    if not (700 <= lv.w <= 1000):
        errs.append("el nivel debe tener entre 700 y 1000 columnas (tiene %d)" % lv.w)
    num = int(os.path.basename(lv.path)[3:6])
    idx = (num - 1) % 20 + 1
    secret_levels = {5, 9, 13, 19}
    n_o = len(lv.cells("O"))
    if (idx in secret_levels) != (n_o == 1) or n_o > 1:
        errs.append("salida secreta: el nivel %d %s tener una 'O' (hay %d)" % (num, "debe" if idx in secret_levels else "no debe", n_o))
    kind = lv.meta.get("kind", "normal")
    boss = lv.meta.get("boss", 0)
    exp_kind = {4: "cave", 13: "cave", 7: "house", 10: "fortress", 19: "secret", 20: "castle"}.get(idx, "normal")
    if kind != exp_kind:
        errs.append("el tipo del nivel %d debe ser %r (es %r)" % (num, exp_kind, kind))
    flat_all = "".join(lv.rows)
    top_rows = "".join(lv.rows[:3])
    if kind == "cave" and top_rows.count("#") < 150:
        errs.append("una cueva necesita techo (hay %d bloques en las 3 filas superiores)" % top_rows.count("#"))
    if kind == "house" and flat_all.count("o") < 150:
        errs.append("la casa de bonificación debe tener muchas monedas (%d)" % flat_all.count("o"))
    if kind == "fortress" and flat_all.count("p") < 6:
        errs.append("la fortaleza necesita prensas (hay %d)" % flat_all.count("p"))
    if kind == "castle":
        if boss < 1 or len(lv.cells("X")) != 1 or len(lv.cells("G")) != 1:
            errs.append("el castillo necesita jefe (@boss), una 'X' y una 'G'")
    elif len(lv.cells("X")) or len(lv.cells("G")):
        errs.append("jefe o puerta de jefe en un nivel que no es castillo")
    main_cols = lv.cells("F")[0][0] + 10 if lv.cells("F") else lv.w
    if len(lv.cells("C")) < max(3, main_cols // 170):
        errs.append("pocos puntos de control (%d) para %d columnas de recorrido" % (len(lv.cells("C")), main_cols))
    if not lv.cells("U") and kind_of(lv) != "castle":
        errs.append("sin llaves")
    if not (lv.cells("I") or lv.cells("M")):
        errs.append("sin relojes de tiempo extra")
    for g in lv.gates():
        if len(g) < 3:
            errs.append("verja demasiado baja en %s" % (g[0],))
    # aristas de warps
    glyph_ok = True
    for wp in lv.warps:
        for end in (wp["a"], wp["b"]):
            ch = rows[end[1]][end[0]]
            if ch != ("T" if wp["kind"] == "tunnel" else "A"):
                errs.append("el extremo %s del warp no tiene su glifo (hay %r)" % (end, ch))
                glyph_ok = False
    if n_p != 1 or n_f != 1 or not glyph_ok:
        return
    open_gates = set()
    keys_have = 0
    consumed = set()
    keys_seen = set()
    opened_doors = set()
    start = lv.cells("P")[0]
    goal = lv.cells("F")[0]
    if kind == "castle":
        goal = lv.cells("G")[0]  # en el castillo se comprueba que se llega a la arena; la meta aparece al vencer al jefe

    def build():
        ck = lg.Check(sim_rows(rows, open_gates))
        return ck, ck.standable()

    def graph_extra(ck, st):
        """Aristas de túneles y puertas (puertas con cerradura solo si ya se pueden abrir/están abiertas)."""
        extra = {}
        for i, wp in enumerate(lv.warps):
            a, b = wp["a"], wp["b"]
            sa, sb = stand_near(st, a[0], a[1]), stand_near(st, b[0], b[1])
            if sa is None or sb is None:
                continue
            if wp["kind"] == "tunnel":
                ia, ib = sb, sa
            else:
                dirn = wp["dir"]
                ia = stand_near(st, door_arrival(b, dirn), b[1])
                ib = stand_near(st, door_arrival(a, -dirn), a[1])
                if ia is None or ib is None:
                    continue
            usable_ab = wp["kind"] == "tunnel" or wp["key"] == 0 or i in opened_doors
            if usable_ab:
                extra.setdefault(sa, []).append((ia, 0.9))
            extra.setdefault(sb, []).append((ib, 0.9))
        return extra

    def dijkstra(src, ck, st, extra):
        dist = {src: 0.0}
        pq = [(0.0, src)]
        while pq:
            d, u = heapq.heappop(pq)
            if d > dist.get(u, 1e18):
                continue
            for v, c in neighbors(ck, st, u) + extra.get(u, []):
                nd = d + c
                if nd < dist.get(v, 1e18):
                    dist[v] = nd
                    heapq.heappush(pq, (nd, v))
        return dist

    def start_node(st):
        s = start
        while s[1] < lg.R and s not in st:
            s = (s[0], s[1] + 1)
        return s

    # --- simulación de la partida: recoger llaves y gastarlas donde hace falta
    ck, st = build()
    dist = {}
    steps = 0
    mandatory_time = None
    while steps < 12:
        steps += 1
        extra = graph_extra(ck, st)
        dist = dijkstra(start_node(st), ck, st, extra)
        reach = set(dist)

        def reach_cell(c):
            x, y = c
            for (vx, vy) in reach:
                if abs(vx - x) > 8 or vy - y > 7 or y - vy > 12:
                    continue
                if (vx, vy) == (x, y) or (abs(vx - x) <= 1 and 0 <= vy - y <= 6 and lg.arc_ok(ck, vx, vy, x, y + 1, 5.6)) or (lg.arc_ok(ck, vx, vy, x, y + 1, 5.6) and abs(vx - x) <= 6 and vy - y <= 5):
                    return True
            return False

        for k in lv.cells("U"):
            if k not in keys_seen and reach_cell(k):
                keys_seen.add(k)
                keys_have += 1
        g0 = stand_near(st, goal[0], goal[1], 4)
        if g0 in reach:
            mandatory_time = dist[g0]
            break
        # sin llegar a la meta: abrir la verja alcanzable más cercana si hay llave
        opened = False
        if keys_have > 0:
            for g in lv.gates():
                if g[0] in open_gates:
                    continue
                gx = g[0][0]
                near = any(abs(vx - gx) <= 2 and abs(vy - g[-1][1]) <= 3 for (vx, vy) in reach)
                if near:
                    for cell in g:
                        open_gates.add(cell)
                    keys_have -= 1
                    opened = True
                    break
        if not opened:
            break
        ck, st = build()
    g0 = stand_near(st, goal[0], goal[1], 4)
    if g0 is None or g0 not in dist:
        errs.append("la meta NO es alcanzable (llaves recogidas: %d; se llega hasta la columna %d)" % (len(keys_seen), max([x for (x, y) in dist if x < goal[0]] or [0])))
        return
    lv.notes.append("meta alcanzable; verjas abiertas en la ruta: %d" % (len(open_gates) and sum(1 for g in lv.gates() if g[0] in open_gates)))
    # --- 100%: abrir puertas con llaves restantes
    for i, wp in enumerate(lv.warps):
        if wp["kind"] == "door" and wp["key"] > 0 and keys_have >= wp["key"]:
            opened_doors.add(i)
            keys_have -= wp["key"]
    ck, st = build()
    extra = graph_extra(ck, st)
    dist = dijkstra(start_node(st), ck, st, extra)
    reach = set(dist)
    # gemas, relojes, llaves, checkpoints alcanzables
    def cell_ok(c):
        x, y = c
        for (vx, vy) in reach:
            if abs(vx - x) > 8 or vy - y > 7 or y - vy > 12:
                continue
            if (vx, vy) == (x, y) or (abs(vx - x) <= 1 and 0 <= vy - y <= 6 and lg.arc_ok(ck, vx, vy, x, y + 1, 5.6)) or (lg.arc_ok(ck, vx, vy, x, y + 1, 5.6) and abs(vx - x) <= 6 and vy - y <= 5):
                return True
        return False
    for ch, name in (("*", "gema"), ("U", "llave"), ("I", "reloj"), ("M", "reloj grande"), ("C", "punto de control"), ("O", "salida secreta")):
        for c in lv.cells(ch):
            if not cell_ok(c):
                errs.append("%s inalcanzable en %s" % (name, c))
    for wp in lv.warps:
        sa, sb = stand_near(st, wp["a"][0], wp["a"][1], 1), stand_near(st, wp["b"][0], wp["b"][1], 1)
        if sa not in dist:
            errs.append("el extremo %s de %s no es alcanzable andando" % (wp["a"], wp["kind"]))
    gates_n = len(lv.gates())
    doors_n = sum(1 for wp in lv.warps if wp["kind"] == "door" and wp["key"] > 0)
    keys_n = len(lv.cells("U"))
    lv.notes.append("llaves %d, verjas %d, puertas con llave %d, túneles %d" % (keys_n, gates_n, doors_n, sum(1 for wp in lv.warps if wp["kind"] == "tunnel")))
    if keys_n < gates_n + doors_n:
        errs.append("hay menos llaves (%d) que cerraduras (%d): no se puede abrir todo" % (keys_n, gates_n + doors_n))
    # llegada de los warps
    for wp in lv.warps:
        for end, side in ((wp["a"], -wp["dir"]), (wp["b"], wp["dir"])):
            if wp["kind"] == "tunnel":
                if stand_near(st, end[0], end[1], 0) is None:
                    errs.append("la boca de túnel %s no está sobre suelo firme" % (end,))
            else:
                if stand_near(st, door_arrival(end, side), end[1], 0) is None:
                    errs.append("el punto de llegada de la puerta %s no es suelo firme" % (end,))
                if stand_near(st, end[0], end[1], 0) is None:
                    errs.append("la puerta %s no está sobre suelo firme" % (end,))
    # tiempo
    par = mandatory_time or 0.0
    limit = lv.meta["time"]
    lv.notes.append("tiempo mínimo estimado de la ruta %.0f s; límite %d s (x%.1f)" % (par, limit, limit / max(par, 1)))
    full = lv.w * CELL_RUN  # recorrer todo el nivel corriendo sin parar (sin atajos)
    lv.notes.append("carrera completa sin atajos %.0f s; el límite es x%.1f" % (full, limit / full))
    if limit < par * 1.6:
        errs.append("límite de tiempo demasiado justo (%.0f s para una ruta de %.0f s)" % (limit, par))
    if limit < full * 2.6 or limit > full * 4.2:
        errs.append("el límite de tiempo debe estar entre 2.6 y 4.2 veces la carrera completa (%.0f-%.0f s)" % (full * 2.6, full * 4.2))
    # variedad y dificultad
    flat_rows = "".join(rows)
    kinds = {ch: flat_rows.count(ch) for ch in "^LmvcgpW<>SwsjftTAQUIM"}
    present = [ch for ch, k in kinds.items() if k > 0]
    lv.notes.append("columnas %d · enemigos %d · pinchos %d · elementos distintos %d (%s)" % (lv.w, sum(kinds[k] for k in "wsjft"), kinds["^"], len(present), "".join(present)))
    if len(present) < 11:
        errs.append("poca variedad de elementos (%d)" % len(present))


def fingerprint(lv):
    flat = "".join(lv.rows)
    keys = "=^~aomvcgpWSwsjftTAQUIMB"  # lo que da carácter al nivel (sin suelo ni vacío)
    v = [flat.count(k) for k in keys]
    tot = float(sum(v)) or 1.0
    return [x / tot for x in v]


def cosine(a, b):
    num = sum(x * y for x, y in zip(a, b))
    da = math.sqrt(sum(x * x for x in a))
    db = math.sqrt(sum(y * y for y in b))
    return num / max(1e-9, da * db)


def pieces_of(path):
    for line in open(path):
        if line.startswith("; piezas:"):
            return line.split(":", 1)[1].strip().split(",")
    return []


def distinct(levels):
    """Ningún par de niveles puede ser casi idéntico: se compara la secuencia de piezas (tríos consecutivos, sin contar
    suelo plano ni puntos de control) y se exige que solapen poco."""
    errs = []

    def grams(seq, n=3):
        return set(tuple(seq[i:i + n]) for i in range(len(seq) - n + 1))

    P = [[x for x in pieces_of(lv.path) if x not in ("checkpoint", "flat")] for lv in levels]
    for i in range(len(levels)):
        for j in range(i + 1, len(levels)):
            a, b = grams(P[i]), grams(P[j])
            overlap = len(a & b) / max(1, min(len(a), len(b)))
            if overlap > 0.35:
                errs.append("%s y %s se parecen demasiado (comparten el %d%% de su secuencia de piezas)" % (os.path.basename(levels[i].path), os.path.basename(levels[j].path), int(overlap * 100)))
    return errs


def main():
    files = [f for f in sorted(glob.glob(os.path.join(WORLD_DIR, "ww_*.txt"))) if not f.endswith("ww_950.txt")]  # el taller (950) se valida con ww_mech_check.py
    bad = 0
    levels = []
    for f in files:
        lv = Level(f)
        analyse(lv)
        levels.append(lv)
        print("%s: %s" % (os.path.basename(f), "OK" if not lv.errors else "ERRORES"))
        for n in lv.notes:
            print("    " + n)
        for e in lv.errors:
            print("    ✗ " + e)
        bad += len(lv.errors)
    for e in distinct(levels):
        print("✗ " + e)
        bad += 1
    import ww_mech_check as mc
    for f in files + [os.path.join(WORLD_DIR, "ww_950.txt")]:
        for e in mc.check(mc.load(f), mc.PRESSES.get(f, ())):
            print("%s: x %s" % (os.path.basename(f), e))
            bad += 1
    print("niveles revisados: %d | errores: %d" % (len(files), bad))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()

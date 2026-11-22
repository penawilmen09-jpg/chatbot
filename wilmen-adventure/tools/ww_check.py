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
            if k in ("time", "difficulty", "region", "theme"):
                meta[k] = int(v)
            elif k == "title":
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
    if len(lv.cells("C")) < 3:
        errs.append("faltan puntos de control (mínimo 3)")
    if lv.w < 500:
        errs.append("el nivel es demasiado corto: %d columnas (mínimo 500)" % lv.w)
    if not lv.cells("U"):
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
        errs.append("la meta NO es alcanzable (llaves recogidas: %d)" % len(keys_seen))
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
    for ch, name in (("*", "gema"), ("U", "llave"), ("I", "reloj"), ("M", "reloj grande"), ("C", "punto de control")):
        for c in lv.cells(ch):
            if not cell_ok(c):
                errs.append("%s inalcanzable en %s" % (name, c))
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


def main():
    files = sorted(glob.glob(os.path.join(WORLD_DIR, "ww_*.txt")))
    bad = 0
    for f in files:
        lv = Level(f)
        analyse(lv)
        print("%s: %s" % (os.path.basename(f), "OK" if not lv.errors else "ERRORES"))
        for n in lv.notes:
            print("    " + n)
        for e in lv.errors:
            print("    ✗ " + e)
        bad += len(lv.errors)
    print("niveles revisados: %d | errores: %d" % (len(files), bad))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()

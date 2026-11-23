#!/usr/bin/env python3
"""Validador de los niveles nuevos de WILMEN WORLD (los que declaran `@par`): comprueba por simulación del grafo de movimientos
(reutiliza la física de saltos de levelgen.py y añade las mecánicas nuevas) que:
  - la meta es alcanzable SIN abrir ninguna puerta y SIN llaves;
  - todas las llaves se alcanzan sin abrir ninguna puerta y hay al menos tantas llaves como cerraduras;
  - con todas las puertas abiertas se alcanzan las 3 gemas y todos los premios;
  - desde cualquier punto alcanzable se puede llegar a la meta (nunca se queda uno atrapado);
  - el reloj: @par y @time son coherentes con la ruta estimada y con la exploración completa.
Aristas de mecánicas (conservadoras): setas, lianas, burbujas, ascensores, plataformas orbitales, resortes, interruptores.
Uso: python3 tools/ww_t1_check.py [archivos.txt ...]"""
import glob, heapq, math, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import levelgen as lg
import ww_check as wc

AIR = set("TAUIMdoh*uPFCOwsjftzDY0keilqa|123456789$%{}&'/\\:.,\"`!nb")
CELL = wc.CELL_RUN


def arc_fixed(ck, ax, ay, bx, by, apex):
    """Como levelgen.arc_ok pero con la cima del arco fijada (para setas)."""
    dyu = ay - by
    if apex < dyu + 0.2 and dyu > 0:
        return False
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
            for yy in (feet - 0.05, feet - 0.65, feet - 1.25):
                if i > 0 and ck.blocking(int(math.floor(x)), int(math.floor(yy))):
                    return False
    return True


class Sim:
    def __init__(self, path):
        self.path = path
        self.rows, self.meta, self.warps = wc.parse(path)
        self.H, self.W = len(self.rows), len(self.rows[0])
        self.errors, self.notes = [], []
        self.toggles = {1: False, 2: False}
        for r in self.rows:
            for ch in r:
                if ch in "()":
                    self.toggles[1] = True
                if ch in "[]":
                    self.toggles[2] = True
        self.ncomb = 1 + (1 if self.toggles[1] else 0) + (2 if self.toggles[2] else 0)
        self.states = [(a, b) for a in ((0, 1) if self.toggles[1] else (0,)) for b in ((0, 1) if self.toggles[2] else (0,))]
        self.ck, self.st = {}, {}
        for s in self.states:
            self.ck[s] = lg.Check(self.sim_rows(s))
            self.st[s] = self.ck[s].standable()
        self.cache = {}

    def cells(self, ch):
        return [(x, y) for y, r in enumerate(self.rows) for x, c in enumerate(r) if c == ch]

    def sim_rows(self, s):
        out = []
        for y, r in enumerate(self.rows):
            o = []
            for x, ch in enumerate(r):
                if ch in "-_":
                    o.append("=")
                elif ch == "(":
                    o.append("#" if s[0] == 0 else " ")
                elif ch == ")":
                    o.append("#" if s[0] == 1 else " ")
                elif ch == "[":
                    o.append("#" if (len(s) > 1 and s[1] == 0 or len(s) == 1) else " ")
                elif ch == "]":
                    o.append("#" if (len(s) > 1 and s[1] == 1) else " ")
                elif ch in AIR:
                    o.append(" ")
                else:
                    o.append(ch)
            out.append("".join(o))
        return out

    # ------------------------------------------------------------ aristas
    def edges(self, node, s, doors_open):
        key = (node, s, doors_open)
        if key in self.cache:
            return self.cache[key]
        ck, st = self.ck[s], self.st[s]
        res = list(wc.neighbors(ck, st, node))
        res = [((n, s), c) for (n, c) in res]
        res += self.mech_edges(node, s)
        res += self.walk_off(node, s)
        x, y = node
        for wp in self.warps:
            a, b = wp["a"], wp["b"]
            sa, sb = wc.stand_near(st, a[0], a[1]), wc.stand_near(st, b[0], b[1])
            if sa is None or sb is None:
                continue
            if wp["kind"] == "tunnel":
                ia, ib = sb, sa
            else:
                ia = wc.stand_near(st, wc.door_arrival(b, wp["dir"]), b[1])
                ib = wc.stand_near(st, wc.door_arrival(a, -wp["dir"]), a[1])
                if ia is None or ib is None:
                    continue
            ok_ab = wp["kind"] == "tunnel" or wp["key"] == 0 or doors_open
            if node == sa and ok_ab:
                res.append(((ia, s), 0.9))
            if node == sb:
                res.append(((ib, s), 0.9))
        # interruptores: pisar la celda del interruptor cambia el estado
        ch = self.rows[y][x]
        if ch == "/" and self.toggles[1]:
            ns = (1 - s[0],) + s[1:]
            if ns in self.st and node in self.st[ns]:
                res.append(((node, ns), 0.3))
        if ch == "\\" and self.toggles[2]:
            ns = (s[0], 1 - s[1])
            if ns in self.st and node in self.st[ns]:
                res.append(((node, ns), 0.3))
        self.cache[key] = res
        return res

    def walk_off(self, node, s):
        """Caer andando por el borde de una repisa (sin saltar): cae en vertical y aterriza en el primer apoyo."""
        ck, st = self.ck[s], self.st[s]
        x, y = node
        out = []
        for d in (-1, 1):
            for drift in (1, 2):
                nx = x + d * drift
                if ck.solid(nx, y) or ck.solid(nx, y - 1) or ck.supported(nx, y):
                    break
                yy = y
                while yy < self.H + 1 and (nx, yy) not in st:
                    yy += 1
                    if ck.blocking(nx, yy) or yy > self.H:
                        yy = None
                        break
                if yy is not None and (nx, yy) in st and yy > y:
                    out.append((((nx, yy), s), 0.3 + 0.08 * (yy - y)))
                break
        return out

    def mech_edges(self, node, s):
        ck, st = self.ck[s], self.st[s]
        x, y = node
        ch = self.rows[y][x]
        out = []
        if ch in "%{}":
            for (bx, by) in st:
                dx, dyu = bx - x, y - by
                if (bx, by) == node:
                    continue
                if ch == "%" and abs(dx) <= 5 and 1 <= dyu <= 7 and arc_fixed(ck, x, y, bx, by, 7.4):
                    out.append((((bx, by), s), 1.2))
                elif ch == "{" and 4 <= dx <= 14 and -9 <= dyu <= 5 and arc_fixed(ck, x, y, bx, by, 6.6):
                    out.append((((bx, by), s), 1.4))
                elif ch == "}" and 4 <= -dx <= 14 and -9 <= dyu <= 5 and arc_fixed(ck, x, y, bx, by, 6.6):
                    out.append((((bx, by), s), 1.4))
        for vx, v_top, vlen in self.vines():
            low = v_top + vlen
            if abs(x - vx) <= 9 and low - 3 <= y <= low + 5:
                for (bx, by) in st:
                    if abs(bx - vx) <= 9 and low - 3 <= by <= low + 5 and abs(bx - x) >= 3 and (bx - vx) * (x - vx) <= 0:
                        out.append((((bx, by), s), 3.0))
        for z in self.bubbles():
            zx0, zx1, zy0, zy1 = z
            if zx0 - 2 <= x <= zx1 + 2 and zy0 <= y <= zy1 + 3:
                for (bx, by) in st:
                    if zx0 - 5 <= bx <= zx1 + 5 and zy0 - 2 <= by < y - 1:
                        out.append((((bx, by), s), 1.0 + (y - by) / 10.0))
        for (ex, ey) in self.cells("b"):
            if ex - 1 <= x <= ex + 2 and ey - 2 <= y <= ey + 1:
                for (bx, by) in st:
                    if ex - 3 <= bx <= ex + 4 and ey - 8 <= by <= ey - 5:
                        out.append((((bx, by), s), 4.0))
            if ex - 3 <= x <= ex + 4 and ey - 8 <= y <= ey - 5:
                for (bx, by) in st:
                    if ex - 1 <= bx <= ex + 2 and ey - 2 <= by <= ey + 1:
                        out.append((((bx, by), s), 3.0))
        for (ox, oy) in self.cells("n"):
            if (x - ox) ** 2 + (y - oy) ** 2 <= 49:
                for (bx, by) in st:
                    if (bx - ox) ** 2 + (by - oy) ** 2 <= 49 and abs(bx - x) >= 3:
                        out.append((((bx, by), s), 3.0))
        return out

    def vines(self):
        if hasattr(self, "_v"):
            return self._v
        res = []
        for (x, y) in self.cells("$"):
            if self.rows[y - 1][x] != "$":
                n = 0
                while y + n < self.H and self.rows[y + n][x] == "$":
                    n += 1
                res.append((x, y, n))
        self._v = res
        return res

    def bubbles(self):
        if hasattr(self, "_b"):
            return self._b
        cs = set(self.cells(","))
        seen, res = set(), []
        for c in sorted(cs):
            if c in seen:
                continue
            stack, comp = [c], []
            while stack:
                p = stack.pop()
                if p in seen or p not in cs:
                    continue
                seen.add(p)
                comp.append(p)
                stack += [(p[0] + 1, p[1]), (p[0] - 1, p[1]), (p[0], p[1] + 1), (p[0], p[1] - 1)]
            res.append((min(a for a, b in comp), max(a for a, b in comp), min(b for a, b in comp), max(b for a, b in comp)))
        self._b = res
        return res

    # ------------------------------------------------------------ alcance
    def start_node(self, s):
        x, y = self.cells("P")[0]
        while y < self.H and (x, y) not in self.st[s]:
            y += 1
        return (x, y)

    def dijkstra(self, src, doors_open):
        dist = {src: 0.0}
        pq = [(0.0, src)]
        while pq:
            d, u = heapq.heappop(pq)
            if d > dist.get(u, 1e18):
                continue
            for v, c in self.edges(u[0], u[1], doors_open):
                nd = d + c
                if nd < dist.get(v, 1e18):
                    dist[v] = nd
                    heapq.heappush(pq, (nd, v))
        return dist

    def near_reach(self, cell, reach_nodes, ck=None):
        """¿Se puede tocar `cell` desde algún nodo alcanzado? (objetos en el aire: monedas, gemas, llaves...)"""
        x, y = cell
        ck = ck or self.ck[self.states[0]]
        for (vx, vy) in reach_nodes:
            if abs(vx - x) > 7 or vy - y > 7 or y - vy > 6:
                continue
            if (vx, vy) == (x, y) or (abs(vx - x) <= 1 and 0 <= vy - y <= 3) or (abs(vx - x) <= 6 and lg.arc_ok(ck, vx, vy, x, y + 1, 5.6)):
                return True
        return False


def analyse(path):
    sm = Sim(path)
    errs, notes = sm.errors, sm.notes
    rows, meta = sm.rows, sm.meta
    P, F = sm.cells("P"), sm.cells("F")
    if len(P) != 1 or len(F) != 1:
        errs.append("debe haber 1 'P' y 1 'F'")
        return sm
    gems = sm.cells("*")
    if len(gems) != 3:
        errs.append("debe haber 3 gemas (hay %d)" % len(gems))
    keys = sm.cells("U")
    doors = [w for w in sm.warps if w["kind"] == "door" and w["key"] > 0]
    if len(keys) < sum(w["key"] for w in doors):
        errs.append("hay %d llaves para %d cerraduras (debe haber al menos tantas llaves como cerraduras)" % (len(keys), sum(w["key"] for w in doors)))
    if not (20 <= sm.H <= 40):
        errs.append("altura %d fuera de 20..40" % sm.H)
    if not (340 <= sm.W <= 900):
        errs.append("anchura %d fuera de 340..900" % sm.W)
    s0 = sm.states[0]
    start = sm.start_node(s0)
    # 1) con todas las puertas cerradas
    d0 = sm.dijkstra((start, s0), False)
    reach0 = {n for (n, s) in d0}
    gnode = wc.stand_near(sm.st[s0], F[0][0], F[0][1], 6)
    goal_states = [(gnode, s) for s in sm.states if (gnode, s) in d0]
    mandatory = meta.get("kind") == "fortress"   # la fortaleza tiene cerraduras OBLIGATORIAS (con sus llaves libres y suficientes)
    if not goal_states and not mandatory:
        errs.append("la meta NO es alcanzable sin abrir puertas (se llega hasta la columna %d)" % max([x for (x, y) in reach0 if x < F[0][0]] or [0]))
        return sm
    if not goal_states:
        dm = sm.dijkstra((start, s0), True)
        goal_states = [(gnode, s) for s in sm.states if (gnode, s) in dm]
        if not goal_states:
            errs.append("la meta NO es alcanzable ni con todas las puertas abiertas")
            return sm
        d0 = dm
        need = sum(w["key"] for w in doors)
        free = [k for k in keys if sm.near_reach(k, reach0)]
        if len(free) < need:
            errs.append("la meta exige %d llaves libres y solo hay %d" % (need, len(free)))
    p_est = min(d0[g] for g in goal_states)
    for k in keys:
        if not sm.near_reach(k, reach0):
            errs.append("la llave %s no se alcanza sin abrir puertas" % (k,))
    # 2) con todas las puertas abiertas
    d1 = sm.dijkstra((start, s0), True)
    reach1 = {n for (n, s) in d1}
    for g in gems:
        if not sm.near_reach(g, reach1):
            errs.append("la gema %s NO es alcanzable" % (g,))
    items = []
    for ch, name in (("*", "gema"), ("k", "orbe"), ("e", "orbe"), ("i", "orbe"), ("l", "orbe"), ("q", "orbe"), ("u", "vida"), ("h", "corazón"), ("I", "reloj"), ("M", "reloj"), ("U", "llave"), ("O", "salida secreta")):
        for c in sm.cells(ch):
            if not sm.near_reach(c, reach1):
                errs.append("%s %s inalcanzable" % (name, c))
            else:
                items.append((c, name))
    # 3) nunca atrapado: todo nodo alcanzable (con las puertas abiertas) debe poder llegar a la meta
    allnodes = list(d1)
    radj = {}
    for u in allnodes:
        for v, c in sm.edges(u[0], u[1], True):
            radj.setdefault(v, []).append((u, c))
    back = {}
    pq = []
    for g in [(gnode, s) for s in sm.states]:
        back[g] = 0.0
        pq.append((0.0, g))
    heapq.heapify(pq)
    while pq:
        d, u = heapq.heappop(pq)
        if d > back.get(u, 1e18):
            continue
        for v, c in radj.get(u, []):
            nd = d + c
            if nd < back.get(v, 1e18):
                back[v] = nd
                heapq.heappush(pq, (nd, v))
    trapped = [n for n in allnodes if n not in back]
    # una caída al vacío no crea nodos, así que cualquier nodo sin salida es una trampa real
    tr_cells = sorted({n[0] for n in trapped})
    if tr_cells:
        errs.append("zonas sin salida hacia la meta (%d celdas), p. ej. %s" % (len(tr_cells), tr_cells[:5]))
    # 4) reloj
    detours = {}
    for c, name in items:
        best = None
        for (n, s), dd in d1.items():
            if abs(n[0] - c[0]) <= 3 and abs(n[1] - c[1]) <= 4:
                tb = back.get((n, s))
                if tb is not None:
                    v = dd + tb
                    best = v if best is None else min(best, v)
        if best is not None:
            detours.setdefault(c[0] // 25, []).append(max(0.0, best - p_est))
    e_est = p_est + sum(max(v) for v in detours.values())
    par, tl = int(meta.get("par", 0)), int(meta.get("time", 300))
    notes.append("P ideal %.0f s · E ideal %.0f s · @par %d · @time %d" % (p_est, e_est, par, tl))
    if par < p_est * 1.3:
        errs.append("@par %d es menor que 1,3 x la ruta ideal (%.0f s)" % (par, p_est * 1.3))
    if tl < 2.5 * par:
        errs.append("@time %d < 2,5 x @par (%d)" % (tl, int(2.5 * par)))
    if tl < 2.0 * e_est:
        errs.append("@time %d no cubre explorarlo todo (2 x %.0f s = %d)" % (tl, e_est, int(2 * e_est)))
    if len(sm.cells("C")) < 2:
        errs.append("pocos puntos de control")
    notes.append("llaves %d · cerraduras %d · gemas %d · nodos %d" % (len(keys), len(doors), len(gems), len(d1)))
    return sm


def main():
    files = sys.argv[1:] or sorted(glob.glob(os.path.join(wc.WORLD_DIR, "ww_*.txt")))
    bad = 0
    for f in files:
        if "@par" not in open(f).read():
            continue
        sm = analyse(f)
        print("%s: %s" % (os.path.basename(f), "OK" if not sm.errors else "ERRORES"))
        for n in sm.notes:
            print("    " + n)
        for e in sm.errors:
            print("    x " + e)
        bad += len(sm.errors)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()

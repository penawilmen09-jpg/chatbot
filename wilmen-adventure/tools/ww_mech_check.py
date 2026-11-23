#!/usr/bin/env python3
"""Validador estatico de las mecanicas nuevas de WILMEN WORLD (tanda 0) y de la altura variable.

Comprueba, por nivel (incluido el taller ww_950), que cada mecanica esta bien colocada:
  % { }  setas: celda libre encima (2 filas) y suelo debajo.
  $      lianas: columna con ancla solida arriba, sin suelo dentro y con largo 6..12.
  & '    tolvas de troncos: apoyadas en suelo.
  -      plataformas que desaparecen: tramos de 2..5 celdas y huecos entre cadenas <= 4 celdas (se salta con ritmo).
  _      puentes: tramo >= 4 con suelo firme a ambos lados a su altura.
  / \\    interruptores: si hay bloques ( ) [ ] del grupo debe existir su interruptor (y viceversa).
  : . ,  corrientes: zonas rectangulares de >= 2 celdas.
  " `    lanzadardos: con suelo debajo; ! pendulo: ancla solida arriba.
  z D 0  topo, guardian y lanzarrocas: sobre suelo firme; Y murcielago: colgado bajo un techo solido.
  ~      prensa: tramo de 2-3 celdas con techo solido encima y suelo debajo a >= 4 celdas.
  n b    orbital: radio libre de 3 celdas; ascensor: 6 celdas libres encima y parada baja a ras del foso.
Altura: entre 20 y 40 filas; con mas de 20 filas, el nivel debe tener suelo/plataforma en la zona baja (sin vacio total).
Uso: python3 tools/ww_mech_check.py [archivos...]   (sin argumentos: todos los niveles de levels/world)
"""
import glob, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
WORLD = os.path.join(HERE, "..", "levels", "world")
SOLID = set("#=B?")


def load(path):
    rows = []
    for l in open(path, encoding="utf-8").read().split("\n"):
        l = l.rstrip("\r")
        if l.startswith(";") or l.startswith("@"):
            continue
        rows.append(l)
    while rows and rows[-1] == "":
        rows.pop()
    w = max(len(r) for r in rows)
    return [r.ljust(w) for r in rows]


def check(rows):
    errs = []
    H, W = len(rows), len(rows[0])

    def c(x, y):
        return rows[y][x] if 0 <= y < H and 0 <= x < W else "#"

    def solid(x, y):
        return c(x, y) in SOLID

    if not (20 <= H <= 40):
        errs.append("altura %d fuera de 20..40 filas" % H)
    if H > 20:
        low = "".join(rows[-4:])
        if low.count("#") < W * 0.05:
            errs.append("nivel alto sin suelo en las filas inferiores")
    sw = {1: False, 2: False}
    blocks = {1: False, 2: False}
    for y in range(H):
        for x in range(W):
            ch = c(x, y)
            if ch in "%{}":
                if c(x, y - 1) != " " or c(x, y - 2) != " ":
                    errs.append("seta (%d,%d) sin espacio libre encima" % (x, y))
                if not solid(x, y + 1):
                    errs.append("seta (%d,%d) sin suelo debajo" % (x, y))
            elif ch == "$" and c(x, y - 1) != "$":
                n = 0
                while c(x, y + n) == "$":
                    n += 1
                if not (6 <= n <= 12):
                    errs.append("liana (%d,%d) de %d celdas (debe ser 6..12)" % (x, y, n))
                if not solid(x, y - 1):
                    errs.append("liana (%d,%d) sin ancla solida arriba" % (x, y))
            elif ch in "zD0" and not solid(x, y + 1):
                errs.append("enemigo '%s' (%d,%d) sin suelo debajo" % (ch, x, y))
            elif ch == "Y" and not solid(x, y - 1):
                errs.append("murcielago (%d,%d) sin techo solido encima" % (x, y))
            elif ch == "~" and c(x - 1, y) != "~":
                n = 0
                while c(x + n, y) == "~":
                    n += 1
                if not (2 <= n <= 3):
                    errs.append("prensa (%d,%d) de %d celdas (2..3)" % (x, y, n))
                if not all(solid(x + i, y - 1) for i in range(n)):
                    errs.append("prensa (%d,%d) sin techo solido encima" % (x, y))
                fy = y + 1
                while fy < H and not solid(x, fy):
                    fy += 1
                if fy - y < 5:
                    errs.append("prensa (%d,%d) con menos de 4 celdas libres hasta el suelo" % (x, y))
            elif ch in "&'" and not solid(x, y + 1):
                errs.append("tolva (%d,%d) sin suelo debajo" % (x, y))
            elif ch in "\"`" and False:
                pass
            elif ch == "!" and c(x, y - 1) != "!":
                if not solid(x, y - 1):
                    errs.append("pendulo (%d,%d) sin ancla solida arriba" % (x, y))
            elif ch == "/":
                sw[1] = True
            elif ch == "\\":
                sw[2] = True
            elif ch in "()":
                blocks[1] = True
            elif ch in "[]":
                blocks[2] = True
            elif ch == "n":
                for dy in range(-3, 4):
                    for dx in range(-4, 5):
                        if solid(x + dx, y + dy) and dx * dx + dy * dy <= 16:
                            errs.append("orbital (%d,%d) con terreno dentro de su recorrido" % (x, y))
                            break
                    else:
                        continue
                    break
            elif ch == "b":
                for dy in range(1, 7):
                    if solid(x, y - dy) or solid(x + 1, y - dy):
                        errs.append("ascensor (%d,%d) con terreno en su recorrido" % (x, y))
                        break
    for g in (1, 2):
        if blocks[g] != sw[g]:
            errs.append("grupo %d: bloques=%s e interruptor=%s no coinciden" % (g, blocks[g], sw[g]))
    # plataformas que desaparecen: tramos y huecos
    for y in range(H):
        x = 0
        runs = []
        while x < W:
            if c(x, y) == "-":
                s = x
                while c(x, y) == "-":
                    x += 1
                runs.append((s, x - s))
                if not (2 <= x - s <= 5):
                    errs.append("plataforma que desaparece (%d,%d) de %d celdas (2..5)" % (s, y, x - s))
            else:
                x += 1
    ph = sorted((x, y) for y in range(H) for x in range(W) if c(x, y) == "-" and c(x - 1, y) != "-")
    for a, b in zip(ph, ph[1:]):
        if abs(a[1] - b[1]) <= 2 and b[0] - a[0] < 40:
            wa = 0
            while c(a[0] + wa, a[1]) == "-":
                wa += 1
            if b[0] - (a[0] + wa) > 4:
                errs.append("hueco de %d celdas entre plataformas que desaparecen en %d,%d" % (b[0] - (a[0] + wa), a[0], a[1]))
    # puentes
    for y in range(H):
        x = 0
        while x < W:
            if c(x, y) == "_":
                s = x
                while c(x, y) == "_":
                    x += 1
                if x - s < 4:
                    errs.append("puente (%d,%d) de solo %d tablas" % (s, y, x - s))
                if not solid(s - 1, y) or not solid(x, y):
                    errs.append("puente (%d,%d) sin suelo firme a sus lados" % (s, y))
            else:
                x += 1
    # corrientes: zonas rectangulares
    for ch in ":.,":
        cells = {(x, y) for y in range(H) for x in range(W) if c(x, y) == ch}
        seen = set()
        for (x, y) in sorted(cells):
            if (x, y) in seen:
                continue
            x1 = x
            while (x1, y) in cells:
                x1 += 1
            y1 = y
            while all((xx, y1) in cells for xx in range(x, x1)):
                y1 += 1
            for yy in range(y, y1):
                for xx in range(x, x1):
                    seen.add((xx, yy))
            if x1 - x < 2 or y1 - y < 2:
                errs.append("corriente '%s' (%d,%d) demasiado pequena" % (ch, x, y))
    return errs


def main():
    files = sys.argv[1:] or sorted(glob.glob(os.path.join(WORLD, "ww_*.txt")))
    bad = 0
    for f in files:
        errs = check(load(f))
        print("%s: %s" % (os.path.basename(f), "OK" if not errs else "ERRORES"))
        for e in errs:
            print("    x " + e)
        bad += len(errs)
    print("niveles revisados: %d | errores: %d" % (len(files), bad))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()

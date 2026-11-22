#!/usr/bin/env python3
"""Diseño del mapa general de WILMEN WORLD: 120 niveles repartidos por 6 regiones (20 por región).

Escribe levels/world/map.json (nodos, caminos, ríos, montañas, regiones) que usan el juego y el generador de arte
(tools/gen_ww_map_art.py). La región 1 (Bosque Esmeralda) está diseñada a mano; las demás usan la misma topología
(14 normales, 2 cuevas, 1 casa de bonificación, 1 fortaleza, 1 nivel con ruta secreta y 1 castillo) con otra forma
sobre su propio territorio, y quedan «en construcción» hasta su etapa.

Uso: python3 tools/ww_map.py [--check] [--preview salida.png]
"""
import json, math, os, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "levels", "world", "map.json")
W, H = 2400, 1350

REGIONS = [
    {"id": 1, "name": "Bosque Esmeralda", "status": "playable", "box": [60, 740, 880, 1300], "theme": 1},
    {"id": 2, "name": "Desierto Dorado", "status": "construction", "box": [950, 880, 1560, 1310], "theme": 3},
    {"id": 3, "name": "Reino Volcánico", "status": "construction", "box": [1640, 840, 2340, 1290], "theme": 7},
    {"id": 4, "name": "Reino Congelado", "status": "construction", "box": [1700, 60, 2340, 700], "theme": 4},
    {"id": 5, "name": "Océano Perdido", "status": "construction", "box": [860, 220, 1600, 760], "theme": 6},
    {"id": 6, "name": "Reino de las Sombras", "status": "construction", "box": [60, 60, 780, 640], "theme": 5},
]

# tipo de cada nivel de una región (índice local 1..20). house/secret: la casa 7 está oculta hasta descubrir su camino secreto
KINDS = {1: "dot", 2: "dot", 3: "dot", 4: "cave", 5: "dot", 6: "dot", 7: "house", 8: "dot", 9: "dot", 10: "fortress",
         11: "dot", 12: "dot", 13: "cave", 14: "dot", 15: "dot", 16: "dot", 17: "dot", 18: "dot", 19: "dot", 20: "castle"}
HIDDEN = {7}
# posiciones de la región 1 (unidades normalizadas 0..1 dentro de su caja): serpentina sur -> norte -> este
TEMPLATE = {
    1: (0.03, 0.90), 2: (0.14, 0.78), 3: (0.28, 0.88), 4: (0.36, 0.98), 5: (0.40, 0.70), 6: (0.52, 0.86),
    7: (0.50, 0.52), 8: (0.66, 0.96), 9: (0.80, 0.84), 10: (0.95, 0.72), 11: (0.84, 0.58), 12: (0.70, 0.50),
    13: (0.54, 0.38), 14: (0.78, 0.34), 15: (0.38, 0.28), 16: (0.24, 0.14), 17: (0.40, 0.05), 18: (0.58, 0.14),
    19: (0.76, 0.12), 20: (0.96, 0.22),
}
# (a, b, condición, clase): condición = ("done", n) | ("secret", n); clase: path | bridge | tunnel
TOPOLOGY = [
    (1, 2, ("done", 1), "path"), (2, 3, ("done", 2), "path"), (3, 4, ("done", 3), "path"), (3, 5, ("done", 3), "path"),
    (4, 6, ("done", 4), "path"), (5, 6, ("done", 5), "path"), (5, 7, ("secret", 5), "path"), (6, 8, ("done", 6), "path"),
    (8, 9, ("done", 8), "path"), (9, 10, ("done", 9), "path"), (10, 11, ("done", 10), "path"), (11, 12, ("done", 11), "path"),
    (12, 13, ("done", 12), "path"), (12, 14, ("done", 12), "path"), (13, 15, ("done", 13), "path"), (14, 15, ("done", 14), "path"),
    (15, 16, ("done", 15), "path"), (16, 17, ("done", 16), "path"), (17, 18, ("done", 17), "path"), (18, 19, ("done", 18), "path"),
    (19, 20, ("done", 19), "path"),
    (9, 15, ("secret", 9), "tunnel"), (13, 19, ("secret", 13), "tunnel"),
]
# transformaciones de la plantilla por región (giro/espejo) para que cada territorio tenga otra forma
TRANSFORMS = {1: (False, False), 2: (False, True), 3: (False, False), 4: (True, False), 5: (True, True), 6: (True, False)}

# ríos y montañas (coordenadas del mundo). Los caminos que cruzan un río llevan puente.
RIVERS = [
    [(578, 1330), (560, 1240), (590, 1150), (566, 1060)],
    [(250, 1010), (330, 960), (440, 990), (540, 940), (640, 970), (720, 930), (870, 960)],
    [(1180, 1330), (1210, 1220), (1170, 1120), (1200, 1000)],
    [(2020, 1330), (1990, 1200), (2040, 1090), (2010, 960)],
    [(1950, 90), (1990, 260), (1940, 420), (1990, 560)],
]
MOUNTAINS = [  # (x, y, ancho, alto, región)
    (470, 800, 130, 80, 1), (560, 780, 150, 100, 1), (680, 820, 110, 70, 1), (340, 770, 120, 70, 1),
    (1050, 960, 120, 70, 2), (1350, 1000, 140, 90, 2),
    (1800, 900, 170, 110, 3), (2150, 960, 150, 100, 3), (1950, 1000, 120, 70, 3),
    (1900, 300, 170, 120, 4), (2150, 200, 150, 110, 4), (2100, 520, 140, 90, 4),
    (240, 200, 170, 110, 6), (520, 330, 150, 100, 6), (400, 540, 130, 80, 6),
]


def node_id(region, idx):
    return (region - 1) * 20 + idx


def place(region):
    r = REGIONS[region - 1]
    x0, y0, x1, y1 = r["box"]
    fx, fy = TRANSFORMS[region]
    pos = {}
    for i in range(1, 21):
        u, v = TEMPLATE[i]
        if fx:
            u = 1 - u
        if fy:
            v = 1 - v
        pos[i] = (round(x0 + u * (x1 - x0)), round(y0 + v * (y1 - y0)))
    return pos


def curve(a, b, seed):
    """Camino ligeramente curvo entre dos puntos (polilínea)."""
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    ln = math.hypot(dx, dy) or 1.0
    nx, ny = -dy / ln, dx / ln
    off = (((seed * 37) % 11) - 5) * 0.012 * ln
    pts = []
    n = max(4, int(ln / 22))
    for k in range(n + 1):
        t = k / n
        bend = math.sin(math.pi * t) * off
        pts.append((round(ax + dx * t + nx * bend), round(ay + dy * t + ny * bend)))
    return pts


def seg_inter(p1, p2, p3, p4):
    d = (p2[0] - p1[0]) * (p4[1] - p3[1]) - (p2[1] - p1[1]) * (p4[0] - p3[0])
    if abs(d) < 1e-9:
        return None
    t = ((p3[0] - p1[0]) * (p4[1] - p3[1]) - (p3[1] - p1[1]) * (p4[0] - p3[0])) / d
    u = ((p3[0] - p1[0]) * (p2[1] - p1[1]) - (p3[1] - p1[1]) * (p2[0] - p1[0])) / d
    if 0 <= t <= 1 and 0 <= u <= 1:
        return (p1[0] + t * (p2[0] - p1[0]), p1[1] + t * (p2[1] - p1[1]), math.atan2(p2[1] - p1[1], p2[0] - p1[0]))
    return None


def build():
    nodes, edges, bridges = [], [], []
    for r in REGIONS:
        pos = place(r["id"])
        for i in range(1, 21):
            nodes.append({"id": node_id(r["id"], i), "region": r["id"], "idx": i, "kind": KINDS[i], "pos": list(pos[i]),
                          "hidden": i in HIDDEN})
    byid = {n["id"]: n for n in nodes}
    for r in REGIONS:
        for k, (a, b, cond, cls) in enumerate(TOPOLOGY):
            na, nb = byid[node_id(r["id"], a)], byid[node_id(r["id"], b)]
            pts = curve(tuple(na["pos"]), tuple(nb["pos"]), na["id"] * 7 + k)
            edges.append({"a": na["id"], "b": nb["id"], "kind": cls, "need": {"type": cond[0], "node": node_id(r["id"], cond[1])},
                          "path": [list(p) for p in pts]})
    # conexiones entre regiones: castillo de la región r -> primer nivel de la siguiente
    LINKS = [(1, 2), (2, 3), (3, 4), (4, 5), (5, 6)]
    for (ra, rb) in LINKS:
        na, nb = byid[node_id(ra, 20)], byid[node_id(rb, 1)]
        pts = curve(tuple(na["pos"]), tuple(nb["pos"]), ra * 13)
        edges.append({"a": na["id"], "b": nb["id"], "kind": "bridge",
                      "need": {"type": "done", "node": na["id"]}, "path": [list(p) for p in pts], "region_link": True})
    # túnel sellado de la región 1 (se descubre con la salida secreta del 1-19): lleva a una región aún en construcción
    sealed_pos = (byid[19]["pos"][0] + 40, byid[19]["pos"][1] - 70) if False else (byid[node_id(1, 19)]["pos"][0] + 20, byid[node_id(1, 19)]["pos"][1] - 62)
    nodes.append({"id": 901, "region": 1, "idx": 0, "kind": "sealed", "pos": [sealed_pos[0], sealed_pos[1]], "hidden": True})
    edges.append({"a": node_id(1, 19), "b": 901, "kind": "tunnel", "need": {"type": "secret", "node": node_id(1, 19)},
                  "path": [list(p) for p in curve(tuple(byid[node_id(1, 19)]["pos"]), sealed_pos, 5)]})
    # puentes: cruces de caminos y ríos
    for e in edges:
        pts = e["path"]
        for i in range(len(pts) - 1):
            for rv in RIVERS:
                for j in range(len(rv) - 1):
                    hit = seg_inter(pts[i], pts[i + 1], rv[j], rv[j + 1])
                    if hit and e["kind"] != "tunnel":
                        bridges.append({"x": round(hit[0]), "y": round(hit[1]), "angle": round(hit[2], 3), "edge": [e["a"], e["b"]]})
                        e["kind"] = "bridge" if e["kind"] == "path" else e["kind"]
    return {"world": [W, H], "start": 1, "regions": REGIONS, "nodes": nodes, "edges": edges, "rivers": RIVERS,
            "mountains": [list(m) for m in MOUNTAINS], "bridges": bridges}


def check(d):
    errs = []
    ids = [n["id"] for n in d["nodes"] if n["id"] < 900]
    if sorted(ids) != list(range(1, 121)):
        errs.append("deben existir los 120 niveles (1..120)")
    for r in d["regions"]:
        k = [n for n in d["nodes"] if n["region"] == r["id"] and n["id"] < 900]
        if len(k) != 20:
            errs.append("la región %d no tiene 20 niveles" % r["id"])
        kinds = {}
        for n in k:
            kinds[n["kind"]] = kinds.get(n["kind"], 0) + 1
        if kinds != {"dot": 15, "cave": 2, "house": 1, "fortress": 1, "castle": 1}:
            errs.append("distribución de la región %d: %s" % (r["id"], kinds))
    byid = {n["id"]: n for n in d["nodes"]}
    # solapes
    for i, a in enumerate(d["nodes"]):
        for b in d["nodes"][i + 1:]:
            if math.dist(a["pos"], b["pos"]) < 34:
                errs.append("nodos demasiado juntos: %s y %s" % (a["id"], b["id"]))
    # simulación: completar todo lo alcanzable desde el inicio recorre la región 1 y los secretos aparecen
    done, secret = set(), set()
    reach = {d["start"]}
    changed = True
    while changed:
        changed = False
        for e in d["edges"]:
            need = e["need"]
            ok = (need["type"] == "done" and need["node"] in done) or (need["type"] == "secret" and need["node"] in secret)
            if ok:
                for t in (e["a"], e["b"]):
                    if t not in reach:
                        reach.add(t)
                        changed = True
        for n in list(reach):
            nd = byid[n]
            if nd["region"] == 1 and nd["kind"] != "sealed" and n not in done:
                done.add(n)
                secret.add(n)  # el nivel puede tener salida secreta: se supone completada
                changed = True
    r1 = {n["id"] for n in d["nodes"] if n["region"] == 1 and n["id"] < 900}
    if not r1 <= reach:
        errs.append("región 1: nodos inalcanzables %s" % sorted(r1 - reach))
    return errs


def preview(d, path):
    from PIL import Image, ImageDraw
    S = 0.5
    im = Image.new("RGB", (int(W * S), int(H * S)), (30, 60, 110))
    dr = ImageDraw.Draw(im)
    for r in d["regions"]:
        x0, y0, x1, y1 = r["box"]
        dr.rectangle([x0 * S, y0 * S, x1 * S, y1 * S], fill=(60, 110, 60) if r["status"] == "playable" else (80, 80, 90))
    for rv in d["rivers"]:
        dr.line([(x * S, y * S) for x, y in rv], fill=(80, 160, 255), width=4)
    for m in d["mountains"]:
        dr.polygon([(m[0] * S, (m[1] + m[3]) * S), ((m[0] + m[2] / 2) * S, m[1] * S), ((m[0] + m[2]) * S, (m[1] + m[3]) * S)], fill=(130, 120, 110))
    for e in d["edges"]:
        col = (255, 220, 120) if e["kind"] == "path" else ((120, 200, 255) if e["kind"] == "bridge" else (255, 120, 255))
        dr.line([(x * S, y * S) for x, y in e["path"]], fill=col, width=2)
    for b in d["bridges"]:
        dr.ellipse([b["x"] * S - 4, b["y"] * S - 4, b["x"] * S + 4, b["y"] * S + 4], outline=(255, 255, 255))
    colors = {"dot": (255, 255, 255), "cave": (150, 100, 60), "house": (255, 160, 80), "fortress": (200, 60, 60), "castle": (220, 40, 220), "sealed": (60, 60, 60)}
    for n in d["nodes"]:
        x, y = n["pos"]
        dr.ellipse([x * S - 5, y * S - 5, x * S + 5, y * S + 5], fill=colors[n["kind"]], outline=(0, 0, 0))
        if n["region"] == 1 and n["id"] < 900:
            dr.text((x * S + 6, y * S - 4), str(n["id"]), fill=(255, 255, 255))
    im.save(path)


def main():
    d = build()
    errs = check(d)
    for e in errs:
        print("✗", e)
    if "--preview" in sys.argv:
        preview(d, sys.argv[sys.argv.index("--preview") + 1])
    if "--check" in sys.argv:
        print("mapa: %d nodos, %d caminos, %d puentes, errores: %d" % (len(d["nodes"]), len(d["edges"]), len(d["bridges"]), len(errs)))
        sys.exit(1 if errs else 0)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(d, open(OUT, "w"), separators=(",", ":"))
    print("escrito", OUT, "(%d nodos, %d caminos, %d puentes)" % (len(d["nodes"]), len(d["edges"]), len(d["bridges"])))
    if errs:
        sys.exit(1)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Arte original del mapa de WILMEN WORLD (todo procedural con Pillow, semilla fija):
  assets/ww_map/terrain.png  mundo de 2400x1350: océano, 6 regiones con su paisaje, ríos, montañas y atrezo
  assets/ww_map/icons.png    iconos de 32x32: tipos de entrada (punto, casa, cueva, fortaleza, castillo, túnel sellado),
                              insignias (candado, bandera, cartel de obras, destello, estrella), puente y boca de túnel
Lee levels/world/map.json (tools/ww_map.py) para no poner nada encima de los caminos. Uso: python3 tools/gen_ww_map_art.py
"""
import json, math, os, random
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "assets", "ww_map")
OL = (26, 18, 38, 255)
rnd = random.Random(20261122)


def dk(c, f=0.6):
    return (int(c[0] * f), int(c[1] * f), int(c[2] * f), 255)


def lt(c, f=0.35):
    return (int(c[0] + (255 - c[0]) * f), int(c[1] + (255 - c[1]) * f), int(c[2] + (255 - c[2]) * f), 255)


PAL = {
    1: ((88, 172, 74, 255), (70, 150, 62, 255)),     # bosque: hierba
    2: ((232, 196, 120, 255), (216, 176, 100, 255)),  # desierto: arena
    3: ((74, 54, 56, 255), (92, 66, 62, 255)),       # volcán: roca negra
    4: ((232, 240, 250, 255), (206, 224, 242, 255)),  # hielo: nieve
    5: ((226, 206, 150, 255), (110, 190, 120, 255)),  # océano: arena e islas
    6: ((62, 48, 88, 255), (50, 38, 72, 255)),       # sombras: tierra violeta
}


def blob_mask(box, seed, pad=0):
    """Máscara de tierra con costa irregular: elipses solapadas dentro de la caja."""
    r = random.Random(seed)
    m = Image.new("L", (2400, 1350), 0)
    d = ImageDraw.Draw(m)
    x0, y0, x1, y1 = box
    x0 -= pad
    y0 -= pad
    x1 += pad
    y1 += pad
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    d.rounded_rectangle([x0 + 40, y0 + 40, x1 - 40, y1 - 40], radius=70, fill=255)
    for _ in range(70):
        ex = r.uniform(x0, x1)
        ey = r.uniform(y0, y1)
        rx, ry = r.uniform(26, 70), r.uniform(26, 70)
        # más cerca del borde -> costa; el interior queda lleno
        d.ellipse([ex - rx, ey - ry, ex + rx, ey + ry], fill=255)
    # recorta lo que se sale de la caja ampliada
    cl = Image.new("L", m.size, 0)
    ImageDraw.Draw(cl).rectangle([x0 - 20, y0 - 20, x1 + 20, y1 + 20], fill=255)
    return ImageChops.multiply(m, cl)


def corridor(d, data, extra=30):
    """Lista de puntos (nodos y caminos) donde no se coloca atrezo."""
    pts = []
    for n in data["nodes"]:
        pts.append(tuple(n["pos"]))
    for e in data["edges"]:
        pts.extend(tuple(p) for p in e["path"])
    return pts


def far_from(pts, x, y, dist):
    for (px, py) in pts:
        if abs(px - x) < dist and abs(py - y) < dist and math.hypot(px - x, py - y) < dist:
            return False
    return True


# ------------------------------------------------------------------- atrezo ---
def tree(d, x, y, kind, big=1.0):
    s = big
    if kind == "oak":
        d.rectangle([x - 2, y - 4, x + 2, y + 4], fill=(110, 74, 44, 255))
        d.ellipse([x - 12 * s, y - 24 * s, x + 12 * s, y - 2 * s], fill=OL)
        d.ellipse([x - 11 * s, y - 23 * s, x + 11 * s, y - 3 * s], fill=(52, 130, 60, 255))
        d.ellipse([x - 8 * s, y - 21 * s, x + 2 * s, y - 11 * s], fill=(86, 176, 78, 255))
    elif kind == "pine":
        d.rectangle([x - 1.5, y - 3, x + 1.5, y + 4], fill=(100, 70, 44, 255))
        for i, (w, off) in enumerate(((13, 0), (10, -9), (7, -17))):
            d.polygon([(x - w * s, y + off - 3), (x, y + off - 15 * s), (x + w * s, y + off - 3)], fill=OL)
            d.polygon([(x - (w - 1.5) * s, y + off - 4), (x, y + off - 13 * s), (x + (w - 1.5) * s, y + off - 4)], fill=(40, 110, 70, 255))
    elif kind == "snowpine":
        d.rectangle([x - 1.5, y - 3, x + 1.5, y + 4], fill=(90, 70, 60, 255))
        for (w, off) in ((13, 0), (10, -9), (7, -17)):
            d.polygon([(x - w * s, y + off - 3), (x, y + off - 15 * s), (x + w * s, y + off - 3)], fill=(60, 90, 120, 255))
            d.polygon([(x - (w - 3) * s, y + off - 6), (x, y + off - 15 * s), (x + (w - 3) * s, y + off - 6)], fill=(245, 250, 255, 255))
    elif kind == "dead":
        d.line([x, y + 4, x, y - 18 * s], fill=(30, 22, 44, 255), width=3)
        d.line([x, y - 10 * s, x - 9 * s, y - 20 * s], fill=(30, 22, 44, 255), width=2)
        d.line([x, y - 14 * s, x + 8 * s, y - 22 * s], fill=(30, 22, 44, 255), width=2)
    elif kind == "palm":
        d.line([x, y + 4, x + 2, y - 16 * s], fill=(130, 90, 50, 255), width=3)
        for a in (-0.9, -0.3, 0.3, 0.9, 2.2, 2.8):
            d.line([x + 2, y - 16 * s, x + 2 + math.cos(a) * 12 * s, y - 16 * s - math.sin(abs(a)) * 6 * s + 4], fill=(40, 150, 70, 255), width=3)
    elif kind == "cactus":
        d.rounded_rectangle([x - 3, y - 20 * s, x + 3, y + 3], radius=3, fill=OL)
        d.rounded_rectangle([x - 2, y - 19 * s, x + 2, y + 2], radius=2, fill=(70, 150, 80, 255))
        d.rounded_rectangle([x - 9, y - 12 * s, x - 4, y - 8 * s], radius=2, fill=(70, 150, 80, 255))
        d.rectangle([x - 9, y - 12 * s, x - 7, y - 3], fill=(70, 150, 80, 255))
        d.rounded_rectangle([x + 4, y - 15 * s, x + 9, y - 11 * s], radius=2, fill=(70, 150, 80, 255))
        d.rectangle([x + 7, y - 15 * s, x + 9, y - 6], fill=(70, 150, 80, 255))
    elif kind == "bush":
        d.ellipse([x - 8, y - 8, x + 8, y + 3], fill=OL)
        d.ellipse([x - 7, y - 7, x + 7, y + 2], fill=(60, 140, 70, 255))
        d.ellipse([x - 4, y - 6, x + 1, y - 2], fill=(100, 190, 90, 255))
    elif kind == "rock":
        d.polygon([(x - 9, y + 2), (x - 5, y - 7), (x + 3, y - 9), (x + 9, y + 2)], fill=OL)
        d.polygon([(x - 7, y + 1), (x - 4, y - 5), (x + 3, y - 7), (x + 7, y + 1)], fill=(120, 116, 128, 255))
    elif kind == "lava":
        d.ellipse([x - 14, y - 6, x + 14, y + 6], fill=(40, 20, 20, 255))
        d.ellipse([x - 12, y - 5, x + 12, y + 5], fill=(255, 110, 30, 255))
        d.ellipse([x - 7, y - 3, x + 5, y + 2], fill=(255, 210, 90, 255))
    elif kind == "dune":
        d.arc([x - 22, y - 8, x + 22, y + 14], 200, 340, fill=(190, 150, 80, 255), width=2)
    elif kind == "grave":
        d.rounded_rectangle([x - 5, y - 14, x + 5, y + 2], radius=4, fill=OL)
        d.rounded_rectangle([x - 4, y - 13, x + 4, y + 1], radius=3, fill=(120, 110, 150, 255))
        d.line([x, y - 10, x, y - 4], fill=OL)
        d.line([x - 2, y - 8, x + 2, y - 8], fill=OL)
    elif kind == "ice":
        d.polygon([(x - 6, y + 3), (x - 2, y - 14), (x + 2, y - 6), (x + 6, y + 3)], fill=(120, 170, 215, 255))
        d.polygon([(x - 3, y + 2), (x - 1, y - 10), (x + 1, y - 5), (x + 3, y + 2)], fill=(205, 235, 255, 255))
    elif kind == "flower":
        c = rnd.choice([(255, 120, 150, 255), (255, 230, 90, 255), (255, 255, 255, 255), (170, 130, 255, 255)])
        d.point((x, y), fill=c)
        d.point((x + 1, y), fill=c)
        d.point((x, y - 1), fill=c)


def mountain(d, x, y, w, h, region):
    base = {1: (128, 120, 112), 2: (190, 120, 80), 3: (74, 62, 70), 4: (150, 190, 230), 5: (130, 120, 112), 6: (84, 70, 112)}[region]
    base = base + (255,)
    peak = (x + w * 0.5, y)
    d.polygon([(x - 2, y + h), peak, (x + w + 2, y + h)], fill=OL)
    d.polygon([(x, y + h - 1), (peak[0], y + 3), (x + w, y + h - 1)], fill=base)
    d.polygon([(peak[0], y + 3), (x + w, y + h - 1), (peak[0] + 4, y + h - 1), (peak[0] + w * 0.12, y + h * 0.5)], fill=dk(base, 0.78))
    cap = (245, 250, 255, 255) if region in (1, 4, 6, 5) else ((255, 140, 50, 255) if region == 3 else (240, 210, 160, 255))
    d.polygon([(peak[0], y + 3), (peak[0] - w * 0.16, y + h * 0.32), (peak[0] - w * 0.05, y + h * 0.26), (peak[0] + w * 0.03, y + h * 0.34), (peak[0] + w * 0.16, y + h * 0.3)], fill=cap)


def river(d, pts, width=16):
    for w, col in ((width + 6, (54, 108, 70, 255)), (width, (66, 150, 235, 255)), (width - 8, (120, 196, 255, 255))):
        d.line(pts, fill=col, width=w, joint="curve")
        for (x, y) in pts:
            d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=col)


def draw_terrain(data):
    W, H = data["world"]
    img = Image.new("RGBA", (W, H), (38, 98, 170, 255))
    d = ImageDraw.Draw(img)
    # océano con olas
    for _ in range(2600):
        x, y = rnd.randint(0, W - 1), rnd.randint(0, H - 1)
        d.line([x, y, x + rnd.randint(6, 16), y], fill=(70, 130, 200, 255))
    # tierra de cada región
    land_all = Image.new("L", (W, H), 0)
    for r in data["regions"]:
        m = blob_mask(r["box"], 100 + r["id"])
        if r["id"] == 5:
            # archipiélago: una isla alrededor de cada nivel y de los puentes
            m = Image.new("L", (W, H), 0)
            md = ImageDraw.Draw(m)
            for n in data["nodes"]:
                if n["region"] == 5:
                    x, y = n["pos"]
                    rr = rnd.randint(46, 70)
                    md.ellipse([x - rr * 1.3, y - rr, x + rr * 1.3, y + rr], fill=255)
                    for _ in range(3):
                        ox, oy = rnd.randint(-60, 60), rnd.randint(-40, 40)
                        md.ellipse([x + ox - 30, y + oy - 22, x + ox + 30, y + oy + 22], fill=255)
            for e in data["edges"]:
                if data["nodes"][[n["id"] for n in data["nodes"]].index(e["a"])]["region"] == 5 and data["nodes"][[n["id"] for n in data["nodes"]].index(e["b"])]["region"] == 5 and e["kind"] != "tunnel":
                    for (x, y) in e["path"]:
                        md.ellipse([x - 22, y - 22, x + 22, y + 22], fill=255)
        land_all = ImageChops.lighter(land_all, m)
        base, alt = PAL[r["id"]]
        tex = Image.new("RGBA", (W, H), base)
        td = ImageDraw.Draw(tex)
        for _ in range(9000):
            x, y = rnd.randint(0, W - 1), rnd.randint(0, H - 1)
            if m.getpixel((x, y)) > 0:
                td.rectangle([x, y, x + rnd.randint(1, 3), y + 1], fill=alt)
        if r["id"] == 5:
            for _ in range(600):
                x, y = rnd.randint(0, W - 1), rnd.randint(0, H - 1)
                if m.getpixel((x, y)) > 0:
                    td.ellipse([x - 8, y - 5, x + 8, y + 5], fill=PAL[5][1])
        # costa: borde oscuro y playa clara
        edge = ImageChops.subtract(m.filter(ImageFilter.MaxFilter(9)), m)
        img.paste((20, 70, 110, 255), mask=edge)
        beach = ImageChops.subtract(m, m.filter(ImageFilter.MinFilter(7)))
        img.paste(tex, mask=m)
        img.paste(lt(base, 0.25), mask=beach)
    d = ImageDraw.Draw(img)
    # ríos
    for rv in data["rivers"]:
        river(d, [tuple(p) for p in rv])
    # lagos decorativos
    for (x, y, rr) in ((1010, 1040, 40), (2260, 1040, 36), (2220, 330, 48), (150, 420, 44)):
        d.ellipse([x - rr * 1.4, y - rr, x + rr * 1.4, y + rr], fill=(54, 108, 70, 255) if x < 1000 else (54, 80, 120, 255))
        d.ellipse([x - rr * 1.3, y - rr + 4, x + rr * 1.3, y + rr - 4], fill=(100, 180, 250, 255) if y < 800 or x > 2000 else (66, 150, 235, 255))
    # montañas
    for (x, y, w, h, rg) in data["mountains"]:
        mountain(d, x, y, w, h, rg)
    # atrezo
    free = corridor(d, data)
    mt_boxes = [(m[0] - 20, m[1] - 20, m[0] + m[2] + 20, m[1] + m[3] + 20) for m in data["mountains"]]

    def ok(x, y, dist=26):
        if m_inside(x, y):
            return False
        return far_from(free, x, y, dist)

    def m_inside(x, y):
        for (a, b, c, e) in mt_boxes:
            if a < x < c and b < y < e:
                return True
        return False

    def land_ok(x, y):
        return 0 <= x < W and 0 <= y < H and land_all.getpixel((x, y)) > 0 and not river_near(x, y)

    def river_near(x, y):
        for rv in data["rivers"]:
            for (px, py) in rv:
                if math.hypot(px - x, py - y) < 26:
                    return True
        return False

    scatter = {1: (("oak", 160), ("pine", 90), ("bush", 130), ("flower", 400), ("rock", 20)),
               2: (("cactus", 90), ("dune", 140), ("rock", 40), ("palm", 24)),
               3: (("lava", 40), ("rock", 80), ("dead", 30)),
               4: (("snowpine", 150), ("ice", 80), ("rock", 20)),
               5: (("palm", 40), ("bush", 30), ("rock", 20)),
               6: (("dead", 110), ("grave", 70), ("rock", 40))}
    pts = []
    for r in data["regions"]:
        x0, y0, x1, y1 = r["box"]
        for kind, n in scatter[r["id"]]:
            for _ in range(n * 3):
                x, y = rnd.randint(x0, x1), rnd.randint(y0, y1)
                if land_ok(x, y) and ok(x, y, 18 if kind in ("flower", "dune") else 30):
                    pts.append((y, x, kind))
                    n -= 1
                    if n <= 0:
                        break
    for (y, x, kind) in sorted(pts):  # de atrás hacia delante
        tree(d, x, y, kind, big=rnd.choice([0.9, 1.0, 1.1]))
    # volcán y pirámide como puntos de referencia
    x, y = 2040, 1030
    d.polygon([(x - 90, y + 50), (x - 24, y - 70), (x + 24, y - 70), (x + 90, y + 50)], fill=OL)
    d.polygon([(x - 84, y + 48), (x - 20, y - 64), (x + 20, y - 64), (x + 84, y + 48)], fill=(68, 56, 62, 255))
    d.ellipse([x - 22, y - 76, x + 22, y - 62], fill=(255, 120, 30, 255))
    for k in range(5):
        d.ellipse([x - 8 + k * 4, y - 100 - k * 14, x + 10 + k * 4, y - 84 - k * 14], fill=(90, 80, 90, 190))
    x, y = 1240, 1180
    d.polygon([(x - 60, y + 30), (x, y - 50), (x + 60, y + 30)], fill=OL)
    d.polygon([(x - 56, y + 28), (x, y - 44), (x + 56, y + 28)], fill=(224, 180, 100, 255))
    d.polygon([(x, y - 44), (x + 56, y + 28), (x + 22, y + 28)], fill=(190, 146, 80, 255))
    return img


# ------------------------------------------------------------------- iconos ---
def icon(f):
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    f(ImageDraw.Draw(im))
    return im


def ic_dot(d):
    d.ellipse([4, 6, 28, 30], fill=OL)
    d.ellipse([6, 8, 26, 28], fill=(250, 210, 70, 255))
    d.ellipse([9, 11, 23, 25], fill=(255, 240, 150, 255))
    d.ellipse([13, 14, 19, 20], fill=(250, 190, 40, 255))


def ic_house(d):
    d.rectangle([6, 14, 26, 29], fill=OL)
    d.rectangle([8, 16, 24, 28], fill=(236, 190, 130, 255))
    d.polygon([(3, 15), (16, 3), (29, 15)], fill=OL)
    d.polygon([(6, 14), (16, 6), (26, 14)], fill=(210, 70, 60, 255))
    d.rectangle([14, 20, 19, 28], fill=OL)
    d.rectangle([15, 21, 18, 28], fill=(120, 80, 50, 255))
    d.rectangle([9, 18, 12, 21], fill=(150, 210, 255, 255))
    d.rectangle([21, 5, 23, 10], fill=OL)


def ic_cave(d):
    d.polygon([(2, 30), (6, 12), (16, 4), (26, 12), (30, 30)], fill=OL)
    d.polygon([(4, 29), (8, 13), (16, 6), (24, 13), (28, 29)], fill=(150, 130, 120, 255))
    d.ellipse([10, 14, 22, 32], fill=OL)
    d.ellipse([12, 17, 20, 31], fill=(40, 28, 56, 255))
    d.point((15, 22), fill=(255, 220, 120, 255))


def ic_fort(d):
    d.rectangle([4, 12, 28, 29], fill=OL)
    d.rectangle([6, 14, 26, 28], fill=(150, 150, 168, 255))
    for x in (4, 12, 20):
        d.rectangle([x, 6, x + 7, 14], fill=OL)
        d.rectangle([x + 1, 8, x + 6, 14], fill=(170, 170, 188, 255))
    d.rectangle([13, 20, 19, 28], fill=OL)
    d.rectangle([14, 21, 18, 28], fill=(80, 60, 70, 255))
    d.rectangle([8, 17, 10, 20], fill=OL)
    d.rectangle([22, 17, 24, 20], fill=OL)


def ic_castle(d):
    d.rectangle([3, 12, 29, 30], fill=OL)
    d.rectangle([5, 14, 27, 29], fill=(176, 176, 200, 255))
    for x in (2, 22):
        d.rectangle([x, 4, x + 8, 30], fill=OL)
        d.rectangle([x + 1, 6, x + 7, 29], fill=(190, 190, 214, 255))
        d.polygon([(x - 1, 6), (x + 4, -1), (x + 9, 6)], fill=OL)
        d.polygon([(x + 1, 5), (x + 4, 1), (x + 7, 5)], fill=(210, 60, 90, 255))
    d.rectangle([12, 8, 20, 14], fill=OL)
    d.polygon([(11, 9), (16, 2), (21, 9)], fill=OL)
    d.polygon([(13, 8), (16, 4), (19, 8)], fill=(230, 190, 70, 255))
    d.ellipse([12, 18, 20, 32], fill=OL)
    d.rectangle([13, 24, 19, 31], fill=(90, 60, 50, 255))
    d.rectangle([14, 20, 18, 24], fill=(90, 60, 50, 255))


def ic_sealed(d):
    ic_cave(d)
    d.line([8, 18, 24, 30], fill=(255, 210, 60, 255), width=3)
    d.line([24, 18, 8, 30], fill=(255, 210, 60, 255), width=3)


def ic_lock(d):
    d.arc([10, 4, 22, 18], 180, 360, fill=OL, width=4)
    d.rectangle([7, 14, 25, 29], fill=OL)
    d.rectangle([9, 16, 23, 27], fill=(250, 200, 60, 255))
    d.rectangle([15, 19, 17, 24], fill=OL)


def ic_flag(d):
    d.rectangle([9, 3, 11, 30], fill=OL)
    d.polygon([(11, 4), (28, 9), (11, 17)], fill=OL)
    d.polygon([(12, 6), (25, 9), (12, 14)], fill=(70, 220, 110, 255))
    d.ellipse([6, 26, 14, 32], fill=OL)


def ic_sign(d):
    d.rectangle([14, 14, 18, 30], fill=OL)
    d.rectangle([15, 15, 17, 29], fill=(130, 90, 50, 255))
    d.rectangle([4, 3, 28, 17], fill=OL)
    d.rectangle([6, 5, 26, 15], fill=(236, 200, 120, 255))
    d.line([10, 12, 20, 7], fill=OL, width=2)  # martillo
    d.rectangle([18, 6, 23, 9], fill=OL)


def ic_spark(d):
    for (x, y, r) in ((16, 16, 11), (7, 7, 4), (25, 8, 3), (24, 25, 4)):
        d.polygon([(x, y - r), (x + r * 0.28, y - r * 0.28), (x + r, y), (x + r * 0.28, y + r * 0.28), (x, y + r), (x - r * 0.28, y + r * 0.28), (x - r, y), (x - r * 0.28, y - r * 0.28)], fill=(255, 255, 220, 255))


def ic_star(d):
    pts = []
    for k in range(10):
        r = 13 if k % 2 == 0 else 6
        a = -math.pi / 2 + k * math.pi / 5
        pts.append((16 + math.cos(a) * r, 17 + math.sin(a) * r))
    d.polygon(pts, fill=OL)
    pts2 = []
    for k in range(10):
        r = 10 if k % 2 == 0 else 4
        a = -math.pi / 2 + k * math.pi / 5
        pts2.append((16 + math.cos(a) * r, 17 + math.sin(a) * r))
    d.polygon(pts2, fill=(255, 220, 60, 255))


def ic_bridge(d):
    d.rectangle([0, 8, 31, 24], fill=OL)
    d.rectangle([0, 10, 31, 22], fill=(170, 120, 70, 255))
    for x in range(1, 31, 6):
        d.rectangle([x, 10, x + 4, 22], fill=(206, 152, 92, 255))
    d.rectangle([0, 8, 31, 10], fill=(110, 76, 46, 255))
    d.rectangle([0, 22, 31, 24], fill=(110, 76, 46, 255))


def ic_tunnel(d):
    d.rectangle([2, 8, 30, 30], fill=OL)
    d.rectangle([4, 10, 28, 30], fill=(120, 116, 132, 255))
    d.ellipse([6, 12, 26, 38], fill=OL)
    d.ellipse([8, 14, 24, 36], fill=(30, 22, 50, 255))
    d.rectangle([2, 6, 30, 10], fill=OL)
    d.rectangle([3, 7, 29, 9], fill=(150, 146, 162, 255))


ICONS = [ic_dot, ic_house, ic_cave, ic_fort, ic_castle, ic_sealed, ic_lock, ic_flag, ic_sign, ic_spark, ic_star, ic_bridge, ic_tunnel]


def main():
    data = json.load(open(os.path.join(ROOT, "levels", "world", "map.json")))
    os.makedirs(OUT, exist_ok=True)
    draw_terrain(data).convert("RGB").save(os.path.join(OUT, "terrain.png"), optimize=True)
    sheet = Image.new("RGBA", (32 * len(ICONS), 32), (0, 0, 0, 0))
    for i, f in enumerate(ICONS):
        sheet.paste(icon(f), (i * 32, 0))
    sheet.save(os.path.join(OUT, "icons.png"))
    print("terrain.png (%d KB) e icons.png generados" % (os.path.getsize(os.path.join(OUT, "terrain.png")) // 1024))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Vista previa de los niveles con el ARTE REAL del juego (tiles, atrezo, líquidos, fondos de zona), sin abrir Godot.

Es una composición fiel de los mismos ficheros que usa el motor (no una captura del motor): sirve para revisar
el diseño visual. Para capturas reales del motor hay que ejecutar tests/render_test.gd con pantalla (CI: job render).

  python3 tools/preview_worlds.py mundos salida.png      # 10 mundos, una ventana destacada de cada uno
  python3 tools/preview_worlds.py mundo N salida.png     # 9 niveles de un mundo
  python3 tools/preview_worlds.py nivel N salida.png     # un nivel completo
"""
import os
import statistics
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from worlds_def import PROPS, zone_of  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
A = lambda *p: os.path.join(ROOT, "assets", *p)
_cache = {}


def img(*p):
    k = os.path.join(*p)
    if k not in _cache:
        _cache[k] = Image.open(A(*p)).convert("RGBA")
    return _cache[k]


def read_rows(n):
    rows = [l.rstrip("\n") for l in open(os.path.join(ROOT, "levels", "data", "level_%02d.txt" % n), encoding="utf-8") if not l.startswith(";")]
    while rows and rows[-1] == "":
        rows.pop()
    w = max(len(r) for r in rows)
    rows = [r.ljust(w) for r in rows]
    while len(rows) < 20:
        rows.append(" " * w)
    return rows


def prop_rects(world):
    out, x = [], 0
    for (_n, w, h, fr, anchor) in PROPS[world]:
        out.append((x, w, h, fr, anchor))
        x += w * fr
    return out


def render(n, x0=0, width=480, t=0):
    """Dibuja el nivel n, ventana horizontal [x0, x0+width) px, alineada abajo (270 px de alto)."""
    world = (n - 1) // 10 + 1
    zone = zone_of((n - 1) % 10 + 1)
    rows = read_rows(n)
    cols = len(rows[0])
    H = 270
    canvas = Image.new("RGBA", (width, H))
    far = img("backgrounds", "bg_w%d_z%d_far.png" % (world, zone))
    for rep in range(-1, 3):
        canvas.paste(far.crop((0, 0, 480, 270)), (rep * 480 - int(x0 * 0.04) % 480, 0))
    for nm, fac in (("mid", 0.2), ("near", 0.45)):
        layer = img("backgrounds", "bg_w%d_z%d_%s.png" % (world, zone, nm))
        for rep in range(-1, 3):
            canvas.alpha_composite(layer.crop((0, 0, 480, 270)), (rep * 480 - int(x0 * fac) % 480, 0)) if rep * 480 - int(x0 * fac) % 480 < width else None
    world_img = Image.new("RGBA", (cols * 16, 20 * 16 + 12 * 16))
    tiles = img("tiles", "tiles_w%d.png" % world)
    T = lambda i: tiles.crop((i * 16, 0, i * 16 + 16, 16))
    props = img("decor", "props_w%d.png" % world)
    pr = prop_rects(world)
    en = img("enemies", "enemies_w%d.png" % world)
    items = {k: img("items", k + ".png") for k in ("coin", "gem", "heart", "life", "spring", "goal", "checkpoint")}
    solid = lambda x, y: 0 <= y < 20 and 0 <= x < cols and rows[y][x] in "#><~"
    ph = t % 2
    # pared de fondo de cuevas (columnas con techo pegado arriba)
    for x in range(cols):
        if rows[0][x] == "#":
            y = 0
            while y < 20 and solid(x, y):
                y += 1
            while y < 20 and not solid(x, y):
                world_img.alpha_composite(T(25), (x * 16, y * 16))
                y += 1
    for y in range(20):
        for x in range(cols):
            c = rows[y][x]
            p = (x * 16, y * 16)
            if c.isdigit() and c != "0":
                sx, w, h, fr, anchor = pr[int(c) - 1]
                spr = props.crop((sx + (ph % fr) * w, 0, sx + (ph % fr) * w + w, h))
                py = p[1] if anchor == "h" else p[1] + 16 - h
                world_img.alpha_composite(spr, (p[0] + 8 - w // 2, py))
    for y in range(20):
        for x in range(cols):
            c = rows[y][x]
            p = (x * 16, y * 16)
            if c == "#":
                world_img.alpha_composite(T(0 if not solid(x, y - 1) else (1 + (x * 7 + y * 3) % 2)), p)
            elif c == "=": world_img.alpha_composite(T(3), p)
            elif c == "B": world_img.alpha_composite(T(4), p)
            elif c in "?+": world_img.alpha_composite(T(5), p)
            elif c == "^": world_img.alpha_composite(T(7), p)
            elif c == "L": world_img.alpha_composite(T(8 + ((x + ph) % 2)), p)
            elif c == "~": world_img.alpha_composite(T(17), p)
            elif c in "><": world_img.alpha_composite(T((12 if c == ">" else 14) + ph), p)
    # decorado antiguo 'd'
    dec = img("decor", "decor_w%d.png" % world)
    for y in range(20):
        for x in range(cols):
            if rows[y][x] == "d":
                world_img.alpha_composite(dec, (x * 16 + 8 - 12, y * 16 + 16 - 32))
    # líquidos
    for y in range(20):
        for x in range(cols):
            c = rows[y][x]
            if c == "a":
                above = rows[y - 1][x] if y > 0 else " "
                world_img.alpha_composite(T(20 + ph if above != "a" else 22), (x * 16, y * 16))
            elif c == "|":
                world_img.alpha_composite(T(23 + ((ph + y) % 2)), (x * 16, y * 16))
    for x in range(cols):
        if rows[19][x] == " " and rows[18][x] == " ":
            world_img.alpha_composite(T(20 + ph), (x * 16, 18 * 16))
            world_img.alpha_composite(T(22), (x * 16, 19 * 16))
            for k in range(1, 13):
                world_img.alpha_composite(T(22), (x * 16, (19 + k) * 16))
    # relleno bajo suelos
    for x in range(cols):
        if rows[19][x] == "#":
            for k in range(1, 13):
                world_img.alpha_composite(T(1), (x * 16, (19 + k) * 16))
    hero = img("player", "wilmen.png").crop((0, 0, 24, 24))
    for y in range(20):
        for x in range(cols):
            c = rows[y][x]
            p = (x * 16, y * 16)
            if c == "o": world_img.alpha_composite(items["coin"].crop((0, 0, 16, 16)), p)
            elif c == "*": world_img.alpha_composite(items["gem"].crop((0, 0, 16, 16)), p)
            elif c == "h": world_img.alpha_composite(items["heart"], p)
            elif c == "S": world_img.alpha_composite(items["spring"].crop((0, 0, 16, 16)), p)
            elif c == "C": world_img.alpha_composite(items["checkpoint"].crop((0, 0, 16, 32)), (p[0], p[1] - 16))
            elif c == "F": world_img.alpha_composite(items["goal"].crop((0, 0, 16, 48)), (p[0], p[1] - 32))
            elif c == "P": world_img.alpha_composite(hero, (p[0] - 4, p[1] - 8))
            elif c in "wsjft":
                r = "wsjft".index(c)
                world_img.alpha_composite(en.crop((0, r * 16, 16, r * 16 + 16)), p)
            elif c in "mv":
                world_img.alpha_composite(img("tiles", "mplatform_w%d.png" % world), (p[0], p[1] + 4))
            elif c == "X":
                b = img("bosses", "boss_%d.png" % world)
                world_img.alpha_composite(b.crop((0, 0, 64, 64)), (p[0] - 24, p[1] - 24))
    # ventana alineada abajo
    top = 20 * 16 - H + 20  # deja ver algo de líquido bajo el mapa
    x0 = max(0, min(x0, cols * 16 - width))
    canvas.alpha_composite(world_img.crop((x0, top, x0 + width, top + H)))
    return canvas.convert("RGB")


def best_window(world, width=480):
    """Ventana más interesante del mundo: desniveles, agua/cascadas y atrezo variado."""
    best = None
    for i in range(2, 10):
        n = (world - 1) * 10 + i
        rows = read_rows(n)
        cols = len(rows[0])
        prof = []
        for x in range(cols):
            ys = [y for y in range(19, 2, -1) if rows[y][x] == "#" and rows[y - 1][x] != "#"]
            prof.append(ys[0] if ys else 20)
        for x0 in range(20, cols - 30, 10):
            seg = prof[x0:x0 + 30]
            chars = "".join(rows[y][x0:x0 + 30] for y in range(20))
            score = statistics.pstdev(seg) * 2 + 3 * (chars.count("a") + chars.count("|") > 2) + len(set(c for c in chars if c.isdigit())) * 0.6
            score += 1.5 * (chars.count("=") > 3) + 0.05 * chars.count("o")
            if best is None or score > best[0]:
                best = (score, n, x0 * 16)
    return best[1], best[2]


def main():
    mode = sys.argv[1]
    if mode == "mundos":
        out = sys.argv[2]
        W, H = 480, 270
        sheet = Image.new("RGB", (W * 2 + 6, (H + 6) * 5), (20, 20, 28))
        for w in range(1, 11):
            n, x0 = best_window(w)
            im = render(n, x0)
            sheet.paste(im, (((w - 1) % 2) * (W + 6), ((w - 1) // 2) * (H + 6)))
            print("mundo %d: nivel %d desde x=%d px" % (w, n, x0))
        sheet.save(out)
    elif mode == "mundo":
        w = int(sys.argv[2])
        out = sys.argv[3]
        W, H = 480, 270
        sheet = Image.new("RGB", (W * 3 + 12, (H + 6) * 3), (20, 20, 28))
        for i in range(1, 10):
            n = (w - 1) * 10 + i
            rows = read_rows(n)
            x0 = max(0, (len(rows[0]) * 16) // 2 - 240)
            sheet.paste(render(n, x0), (((i - 1) % 3) * (W + 6), ((i - 1) // 3) * (H + 6)))
        sheet.save(out)
    else:
        n = int(sys.argv[2])
        out = sys.argv[3]
        cols = len(read_rows(n)[0])
        render(n, 0, cols * 16).save(out)


if __name__ == "__main__":
    main()

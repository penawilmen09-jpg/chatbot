#!/usr/bin/env python3
"""Arte del menú principal (todo procedural con Pillow): cielo, montañas, acantilado con castillo y cascadas, árbol,
logo en 3D, botones de colores (9 porciones), iconos, botones redondos y barra de madera.

Salida: assets/menu/*.png   Uso: python3 tools/gen_menu.py
Los textos (botones, estadísticas) NO van en las imágenes: los dibuja el juego con componentes reales.
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "assets", "menu")
FONT = os.path.join(ROOT, "assets", "ui", "DejaVuSans-Bold.ttf")
S = 4  # supermuestreo para bordes suaves


def C(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)


def lighten(c, t):
    return mix(c, (255, 255, 255, 255), t)


def darken(c, t):
    return mix(c, (0, 0, 0, 255), t)


def save(im, name):
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, name))


def canvas(w, h):
    big = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    return big, ImageDraw.Draw(big)


def finish(big, w, h):
    return big.resize((w, h), Image.LANCZOS)


def rr(d, box, r, fill=None, outline=None, width=1):
    x0, y0, x1, y1 = [v * S for v in box]
    d.rounded_rectangle([x0, y0, x1 - 1, y1 - 1], radius=r * S, fill=fill, outline=outline, width=width * S)


def vgrad(d, box, top, bot, r=0):
    x0, y0, x1, y1 = box
    h = y1 - y0
    for y in range(int(y0 * S), int(y1 * S)):
        t = (y - y0 * S) / max(1, h * S)
        d.line([(x0 * S, y), (x1 * S - 1, y)], fill=mix(top, bot, t))


# ------------------------------------------------------------- cielo ------
def gen_sky():
    im = Image.new("RGBA", (8, 270))
    d = ImageDraw.Draw(im)
    stops = [(0.0, C("#2f7fe0")), (0.45, C("#6cb8f4")), (0.8, C("#b8e4ff")), (1.0, C("#e8f8ff"))]
    for y in range(270):
        t = y / 269.0
        for i in range(len(stops) - 1):
            if stops[i][0] <= t <= stops[i + 1][0]:
                u = (t - stops[i][0]) / (stops[i + 1][0] - stops[i][0])
                d.line([(0, y), (8, y)], fill=mix(stops[i][1], stops[i + 1][1], u))
    save(im, "sky.png")


def gen_mountains():
    W, H = 480, 130
    big, d = canvas(W, H)
    rnd = random.Random(7)
    for layer, (base, col, snow, amp) in enumerate([(100, C("#8fb4e0"), C("#ffffff"), 46), (118, C("#6a98d0"), C("#e8f4ff"), 34)]):
        peaks = []
        n = 6 if layer == 0 else 8
        for i in range(n):
            peaks.append(((i + 0.5) * W / n + rnd.randint(-12, 12), base - rnd.randint(amp - 16, amp)))
        pts = [(-20, H + 4)]
        for (px, py) in peaks:
            pts += [(px - 48, base + 6), (px, py), (px + 48, base + 6)]
        pts += [(W + 20, H + 4)]
        d.polygon([(x * S, y * S) for x, y in pts], fill=col)
        for (px, py) in peaks:  # nieve en las cimas
            d.polygon([(px * S, py * S), ((px - 11) * S, (py + 16) * S), ((px - 4) * S, (py + 13) * S), ((px + 1) * S, (py + 19) * S),
                       ((px + 7) * S, (py + 13) * S), ((px + 11) * S, (py + 16) * S)], fill=snow)
        # sombra lateral
        for (px, py) in peaks:
            d.polygon([(px * S, py * S), ((px + 48) * S, (base + 6) * S), (px * S, (base + 6) * S)], fill=darken(col, 0.12))
    # bruma al pie
    haze = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
    hd = ImageDraw.Draw(haze)
    for y in range(int(H * S * 0.55), H * S):
        a = int(150 * (y - H * S * 0.55) / (H * S * 0.45))
        hd.line([(0, y), (W * S, y)], fill=(200, 230, 255, a))
    big.alpha_composite(haze)
    save(finish(big, W, H), "mountains.png")


# ------------------------------------------------ acantilado y castillo ---
def stone(d, x0, y0, x1, y1, base, rnd):
    rr(d, (x0, y0, x1, y1), 0, fill=base)
    bh = 9
    for row, y in enumerate(range(int(y0), int(y1), bh)):
        d.line([(x0 * S, y * S), (x1 * S, y * S)], fill=darken(base, 0.35), width=S)
        off = 0 if row % 2 == 0 else 8
        for x in range(int(x0) + off, int(x1), 16):
            d.line([(x * S, y * S), (x * S, (y + bh) * S)], fill=darken(base, 0.3), width=S)
            if rnd.random() < 0.35:
                d.rectangle([(x + 2) * S, (y + 2) * S, (x + 6) * S, (y + 4) * S], fill=lighten(base, 0.12))


def tower(d, cx, base_y, w, h, roof_h, rnd, flag=True):
    stone(d, cx - w // 2, base_y - h, cx + w // 2, base_y, C("#a8acb8"), rnd)
    for k in range(3):  # ventanas
        pass
    d.rectangle([(cx - 2) * S, (base_y - h + 8) * S, (cx + 1) * S, (base_y - h + 14) * S], fill=C("#3a3a50"))
    d.polygon([((cx - w // 2 - 3) * S, (base_y - h) * S), (cx * S, (base_y - h - roof_h) * S), ((cx + w // 2 + 3) * S, (base_y - h) * S)], fill=C("#d03a2a"))
    d.polygon([(cx * S, (base_y - h - roof_h) * S), ((cx + w // 2 + 3) * S, (base_y - h) * S), (cx * S, (base_y - h) * S)], fill=C("#a02418"))
    d.line([(cx * S, (base_y - h - roof_h) * S), (cx * S, (base_y - h - roof_h - 8) * S)], fill=C("#5a3a1a"), width=S)
    if flag:
        d.polygon([(cx * S, (base_y - h - roof_h - 8) * S), ((cx + 7) * S, (base_y - h - roof_h - 6) * S), (cx * S, (base_y - h - roof_h - 3) * S)], fill=C("#ff3a3a"))


def gen_cliff():
    W, H = 250, 250
    big, d = canvas(W, H)
    rnd = random.Random(3)
    # cuerpo del acantilado: piedra con base irregular
    stone(d, 60, 112, W, H, C("#8a8e9a"), rnd)
    # roca más oscura abajo izquierda
    d.polygon([(40 * S, H * S), (60 * S, 130 * S), (70 * S, 112 * S), (90 * S, H * S)], fill=C("#6a6e7a"))
    # meseta de hierba
    rr(d, (52, 100, W, 118), 4, fill=C("#58c84a"))
    rr(d, (52, 100, W, 106), 3, fill=C("#8ae860"))
    for x in range(54, W, 7):  # flequillo de hierba
        d.polygon([(x * S, 116 * S), ((x + 3) * S, 124 * S), ((x + 6) * S, 116 * S)], fill=C("#58c84a"))
    # canales de las cascadas (agua base)
    for (cx, y0, w) in ((82, 118, 20), (176, 118, 26)):
        rr(d, (cx, y0, cx + w, H), 3, fill=C("#4aa0ff"))
        d.rectangle([cx * S, y0 * S, (cx + 3) * S, H * S], fill=C("#8ad0ff"))
    # estanque inferior
    rr(d, (60, H - 22, W, H), 0, fill=C("#3a8ae8"))
    for x in range(64, W, 14):
        d.arc([x * S, (H - 20) * S, (x + 10) * S, (H - 14) * S], 200, 340, fill=C("#bfe4ff"), width=S)
    # castillo
    stone(d, 112, 56, 196, 104, C("#b8bcc8"), rnd)
    for x in range(114, 196, 9):
        d.rectangle([x * S, 50 * S, (x + 4) * S, 56 * S], fill=C("#b8bcc8"))
    d.rounded_rectangle([146 * S, 80 * S, 162 * S, 104 * S], radius=6 * S, fill=C("#3a2a1a"))
    d.pieslice([146 * S, 74 * S, 162 * S, 90 * S], 180, 360, fill=C("#3a2a1a"))
    for (tx, tb, tw, th, tr) in ((104, 104, 18, 44, 22), (204, 104, 18, 44, 22), (154, 56, 24, 34, 30), (128, 56, 16, 28, 18), (182, 56, 16, 28, 18)):
        tower(d, tx, tb, tw, th, tr, rnd)
    # árboles de la meseta
    for (tx, ty, r) in ((84, 100, 9), (222, 100, 11), (236, 104, 8), (66, 102, 7)):
        d.rectangle([(tx - 1) * S, (ty - 2) * S, (tx + 1) * S, ty * S], fill=C("#6a4020"))
        d.ellipse([(tx - r) * S, (ty - r * 1.6) * S, (tx + r) * S, (ty + 1) * S], fill=C("#2f9a44"))
        d.ellipse([(tx - r * 0.6) * S, (ty - r * 1.6) * S, (tx + r * 0.3) * S, (ty - r * 0.6) * S], fill=C("#58c85a"))
    # borde izquierdo con hierba que cuelga
    for y in range(120, 220, 12):
        d.ellipse([46 * S, y * S, 64 * S, (y + 14) * S], fill=C("#3a9a3a"))
    save(finish(big, W, H), "cliff.png")
    # cascadas animadas (2 fotogramas, mismos huecos)
    frames = []
    for f in range(2):
        im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        dd = ImageDraw.Draw(im)
        for (cx, y0, w) in ((82, 118, 20), (176, 118, 26)):
            for k in range(0, w - 3, 5):
                for y in range(y0 + (f * 5 + k) % 12, H - 22, 12):
                    dd.line([(cx + 4 + k, y), (cx + 4 + k, y + 6)], fill=(255, 255, 255, 235), width=1)
            dd.rectangle([cx, y0, cx + 2, H - 22], fill=(180, 225, 255, 200))
        for x in range(64, W, 14):  # espuma del estanque
            dd.ellipse([x + f * 3, H - 24, x + 9 + f * 3, H - 20], fill=(255, 255, 255, 190))
        frames.append(im)
    sheet = Image.new("RGBA", (W * 2, H))
    sheet.paste(frames[0], (0, 0))
    sheet.paste(frames[1], (W, 0))
    save(sheet, "falls.png")


# ------------------------------------------------------------- árbol ------
def gen_tree():
    W, H = 170, 230
    big, d = canvas(W, H)
    rnd = random.Random(11)
    # tronco
    pts = [(30, H), (40, 150), (36, 90), (46, 30), (86, 30), (84, 90), (92, 150), (104, H)]
    d.polygon([(x * S, y * S) for x, y in pts], fill=C("#7a4a26"))
    d.polygon([((x + 0) * S, y * S) for x, y in [(70, 30), (86, 30), (84, 90), (92, 150), (104, H), (80, H), (74, 150), (72, 90)]], fill=C("#5a3418"))
    for y in range(40, H, 9):  # corteza
        x = 44 + rnd.randint(0, 40)
        d.line([(x * S, y * S), ((x + 3) * S, (y + 7) * S)], fill=C("#4a2a12"), width=S)
        d.line([((x - 6) * S, (y + 2) * S), ((x - 4) * S, (y + 8) * S)], fill=C("#a06a3a"), width=S)
    # rama a la derecha
    d.polygon([(80 * S, 70 * S), (150 * S, 40 * S), (156 * S, 52 * S), (86 * S, 90 * S)], fill=C("#7a4a26"))
    # copa
    for (cx, cy, r, col) in ((60, 24, 44, "#2a8a38"), (110, 20, 40, "#2f9a44"), (30, 50, 30, "#2a8a38"), (140, 52, 30, "#38b04c"),
                             (84, 8, 38, "#3ab84e"), (50, 6, 30, "#48c85a"), (130, 26, 26, "#48c85a")):
        d.ellipse([(cx - r) * S, (cy - r) * S, (cx + r) * S, (cy + r) * S], fill=C(col))
    for _ in range(90):  # hojas con brillo
        x, y = rnd.randint(8, 160), rnd.randint(0, 84)
        d.ellipse([x * S, y * S, (x + 7) * S, (y + 4) * S], fill=C("#8aef7a") if rnd.random() < 0.5 else C("#1f7a30"))
    save(finish(big, W, H), "tree.png")


# ------------------------------------------------------------- puente -----
def gen_bridge():
    W, H = 110, 40
    big, d = canvas(W, H)
    for x in range(0, W, 7):  # tablones
        d.rectangle([x * S, 24 * S, (x + 5) * S, 30 * S], fill=C("#a06a3a"))
        d.rectangle([x * S, 24 * S, (x + 5) * S, 26 * S], fill=C("#c88a52"))
    d.line([(0, 22 * S), (W * S, 22 * S)], fill=C("#6a4020"), width=2 * S)
    for x in range(0, W, 14):
        d.line([(x * S, 8 * S), (x * S, 24 * S)], fill=C("#6a4020"), width=2 * S)
    pts = [(x * S, (8 + 10 * (1 - math.cos((x - 0) / W * math.pi * 2)) / 2 * 0.6 + 2) * S) for x in range(0, W + 1, 2)]
    d.line(pts, fill=C("#7a5030"), width=2 * S)
    d.line([(0, 30 * S), (W * S, 30 * S)], fill=C("#5a3418"), width=2 * S)
    save(finish(big, W, H), "bridge.png")


# ------------------------------------------------------------- logo -------
def text_3d(base, txt, font, xy, top, bot, edge, depth=10, outline=6):
    """Letras gruesas con degradado, contorno y extrusión (efecto 3D)."""
    x, y = xy
    d = ImageDraw.Draw(base)
    for k in range(depth, 0, -1):  # extrusión
        d.text((x + k // 2, y + k), txt, font=font, fill=darken(edge, 0.25 + 0.03 * (depth - k)), stroke_width=outline, stroke_fill=darken(edge, 0.55))
    d.text((x, y), txt, font=font, fill=edge, stroke_width=outline, stroke_fill=C("#3a1f08"))
    mask = Image.new("L", base.size, 0)
    ImageDraw.Draw(mask).text((x, y), txt, font=font, fill=255)
    bb = mask.getbbox()
    grad = Image.new("RGBA", base.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad)
    for yy in range(bb[1], bb[3]):
        t = (yy - bb[1]) / max(1, bb[3] - bb[1])
        col = mix(top, bot, min(1.0, t * 1.25))
        gd.line([(bb[0], yy), (bb[2], yy)], fill=col)
    base.paste(grad, (0, 0), mask)
    # brillo superior
    hi = Image.new("RGBA", base.size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(hi)
    hd.rectangle([bb[0], bb[1], bb[2], bb[1] + (bb[3] - bb[1]) // 4], fill=(255, 255, 255, 70))
    hi.putalpha(Image.composite(hi.getchannel("A"), Image.new("L", base.size, 0), mask))
    base.alpha_composite(hi)


def leaf(d, x, y, ang, size, col):
    pts = []
    for t in range(0, 21):
        a = t / 20.0 * math.pi
        r = math.sin(a) * size * 0.35
        px = math.cos(a) * size * 0.5 + size * 0.5
        pts.append((px, r))
    for t in range(20, -1, -1):
        a = t / 20.0 * math.pi
        r = -math.sin(a) * size * 0.35
        px = math.cos(a) * size * 0.5 + size * 0.5
        pts.append((px, r))
    ca, sa = math.cos(ang), math.sin(ang)
    d.polygon([(x + (px - size * 0.5) * ca - py * sa, y + (px - size * 0.5) * sa + py * ca) for px, py in pts], fill=col)


def gen_logo():
    W, H = 620, 290  # el juego lo muestra al 50%
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # tablón de madera
    plank = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    pd = ImageDraw.Draw(plank)
    pd.rounded_rectangle([30, 62, W - 30, H - 14], radius=30, fill=C("#5a3418"), outline=C("#2a1408"), width=5)
    pd.rounded_rectangle([40, 72, W - 40, H - 28], radius=26, fill=C("#8a5428"))
    for y in range(82, H - 36, 14):
        pd.line([(52, y), (W - 52, y + random.Random(y).randint(-2, 2))], fill=C("#6a3e1c"), width=2)
    pd.rounded_rectangle([40, 72, W - 40, 112], radius=26, fill=(255, 255, 255, 28))
    im.alpha_composite(plank)
    # musgo y hojas en los bordes
    rnd = random.Random(5)
    for (cx, cy, sgn) in ((50, 90, -1), (W - 50, 90, 1), (56, 220, -1), (W - 56, 220, 1)):
        for k in range(7):
            leaf(d, cx + sgn * rnd.randint(-6, 24), cy + rnd.randint(-34, 22), rnd.uniform(0, 6.28), rnd.randint(30, 52),
                 C("#2f9a44") if k % 2 else C("#58c85a"))
    for x in range(70, W - 70, 26):
        d.ellipse([x, 68, x + 22, 82], fill=C("#3ab84e"))
    # corona
    cx, cy = W // 2, 30
    d.polygon([(cx - 40, cy + 34), (cx - 46, cy - 8), (cx - 22, cy + 10), (cx, cy - 20), (cx + 22, cy + 10), (cx + 46, cy - 8), (cx + 40, cy + 34)], fill=C("#ffd23a"), outline=C("#8a5a0a"))
    d.rectangle([cx - 40, cy + 26, cx + 40, cy + 38], fill=C("#f0a010"), outline=C("#8a5a0a"))
    for (px_, col) in ((cx - 24, "#ff3a4a"), (cx, "#59d0ff"), (cx + 24, "#ff3a4a")):
        d.ellipse([px_ - 5, cy + 28, px_ + 5, cy + 38], fill=C(col))
    for (px_, py_) in ((cx - 46, cy - 8), (cx, cy - 20), (cx + 46, cy - 8)):
        d.ellipse([px_ - 5, py_ - 5, px_ + 5, py_ + 5], fill=C("#fff7a0"))
    f1 = ImageFont.truetype(FONT, 124)
    f2 = ImageFont.truetype(FONT, 78)
    b1 = d.textbbox((0, 0), "WILMEN", font=f1, stroke_width=6)
    b2 = d.textbbox((0, 0), "ADVENTURE", font=f2, stroke_width=6)
    x1 = (W - (b1[2] - b1[0])) // 2 - b1[0]
    x2 = (W - (b2[2] - b2[0])) // 2 - b2[0]
    text_3d(im, "WILMEN", f1, (x1, 40 - b1[1]), C("#fff27a"), C("#f09a10"), C("#d8780a"), depth=12)
    text_3d(im, "ADVENTURE", f2, (x2, 158 - b2[1] + 6), C("#ffffff"), C("#a8b0c0"), C("#7a8294"), depth=9)
    save(im, "logo.png")


# ----------------------------------------------------------- botones ------
BTN = {
    "green": ("#3cc428", "#a6ff6a", "#1a7a12"),
    "blue": ("#2f6ae8", "#86b8ff", "#17399a"),
    "purple": ("#9a3ad8", "#dc96ff", "#561a88"),
    "orange": ("#ff9412", "#ffd464", "#b05408"),
    "red": ("#e83424", "#ff907a", "#861410"),
}


def gen_buttons():
    W, H = 48, 32
    for name, (base, hi, lo) in BTN.items():
        big, d = canvas(W, H)
        rr(d, (0, 0, W, H), 11, fill=C("#2a1408"))  # contorno oscuro
        rr(d, (1, 1, W - 1, H - 1), 10, fill=C("#ffd84a"))  # aro dorado
        rr(d, (2.5, 2.5, W - 2.5, H - 2.5), 9, fill=C("#b8780a"))
        body = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
        bd = ImageDraw.Draw(body)
        vgrad(bd, (3, 3, W - 3, H - 3), lighten(C(base), 0.18), darken(C(lo), 0.0))
        m = Image.new("L", (W * S, H * S), 0)
        ImageDraw.Draw(m).rounded_rectangle([3 * S, 3 * S, (W - 3) * S - 1, (H - 3) * S - 1], radius=8 * S, fill=255)
        big.paste(body, (0, 0), m)
        gl = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
        gd = ImageDraw.Draw(gl)
        gd.rounded_rectangle([5 * S, 4 * S, (W - 5) * S, 15 * S], radius=6 * S, fill=(255, 255, 255, 80))
        gd.rounded_rectangle([5 * S, 4 * S, (W - 5) * S, 7 * S], radius=3 * S, fill=(255, 255, 255, 80))
        big.alpha_composite(gl)
        save(finish(big, W, H), "btn_%s.png" % name)


def icon(name, size=20):
    big, d = canvas(size, size)
    s = size * S
    if name == "play":
        d.polygon([(s * 0.26, s * 0.14), (s * 0.84, s * 0.5), (s * 0.26, s * 0.86)], fill=C("#ffffff"), outline=C("#2a2a2a"))
    elif name == "map":
        for i, col in enumerate(("#ffe8a0", "#f4d070", "#ffe8a0")):
            x0 = s * (0.08 + i * 0.28)
            d.polygon([(x0, s * (0.26 if i % 2 == 0 else 0.34)), (x0 + s * 0.3, s * (0.34 if i % 2 == 0 else 0.26)),
                       (x0 + s * 0.3, s * (0.84 if i % 2 == 0 else 0.76)), (x0, s * (0.76 if i % 2 == 0 else 0.84))], fill=C(col), outline=C("#7a5a1a"))
        d.ellipse([s * 0.5, s * 0.02, s * 0.78, s * 0.34], fill=C("#e83a2a"), outline=C("#7a1410"))
        d.ellipse([s * 0.58, s * 0.1, s * 0.7, s * 0.22], fill=C("#ffffff"))
    elif name == "star":
        pts = []
        for k in range(10):
            a = -math.pi / 2 + k * math.pi / 5
            r = s * (0.46 if k % 2 == 0 else 0.2)
            pts.append((s * 0.5 + math.cos(a) * r, s * 0.54 + math.sin(a) * r))
        d.polygon(pts, fill=C("#ffd23a"), outline=C("#9a5a0a"))
        d.polygon([(s * 0.5, s * 0.12), (s * 0.58, s * 0.38), (s * 0.5, s * 0.5)], fill=C("#fff4a0"))
    elif name == "gear":
        cx = cy = s / 2
        pts = []
        for k in range(16):
            a = k * math.pi / 8
            r = s * (0.46 if k % 2 == 0 else 0.34)
            pts += [(cx + math.cos(a - 0.1) * r, cy + math.sin(a - 0.1) * r), (cx + math.cos(a + 0.1) * r, cy + math.sin(a + 0.1) * r)]
        d.polygon(pts, fill=C("#e0e4ec"), outline=C("#4a4e5a"))
        d.ellipse([cx - s * 0.17, cy - s * 0.17, cx + s * 0.17, cy + s * 0.17], fill=C("#ff9412"), outline=C("#4a4e5a"))
    elif name == "door":
        d.rectangle([s * 0.1, s * 0.12, s * 0.58, s * 0.9], fill=C("#d89a3a"), outline=C("#6a3a0a"))
        d.rectangle([s * 0.18, s * 0.2, s * 0.5, s * 0.82], fill=C("#a8661a"))
        d.polygon([(s * 0.56, s * 0.38), (s * 0.78, s * 0.38), (s * 0.78, s * 0.26), (s * 0.96, s * 0.5), (s * 0.78, s * 0.74), (s * 0.78, s * 0.62), (s * 0.56, s * 0.62)], fill=C("#3ad04a"), outline=C("#126a1a"))
    elif name == "diamond":
        d.polygon([(s * 0.5, s * 0.08), (s * 0.92, s * 0.38), (s * 0.5, s * 0.94), (s * 0.08, s * 0.38)], fill=C("#59c8ff"), outline=C("#1a5a9a"))
        d.polygon([(s * 0.5, s * 0.08), (s * 0.68, s * 0.38), (s * 0.5, s * 0.38), (s * 0.32, s * 0.38)], fill=C("#b0eaff"))
    elif name == "trophy":
        d.polygon([(s * 0.22, s * 0.1), (s * 0.78, s * 0.1), (s * 0.7, s * 0.52), (s * 0.5, s * 0.64), (s * 0.3, s * 0.52)], fill=C("#ffd23a"), outline=C("#9a5a0a"))
        d.arc([s * 0.02, s * 0.14, s * 0.3, s * 0.46], 90, 270, fill=C("#f0a010"), width=2 * S)
        d.arc([s * 0.7, s * 0.14, s * 0.98, s * 0.46], 270, 90, fill=C("#f0a010"), width=2 * S)
        d.rectangle([s * 0.44, s * 0.62, s * 0.56, s * 0.78], fill=C("#f0a010"))
        d.rectangle([s * 0.28, s * 0.78, s * 0.72, s * 0.92], fill=C("#a8661a"), outline=C("#5a3410"))
    elif name == "note":
        d.ellipse([s * 0.16, s * 0.6, s * 0.46, s * 0.86], fill=C("#ffd23a"), outline=C("#7a4a0a"))
        d.ellipse([s * 0.56, s * 0.5, s * 0.86, s * 0.76], fill=C("#ffd23a"), outline=C("#7a4a0a"))
        d.rectangle([s * 0.4, s * 0.16, s * 0.48, s * 0.72], fill=C("#ffd23a"), outline=C("#7a4a0a"))
        d.rectangle([s * 0.8, s * 0.06, s * 0.88, s * 0.62], fill=C("#ffd23a"), outline=C("#7a4a0a"))
        d.polygon([(s * 0.4, s * 0.16), (s * 0.88, s * 0.06), (s * 0.88, s * 0.24), (s * 0.4, s * 0.34)], fill=C("#ffd23a"), outline=C("#7a4a0a"))
    elif name == "pad":
        d.rounded_rectangle([s * 0.04, s * 0.28, s * 0.96, s * 0.8], radius=int(s * 0.22), fill=C("#f0d8b0"), outline=C("#7a5a30"), width=S)
        d.rectangle([s * 0.2, s * 0.46, s * 0.44, s * 0.56], fill=C("#5a3a1a"))
        d.rectangle([s * 0.26, s * 0.4, s * 0.36, s * 0.62], fill=C("#5a3a1a"))
        d.ellipse([s * 0.6, s * 0.4, s * 0.7, s * 0.5], fill=C("#5a3a1a"))
        d.ellipse([s * 0.72, s * 0.5, s * 0.82, s * 0.6], fill=C("#5a3a1a"))
    return finish(big, size, size)


def gen_icons():
    for n in ("play", "map", "star", "gear", "door", "diamond", "trophy", "note", "pad"):
        save(icon(n, 20), "icon_%s.png" % n)


def gen_round():
    for name, (fill_top, fill_bot, ic) in {"trophy": ("#8a4a1a", "#5a2a0a", "trophy"), "music": ("#2f7ae8", "#1a4aa8", "note")}.items():
        W = 36
        big, d = canvas(W, W)
        d.ellipse([0, 0, W * S - 1, W * S - 1], fill=C("#2a1408"))
        d.ellipse([1 * S, 1 * S, (W - 1) * S - 1, (W - 1) * S - 1], fill=C("#ffd84a"))
        d.ellipse([3 * S, 3 * S, (W - 3) * S - 1, (W - 3) * S - 1], fill=C("#b8780a"))
        inner = Image.new("RGBA", (W * S, W * S), (0, 0, 0, 0))
        idr = ImageDraw.Draw(inner)
        vgrad(idr, (4, 4, W - 4, W - 4), C(fill_top), C(fill_bot))
        m = Image.new("L", (W * S, W * S), 0)
        ImageDraw.Draw(m).ellipse([4 * S, 4 * S, (W - 4) * S - 1, (W - 4) * S - 1], fill=255)
        big.paste(inner, (0, 0), m)
        gl = Image.new("RGBA", (W * S, W * S), (0, 0, 0, 0))
        ImageDraw.Draw(gl).ellipse([7 * S, 5 * S, (W - 7) * S, 17 * S], fill=(255, 255, 255, 60))
        big.alpha_composite(gl)
        im = finish(big, W, W)
        im.alpha_composite(icon(ic, 22), (7, 7))
        save(im, "round_%s.png" % name)


def gen_bar():
    W, H = 48, 28
    big, d = canvas(W, H)
    rr(d, (0, 0, W, H), 7, fill=C("#2a1408"))
    rr(d, (1.5, 1.5, W - 1.5, H - 1.5), 6, fill=C("#a8661a"))
    body = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    vgrad(bd, (3, 3, W - 3, H - 3), C("#c88a42"), C("#7a4416"))
    m = Image.new("L", (W * S, H * S), 0)
    ImageDraw.Draw(m).rounded_rectangle([3 * S, 3 * S, (W - 3) * S - 1, (H - 3) * S - 1], radius=5 * S, fill=255)
    big.paste(body, (0, 0), m)
    rnd = random.Random(4)
    for _ in range(14):
        y = rnd.randint(5, H - 6)
        d.line([(5 * S, y * S), (rnd.randint(14, W - 6) * S, y * S)], fill=C("#7a4416"), width=1)
    d.line([(4 * S, 4 * S), ((W - 4) * S, 4 * S)], fill=C("#e8b068"), width=S)
    save(finish(big, W, H), "bar.png")
    # separador y panel de cartel
    sign = Image.new("RGBA", (54, 44), (0, 0, 0, 0))
    big, d = canvas(54, 44)
    rr(d, (2, 8, 52, 42), 6, fill=C("#2a1408"))
    rr(d, (3, 9, 51, 41), 5, fill=C("#a8661a"))
    vgrad(d, (4, 10, 50, 40), C("#c88a42"), C("#8a5220"))
    d.line([(14 * S, 0), (14 * S, 12 * S)], fill=C("#5a3418"), width=2 * S)
    d.line([(40 * S, 0), (40 * S, 12 * S)], fill=C("#5a3418"), width=2 * S)
    sign = finish(big, 54, 44)
    sign.alpha_composite(icon("pad", 30), (12, 12))
    save(sign, "sign.png")


# -------------------------------------------------------- cofre y gemas ----
def gen_treasure():
    W, H = 64, 48
    big, d = canvas(W, H)
    rr(d, (2, 22, 62, 46), 3, fill=C("#2a1408"))
    rr(d, (3, 23, 61, 45), 3, fill=C("#a8661a"))
    for x in range(8, 60, 12):
        d.line([(x * S, 23 * S), (x * S, 45 * S)], fill=C("#6a3a10"), width=S)
    d.rectangle([3 * S, 33 * S, 61 * S, 36 * S], fill=C("#ffd23a"))
    d.polygon([(3 * S, 24 * S), (8 * S, 4 * S), (56 * S, 4 * S), (61 * S, 24 * S)], fill=C("#2a1408"))
    d.polygon([(5 * S, 24 * S), (10 * S, 6 * S), (54 * S, 6 * S), (59 * S, 24 * S)], fill=C("#8a5220"))
    d.rectangle([8 * S, 6 * S, 56 * S, 9 * S], fill=C("#ffd23a"))
    for (gx, gy, col) in ((14, 20, "#59c8ff"), (26, 16, "#8ae0ff"), (40, 18, "#59c8ff"), (50, 21, "#2f9ae8"), (32, 22, "#b0eaff")):
        d.polygon([(gx * S, (gy - 7) * S), ((gx + 6) * S, (gy - 2) * S), (gx * S, (gy + 5) * S), ((gx - 6) * S, (gy - 2) * S)], fill=C(col), outline=C("#1a5a9a"))
    d.ellipse([27 * S, 30 * S, 37 * S, 40 * S], fill=C("#ffd23a"), outline=C("#6a3a10"))
    d.rectangle([31 * S, 33 * S, 33 * S, 38 * S], fill=C("#6a3a10"))
    save(finish(big, W, H), "chest.png")
    big, d = canvas(20, 20)
    d.polygon([(10 * S, 1 * S), (18 * S, 8 * S), (10 * S, 19 * S), (2 * S, 8 * S)], fill=C("#59c8ff"), outline=C("#1a5a9a"))
    d.polygon([(10 * S, 1 * S), (14 * S, 8 * S), (10 * S, 8 * S), (6 * S, 8 * S)], fill=C("#b0eaff"))
    save(finish(big, 20, 20), "gem.png")
    # moneda con estrella (2 giros)
    for i, w in enumerate((18, 10)):
        big, d = canvas(20, 20)
        d.ellipse([(10 - w / 2) * S, 1 * S, (10 + w / 2) * S, 19 * S], fill=C("#8a5a0a"))
        d.ellipse([(10 - w / 2 + 1) * S, 2 * S, (10 + w / 2 - 1) * S, 18 * S], fill=C("#ffd23a"))
        if w > 12:
            pts = []
            for k in range(10):
                a = -math.pi / 2 + k * math.pi / 5
                r = 6 if k % 2 == 0 else 2.6
                pts.append(((10 + math.cos(a) * r) * S, (10.5 + math.sin(a) * r) * S))
            d.polygon(pts, fill=C("#f0a010"), outline=C("#9a5a0a"))
        save(finish(big, 20, 20), "coin%d.png" % i)


def main():
    gen_sky()
    gen_mountains()
    gen_cliff()
    gen_tree()
    gen_bridge()
    gen_logo()
    gen_buttons()
    gen_icons()
    gen_round()
    gen_bar()
    gen_treasure()
    print("menú: arte generado en", OUT)


if __name__ == "__main__":
    main()

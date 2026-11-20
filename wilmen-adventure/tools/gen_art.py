#!/usr/bin/env python3
"""Genera TODO el pixel art de WILMEN ADVENTURE de forma procedural.

Ningún recurso externo: cada PNG se dibuja aquí con Pillow.
Uso:  python3 tools/gen_art.py
"""
import math
import os
import random

from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ASSETS = os.path.join(ROOT, "assets")


def C(s, a=255):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


OUTLINE = C("#1a1226")
CLEAR = (0, 0, 0, 0)


def save(im, *path):
    p = os.path.join(ASSETS, *path)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    im.save(p)


def outline(im, color=OUTLINE):
    """Contorno de 1 px alrededor de los píxeles opacos."""
    w, h = im.size
    src = im.load()
    out = im.copy()
    dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 0:
                        dst[x, y] = color
                        break
    return out


def sheet(frames, fw, fh):
    im = Image.new("RGBA", (fw * len(frames), fh), CLEAR)
    for i, f in enumerate(frames):
        im.paste(f, (i * fw, 0))
    return im


def newc(w, h):
    im = Image.new("RGBA", (w, h), CLEAR)
    return im, ImageDraw.Draw(im)


def rect(d, x, y, w, h, c):
    if w > 0 and h > 0:
        d.rectangle([x, y, x + w - 1, y + h - 1], fill=c)


def px(d, x, y, c):
    d.point((x, y), fill=c)


# ---------------------------------------------------------------- HÉROE ---
SKIN = C("#f2b27a")
SKIN_D = C("#d68a55")
HAIR = C("#7a3b1d")
HAIR_L = C("#b0612f")
TUNIC = C("#1fa38a")
TUNIC_D = C("#137a69")
SCARF = C("#e23d3d")
SCARF_D = C("#a62828")
BELT = C("#6b4224")
BUCKLE = C("#ffd34d")
PANTS = C("#3b4a8a")
PANTS_D = C("#2b3768")
BOOT = C("#5a3418")
WHITE = C("#ffffff")
EYE = C("#1b1b2f")


def hero_frame(kind, i=0):
    """Wilmen, 24x24, mirando a la derecha. Pies en la fila 23."""
    im, d = newc(24, 24)
    bob = 0
    lean = 0
    la = (0, 0)  # (dx, lift) pierna trasera
    lb = (0, 0)  # pierna delantera
    arm_dx, arm_dy = 0, 0
    scarf_w = 0
    eyes_closed = False
    if kind == "idle":
        bob = i
        scarf_w = i
    elif kind == "run":
        ph = i / 6.0 * 2 * math.pi
        la = (round(3 * math.sin(ph)), max(0, round(2 * math.cos(ph))))
        lb = (round(-3 * math.sin(ph)), max(0, round(-2 * math.cos(ph))))
        bob = 1 if i % 3 == 1 else 0
        arm_dx = round(-2 * math.sin(ph))
        scarf_w = (i % 2) * 2 - 1
        lean = 1
    elif kind == "jump":
        la, lb = (-2, 3), (2, 1)
        arm_dy = -2
        scarf_w = -2
    elif kind == "fall":
        la, lb = (-3, 0), (3, 1)
        arm_dy = -3
        scarf_w = 2
    elif kind == "hurt" or kind == "die":
        la, lb = (-3, 1), (3, 1)
        arm_dy = -4
        eyes_closed = True
        scarf_w = 2
    elif kind == "dash":
        lean = 3
        la, lb = (-4, 0), (3, 2)
        scarf_w = -2
        arm_dx = -3
    elif kind == "cast":
        arm_dx = 4
        scarf_w = 1
    hip = 18 + bob
    # --- pierna trasera
    for (dx, lift), col, shade in ((la, PANTS_D, True), (lb, PANTS, False)):
        lx = 10 + dx + (lean if lift < 99 else 0) - (1 if shade else 0)
        top = hip
        bot = 21 - lift
        rect(d, lx, top, 3, max(1, bot - top + 1), col)
        rect(d, lx, bot + 1, 4, 2, BOOT)
    # --- cuerpo
    rect(d, 9 + lean, 12 + bob, 8, 5, TUNIC)
    rect(d, 9 + lean, 15 + bob, 8, 2, TUNIC_D)
    rect(d, 9 + lean, 17 + bob, 8, 1, BELT)
    px(d, 13 + lean, 17 + bob, BUCKLE)
    px(d, 14 + lean, 17 + bob, BUCKLE)
    rect(d, 9 + lean, 18 + bob, 8, 1, PANTS)
    # --- cabeza
    hx = 8 + lean
    hy = 2 + bob
    rect(d, hx, hy + 2, 9, 8, SKIN)
    rect(d, hx - 1, hy, 11, 4, HAIR)  # pelo
    rect(d, hx - 1, hy + 3, 3, 5, HAIR)  # patilla trasera
    for tx in (hx + 1, hx + 4, hx + 7):  # mechones
        px(d, tx, hy - 1, HAIR_L)
        px(d, tx + 1, hy - 1, HAIR)
    rect(d, hx + 5, hy + 3, 4, 1, HAIR)  # flequillo
    px(d, hx + 8, hy + 4, HAIR)
    px(d, hx + 2, hy + 1, HAIR_L)
    px(d, hx + 3, hy + 1, HAIR_L)
    px(d, hx + 1, hy + 5, SKIN_D)  # oreja
    if eyes_closed:
        rect(d, hx + 5, hy + 6, 3, 1, EYE)
    else:
        rect(d, hx + 5, hy + 5, 2, 3, WHITE)
        rect(d, hx + 6, hy + 5, 1, 3, EYE)
    px(d, hx + 7, hy + 8, SKIN_D)  # boca
    px(d, hx + 8, hy + 6, SKIN_D)  # nariz
    # --- bufanda
    rect(d, hx - 1, 11 + bob, 11, 2, SCARF)
    rect(d, hx - 1, 12 + bob, 11, 1, SCARF_D)
    ty = 11 + bob + scarf_w
    for k in range(5):
        px(d, hx - 2 - k, ty + (1 if k % 2 else 0), SCARF)
        px(d, hx - 2 - k, ty + 1 + (1 if k % 2 else 0), SCARF_D)
    # --- brazo delantero
    ax = 12 + lean + arm_dx
    ay = 13 + bob + arm_dy
    if kind == "cast":
        rect(d, 13 + lean, 13 + bob, 6, 2, TUNIC_D)
        rect(d, 19 + lean, 13 + bob, 2, 2, SKIN)
    elif kind in ("jump", "fall", "hurt", "die"):
        rect(d, ax, ay, 2, 4, TUNIC_D)
        rect(d, ax, ay - 1, 2, 2, SKIN)
    else:
        rect(d, ax, ay, 2, 4, TUNIC_D)
        rect(d, ax, ay + 3, 2, 2, SKIN)
    return outline(im)


def gen_hero():
    frames = [hero_frame("idle", 0), hero_frame("idle", 1)]
    frames += [hero_frame("run", i) for i in range(6)]
    frames += [hero_frame("jump"), hero_frame("fall"), hero_frame("hurt"),
               hero_frame("dash"), hero_frame("cast")]
    save(sheet(frames, 24, 24), "player", "wilmen.png")


# ------------------------------------------------------------- PALETAS ---
WORLDS = {
    1: dict(
        sky_top="#5ab8f0", sky_bot="#c8f0ff", far="#8ccf9a", mid="#4fa86a", near="#2f7f4d",
        top="#58c84a", top_d="#2e8f3a", fill="#8a5a33", fill_d="#6a4026", fill_l="#a87444",
        brick="#c0693a", brick_d="#8a4526", blk="#f2b630", blk_d="#b8801a", spike="#cfd8e8",
        plat="#a87444", plat_d="#6a4026"),
    2: dict(
        sky_top="#140a2c", sky_bot="#3a2370", far="#4a3a8c", mid="#33276a", near="#221a4a",
        top="#7a6ad0", top_d="#4a3f9a", fill="#4c4080", fill_d="#352b62", fill_l="#6a5cb0",
        brick="#5a6ad0", brick_d="#3a47a0", blk="#59e0f0", blk_d="#2a9ab0", spike="#9af0ff",
        plat="#6a5cb0", plat_d="#352b62"),
    3: dict(
        sky_top="#f59a4a", sky_bot="#ffe3a0", far="#f0b86a", mid="#d89a4a", near="#b87a34",
        top="#f2d27a", top_d="#d9a94a", fill="#d9a350", fill_d="#b27a30", fill_l="#ecc070",
        brick="#cf8f46", brick_d="#9c6428", blk="#4ad0b0", blk_d="#1f8a74", spike="#f0e6c8",
        plat="#cf8f46", plat_d="#9c6428"),
    4: dict(
        sky_top="#9cc8f0", sky_bot="#f0faff", far="#c8e0f5", mid="#9cc4e8", near="#6a9cd0",
        top="#ffffff", top_d="#c8e4f8", fill="#7ab4e0", fill_d="#4f86bb", fill_l="#a8d4f2",
        brick="#6aa0d8", brick_d="#3f72ad", blk="#ffd04a", blk_d="#c08a1a", spike="#e8f8ff",
        plat="#a8d4f2", plat_d="#4f86bb"),
    5: dict(
        sky_top="#12081c", sky_bot="#4a1f42", far="#3a2450", mid="#2a1a3c", near="#1c1028",
        top="#7a6a90", top_d="#4a3d60", fill="#4e4262", fill_d="#352c46", fill_l="#6a5c82",
        brick="#6a5a82", brick_d="#3d3150", blk="#ff6a3a", blk_d="#a8300f", spike="#c8c0d8",
        plat="#6a5c82", plat_d="#352c46"),
}


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


# --------------------------------------------------------------- TILES ----
TILE_NAMES = ["top", "fill_a", "fill_b", "platform", "brick", "question",
              "used", "spike", "lava_a", "lava_b", "ice_top", "ice_fill"]

QMARK = [
    "01110",
    "10001",
    "00001",
    "00110",
    "00100",
    "00000",
    "00100",
]


def speckle(d, rnd, base, dark, light, n_dark=14, n_light=8):
    for _ in range(n_dark):
        px(d, rnd.randint(0, 15), rnd.randint(0, 15), dark)
    for _ in range(n_light):
        px(d, rnd.randint(0, 15), rnd.randint(0, 15), light)


def tile_fill(w, variant):
    P = WORLDS[w]
    rnd = random.Random(w * 100 + variant)
    im, d = newc(16, 16)
    base, dark, light = C(P["fill"]), C(P["fill_d"]), C(P["fill_l"])
    rect(d, 0, 0, 16, 16, base)
    if w == 5:  # ladrillos de castillo
        for row in range(4):
            y = row * 4
            rect(d, 0, y + 3, 16, 1, dark)
            off = 0 if row % 2 == 0 else 4
            for bx in range(-off, 16, 8):
                if 0 <= bx < 16:
                    rect(d, bx, y, 1, 4, dark)
        speckle(d, rnd, base, dark, light, 6, 6)
    elif w == 3:  # arenisca con estratos
        for y in (3, 8, 12):
            rect(d, 0, y + variant % 2, 16, 1, dark)
        speckle(d, rnd, base, dark, light, 10, 10)
    elif w == 4:  # hielo
        speckle(d, rnd, base, dark, light, 8, 14)
        for k in range(3):
            x = rnd.randint(1, 12)
            y = rnd.randint(1, 12)
            px(d, x, y, WHITE)
            px(d, x + 1, y + 1, WHITE)
    elif w == 2:  # roca con cristales
        speckle(d, rnd, base, dark, light, 14, 6)
        cx, cy = rnd.randint(3, 11), rnd.randint(4, 11)
        px(d, cx, cy, C("#9af0ff"))
        px(d, cx, cy - 1, C("#59e0f0"))
        px(d, cx + 1, cy, C("#59e0f0"))
    else:  # tierra
        speckle(d, rnd, base, dark, light, 16, 6)
        if variant:
            rect(d, 4, 9, 3, 2, C("#9a9a9a"))
            px(d, 4, 9, C("#cfcfcf"))
    return im


def tile_top(w):
    P = WORLDS[w]
    rnd = random.Random(w * 7)
    im = tile_fill(w, 0)
    d = ImageDraw.Draw(im)
    top, topd = C(P["top"]), C(P["top_d"])
    if w == 1:
        rect(d, 0, 0, 16, 4, top)
        rect(d, 0, 4, 16, 1, topd)
        for x in range(0, 16, 2):
            px(d, x, 5, top if x % 4 == 0 else topd)
        for x in (3, 9, 13):
            px(d, x, 1, C("#8ee86a"))
    elif w == 2:
        rect(d, 0, 0, 16, 3, top)
        rect(d, 0, 3, 16, 1, topd)
        for x in (2, 7, 12):
            px(d, x, 0, C("#cfe8ff"))
            px(d, x, 1, C("#59e0f0"))
    elif w == 3:
        rect(d, 0, 0, 16, 4, top)
        rect(d, 0, 4, 16, 1, topd)
        for x in range(1, 16, 5):
            px(d, x, 1, C("#fff0b8"))
    elif w == 4:
        rect(d, 0, 0, 16, 5, top)
        rect(d, 0, 5, 16, 1, topd)
        for x in (1, 5, 10, 14):  # carámbanos
            px(d, x, 6, topd)
            px(d, x, 7, C("#cfe8ff"))
    else:
        rect(d, 0, 0, 16, 3, top)
        rect(d, 0, 3, 16, 1, topd)
        rect(d, 0, 0, 16, 1, C("#a898c0"))
    return im


def tile_platform(w):
    P = WORLDS[w]
    im, d = newc(16, 16)
    rect(d, 0, 0, 16, 6, C(P["plat"]))
    rect(d, 0, 0, 16, 1, C(P["top"]) if w != 1 else C("#c89a60"))
    rect(d, 0, 5, 16, 1, C(P["plat_d"]))
    rect(d, 0, 6, 16, 1, OUTLINE)
    for x in (3, 8, 13):
        px(d, x, 3, C(P["plat_d"]))
    px(d, 0, 0, CLEAR)
    return im


def tile_brick(w):
    P = WORLDS[w]
    im, d = newc(16, 16)
    base, dark = C(P["brick"]), C(P["brick_d"])
    rect(d, 0, 0, 16, 16, base)
    for y in (0, 5, 10, 15):
        rect(d, 0, y, 16, 1, dark)
    for row, y in enumerate((0, 5, 10)):
        off = 0 if row % 2 == 0 else 4
        for x in range(off, 16, 8):
            rect(d, x, y, 1, 5, dark)
    rect(d, 0, 0, 1, 16, dark)
    rect(d, 15, 0, 1, 16, dark)
    for y in (1, 6, 11):
        rect(d, 1, y, 3, 1, lerp(base, WHITE, 0.3))
    return im


def tile_question(w, used=False):
    P = WORLDS[w]
    im, d = newc(16, 16)
    if used:
        base, dark = C("#8a8298"), C("#5a5268")
        rect(d, 0, 0, 16, 16, base)
    else:
        base, dark = C(P["blk"]), C(P["blk_d"])
        rect(d, 0, 0, 16, 16, base)
    rect(d, 0, 0, 16, 1, lerp(base, WHITE, 0.45))
    rect(d, 0, 0, 1, 16, lerp(base, WHITE, 0.25))
    rect(d, 0, 15, 16, 1, dark)
    rect(d, 15, 0, 1, 16, dark)
    for p in ((2, 2), (13, 2), (2, 13), (13, 13)):
        px(d, p[0], p[1], dark)
    if not used:
        for r, line in enumerate(QMARK):
            for c, ch in enumerate(line):
                if ch == "1":
                    px(d, 5 + c + 1, 4 + r + 1, dark)
                    px(d, 5 + c, 4 + r, WHITE)
    return im


def tile_spike(w):
    P = WORLDS[w]
    im, d = newc(16, 16)
    col = C(P["spike"])
    shade = lerp(col, OUTLINE, 0.45)
    for k in range(2):
        bx = k * 8
        d.polygon([(bx, 15), (bx + 3, 7), (bx + 7, 15)], fill=col)
        d.polygon([(bx + 3, 7), (bx + 7, 15), (bx + 4, 15)], fill=shade)
    rect(d, 0, 15, 16, 1, shade)
    return outline(im)


def tile_lava(variant):
    im, d = newc(16, 16)
    rect(d, 0, 0, 16, 16, C("#ff6a1a"))
    rect(d, 0, 0, 16, 3, C("#ffd23a"))
    for x in range(16):
        h = 2 + int(1.5 * math.sin((x + variant * 4) / 16 * 2 * math.pi * 2))
        rect(d, x, 0, 1, h, C("#fff08a"))
        px(d, x, h + 1, C("#ff9a2a"))
    rnd = random.Random(5 + variant)
    for _ in range(8):
        px(d, rnd.randint(0, 15), rnd.randint(4, 15), C("#c8300a"))
    return im


def gen_tiles():
    for w in WORLDS:
        P = WORLDS[w]
        tiles = [tile_top(w), tile_fill(w, 0), tile_fill(w, 1), tile_platform(w),
                 tile_brick(w), tile_question(w), tile_question(w, True), tile_spike(w),
                 tile_lava(0), tile_lava(1), tile_top(w), tile_fill(w, 0)]
        save(sheet(tiles, 16, 16), "tiles", "tiles_w%d.png" % w)
        # plataforma móvil 32x8
        im, d = newc(32, 8)
        rect(d, 0, 0, 32, 6, C(P["plat"]))
        rect(d, 0, 0, 32, 1, C(P["top"]) if w != 1 else C("#c89a60"))
        rect(d, 0, 5, 32, 1, C(P["plat_d"]))
        for x in (3, 10, 17, 24, 29):
            px(d, x, 3, C(P["plat_d"]))
        rect(d, 3, 6, 2, 2, C(P["plat_d"]))
        rect(d, 27, 6, 2, 2, C(P["plat_d"]))
        save(outline(im), "tiles", "mplatform_w%d.png" % w)


# ------------------------------------------------------------ DECORADO ----
def gen_decor():
    # 24x32 anclado abajo
    for w in WORLDS:
        im, d = newc(24, 32)
        if w == 1:  # árbol redondo
            rect(d, 10, 18, 4, 14, C("#7a4a26"))
            rect(d, 10, 18, 1, 14, C("#a06a3a"))
            for (cx, cy, r, col) in ((12, 10, 9, "#2f9a44"), (6, 14, 6, "#38b04c"),
                                     (18, 14, 6, "#2a8a3c"), (12, 6, 6, "#48c85a")):
                d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=C(col))
            px(d, 9, 5, C("#8ef08a"))
            px(d, 10, 5, C("#8ef08a"))
        elif w == 2:  # cristales
            for (x, h, col) in ((5, 14, "#59e0f0"), (11, 24, "#9af0ff"), (17, 17, "#b080ff")):
                d.polygon([(x - 3, 31), (x, 31 - h), (x + 3, 31)], fill=C(col))
                d.polygon([(x, 31 - h), (x + 3, 31), (x, 31)], fill=lerp(C(col), OUTLINE, 0.3))
        elif w == 3:  # cactus
            rect(d, 10, 8, 5, 24, C("#3a9a4a"))
            rect(d, 10, 8, 1, 24, C("#5ac86a"))
            rect(d, 4, 14, 6, 3, C("#3a9a4a"))
            rect(d, 4, 8, 3, 7, C("#3a9a4a"))
            rect(d, 15, 17, 6, 3, C("#3a9a4a"))
            rect(d, 18, 11, 3, 8, C("#3a9a4a"))
            for p in ((12, 12), (12, 20), (5, 10), (19, 14)):
                px(d, p[0], p[1], C("#d8f0a8"))
            px(d, 12, 6, C("#ff6a8a"))
            px(d, 13, 7, C("#ff6a8a"))
        elif w == 4:  # pino nevado
            for k, (y, hw) in enumerate(((22, 10), (14, 8), (6, 6))):
                d.polygon([(12 - hw, y + 8), (12, y - 6), (12 + hw, y + 8)], fill=C("#3a8a6a"))
                d.polygon([(12 - hw + 2, y + 2), (12, y - 6), (12 + hw - 2, y + 2)], fill=C("#ffffff"))
            rect(d, 11, 28, 3, 4, C("#6a4026"))
        else:  # antorcha
            rect(d, 11, 12, 3, 20, C("#4a3d60"))
            rect(d, 9, 10, 7, 3, C("#6a5c82"))
            d.polygon([(12, 1), (8, 9), (16, 9)], fill=C("#ff8a2a"))
            d.polygon([(12, 4), (10, 9), (14, 9)], fill=C("#ffe05a"))
        save(outline(im), "decor", "decor_w%d.png" % w)


# ------------------------------------------------------------ OBJETOS -----
def gen_items():
    # moneda: 4 fotos de giro
    frames = []
    for wd in (10, 7, 3, 7):
        im, d = newc(16, 16)
        x0 = 8 - wd // 2
        d.ellipse([x0, 2, x0 + wd - 1, 13], fill=C("#ffd23a"))
        if wd > 5:
            d.ellipse([x0 + 1, 3, x0 + wd - 2, 12], fill=C("#ffe97a"))
            rect(d, 7, 5, 2, 6, C("#e0a010"))
        frames.append(outline(im))
    save(sheet(frames, 16, 16), "items", "coin.png")
    # gema: 2 frames (brillo)
    frames = []
    for f in range(2):
        im, d = newc(16, 16)
        d.polygon([(8, 1), (14, 6), (8, 15), (2, 6)], fill=C("#ff4aa8"))
        d.polygon([(8, 1), (14, 6), (8, 6)], fill=C("#ff9ad0"))
        d.polygon([(8, 6), (14, 6), (8, 15)], fill=C("#c01878"))
        d.polygon([(2, 6), (8, 6), (8, 1)], fill=C("#ff7ac0"))
        if f:
            px(d, 5, 4, WHITE)
            px(d, 6, 3, WHITE)
            px(d, 4, 5, WHITE)
        else:
            px(d, 5, 5, WHITE)
        frames.append(outline(im))
    save(sheet(frames, 16, 16), "items", "gem.png")
    # corazón
    im, d = newc(16, 16)
    for (cx, cy) in ((5, 5), (10, 5)):
        d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=C("#ff3a4a"))
    d.polygon([(2, 6), (13, 6), (8, 13)], fill=C("#ff3a4a"))
    px(d, 4, 3, WHITE)
    px(d, 5, 3, WHITE)
    save(outline(im), "items", "heart.png")
    # vida extra (insignia W)
    im, d = newc(16, 16)
    d.ellipse([1, 1, 14, 14], fill=C("#1fa38a"))
    d.ellipse([3, 3, 12, 12], fill=C("#2fd0ae"))
    for (a, b) in ((4, 5), (6, 9), (8, 6), (9, 9), (11, 5)):
        pass
    d.line([(4, 5), (6, 10), (8, 6), (10, 10), (12, 5)], fill=WHITE)
    save(outline(im), "items", "life.png")
    # resorte
    frames = []
    for h in (9, 5):
        im, d = newc(16, 16)
        rect(d, 2, 14, 12, 2, C("#6a5c82"))
        for k in range(4):
            y = 14 - h + k * (h // 4 + 1)
            rect(d, 3, y, 10, 1, C("#d8d8e8"))
        rect(d, 1, 14 - h - 2, 14, 3, C("#ff4a4a"))
        frames.append(outline(im))
    save(sheet(frames, 16, 16), "items", "spring.png")
    # meta (bandera con asta) 16x48, 2 frames
    frames = []
    for f in range(2):
        im, d = newc(16, 48)
        rect(d, 7, 2, 2, 46, C("#e8e8f0"))
        rect(d, 7, 2, 1, 46, WHITE)
        d.ellipse([5, 0, 10, 4], fill=C("#ffd23a"))
        off = f
        d.polygon([(9, 5), (15, 8 + off), (9, 12)], fill=C("#1fa38a"))
        d.polygon([(9, 5), (13, 7 + off), (9, 8)], fill=C("#2fd0ae"))
        px(d, 11, 8, WHITE)
        frames.append(outline(im))
    save(sheet(frames, 16, 48), "items", "goal.png")
    # punto de control 16x32: apagado / encendido
    frames = []
    for on in (False, True):
        im, d = newc(16, 32)
        rect(d, 7, 6, 2, 26, C("#9a90b0"))
        rect(d, 4, 29, 8, 3, C("#6a5c82"))
        d.ellipse([5, 3, 10, 7], fill=C("#ffd23a") if on else C("#8a8298"))
        flag = C("#ff4a4a") if on else C("#6a6280")
        d.polygon([(9, 7), (15, 10), (9, 14)], fill=flag)
        frames.append(outline(im))
    save(sheet(frames, 16, 32), "items", "checkpoint.png")
    # proyectiles 8x8: spark, ice, shard, orb, snowball, acorn/rock, wave, sand
    cells = []

    def cell(fn):
        im, d = newc(8, 8)
        fn(d)
        cells.append(outline(im))
    cell(lambda d: (d.ellipse([1, 1, 6, 6], fill=C("#ffd23a")), d.ellipse([2, 2, 5, 5], fill=C("#fff6b0"))))
    cell(lambda d: (d.polygon([(0, 4), (4, 0), (7, 4), (4, 7)], fill=C("#8fe0ff")), px(d, 3, 3, WHITE)))
    cell(lambda d: d.polygon([(0, 6), (3, 0), (6, 6)], fill=C("#b080ff")))
    cell(lambda d: (d.ellipse([0, 0, 7, 7], fill=C("#8a2ad0")), d.ellipse([2, 2, 5, 5], fill=C("#ff5aff"))))
    cell(lambda d: (d.ellipse([0, 0, 7, 7], fill=C("#e8f4ff")), px(d, 2, 2, WHITE)))
    cell(lambda d: (d.ellipse([0, 1, 7, 7], fill=C("#8a5a33")), rect(d, 3, 0, 2, 2, C("#58c84a"))))
    cell(lambda d: d.polygon([(0, 7), (2, 0), (6, 7)], fill=C("#ff8a2a")))
    cell(lambda d: (d.ellipse([0, 0, 7, 7], fill=C("#e0b050")), px(d, 2, 2, C("#fff0b8"))))
    save(sheet(cells, 8, 8), "items", "projectiles.png")


def gen_ui_icons():
    cells = []

    def cell(fn):
        im, d = newc(16, 16)
        fn(d)
        cells.append(outline(im))
    # 0 corazón lleno, 1 vacío
    def heart(d, col):
        for (cx, cy) in ((5, 5), (10, 5)):
            d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=col)
        d.polygon([(2, 6), (13, 6), (8, 13)], fill=col)
    cell(lambda d: heart(d, C("#ff3a4a")))
    cell(lambda d: heart(d, C("#4a3f5a")))
    cell(lambda d: (d.ellipse([3, 2, 12, 13], fill=C("#ffd23a")), rect(d, 7, 5, 2, 6, C("#e0a010"))))
    cell(lambda d: (d.polygon([(8, 1), (14, 6), (8, 15), (2, 6)], fill=C("#ff4aa8")), px(d, 5, 5, WHITE)))
    cell(lambda d: (d.ellipse([1, 1, 14, 14], fill=C("#1fa38a")), d.line([(4, 5), (6, 10), (8, 6), (10, 10), (12, 5)], fill=WHITE)))
    # 5..9 poderes: chispa, impulso, escudo, hielo, sombra
    cell(lambda d: (d.polygon([(8, 0), (10, 6), (15, 8), (10, 10), (8, 15), (6, 10), (1, 8), (6, 6)], fill=C("#ffd23a"))))
    cell(lambda d: (d.polygon([(1, 3), (9, 3), (14, 8), (9, 13), (1, 13), (5, 8)], fill=C("#59e0f0"))))
    cell(lambda d: (d.polygon([(2, 2), (13, 2), (13, 9), (8, 14), (2, 9)], fill=C("#ffb030")), rect(d, 6, 5, 3, 5, C("#fff0b0"))))
    cell(lambda d: (d.polygon([(8, 0), (14, 8), (8, 15), (2, 8)], fill=C("#8fe0ff")), d.line([(8, 3), (8, 12)], fill=WHITE), d.line([(4, 8), (12, 8)], fill=WHITE)))
    cell(lambda d: (d.ellipse([1, 1, 14, 14], fill=C("#5a2a9a")), d.ellipse([5, 4, 14, 12], fill=C("#1a0a30")), px(d, 10, 7, C("#ffe05a"))))
    save(sheet(cells, 16, 16), "ui", "icons.png")


# ------------------------------------------------------------ ENEMIGOS ----
EN = {
    1: dict(body="#e0502a", body_l="#ff8a5a", body_d="#a02a12", acc="#f8f0d8", eye="#1a1226"),
    2: dict(body="#7a4ad0", body_l="#a880ff", body_d="#4a2a90", acc="#59e0f0", eye="#fff6a0"),
    3: dict(body="#e0a020", body_l="#ffd860", body_d="#a06a10", acc="#4a2a10", eye="#1a1226"),
    4: dict(body="#e8f4ff", body_l="#ffffff", body_d="#8ab4d8", acc="#3a6ac0", eye="#1a1226"),
    5: dict(body="#4a2a70", body_l="#7a4aa8", body_d="#2a1448", acc="#ff4a3a", eye="#ffe05a"),
}


def eyes(d, x, y, col, angry=True):
    rect(d, x, y, 2, 2, WHITE)
    rect(d, x + 4, y, 2, 2, WHITE)
    px(d, x + 1, y + 1, col)
    px(d, x + 4, y + 1, col)
    if angry:
        px(d, x, y - 1, OUTLINE)
        px(d, x + 1, y - 1, OUTLINE)
        px(d, x + 4, y - 1, OUTLINE)
        px(d, x + 5, y - 1, OUTLINE)


def enemy_walker(w, f):
    P = EN[w]
    im, d = newc(16, 16)
    body, bl, bd, acc, eye = (C(P[k]) for k in ("body", "body_l", "body_d", "acc", "eye"))
    squash = 1 if f in (1, 3) else 0
    top = 3 + squash
    if w == 1:  # hongo
        d.ellipse([1, top, 14, top + 8], fill=body)
        rect(d, 1, top + 5, 14, 3, body)
        for (sx, sy) in ((4, top + 2), (9, top + 1), (11, top + 4)):
            rect(d, sx, sy, 2, 2, acc)
        rect(d, 4, top + 8, 8, 4, C("#f0e0b8"))
        eyes(d, 5, top + 8, eye)
    elif w == 2:  # escarabajo de cristal
        d.ellipse([1, top + 1, 14, top + 11], fill=body)
        rect(d, 1, top + 7, 14, 4, body)
        d.polygon([(4, top + 2), (6, top - 3), (8, top + 2)], fill=acc)
        d.polygon([(8, top + 2), (11, top - 2), (12, top + 3)], fill=acc)
        eyes(d, 5, top + 5, eye)
    elif w == 3:  # escarabajo dorado
        d.ellipse([1, top, 14, top + 10], fill=body)
        rect(d, 1, top + 6, 14, 4, body)
        rect(d, 7, top, 2, 10, acc)
        rect(d, 1, top + 3, 3, 2, bd)
        rect(d, 12, top + 3, 3, 2, bd)
        px(d, 4, top + 6, eye)
        px(d, 11, top + 6, eye)
    elif w == 4:  # bola de nieve con gorro
        d.ellipse([1, top, 14, top + 11], fill=body)
        rect(d, 2, top - 1, 12, 3, acc)
        rect(d, 11, top - 3, 3, 3, acc)
        eyes(d, 5, top + 4, eye, False)
        rect(d, 7, top + 7, 2, 2, C("#ff8a2a"))
    else:  # diablillo de sombra
        d.ellipse([1, top + 1, 14, top + 11], fill=body)
        rect(d, 1, top + 7, 14, 4, body)
        d.polygon([(2, top + 2), (3, top - 3), (6, top + 1)], fill=bd)
        d.polygon([(13, top + 2), (12, top - 3), (9, top + 1)], fill=bd)
        rect(d, 5, top + 4, 2, 2, eye)
        rect(d, 9, top + 4, 2, 2, eye)
    # sombreado y pies
    rect(d, 2, top + 8 if w != 1 else top + 11, 12, 1, bd) if w not in (1,) else None
    foot = (3, 9) if f % 2 == 0 else (5, 11)
    rect(d, foot[0], 13, 3, 2, bd if w != 4 else C("#6a8ab0"))
    rect(d, foot[1], 13, 3, 2, bd if w != 4 else C("#6a8ab0"))
    px(d, 4, top + 1, bl)
    px(d, 5, top, bl)
    return outline(im)


def enemy_spiky(w, f):
    P = EN[w]
    im, d = newc(16, 16)
    body = C(P["body"])
    bd = C(P["body_d"])
    spike = {1: "#3a3a4a", 2: "#59e0f0", 3: "#7a5a20", 4: "#8fb8e8", 5: "#c8c0d8"}[w]
    ang0 = f * math.pi / 8
    cx, cy = 8, 8
    for k in range(8):
        a = ang0 + k * math.pi / 4
        tip = (cx + 7.4 * math.cos(a), cy + 7.4 * math.sin(a))
        l = (cx + 4.5 * math.cos(a - 0.4), cy + 4.5 * math.sin(a - 0.4))
        r = (cx + 4.5 * math.cos(a + 0.4), cy + 4.5 * math.sin(a + 0.4))
        d.polygon([l, tip, r], fill=C(spike))
    d.ellipse([3, 3, 12, 12], fill=body)
    d.ellipse([3, 6, 12, 12], fill=bd)
    d.ellipse([3, 3, 12, 9], fill=body)
    rect(d, 5, 6, 2, 2, C(P["eye"]) if w in (2, 5) else WHITE)
    rect(d, 9, 6, 2, 2, C(P["eye"]) if w in (2, 5) else WHITE)
    px(d, 6, 7, OUTLINE if w not in (2, 5) else C("#ff2a2a"))
    px(d, 10, 7, OUTLINE if w not in (2, 5) else C("#ff2a2a"))
    return outline(im)


def enemy_jumper(w, f):
    P = EN[w]
    im, d = newc(16, 16)
    body, bl, bd, acc, eye = (C(P[k]) for k in ("body", "body_l", "body_d", "acc", "eye"))
    cols = {1: ("#48b848", "#80e070", "#2a7a2a"), 2: ("#8a6ad0", "#b8a0ff", "#5a3a9a"),
            3: ("#d8a850", "#f0d080", "#a07830"), 4: ("#7ac0f0", "#b8e4ff", "#4a88c0"),
            5: ("#6a3a8a", "#9a6ac0", "#3a1a5a")}[w]
    body, bl, bd = C(cols[0]), C(cols[1]), C(cols[2])
    if f == 0:  # agachado
        d.ellipse([1, 6, 14, 15], fill=body)
        rect(d, 1, 11, 14, 4, body)
        rect(d, 0, 13, 4, 3, bd)
        rect(d, 12, 13, 4, 3, bd)
        ey = 4
    else:  # estirado
        d.ellipse([3, 3, 12, 13], fill=body)
        rect(d, 1, 12, 3, 4, bd)
        rect(d, 12, 12, 3, 4, bd)
        rect(d, 5, 12, 6, 2, bd)
        ey = 1
    rect(d, 3, ey + 1 if f == 0 else ey + 1, 4, 4, WHITE)
    rect(d, 9, ey + 1, 4, 4, WHITE)
    rect(d, 5, ey + 2, 2, 3, OUTLINE)
    rect(d, 11, ey + 2, 2, 3, OUTLINE)
    if w == 5:
        px(d, 5, ey + 3, C("#ffe05a"))
        px(d, 11, ey + 3, C("#ffe05a"))
    px(d, 4, 9 if f == 0 else 7, bl)
    return outline(im)


def enemy_flyer(w, f):
    P = EN[w]
    im, d = newc(16, 16)
    cols = {1: ("#f0c020", "#fff08a", "#1a1226"), 2: ("#8a4ad0", "#c0a0ff", "#59e0f0"),
            3: ("#c8782a", "#f0b060", "#4a2a10"), 4: ("#9ad4f8", "#e8f8ff", "#3a6ac0"),
            5: ("#7a1a3a", "#c04a6a", "#ffe05a")}[w]
    body, wing, acc = C(cols[0]), C(cols[1]), C(cols[2])
    wy = (1, 4, 7)[f % 3]
    # alas
    d.polygon([(7, 8), (1, wy), (4, wy + 5), (7, 11)], fill=wing)
    d.polygon([(9, 8), (15, wy), (12, wy + 5), (9, 11)], fill=wing)
    d.ellipse([4, 5, 11, 13], fill=body)
    if w == 1:
        for y in (7, 10):
            rect(d, 5, y, 6, 1, acc)
        px(d, 8, 14, acc)
    rect(d, 5, 7, 2, 2, WHITE)
    rect(d, 9, 7, 2, 2, WHITE)
    px(d, 6, 8, OUTLINE if w not in (2, 5) else acc)
    px(d, 10, 8, OUTLINE if w not in (2, 5) else acc)
    if w in (2, 4, 5):  # orejas de murciélago
        px(d, 5, 4, body)
        px(d, 10, 4, body)
    return outline(im)


def enemy_shooter(w, f):
    im, d = newc(16, 16)
    cols = {1: ("#3a9a44", "#d03a4a", "#1f6a2a"), 2: ("#8a6ad0", "#59e0f0", "#4a3a8a"),
            3: ("#4aa84a", "#ff6a8a", "#2a7a2a"), 4: ("#8ab4d8", "#ffffff", "#4a7ab0"),
            5: ("#5a4a72", "#ff4a3a", "#352c46")}[w]
    base, head, dark = C(cols[0]), C(cols[1]), C(cols[2])
    rect(d, 4, 11, 8, 5, dark)
    rect(d, 5, 11, 6, 1, base)
    bob = 1 if f == 1 else 0
    rect(d, 7, 7 + bob, 2, 5, base)
    d.ellipse([3, 1 + bob, 12, 9 + bob], fill=head)
    # boca / cañón hacia la derecha
    if f == 2:
        d.ellipse([9, 3 + bob, 15, 8 + bob], fill=OUTLINE)
        px(d, 13, 5 + bob, C("#ffd23a"))
    else:
        rect(d, 10, 5 + bob, 3, 2, OUTLINE)
    rect(d, 5, 3 + bob, 2, 2, WHITE)
    px(d, 6, 4 + bob, OUTLINE)
    px(d, 5, 2 + bob, lerp(head, WHITE, 0.5))
    return outline(im)


def gen_enemies():
    for w in WORLDS:
        im = Image.new("RGBA", (64, 80), CLEAR)
        rows = [
            [enemy_walker(w, i) for i in range(4)],
            [enemy_spiky(w, i) for i in range(4)],
            [enemy_jumper(w, 0), enemy_jumper(w, 1)],
            [enemy_flyer(w, i) for i in range(3)],
            [enemy_shooter(w, i) for i in range(3)],
        ]
        for r, row in enumerate(rows):
            for c, fr in enumerate(row):
                im.paste(fr, (c * 16, r * 16))
        save(im, "enemies", "enemies_w%d.png" % w)


# --------------------------------------------------------------- JEFES ----
def boss_trunk(f):
    im, d = newc(64, 64)
    bark, bark_d, bark_l = C("#8a5a33"), C("#5a3a20"), C("#b07a48")
    leaf, leaf_l = C("#2f9a44"), C("#58c84a")
    # raíces/pies
    rect(d, 12, 54, 10, 8, bark_d)
    rect(d, 42, 54, 10, 8, bark_d)
    # brazos (ramas)
    arm = -4 if f else 0
    d.polygon([(10, 26), (0, 20 + arm), (2, 28 + arm), (12, 36)], fill=bark)
    d.polygon([(54, 26), (63, 20 + arm), (61, 28 + arm), (52, 36)], fill=bark)
    for (x, y) in ((1, 19 + arm), (62, 19 + arm)):
        d.ellipse([x - 4, y - 5, x + 4, y + 3], fill=leaf)
    # tronco
    d.rounded_rectangle([10, 14, 53, 58], radius=8, fill=bark)
    rect(d, 10, 14, 6, 44, bark_l)
    rect(d, 47, 18, 6, 40, bark_d)
    for x in (22, 30, 38, 44):
        rect(d, x, 20, 1, 34, bark_d)
    # corona de hojas
    for (cx, cy, r) in ((20, 12, 9), (32, 7, 10), (44, 12, 9), (26, 14, 6), (38, 14, 6)):
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=leaf)
    for (cx, cy) in ((24, 6), (34, 3), (42, 8)):
        d.ellipse([cx - 2, cy - 2, cx + 2, cy + 1], fill=leaf_l)
    # cara
    for ex in (20, 36):
        d.polygon([(ex, 28), (ex + 9, 30), (ex + 9, 36), (ex, 34)], fill=C("#1a1226"))
        d.polygon([(ex + 1, 30), (ex + 8, 31), (ex + 8, 35), (ex + 1, 34)], fill=C("#d8ff5a"))
        rect(d, ex + 4, 31, 2, 3, C("#1a1226"))
    d.polygon([(18, 26), (29, 30), (29, 31), (18, 28)], fill=C("#1a1226"))
    d.polygon([(46, 26), (35, 30), (35, 31), (46, 28)], fill=C("#1a1226"))
    d.polygon([(22, 44), (42, 44), (40, 52), (24, 52)], fill=C("#1a1226"))
    for x in (25, 30, 35):
        d.polygon([(x, 44), (x + 3, 44), (x + 1, 49)], fill=C("#f0e8d0"))
    return outline(im)


def boss_golem(f):
    im, d = newc(64, 64)
    body, body_d, crys, crys_l = C("#5a4a9a"), C("#3a2f6a"), C("#59e0f0"), C("#b8f8ff")
    fy = 3 if f else 0
    # puños flotantes
    for (cx) in (6, 58):
        d.polygon([(cx - 8, 36 + fy), (cx, 28 + fy), (cx + 8, 36 + fy), (cx + 6, 48 + fy), (cx - 6, 48 + fy)], fill=crys)
        d.polygon([(cx, 28 + fy), (cx + 8, 36 + fy), (cx + 6, 48 + fy), (cx, 48 + fy)], fill=lerp(crys, OUTLINE, 0.35))
        px(d, cx - 3, 34 + fy, crys_l)
    # piernas
    rect(d, 20, 50, 9, 12, body_d)
    rect(d, 35, 50, 9, 12, body_d)
    # torso hexagonal
    d.polygon([(14, 26), (24, 12), (40, 12), (50, 26), (46, 50), (18, 50)], fill=body)
    d.polygon([(32, 12), (40, 12), (50, 26), (46, 50), (32, 50)], fill=body_d)
    # cristales de hombros
    for (x, h) in ((12, 14), (20, 18), (44, 18), (52, 14)):
        d.polygon([(x - 4, 22), (x, 22 - h), (x + 4, 22)], fill=crys)
        d.polygon([(x, 22 - h), (x + 4, 22), (x, 22)], fill=lerp(crys, OUTLINE, 0.35))
    # núcleo
    d.polygon([(32, 28), (40, 36), (32, 46), (24, 36)], fill=C("#ff4a6a"))
    d.polygon([(32, 28), (40, 36), (32, 36)], fill=C("#ff9ab0"))
    # ojos
    rect(d, 24, 18, 5, 3, C("#ff4a6a"))
    rect(d, 35, 18, 5, 3, C("#ff4a6a"))
    return outline(im)


def boss_scarab(f):
    im, d = newc(64, 64)
    gold, gold_d, gold_l = C("#e0a020"), C("#a06a10"), C("#ffe27a")
    # patas
    ly = 2 if f else 0
    for (x0, y0, x1, y1) in ((10, 48, 2, 58 - ly), (18, 52, 12, 62 - ly), (46, 52, 52, 62 - ly), (54, 48, 62, 58 - ly)):
        d.line([(x0, y0), (x1, y1)], fill=C("#3a2a10"), width=3)
    d.ellipse([6, 18, 58, 56], fill=gold)
    rect(d, 6, 40, 52, 12, gold)
    d.pieslice([6, 18, 58, 56], 180, 270, fill=gold_l)
    d.chord([6, 30, 58, 60], 0, 180, fill=gold_d)
    rect(d, 31, 18, 2, 34, gold_d)
    for (x, y) in ((16, 30), (22, 40), (42, 40), (48, 30)):
        rect(d, x, y, 4, 4, C("#4ad0b0"))
    # cabeza y cuerno
    d.ellipse([20, 8, 44, 28], fill=C("#2a2438"))
    d.polygon([(29, 10), (32, -2 if False else 0), (35, 10)], fill=C("#d8d0e8"))
    rect(d, 24, 16, 5, 4, C("#ff3a3a"))
    rect(d, 35, 16, 5, 4, C("#ff3a3a"))
    d.polygon([(22, 24), (26, 28), (30, 24)], fill=C("#d8d0e8"))
    d.polygon([(34, 24), (38, 28), (42, 24)], fill=C("#d8d0e8"))
    return outline(im)


def boss_yeti(f):
    im, d = newc(64, 64)
    fur, fur_d, fur_l = C("#e8f4ff"), C("#9cc0e0"), C("#ffffff")
    skin = C("#4a8ad0")
    arm = -5 if f else 0
    # piernas
    rect(d, 16, 50, 13, 12, fur_d)
    rect(d, 35, 50, 13, 12, fur_d)
    rect(d, 14, 58, 6, 4, skin)
    rect(d, 44, 58, 6, 4, skin)
    # brazos
    d.ellipse([0, 22 + arm, 16, 52 + arm], fill=fur)
    d.ellipse([48, 22 + arm, 64, 52 + arm], fill=fur)
    for cx in (4, 59):
        for k in range(3):
            d.polygon([(cx - 3 + k * 3, 50 + arm), (cx - 2 + k * 3, 56 + arm), (cx - 1 + k * 3, 50 + arm)], fill=C("#2a3a5a"))
    # cuerpo peludo
    d.ellipse([8, 18, 56, 58], fill=fur)
    d.ellipse([14, 32, 50, 58], fill=fur_l)
    for x in range(10, 56, 6):
        d.polygon([(x, 54), (x + 3, 60), (x + 6, 54)], fill=fur)
    # cabeza
    d.ellipse([16, 4, 48, 34], fill=fur)
    d.ellipse([20, 12, 44, 32], fill=skin)
    d.polygon([(18, 8), (14, 0), (24, 6)], fill=C("#d8d0b8"))
    d.polygon([(46, 8), (50, 0), (40, 6)], fill=C("#d8d0b8"))
    # ojos furiosos
    d.polygon([(22, 16), (30, 20), (30, 23), (22, 21)], fill=OUTLINE)
    d.polygon([(42, 16), (34, 20), (34, 23), (42, 21)], fill=OUTLINE)
    rect(d, 25, 19, 3, 3, C("#ff4a3a"))
    rect(d, 36, 19, 3, 3, C("#ff4a3a"))
    # boca con colmillos
    rect(d, 24, 26, 16, 6, OUTLINE)
    for x in (26, 30, 34):
        d.polygon([(x, 26), (x + 3, 26), (x + 1, 31)], fill=WHITE)
    return outline(im)


def boss_shadow(f):
    im, d = newc(64, 64)
    cloak, cloak_d, cloak_l = C("#3a1f5a"), C("#1f1038"), C("#5a3a8a")
    w = 2 if f else 0
    # capa
    d.polygon([(32, 6), (52, 30), (60, 62 - w), (52, 56), (44, 62), (36, 55 + w),
               (28, 62), (20, 55), (12, 62 - w), (4, 62), (12, 30)], fill=cloak)
    d.polygon([(32, 6), (52, 30), (60, 62 - w), (52, 56), (44, 62), (36, 55 + w), (32, 60)], fill=cloak_d)
    d.polygon([(32, 6), (12, 30), (4, 62), (14, 50), (20, 20)], fill=cloak_l)
    # capucha
    d.ellipse([20, 8, 44, 36], fill=cloak_d)
    d.ellipse([23, 14, 41, 34], fill=C("#0a0414"))
    # ojos brillantes
    rect(d, 26, 22, 4, 3, C("#ffe05a"))
    rect(d, 34, 22, 4, 3, C("#ffe05a"))
    px(d, 27, 22, WHITE)
    px(d, 35, 22, WHITE)
    # corona
    for x in (23, 28, 33, 38):
        d.polygon([(x, 10), (x + 2, 0 if x in (28, 33) else 3), (x + 4, 10)], fill=C("#ff4a3a"))
    # manos con orbes
    for cx in (6, 58):
        d.ellipse([cx - 5, 36 - w, cx + 5, 46 - w], fill=C("#8a2ad0"))
        d.ellipse([cx - 2, 39 - w, cx + 2, 43 - w], fill=C("#ff5aff"))
    return outline(im)


def gen_bosses():
    fns = [boss_trunk, boss_golem, boss_scarab, boss_yeti, boss_shadow]
    for i, fn in enumerate(fns, start=1):
        save(sheet([fn(0), fn(1)], 64, 64), "bosses", "boss_%d.png" % i)


# ------------------------------------------------------------- FONDOS -----
BW, BH = 480, 400


def ridge(x, amps, phases, ks):
    return sum(a * math.sin(2 * math.pi * k * x / BW + p) for a, p, k in zip(amps, phases, ks))


def bg_far(w):
    P = WORLDS[w]
    im = Image.new("RGBA", (BW, BH), CLEAR)
    d = ImageDraw.Draw(im)
    top, bot = C(P["sky_top"]), C(P["sky_bot"])
    bands = 24
    for y in range(BH):
        t = min(1.0, y / 270.0)
        t = round(t * bands) / bands
        d.line([(0, y), (BW, y)], fill=lerp(top, bot, t))
    rnd = random.Random(w)
    if w == 1:  # nubes
        for _ in range(7):
            cx, cy = rnd.randint(0, BW), rnd.randint(20, 120)
            for k in range(4):
                for dx in (0, -BW, BW):
                    d.ellipse([cx + dx + k * 14 - 10, cy - 8 + (k % 2) * 4, cx + dx + k * 14 + 12, cy + 8], fill=C("#ffffff", 235))
        for dx in (0, -BW):
            d.ellipse([360 + dx, 24, 396 + dx, 60], fill=C("#fff6b0"))
    elif w == 2:  # estrellas/cristales lejanos
        for _ in range(90):
            x, y = rnd.randint(0, BW - 1), rnd.randint(0, 260)
            px(d, x, y, C("#cfe8ff") if rnd.random() < 0.7 else C("#59e0f0"))
    elif w == 3:  # sol
        for dx in (0, -BW):
            d.ellipse([90 + dx, 40, 150 + dx, 100], fill=C("#fff2c0"))
            d.ellipse([100 + dx, 50, 140 + dx, 90], fill=C("#fffbe0"))
        for _ in range(4):
            cx, cy = rnd.randint(0, BW), rnd.randint(30, 110)
            for dx in (0, -BW, BW):
                d.ellipse([cx + dx, cy, cx + dx + 50, cy + 8], fill=C("#ffe8b8", 200))
    elif w == 4:  # copos y sol pálido
        for _ in range(70):
            x, y = rnd.randint(0, BW - 1), rnd.randint(0, 260)
            px(d, x, y, WHITE)
        for dx in (0, -BW):
            d.ellipse([60 + dx, 36, 92 + dx, 68], fill=C("#fffbe8"))
    else:  # luna roja y nubes oscuras
        for dx in (0, -BW):
            d.ellipse([340 + dx, 30, 396 + dx, 86], fill=C("#ff7a5a"))
            d.ellipse([352 + dx, 42, 384 + dx, 74], fill=C("#ffb08a"))
        for _ in range(6):
            cx, cy = rnd.randint(0, BW), rnd.randint(20, 150)
            for dx in (0, -BW, BW):
                d.ellipse([cx + dx, cy, cx + dx + 70, cy + 10], fill=C("#2a1438", 220))
    return im


def silhouette(w, layer):
    P = WORLDS[w]
    im = Image.new("RGBA", (BW, BH), CLEAR)
    d = ImageDraw.Draw(im)
    col = C(P["mid"] if layer == "mid" else P["near"])
    col_l = lerp(col, WHITE, 0.12)
    rnd = random.Random(w * 31 + (1 if layer == "mid" else 2))
    base = 215 if layer == "mid" else 250
    ks = (1, 2, 5) if layer == "mid" else (2, 3, 7)
    amps = (22, 10, 4) if layer == "mid" else (14, 8, 3)
    phases = [rnd.random() * 6.28 for _ in range(3)]
    for x in range(BW):
        h = base - ridge(x, amps, phases, ks) - (40 if layer == "mid" else 0)
        if w == 3 and layer == "mid":
            h = base - 10 - ridge(x, (16, 6, 2), phases, (1, 2, 4))
        d.line([(x, int(h)), (x, BH)], fill=col)
    # elementos temáticos que se repiten (con envoltura horizontal)
    n = 9 if layer == "mid" else 7
    for i in range(n):
        x = int((i + rnd.random() * 0.6) * BW / n)
        y = base - 30
        for dx in (0, -BW, BW):
            xx = x + dx
            if w == 1:  # pinos / arbustos
                hh = 40 if layer == "mid" else 56
                d.polygon([(xx - 14, y + 20), (xx, y - hh + 20), (xx + 14, y + 20)], fill=col_l)
                d.polygon([(xx - 10, y + 6), (xx, y - hh + 8), (xx + 10, y + 6)], fill=col)
            elif w == 2:  # estalactitas / cristales
                hh = rnd.randint(30, 70)
                if layer == "mid":
                    d.polygon([(xx - 8, 0), (xx, hh), (xx + 8, 0)], fill=col)
                else:
                    d.polygon([(xx - 9, y + 30), (xx, y - hh + 30), (xx + 9, y + 30)], fill=col_l)
            elif w == 3:  # pirámides y dunas
                if layer == "mid" and i % 3 == 0:
                    d.polygon([(xx - 46, y + 40), (xx, y - 40), (xx + 46, y + 40)], fill=col_l)
                    d.polygon([(xx, y - 40), (xx + 46, y + 40), (xx, y + 40)], fill=col)
            elif w == 4:  # picos nevados
                hh = 60 if layer == "mid" else 44
                d.polygon([(xx - 34, y + 30), (xx, y - hh + 30), (xx + 34, y + 30)], fill=col)
                d.polygon([(xx - 10, y - hh + 52), (xx, y - hh + 30), (xx + 10, y - hh + 52)], fill=C("#ffffff"))
            else:  # torres de castillo
                if layer == "mid" or i % 2 == 0:
                    tw = 18 if layer == "mid" else 24
                    th = 70 if layer == "mid" else 90
                    d.rectangle([xx - tw // 2, y - th + 30, xx + tw // 2, BH], fill=col_l if layer == "mid" else col)
                    for bx in range(xx - tw // 2, xx + tw // 2, 6):
                        d.rectangle([bx, y - th + 24, bx + 3, y - th + 30], fill=col_l if layer == "mid" else col)
                    px(d, xx, y - th + 44, C("#ffb04a"))
                    px(d, xx, y - th + 60, C("#ffb04a"))
    return im


def gen_backgrounds():
    for w in WORLDS:
        save(bg_far(w), "backgrounds", "bg_w%d_far.png" % w)
        save(silhouette(w, "mid"), "backgrounds", "bg_w%d_mid.png" % w)
        save(silhouette(w, "near"), "backgrounds", "bg_w%d_near.png" % w)


def gen_icon():
    for size, name in ((128, "icon.png"), (192, "icon_192.png")):
        im = Image.new("RGBA", (size, size), CLEAR)
        d = ImageDraw.Draw(im)
        for y in range(size):
            d.line([(0, y), (size, y)], fill=lerp(C("#5ab8f0"), C("#c8f0ff"), y / size))
        d.rectangle([0, int(size * 0.78), size, size], fill=C("#58c84a"))
        d.rectangle([0, int(size * 0.86), size, size], fill=C("#8a5a33"))
        hero = hero_frame("idle", 0).resize((int(size * 0.7),) * 2, Image.NEAREST)
        im.alpha_composite(hero, (int(size * 0.15), int(size * 0.12)))
        # esquinas redondeadas
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, size - 1, size - 1], radius=size // 6, fill=255)
        im.putalpha(mask)
        im.save(os.path.join(ROOT, name))


def main():
    gen_hero()
    gen_tiles()
    gen_decor()
    gen_items()
    gen_ui_icons()
    gen_enemies()
    gen_bosses()
    gen_backgrounds()
    gen_icon()
    print("arte generado en", ASSETS)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Fondos con parallax de 3 capas y 4 zonas visuales por mundo (mañana/mediodía/atardecer y arena del jefe).

assets/backgrounds/bg_w{M}_z{Z}_{far,mid,near}.png  (480x400, se repiten en horizontal)
La capa lejana es siempre totalmente opaca (cielo completo); las otras son siluetas con transparencia.
"""
import math
import random

from PIL import Image, ImageDraw

import gen_art as ga
from gen_art import C, CLEAR, BH, BW, save

lerp = ga.lerp


def shade(col, t):
    if t >= 0:
        return tuple(int(col[i] + (255 - col[i]) * t) for i in range(3)) + (col[3],)
    return tuple(int(col[i] * (1 + t)) for i in range(3)) + (col[3],)


# ---------------------------------------------------------------- tabla ---
# far: lista de elementos del cielo; mid/near: (tipo, cantidad, color principal, color secundario)
Z = {}
Z[1] = [
    dict(top="#5ab8f0", bot="#c8f0ff", far=[("sun", 390, 52, 26, "#fff6b0"), ("clouds", 7, "#ffffff", 235)],
         mid=("tree", 8, "#4fa86a", "#8ae08a"), near=("bush", 9, "#2f7f4d", "#58c84a"), rm="#4fa86a", rn="#2f7f4d"),
    dict(top="#6ec6ff", bot="#e0fbff", far=[("sun", 90, 46, 22, "#fffbd0"), ("clouds", 5, "#ffffff", 235)],
         mid=("cliff", 5, "#6a9a78", "#c8f0ff"), near=("giant", 5, "#2f6a45", "#4a9a5a"), rm="#6a9a78", rn="#2f6a45"),
    dict(top="#ff9a5a", bot="#ffe0a0", far=[("sun", 330, 150, 40, "#fff0b0"), ("clouds", 5, "#ffc890", 220), ("stars", 0)],
         mid=("tree", 8, "#3a6a5a", "#6aa87a"), near=("pine", 8, "#254a3a", "#3a7a50"), rm="#3a6a5a", rn="#254a3a"),
    dict(top="#12301e", bot="#5a9a4a", far=[("godrays", 6, "#f0ffb0"), ("clouds", 3, "#a0d890", 150)],
         mid=("giant", 6, "#2a6a3a", "#4a9a5a"), near=("giant", 5, "#173a25", "#2a6a3a"), rm="#2a6a3a", rn="#173a25"),
]
Z[2] = [
    dict(top="#140a2c", bot="#3a2370", far=[("stars", 90, "#cfe8ff")], mid=("stalac", 9, "#33276a", "#5a4aa0"),
         near=("crystal", 8, "#4a3a9a", "#59e0f0"), rm="#33276a", rn="#221a4a"),
    dict(top="#06223a", bot="#1a6a8a", far=[("glow", "#59f0ff", 70), ("stars", 50, "#b0f8ff")],
         mid=("crystal", 8, "#1a5a7a", "#59e0f0"), near=("stalac", 8, "#0e3a56", "#2a9ab0"), rm="#1a5a7a", rn="#0e3a56"),
    dict(top="#2a0a3a", bot="#8a2aa0", far=[("glow", "#ff7af0", 60), ("stars", 60, "#ffd0ff")],
         mid=("crystal", 9, "#6a2a8a", "#e08aff"), near=("crystal", 7, "#3a1450", "#b050e0"), rm="#6a2a8a", rn="#3a1450"),
    dict(top="#0a0a1a", bot="#4a1a6a", far=[("glow", "#c080ff", 90), ("stars", 70, "#e8d0ff")],
         mid=("crystal", 7, "#3a1a6a", "#b080ff"), near=("stalac", 7, "#1a0a30", "#7a4ac0"), rm="#3a1a6a", rn="#1a0a30"),
]
Z[3] = [
    dict(top="#f59a4a", bot="#ffe3a0", far=[("sun", 120, 70, 30, "#fff2c0"), ("clouds", 4, "#ffe8b8", 200)],
         mid=("pyramid", 5, "#d89a4a", "#f0c070"), near=("dune", 6, "#b87a34", "#d89a4a"), rm="#e0a85a", rn="#b87a34"),
    dict(top="#e07a5a", bot="#ffd2a0", far=[("sun", 380, 60, 26, "#ffe8c0")],
         mid=("mesa", 6, "#b8603a", "#e08a5a"), near=("palm", 7, "#7a4a24", "#3a9a4a"), rm="#c8704a", rn="#8a4a2a"),
    dict(top="#2a1a4a", bot="#e08a4a", far=[("stars", 60, "#ffe8d0"), ("sun", 300, 130, 36, "#ffd090")],
         mid=("column", 8, "#7a4a3a", "#c88a5a"), near=("dune", 6, "#5a3424", "#8a5a34"), rm="#6a3a30", rn="#4a2a20"),
    dict(top="#4a0a0a", bot="#f0a04a", far=[("sun", 240, 120, 64, "#ffd080"), ("clouds", 3, "#a04a2a", 200)],
         mid=("pyramid", 3, "#6a2a1a", "#a04a2a"), near=("column", 7, "#3a1410", "#6a2a1a"), rm="#7a3020", rn="#3a1410"),
]
Z[4] = [
    dict(top="#9cc8f0", bot="#f0faff", far=[("sun", 70, 52, 20, "#fffbe8"), ("clouds", 4, "#ffffff", 220)],
         mid=("mountain", 7, "#9cc4e8", "#ffffff"), near=("pine", 8, "#6a9cd0", "#ffffff"), rm="#9cc4e8", rn="#6a9cd0"),
    dict(top="#1a3a6a", bot="#7ac0e0", far=[("aurora",), ("stars", 70, "#ffffff")],
         mid=("glacier", 6, "#5a9ac8", "#c8f0ff"), near=("icicle", 9, "#3a7ab0", "#a8e0ff"), rm="#5a9ac8", rn="#3a7ab0"),
    dict(top="#8a9ab0", bot="#d0dcea", far=[("clouds", 8, "#e8f0f8", 200)],
         mid=("mountain", 6, "#7a90b0", "#ffffff"), near=("rocks", 8, "#5a708f", "#9ab0cf"), rm="#7a90b0", rn="#5a708f"),
    dict(top="#0a2050", bot="#6aa0e0", far=[("aurora",), ("stars", 90, "#ffffff"), ("sun", 360, 70, 30, "#e8f8ff")],
         mid=("glacier", 5, "#3a6aa0", "#b0e0ff"), near=("mountain", 6, "#1a3a70", "#a0d0ff"), rm="#3a6aa0", rn="#1a3a70"),
]
Z[5] = [
    dict(top="#12081c", bot="#4a1f42", far=[("sun", 360, 56, 28, "#ff7a5a"), ("clouds", 6, "#2a1438", 220)],
         mid=("castle", 7, "#3a2450", "#6a4a8a"), near=("grave", 8, "#1c1028", "#4a3a60"), rm="#2a1a3c", rn="#1c1028"),
    dict(top="#0a0610", bot="#2a1838", far=[("glow", "#ff8a2a", 40)],
         mid=("arch", 6, "#24183a", "#5a3a7a"), near=("chains", 8, "#120a1c", "#4a3a60"), rm="#24183a", rn="#120a1c"),
    dict(top="#1a0a2a", bot="#7a2a4a", far=[("sun", 120, 70, 34, "#ff5a4a"), ("clouds", 6, "#3a1a3a", 220)],
         mid=("spire", 8, "#2a1a3c", "#5a3a7a"), near=("castle", 6, "#160c22", "#3a2a50"), rm="#2a1a3c", rn="#160c22"),
    dict(top="#200808", bot="#6a1a2a", far=[("sun", 240, 100, 52, "#ff4a3a"), ("clouds", 5, "#2a0a14", 230)],
         mid=("spire", 6, "#3a1020", "#7a2a3a"), near=("castle", 4, "#1a060c", "#4a1a2a"), rm="#3a1020", rn="#1a060c"),
]
Z[6] = [
    dict(top="#3a8ee8", bot="#d8f4ff", far=[("sun", 400, 40, 22, "#fffbe0"), ("clouds", 9, "#ffffff", 230)],
         mid=("island", 6, "#9ccaf0", "#4aa84a"), near=("cloudbank", 6, "#ffffff", "#d8ecff"), rm="#c8e4ff", rn="#ffffff"),
    dict(top="#6ab0f0", bot="#fff0d0", far=[("sun", 90, 120, 44, "#fff6c0"), ("clouds", 7, "#ffe8d0", 230)],
         mid=("windmill", 6, "#8ab4e0", "#fff0d0"), near=("cloudbank", 6, "#fff4e0", "#ffe0c0"), rm="#c8dcf0", rn="#fff4e0"),
    dict(top="#2a4a9a", bot="#f0a0c0", far=[("sun", 300, 140, 36, "#ffe0a0"), ("clouds", 6, "#ffc0d0", 230)],
         mid=("island", 6, "#7a88c8", "#4a9a6a"), near=("cloudbank", 6, "#ffd0e0", "#f0a0c0"), rm="#a8b0e0", rn="#ffd0e0"),
    dict(top="#1a2a5a", bot="#6a8ad0", far=[("clouds", 8, "#3a4a7a", 235), ("glow", "#8aa0ff", 50)],
         mid=("island", 5, "#4a5a9a", "#5a8a6a"), near=("cloudbank", 6, "#5a6aa0", "#3a4a80"), rm="#5a6aa0", rn="#3a4a80"),
]
Z[7] = [
    dict(top="#2a0a0a", bot="#d8501a", far=[("volcano_far", 330), ("embers", 70)],
         mid=("volcano", 5, "#5a1a1a", "#ff7a1a"), near=("rocks", 7, "#240a0a", "#4a1818"), rm="#3a1212", rn="#240a0a"),
    dict(top="#3a0a0a", bot="#ff7a2a", far=[("glow", "#ff9a2a", 90), ("embers", 60)],
         mid=("lavacliff", 5, "#4a1612", "#ff8a2a"), near=("spire", 7, "#1c0808", "#5a2018"), rm="#4a1612", rn="#1c0808"),
    dict(top="#1a0a14", bot="#9a2a1a", far=[("glow", "#ff5a1a", 70), ("embers", 50)],
         mid=("stalac", 9, "#3a1418", "#8a3a22"), near=("crystal", 7, "#1a0a0c", "#6a2018"), rm="#3a1418", rn="#1a0a0c"),
    dict(top="#300808", bot="#ff9a2a", far=[("volcano_far", 240), ("glow", "#ffcc4a", 100), ("embers", 90)],
         mid=("volcano", 3, "#3a0e0e", "#ffa02a"), near=("spire", 6, "#180606", "#4a1a14"), rm="#3a0e0e", rn="#180606"),
]
Z[8] = [
    dict(top="#1a5a3a", bot="#a8e88a", far=[("godrays", 7, "#f0ffb0"), ("stars", 40, "#d8ff8a")],
         mid=("giant", 7, "#2a7a4a", "#4ab070"), near=("fern", 9, "#134226", "#2a8a3a"), rm="#2a7a4a", rn="#134226"),
    dict(top="#2a4a3a", bot="#9ab88a", far=[("clouds", 6, "#c8d8b8", 170), ("stars", 30, "#d8ff8a")],
         mid=("tree", 8, "#3a5a40", "#6a8a60"), near=("reed", 12, "#1a3a28", "#4a7a44"), rm="#3a5a40", rn="#1a3a28"),
    dict(top="#1a6a5a", bot="#c0f0a0", far=[("godrays", 5, "#fffec0"), ("clouds", 3, "#e0fcd0", 150)],
         mid=("ruin", 6, "#2a6a5a", "#7ac090"), near=("giant", 5, "#0e3a2e", "#2a7a5a"), rm="#2a6a5a", rn="#0e3a2e"),
    dict(top="#0a2a1a", bot="#4a8a3a", far=[("godrays", 5, "#a0ff90"), ("stars", 50, "#c8ff6a")],
         mid=("giant", 6, "#14442a", "#2a8a4a"), near=("giant", 5, "#082014", "#1a5a30"), rm="#14442a", rn="#082014"),
]
Z[9] = [
    dict(top="#1a2a3a", bot="#6a8a9a", far=[("smoke", 6, "#7a8a96", 150), ("gears", 3)],
         mid=("chimney", 7, "#3a5060", "#6a8090"), near=("gear", 5, "#1c2a36", "#3a5060"), rm="#2a3c4a", rn="#1c2a36"),
    dict(top="#3a3a3a", bot="#9a9a8a", far=[("smoke", 9, "#c8c8c0", 170)],
         mid=("factory", 5, "#4a5058", "#8a9098"), near=("pipes", 8, "#2a3036", "#5a6068"), rm="#4a5058", rn="#2a3036"),
    dict(top="#1a1a2a", bot="#5a4a6a", far=[("stars", 40, "#ffb0b0"), ("glow", "#ff5a5a", 40)],
         mid=("antenna", 8, "#2a2a3e", "#5a5a7a"), near=("girder", 7, "#14141e", "#3a3a52"), rm="#2a2a3e", rn="#14141e"),
    dict(top="#200a0a", bot="#5a2a2a", far=[("glow", "#ff4a2a", 100), ("smoke", 6, "#6a3a3a", 170)],
         mid=("chimney", 5, "#3a1c1c", "#7a3a3a"), near=("gear", 4, "#180808", "#4a2020"), rm="#3a1c1c", rn="#180808"),
]
Z[10] = [
    dict(top="#06020e", bot="#2a1060", far=[("stars", 160, "#ffffff"), ("nebula", "#5a2a9a"), ("nebula2", "#9a2a7a")],
         mid=("spire", 8, "#2a1458", "#6a3ab0"), near=("column", 7, "#12082a", "#3a2470"), rm="#1e0e44", rn="#12082a"),
    dict(top="#0a0a2a", bot="#4a2a8a", far=[("stars", 120, "#ffd23a"), ("nebula", "#2a4ab0")],
         mid=("island", 6, "#3a2a7a", "#8a5ad0"), near=("arch", 6, "#160c36", "#4a3a8a"), rm="#2a1a60", rn="#160c36"),
    dict(top="#1a0a2a", bot="#c08a30", far=[("sun", 240, 140, 50, "#ffe080"), ("clouds", 5, "#a06a30", 200)],
         mid=("fortress", 5, "#4a2a50", "#e0b050"), near=("spire", 6, "#201030", "#7a4a40"), rm="#4a2a50", rn="#201030"),
    dict(top="#10021a", bot="#6a1a5a", far=[("sun", 240, 100, 72, "#ffd0f0"), ("stars", 100, "#ffffff"), ("glow", "#ff5ad0", 90)],
         mid=("fortress", 3, "#2a0a3a", "#a04a90"), near=("spire", 5, "#0a0214", "#4a1a50"), rm="#2a0a3a", rn="#0a0214"),
]


# ----------------------------------------------------------------- cielo ---
def sky(top, bot):
    im = Image.new("RGBA", (BW, BH), CLEAR)
    d = ImageDraw.Draw(im)
    t, b = C(top), C(bot)
    for y in range(BH):
        k = min(1.0, y / 270.0)
        k = round(k * 24) / 24
        d.line([(0, y), (BW, y)], fill=lerp(t, b, k))
    return im


def far_layer(w, zi, cfg):
    base = sky(cfg["top"], cfg["bot"])
    over = Image.new("RGBA", (BW, BH), CLEAR)
    d = ImageDraw.Draw(over)
    rnd = random.Random(w * 100 + zi)
    for el in cfg["far"]:
        k = el[0]
        if k == "sun":
            _, cx, cy, r, col = el
            for dx in (0, -BW, BW):
                d.ellipse([cx + dx - r - 8, cy - r - 8, cx + dx + r + 8, cy + r + 8], fill=C(col, 50))
                d.ellipse([cx + dx - r, cy - r, cx + dx + r, cy + r], fill=C(col))
                d.ellipse([cx + dx - r // 2, cy - r // 2, cx + dx + r // 2, cy + r // 2], fill=shade(C(col), 0.5))
        elif k == "clouds":
            _, n, col, a = el
            for _i in range(n):
                cx, cy = rnd.randint(0, BW), rnd.randint(20, 170)
                for dx in (0, -BW, BW):
                    for q in range(4):
                        d.ellipse([cx + dx + q * 14 - 10, cy - 8 + (q % 2) * 4, cx + dx + q * 14 + 12, cy + 8], fill=C(col, a))
        elif k == "stars":
            _, n, *rest = el + (None,)
            col = rest[0] if rest and rest[0] else "#ffffff"
            for _i in range(n):
                x, y = rnd.randint(0, BW - 1), rnd.randint(0, 250)
                ga.px(d, x, y, C(col))
        elif k == "glow":
            _, col, a = el
            for r in range(8):
                yy = 270 - r * 22
                d.rectangle([0, yy, BW, yy + 22], fill=C(col, max(6, a // 8)))
        elif k == "godrays":
            _, n, col = el
            for _i in range(n):
                x = rnd.randint(0, BW)
                for dx in (0, -BW, BW):
                    d.polygon([(x + dx, 0), (x + dx + 14, 0), (x + dx + 50, 270), (x + dx + 22, 270)], fill=C(col, 30))
        elif k == "aurora":
            for band, col in enumerate(("#4aff9a", "#4ac0ff", "#9a6aff")):
                for x in range(0, BW, 2):
                    y = 60 + band * 18 + int(18 * math.sin(x / 38.0 + band))
                    d.line([(x, y), (x, y + 44)], fill=C(col, 38))
        elif k == "nebula" or k == "nebula2":
            col = el[1]
            cx, cy, r = (120, 100, 60) if k == "nebula" else (330, 70, 70)
            for dx in (0, -BW):
                for q in range(5):
                    d.ellipse([cx + dx - r + q * 6, cy - r // 2 + q * 3, cx + dx + r - q * 6, cy + r // 2 - q * 3], fill=C(col, 40))
        elif k == "volcano_far":
            cx = el[1]
            for dx in (0, -BW):
                d.polygon([(cx + dx - 70, 270), (cx + dx, 120), (cx + dx + 70, 270)], fill=C("#4a1410"))
                d.polygon([(cx + dx - 12, 126), (cx + dx, 112), (cx + dx + 14, 128)], fill=C("#ff7a1a"))
        elif k == "embers":
            for _i in range(el[1]):
                ga.px(d, rnd.randint(0, BW - 1), rnd.randint(0, 260), C("#ffb05a") if rnd.random() < 0.3 else C("#5a2a22"))
        elif k == "smoke":
            _, n, col, a = el
            for _i in range(n):
                cx, cy = rnd.randint(0, BW), rnd.randint(30, 170)
                for dx in (0, -BW, BW):
                    d.ellipse([cx + dx, cy, cx + dx + 60, cy + 14], fill=C(col, a))
        elif k == "gears":
            for (cx, cy, r) in ((90, 90, 34), (250, 60, 24), (400, 110, 40))[: el[1]]:
                for dx in (0, -BW):
                    d.ellipse([cx + dx - r, cy - r, cx + dx + r, cy + r], outline=C("#4a6070"), width=4)
                    for q in range(8):
                        a = q * math.pi / 4
                        d.line([(cx + dx, cy), (cx + dx + r * math.cos(a), cy + r * math.sin(a))], fill=C("#4a6070"), width=3)
    base.alpha_composite(over)
    lo = min(base.getchannel("A").getdata())
    assert lo == 255, "bg_w%d_z%d_far tiene píxeles transparentes (alfa %d)" % (w, zi, lo)
    return base


# ------------------------------------------------------------- siluetas ---
def feature(d, kind, x, base, s, c1, c2, rnd, layer):
    """Un elemento temático apoyado en `base` (y), con escala s."""
    c1, c2 = C(c1), C(c2)
    dk = shade(c1, -0.25)
    if kind == "tree":
        h = int(46 * s)
        d.rectangle([x - 3, base - h // 2, x + 3, base + 40], fill=dk)
        for (ox, oy, r) in ((0, -h, 0.5), (-12, -h + 12, 0.38), (12, -h + 12, 0.38)):
            rr = int(h * r)
            d.ellipse([x + ox - rr, base + oy - rr // 2 - 10, x + ox + rr, base + oy + rr // 2 + 10], fill=c1)
        d.ellipse([x - 8, base - h - 6, x + 6, base - h + 4], fill=c2)
    elif kind == "pine":
        h = int(54 * s)
        d.rectangle([x - 2, base - 6, x + 2, base + 40], fill=dk)
        for k in range(4):
            y1 = base - h + k * (h // 4)
            hw = int((8 + k * 5) * s)
            d.polygon([(x - hw, y1 + h // 3), (x, y1), (x + hw, y1 + h // 3)], fill=c1)
            d.polygon([(x - hw + 3, y1 + h // 6), (x, y1), (x + hw - 3, y1 + h // 6)], fill=c2)
    elif kind == "giant":
        tw = int(14 * s)
        d.rectangle([x - tw // 2, 0, x + tw // 2, BH], fill=c1)
        d.rectangle([x - tw // 2, 0, x - tw // 2 + 3, BH], fill=c2)
        d.ellipse([x - 38, -26, x + 38, 40], fill=shade(c1, -0.1))
        d.ellipse([x - 22, -10, x + 30, 52], fill=c1)
        for vx in (x - tw // 2 - 6, x + tw // 2 + 4):
            d.line([(vx, 30), (vx + 3, 90 + rnd.randint(0, 40))], fill=c2, width=2)
    elif kind == "cliff":
        w2 = int(34 * s)
        h = int(110 * s)
        d.polygon([(x - w2, base + 40), (x - w2 + 8, base - h), (x + w2 - 10, base - h + 6), (x + w2, base + 40)], fill=c1)
        d.rectangle([x - 4, base - h + 6, x + 4, base + 40], fill=c2)  # cascada lejana
        d.rectangle([x - 1, base - h + 6, x + 1, base + 40], fill=shade(c2, 0.5))
    elif kind == "crystal":
        for (ox, hh, ww) in ((-8, 40, 6), (0, 62, 8), (9, 34, 6)):
            hh = int(hh * s)
            d.polygon([(x + ox - ww, base + 30), (x + ox, base + 30 - hh - 20), (x + ox + ww, base + 30)], fill=c1)
            d.polygon([(x + ox, base + 30 - hh - 20), (x + ox + ww, base + 30), (x + ox, base + 30)], fill=shade(c1, -0.25))
            ga.px(d, x + ox - 2, base + 30 - hh // 2, c2)
    elif kind == "stalac":
        for (ox, hh, ww) in ((-9, 60, 8), (0, 90, 10), (11, 48, 7)):
            hh = int(hh * s * (0.7 + 0.5 * rnd.random()))
            d.polygon([(x + ox - ww, 0), (x + ox, hh), (x + ox + ww, 0)], fill=c1)
            d.polygon([(x + ox, 0), (x + ox, hh), (x + ox + ww, 0)], fill=shade(c1, -0.22))
        ga.px(d, x, 30, c2)
    elif kind == "pyramid":
        w2 = int(64 * s)
        d.polygon([(x - w2, base + 40), (x, base - int(70 * s)), (x + w2, base + 40)], fill=c2)
        d.polygon([(x, base - int(70 * s)), (x + w2, base + 40), (x, base + 40)], fill=c1)
    elif kind == "dune":
        w2 = int(70 * s)
        d.ellipse([x - w2, base - int(26 * s), x + w2, base + 80], fill=c1)
        d.ellipse([x - w2 // 2, base - int(30 * s), x + w2 // 2, base + 40], fill=c2)
    elif kind == "mesa":
        w2 = int(46 * s)
        h = int(70 * s)
        d.polygon([(x - w2, base + 40), (x - w2 + 6, base - h), (x + w2 - 6, base - h), (x + w2, base + 40)], fill=c1)
        d.rectangle([x - w2 + 6, base - h, x + w2 - 6, base - h + 6], fill=c2)
        for k in range(3):
            d.line([(x - w2 + 4, base - h + 18 + k * 14), (x + w2 - 4, base - h + 18 + k * 14)], fill=shade(c1, -0.2))
    elif kind == "palm":
        h = int(70 * s)
        d.line([(x, base + 30), (x + 4, base - h)], fill=c1, width=4)
        for ang in (-2.7, -2.1, -1.5, -0.9, -0.3):
            d.line([(x + 4, base - h), (x + 4 + math.cos(ang) * 30 * s, base - h - math.sin(ang) * 10 * s + 6)], fill=c2, width=3)
    elif kind == "column":
        h = int(70 * s)
        cw = int(11 * s)
        d.rectangle([x - cw, base - h, x + cw, base + 40], fill=c2)
        d.rectangle([x - cw - 3, base - h - 6, x + cw + 3, base - h + 2], fill=c1)
        d.rectangle([x - cw + 2, base - h, x - cw + 4, base + 40], fill=shade(c2, 0.3))
    elif kind == "mountain":
        w2 = int(58 * s)
        h = int(110 * s)
        d.polygon([(x - w2, base + 40), (x, base - h), (x + w2, base + 40)], fill=c1)
        d.polygon([(x - w2 // 3, base - h * 2 // 3), (x, base - h), (x + w2 // 3, base - h * 2 // 3), (x + 4, base - h * 2 // 3 + 8), (x - 4, base - h * 2 // 3 + 6)], fill=c2)
    elif kind == "glacier":
        for (ox, ww, hh) in ((-18, 20, 50), (0, 24, 80), (20, 18, 40)):
            hh = int(hh * s)
            d.polygon([(x + ox - ww, base + 40), (x + ox - ww + 6, base - hh), (x + ox + ww - 4, base - hh + 10), (x + ox + ww, base + 40)], fill=c1)
            d.line([(x + ox - ww + 6, base - hh), (x + ox + ww - 4, base - hh + 10)], fill=c2, width=2)
    elif kind == "icicle":
        for (ox, hh, ww) in ((-8, 40, 5), (0, 64, 6), (9, 34, 4)):
            hh = int(hh * s)
            d.polygon([(x + ox - ww, 0), (x + ox, hh), (x + ox + ww, 0)], fill=c1)
            d.line([(x + ox, 2), (x + ox, hh - 4)], fill=c2)
    elif kind == "castle":
        tw = int(22 * s)
        th = int(96 * s)
        d.rectangle([x - tw // 2, base - th, x + tw // 2, base + 40], fill=c1)
        for bx in range(x - tw // 2, x + tw // 2, 6):
            d.rectangle([bx, base - th - 6, bx + 3, base - th], fill=c1)
        d.rectangle([x - tw // 2 - 12, base - th // 2, x - tw // 2, base + 40], fill=c1)
        for yy in (base - th + 22, base - th + 46):
            ga.px(d, x, yy, C("#ffb04a"))
            ga.px(d, x, yy + 1, C("#ffb04a"))
    elif kind == "spire":
        tw = int(14 * s)
        th = int(100 * s)
        d.rectangle([x - tw // 2, base - th, x + tw // 2, base + 40], fill=c1)
        d.polygon([(x - tw // 2 - 4, base - th), (x, base - th - int(34 * s)), (x + tw // 2 + 4, base - th)], fill=c1)
        d.rectangle([x - 1, base - th + 18, x + 1, base - th + 28], fill=c2)
        d.rectangle([x - 1, base - th + 44, x + 1, base - th + 54], fill=c2)
    elif kind == "arch":
        cw = int(12 * s)
        gap = int(38 * s)
        h = int(86 * s)
        for sx in (-gap, gap):
            d.rectangle([x + sx - cw // 2, base - h, x + sx + cw // 2, base + 40], fill=c1)
        d.pieslice([x - gap - cw // 2, base - h - gap, x + gap + cw // 2, base - h + gap], 180, 360, fill=c1)
        d.pieslice([x - gap + cw // 2, base - h - gap + 10, x + gap - cw // 2, base - h + gap - 10], 180, 360, fill=CLEAR)
        ga.px(d, x, base - h - gap + 6, c2)
    elif kind == "chains":
        for k in range(3):
            xx = x - 14 + k * 14
            for yy in range(0, 70 + k * 18, 6):
                d.rectangle([xx, yy, xx + 2, yy + 3], fill=c1)
            d.ellipse([xx - 3, 70 + k * 18, xx + 5, 80 + k * 18], fill=c2)
    elif kind == "grave":
        d.rectangle([x - 1, base - 18, x + 1, base + 40], fill=c1)
        d.rectangle([x - 7, base - 14, x + 7, base - 11], fill=c1)
        d.ellipse([x + 16, base - 4, x + 28, base + 20], fill=c1)
        d.rectangle([x + 18, base + 6, x + 26, base + 40], fill=c1)
        if rnd.random() < 0.5:
            d.line([(x - 30, base + 20), (x - 30, base - 20), (x - 22, base - 34)], fill=c1, width=2)
    elif kind == "island":
        rw = int(rnd.randint(28, 46) * s)
        y = base - 110 + rnd.randint(-10, 50)
        d.polygon([(x - rw, y), (x + rw, y), (x + rw // 2, y + rw), (x, y + rw + 14), (x - rw // 2, y + rw)], fill=c1)
        d.rectangle([x - rw, y - 6, x + rw, y], fill=c2)
        d.polygon([(x - 6, y - 6), (x, y - 26), (x + 6, y - 6)], fill=shade(c2, -0.3))
        if rnd.random() < 0.5:
            d.rectangle([x + rw // 2, y + 4, x + rw // 2 + 3, base + 40], fill=C("#ffffff", 120))
    elif kind == "cloudbank":
        for q in range(4):
            d.ellipse([x - 34 + q * 16, base - 8 - (q % 2) * 8, x + 10 + q * 16, base + 46], fill=c1)
        d.ellipse([x - 20, base + 10, x + 40, base + 60], fill=c2)
    elif kind == "windmill":
        h = int(70 * s)
        d.polygon([(x - 8, base + 40), (x - 5, base - h), (x + 5, base - h), (x + 8, base + 40)], fill=c1)
        d.polygon([(x - 8, base - h), (x, base - h - 12), (x + 8, base - h)], fill=c2)
        for a in (0.4, 2.0, 3.6, 5.2):
            d.line([(x, base - h), (x + math.cos(a) * 28, base - h + math.sin(a) * 28)], fill=c2, width=3)
    elif kind == "volcano":
        w2 = int(60 * s)
        h = int(100 * s)
        d.polygon([(x - w2, base + 40), (x - 10, base - h), (x + 10, base - h), (x + w2, base + 40)], fill=c1)
        d.polygon([(x - 10, base - h), (x + 10, base - h), (x + 5, base - h + 10), (x - 5, base - h + 10)], fill=c2)
        d.line([(x, base - h + 10), (x - 8, base)], fill=c2, width=2)
    elif kind == "lavacliff":
        w2 = int(40 * s)
        h = int(100 * s)
        d.polygon([(x - w2, base + 40), (x - w2 + 10, base - h), (x + w2 - 6, base - h + 10), (x + w2, base + 40)], fill=c1)
        d.rectangle([x - 3, base - h + 10, x + 3, base + 40], fill=c2)
    elif kind == "fern":
        for ang in (-2.4, -1.9, -1.4, -0.9, -0.4):
            d.line([(x, base + 30), (x + math.cos(ang) * 34 * s, base + 30 + math.sin(ang) * 40 * s)], fill=c1, width=4)
            d.line([(x, base + 30), (x + math.cos(ang) * 28 * s, base + 30 + math.sin(ang) * 32 * s)], fill=c2, width=1)
    elif kind == "reed":
        for k in range(5):
            xx = x - 8 + k * 4
            d.line([(xx, base + 40), (xx + (k - 2), base - 26 - (k % 3) * 8)], fill=c1, width=2)
        d.ellipse([x - 3, base - 38, x + 3, base - 22], fill=c2)
    elif kind == "ruin":
        for (ox, hh) in ((-14, 50), (0, 74), (16, 38)):
            hh = int(hh * s)
            d.rectangle([x + ox - 7, base - hh, x + ox + 7, base + 40], fill=c1)
            d.rectangle([x + ox - 9, base - hh - 4, x + ox + 9, base - hh], fill=c2)
        d.ellipse([x - 22, base - 80, x + 22, base - 56], fill=shade(c1, -0.1))
    elif kind == "chimney":
        cw = int(16 * s)
        ch = int(70 * s)
        d.rectangle([x - cw // 2, base - ch, x + cw // 2, base + 40], fill=c1)
        d.rectangle([x - cw // 2 - 3, base - ch - 6, x + cw // 2 + 3, base - ch + 2], fill=c2)
        d.line([(x - 60, base - 10), (x - cw // 2, base - 10)], fill=c2, width=4)
        d.ellipse([x - 10, base - ch - 22, x + 22, base - ch + 4], fill=C("#8a9aa6", 110))
    elif kind == "factory":
        fw = int(50 * s)
        d.rectangle([x - fw, base - 40, x + fw, base + 40], fill=c1)
        d.polygon([(x - fw, base - 40), (x - fw // 2, base - 62), (x, base - 40), (x + fw // 2, base - 62), (x + fw, base - 40)], fill=c1)
        for q in range(4):
            d.rectangle([x - fw + 8 + q * 22, base - 24, x - fw + 16 + q * 22, base - 14], fill=c2)
    elif kind == "antenna":
        h = int(110 * s)
        d.line([(x, base + 40), (x, base - h)], fill=c1, width=4)
        for k in range(3):
            d.line([(x - 12 + k * 4, base - h + 14 + k * 18), (x + 12 - k * 4, base - h + 14 + k * 18)], fill=c1, width=2)
        d.ellipse([x - 4, base - h - 6, x + 4, base - h + 2], fill=c2)
    elif kind == "girder":
        h = int(90 * s)
        d.rectangle([x - 4, base - h, x + 4, base + 40], fill=c1)
        for yy in range(base - h, base + 40, 12):
            d.line([(x - 4, yy), (x + 20, yy + 12)], fill=c2, width=2)
        d.rectangle([x - 4, base - h, x + 40, base - h + 5], fill=c1)
    elif kind == "gear":
        r = int(28 * s)
        d.ellipse([x - r, base - r, x + r, base + r], outline=c2, width=5)
        for q in range(8):
            a = q * math.pi / 4
            d.line([(x, base), (x + r * math.cos(a), base + r * math.sin(a))], fill=c2, width=3)
            d.ellipse([x + (r + 3) * math.cos(a) - 4, base + (r + 3) * math.sin(a) - 4, x + (r + 3) * math.cos(a) + 4, base + (r + 3) * math.sin(a) + 4], fill=c2)
        d.ellipse([x - 6, base - 6, x + 6, base + 6], fill=c1)
    elif kind == "pipes":
        d.rectangle([x - 40, base - 4, x + 40, base + 2], fill=c1)
        d.rectangle([x - 40, base - 4, x + 40, base - 2], fill=c2)
        d.rectangle([x - 6, base - 40, x + 2, base + 40], fill=c1)
        d.rectangle([x + 30, base - 24, x + 36, base + 40], fill=c1)
    elif kind == "fortress":
        fw = int(54 * s)
        d.rectangle([x - fw, base - 30, x + fw, base + 40], fill=c1)
        for (ox, hh) in ((-fw, 80), (-fw // 3, 100), (fw // 3, 100), (fw, 80)):
            d.rectangle([x + ox - 8, base - hh, x + ox + 8, base + 40], fill=c1)
            d.polygon([(x + ox - 10, base - hh), (x + ox, base - hh - 24), (x + ox + 10, base - hh)], fill=c2)
        for q in range(5):
            ga.px(d, x - 36 + q * 18, base - 16, C("#ffe080"))
    elif kind == "rocks":
        for (ox, rr) in ((-14, 16), (4, 22), (22, 14)):
            d.ellipse([x + ox - rr, base - rr // 2 + 10, x + ox + rr, base + rr + 30], fill=c1)
        d.arc([x - 8, base - 6, x + 14, base + 22], 200, 300, fill=c2)
    elif kind == "bush":
        for (ox, rr) in ((-16, 14), (0, 20), (18, 15)):
            d.ellipse([x + ox - rr, base - rr + 20, x + ox + rr, base + rr + 30], fill=c1)
        ga.px(d, x - 8, base + 8, c2)
        ga.px(d, x + 10, base + 6, c2)
        ga.px(d, x, base + 2, c2)


def layer_img(w, zi, cfg, which):
    kind, n, c1, c2 = cfg[which]
    rc = cfg["rm"] if which == "mid" else cfg["rn"]
    im = Image.new("RGBA", (BW, BH), CLEAR)
    d = ImageDraw.Draw(im)
    rnd = random.Random(w * 1000 + zi * 10 + (1 if which == "mid" else 2))
    base = 225 if which == "mid" else 255
    ks = (1, 2, 5) if which == "mid" else (2, 3, 7)
    amps = (20, 9, 3) if which == "mid" else (13, 7, 3)
    phases = [rnd.random() * 6.28 for _ in range(3)]
    col = C(rc)
    hang = kind in ("stalac", "icicle", "chains")
    floatk = kind in ("island", "cloudbank")
    if kind != "cloudbank" and not (w == 6 and which == "mid"):
        for x in range(BW):
            h = base - ga.ridge(x, amps, phases, ks) - (40 if which == "mid" else 0)
            d.line([(x, int(h)), (x, BH)], fill=col)
    s = 1.0 if which == "mid" else 1.25
    for i in range(n):
        x = int((i + rnd.random() * 0.6) * BW / n)
        for dx in (0, -BW, BW):
            b = base - 30 + (rnd.randint(-6, 6) if not floatk else 0)
            feature(d, kind, x + dx, b, s, c1, c2, rnd, which)
    return im


def main():
    for w in range(1, 11):
        for zi, cfg in enumerate(Z[w]):
            save(far_layer(w, zi, cfg), "backgrounds", "bg_w%d_z%d_far.png" % (w, zi))
            save(layer_img(w, zi, cfg, "mid"), "backgrounds", "bg_w%d_z%d_mid.png" % (w, zi))
            save(layer_img(w, zi, cfg, "near"), "backgrounds", "bg_w%d_z%d_near.png" % (w, zi))
    print("fondos: 10 mundos x 4 zonas x 3 capas")


if __name__ == "__main__":
    main()

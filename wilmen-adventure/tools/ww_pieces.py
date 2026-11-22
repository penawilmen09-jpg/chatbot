"""Piezas nuevas para los niveles de WILMEN WORLD (además de las de ww_levels.py). Cada pieza dibuja en el lienzo `c`
desde la columna x con el suelo a la fila `gt` y devuelve la columna final (o (columna, nuevo_suelo))."""
from ww_levels import *


def rise(c, x, dy, gt=15):
    """Escalera de subida: el suelo pasa de gt a gt-dy (escalones de 2 celdas)."""
    for i in range(dy):
        c.fill(x + 2 * i, gt - 1 - i, x + 2 * i + 2, R, "#")
    return x + 2 * dy, gt - dy


def fall(c, x, dy, gt=15):
    """Escalera de bajada: el suelo pasa de gt a gt+dy."""
    for i in range(dy):
        c.fill(x + 2 * i, gt + 1 + i, x + 2 * i + 2, R, "#")
    return x + 2 * dy, gt + dy


def islands(c, x, spec, gt=15, foe=(), springs=()):
    """Islas sólidas flotantes sobre el vacío. spec: [(hueco, ancho, altura_sobre_gt, grosor)]."""
    ground(c, x, x + 3, gt)
    cx = x + 3
    for i, (gap, w, rise_, thick) in enumerate(spec):
        arc(c, cx, cx + gap, gt - rise_ - 3, 2)
        cx += gap
        top = gt - rise_
        c.fill(cx, top, cx + w, min(R, top + thick), "#")
        if i in springs:
            c.set(cx + w // 2, top - 1, "S")
        coins(c, cx, cx + w, top - 2)
        cx += w
    for dx, k in foe:
        c.set(x + dx, gt - 7, k)
    ground(c, cx + 2, cx + 6, gt)
    return cx + 6


def log_river(c, x, spec, gt=15, foe=()):
    """Río con troncos. spec: [("log"|"rock"|"mlog", hueco, largo)]. El agua es decorativa (caer sigue matando)."""
    ground(c, x, x + 3, gt)
    cx = x + 3
    start = cx
    for (kind, gap, ln) in spec:
        cx += gap
        if kind == "log":
            for k in range(ln):
                c.set(cx + k, gt, "=")
            coins(c, cx, cx + ln, gt - 2)
        elif kind == "rock":
            c.fill(cx, gt, cx + ln, min(R, gt + 3), "#")
            coins(c, cx, cx + ln, gt - 2)
        elif kind == "mlog":
            c.set(cx + 1, gt, "m")
            coins(c, cx, cx + 3, gt - 3)
            cx += 1
        cx += ln
    cx += 2
    for xx in range(start, cx):
        for yy in range(gt + 1, R):
            if c.get(xx, yy) == " ":
                c.set(xx, yy, "a")
    ground(c, cx, cx + 3, gt)
    for dx, k in foe:
        c.set(x + dx, gt - 5, k)
    return cx + 3


def bounce_field(c, x, w, springs, gt=15, foe=(), gem=None):
    """Suelo con setas-resorte (S) que lanzan a plataformas altas con monedas."""
    ground(c, x, x + w, gt)
    for dx in springs:
        c.set(x + dx, gt - 1, "S")
        for k in range(5):
            c.set(x + dx + 2 + k, gt - 6, "=")
        coins(c, x + dx + 2, x + dx + 7, gt - 8)
    foes(c, x, gt, foe)
    if gem:
        c.set(x + gem[0], gt - gem[1], "*")
    return x + w


def cave_hall(c, x, w, gt=15, ceil=6, hangs=(), foe=(), coin=True, crushers=()):
    """Sala de cueva: techo sólido, estalactitas (bloques colgantes) y suelo."""
    ground(c, x, x + w, gt)
    top = gt - ceil
    c.fill(x, 0, x + w, top + 1, "#")
    for (dx, ln) in hangs:
        c.fill(x + dx, top + 1, x + dx + 2, top + 1 + ln, "#")
    for dx in crushers:
        c.set(x + dx, top + 1, "p")
    if coin:
        coins(c, x + 3, x + w - 3, gt - 2)
    foes(c, x, gt, foe)
    return x + w


def treetops(c, x, spec, gt=15, foe=()):
    """Copas altas: plataformas de un solo sentido a distintas alturas sobre el vacío. spec: [(avance, altura, largo)]."""
    ground(c, x, x + 3, gt)
    cx = x + 3
    for (adv, h, ln) in spec:
        cx += adv
        for k in range(ln):
            c.set(cx + k, gt - h, "=")
        coins(c, cx, cx + ln, gt - h - 2)
        cx += ln
    cx += 2
    ground(c, cx, cx + 3, gt)
    for dx, k in foe:
        c.set(x + dx, gt - 6, k)
    return cx + 3


def thorns(c, x, w, pattern, gt=15, foe=(), shelf=()):
    """Jardín de espinas. pattern: lista de (dx, largo) de pinchos; shelf: [(dx, altura, largo)] repisas."""
    ground(c, x, x + w, gt)
    for (dx, ln) in pattern:
        for k in range(ln):
            c.set(x + dx + k, gt - 1, "^")
    for (dx, h, ln) in shelf:
        for k in range(ln):
            c.set(x + dx + k, gt - h, "=")
        coins(c, x + dx, x + dx + ln, gt - h - 2)
    foes(c, x, gt, foe)
    return x + w


def sniper(c, x, w, pillars, gt=15, foe=()):
    """Callejón de francotiradores: pilares de piedra con tiradores encima. pillars: [(dx, alto)]."""
    ground(c, x, x + w, gt)
    for (dx, h) in pillars:
        c.fill(x + dx, gt - h, x + dx + 2, gt, "#")
        c.set(x + dx, gt - h - 1, "t")
    coins(c, x + 2, x + w - 2, gt - 4)
    foes(c, x, gt, foe)
    return x + w


def bastion(c, x, w, gt=15, crushers=(), spikes=(), shooters=(), ceil=5, foe=()):
    """Pasillo de fortaleza: techo, prensas, pinchos y tiradores en nichos."""
    ground(c, x, x + w, gt)
    top = gt - ceil
    c.fill(x, 0, x + w, top + 1, "#")
    for dx in crushers:
        c.set(x + dx, top + 1, "p")
    for (dx, ln) in spikes:
        for k in range(ln):
            c.set(x + dx + k, gt - 1, "^")
    for dx in shooters:
        c.set(x + dx, gt - 1, "t")
    coins(c, x + 3, x + w - 3, gt - 2)
    foes(c, x, gt, foe)
    return x + w


def ruins(c, x, w, gt=15, bricks=(), crumbles=(), foe=()):
    """Ruinas: ladrillos que se rompen, tramos que se desmoronan y enemigos."""
    ground(c, x, x + w, gt)
    for (dx, ln) in bricks:
        for k in range(ln):
            c.set(x + dx + k, gt - 4, "B")
    for (dx, ln) in crumbles:
        for k in range(ln):
            c.set(x + dx + k, gt - 3, "c")
    coins(c, x + 2, x + w - 2, gt - 2)
    foes(c, x, gt, foe)
    return x + w


def lianas(c, x, spec, gt=15):
    """Lianas: huecos cruzados por plataformas móviles. spec: [(hueco, 'm'|'v')]."""
    ground(c, x, x + 3, gt)
    cx = x + 3
    for (gap, kind) in spec:
        mx = cx + gap // 2 - 1
        c.set(mx, gt, kind)
        coins(c, mx - 1, mx + 3, gt - 3)
        cx += gap
        ground(c, cx, cx + 4, gt)
        cx += 4
    return cx


def waterfall(c, x, gt=15, w=16, up=10):
    """Cascada: corriente de aire ascendente junto a una caída de agua decorativa, con repisa de monedas."""
    ground(c, x, x + w, gt)
    wx = x + 4
    for yy in range(gt - up, gt):
        for k in range(3):
            c.set(wx + k, yy, "W")
        c.set(wx - 1, yy, "|")
        c.set(wx + 3, yy, "|")
    for k in range(5):
        c.set(wx + 4 + k, gt - up + 1, "=")
    coins(c, wx + 4, wx + 9, gt - up - 1)
    arc(c, wx - 2, wx + 4, gt - 3, 4)
    return x + w


def mud(c, x, w, gt=15, foe=(), thorn=()):
    ground(c, x, x + w, gt)
    for xx in range(x + 2, x + w - 2):
        c.set(xx, gt, "~")
    for dx in thorn:
        c.set(x + dx, gt - 1, "^")
    coins(c, x + 3, x + w - 3, gt - 3)
    foes(c, x, gt, foe)
    return x + w


# ---------------------------------------------------------------- salas ------
def side_room(c, x0, kind, w=58, gems=0, key=False):
    """Sala cerrada a la derecha del mapa (cueva, bodega, cámara). Devuelve (entrada, salida, columna_siguiente)."""
    c.fill(x0, 0, x0 + w, R, "#")
    ix0, ix1 = x0 + 2, x0 + w - 2
    c.fill(ix0, 1 if kind == "shaft" else 3, ix1, 15, " ")
    ground(c, ix0, ix1, 15)
    entry = (ix0 + 2, 14)
    exit_ = (ix1 - 4, 14)
    g = []
    if kind == "key":
        spike_run(c, ix0 + 6, 14, [(3, 2), (8, 3)], shelf=[(5, 11, 4)], gt=15)
        for k in range(5):
            c.set(ix0 + 24 + k, 12, "=")
        if key:
            c.set(ix0 + 26, 11, "U")
        c.set(ix0 + 34, 14, "w")
        c.set(ix0 + 39, 14, "j")
        c.set(ix0 + 44, 14, "I")
        g = [(ix0 + 31, 14)]
    elif kind == "gem":
        for k in range(4):
            c.set(ix0 + 10 + k * 7, 12 - (k % 2) * 2, "=")
            c.set(ix0 + 11 + k * 7, 12 - (k % 2) * 2, "=")
        thorns_row = [(ix0 + 9, 5), (ix0 + 19, 5), (ix0 + 29, 5)]
        for (sx, ln) in thorns_row:
            for k in range(ln):
                c.set(sx + k, 14, "^")
        c.set(ix0 + 40, 14, "w")
        c.set(ix0 + 44, 14, "M")
        g = [(ix0 + 38, 9)]
    elif kind == "vault":
        coins(c, ix0 + 5, ix1 - 8, 13)
        for k in range(5):
            c.set(ix0 + 18 + k, 12, "=")
        c.set(ix0 + 20, 9, "u")
        c.set(ix0 + 12, 14, "N")
        c.set(ix0 + 34, 14, "R")
        c.set(ix0 + 44, 14, "M")
        g = [(ix0 + 28, 10)]
    elif kind == "arena":
        for dx in (10, 18, 26):
            c.fill(ix0 + dx, 3, ix0 + dx + 2, 8, "#")
            c.set(ix0 + dx, 9, "p")
        for dx, k in ((8, "w"), (14, "j"), (22, "w"), (30, "s"), (38, "t"), (42, "w")):
            c.set(ix0 + dx, 14, k)
        c.set(ix0 + 46, 14, "M")
        g = [(ix0 + 33, 12)]
        c.set(ix0 + 32, 12, "=")
        c.set(ix0 + 33, 12, "=")
        c.set(ix0 + 34, 12, "=")
    elif kind == "shaft":
        for i, (dx, y) in enumerate(((8, 12), (14, 9), (8, 6), (14, 3))):
            for k in range(4):
                c.set(ix0 + dx + k, y, "=")
        g = [(ix0 + 16, 2)]
        c.set(ix0 + 30, 14, "I")
        coins(c, ix0 + 24, ix0 + 36, 13)
    elif kind == "secret":
        # sala de la salida secreta: espinas y una última plataforma antes de la bandera morada
        for (sx, ln) in ((ix0 + 10, 4), (ix0 + 20, 4), (ix0 + 30, 5)):
            for k in range(ln):
                c.set(sx + k, 14, "^")
        for k in range(4):
            c.set(ix0 + 14 + k, 12, "=")
            c.set(ix0 + 26 + k, 12, "=")
        c.set(ix0 + 44, 14, "O")
        c.set(ix0 + 40, 14, "w")
        c.set(ix0 + 28, 11, "I")
        g = [(ix0 + 15, 10)]
    for (gx, gy) in g[:gems]:
        c.set(gx, gy, "*")
    return entry, exit_, x0 + w


def fork(c, x, w, gt=15, low_foe=(), spikes=(), up_foe=()):
    """Bifurcación: ruta baja (suelo con enemigos y pinchos) y ruta alta (troncos con monedas). Las dos llevan al mismo sitio."""
    ground(c, x, x + w, gt)
    for k in range(0, w - 9, 8):
        for j in range(5):
            c.set(x + 3 + k + j, gt - 5, "=")
        coins(c, x + 3 + k, x + 8 + k, gt - 7)
    for (dx, ln) in spikes:
        for k in range(ln):
            c.set(x + dx + k, gt - 1, "^")
    foes(c, x, gt, low_foe)
    for dx in up_foe:
        c.set(x + dx, gt - 9, "f")
    return x + w

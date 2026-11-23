#!/usr/bin/env python3
"""Arte de los enemigos y trampas nuevos de WILMEN WORLD (paso B): topo, guardián, murciélago, lanzarrocas, prensa.
Salida: assets/enemies/ww_enemies.png (casillas 16x16; 5 filas x 4 columnas, ver ROWS en enemies/ww_enemy.gd)."""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "enemies", "ww_enemies.png")
OL = (26, 18, 38, 255)
W_ = (255, 255, 255, 255)


def new():
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def eyes(d, y, ang=False, x0=5, x1=10):
    for x in (x0, x1):
        d.rectangle([x, y, x + 1, y + 2], fill=W_)
        d.point((x + 1, y + 1), fill=OL)
    if ang:
        d.line([(x0 - 1, y - 1), (x0 + 2, y)], fill=OL)
        d.line([(x1 + 2, y - 1), (x1 - 1, y)], fill=OL)


def mole(f):
    im, d = new()
    dirt, dark = (150, 104, 66, 255), (104, 70, 44, 255)
    if f == 0:  # montículo
        d.ellipse([2, 10, 13, 17], fill=OL)
        d.ellipse([3, 11, 12, 17], fill=dirt)
        d.point((6, 12), fill=dark); d.point((9, 13), fill=dark)
    elif f == 1:  # tiembla (aviso)
        d.ellipse([1, 9, 14, 17], fill=OL)
        d.ellipse([2, 10, 13, 17], fill=dirt)
        d.polygon([(5, 9), (7, 6), (9, 9)], fill=dark)
        d.point((4, 11), fill=dark); d.point((11, 12), fill=dark)
    else:  # fuera
        d.ellipse([2, 3, 13, 14], fill=OL)
        d.ellipse([3, 4, 12, 13], fill=(122, 96, 80, 255))
        d.ellipse([6, 9, 9, 12], fill=(240, 150, 150, 255))
        eyes(d, 6, ang=True, x0=4, x1=9)
        d.polygon([(2, 14), (5, 12), (6, 15)], fill=(250, 240, 200, 255))
        d.polygon([(13, 14), (10, 12), (9, 15)], fill=(250, 240, 200, 255))
        d.ellipse([1, 12, 14, 17], fill=dirt)
    return im


def guard(f):
    im, d = new()
    st, st2 = (140, 146, 164, 255), (96, 102, 122, 255)
    d.rectangle([3, 3, 12, 15], fill=OL)
    d.rectangle([4, 4, 11, 14], fill=st)
    d.rectangle([4, 10, 11, 14], fill=st2)
    if f == 2:  # aturdido
        d.rectangle([5, 5, 10, 8], fill=(240, 230, 120, 255))
        d.line([(5, 5), (7, 7)], fill=OL); d.line([(7, 5), (5, 7)], fill=OL)
        d.line([(8, 5), (10, 7)], fill=OL); d.line([(10, 5), (8, 7)], fill=OL)
        for x in (3, 7, 11):
            d.point((x, 1), fill=(255, 220, 80, 255))
    else:
        d.rectangle([5, 5, 10, 7], fill=(255, 90, 80, 255) if f == 1 else (30, 30, 50, 255))
        d.point((6, 6), fill=W_); d.point((9, 6), fill=W_)
    # escudo frontal (a la izquierda; se voltea por código)
    d.rectangle([0, 5, 3, 13], fill=OL)
    d.rectangle([1, 6, 3, 12], fill=(210, 170, 70, 255))
    d.point((2, 9), fill=(255, 240, 160, 255))
    return im


def bat(f):
    im, d = new()
    body = (110, 70, 140, 255)
    if f == 0:  # colgado
        d.ellipse([4, 1, 11, 10], fill=OL)
        d.ellipse([5, 2, 10, 9], fill=body)
        d.polygon([(4, 3), (1, 8), (5, 8)], fill=(80, 50, 100, 255))
        d.polygon([(11, 3), (14, 8), (10, 8)], fill=(80, 50, 100, 255))
        eyes(d, 4, x0=5, x1=9)
    elif f in (1, 2):  # aleteo
        up = f == 1
        d.polygon([(8, 6), (0, 3 if up else 9), (3, 11 if not up else 8)], fill=OL)
        d.polygon([(8, 6), (16, 3 if up else 9), (13, 11 if not up else 8)], fill=OL)
        d.polygon([(8, 6), (2, 4 if up else 9), (4, 9)], fill=(150, 100, 190, 255))
        d.polygon([(8, 6), (14, 4 if up else 9), (12, 9)], fill=(150, 100, 190, 255))
        d.ellipse([5, 4, 11, 12], fill=OL); d.ellipse([6, 5, 10, 11], fill=body)
        eyes(d, 6, ang=True, x0=6, x1=9)
    else:  # picado
        d.polygon([(8, 15), (4, 2), (12, 2)], fill=OL)
        d.polygon([(8, 14), (5, 3), (11, 3)], fill=body)
        d.polygon([(4, 3), (1, 9), (5, 8)], fill=(150, 100, 190, 255))
        d.polygon([(12, 3), (15, 9), (11, 8)], fill=(150, 100, 190, 255))
        eyes(d, 4, ang=True, x0=5, x1=9)
        d.polygon([(7, 11), (8, 14), (9, 11)], fill=W_)
    return im


def lobber(f):
    im, d = new()
    g, g2 = (96, 150, 70, 255), (66, 110, 50, 255)
    arm = 0 if f == 0 else (-3 if f == 1 else 2)
    d.ellipse([2, 5, 13, 16], fill=OL)
    d.ellipse([3, 6, 12, 15], fill=g)
    d.ellipse([4, 10, 11, 15], fill=g2)
    eyes(d, 7, ang=(f != 0), x0=4, x1=9)
    d.ellipse([5, 11, 10, 13], fill=OL)
    d.rectangle([13, 5 + arm, 15, 8 + arm], fill=OL)
    d.rectangle([13, 6 + arm, 14, 7 + arm], fill=g)
    if f == 1:  # roca en la mano
        d.ellipse([11, 0, 15, 4], fill=OL); d.ellipse([12, 1, 14, 3], fill=(170, 160, 150, 255))
    return im


def misc(f):
    im, d = new()
    if f == 0:  # roca lanzada
        d.ellipse([3, 3, 12, 12], fill=OL)
        d.ellipse([4, 4, 11, 11], fill=(170, 160, 150, 255))
        d.point((6, 6), fill=(210, 205, 195, 255)); d.point((9, 9), fill=(120, 112, 105, 255))
    elif f == 1:  # cadena de la prensa
        d.rectangle([6, 0, 9, 15], fill=OL)
        for y in (1, 5, 9, 13):
            d.rectangle([7, y, 8, y + 2], fill=(190, 190, 205, 255))
    elif f == 2:  # cuerpo de la prensa
        d.rectangle([0, 0, 15, 15], fill=OL)
        d.rectangle([1, 1, 14, 14], fill=(118, 124, 146, 255))
        d.rectangle([1, 1, 14, 3], fill=(160, 166, 188, 255))
        for x in (3, 12):
            d.rectangle([x, 6, x + 1, 7], fill=OL)
    else:  # cara con pinchos (abajo)
        d.rectangle([0, 0, 15, 8], fill=OL)
        d.rectangle([1, 1, 14, 7], fill=(118, 124, 146, 255))
        for x in range(0, 16, 4):
            d.polygon([(x, 8), (x + 2, 15), (x + 4, 8)], fill=OL)
            d.polygon([(x + 1, 8), (x + 2, 13), (x + 3, 8)], fill=(230, 235, 245, 255))
    return im


rows = [[mole(i) for i in (0, 1, 2, 2)], [guard(i) for i in (0, 1, 2, 2)], [bat(i) for i in (0, 1, 2, 3)],
        [lobber(i) for i in (0, 1, 2, 2)], [misc(i) for i in (0, 1, 2, 3)]]
sheet = Image.new("RGBA", (64, 80), (0, 0, 0, 0))
for r, row in enumerate(rows):
    for c, im in enumerate(row):
        sheet.paste(im, (c * 16, r * 16))
sheet.save(OUT)
print("escrito", os.path.normpath(OUT))
Image.open(OUT).resize((384, 480), Image.NEAREST).save("/tmp/ww_enemies_preview.png")

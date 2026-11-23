"""1-8 Salto del Duende (340x34): descenso por una cascada; burbujas, desmoronables y una cueva dentro del acantilado."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from ww_cv import Cv

META = dict(title="Salto del Duende", region=1, theme=1, time=340, par=130, diff=3, kind="normal", zone=0)


def ledge(c, x0, x1, top, thick=2):
    c.fill(x0, top, x1, top + thick, "#")
    for x in range(x0, x1):
        c.top[x] = top


def build():
    c = Cv(340, 34)
    # acantilado escalonado (la cima baja en peldanos) con la cueva dentro
    for x0, x1, t in ((0, 40, 4), (40, 52, 6), (52, 64, 8), (64, 76, 10), (76, 88, 11), (88, 100, 12)):
        c.land(x0, x1, t)
    # tramo 2: repisas separadas (descenso con caidas)
    for x0, x1, t in ((104, 111, 16), (116, 123, 17), (128, 135, 18), (140, 147, 19), (152, 159, 20), (164, 171, 21)):
        ledge(c, x0, x1, t)
    c.plat(100, 106, 18, "=")                                 # repisa de la boca este de la cueva
    c.fill(143, 13, 147, 14, "#")                              # repisa de la gema (solo con burbujas)
    for x in range(143, 147):
        c.top[x] = 13
    c.fill(147, 14, 150, 24, ",")                              # burbujas 1 (junto a la repisa de la gema)
    c.fill(171, 16, 174, 26, ",")                              # burbujas 2
    for i in range(5):                                         # desmoronables en zigzag
        c.fill(176 + 8 * i, 23 + i, 178 + 8 * i, 24 + i, "c")
    c.land(216, 340, 28)                                       # poza final
    # ---- cueva del acantilado
    c.carve(28, 4, 32, 16)                                     # E1: agujero en la cima (4 de ancho)
    c.carve(6, 14, 36, 20)                                     # R1 30x6
    c.carve(36, 14, 100, 18)                                   # corredor largo hasta la boca este (64x4)
    c.carve(12, 20, 18, 22)                                    # paso a R2
    c.carve(8, 22, 28, 29)                                     # R2 20x7
    c.plat(10, 14, 26, "="); c.plat(14, 18, 23, "=")
    c.carve(290, 29, 308, 33)                                  # sala bajo la poza
    on = c.on
    c.set(5, 3, "P")
    c.coins(8, 2, 8); c.coins(44, 5, 6); c.coins(55, 7, 6); c.coins(67, 9, 6); c.coins(79, 10, 6); c.coins(91, 11, 6)
    c.fill(56, 3, 62, 5, "#"); c.set(58, 5, "Y")
    c.fill(127, 12, 135, 14, "#"); c.set(130, 14, "Y")
    c.fill(186, 19, 194, 21, "#"); c.set(190, 21, "Y")
    for x, y in ((112, 13), (138, 15), (160, 17)):
        c.set(x, y, "f")
    c.set(96, 11, "C")
    c.set(111, 12, "C") if False else None
    c.set(145, 12, "*")
    c.coins(104, 15, 5); c.coins(116, 16, 5); c.coins(128, 17, 5); c.coins(140, 18, 5); c.coins(152, 19, 5); c.coins(164, 20, 5)
    for i in range(5):
        c.set(176 + 8 * i, 22 + i, "o")
    c.set(218, 27, "C")
    for x in range(222, 226):
        c.set(x, 27, "^")
    c.coins(228, 27, 12)
    # cueva: objetos
    c.set(30, 21, "w") if False else None
    c.set(20, 28, "U"); c.set(24, 28, "*"); c.set(12, 28, "I"); c.coins(9, 26, 3)
    c.coins(40, 17, 10); c.coins(70, 17, 10)
    c.set(300, 27, "A")
    c.warp((300, 27), (294, 32), "door", 1)
    c.set(294, 32, "A"); c.set(304, 32, "*"); c.set(300, 32, "u"); c.coins(296, 32, 4); c.set(306, 32, "M")
    c.set(332, 27, "F")
    return c


def save():
    return build().save(8, **META, comments=("Descenso: cima escalonada, repisas, burbujas, desmoronables y poza; cueva dentro del acantilado.",))


if __name__ == "__main__":
    c = build()
    a = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    b = int(sys.argv[2]) if len(sys.argv) > 2 else 130
    print(c.preview(a, b))

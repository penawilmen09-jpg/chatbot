"""2-1 (nivel 21) Dunas del Amanecer (560x26): dunas con cintas de arena, viento que eleva y resortes; cueva bajo la duna."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from ww_cv import Cv

META = dict(title="Dunas del Amanecer", region=2, theme=3, time=380, par=140, diff=1, kind="normal", zone=0)


def build():
    c = Cv(560, 26)
    prof = [(0, 30, 16), (30, 50, 15), (50, 70, 16), (70, 100, 16), (100, 112, 15), (112, 150, 16), (162, 180, 16), (194, 230, 16),
            (230, 262, 15), (262, 300, 16), (300, 330, 14), (330, 372, 13), (372, 400, 14), (400, 430, 15), (430, 462, 14),
            (462, 560, 12)]
    for a, b, t in prof:
        c.land(a, b, t)
    # cintas de arena: > empuja hacia delante, < en contra (sobre la superficie)
    for x in range(70, 100):
        c.set(x, 16, ">")
    for x in range(232, 262):
        c.set(x, 15, "<")
    # fosos con columnas de viento
    c.land(155, 158, 16); c.land(186, 189, 16)
    c.fill(155, 9, 158, 16, "W"); c.fill(186, 9, 189, 16, "W")
    c.plat(152, 162, 8, "="); c.plat(183, 193, 8, "=")
    # subsuelo: la cueva de la duna (3 espacios)
    for i in range(6):
        c.carve(304 + i, 14 + i, 308 + i, 18 + i)
    c.carve(306, 19, 352, 24)                         # M1 galeria 46x5
    c.carve(352, 20, 376, 24)                         # M2 sala 24x4 (llave)
    c.carve(346, 13, 350, 19)                         # X1 pozo a la superficie
    c.plat(346, 349, 16, "="); c.plat(347, 350, 13, "=")
    c.carve(358, 14, 372, 19)                         # M3 camara secreta sobre M2 (techo de ladrillos)
    c.plat(364, 366, 19, "B")
    on = c.on
    c.set(3, 15, "P")
    c.coins(8, 14, 10)
    c.set(40, c.top[40] - 1, "w"); c.set(120, 15, "s"); c.set(140, 15, "j"); c.set(205, 15, "j"); c.set(245, 14, "s")
    for x in (112, 113, 114):
        c.set(x, 15, "^")
    for x in (184, 185, 186):
        pass
    c.set(170, 15, "S"); c.set(215, 15, "S")
    c.set(150, 15, "C") if False else None
    c.set(166, 15, "C"); c.set(300, 13, "C"); c.set(430, 13, "C")
    c.coins(104, 13, 6); c.coins(165, 12, 6); c.coins(196, 14, 8); c.set(157, 7, "*"); c.coins(184, 7, 8)
    # cueva: llave, gema, reloj, vida
    c.set(370, 23, "U"); c.set(356, 23, "I"); c.set(330, 23, "u"); c.coins(310, 23, 6)
    c.set(366, 12 + 5, "*") if False else None
    c.set(364, 18, "*"); c.set(360, 18, "k")
    # superficie: puerta con llave a un oasis escondido
    c.set(395, 13, "A")
    c.set(2, 3, "#")
    c.fill(2, 2, 22, 10, "#"); c.carve(4, 4, 20, 9)
    c.warp((395, 13), (6, 8), "door", 1)
    c.set(6, 8, "A"); c.set(16, 8, "*"); c.set(12, 8, "h"); c.coins(8, 8, 6)
    # ascenso final con desmoronables
    for i in range(6):
        c.fill(405 + 4 * i, 14 - i, 407 + 4 * i, 15 - i, "c")
    c.coins(440, 12, 8); c.set(540, 11, "F")
    c.set(230, 8, "I")
    for x in (20, 55, 132, 212, 280, 345, 380, 440):
        if c.get(x, c.top[x] - 1) == " ":
            c.set(x, c.top[x] - 1, "d")
    return c


def save():
    return build().save(21, **META, comments=("Dunas: cintas de arena, viento, resortes y cueva bajo la duna.",))


if __name__ == "__main__":
    c = build()
    a = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    b = int(sys.argv[2]) if len(sys.argv) > 2 else 130
    print(c.preview(a, b))

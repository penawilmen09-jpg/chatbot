"""2-2 (nivel 22) Oasis Espejismo (420x30): lago con islas y corrientes, palmeral que se escala y meseta con cueva del manantial."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from ww_cv import Cv

META = dict(title="Oasis Espejismo", region=2, theme=3, time=400, par=150, diff=2, kind="normal", zone=1)


def build():
    c = Cv(420, 30)
    c.land(0, 60, 22)
    for i in range(9):
        c.land(66 + 14 * i, 74 + 14 * i, 22)
    c.land(190, 262, 22)
    c.land(270, 420, 8)
    for gx in (75, 103, 131):
        c.fill(gx, 18, gx + 5, 22, ":")
    for gx in (89, 117, 145):
        c.fill(gx, 18, gx + 5, 22, ".")
    # palmeral: escalera de palmeras hasta la meseta
    for x, y in ((262, 19), (266, 16), (262, 13), (266, 10)):
        c.plat(x, x + 4, y, "=")
    # palmera alta sobre el lago (gema)
    c.plat(176, 180, 18, "=")
    # cueva del manantial dentro de la meseta
    c.carve(300, 8, 304, 13)
    c.carve(290, 13, 340, 19)
    c.carve(340, 16, 372, 24)
    c.carve(372, 20, 392, 24)
    c.carve(392, 8, 396, 24)
    c.plat(392, 395, 21, "="); c.plat(393, 396, 18, "="); c.plat(392, 395, 15, "="); c.plat(393, 396, 12, "=")
    c.plat(300, 303, 11, "=")
    # sala oculta (oasis escondido) en el cielo
    c.fill(4, 2, 24, 12, "#"); c.carve(6, 4, 22, 11)
    on = c.on
    c.set(3, 21, "P")
    c.coins(8, 20, 8)
    for i in range(9):
        c.coins(68 + 14 * i, 20, 4)
    c.set(112, 21, "f") if False else None
    c.set(100, 12, "f"); c.set(140, 12, "f"); c.set(170, 12, "f")
    c.set(75, 21, "s") if False else None
    c.set(220, 21, "t"); c.set(240, 21, "w")
    c.set(178, 17, "*")
    c.set(30, 21, "C") if False else None
    c.set(194, 21, "C"); c.set(272, 7, "C"); c.set(360, 7, "C")
    c.coins(200, 21, 8); c.coins(245, 21, 6)
    # meseta
    c.set(285, 7, "j"); c.set(320, 7, "w"); c.set(350, 7, "s"); c.set(388, 7, "j")
    c.coins(276, 6, 8); c.coins(330, 6, 10); c.coins(370, 6, 10)
    c.set(412, 7, "F")
    c.set(404, 7, "A")
    c.warp((404, 7), (8, 10), "door", 1)
    c.set(8, 10, "A"); c.set(18, 10, "*"); c.set(14, 10, "u"); c.coins(10, 10, 6)
    # cueva
    c.set(350, 23, "U"); c.set(310, 18, "I"); c.set(376, 23, "*"); c.coins(296, 18, 8); c.coins(344, 23, 6); c.set(384, 23, "h")
    c.set(318, 18, "z"); c.set(362, 23, "z")
    for x in (10, 40, 205, 255, 285, 340, 380):
        if c.top[x] < 30 and c.get(x, c.top[x] - 1) == " ":
            c.set(x, c.top[x] - 1, "d")
    return c


def save():
    return build().save(22, **META, comments=("Oasis: lago con islas y corrientes, palmeral, meseta y cueva del manantial.",))


if __name__ == "__main__":
    c = build()
    a = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    b = int(sys.argv[2]) if len(sys.argv) > 2 else 130
    print(c.preview(a, b))

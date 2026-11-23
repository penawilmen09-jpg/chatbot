"""1-10 Fortaleza de Raices (640x34, fortaleza): patio central, torre oeste (ascensores) y torre este (plataformas orbitales);
la puerta doble de la meta exige 2 llaves (una por torre); pasadizo subterraneo con prensas y armeria secreta."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from ww_cv import Cv

META = dict(title="Fortaleza de Raices", region=1, theme=1, time=480, par=190, diff=4, kind="fortress", zone=2)


def build():
    c = Cv(640, 34)
    c.land(0, 640, 26)
    # torre oeste (macizo 60-150 con sala interior de 78x20)
    c.fill(60, 0, 150, 26, "#")
    c.carve(66, 6, 144, 26)
    c.carve(60, 22, 66, 26); c.carve(144, 22, 150, 26)
    for x in range(60, 150):
        c.top[x] = 0
    c.plat(70, 80, 22, "="); c.plat(88, 98, 19, "=")           # peldanos de entrada
    c.plat(104, 110, 20, "=")                                   # base del ascensor 2
    c.plat(114, 124, 14, "=")                                   # cima con la llave 1
    c.plat(127, 137, 16, "=")
    # patio: puente levadizo con prensas bajo una viga
    c.fill(250, 14, 305, 18, "#")
    # parapetos con lanzarrocas
    for x0, t in ((196, 19), (340, 19), (430, 19)):
        c.fill(x0, t, x0 + 6, t + 2, "#")
        for x in range(x0, x0 + 6):
            c.top[x] = t
    for x0 in (196, 340, 430):
        c.plat(x0 - 10, x0 - 6, 23, "="); c.plat(x0 - 6, x0 - 2, 20, "=")
    # torre este (macizo 484-570 con sala interior)
    c.fill(484, 0, 570, 26, "#")
    c.carve(490, 6, 564, 26)
    c.carve(484, 22, 490, 26); c.carve(564, 22, 570, 26)
    for x in range(484, 570):
        c.top[x] = 0
    c.plat(492, 498, 22, "="); c.plat(508, 514, 17, "="); c.plat(523, 529, 12, "=")
    # muralla final y camara de la meta
    c.fill(602, 0, 640, 26, "#")
    c.carve(606, 19, 636, 26)
    # pasadizo subterraneo entre torres (26x5) con prensas
    c.carve(70, 28, 96, 33)
    # armeria secreta bajo el patio
    c.carve(176, 28, 194, 33)
    on = c.on
    c.set(4, 25, "P")
    c.coins(10, 24, 8)
    # entrada
    c.set(30, 25, "D"); c.set(46, 25, "D")
    # torre oeste: ascensores
    c.set(100, 26, "b") if False else None
    c.carve(100, 26, 102, 28); c.set(100, 26, "b"); c.set(110, 20, "b")
    c.coins(70, 21, 6); c.coins(88, 18, 6); c.coins(104, 19, 4); c.coins(115, 13, 4); c.coins(127, 15, 5)
    c.set(135, 25, "C") if False else None
    c.set(155, 25, "C")
    # patio
    c.set(240, 25, "D"); c.set(312, 25, "D")
    c.extra.append("@press 258,18,2"); c.extra.append("@press 284,18,2")
    for x0 in (196, 340, 430):
        c.set(x0 + 3, c.top[x0] - 1, "0")
    c.coins(160, 25, 10); c.coins(210, 25, 12); c.coins(320, 25, 14); c.coins(380, 25, 10); c.coins(440, 25, 10)
    c.set(300, 25, "M")
    c.set(198, 18, "o"); c.set(342, 18, "*")
    # torre este: plataformas orbitales
    c.set(503, 20, "n"); c.set(518, 14, "n")
    c.set(496, 25, "C") if False else None
    c.set(480, 25, "C")
    c.set(522, 9, "U") if False else None
    c.coins(492, 21, 6); c.coins(508, 16, 6); c.set(528, 10, "D") if False else None
    # puerta doble de la meta (2 llaves)
    c.set(600, 25, "A")
    c.warp((600, 25), (608, 25), "door", 2)
    c.set(608, 25, "A"); c.set(630, 25, "F"); c.coins(612, 25, 10)
    c.set(575, 25, "C")
    # pasadizo subterraneo
    c.set(64, 25, "T"); c.set(71, 32, "T")
    c.warp((64, 25), (71, 32), "tunnel")
    c.set(95, 32, "T"); c.set(488, 25, "T")
    c.warp((95, 32), (488, 25), "tunnel")
    c.extra.append("@press 80,28,2"); c.extra.append("@press 86,28,2")
    c.coins(74, 32, 5)
    # armeria secreta
    c.set(170, 25, "T"); c.set(178, 32, "T")
    c.warp((170, 25), (178, 32), "tunnel")
    c.set(190, 32, "*"); c.set(186, 32, "u"); c.coins(180, 32, 5); c.set(184, 32, "k")
    c.set(250, 25, "d") if False else None
    c.set(120, 13, "U"); c.set(526, 11, "U"); c.set(133, 15, "*")
    return c


def save():
    return build().save(10, **META, comments=("Fortaleza: torre oeste (ascensores), patio con prensas, torre este (orbitales), puerta doble con 2 llaves.",))


if __name__ == "__main__":
    c = build()
    a = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    b = int(sys.argv[2]) if len(sys.argv) > 2 else 130
    print(c.preview(a, b))

"""2-4 (nivel 24) Ruinas de Arena (360x28): cueva de camaras enterradas conectadas por rampas."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from ww_cv import Cv

META = dict(title="Ruinas de Arena", region=2, theme=3, time=420, par=160, diff=2, kind="cave", zone=2)


def build():
    c = Cv(360, 28)
    c.land(0, 360, 6)
    c.carve(20, 6, 25, 13)                         # pozo de entrada
    c.plat(20, 23, 10, "="); c.plat(22, 25, 8, "=")
    c.carve(25, 12, 84, 19)                        # A  stand 18
    c.carve(82, 15, 140, 22)                       # B  stand 21
    c.carve(138, 12, 200, 22)                      # C  y rampa B->C
    for i, (x, y) in enumerate(((141, 19), (145, 16), (149, 13))):
        c.plat(x, x + 3, y, "=")
    c.fill(150, 20, 200, 23, "#")                  # suelo de C a stand 19
    c.carve(150, 12, 200, 19)
    c.carve(198, 17, 262, 25)                      # D  stand 24
    c.carve(260, 12, 320, 19)                      # E  stand 18
    c.carve(256, 12, 262, 25)
    c.plat(256, 259, 22, "="); c.plat(259, 263, 19, "=")
    c.carve(318, 6, 323, 19)                       # pozo de salida
    c.plat(318, 321, 15, "="); c.plat(320, 323, 12, "="); c.plat(318, 321, 9, "=")
    c.set(3, 5, "P"); c.coins(6, 5, 8)
    c.set(36, 18, "z"); c.set(60, 18, "j"); c.set(100, 21, "w"); c.set(120, 21, "s"); c.set(172, 19, "z")
    c.set(30, 11, "Y") if False else None
    c.fill(40, 11, 44, 12, "#"); c.set(42, 12, "Y")
    c.fill(110, 14, 114, 15, "#"); c.set(112, 15, "Y")
    c.fill(228, 16, 232, 17, "#"); c.set(230, 17, "Y")
    c.set(40, 18, "C"); c.set(200, 24, "C") if False else None; c.set(262, 17, "C") if False else None
    c.set(90, 21, "C"); c.set(205, 24, "C")
    c.coins(30, 17, 8); c.coins(88, 20, 8); c.coins(160, 18, 10); c.coins(210, 23, 10); c.coins(274, 17, 10); c.coins(280, 14, 5)
    c.set(240, 24, "U"); c.set(160, 14, "*"); c.set(60, 11, "*") if False else None; c.set(180, 14, "*"); c.set(300, 17, "*"); c.set(66, 17, "I")
    c.set(250, 24, "^") if False else None
    for x in (127, 128, 129):
        c.set(x, 21, "^")
    c.set(245, 24, "j")
    # puerta a la camara oculta con corazon
    c.fill(4, 12, 20, 24, "#"); c.carve(6, 14, 18, 22)
    c.set(300, 18, "A"); c.warp((300, 18), (8, 21), "door", 1)
    c.set(8, 21, "A"); c.set(14, 21, "h"); c.set(16, 21, "u"); c.coins(10, 21, 4)
    c.set(340, 5, "F")
    return c


def save():
    return build().save(24, **META, comments=("Cueva: camaras enterradas conectadas.",))


if __name__ == "__main__":
    print(build().preview(0, 130))

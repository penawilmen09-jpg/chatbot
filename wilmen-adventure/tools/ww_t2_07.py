"""1-7 Aserradero del Lenador (380x30, casa/bonus): edificio de 3 pisos con ascensores, prensas, sierras y una chimenea."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from ww_cv import Cv

META = dict(title="Aserradero del Lenador", region=1, theme=1, time=460, par=150, diff=2, kind="house", zone=1)


def build():
    c = Cv(380, 30)
    c.fill(0, 0, 380, 30, "#")
    for x in range(380):
        c.top[x] = 0
    c.carve(4, 24, 376, 29)       # F1 patio de troncos (suelo fila 29)
    c.carve(4, 18, 376, 23)       # F2 sierra mayor (suelo fila 23)
    c.carve(4, 9, 376, 17)        # F3 despacho (suelo fila 17)
    # ascensores: huecos en los suelos
    c.carve(90, 23, 92, 24); c.carve(90, 29, 92, 30)       # E1: F1 -> F2
    c.carve(300, 17, 302, 18); c.carve(300, 23, 302, 24)   # E2: F2 -> F3
    # chimenea (atajo) en el extremo este: pozo con salientes alternos de F1 a F3
    c.carve(362, 9, 370, 29)
    for k, y in enumerate((26, 23, 20, 17, 14, 11)):
        x0 = 362 if k % 2 == 0 else 366
        c.plat(x0, x0 + 4, y, "=")
    # salas selladas arriba (sotano de la sierra y boveda del tesoro)
    c.carve(10, 2, 28, 7)
    c.carve(40, 2, 62, 7)
    # muro conmutable de la boveda del despacho (F3)
    c.fill(330, 9, 331, 17, "(")
    on = c.on
    c.set(90, 29, "b"); c.set(300, 23, "b")
    c.set(8, 28, "P")
    # F1
    c.set(60, 28, "D"); c.set(120, 28, "D")                # guardianes al pie del ascensor 1
    c.set(240, 28, "&"); c.set(330, 28, "&")               # troncos que ruedan hacia el ascensor
    c.coins(20, 27, 12); c.coins(130, 27, 10); c.coins(250, 27, 14); c.coins(300, 27, 8)
    c.set(40, 28, "A")                                      # puerta al sotano
    c.warp((40, 28), (14, 6), "door", 1)
    c.set(14, 6, "A"); c.set(24, 6, "*"); c.set(20, 6, "q"); c.coins(16, 6, 3); c.coins(21, 5, 3)
    c.set(350, 28, "U")
    # F2: prensas y sierras
    for x in (112, 142, 172, 202):
        c.extra.append("@press %d,18,2" % x)
    for x in (236, 266):
        for r in range(18, 22):
            c.set(x, r, "!")
    c.set(100, 22, "C"); c.set(250, 21, "*")
    c.coins(96, 21, 10); c.coins(125, 21, 3); c.coins(155, 21, 3); c.coins(185, 21, 3); c.coins(215, 21, 6); c.coins(276, 21, 12)
    c.set(285, 21, "I"); c.set(60, 22, "u")
    # F3
    c.set(310, 16, "C"); c.set(316, 16, "/")
    c.set(322, 16, "A")
    c.warp((322, 16), (42, 6), "door", 1)
    c.set(42, 6, "A"); c.set(58, 6, "*"); c.set(54, 6, "h"); c.set(50, 6, "M"); c.coins(44, 6, 6); c.coins(55, 6, 2)
    c.set(30, 16, "U")
    c.coins(36, 16, 10); c.coins(80, 16, 20); c.coins(150, 16, 20); c.coins(220, 16, 20); c.coins(335, 16, 10)
    c.set(360, 16, "F") if False else None
    c.set(350, 16, "F")
    return c


def save():
    return build().save(7, **META, comments=("Casa: edificio de 3 pisos; ascensores, prensas, sierras y chimenea.",))


if __name__ == "__main__":
    c = build()
    a = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    b = int(sys.argv[2]) if len(sys.argv) > 2 else 130
    print(c.preview(a, b))

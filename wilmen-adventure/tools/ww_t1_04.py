"""1-4 Cueva de las Raices (420x28, cueva): red de espacios de formas distintas con puzles de interruptores."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from ww_cv import Cv

META = dict(title="Cueva de las Raices", region=1, theme=1, time=480, par=180, diff=2, kind="cave", zone=3)


def build():
    c = Cv(420, 28)
    c.fill(0, 0, 420, 28, "#")
    for x in range(420):
        c.top[x] = 0
    # exterior (x >= 332): superficie en la fila 8
    c.carve(332, 0, 420, 8)
    for x in range(332, 420):
        c.top[x] = 8
    # ---- salas
    c.carve(2, 15, 38, 25)                                  # R1 Vestibulo 36x10
    c.fill(14, 24, 26, 25, "#")
    c.carve(38, 22, 52, 25)                                 # pasillo A 14x3
    c.carve(52, 11, 96, 25)                                 # S2 Columnas 44x14
    for x0 in (58, 66, 74, 82, 90):
        c.fill(x0, 22, x0 + 2, 25, "#")
    c.carve(96, 21, 112, 25)                                # pasillo B 16x4
    c.carve(112, 21, 116, 25)
    c.carve(116, 3, 138, 25)                                # Embudo (22 de ancho arriba, 8 abajo, 22 de alto)
    for y in range(3, 25):
        k = (y - 3) // 3
        c.fill(116, y, 116 + k, y + 1, "#")
        c.fill(138 - k, y, 138, y + 1, "#")
    c.carve(112, 21, 121, 25); c.carve(96, 15, 121, 19)     # pasillo B y alameda llegan al embudo
    c.carve(130, 14, 147, 18)                               # boca media -> anillo
    c.plat(118, 122, 22, "="); c.plat(124, 128, 19, "="); c.plat(130, 134, 16, "="); c.plat(125, 129, 13, "=")
    c.plat(119, 123, 10, "="); c.plat(125, 129, 7, "="); c.plat(118, 122, 19, "=")
    c.carve(129, 3, 206, 7)                                 # boca superior: corredor alto sobre el anillo
    c.carve(200, 7, 205, 17)                                # pozo de la boca superior a la galeria (entre los dos muros)
    c.carve(144, 12, 168, 25); c.oval(156, 12, 12, 4, floor=13)   # S4 camara circular (rectangulo con cupula)
    c.fill(154, 11, 158, 25, "#")
    c.plat(146, 150, 23, "="); c.plat(150, 154, 20, "="); c.plat(146, 150, 17, "="); c.plat(150, 154, 14, "=")
    c.carve(166, 19, 174, 25)                               # salida del anillo
    # S5 galeria inclinada: suelo que sube 7 celdas
    for x in range(172, 230):
        f = 25 - (x - 172) // 8
        c.carve(x, f - 5, x + 1, f)
    # tapa de la boca superior sobre la galeria
    # gruta de salida (corredor ancho con ramificaciones)
    c.carve(228, 14, 398, 18)
    c.carve(296, 7, 308, 13)                                # Telarana (secreta, techo de ladrillos)
    c.plat(300, 302, 13, "B")
    c.carve(304, 19, 324, 25)                               # Tesoro 20x6
    c.carve(332, 8, 337, 14)                                # X1 pozo a la superficie
    c.plat(332, 335, 16, "="); c.plat(334, 337, 13, "="); c.plat(332, 335, 10, "=")
    c.carve(372, 8, 378, 14)                                # E2 boca del barranco (hoyo)
    c.plat(373, 376, 16, "="); c.plat(375, 378, 12, "=")
    c.carve(392, 8, 397, 14)                                # X2 ventana alta
    c.plat(392, 395, 16, "="); c.plat(394, 397, 13, "="); c.plat(392, 395, 10, "=")

    # ---- objetos
    c.set(4, 24, "P")
    c.coins(6, 23, 5); c.coins(30, 23, 5)
    c.set(45, 24, "C")
    # S2: pinchos, topos, columnas, interruptor 1 y su muro
    for x0 in (61, 77, 85):
        for dx in range(3):
            c.set(x0 + dx, 24, "^")
    c.set(55, 24, "z"); c.set(71, 24, "z"); c.set(93, 24, "z")
    c.set(75, 20, "*")
    c.set(95, 24, "/")
    c.fill(96, 21, 97, 25, "(")
    c.set(110, 24, "/")
    # alameda: topos y llave B
    for x in (99, 104, 109, 114):
        c.set(x, 18, "z")
    c.set(115, 18, "U")
    # embudo: lanzarrocas y premio
    c.set(141, 6, "0")
    # anillo: llave A, interruptor 2 y su espejo, reloj
    c.set(151, 13, "U")
    c.set(156, 10, "\\")
    c.set(160, 24, "I")
    c.set(148, 24, "C")
    c.set(169, 24, "\\")
    # galeria: muros conmutables con interruptores entre ellos
    for x, ch in ((190, "["), (206, "]")):
        f = 25 - (x - 172) // 8
        c.fill(x, f - 5, x + 1, f, ch)
    c.set(175, 24, "\\")
    f = 25 - (198 - 172) // 8
    c.set(198, f - 1, "\\")
    c.set(218, 25 - (218 - 172) // 8 - 1, "0"); c.set(226, 25 - (226 - 172) // 8 - 1, "0")
    c.set(228, 17, "C") if False else None
    # gruta: manantial (corriente), puertas, premios
    c.fill(250, 14, 280, 18, ":")
    c.set(292, 17, "C")
    c.set(300, 7 + 1, "*") if False else None
    c.set(302, 12, "*"); c.set(298, 12, "i"); c.coins(294, 12, 3); c.coins(303, 12, 3)
    c.set(312, 17, "A")
    c.warp((312, 17), (306, 24), "door", 1)
    c.set(306, 24, "A"); c.set(316, 24, "*"); c.set(320, 24, "M"); c.set(318, 24, "h"); c.coins(308, 24, 5); c.set(322, 24, "u")
    c.coins(236, 17, 8); c.coins(340, 17, 12)
    # exterior
    c.set(336, 7, "C")
    c.coins(340, 6, 8); c.coins(380, 6, 8)
    c.set(412, 7, "F")
    for x in (344, 356, 364, 384, 402):
        c.set(x, 7, "d")
    return c


def save():
    return build().save(4, **META, comments=("Cueva: red de 11 espacios; interruptores del grupo 1 (pasillo B) y 2 (galeria).",))


if __name__ == "__main__":
    c = build()
    a = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    b = int(sys.argv[2]) if len(sys.argv) > 2 else 130
    print(c.preview(a, b))

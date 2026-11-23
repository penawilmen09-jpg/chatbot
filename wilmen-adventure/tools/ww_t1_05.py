"""1-5 Copas Altas (340x32): copas de arboles unidas por lianas y setas, con La Red del Tronco (troncos huecos y rama hueca)."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from ww_cv import Cv

META = dict(title="Copas Altas", region=1, theme=1, time=340, par=130, diff=3, kind="normal", zone=0)


def crown(c, x0, x1, top, trunk=None, thick=2):
    c.fill(x0, top, x1, top + thick, "#")
    for x in range(x0, x1):
        c.top[x] = top
    if trunk:
        c.fill(trunk[0], top + thick, trunk[1], 32, "#")


def vine(c, x, top):
    """Liana de 10 celdas para un hueco de 9 entre copas a la altura `top` (plantilla validada en el taller)."""
    c.set(x, top - 15, "#")
    for r in range(top - 14, top - 4):
        c.set(x, r, "$")


def build():
    c = Cv(340, 32)
    c.land(0, 36, 30)
    crown(c, 28, 42, 26, (33, 37))
    crown(c, 51, 64, 26, (55, 59))
    crown(c, 67, 82, 19, (72, 76))
    crown(c, 93, 102, 19)
    crown(c, 109, 123, 19, (113, 117))
    crown(c, 132, 146, 19, (137, 143))       # tronco A (hueco)
    crown(c, 155, 164, 19); crown(c, 173, 182, 19)
    crown(c, 191, 205, 19, (195, 201))       # tronco B (hueco)
    crown(c, 214, 228, 19, (218, 222))
    crown(c, 231, 246, 12, (236, 240))
    crown(c, 255, 269, 12, (259, 263))
    crown(c, 278, 292, 12, (282, 286))
    crown(c, 295, 311, 9, (300, 304))        # copa de la meta
    crown(c, 313, 322, 2)                    # rama de la salida secreta
    for x, t in ((46, 26), (86, 19), (106, 19), (127, 19), (150, 19), (168, 19), (186, 19), (209, 19)):
        vine(c, x, t)
    # ---- La Red del Tronco
    c.fill(146, 27, 196, 32, "#")
    for x in range(146, 196):
        c.top[x] = 27
    c.carve(138, 21, 142, 32)                # tronco A: pozo 4x11
    c.carve(142, 28, 196, 31)                # tunel de la rama (54x3)
    c.carve(196, 21, 200, 32)                # tronco B: pozo 4x11
    c.carve(139, 19, 141, 21)                # boca en la copa A
    c.carve(197, 19, 199, 21)                # boca en la copa B
    c.plat(138, 140, 28, "="); c.plat(140, 142, 25, "="); c.plat(138, 140, 22, "=")
    c.plat(196, 198, 28, "="); c.plat(198, 200, 25, "="); c.plat(196, 198, 22, "=")
    c.carve(185, 27, 189, 29); c.plat(186, 189, 29, "=")      # ventana X2 a la rama
    c.plat(180, 182, 27, "B")                                  # ladrillos del techo: atajo
    c.plat(184, 187, 24, "="); c.plat(188, 191, 21, "=")       # peldanos de la rama a la copa B
    # ---- salas selladas en el cielo (solo por puerta)
    c.fill(4, 4, 18, 14, "#"); c.carve(6, 6, 16, 13)          # Nido del pajaro 10x7
    c.fill(22, 4, 36, 14, "#"); c.carve(24, 6, 34, 13)        # Terraza del atardecer 10x7

    c.set(3, 29, "P")
    c.arc(8, 26, 28, 3)
    c.coins(30, 25, 10)
    c.fill(50, 16, 56, 18, "#"); c.set(52, 18, "Y")           # murcielago sobre el aterrizaje de la liana 1
    c.coins(52, 25, 8)
    c.set(63, 25, "%")                                        # seta: C2 -> C3
    c.coins(69, 18, 12)
    c.set(72, 18, "%"); c.plat(76, 81, 12, "="); c.set(78, 11, "*")   # gema 1: seta a una repisa alta
    c.coins(94, 18, 7)
    c.fill(95, 9, 100, 11, "#"); c.set(97, 11, "Y")           # murcielago sobre la isla central
    c.coins(110, 18, 4)
    c.set(116, 18, "C")
    c.coins(133, 18, 10)
    c.coins(156, 18, 7); c.coins(174, 18, 7)
    c.set(160, 10, "f"); c.set(178, 10, "f")                  # voladores sobre el vano largo
    # Red del tronco: objetos
    c.set(160, 26, "U")                                       # llave A en la rama (ruta baja)
    c.set(190, 30, "U")                                       # llave B al fondo del tunel
    c.set(170, 30, "M"); c.set(174, 30, "l"); c.coins(167, 30, 3); c.set(176, 30, "*")
    c.coins(146, 30, 6); c.coins(180, 30, 4)
    # puertas a las salas del cielo
    c.set(203, 18, "A")
    c.warp((203, 18), (8, 12), "door", 1)
    c.set(8, 12, "A"); c.set(13, 12, "*"); c.set(11, 12, "u"); c.coins(9, 12, 2); c.coins(14, 12, 2)
    c.set(262, 11, "A")
    c.warp((262, 11), (26, 12), "door", 1)
    c.set(26, 12, "A"); c.set(32, 12, "q"); c.coins(27, 12, 4); c.coins(29, 11, 3); c.coins(33, 12, 1)
    # T oculta en la copa A -> tunel de la rama (secreto)
    c.set(135, 18, "T"); c.set(134, 18, "d")
    c.set(172, 30, "T")
    c.warp((135, 18), (172, 30), "tunnel")
    c.coins(215, 18, 12)
    c.set(220, 18, "C")
    c.set(227, 18, "%")                                       # seta: C7 -> C8
    c.coins(232, 11, 12)
    c.set(243, 11, "{")                                       # seta diagonal: C8 -> C9
    c.coins(256, 11, 12)
    c.set(267, 11, "{")                                       # seta diagonal: C9 -> C10
    c.fill(279, 5, 285, 7, "#"); c.set(282, 7, "Y")           # murcielago sobre C10
    c.coins(279, 11, 8)
    c.set(281, 11, "C")
    c.coins(301, 8, 5)
    c.set(299, 8, "F")
    c.set(309, 8, "%")                                        # seta de la salida secreta
    c.set(317, 1, "O")
    for x in (8, 18, 90, 118, 212, 224, 240, 262, 284):
        if c.top[x] < 32 and c.get(x, c.on(x)) == " ":
            c.set(x, c.on(x), "d")
    return c


def save():
    return build().save(5, **META, comments=("Subsuelo: La Red del Tronco (troncos huecos y rama hueca). Salida secreta (O) hacia la casa 1-7.",))


if __name__ == "__main__":
    c = build()
    a = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    b = int(sys.argv[2]) if len(sys.argv) > 2 else 130
    print(c.preview(a, b))

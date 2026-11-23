"""1-1 Sendero del Amanecer (520x30): colinas, setas y la Madriguera (red subterranea suave de 7 espacios)."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from ww_cv import Cv

META = dict(title="Sendero del Amanecer", region=1, theme=1, time=320, par=110, diff=1, kind="normal", zone=0)


def build():
    c = Cv(520, 30)
    # ---- superficie
    for a, b, t in [(0, 25, 16), (25, 45, 15), (45, 60, 16), (60, 75, 16), (75, 90, 15), (90, 103, 16), (103, 112, 9),
                    (112, 130, 15), (130, 150, 14), (150, 180, 13), (180, 230, 12), (230, 250, 12), (250, 270, 11),
                    (270, 290, 12), (290, 310, 11), (310, 330, 12),
                    (330, 342, 12), (345, 357, 12), (361, 371, 12), (376, 388, 12), (400, 444, 12),
                    (444, 448, 8), (448, 462, 12), (462, 520, 5)]:
        c.land(a, b, t)

    # ---- subsuelo: La Madriguera
    for i in range(8):                                   # E1: rampa de entrada (cols 66-73)
        c.carve(66 + i, 15 + i, 69 + i, 19 + i)
    c.carve(70, 22, 118, 26)                             # M1 Zanja 48x4
    c.carve(118, 16, 133, 26)                            # M2 Raiz hueca 15x10 con repisas
    c.plat(118, 123, 24, "#"); c.plat(126, 132, 21, "#"); c.plat(118, 124, 18, "#")
    c.oval(144, 22, 11, 5, floor=27)                     # M3 Sala del eco
    c.carve(132, 22, 135, 27)
    c.plat(146, 148, 25, "#"); c.plat(149, 151, 23, "#"); c.plat(152, 154, 21, "#")   # escalera a M6
    c.carve(154, 15, 182, 19)                            # M6 Balcon de raices
    c.fill(154, 19, 182, 20, "#")
    c.carve(176, 13, 182, 15)                            # X1: ventana a la superficie
    c.plat(176, 179, 17, "="); c.plat(179, 182, 15, "=")
    segs = [(156, 170, 27), (170, 186, 26), (186, 202, 25), (202, 218, 24)]   # M4 Galeria larga (suelo que sube)
    c.carve(154, 23, 157, 27)
    for a, b, f in segs:
        c.carve(a, f - 4, b, f)
        c.fill(a, f, b, 30, "#")
    c.carve(218, 12, 226, 24)                            # E3/X2: pozo del bosque alto
    c.plat(219, 222, 21, "="); c.plat(222, 225, 18, "="); c.plat(219, 222, 15, "=")
    c.carve(226, 20, 240, 24)                            # tramo oculto del pasadizo bajo tierra
    c.fill(218, 24, 240, 30, "#")
    c.carve(233, 16, 263, 19)                            # M7 pasadizo oculto 30x3 (techo de ladrillos)
    c.fill(233, 19, 263, 20, "#")
    c.plat(236, 238, 19, "B")
    c.plat(234, 237, 22, "#")
    c.carve(258, 11, 263, 16)                            # X3: salida a la colina
    c.plat(259, 262, 14, "=")
    c.carve(84, 17, 97, 21)                              # M5 Despensa secreta sobre la Zanja
    c.plat(84, 86, 21, "B")
    c.carve(452, 21, 467, 27)                            # Casita de piedra (sala sellada)

    # ---- objetos
    on = c.on
    c.set(3, on(3), "P")
    c.arc(8, 20, 13, 2); c.plat(14, 20, 12, "=")
    c.set(40, on(40), "w")                               # patrulla simple: enseña a pisar
    c.set(85, on(85), "w")                               # junto a la seta: enseña a esperar
    c.set(99, on(99), "%")                               # seta vertical
    c.coins(104, 8, 7); c.set(107, 7, "*")               # gema 1 en la repisa
    c.coins(70, 14, 5)
    c.set(100, 25, "w")                                  # caminante de la zanja
    c.set(120, 17, "U"); c.set(122, 17, "T")             # llave y llegada de la boca secreta
    c.set(190, 24, "I")
    c.set(170, 18, "u")
    c.set(92, 20, "k"); c.coins(88, 20, 3); c.coins(94, 20, 2); c.set(95, 19, "*")
    c.set(125, on(125), "T"); c.set(124, on(124), "d")
    c.warp((125, on(125)), (122, 17), "tunnel")
    for x0, x1, y in ((160, 167, 9), (175, 181, 8), (195, 201, 9)):
        c.plat(x0, x1, y, "="); c.coins(x0, y - 1, x1 - x0)
    c.set(205, on(205), "C")
    c.set(260, 9, "I")
    c.set(292, on(292), "A")
    c.warp((292, on(292)), (454, 26), "door", 1)
    c.set(454, 26, "A")
    c.coins(456, 25, 4); c.coins(461, 25, 3); c.set(465, 25, "*"); c.set(465, 24, "h")
    c.set(310, on(310), "w")
    c.set(331, on(331), "C")
    c.set(336, on(336), "j"); c.set(366, on(366), "j")
    c.set(386, on(386), "{")
    c.plat(390, 392, 10, "="); c.plat(393, 395, 9, "="); c.plat(396, 398, 10, "=")
    c.set(421, on(421), "C")
    c.arc(402, 418, 10, 2)
    c.set(340, on(340), "w")
    c.set(436, on(436), "{")
    c.plat(441, 443, 10, "=")
    c.plat(452, 455, 10, "="); c.plat(456, 459, 8, "="); c.plat(459, 462, 6, "=")
    c.set(458, on(458), "%")
    c.coins(463, 4, 8)
    c.set(512, 4, "F")
    # decoracion
    for x in (12, 30, 55, 78, 135, 165, 215, 240, 280, 320, 410, 430):
        if c.get(x, on(x)) == " ":
            c.set(x, on(x), "d")
    return c


def save():
    return build().save(1, **META, comments=("Subsuelo: La Madriguera (7 espacios, 3 entradas, 3 salidas). Setas: vertical, diagonal, cadena.",))


if __name__ == "__main__":
    c = build()
    import sys as _s
    a = int(_s.argv[1]) if len(_s.argv) > 1 else 0
    b = int(_s.argv[2]) if len(_s.argv) > 2 else 130
    print(c.preview(a, b))

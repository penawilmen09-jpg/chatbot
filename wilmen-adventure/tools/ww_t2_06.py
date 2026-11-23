"""1-6 Pantano Hundido (680x24): dos capas (troncos altos / lecho inundado con corrientes) y la tuberia hundida."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from ww_cv import Cv

META = dict(title="Pantano Hundido", region=1, theme=1, time=440, par=170, diff=3, kind="normal", zone=2)


def log(c, x0, x1, top):
    c.fill(x0, top, x1, top + 2, "#")
    for x in range(x0, x1):
        c.top[x] = top


def stairs(c, x):
    """Escalera de la capa baja a la alta (dos repisas de paso) que acaba en un tronco que empieza en x+8."""
    c.plat(x, x + 4, 15, "=")
    c.plat(x + 4, x + 7, 12, "=")
    c.plat(x + 6, x + 8, 10, "=")


def build():
    c = Cv(680, 24)
    c.land(0, 680, 18)                                   # lecho del pantano
    # troncos de la capa alta (x0, x1, top)
    L = [(4, 26, 9), (30, 52, 9), (56, 80, 8), (84, 110, 9), (114, 140, 9), (144, 168, 8), (172, 196, 9), (200, 226, 9),
         (230, 252, 8), (256, 282, 9), (286, 312, 9), (316, 342, 8), (346, 372, 9), (376, 402, 9), (406, 432, 8), (436, 462, 9),
         (466, 492, 9), (496, 522, 8), (526, 552, 9), (556, 582, 9), (586, 614, 8), (618, 646, 9), (650, 676, 9)]
    for a, b, t in L:
        log(c, a, b, t)
    for x in (30, 152, 270, 380, 490, 600):               # escaleras entre capas
        stairs(c, x - 8)
    # corrientes del lecho (4 filas) y de la capa baja
    for x0, x1, ch in ((60, 100, ":"), (156, 172, "."), (204, 244, ":"), (300, 336, "."), (440, 480, ":"), (520, 560, "."), (600, 640, ":")):
        c.fill(x0, 14, x1, 18, ch)
    # piedras solitarias sobre el lecho (gema 1)
    c.plat(187, 191, 16, "#")
    # la tuberia hundida: tunel bajo el lecho con corriente interior y una llave
    c.carve(254, 18, 258, 20); c.carve(256, 20, 288, 23)
    c.carve(286, 18, 290, 20)
    c.plat(254, 257, 19, "="); c.plat(287, 290, 19, "=")
    c.fill(258, 20, 286, 22, ":")
    # choza hundida sellada (sala bajo el lecho, solo por puerta)
    c.carve(32, 20, 56, 23)
    on = c.on
    c.set(5, 8, "P")
    # capa alta: enemigos con funcion
    for x, k in ((92, "j"), (210, "j"), (360, "j"), (480, "j"), (300, "t"), (550, "t")):
        t = c.top[x]
        c.set(x, t - 1, k)
    for x in (130, 310, 500):
        c.set(x, c.top[x] - 1, "&")
    # lecho: topos
    for x in (118, 182, 270, 392, 500):
        c.set(x, 17, "z")
    # monedas, premios
    for a, b, t in L:
        if (a // 7) % 2 == 0:
            c.coins(a + 3, t - 2, 6)
    c.set(189, 15, "*")
    c.set(330, 5, "*")
    c.set(378, 7, "I")
    c.set(175, 17, "C"); c.set(340, 7, "C"); c.set(510, 7, "C")
    c.set(272, 22, "U"); c.set(640, 8, "U")
    c.set(600, 7, "A"); c.set(34, 22, "A")
    c.warp((600, 7), (34, 22), "door", 1)
    c.set(50, 22, "*"); c.set(53, 22, "u"); c.coins(37, 22, 6); c.set(45, 22, "i")
    c.set(660, 8, "F")
    for x in (20, 100, 200, 300, 420, 540, 640):
        if c.get(x, c.top[x] - 1) == " ":
            c.set(x, c.top[x] - 1, "d")
    return c


def save():
    return build().save(6, **META, comments=("Dos capas: troncos altos y lecho inundado con corrientes; tuberia hundida bajo el lecho.",))


if __name__ == "__main__":
    c = build()
    a = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    b = int(sys.argv[2]) if len(sys.argv) > 2 else 130
    print(c.preview(a, b))

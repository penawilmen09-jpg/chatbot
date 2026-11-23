"""2-5 (nivel 25) Tormenta de Arena (480x26): cintas en contra, columnas de viento y desmoronables; salida secreta a la casa 2-7."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from ww_cv import Cv

META = dict(title="Tormenta de Arena", region=2, theme=3, time=420, par=160, diff=3, kind="normal", zone=0)


def build():
    c = Cv(480, 26)
    prof = [(0, 40, 16), (44, 80, 16), (84, 120, 15), (124, 150, 16), (154, 190, 15), (194, 230, 16), (234, 270, 14), (274, 310, 15),
            (314, 350, 14), (354, 390, 13), (394, 480, 12)]
    for a, b, t in prof:
        c.land(a, b, t)
    for x in range(44, 80):
        c.set(x, 16 - 0 if False else 15, "<")
    for x in range(154, 190):
        c.set(x, 14, "<")
    for x in range(274, 310):
        c.set(x, 14, "<")
    # columnas de viento sobre islas
    for gx in (112, 141, 222):
        pass
    c.land(121, 124, 15); c.fill(121, 8, 124, 15, "W"); c.plat(118, 128, 7, "=")
    # desmoronables a la salida secreta
    for i in range(7):
        c.fill(396 + 4 * i, 11 - i, 398 + 4 * i, 12 - i, "c")
    c.fill(420, 3, 432, 5, "#")
    c.set(426, 2, "O")
    c.set(3, 15, "P"); c.coins(8, 14, 8)
    c.set(30, 15, "w"); c.set(100, 14, "s"); c.set(210, 15, "j"); c.set(250, 13, "t"); c.set(290, 13, "w"); c.set(335, 13, "s")
    c.set(60, 14, "z") if False else None
    c.set(45, 15, "C"); c.set(200, 15, "C"); c.set(360, 12, "C")
    c.coins(50, 13, 8); c.coins(88, 13, 6); c.coins(160, 12, 10); c.coins(198, 13, 8); c.coins(240, 12, 8); c.coins(280, 12, 8); c.coins(320, 12, 8)
    c.set(123, 6, "*"); c.set(236, 13, "*") if False else None
    c.plat(214, 222, 10, "="); c.set(218, 9, "*")
    c.plat(330, 338, 9, "="); c.set(334, 8, "*")
    c.set(17, 4, "#")
    c.set(240, 13, "U") if False else None
    c.set(368, 12, "U")
    c.set(450, 11, "A"); c.warp((450, 11), (8, 10), "door", 1)
    c.fill(4, 2, 24, 12, "#"); c.carve(6, 4, 22, 11)
    c.set(8, 10, "A"); c.set(14, 10, "u"); c.set(18, 10, "h"); c.coins(10, 10, 6)
    c.set(470, 11, "F")
    for x in (18, 70, 105, 140, 175, 215, 255, 295, 330, 372):
        if c.top[x] < 26 and c.get(x, c.on(x)) == " ":
            c.set(x, c.on(x), "d")
    return c


def save():
    return build().save(25, **META, comments=("Tormenta: salida secreta (O) hacia la casa 2-7 (nivel 27).",))


if __name__ == "__main__":
    print(build().preview(0, 130))

"""1-9 Templo de los Tres Sellos (600x30): antesala, patio y tres camaras (norte con dardos, este con pendulos, oeste con la llave);
dos sellos de interruptor abren la camara del idolo; tres pasadizos subterraneos y una salida secreta."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from ww_cv import Cv

META = dict(title="Templo de los Tres Sellos", region=1, theme=1, time=420, par=160, diff=4, kind="normal", zone=3)


def build():
    c = Cv(600, 30)
    c.land(0, 600, 21)
    # camara norte (suelo alto con dardos) y camara oeste (suelo alto)
    c.fill(112, 13, 200, 15, "#"); c.fill(112, 6, 200, 8, "#")
    c.fill(20, 13, 100, 15, "#")
    for x in range(20, 100):
        c.top[x] = 13
    for x in range(112, 200):
        c.top[x] = 13
    c.plat(100, 104, 18, "="); c.plat(104, 108, 15, "=")      # peldanos del patio a la camara oeste/norte
    c.plat(106, 110, 18, "="); c.plat(108, 112, 15, "=") if False else None
    # camara este: techo con pendulos
    c.fill(300, 0, 440, 14, "#")
    # sala del idolo: techo y muros conmutables
    c.fill(440, 0, 600, 14, "#")
    c.fill(440, 14, 441, 21, "(")
    c.fill(448, 14, 449, 21, "[")
    # pilares en ruinas del patio
    for x0, h in ((140, 3), (176, 2), (214, 3), (250, 2)):
        c.fill(x0, 21 - h, x0 + 2, 21, "#")
        for x in (x0, x0 + 1):
            c.top[x] = 21 - h
    # ---- pasadizos secretos bajo el suelo
    c.carve(40, 25, 52, 28)          # A: 12
    c.carve(56, 25, 82, 28)          # B: 26 (con dardos)
    c.carve(88, 25, 128, 28)         # C: 40
    # sala secreta de la salida (bajo la sala del idolo)
    c.carve(556, 24, 584, 28)
    on = c.on
    c.set(4, 20, "P")
    c.coins(10, 19, 6)
    # enemigos y trampas con funcion
    c.set(70, 20, "D"); c.set(160, 20, "D"); c.set(232, 20, "D")
    for x, r in ((198, 12), (188, 10), (178, 12), (168, 10)):
        c.set(x, r, "\"")
    c.set(150, 12, "t"); c.set(130, 12, "t")
    for x in (330, 355, 380):
        for r in range(14, 19):
            c.set(x, r, "!")
    c.set(114, 12, "/")                                        # sello 1 (interruptor del grupo 1)
    c.set(410, 20, "\\")                                       # sello 2 (grupo 2)
    c.set(30, 12, "U")                                         # sello 3 / llave de la camara secreta
    c.set(140 - 1, 12, "*") if False else None
    c.set(160, 12, "o")
    c.set(122, 12, "*")
    c.set(395, 13, "*") if False else None
    c.plat(394, 399, 17, "="); c.set(396, 16, "*")
    c.set(80, 12, "*")
    c.set(105, 20, "C"); c.set(300, 20, "C"); c.set(430, 20, "C")
    c.set(360, 20, "I")
    c.coins(30, 12, 1) if False else None
    c.coins(40, 12, 12); c.coins(120, 20, 8); c.coins(260, 20, 8); c.coins(310, 20, 6); c.coins(470, 20, 14)
    c.set(560, 20, "A")
    c.warp((560, 20), (558, 27), "door", 1)
    c.set(558, 27, "A"); c.set(570, 27, "O"); c.coins(560, 27, 5); c.set(578, 27, "h")
    c.set(590, 20, "F")
    # tunel A: patio/antesala <-> corredor 12
    c.set(50, 20, "T"); c.set(41, 27, "T")
    c.warp((50, 20), (41, 27), "tunnel")
    c.set(51, 27, "T"); c.set(116, 20, "T")
    c.warp((51, 27), (116, 20), "tunnel")
    # tunel B (26, con dardos): patio -> camara este
    c.set(200, 20, "T"); c.set(57, 27, "T")
    c.warp((200, 20), (57, 27), "tunnel")
    c.set(81, 27, "T"); c.set(305, 20, "T")
    c.warp((81, 27), (305, 20), "tunnel")
    c.set(75, 27, "\"")
    # tunel C (40): patio este -> camara este tras los pendulos
    c.set(258, 20, "T"); c.set(89, 27, "T")
    c.warp((258, 20), (89, 27), "tunnel")
    c.set(127, 27, "T"); c.set(392, 20, "T")
    c.warp((127, 27), (392, 20), "tunnel")
    return c


def save():
    return build().save(9, **META, comments=("Templo: patio, tres camaras (dardos, pendulos, llave), dos sellos de interruptor, tres pasadizos y salida secreta.",))


if __name__ == "__main__":
    c = build()
    a = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    b = int(sys.argv[2]) if len(sys.argv) > 2 else 130
    print(c.preview(a, b))

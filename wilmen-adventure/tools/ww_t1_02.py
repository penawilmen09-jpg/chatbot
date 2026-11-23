"""1-2 Garganta de las Cascadas (360x32): ascenso en 3 terrazas con agua y El Panal (galerias dentro de la roca)."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from ww_cv import Cv

META = dict(title="Garganta de las Cascadas", region=1, theme=1, time=420, par=150, diff=1, kind="normal", zone=1)


def ledge(c, x0, x1, top, thick=2):
    c.fill(x0, top, x1, top + thick, "#")
    for x in range(x0, x1):
        c.top[x] = top


def build():
    c = Cv(360, 32)
    # ---- terraza 1: valle con poza
    c.land(0, 40, 29); c.land(56, 126, 29)
    for x0, x1 in ((43, 46), (49, 52), (54, 56)):
        c.fill(x0, 28, x1, 29, "#")
    c.fill(40, 25, 56, 28, ":")                      # corriente a la derecha (16x3) sobre la poza
    # R1: roca del pozo (cols 84-98), con el pozo vertical dentro
    c.land(84, 99, 17)
    c.carve(88, 17, 94, 29)                          # pozo 6x12
    c.carve(94, 26, 99, 29)                          # puerta baja al pozo (lado derecho)
    c.plat(88, 91, 26, "#"); c.plat(91, 94, 23, "#"); c.plat(88, 91, 20, "#")   # salientes alternos
    c.carve(94, 21, 99, 25); c.fill(94, 25, 99, 26, "#")                        # nicho 5x4 con la llave A
    c.fill(80, 17, 83, 29, ",")                      # BC1: columna de burbujas (subida 1)
    # ---- terraza 2: cadena de repisas sobre el vacio
    for x0, x1, t in ((100, 107, 17), (109, 116, 16), (118, 125, 17), (150, 165, 20), (168, 175, 19), (178, 185, 20),
                      (188, 195, 19), (198, 207, 20), (210, 222, 20)):
        ledge(c, x0, x1, t)
    c.land(126, 149, 17)                             # R5: macizo con la Cueva del arcoiris
    c.carve(128, 20, 147, 26)
    c.fill(159, 16, 165, 20, ".")                    # corriente a la izquierda (15x4) sobre la repisa
    # ---- R4: macizo sobre la terraza 2 con El Panal dentro (galerias)
    c.fill(150, 8, 222, 15, "#")
    for x in range(150, 222):
        c.top[x] = 8
    c.carve(154, 10, 198, 13)                        # P2 Galeria del goteo 44x3
    c.carve(198, 9, 220, 14)                         # P3 Camara de las cascadillas 22x5
    c.carve(150, 13, 154, 15); c.plat(150, 154, 15, "#"); c.plat(155, 158, 17, "=")   # E2: arco de entrada con peldanos
    c.carve(212, 8, 215, 9); c.plat(211, 215, 10, "=")     # X3: ventana a la cresta
    c.fill(222, 8, 226, 20, ",")                     # BC2: columna de burbujas (subida 2)
    # ---- terraza 3: cresta
    c.land(226, 263, 8)
    c.carve(236, 12, 248, 17)                        # Despensa del arcoiris
    c.carve(238, 20, 258, 27)                        # Mirador
    for x0, x1, t in ((264, 271, 7), (274, 283, 6), (310, 319, 5)):
        ledge(c, x0, x1, t)
    c.fill(288, 6, 307, 8, "#")                      # puente de piedra de 19 celdas
    for x in range(288, 307):
        c.top[x] = 6
    c.land(337, 360, 5)
    c.fill(322, 2, 337, 5, ":")                      # corriente a la derecha sobre el ultimo hueco
    # ---- objetos
    on = c.on
    c.set(3, 28, "P")
    c.arc(8, 26, 27, 2); c.coins(60, 27, 6); c.coins(100, 27, 8)
    c.set(121, 28, "C")
    c.set(30, 28, "w") if False else None
    for x in range(76, 80):
        c.set(x, 28, "^")
    for x in range(120, 125):
        c.set(x, 28, "^") if False else None
    # pozo: llave A en el nicho
    c.set(97, 24, "U"); c.coins(95, 24, 2)
    # secreto: T oculta tras la cascada 1 -> cueva del arcoiris
    c.set(119, 28, "T")
    c.set(130, 25, "T")
    c.warp((119, 28), (130, 25), "tunnel")
    c.set(140, 25, "*"); c.set(137, 25, "u"); c.coins(132, 25, 3)
    # terraza 2: enemigos y objetos
    c.set(80, 12, "f"); c.set(84, 11, "f")           # voladores sobre BC1
    c.coins(101, 16, 5); c.coins(110, 15, 5); c.coins(119, 16, 5)
    c.set(206, 19, "t")                              # disparador: cubre el tramo hacia la cascada 2
    c.set(202, 19, "C")
    c.coins(169, 18, 5); c.coins(189, 18, 5)
    # Panal
    c.set(160, 12, "I"); c.set(196, 12, "*")
    c.coins(170, 12, 8)
    c.set(205, 12, "f")                              # volador de la camara
    c.set(216, 12, "U"); c.set(218, 12, "A")
    c.warp((218, 12), (238, 16), "door", 1)
    c.set(238, 16, "A"); c.set(244, 16, "u"); c.coins(240, 16, 3); c.coins(245, 16, 2)
    # terraza 3
    c.set(291, 5, "C")
    c.set(276, 5, "t")
    c.coins(266, 6, 5); c.coins(276, 4, 5); c.coins(290, 5, 14)
    c.set(325, 5, "m"); c.set(331, 5, "m")
    c.set(342, 4, "A")
    c.warp((342, 4), (240, 26), "door", 1)
    c.set(240, 26, "A"); c.set(255, 26, "*"); c.set(252, 26, "h"); c.set(248, 26, "i"); c.set(246, 25, "M")
    c.coins(342, 3, 4)
    c.set(352, 4, "F")
    return c


def save():
    return build().save(2, **META, comments=("Subsuelo: El Panal (galerias en la roca), pozo vertical, cueva tras la cascada.",))


if __name__ == "__main__":
    c = build()
    a = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    b = int(sys.argv[2]) if len(sys.argv) > 2 else 130
    print(c.preview(a, b))

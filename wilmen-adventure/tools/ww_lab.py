#!/usr/bin/env python3
"""Genera levels/world/ww_950.txt: el TALLER DE MECANICAS de WILMEN WORLD (tanda 0).

Un recorrido de 450x30 con una estacion por cada mecanica nueva, en orden de dificultad. No cuenta para el progreso ni se
guarda (se abre desde Menu > Taller de mecanicas en el mapa). Sirve para probar las mecanicas en el telefono antes de usarlas
en los niveles definitivos. Estaciones (columna aproximada): 1 setas 30-70 | 2 lianas 72-116 | 3 troncos 118-160 |
4 plataformas que desaparecen 164-200 | 5 puente que se derrumba 206-236 | 6 interruptores 240-310 | 7 corrientes 312-380 |
8 dardos y pendulo 382-404 | 9 orbital y ascensor 405-450.
"""
import os

W, H, GT = 450, 30, 25  # ancho, alto y fila del suelo
g = [[" "] * W for _ in range(H)]


def put(x, y, c):
    if 0 <= x < W and 0 <= y < H:
        g[y][x] = c


def fill(x0, y0, x1, y1, c):
    for y in range(y0, y1):
        for x in range(x0, x1):
            put(x, y, c)


def ground(x0, x1):
    fill(x0, GT, x1, H, "#")


def coins(x, y, n):
    for i in range(n):
        put(x + i, y, "o")


for a, b in [(0, 57), (67, 82), (91, 100), (109, 164), (197, 206), (237, 405), (416, 429)]:
    ground(a, b)
fill(432, 20, 450, H, "#")

put(3, GT - 1, "P")

# 1) SETAS: vertical hasta la repisa y diagonal sobre el foso
put(34, GT - 1, "%")
fill(38, 18, 47, 20, "#")
coins(39, 16, 6)
put(55, GT - 1, "{")
coins(60, 17, 4)
put(70, GT - 1, "C")

# 2) LIANAS: dos lianas de 10 celdas sobre fosos (la liana se agarra en el aire y se suelta con la velocidad del balanceo)
for k in range(10):
    put(86, 11 + k, "$")
    put(104, 11 + k, "$")
put(86, 10, "#")
put(104, 10, "#")
coins(93, GT - 3, 4)
put(116, GT - 1, "C")

# 3) TRONCOS: tolva en una repisa elevada; los troncos bajan y ruedan por el suelo hacia el jugador
fill(148, 17, 153, 19, "#")
put(150, 16, "&")
fill(130, 21, 134, 22, "#")
coins(130, 19, 4)
coins(125, GT - 2, 3)
put(160, GT - 1, "C")

# 4) PLATAFORMAS QUE DESAPARECEN: cadena sobre el foso 164..196
for (x, y) in [(167, 24), (173, 23), (179, 22), (185, 23), (191, 24)]:
    fill(x, y, x + 3, y + 1, "-")
coins(167, 22, 3)
coins(179, 20, 3)
put(202, GT - 1, "C")

# 5) PUENTE QUE SE DERRUMBA: 31 tablas a la altura del suelo (206..236); hay que cruzarlo sin detenerse
fill(206, GT, 237, GT + 1, "_")
coins(212, GT - 3, 16)

# 6) INTERRUPTORES: muro ( que se abre, escalones ) sobre el foso y escalera ] con el segundo interruptor
put(250, GT - 1, "/")
fill(262, 19, 263, GT, "(")
fill(266, GT, 280, H, " ")
fill(266, GT, 280, GT + 1, ")")
put(284, GT - 1, "\\")
for i, y in enumerate([23, 22, 21, 20]):
    fill(288 + i * 2, y, 290 + i * 2, y + 1, "]")
fill(296, 19, 302, 20, "#")
coins(296, 17, 6)
put(310, GT - 1, "C")

# 7) CORRIENTES: rio hacia la derecha, tramo a contracorriente y columna de burbujas hasta una repisa alta
fill(314, 19, 334, GT, ":")
fill(338, 19, 345, GT, ".")
fill(360, 11, 362, GT, ",")
fill(358, 11, 359, 13, "#")
fill(364, 11, 372, 13, "#")
coins(365, 9, 5)
put(380, GT - 1, "C")

# 8) DARDOS Y PENDULO
put(390, GT - 1, "\"")
fill(398, 16, 399, 17, "#")
for k in range(7):
    put(398, 17 + k, "!")

# 9) PLATAFORMA ORBITAL y ASCENSOR
put(410, 23, "n")
put(420, GT - 1, "C")
put(429, 25, "b")
put(442, 19, "F")

out = "; WILMEN WORLD - Taller de mecanicas (tanda 0). Nivel de pruebas: no cuenta para el progreso ni se guarda.\n"
out += "; Generado por tools/ww_lab.py. Estaciones: setas, lianas, troncos, plataformas que desaparecen, puente, interruptores,\n"
out += "; corrientes, dardos y pendulo, orbital y ascensor.\n"
out += "@title Taller de mecanicas\n@region 1\n@theme 1\n@time 900\n@difficulty 2\n@kind normal\n@zone 0\n"
out += "\n".join("".join(r).rstrip() for r in g) + "\n"
path = os.path.join(os.path.dirname(__file__), "..", "levels", "world", "ww_950.txt")
open(path, "w").write(out)
print("escrito", os.path.normpath(path))

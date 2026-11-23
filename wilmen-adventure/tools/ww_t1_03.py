"""1-3 Puente de los Mil Pasos (820x24): pilares y puentes sobre un abismo, con Las Torres Huecas (salones y viaductos)."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from ww_cv import Cv

META = dict(title="Puente de los Mil Pasos", region=1, theme=1, time=430, par=170, diff=2, kind="normal", zone=2)


def pillar(c, x0, x1, top):
    c.land(x0, x1, top)


def bridge(c, x0, x1, row):
    c.fill(x0, row, x1, row + 1, "_")
    for x in range(x0, x1):
        c.top[x] = row


def chain(c, x0, n, rows):
    for i in range(n):
        c.fill(x0 + i * 6, rows[i % len(rows)], x0 + i * 6 + 3, rows[i % len(rows)] + 1, "-")


def arch(c, x0, x1, y):
    c.fill(x0, y, x1, y + 2, "#")


def build():
    c = Cv(820, 24)
    # ---- pilares y puentes
    pillar(c, 0, 40, 14)
    bridge(c, 40, 72, 14)
    pillar(c, 72, 100, 14)
    chain(c, 103, 5, [14, 13, 12, 13, 14])
    pillar(c, 133, 168, 12)
    bridge(c, 168, 189, 12)
    bridge(c, 189, 210, 14)
    pillar(c, 210, 238, 14)
    for x0 in (242, 251, 260, 269):
        pillar(c, x0, x0 + 3, 14)
    for x in (246, 255, 264):
        c.fill(x, 15, x + 1, 16, "c")     # desmoronable intermedio
    pillar(c, 300, 340, 12)
    bridge(c, 340, 370, 13)
    pillar(c, 370, 376, 13)
    bridge(c, 376, 406, 13)
    pillar(c, 406, 440, 13)
    pillar(c, 440, 452, 13)
    bridge(c, 452, 466, 13)
    pillar(c, 466, 480, 13)
    chain(c, 483, 2, [13, 12])
    pillar(c, 496, 508, 13)
    bridge(c, 508, 532, 13)
    pillar(c, 532, 550, 13)
    bridge(c, 550, 564, 13)
    pillar(c, 564, 582, 13)
    chain(c, 585, 1, [13])
    pillar(c, 592, 612, 17)
    pillar(c, 621, 645, 17)                # liana sobre un hueco de 9 celdas (612-620)
    pillar(c, 645, 670, 13)
    bridge(c, 670, 700, 13)
    pillar(c, 700, 730, 14)
    bridge(c, 730, 760, 14)
    pillar(c, 760, 820, 14)
    # liana (ancla en fila 2, 10 celdas)
    c.set(616, 2, "#")
    for r in range(3, 13):
        c.set(616, r, "$")
    # ---- arcos de piedra (donde cuelgan los murcielagos)
    for x0, x1, y in ((50, 66, 6), (108, 124, 5), (176, 200, 3), (247, 270, 6), (372, 384, 7), (520, 530, 5)):
        arch(c, x0, x1, y)
    # ---- subsuelo: Las Torres Huecas
    # H1: salon del pilar 3 (20x8) con pozo de acceso y escalones
    c.carve(140, 15, 160, 23)
    c.carve(148, 12, 154, 15)
    c.plat(148, 151, 14, "="); c.plat(151, 154, 17, "="); c.plat(148, 151, 20, "=")
    # V1: viaducto del eco (cols 160-214): tubo cerrado de 4 de alto
    c.fill(160, 18, 214, 24, "#")
    c.carve(160, 19, 214, 23)
    c.set(160, 23, "#") if False else None
    # H2: salon del pilar 4 (18x7)
    c.carve(214, 16, 232, 23)
    c.carve(222, 14, 227, 16)
    c.plat(222, 225, 15, "="); c.plat(225, 228, 18, "="); c.plat(220, 223, 20, "=")
    c.plat(228, 232, 19, "#")              # cornisa con la llave B
    # V2: pasaje largo (cols 232-304) con ensanche-nicho
    c.fill(232, 18, 304, 24, "#")
    c.carve(232, 19, 304, 23)
    c.carve(264, 14, 278, 23)              # nicho 14x9
    c.plat(264, 267, 19, "#"); c.plat(270, 274, 16, "#")
    # H3: salon del pilar 5 (20x8)
    c.carve(300, 15, 322, 23)
    c.carve(310, 12, 316, 15)
    c.plat(310, 313, 14, "="); c.plat(313, 316, 17, "="); c.plat(310, 313, 20, "=")
    # camara sellada (door) dentro del pilar 5
    c.carve(326, 16, 338, 23)
    # balcon del altar dentro del ultimo pilar
    c.carve(796, 16, 808, 23)

    on = c.on
    c.set(3, on(3), "P")
    # superficie: monedas y objetos
    c.arc(8, 36, 12, 2)
    c.coins(46, 12, 20); c.coins(80, 12, 15)
    c.set(57, 8, "Y")
    c.set(116, 7, "Y"); c.set(118, 9, "*")
    c.coins(104, 12, 3); c.coins(122, 11, 3)
    c.set(160, 11, "C")
    c.set(188, 5, "Y"); c.set(182, 8, "f"); c.set(200, 9, "f")
    c.coins(172, 10, 14)
    c.coins(214, 12, 10)
    c.set(258, 8, "Y")
    c.coins(243, 11, 3); c.coins(252, 11, 3); c.coins(261, 11, 3)
    c.set(338, 11, "C")
    c.coins(344, 11, 22)
    c.set(370, 12, "S")                      # resorte: lanza al arco de la gema 2
    c.set(376, 6, "*"); c.set(374, 6, "M")
    c.coins(380, 12, 20)
    c.set(452, 12, "j") if False else None
    c.coins(445, 12, 6); c.coins(470, 11, 8); c.coins(520, 12, 10)
    c.set(576, 12, "C")
    c.coins(600, 15, 6)
    c.set(660, 12, "f") if False else None
    c.coins(676, 12, 20); c.coins(706, 13, 20); c.coins(740, 13, 14)
    c.set(640, 16, "f") if False else None
    # voladores del hueco ancho
    c.set(640, 10, "f")
    # puertas
    c.set(790, on(790), "A")
    c.warp((790, on(790)), (798, 22), "door", 1)
    c.set(798, 22, "A"); c.set(802, 22, "*"); c.set(804, 22, "h"); c.set(800, 21, "M"); c.coins(799, 22, 1)
    c.set(810, on(810), "F")
    # subsuelo: objetos
    c.set(150, 22, "w") if False else None
    for x, r in ((180, 22), (192, 20), (204, 22)):
        c.set(x, r, "\"")
    for x, r in ((250, 22), (258, 20), (284, 22), (294, 20)):
        c.set(x, r, "\"")
    c.set(271, 15, "U")                      # llave A en el nicho
    c.set(230, 18, "U")                      # llave B en la cornisa del salon 2
    c.set(321, 22, "A")
    c.warp((321, 22), (328, 22), "door", 1)
    c.set(328, 22, "A"); c.set(334, 22, "l"); c.coins(330, 22, 3); c.coins(335, 22, 2)
    c.set(272, 22, "*") if False else None
    # boca oculta en el pilar 4 -> salon 2
    c.set(235, on(235), "T"); c.set(234, on(234), "d")
    c.set(218, 22, "T")
    c.warp((235, on(235)), (218, 22), "tunnel")
    c.coins(150, 22, 3); c.coins(220, 22, 3); c.coins(306, 22, 4)
    c.set(112, 7, "d") if False else None
    for x in (12, 28, 78, 90, 140, 160, 218, 232, 310, 330, 415, 430, 540, 572, 625, 635, 710, 770, 780):
        if c.top[x] < 24 and c.get(x, on(x)) == " ":
            c.set(x, on(x), "d")
    return c


def save():
    return build().save(3, **META, comments=("Subsuelo: Las Torres Huecas (3 salones y 2 viaductos con dardos).",))


if __name__ == "__main__":
    c = build()
    a = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    b = int(sys.argv[2]) if len(sys.argv) > 2 else 130
    print(c.preview(a, b))

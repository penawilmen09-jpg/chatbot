"""2-3 (nivel 23) Canon de Arenisca (400x28): paredes de roca, plataformas, prensas de arenisca y cintas."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from ww_cv import Cv

META = dict(title="Canon de Arenisca", region=2, theme=3, time=380, par=140, diff=2, kind="normal", zone=0)


def build():
    c = Cv(400, 28)
    c.land(0, 40, 22)
    xs = (46, 64, 20), (67, 90, 18), (93, 116, 20), (119, 150, 22), (153, 180, 19), (183, 214, 17), (217, 250, 20), (253, 290, 22), (293, 330, 19), (333, 364, 17), (367, 400, 15)
    for a, b, t in xs:
        c.land(a, b, t)
    # cintas
    for x in range(124, 150):
        c.set(x, 21, ">")
    for x in range(220, 250):
        c.set(x, 19, "<")
    # prensas sobre el suelo (techo de roca arriba)
    for px, py in ((80, 12), (106, 14)):
        c.fill(px - 1, py - 3, px + 3, py, "#")
        c.extra.append("@press %d,%d,2" % (px, py))
    c.set(3, 21, "P"); c.coins(8, 20, 8)
    c.set(30, 21, "z"); c.set(55, 19, "w"); c.set(84, 17, "s"); c.set(130, 20, "j")
    c.set(170, 18, "S"); c.set(200, 16, "t"); c.set(268, 21, "w"); c.set(310, 18, "s"); c.set(350, 16, "j")
    for x in (170, 171):
        pass
    c.set(38, 21, "C"); c.set(160, 18, "C"); c.set(300, 18, "C")
    c.coins(50, 18, 6); c.coins(100, 18, 6); c.coins(165, 16, 8); c.coins(192, 14, 8); c.coins(264, 19, 8); c.coins(342, 14, 8)
    # plataformas altas con gemas
    c.plat(98, 103, 16, "="); c.set(100, 15, "*")
    c.plat(224, 232, 13, "="); c.set(228, 12, "*")
    c.plat(260, 272, 15, "="); c.plat(300, 310, 12, "="); 
    # llave y puerta (sala de arenisca)
    c.fill(4, 2, 24, 12, "#"); c.carve(6, 4, 22, 11)
    c.set(130, 19, "U") if False else None
    c.set(212, 16, "U")
    c.set(375, 14, "A"); c.warp((375, 14), (8, 10), "door", 1)
    c.set(8, 10, "A"); c.set(18, 10, "*"); c.set(14, 10, "u"); c.coins(10, 10, 6)
    c.set(385, 14, "F")
    c.set(240, 18, "y") if False else None
    c.set(70, 17, "Y") if False else None
    for x in (12, 60, 90, 140, 175, 205, 240, 280, 320, 350):
        if c.top[x] < 28 and c.get(x, c.on(x)) == " ":
            c.set(x, c.on(x), "d")
    return c


def save():
    return build().save(23, **META, comments=("Canon: roca y cintas, prensas de arenisca.",))


if __name__ == "__main__":
    print(build().preview(0, 130))

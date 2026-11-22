"""Región 1 - Bosque Esmeralda: los 20 niveles de WILMEN WORLD, compuestos a mano (cada uno con su propio concepto).
Orden y tipo: 1 normal · 2 normal · 3 normal · 4 cueva · 5 normal (salida secreta) · 6 normal · 7 casa de bonificación (oculta)
· 8 normal · 9 normal (salida secreta) · 10 fortaleza · 11 normal · 12 normal · 13 cueva (salida secreta) · 14 normal · 15 normal ·
16 normal · 17 normal · 18 normal · 19 ruta secreta (dos salidas) · 20 castillo con jefe."""
import ww_pieces as P
from ww_pieces import *

CELL = 16.0 / 125.0
MULT = {1: 3.9, 2: 3.7, 3: 3.5, 4: 3.3, 5: 3.1}


class Seq:
    def __init__(self):
        self.c = Cv()
        self.x = 0
        self.gt = 15
        self.names = []
        self.marks = {}
        self.rooms = []
        self.links = []
        self.cps = 0

    def _a(self, name, nx):
        self.names.append(name)
        self.x = nx

    # --- piezas
    def flat(self, w, **k):
        self._a("flat", flat(self.c, self.x, w, gt=self.gt, **k))

    def cp(self, w=6):
        self._a("checkpoint", checkpoint(self.c, self.x, gt=self.gt, w=w))
        self.cps += 1

    def pits(self, seq, **k):
        self._a("pits", stepping_pits(self.c, self.x, seq, gt=self.gt, **k))

    def planks(self, seq):
        self._a("planks", oneway_pits(self.c, self.x, seq, gt=self.gt))

    def spikes(self, w, patches, **k):
        self._a("spikes", spike_run(self.c, self.x, w, patches, gt=self.gt, **k))

    def mover(self, gap, kind="m", **k):
        self._a("mover" + kind, mover_gap(self.c, self.x, gap, kind, gt=self.gt, **k))

    def crumble(self, plats, **k):
        self._a("crumble", crumble_run(self.c, self.x, plats, gt=self.gt, **k))

    def crush(self, w, crushers, **k):
        self._a("crusher", crusher_hall(self.c, self.x, w, crushers, gt=self.gt, **k))

    def geyser(self, w, geysers, **k):
        self._a("geyser", geyser_field(self.c, self.x, w, geysers, gt=self.gt, **k))

    def wind(self, **k):
        self._a("wind", wind_lift(self.c, self.x, gt=self.gt, **k))

    def belt(self, w, belt, **k):
        self._a("conveyor", conveyor(self.c, self.x, w, belt, gt=self.gt, **k))

    def hill(self, w, h, **k):
        self._a("plateau", plateau(self.c, self.x, w, h, gt=self.gt, **k))

    def up(self, dy):
        nx, ng = rise(self.c, self.x, dy, self.gt)
        self.names.append("rise")
        self.x, self.gt = nx, ng

    def down(self, dy):
        nx, ng = fall(self.c, self.x, dy, self.gt)
        self.names.append("fall")
        self.x, self.gt = nx, ng

    def isles(self, spec, **k):
        self._a("islands", islands(self.c, self.x, spec, gt=self.gt, **k))

    def river(self, spec, **k):
        self._a("river", log_river(self.c, self.x, spec, gt=self.gt, **k))

    def bounce(self, w, springs, **k):
        self._a("bounce", bounce_field(self.c, self.x, w, springs, gt=self.gt, **k))

    def cave(self, w, **k):
        self._a("cave", cave_hall(self.c, self.x, w, gt=self.gt, **k))

    def tops(self, spec, **k):
        self._a("treetops", treetops(self.c, self.x, spec, gt=self.gt, **k))

    def thorns(self, w, pattern, **k):
        self._a("thorns", thorns(self.c, self.x, w, pattern, gt=self.gt, **k))

    def sniper(self, w, pillars, **k):
        self._a("sniper", sniper(self.c, self.x, w, pillars, gt=self.gt, **k))

    def bastion(self, w, **k):
        self._a("bastion", bastion(self.c, self.x, w, gt=self.gt, **k))

    def ruins(self, w, **k):
        self._a("ruins", ruins(self.c, self.x, w, gt=self.gt, **k))

    def lianas(self, spec):
        self._a("lianas", lianas(self.c, self.x, spec, gt=self.gt))

    def fall_water(self, **k):
        self._a("waterfall", waterfall(self.c, self.x, gt=self.gt, **k))

    def mud(self, w, **k):
        self._a("mud", mud(self.c, self.x, w, gt=self.gt, **k))

    def tower(self, steps, **k):
        nx, lx, ty = tower(self.c, self.x, steps, gt=self.gt, **k)
        self.names.append("tower")
        self.x = nx
        return lx, ty

    def gate(self, h=3):
        self._a("gate", gate_wall(self.c, self.x, gt=self.gt, h=h))

    # --- marcas y objetos sueltos
    def fork(self, w, **k):
        self._a("fork", P.fork(self.c, self.x, w, gt=self.gt, **k))

    def mark(self, name, dx):
        self.marks[name] = (self.x + dx, self.gt - 1)

    def mouth(self, name, w=14, **k):
        """Un tramo de suelo con una marca de túnel/puerta en su mitad."""
        self.marks[name] = (self.x + w // 2, self.gt - 1)
        self.flat(w, **k)

    def item(self, ch, back=6):
        """Objeto suelto (llave, reloj) dentro del tramo de suelo que acaba de colocarse."""
        self.c.set(self.x - back, self.gt - 1, ch)

    def put(self, dx, dy, ch):
        self.c.set(self.x + dx, self.gt - dy, ch)

    def start(self):
        self.c.set(3, self.gt - 1, "P")

    def goal(self, secret_goal=False):
        self.flat(10, coin=[(1, 9, 3)])
        self.c.set(self.x - 5, self.gt - 1, "F")
        self.flat(6)

    # --- salas y conexiones
    def room(self, kind, **k):
        self.rooms.append((kind, k))
        return len(self.rooms) - 1

    def link(self, a, b, kind, key=0):
        self.links.append((a, b, kind, key))

    def finish(self, n, title, theme, diff, kind="normal", zone=None, notes=(), boss=0):
        c = self.c
        main_end = self.x
        cells = {}
        rx = main_end
        for i, (rk, kw) in enumerate(self.rooms):
            gapw = 10
            c.fill(rx, 0, rx + gapw, R, "#")
            rx += gapw
            ent, ext, rx2 = side_room(c, rx, rk, **kw)
            cells[(i, "in")] = ent
            cells[(i, "out")] = ext
            rx = rx2
        c.ensure(rx)

        def solid_ok(x, y):
            return c.get(x, y) in " d" and c.get(x, y + 1) == "#" and c.get(x, y - 1) in " do" and c.get(x, y - 2) in " do"

        def fixed(name):
            """Mueve la marca a la celda firme más cercana (sin pinchos ni enemigos al lado, con suelo a ambos lados)."""
            mx, my = self.marks[name]
            for d in sorted(range(-10, 11), key=lambda t: abs(t)):
                x = mx + d
                if all(solid_ok(x + k, my) for k in (-2, -1, 0, 1, 2)) and not any(c.get(x + k, my) in "^pSwsjftmvC" for k in (-2, -1, 0, 1, 2)):
                    return (x, my)
            raise ValueError("marca %s sin sitio firme cerca de %s" % (name, self.marks[name]))

        def res(spec):
            if spec[0] == "mark":
                return fixed(spec[1])
            return cells[(spec[1], spec[2])]

        for (a, b, k, key) in self.links:
            warp(c, res(a), res(b), k, key=key)
        cols = c.w
        t = int(round(cols * CELL * MULT[diff] / 5.0) * 5)
        write(n, c, title, 1, theme, t, diff, list(notes), kind=kind, zone=zone, boss=boss, pieces=self.names)
        return cols, self.cps


def gem_at(S, x0, dx, dy):
    S.c.set(x0 + dx, S.gt - dy, "*")


# ---------------------------------------------------------------------------------- 1
def l01():
    """Claro del Alba: presentación larga y amable. Túnel a la bodega (llave) y puerta con cerradura a una cámara."""
    S = Seq()
    S.flat(28, foe=[(16, "w"), (22, "w")], coin=[(4, 14, 3)])
    S.start()
    S.pits([(3, 4, 0), (4, 3, 1), (3, 4, 0), (4, 3, 2)], foe_on=[1])
    S.flat(12, foe=[(5, "s"), (9, "w")], coin=[(2, 10, 3)])
    S.spikes(30, [(7, 2), (14, 3), (22, 2)], shelf=[(9, 10, 6)], foe=[(26, "w")])
    S.planks([(3, 12, 4), (3, 11, 4), (4, 10, 4), (3, 12, 4)])
    S.cp()
    S.mark("A", 14)
    S.flat(18, foe=[(6, "j"), (12, "w")], coin=[(3, 15, 3)], prop=6)
    S.hill(8, 3, foe=[(3, "w")])
    S.mover(8, "m")
    S.flat(12, foe=[(4, "t")], coin=[(2, 10, 3)])
    S.crumble([(2, 3), (3, 3), (2, 2), (3, 3)])
    S.flat(14, foe=[(4, "w"), (9, "s")])
    S.put(8, 1, "I")
    lx, ty = S.tower([(1, 12), (5, 9), (1, 6)], top_y=6, ledge=6)
    S.c.set(lx + 2, ty - 1, "*")
    S.flat(14, foe=[(5, "w"), (9, "j")], coin=[(2, 12, 3)])
    S.cp()
    S.spikes(34, [(5, 2), (10, 2), (15, 3), (22, 2), (27, 2)], shelf=[(6, 11, 4), (16, 10, 5)], foe=[(12, "w"), (30, "s")])
    S.pits([(4, 3, 0), (4, 3, 1), (5, 3, 0), (4, 3, 2), (4, 3, 0)], foe_on=[0, 3])
    S.mark("B", 3)
    S.flat(16, foe=[(7, "w")], coin=[(2, 14, 3)])
    S.mover(9, "v", coin_y=4)
    S.flat(12, foe=[(5, "w"), (8, "j")])
    S.put(7, 1, "M")
    S.crumble([(2, 3), (2, 3), (3, 2), (2, 3), (3, 3)])
    S.flat(14, foe=[(4, "t"), (9, "w")], coin=[(2, 12, 3)])
    S.cp()
    S.hill(10, 2, foe=[(3, "j"), (6, "w")])
    S.spikes(30, [(4, 3), (10, 3), (17, 4), (24, 2)], shelf=[(6, 11, 5), (13, 10, 5), (20, 11, 5)], foe=[(8, "w"), (27, "w")])
    S.mark("D", 6)
    S.flat(20, foe=[(12, "w")], coin=[(2, 18, 3)])
    S.pits([(3, 3, 1), (4, 3, 0), (3, 3, 2)], foe_on=[1])
    S.goal()
    r0 = S.room("key", key=True, gems=1)
    r1 = S.room("vault", gems=1)
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "D"), ("room", r1, "in"), "door", key=1)
    return S.finish(1, "Claro del Alba", 1, 1, zone=0, notes=["Presentación del Bosque Esmeralda, larga pero amable.", "Túnel A a la bodega (llave y gema), que sale tras el tramo de espinas; la llave abre la puerta de la cámara."])


# ---------------------------------------------------------------------------------- 2
def l02():
    """Senda de las Luciérnagas: de noche; pozos con troncos, copas y un atajo de túnel."""
    S = Seq()
    S.flat(24, foe=[(14, "j"), (19, "w")], coin=[(3, 12, 3)])
    S.start()
    S.river([("log", 3, 4), ("rock", 3, 3), ("log", 3, 4), ("log", 4, 3)])
    S.flat(12, foe=[(4, "w"), (8, "t")])
    S.tops([(3, 4, 4), (4, 6, 4), (4, 4, 4), (3, 7, 4)], foe=[(12, "f")])
    S.flat(14, foe=[(6, "w"), (10, "s")], coin=[(2, 12, 3)])
    S.item("U", 4)
    S.cp()
    S.mark("A", 10)
    S.thorns(30, [(5, 1), (9, 1), (13, 1), (17, 2), (23, 1), (26, 1)], shelf=[(8, 4, 5), (19, 5, 5)], foe=[(12, "w"), (28, "w")])
    S.mover(9, "m")
    S.flat(14, foe=[(5, "j"), (9, "w")], coin=[(2, 12, 3)])
    S.put(8, 1, "I")
    S.hill(10, 3, foe=[(4, "w"), (7, "s")])
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 3), (2, 2)])
    S.flat(10, foe=[(4, "w")])
    S.cp()
    S.pits([(4, 3, 0), (4, 3, 2), (4, 3, 0), (5, 3, 1), (4, 3, 0)], foe_on=[1, 3])
    S.mark("B", 5)
    S.flat(18, foe=[(5, "j"), (9, "t"), (13, "w")], coin=[(2, 16, 3)])
    lx, ty = S.tower([(1, 12), (5, 9), (1, 6)], top_y=6, ledge=5)
    S.c.set(lx + 2, ty - 1, "*")
    S.flat(12, foe=[(5, "w")], coin=[(2, 10, 3)])
    S.sniper(22, [(5, 2), (11, 2), (17, 2)], foe=[(8, "w")])
    S.cp()
    S.mover(8, "v", coin_y=4)
    S.flat(14, foe=[(4, "w"), (9, "j")])
    S.river([("log", 3, 3), ("rock", 3, 3), ("log", 4, 4), ("rock", 3, 3)])
    S.cp()
    S.isles([(3, 4, 0, 3), (4, 4, 1, 3), (4, 3, 2, 3), (4, 4, 1, 3), (4, 3, 0, 3)], foe=[(12, "f")])
    S.flat(14, foe=[(5, "w"), (9, "j")], coin=[(2, 12, 3)])
    S.crush(22, [6, 12, 17], foe=[(9, "w")])
    S.mark("D", 6)
    S.flat(12, foe=[(5, "s"), (8, "w")], coin=[(2, 10, 3)])
    S.put(8, 1, "M")
    S.goal()
    r0 = S.room("gem", gems=1)
    r1 = S.room("vault", gems=1)
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "D"), ("room", r1, "in"), "door", key=1)
    return S.finish(2, "Senda de las Luciérnagas", 1, 1, zone=1, notes=["Nocturno: troncos sobre pozos y copas de árboles."])


# ---------------------------------------------------------------------------------- 3
def l03():
    """Puente de Troncos: el río manda. Troncos fijos, móviles y rocas; cada tramo cambia el ritmo."""
    S = Seq()
    S.flat(22, foe=[(12, "w"), (17, "j")], coin=[(3, 12, 3)])
    S.start()
    S.river([("log", 3, 5), ("log", 4, 4), ("rock", 3, 2), ("log", 4, 5)])
    S.flat(10, foe=[(4, "w"), (8, "s")])
    S.river([("mlog", 6, 0), ("rock", 3, 3), ("log", 4, 3)])
    S.flat(12, foe=[(5, "t"), (9, "w")], coin=[(2, 10, 3)])
    S.cp()
    S.mark("A", 8)
    S.river([("log", 3, 3), ("rock", 3, 3), ("log", 3, 3), ("rock", 4, 3), ("log", 3, 4)], foe=[(10, "f")])
    S.flat(16, foe=[(5, "w"), (9, "j"), (13, "w")], coin=[(2, 14, 3)])
    S.put(8, 1, "I")
    S.spikes(26, [(5, 3), (12, 2), (19, 3)], shelf=[(8, 11, 5), (16, 10, 4)], foe=[(23, "w")])
    S.river([("rock", 3, 3), ("rock", 3, 2), ("rock", 4, 3), ("log", 3, 4), ("rock", 3, 3)])
    S.cp()
    S.mark("C", 6)
    S.flat(14, foe=[(4, "w"), (8, "t")], coin=[(2, 12, 3)])
    S.mover(10, "m")
    S.flat(10, foe=[(4, "j")])
    S.river([("log", 4, 3), ("mlog", 7, 0), ("log", 3, 3), ("rock", 3, 3)])
    S.mark("B", 4)
    S.flat(14, foe=[(5, "w"), (9, "s")], coin=[(2, 12, 3)])
    x0 = S.x
    S.bounce(16, [4, 10], foe=[(8, "f")], gem=(6, 8))
    S.flat(10, foe=[(4, "w")])
    S.cp()
    S.river([("log", 3, 4), ("log", 4, 4), ("log", 4, 3), ("rock", 3, 3), ("log", 3, 5)], foe=[(12, "f")])
    S.mark("E", 7)
    S.flat(14, foe=[(5, "w"), (9, "j")], coin=[(2, 12, 3)])
    S.put(7, 1, "M")
    S.mark("D", 8)
    S.spikes(24, [(4, 2), (10, 3), (17, 2)], foe=[(13, "w")])
    S.pits([(3, 3, 1), (4, 3, 0), (3, 3, 2), (4, 3, 0)], foe_on=[1])
    S.goal()
    r0 = S.room("shaft", gems=1)
    r1 = S.room("key", key=True, gems=1)
    r2 = S.room("vault")
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "D"), ("room", r2, "in"), "door", key=1)
    S.link(("mark", "C"), ("room", r1, "in"), "tunnel")
    S.link(("room", r1, "out"), ("mark", "E"), "tunnel")
    return S.finish(3, "Puente de Troncos", 1, 2, zone=0, notes=["Cuatro tramos de río con troncos, rocas y troncos móviles."])


# ---------------------------------------------------------------------------------- 4
def l04():
    """Cueva de las Raíces (cueva): techo bajo, estalactitas, prensas y resortes; una verja con candado en medio."""
    S = Seq()
    S.flat(16, foe=[(10, "w")], coin=[(3, 12, 3)], prop=0)
    S.start()
    S.cave(24, ceil=6, hangs=[(6, 1), (14, 1)], foe=[(9, "w"), (18, "w")])
    S.pits([(3, 4, 0), (4, 3, 1), (3, 4, 0)], foe_on=[1])
    S.cave(26, ceil=6, hangs=[(5, 2), (12, 2), (19, 1)], crushers=[9, 16], foe=[(7, "s"), (22, "w")])
    S.cp()
    S.mark("A", 9)
    S.flat(14, foe=[(5, "j"), (10, "w")], coin=[(2, 12, 3)], prop=0)
    S.bounce(18, [3, 11], foe=[(14, "f")])
    S.cave(24, ceil=7, hangs=[(7, 2), (15, 2)], foe=[(10, "t"), (19, "w")])
    S.put(8, 1, "I")
    S.mover(9, "m")
    S.mark("C", 6)
    S.flat(12, foe=[(4, "w"), (8, "s")], prop=0)
    S.cp()
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 2)])
    S.cave(28, ceil=6, hangs=[(6, 1), (13, 2), (21, 1)], crushers=[10, 17, 24], foe=[(8, "w"), (20, "j")])
    S.flat(10, foe=[(4, "w")], prop=0)
    S.mark("B", 5)
    S.spikes(26, [(5, 3), (12, 3), (19, 2)], shelf=[(8, 11, 5), (16, 10, 5)], foe=[(10, "w"), (23, "w")])
    S.cp()
    S.put(7, 1, "U")
    S.flat(14, foe=[(4, "j"), (10, "w")], prop=0)
    S.pits([(4, 3, 0), (4, 3, 2), (4, 3, 0)], foe_on=[1])
    S.flat(10, coin=[(1, 9, 3)], prop=0)
    S.gate()
    S.mark("D", 5)
    S.flat(14, foe=[(4, "w"), (9, "s")], coin=[(2, 12, 3)], prop=0)
    S.cave(22, ceil=6, hangs=[(6, 2), (14, 2)], crushers=[10], foe=[(18, "w")])
    S.cp()
    S.bounce(20, [4, 12], foe=[(15, "f")])
    S.cave(26, ceil=6, hangs=[(5, 2), (12, 2), (19, 1)], crushers=[9, 16, 22], foe=[(8, "w"), (20, "j")])
    S.mark("E", 6)
    S.flat(26, foe=[(5, "t"), (10, "w"), (19, "j")], coin=[(2, 24, 3)], prop=0)
    S.crumble([(2, 3), (3, 3), (2, 3)])
    S.goal()
    r0 = S.room("gem", gems=1)
    r1 = S.room("arena", gems=1)
    r2 = S.room("shaft", gems=1)
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "C"), ("room", r1, "in"), "tunnel")
    S.link(("room", r1, "out"), ("mark", "D"), "tunnel")
    S.link(("mark", "E"), ("room", r2, "in"), "door")
    return S.finish(4, "Cueva de las Raíces", 2, 2, kind="cave", zone=1, notes=["Cueva: la verja obligatoria exige la llave que está tras el segundo tramo de espinas."])


# ---------------------------------------------------------------------------------- 5
def l05():
    """Copas Altas (salida secreta): sobre las copas de los árboles. Islas con setas, troncos altos y una boca de túnel oculta."""
    S = Seq()
    S.flat(20, foe=[(11, "w"), (16, "j")], coin=[(3, 12, 3)])
    S.start()
    S.isles([(3, 4, 0, 3), (4, 4, 1, 3), (4, 3, 2, 3), (4, 4, 1, 3)], foe=[(12, "f")])
    S.flat(12, foe=[(4, "w"), (8, "s")], coin=[(2, 10, 3)])
    S.bounce(20, [4, 12], foe=[(9, "f"), (16, "w")])
    S.pits([(4, 3, 1), (4, 3, 0), (5, 3, 2)], foe_on=[1])
    S.cp()
    S.isles([(3, 3, 1, 3), (4, 3, 2, 3), (4, 4, 3, 3), (4, 3, 2, 3), (4, 3, 0, 3)], springs=[2], foe=[(10, "f")])
    S.mouth("A", 14, foe=[(3, "w"), (11, "j")], coin=[(2, 12, 3)])
    S.hill(8, 3, foe=[(3, "w")])
    S.mover(9, "m")
    S.flat(12, foe=[(4, "t"), (8, "w")], coin=[(2, 10, 3)])
    S.put(7, 1, "I")
    S.cp()
    S.planks([(3, 12, 4), (4, 10, 4), (4, 8, 4), (4, 10, 4), (3, 12, 4)])
    S.flat(14, foe=[(5, "w"), (9, "s")], coin=[(2, 12, 3)])
    lx, ty = S.tower([(1, 12), (5, 9), (1, 6)], top_y=6, ledge=5)
    S.c.set(lx + 2, ty - 1, "*")
    S.flat(10, foe=[(4, "w")], prop=0)
    S.isles([(4, 3, 0, 3), (4, 3, 1, 3), (5, 3, 0, 3), (4, 3, 2, 3), (5, 3, 0, 3), (4, 3, 1, 3)], foe=[(8, "f"), (20, "f")])
    S.cp()
    S.mark("B", 6)
    S.flat(16, foe=[(5, "j"), (11, "w")], coin=[(2, 14, 3)])
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 3)])
    S.flat(12, foe=[(4, "t"), (8, "w")])
    S.put(6, 1, "M")
    S.spikes(26, [(5, 2), (11, 3), (18, 2)], shelf=[(8, 11, 5), (15, 10, 5)], foe=[(22, "w")])
    S.mark("D", 6)
    S.flat(14, foe=[(4, "w"), (9, "j")], coin=[(2, 12, 3)])
    S.item("U", 5)
    S.mark("V", 6)
    S.pits([(3, 3, 1), (4, 3, 0), (3, 3, 2)], foe_on=[1])
    S.goal()
    r0 = S.room("gem", gems=1)
    r1 = S.room("secret", gems=1)
    r3 = S.room("vault")
    S.link(("mark", "V"), ("room", r3, "in"), "door", key=1)
    S.link(("mark", "B"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "D"), "tunnel")
    S.link(("mark", "A"), ("room", r1, "in"), "tunnel")
    return S.finish(5, "Copas Altas", 1, 2, zone=2, notes=["Islas y troncos sobre el vacío. La boca de túnel A lleva a la salida secreta."])


# ---------------------------------------------------------------------------------- 6
def l06():
    """Pantano Verde: barro que frena, espinas de zarzas, géiseres de gas y troncos podridos."""
    S = Seq()
    S.flat(20, foe=[(10, "w"), (15, "w")], coin=[(3, 12, 3)])
    S.start()
    S.mud(22, foe=[(8, "w"), (14, "s")], thorn=[6, 17])
    S.river([("log", 3, 4), ("rock", 3, 3), ("log", 4, 4)])
    S.flat(10, foe=[(4, "w")], coin=[(2, 8, 3)])
    S.mud(26, foe=[(7, "s"), (13, "w"), (19, "j")], thorn=[5, 11, 21])
    S.cp()
    S.mouth("A", 14, foe=[(3, "t"), (11, "w")], coin=[(2, 12, 3)])
    S.geyser(20, [6, 12], foe=[(16, "w")])
    S.pits([(4, 3, 0), (4, 3, 1), (4, 3, 0), (5, 3, 1)], foe_on=[1])
    S.mud(22, foe=[(8, "w"), (15, "w")], thorn=[4, 12])
    S.item("I", 6)
    S.cp()
    S.river([("rock", 3, 3), ("log", 4, 3), ("rock", 3, 3), ("mlog", 6, 0), ("rock", 3, 3)], foe=[(10, "f")])
    S.flat(14, foe=[(5, "j"), (10, "w")], coin=[(2, 12, 3)])
    S.thorns(28, [(5, 2), (9, 2), (14, 3), (20, 2), (24, 2)], shelf=[(7, 4, 4), (17, 5, 4)], foe=[(12, "w"), (26, "w")])
    S.mud(20, foe=[(6, "w"), (12, "s")], thorn=[9, 16])
    S.cp()
    S.mouth("B", 14, foe=[(3, "w"), (11, "j")])
    S.geyser(22, [5, 11, 17], foe=[(8, "w")])
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 3)])
    lx, ty = S.tower([(1, 12), (5, 9), (1, 6)], top_y=6, ledge=5)
    S.c.set(lx + 2, ty - 1, "*")
    S.flat(12, foe=[(4, "w"), (8, "s")], coin=[(2, 10, 3)])
    S.item("M", 4)
    S.mud(24, foe=[(7, "w"), (13, "j"), (19, "w")], thorn=[4, 10, 16, 21])
    S.cp()
    S.mark("D", 6)
    S.flat(16, foe=[(5, "t"), (11, "w")], coin=[(2, 14, 3)])
    S.pits([(3, 3, 1), (4, 3, 0), (3, 3, 2), (4, 3, 0)], foe_on=[1, 2])
    S.cp()
    S.mud(24, foe=[(7, "w"), (13, "s"), (19, "w")], thorn=[4, 10, 16, 21])
    S.river([("rock", 3, 3), ("log", 4, 3), ("rock", 3, 3), ("log", 3, 4)])
    S.flat(12, foe=[(4, "w")], coin=[(2, 10, 3)])
    S.goal()
    r0 = S.room("key", key=True, gems=1)
    r1 = S.room("vault", gems=1)
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "D"), ("room", r1, "in"), "door", key=1)
    return S.finish(6, "Pantano Verde", 1, 3, zone=1, notes=["Barro, zarzas y géiseres de gas: el ritmo lo marca el suelo."])


# ---------------------------------------------------------------------------------- 7
def l07():
    """Casa del Leñador (casa de bonificación, oculta): monedas por todas partes, cofres y vidas; poco peligro, mucho que buscar."""
    S = Seq()
    rich = [(2, 18, 3), (2, 18, 5)]
    S.flat(24, foe=[(14, "w")], coin=rich + [(3, 20, 7)])
    S.start()
    S.bounce(22, [4, 12], coin=None, gem=(6, 8)) if False else S.bounce(22, [4, 12], foe=[(16, "w")])
    S.pits([(3, 4, 0), (3, 4, 1), (3, 4, 0), (4, 3, 1)], foe_on=[1])
    S.flat(14, foe=[(6, "w")], coin=[(2, 12, 3), (2, 12, 5)])
    S.planks([(3, 12, 5), (3, 10, 5), (3, 8, 5), (3, 10, 5), (3, 12, 5)])
    S.cp()
    S.mouth("A", 16, foe=[(4, "w")], coin=[(2, 14, 3), (2, 14, 5)])
    S.hill(10, 2, coin=True)
    S.tops([(3, 4, 5), (4, 5, 5), (4, 6, 5), (4, 5, 5)], foe=[(12, "f")])
    S.flat(12, foe=[(5, "w")], coin=[(2, 10, 3), (2, 10, 5)])
    S.item("I", 5)
    S.bounce(24, [5, 13], foe=[(18, "w")])
    S.cp()
    S.isles([(3, 5, 0, 3), (4, 5, 1, 3), (4, 5, 2, 3), (4, 5, 1, 3)], foe=[(12, "f")])
    S.flat(14, foe=[(5, "j")], coin=[(2, 12, 3), (2, 12, 5), (2, 12, 7)])
    S.spikes(22, [(7, 2), (14, 2)], shelf=[(5, 10, 6), (14, 10, 6)], foe=[(19, "w")])
    S.mouth("B", 14, coin=[(2, 12, 3), (2, 12, 5)])
    S.cp()
    S.crumble([(2, 3), (2, 3), (3, 3), (2, 3)])
    S.flat(16, foe=[(6, "w"), (11, "w")], coin=[(2, 14, 3), (2, 14, 5)])
    lx, ty = S.tower([(1, 12), (5, 9), (1, 6)], top_y=6, ledge=6)
    S.c.set(lx + 2, ty - 1, "*")
    S.flat(12, coin=[(2, 10, 3), (2, 10, 5)])
    S.item("M", 5)
    S.mover(9, "m")
    S.flat(14, foe=[(5, "w")], coin=[(2, 12, 3), (2, 12, 5)])
    S.cp()
    S.mark("D", 6)
    S.flat(18, foe=[(6, "w"), (12, "w")], coin=[(2, 16, 3), (2, 16, 5)])
    S.pits([(3, 4, 1), (4, 4, 0), (3, 4, 2)], foe_on=[1])
    S.cp()
    S.mouth("C", 14, foe=[(4, "w")], coin=[(2, 12, 3), (2, 12, 5)])
    S.bounce(22, [4, 12], foe=[(16, "w")])
    S.isles([(3, 5, 0, 3), (4, 5, 1, 3), (4, 5, 2, 3)], foe=[(10, "f")])
    S.flat(12, coin=[(2, 10, 3), (2, 10, 5)])
    S.goal()
    r0 = S.room("vault", gems=1)
    r1 = S.room("shaft", gems=1)
    r2 = S.room("key", key=True)
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "D"), ("room", r1, "in"), "door", key=1)
    S.link(("mark", "C"), ("room", r2, "in"), "tunnel")
    S.link(("room", r2, "out"), ("mark", "D"), "tunnel") if False else None
    return S.finish(7, "Casa del Leñador", 1, 1, kind="house", zone=0, notes=["Casa de bonificación: monedas, cofres y vidas."])


# ---------------------------------------------------------------------------------- 8
def l08():
    """Cascada Escondida: ascensos junto a la caída de agua, corrientes de aire y troncos altos."""
    S = Seq()
    S.flat(22, foe=[(12, "w"), (17, "j")], coin=[(3, 12, 3)])
    S.start()
    S.fall_water()
    S.flat(10, foe=[(4, "w")], coin=[(2, 8, 3)])
    S.tops([(3, 4, 4), (4, 6, 4), (4, 8, 4), (4, 6, 4), (3, 4, 4)], foe=[(12, "f")])
    S.flat(12, foe=[(4, "w"), (8, "t")], coin=[(2, 10, 3)])
    S.cp()
    S.mouth("A", 14, foe=[(3, "j"), (11, "w")])
    S.fall_water(w=18, up=11)
    S.river([("log", 3, 4), ("log", 4, 4), ("mlog", 7, 0), ("rock", 3, 3)])
    S.flat(12, foe=[(4, "s"), (8, "w")], coin=[(2, 10, 3)])
    S.item("I", 5)
    S.sniper(24, [(6, 2), (13, 3), (19, 2)], foe=[(10, "w")])
    S.cp()
    S.fall_water()
    S.pits([(4, 3, 1), (4, 3, 2), (4, 3, 1), (5, 3, 0)], foe_on=[0, 2])
    S.flat(14, foe=[(5, "w"), (9, "j")], coin=[(2, 12, 3)])
    lx, ty = S.tower([(1, 12), (5, 9), (1, 6)], top_y=6, ledge=5)
    S.c.set(lx + 2, ty - 1, "*")
    S.mouth("B", 14, foe=[(3, "w")], coin=[(2, 12, 3)])
    S.cp()
    S.fall_water(w=16, up=9)
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 3), (2, 2)])
    S.flat(12, foe=[(4, "t"), (8, "w")])
    S.item("M", 4)
    S.spikes(28, [(5, 3), (11, 3), (17, 3), (23, 2)], shelf=[(7, 11, 5), (13, 10, 5), (20, 11, 5)], foe=[(9, "w"), (26, "w")])
    S.mark("D", 6)
    S.flat(16, foe=[(5, "w"), (11, "j")], coin=[(2, 14, 3)])
    S.fall_water(w=18, up=10)
    S.cp()
    S.tops([(3, 4, 4), (4, 5, 4), (4, 7, 4), (4, 5, 4), (3, 4, 4)], foe=[(12, "f")])
    S.flat(14, foe=[(4, "w"), (9, "j")], coin=[(2, 12, 3)])
    S.sniper(22, [(5, 2), (11, 3), (17, 2)], foe=[(8, "w")])
    S.pits([(3, 3, 1), (4, 3, 0), (3, 3, 2)], foe_on=[1])
    S.goal()
    r0 = S.room("shaft", gems=1)
    r1 = S.room("key", key=True, gems=1)
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "D"), ("room", r1, "in"), "door")
    return S.finish(8, "Cascada Escondida", 1, 3, zone=2, notes=["Cuatro cascadas con corriente ascendente y troncos altos."])


# ---------------------------------------------------------------------------------- 9
def l09():
    """Ruinas Cubiertas (salida secreta): ladrillos, suelos que se desmoronan, prensas y una verja con llave."""
    S = Seq()
    S.flat(20, foe=[(11, "w"), (16, "s")], coin=[(3, 12, 3)])
    S.start()
    S.ruins(24, bricks=[(5, 4), (14, 4)], crumbles=[(8, 3), (18, 3)], foe=[(9, "w"), (20, "j")])
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 3)])
    S.crush(22, [6, 12, 17], foe=[(9, "w")])
    S.cp()
    S.mouth("A", 14, foe=[(3, "w"), (11, "s")])
    S.ruins(26, bricks=[(4, 5), (13, 4), (20, 4)], crumbles=[(9, 3), (16, 3)], foe=[(8, "t"), (22, "w")])
    S.item("I", 5)
    S.pits([(4, 3, 0), (4, 3, 2), (4, 3, 0), (5, 3, 1)], foe_on=[1])
    S.crush(24, [7, 13, 19], foe=[(10, "w"), (20, "j")])
    S.cp()
    S.mark("B", 6)
    S.flat(14, foe=[(5, "w"), (9, "s")], coin=[(2, 12, 3)])
    S.hill(10, 3, foe=[(3, "w"), (7, "t")])
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 3), (2, 2)])
    S.flat(12, foe=[(4, "j")])
    S.item("U", 4)
    S.cp()
    S.ruins(28, bricks=[(4, 4), (11, 5), (19, 4)], crumbles=[(8, 3), (15, 3), (23, 3)], foe=[(7, "w"), (14, "j"), (25, "s")])
    S.mark("C", 6)
    S.flat(10, foe=[(4, "w")], coin=[(1, 9, 3)])
    S.gate()
    S.mark("D", 6)
    S.flat(16, foe=[(4, "w"), (9, "j"), (13, "w")], coin=[(2, 14, 3)])
    S.item("M", 5)
    S.crush(26, [6, 12, 18, 23], foe=[(9, "w"), (21, "w")])
    S.cp()
    S.ruins(26, bricks=[(5, 4), (14, 5)], crumbles=[(9, 3), (19, 3)], foe=[(8, "j"), (22, "w")])
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 3)])
    S.flat(14, foe=[(4, "w"), (9, "s")], coin=[(2, 12, 3)])
    S.pits([(3, 3, 1), (4, 3, 0), (3, 3, 2)], foe_on=[1])
    S.goal()
    r0 = S.room("gem", gems=1)
    r1 = S.room("secret", gems=1)
    r2 = S.room("vault", gems=1)
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "C"), ("room", r1, "in"), "tunnel")
    S.link(("mark", "D"), ("room", r2, "in"), "door")
    return S.finish(9, "Ruinas Cubiertas", 1, 3, zone=1, notes=["Verja obligatoria: la llave está tras el tramo de ruinas. El túnel C lleva a la salida secreta."])


# ---------------------------------------------------------------------------------- 10
def l10():
    """Fortaleza de Raíces (fortaleza): pasillos de piedra con prensas, pinchos y tiradores. Sin descanso."""
    S = Seq()
    S.flat(18, foe=[(10, "w")], coin=[(3, 12, 3)], prop=0)
    S.start()
    S.bastion(24, crushers=[6, 12, 18], spikes=[(9, 2)], shooters=[15], foe=[(20, "w")])
    S.pits([(3, 4, 0), (4, 3, 1), (3, 4, 0)], foe_on=[1])
    S.bastion(26, crushers=[7, 13, 19], spikes=[(4, 2), (16, 2)], shooters=[10, 22], foe=[(14, "s")])
    S.cp()
    S.mouth("A", 14, foe=[(3, "w"), (11, "j")], prop=0)
    S.sniper(24, [(5, 2), (11, 3), (17, 2)], foe=[(9, "w")])
    S.mover(9, "m")
    S.bastion(24, crushers=[6, 11, 17], spikes=[(8, 3)], shooters=[14], foe=[(20, "w")])
    S.item("I", 5)
    S.cp()
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 3)])
    S.bastion(28, crushers=[5, 10, 15, 20], spikes=[(7, 2), (18, 2)], shooters=[12, 24], foe=[(9, "w"), (22, "s")])
    S.flat(10, foe=[(4, "j")], prop=0)
    S.mark("B", 5)
    S.cp()
    S.hill(10, 3, foe=[(3, "t"), (6, "w")])
    S.bastion(24, crushers=[6, 11, 16, 21], spikes=[(9, 2)], shooters=[14], foe=[(19, "w")])
    S.put(-6, 1, "U") if False else None
    S.item("U", 4)
    S.mark("D", 5)
    S.flat(14, foe=[(4, "w"), (9, "j")], prop=0)
    S.pits([(4, 3, 0), (4, 3, 2), (4, 3, 0), (5, 3, 1)], foe_on=[1, 3])
    S.bastion(26, crushers=[5, 10, 15, 20], spikes=[(7, 2), (23, 2)], shooters=[12, 18], foe=[(25, "w")])
    S.item("M", 4)
    S.cp()
    S.mouth("C", 14, foe=[(3, "w"), (11, "s")], prop=0)
    S.bastion(26, crushers=[6, 11, 16, 21], spikes=[(8, 2), (24, 2)], shooters=[13, 19], foe=[(10, "w")])
    S.sniper(24, [(5, 2), (11, 3), (17, 2)], foe=[(9, "w")])
    S.mover(9, "v")
    S.bastion(22, crushers=[5, 10, 15], spikes=[(8, 3)], shooters=[18], foe=[(13, "j")])
    S.goal()
    r0 = S.room("arena", gems=1)
    r1 = S.room("key", key=True, gems=1)
    r2 = S.room("vault", gems=1)
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "D"), ("room", r2, "in"), "door", key=1)
    S.link(("mark", "C"), ("room", r1, "in"), "tunnel")
    return S.finish(10, "Fortaleza de Raíces", 5, 3, kind="fortress", zone=0, notes=["Fortaleza: prensas, pinchos y tiradores sin descanso."])


# --------------------------------------------------------------------------------- 11
def l11():
    """Lianas Colgantes: plataformas móviles verticales y horizontales sobre barrancos, con subidas y bajadas del terreno."""
    S = Seq()
    S.flat(22, foe=[(12, "w"), (17, "j")], coin=[(3, 12, 3)])
    S.start()
    S.lianas([(9, "m"), (9, "v"), (10, "m")])
    S.flat(12, foe=[(4, "w"), (8, "s")], coin=[(2, 10, 3)])
    S.up(3)
    S.flat(14, foe=[(5, "w"), (9, "t")], coin=[(2, 12, 3)])
    S.cp()
    S.mouth("A", 14, foe=[(3, "j"), (11, "w")])
    S.lianas([(10, "v"), (9, "m"), (10, "v")])
    S.flat(12, foe=[(4, "w"), (8, "j")])
    S.item("I", 5)
    S.down(3)
    S.thorns(26, [(5, 2), (10, 3), (17, 2), (22, 2)], shelf=[(7, 4, 4), (14, 5, 4)], foe=[(8, "w"), (24, "w")])
    S.cp()
    S.mover(10, "m")
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 3)])
    S.flat(14, foe=[(5, "w"), (9, "j")], coin=[(2, 12, 3)])
    S.mark("B", 6)
    S.lianas([(9, "v"), (10, "m"), (9, "v"), (10, "m")])
    S.flat(12, foe=[(4, "t"), (8, "w")], coin=[(2, 10, 3)])
    lx, ty = S.tower([(1, 12), (5, 9), (1, 6)], top_y=6, ledge=5)
    S.c.set(lx + 2, ty - 1, "*")
    S.item("M", 3) if False else None
    S.flat(12, foe=[(4, "w")], coin=[(2, 10, 3)])
    S.cp()
    S.up(2)
    S.mark("D", 6)
    S.flat(16, foe=[(5, "w"), (10, "s"), (13, "j")], coin=[(2, 14, 3)])
    S.isles([(3, 3, 0, 3), (4, 3, 1, 3), (4, 3, 2, 3), (4, 3, 1, 3)], foe=[(10, "f")])
    S.down(2)
    S.lianas([(9, "m"), (9, "v")])
    S.flat(12, foe=[(4, "w"), (8, "j")])
    S.item("M", 5)
    S.cp()
    S.pits([(3, 3, 1), (4, 3, 0), (3, 3, 2), (4, 3, 0)], foe_on=[1, 2])
    S.flat(16, foe=[(5, "w"), (10, "j")], coin=[(2, 14, 3)])
    S.lianas([(9, "v"), (10, "m")])
    S.flat(14, foe=[(5, "t"), (9, "w")], coin=[(2, 12, 3)])
    S.goal()
    r0 = S.room("key", key=True, gems=1)
    r1 = S.room("vault", gems=1)
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "D"), ("room", r1, "in"), "door", key=1)
    return S.finish(11, "Lianas Colgantes", 1, 3, zone=2, notes=["Plataformas móviles sobre barrancos y terreno que sube y baja."])


# --------------------------------------------------------------------------------- 12
def l12():
    """Claro de las Setas: gigantescas setas-resorte que lanzan a las copas; cada tramo se juega en dos alturas."""
    S = Seq()
    S.flat(20, foe=[(11, "w")], coin=[(3, 12, 3)])
    S.start()
    S.bounce(24, [4, 13], foe=[(9, "w"), (19, "j")])
    S.pits([(3, 4, 0), (4, 3, 1), (3, 4, 0)], foe_on=[1])
    S.isles([(3, 4, 1, 3), (4, 4, 2, 3), (4, 4, 1, 3), (4, 4, 0, 3)], springs=[1], foe=[(12, "f")])
    S.flat(12, foe=[(4, "w"), (8, "t")], coin=[(2, 10, 3)])
    S.cp()
    S.mouth("A", 14, foe=[(3, "w"), (11, "s")])
    S.bounce(26, [5, 14], foe=[(10, "f"), (21, "w")])
    S.river([("log", 3, 4), ("rock", 3, 3), ("log", 3, 4)])
    S.flat(12, foe=[(4, "j")], coin=[(2, 10, 3)])
    S.item("I", 5)
    S.cp()
    S.tops([(3, 4, 5), (4, 6, 5), (4, 4, 5), (4, 6, 5)], foe=[(12, "f")])
    S.bounce(22, [4, 12], foe=[(17, "w")])
    S.mark("B", 6)
    S.flat(14, foe=[(4, "w"), (9, "j")], coin=[(2, 12, 3)])
    S.spikes(26, [(5, 3), (11, 2), (18, 3)], shelf=[(7, 10, 5), (15, 10, 5)], foe=[(9, "w"), (23, "w")])
    S.cp()
    S.isles([(4, 4, 0, 3), (4, 4, 2, 3), (4, 4, 0, 3), (4, 4, 2, 3), (4, 4, 0, 3)], springs=[1, 3], foe=[(14, "f")])
    S.mark("D", 6)
    S.flat(16, foe=[(5, "w"), (11, "j")], coin=[(2, 14, 3)])
    S.item("M", 5)
    lx, ty = S.tower([(1, 12), (5, 9), (1, 6)], top_y=6, ledge=5)
    S.c.set(lx + 2, ty - 1, "*")
    S.flat(10, foe=[(4, "w")], coin=[(2, 8, 3)])
    S.cp()
    S.bounce(24, [4, 13], foe=[(9, "w"), (19, "t")])
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 3)])
    S.flat(12, foe=[(4, "w"), (8, "j")])
    S.pits([(3, 3, 1), (4, 3, 0), (3, 3, 2)], foe_on=[1])
    S.bounce(22, [4, 12], foe=[(8, "w"), (17, "j")])
    S.flat(12, foe=[(4, "w")], coin=[(2, 10, 3)])
    S.goal()
    r0 = S.room("gem", gems=1)
    r1 = S.room("key", key=True, gems=1)
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "D"), ("room", r1, "in"), "door")
    return S.finish(12, "Claro de las Setas", 1, 3, zone=0, notes=["Setas-resorte: cada tramo se puede jugar por abajo o por las copas."])


# --------------------------------------------------------------------------------- 13
def l13():
    """Mina Abandonada (cueva, salida secreta): galerías con cintas transportadoras, prensas, géiseres de vapor y una verja."""
    S = Seq()
    S.flat(18, foe=[(10, "w")], coin=[(3, 12, 3)], prop=0)
    S.start()
    S.cave(26, ceil=6, hangs=[(6, 1), (14, 2), (20, 1)], foe=[(9, "w"), (21, "w")])
    S.belt(22, (4, 16, ">"), hazard=(17, 2), foe=[(19, "w")])
    S.cave(24, ceil=7, hangs=[(7, 2), (15, 2)], crushers=[11], foe=[(9, "s"), (19, "w")])
    S.cp()
    S.mouth("A", 14, foe=[(3, "w"), (11, "j")], prop=0)
    S.geyser(22, [6, 13], foe=[(17, "w")])
    S.cave(28, ceil=6, hangs=[(5, 1), (12, 2), (20, 1)], crushers=[9, 16, 24], foe=[(8, "t"), (22, "w")])
    S.item("I", 5)
    S.cp()
    S.belt(24, (4, 18, "<"), hazard=(2, 2), foe=[(20, "w")])
    S.pits([(4, 3, 0), (4, 3, 1), (4, 3, 0)], foe_on=[1])
    S.cave(26, ceil=6, hangs=[(6, 2), (13, 2), (20, 2)], crushers=[10, 17], foe=[(9, "j"), (23, "w")])
    S.mark("B", 6)
    S.flat(12, foe=[(4, "w")], prop=0)
    S.cp()
    S.wind()
    S.cave(24, ceil=7, hangs=[(8, 2), (15, 2)], foe=[(11, "w"), (20, "j")])
    S.item("U", 4)
    S.mark("C", 6)
    S.flat(10, foe=[(4, "w")], coin=[(1, 9, 3)], prop=0)
    S.gate()
    S.mark("D", 6)
    S.flat(16, foe=[(4, "w"), (9, "s"), (13, "j")], coin=[(2, 14, 3)], prop=0)
    S.item("M", 4)
    S.cave(26, ceil=6, hangs=[(6, 1), (13, 2), (21, 1)], crushers=[10, 17, 23], foe=[(8, "w"), (20, "w")])
    S.cp()
    S.geyser(22, [5, 11, 17], foe=[(8, "w")])
    S.crumble([(2, 3), (3, 3), (2, 3)])
    S.pits([(3, 3, 1), (4, 3, 0), (3, 3, 2)], foe_on=[1])
    S.cp()
    S.cave(26, ceil=6, hangs=[(6, 2), (13, 1), (20, 2)], crushers=[9, 16, 23], foe=[(8, "w"), (14, "j"), (22, "s")])
    S.belt(22, (4, 16, ">"), hazard=(17, 2), foe=[(19, "w")])
    S.flat(14, foe=[(4, "w"), (9, "j")], coin=[(2, 12, 3)], prop=0)
    S.goal()
    r0 = S.room("shaft", gems=1)
    r1 = S.room("secret", gems=1)
    r2 = S.room("vault", gems=1)
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "C"), ("room", r1, "in"), "tunnel")
    S.link(("mark", "D"), ("room", r2, "in"), "door")
    return S.finish(13, "Mina Abandonada", 2, 4, kind="cave", zone=1, notes=["Cintas, prensas y vapor. La verja exige la llave del último tramo; el túnel C lleva a la salida secreta."])


# --------------------------------------------------------------------------------- 14
def l14():
    """Colina de los Búhos: terreno en terrazas (sube y baja), tiradores en pilares y mesetas."""
    S = Seq()
    S.flat(20, foe=[(11, "w"), (16, "j")], coin=[(3, 12, 3)])
    S.start()
    S.up(2)
    S.flat(12, foe=[(4, "w"), (8, "t")], coin=[(2, 10, 3)])
    S.up(2)
    S.sniper(22, [(5, 2), (12, 2), (17, 2)], foe=[(9, "w")])
    S.cp()
    S.mouth("A", 14, foe=[(3, "j"), (11, "w")])
    S.pits([(4, 3, 0), (4, 3, 1), (4, 3, 0)], foe_on=[1])
    S.down(2)
    S.thorns(24, [(5, 2), (10, 3), (16, 2)], shelf=[(7, 4, 4), (13, 5, 4)], foe=[(8, "w"), (21, "w")])
    S.down(2)
    S.item("I", 4) if False else None
    S.flat(12, foe=[(4, "s"), (8, "w")], coin=[(2, 10, 3)])
    S.item("I", 5)
    S.cp()
    S.up(3)
    S.sniper(24, [(6, 2), (13, 3), (19, 2)], foe=[(10, "w"), (21, "j")])
    S.hill(10, 2, foe=[(3, "t"), (6, "w")])
    S.mark("B", 6)
    S.flat(14, foe=[(4, "w"), (9, "j")], coin=[(2, 12, 3)])
    S.down(3)
    S.mover(9, "m")
    S.cp()
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 3)])
    S.up(2)
    S.thorns(26, [(5, 3), (11, 2), (17, 3), (23, 1)], shelf=[(7, 4, 5), (16, 5, 4)], foe=[(9, "w"), (14, "j"), (24, "w")])
    S.down(2)
    S.item("U", 5) if False else None
    S.flat(12, foe=[(4, "w"), (8, "t")], coin=[(2, 10, 3)])
    S.item("U", 5)
    S.mark("D", 6)
    S.flat(14, foe=[(4, "w"), (9, "j")])
    S.cp()
    lx, ty = S.tower([(1, 12), (5, 9), (1, 6)], top_y=6, ledge=5)
    S.c.set(lx + 2, ty - 1, "*")
    S.up(2)
    S.sniper(22, [(5, 2), (11, 2), (17, 2)], foe=[(8, "w")])
    S.down(2)
    S.item("M", 3) if False else None
    S.flat(14, foe=[(4, "w"), (9, "s")], coin=[(2, 12, 3)])
    S.item("M", 5)
    S.pits([(3, 3, 1), (4, 3, 0), (3, 3, 2), (4, 3, 0)], foe_on=[1])
    S.cp()
    S.mark("E", 6)
    S.flat(12, foe=[(4, "w")], coin=[(2, 10, 3)])
    S.up(3)
    S.thorns(26, [(5, 3), (11, 2), (17, 3), (23, 1)], shelf=[(7, 4, 5), (16, 5, 4)], foe=[(9, "w"), (14, "j"), (24, "w")])
    S.down(3)
    S.sniper(24, [(5, 2), (11, 3), (17, 2)], foe=[(9, "w"), (20, "j")])
    S.crumble([(2, 3), (3, 3), (2, 3)])
    S.flat(14, foe=[(4, "w"), (9, "t")], coin=[(2, 12, 3)])
    S.mover(10, "m")
    S.flat(16, foe=[(4, "w"), (9, "j"), (13, "w")], coin=[(2, 14, 3)])
    S.goal()
    r0 = S.room("arena", gems=1)
    r1 = S.room("vault", gems=1)
    r2 = S.room("key", key=True)
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "D"), ("room", r1, "in"), "door", key=1)
    S.link(("mark", "E"), ("room", r2, "in"), "tunnel")
    return S.finish(14, "Colina de los Búhos", 1, 3, zone=0, notes=["Terrazas que suben y bajan, con tiradores en pilares."])


# --------------------------------------------------------------------------------- 15
def l15():
    """Río Bifurcado: el camino se parte en una ruta baja (suelo y enemigos) y otra alta (troncos); se juega como se prefiera."""
    S = Seq()
    S.flat(22, foe=[(12, "w"), (17, "j")], coin=[(3, 12, 3)])
    S.start()
    S.fork(32, low_foe=[(10, "w"), (18, "j"), (26, "w")], spikes=[(14, 2)])
    S.river([("log", 3, 4), ("rock", 3, 3), ("log", 4, 4), ("rock", 3, 3)])
    S.flat(12, foe=[(4, "w"), (8, "t")], coin=[(2, 10, 3)])
    S.cp()
    S.mouth("A", 14, foe=[(3, "j"), (11, "w")])
    S.fork(40, low_foe=[(9, "w"), (17, "s"), (25, "w"), (33, "j")], spikes=[(12, 3), (28, 2)], up_foe=[15, 30])
    S.mover(9, "m")
    S.flat(12, foe=[(4, "w")], coin=[(2, 10, 3)])
    S.item("I", 5)
    S.cp()
    S.river([("log", 3, 4), ("mlog", 7, 0), ("log", 3, 4), ("rock", 3, 3), ("log", 4, 4)], foe=[(12, "f")])
    S.mark("B", 6)
    S.flat(14, foe=[(4, "w"), (9, "j")], coin=[(2, 12, 3)])
    S.fork(34, low_foe=[(8, "w"), (15, "w"), (22, "j"), (29, "s")], spikes=[(11, 2), (25, 2)])
    lx, ty = S.tower([(1, 12), (5, 9), (1, 6)], top_y=6, ledge=5)
    S.c.set(lx + 2, ty - 1, "*")
    S.flat(10, foe=[(4, "w")])
    S.cp()
    S.tops([(3, 4, 5), (4, 6, 5), (4, 4, 5), (4, 6, 5), (3, 4, 5)], foe=[(12, "f"), (24, "f")])
    S.flat(12, foe=[(4, "t"), (8, "w")], coin=[(2, 10, 3)])
    S.item("M", 5)
    S.mark("D", 6)
    S.fork(38, low_foe=[(9, "w"), (16, "j"), (24, "w"), (31, "s")], spikes=[(12, 3), (27, 3)], up_foe=[18])
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 3)])
    S.flat(14, foe=[(4, "w"), (9, "j")], coin=[(2, 12, 3)])
    S.cp()
    S.river([("rock", 3, 3), ("log", 4, 4), ("rock", 3, 3), ("log", 4, 4)])
    S.pits([(3, 3, 1), (4, 3, 0), (3, 3, 2), (4, 3, 0)], foe_on=[1])
    S.goal()
    r0 = S.room("key", key=True, gems=1)
    r1 = S.room("vault", gems=1)
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "D"), ("room", r1, "in"), "door", key=1)
    return S.finish(15, "Río Bifurcado", 1, 4, zone=1, notes=["Tres bifurcaciones: ruta baja o ruta alta."])


# --------------------------------------------------------------------------------- 16
def l16():
    """Bosque Nocturno: oscuro y denso; muchos enemigos, tiradores y relojes que valen oro."""
    S = Seq()
    S.flat(20, foe=[(8, "w"), (13, "j"), (17, "w")], coin=[(3, 12, 3)])
    S.start()
    S.sniper(24, [(5, 2), (11, 3), (17, 2)], foe=[(8, "w"), (14, "j"), (21, "w")])
    S.pits([(4, 3, 0), (4, 3, 1), (4, 3, 0), (5, 3, 2)], foe_on=[0, 1, 3])
    S.flat(12, foe=[(3, "w"), (7, "s"), (10, "j")], coin=[(2, 10, 3)])
    S.cp()
    S.mouth("A", 14, foe=[(3, "w"), (11, "s")])
    S.thorns(30, [(5, 2), (9, 2), (13, 3), (19, 2), (24, 3)], shelf=[(6, 4, 4), (15, 5, 4)], foe=[(8, "w"), (16, "j"), (22, "t"), (28, "w")])
    S.item("I", 5) if False else None
    S.mover(9, "m")
    S.flat(12, foe=[(3, "w"), (6, "t"), (9, "w")])
    S.item("I", 4)
    S.cp()
    S.isles([(3, 3, 0, 3), (4, 3, 1, 3), (4, 3, 2, 3), (4, 3, 0, 3)], foe=[(8, "f"), (16, "f")])
    S.sniper(26, [(5, 2), (11, 2), (17, 3), (22, 2)], foe=[(8, "w"), (14, "s"), (24, "w")])
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 3), (2, 2)])
    S.mark("B", 6)
    S.flat(14, foe=[(3, "w"), (7, "j"), (11, "w")], coin=[(2, 12, 3)])
    S.cp()
    S.crush(22, [6, 12, 17], foe=[(9, "w"), (20, "j")])
    S.pits([(4, 3, 1), (4, 3, 2), (4, 3, 1), (5, 3, 0)], foe_on=[0, 2])
    S.flat(12, foe=[(3, "t"), (6, "w"), (9, "s")])
    S.item("M", 4)
    lx, ty = S.tower([(1, 12), (5, 9), (1, 6)], top_y=6, ledge=5)
    S.c.set(lx + 2, ty - 1, "*")
    S.cp()
    S.mark("D", 6)
    S.flat(16, foe=[(3, "w"), (6, "j"), (9, "s"), (13, "w")])
    S.thorns(28, [(4, 2), (8, 2), (12, 3), (18, 2), (23, 3)], shelf=[(5, 4, 4), (14, 5, 4)], foe=[(7, "w"), (15, "j"), (21, "t"), (26, "w")])
    S.river([("log", 3, 4), ("rock", 3, 3), ("log", 3, 4), ("rock", 3, 3)], foe=[(10, "f")])
    S.cp()
    S.flat(14, foe=[(3, "w"), (6, "j"), (9, "s"), (12, "w")])
    S.crush(22, [6, 12, 17], foe=[(9, "w"), (20, "j")])
    S.sniper(24, [(5, 2), (11, 3), (17, 2)], foe=[(8, "w"), (14, "j"), (21, "w")])
    S.pits([(4, 3, 0), (4, 3, 1), (4, 3, 0), (5, 3, 2)], foe_on=[0, 1, 3])
    S.flat(12, foe=[(3, "w"), (7, "t")])
    S.goal()
    r0 = S.room("key", key=True, gems=1)
    r1 = S.room("vault", gems=1)
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "D"), ("room", r1, "in"), "door", key=1)
    return S.finish(16, "Bosque Nocturno", 1, 4, zone=2, notes=["El nivel más poblado de la región: muchos enemigos y tiradores."])


# --------------------------------------------------------------------------------- 17
def l17():
    """Sendero de Espinas: poca gente y mucho pincho; precisión milimétrica sobre troncos y repisas."""
    S = Seq()
    S.flat(20, foe=[(12, "w")], coin=[(3, 12, 3)])
    S.start()
    S.thorns(30, [(4, 2), (8, 2), (12, 2), (16, 3), (22, 2), (26, 2)], shelf=[(6, 4, 4), (14, 5, 5)], foe=[(10, "w")])
    S.pits([(3, 3, 1), (4, 3, 0), (3, 3, 2), (4, 3, 0)], foe_on=[1])
    S.thorns(28, [(5, 3), (10, 3), (15, 3), (21, 2), (25, 2)], shelf=[(7, 4, 5), (17, 5, 4)], foe=[(8, "w"), (23, "w")])
    S.cp()
    S.mouth("A", 14, foe=[(3, "w")], coin=[(2, 12, 3)])
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 3), (2, 3)])
    S.thorns(32, [(4, 2), (8, 3), (13, 2), (18, 3), (24, 2), (28, 3)], shelf=[(6, 4, 4), (15, 5, 5), (24, 4, 4)], foe=[(10, "j"), (21, "w")])
    S.item("I", 5) if False else None
    S.flat(12, foe=[(4, "t"), (8, "w")], coin=[(2, 10, 3)])
    S.item("I", 4)
    S.cp()
    S.planks([(3, 12, 4), (4, 10, 4), (3, 12, 4), (4, 10, 4), (3, 12, 4)])
    S.thorns(30, [(5, 2), (9, 2), (13, 2), (17, 2), (22, 3), (27, 2)], shelf=[(7, 4, 4), (19, 5, 5)], foe=[(11, "w"), (25, "j")])
    S.mark("B", 6)
    S.flat(14, foe=[(5, "w"), (9, "s")], coin=[(2, 12, 3)])
    S.mud(20, foe=[(6, "w"), (13, "j")], thorn=[4, 9, 15])
    S.cp()
    S.mover(10, "m")
    S.thorns(30, [(4, 3), (9, 3), (14, 2), (19, 3), (25, 3)], shelf=[(6, 4, 4), (16, 5, 5)], foe=[(11, "w"), (22, "w")])
    lx, ty = S.tower([(1, 12), (5, 9), (1, 6)], top_y=6, ledge=5)
    S.c.set(lx + 2, ty - 1, "*")
    S.item("M", 3) if False else None
    S.flat(12, foe=[(4, "w")], coin=[(2, 10, 3)])
    S.item("M", 4)
    S.cp()
    S.mark("D", 6)
    S.flat(16, foe=[(5, "w"), (11, "j")], coin=[(2, 14, 3)])
    S.thorns(32, [(5, 2), (9, 3), (14, 2), (19, 3), (25, 2), (29, 2)], shelf=[(7, 4, 5), (17, 5, 5)], foe=[(12, "w"), (23, "t")])
    S.pits([(3, 3, 1), (4, 3, 0), (3, 3, 2), (4, 3, 0)], foe_on=[1])
    S.cp()
    S.mud(22, foe=[(6, "w"), (13, "s")], thorn=[4, 9, 16])
    S.river([("log", 3, 4), ("rock", 3, 3), ("log", 4, 4), ("rock", 3, 3)])
    S.flat(14, foe=[(4, "w"), (9, "j")], coin=[(2, 12, 3)])
    S.thorns(26, [(5, 3), (10, 2), (16, 3), (21, 2)], shelf=[(7, 4, 5), (15, 5, 4)], foe=[(12, "w"), (23, "w")])
    S.goal()
    r0 = S.room("gem", gems=1)
    r1 = S.room("key", key=True, gems=1)
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "D"), ("room", r1, "in"), "door")
    return S.finish(17, "Sendero de Espinas", 1, 4, zone=0, notes=["Casi sin enemigos; los pinchos mandan."])


# --------------------------------------------------------------------------------- 18
def l18():
    """Árbol Milenario: dos grandes ascensos por el tronco (torres), corrientes y copas; mucha altura y poca llanura."""
    S = Seq()
    S.flat(20, foe=[(11, "w")], coin=[(3, 12, 3)])
    S.start()
    lx, ty = S.tower([(1, 12), (5, 9), (1, 6)], top_y=6, ledge=5)
    S.c.set(lx + 2, ty - 1, "*")
    S.flat(12, foe=[(4, "w"), (8, "j")], coin=[(2, 10, 3)])
    S.wind()
    S.cp()
    S.mouth("A", 14, foe=[(3, "w"), (11, "j")])
    S.tops([(3, 4, 5), (4, 6, 5), (4, 8, 5), (4, 6, 5)], foe=[(12, "f")])
    S.flat(12, foe=[(4, "t"), (8, "w")], coin=[(2, 10, 3)])
    S.item("I", 5)
    lx2, ty2 = S.tower([(1, 12), (5, 9), (1, 6), (5, 3)], top_y=3, ledge=5)
    S.c.set(lx2 + 2, ty2 - 1, "*")
    S.cp()
    S.isles([(3, 4, 1, 3), (4, 4, 3, 3), (4, 4, 1, 3), (4, 4, 3, 3), (4, 4, 0, 3)], springs=[1], foe=[(12, "f"), (24, "f")])
    S.mark("B", 6)
    S.flat(14, foe=[(4, "w"), (9, "s")], coin=[(2, 12, 3)])
    S.wind()
    S.hill(10, 3, foe=[(3, "t"), (7, "w")])
    S.cp()
    S.mark("E", 12)
    S.bounce(24, [4, 13], foe=[(9, "w"), (19, "f")])
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 3)])
    S.flat(12, foe=[(4, "w"), (8, "j")])
    S.item("M", 4)
    S.mark("D", 6)
    S.flat(14, foe=[(4, "w")], coin=[(2, 12, 3)])
    S.tops([(3, 4, 5), (4, 6, 5), (4, 4, 5), (4, 7, 5), (3, 4, 5)], foe=[(12, "f"), (24, "f")])
    S.wind()
    S.pits([(3, 3, 1), (4, 3, 0), (3, 3, 2), (4, 3, 0)], foe_on=[1])
    S.flat(12, foe=[(4, "w"), (8, "j")], coin=[(2, 10, 3)])
    S.goal()
    r0 = S.room("shaft", gems=1)
    r1 = S.room("key", key=True)
    r2 = S.room("vault")
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "D"), ("room", r2, "in"), "door", key=1)
    S.link(("mark", "E"), ("room", r1, "in"), "tunnel")
    return S.finish(18, "Árbol Milenario", 1, 4, zone=2, notes=["Dos ascensos por el tronco; las corrientes ayudan, pero no perdonan."])


# --------------------------------------------------------------------------------- 19
def l19():
    """Camino de los Susurros (ruta secreta): dos salidas. La normal sigue el camino; la secreta está al final de un túnel oculto
    que solo aparece tras abrir la puerta con la llave del último tramo."""
    S = Seq()
    S.flat(20, foe=[(11, "w"), (16, "j")], coin=[(3, 12, 3)])
    S.start()
    S.river([("log", 3, 4), ("log", 4, 4), ("rock", 3, 3), ("log", 4, 4)])
    S.flat(12, foe=[(4, "w"), (8, "s")], coin=[(2, 10, 3)])
    S.fork(34, low_foe=[(9, "w"), (17, "j"), (25, "w")], spikes=[(13, 2)])
    S.cp()
    S.mouth("A", 14, foe=[(3, "j"), (11, "w")])
    S.ruins(26, bricks=[(5, 4), (14, 4)], crumbles=[(9, 3), (19, 3)], foe=[(8, "w"), (22, "j")])
    S.pits([(4, 3, 0), (4, 3, 2), (4, 3, 0), (5, 3, 1)], foe_on=[1, 3])
    S.item("I", 4) if False else None
    S.flat(12, foe=[(4, "w"), (8, "t")], coin=[(2, 10, 3)])
    S.item("I", 5)
    S.cp()
    S.tops([(3, 4, 5), (4, 6, 5), (4, 4, 5), (4, 6, 5)], foe=[(12, "f")])
    S.mark("B", 6)
    S.flat(14, foe=[(4, "w"), (9, "j")], coin=[(2, 12, 3)])
    S.crush(22, [6, 12, 17], foe=[(9, "w")])
    S.mover(9, "v")
    S.flat(12, foe=[(4, "w"), (8, "s")])
    S.item("U", 4)
    S.cp()
    lx, ty = S.tower([(1, 12), (5, 9), (1, 6)], top_y=6, ledge=5)
    S.c.set(lx + 2, ty - 1, "*")
    S.mark("C", 6)
    S.flat(14, foe=[(4, "w"), (9, "j")], coin=[(2, 12, 3)])
    S.thorns(28, [(5, 3), (10, 2), (16, 3), (22, 2)], shelf=[(7, 4, 5), (16, 5, 4)], foe=[(8, "w"), (13, "j"), (25, "w")])
    S.item("M", 5) if False else None
    S.flat(12, foe=[(4, "t"), (8, "w")], coin=[(2, 10, 3)])
    S.item("M", 4)
    S.cp()
    S.mark("D", 6)
    S.isles([(3, 4, 1, 3), (4, 4, 2, 3), (4, 4, 1, 3), (4, 4, 0, 3)], foe=[(12, "f")])
    S.flat(16, foe=[(5, "w"), (10, "s"), (13, "j")], coin=[(2, 14, 3)])
    S.pits([(3, 3, 1), (4, 3, 0), (3, 3, 2), (4, 3, 0)], foe_on=[1])
    S.goal()
    r0 = S.room("key", key=True, gems=1)
    r1 = S.room("secret", gems=1)
    r2 = S.room("vault")
    S.link(("mark", "A"), ("room", r0, "in"), "tunnel")
    S.link(("room", r0, "out"), ("mark", "B"), "tunnel")
    S.link(("mark", "C"), ("room", r1, "in"), "door", key=1)
    S.link(("mark", "D"), ("room", r2, "in"), "door")
    return S.finish(19, "Camino de los Susurros", 1, 4, kind="secret", zone=1, notes=["Dos salidas: la bandera de siempre y la bandera morada, al final de la puerta con cerradura C."])


# --------------------------------------------------------------------------------- 20
def l20():
    """Castillo del Guardián (castillo con jefe): aproximación por la muralla (prensas, pinchos y tiradores) y arena del Guardián
    de la Espesura, un jefe de tres fases. Dentro del recorrido hay un atajo por túnel y una verja con llave."""
    S = Seq()
    S.flat(18, foe=[(10, "w")], coin=[(3, 12, 3)], prop=0)
    S.start()
    S.bastion(24, crushers=[6, 12, 18], spikes=[(9, 2)], shooters=[15], foe=[(20, "w")])
    S.pits([(3, 4, 0), (4, 3, 1), (3, 4, 0), (4, 3, 2)], foe_on=[1])
    S.sniper(24, [(5, 2), (11, 3), (17, 2)], foe=[(9, "w"), (21, "j")])
    S.cp()
    S.mouth("A", 14, foe=[(3, "w"), (11, "s")], prop=0)
    S.bastion(26, crushers=[7, 13, 19], spikes=[(4, 2), (16, 3)], shooters=[10, 22], foe=[(14, "w")])
    S.mover(9, "m")
    S.flat(12, foe=[(4, "t"), (8, "w")], prop=0)
    S.item("I", 5)
    S.cp()
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 3), (2, 3)])
    S.bastion(28, crushers=[5, 10, 15, 20, 25], spikes=[(7, 2), (18, 2)], shooters=[12, 23], foe=[(9, "w"), (21, "s")])
    lx, ty = S.tower([(1, 12), (5, 9), (1, 6)], top_y=6, ledge=5)
    S.c.set(lx + 2, ty - 1, "*")
    S.mark("B", 6)
    S.flat(14, foe=[(4, "w"), (9, "j")], prop=0)
    S.cp()
    S.hill(10, 3, foe=[(3, "t"), (6, "w")])
    S.sniper(26, [(5, 2), (11, 3), (17, 2), (22, 3)], foe=[(8, "w"), (14, "j"), (24, "w")])
    S.item("U", 4) if False else None
    S.flat(12, foe=[(4, "w"), (8, "s")], prop=0)
    S.item("U", 4)
    S.gate()
    S.flat(14, foe=[(4, "w"), (9, "j")], coin=[(2, 12, 3)], prop=0)
    c = S.c
    c.set(S.x - 12, 14, "*") if False else None
    S.bastion(26, crushers=[6, 11, 16, 21], spikes=[(8, 2), (24, 2)], shooters=[13, 19], foe=[(10, "w")])
    S.item("M", 4) if False else None
    S.pits([(4, 3, 0), (4, 3, 2), (4, 3, 0), (5, 3, 1)], foe_on=[1, 3])
    S.cp()
    S.flat(12, foe=[(4, "w")], coin=[(2, 10, 3)], prop=0)
    S.item("M", 4)
    S.mover(10, "v")
    S.bastion(24, crushers=[5, 10, 15, 20], spikes=[(8, 2)], shooters=[12, 18], foe=[(21, "w")])
    S.cp()
    S.bounce(24, [4, 13], foe=[(9, "w"), (19, "j")], gem=(6, 8))
    S.flat(12, foe=[(4, "w"), (8, "s")], prop=0)
    S.wind()
    lx3, ty3 = S.tower([(1, 12), (5, 9), (1, 6), (5, 3)], top_y=3, ledge=5)
    S.c.set(lx3 + 2, ty3 - 1, "*")
    S.flat(12, foe=[(4, "t"), (8, "w")], prop=0)
    S.item("I", 4)
    S.cp()
    S.sniper(26, [(5, 2), (11, 3), (17, 2), (22, 3)], foe=[(8, "w"), (14, "j"), (24, "w")])
    S.mover(9, "m")
    S.bastion(24, crushers=[5, 10, 15, 20], spikes=[(8, 2), (22, 1)], shooters=[12, 18], foe=[(21, "w")])
    S.crumble([(2, 3), (3, 3), (2, 3), (3, 3)])
    S.flat(14, foe=[(4, "w"), (9, "j")], prop=0)
    S.cp()
    S.flat(10, prop=0)
    # --- arena del jefe: puerta (G) al empezar, jefe (X) al fondo, plataformas y la meta (F) que aparece al vencerlo
    gx = S.x
    S.flat(58, prop=0)
    c.set(gx + 1, 13, "G")
    c.set(gx + 38, 12, "X")
    for dx in (10, 24, 44):
        for k in range(4):
            c.set(gx + dx + k, 12, "=")
    # oro y vidas para el combate
    coins(c, gx + 6, gx + 50, 10)
    c.set(gx + 30, 10, "u") if False else None
    c.set(gx + 54, 14, "F")
    # monedas extra y gemas en el recorrido
    c.set(gx - 35, 8, "*") if False else None
    S.link(("mark", "A"), ("mark", "B"), "tunnel")
    cols = c.w
    # gemas: una en la torre (arriba) y dos escondidas en plataformas altas de la muralla
    c.set(gx - 70, 4, "*") if False else None
    return S.finish(20, "Castillo del Guardián", 5, 5, kind="castle", zone=0, boss=1, notes=["Castillo: prensas, pinchos y tiradores; la puerta (G) cierra la arena del Guardián de la Espesura."])


def build_all():
    out = {}
    for n in range(1, 21):
        fn = globals().get("l%02d" % n)
        if fn is None:
            continue
        out[n] = fn()
        print("ww_%03d.txt: %d columnas, %d puntos de control" % (n, out[n][0], out[n][1]))
    return out

"""Lienzo para dibujar a mano los niveles de WILMEN WORLD (sin piezas prefabricadas).
Coordenadas de celda (x, y); y=0 es el techo. Los rangos son [x0, x1) y [y0, y1)."""
import math, os

WORLD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "levels", "world")


class Cv:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.g = [[" "] * w for _ in range(h)]
        self.top = [h] * w  # fila de la primera celda sólida de la superficie
        self.warps, self.extra = [], []

    def set(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.g[y][x] = c

    def get(self, x, y):
        return self.g[y][x] if 0 <= x < self.w and 0 <= y < self.h else "#"

    def fill(self, x0, y0, x1, y1, c):
        for y in range(y0, y1):
            for x in range(x0, x1):
                self.set(x, y, c)

    def land(self, x0, x1, top):
        """Terreno macizo desde `top` hasta el fondo."""
        for x in range(x0, x1):
            self.top[x] = top
            for y in range(top, self.h):
                self.set(x, y, "#")

    def clear(self, x0, x1):
        """Quita todo el terreno de las columnas (foso sin fondo)."""
        for x in range(x0, x1):
            self.top[x] = self.h
            for y in range(self.h):
                self.set(x, y, " ")

    def carve(self, x0, y0, x1, y1):
        self.fill(x0, y0, x1, y1, " ")

    def oval(self, cx, cy, rx, ry, floor=None):
        for y in range(self.h):
            for x in range(self.w):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0 and (floor is None or y < floor):
                    self.set(x, y, " ")

    def plat(self, x0, x1, y, c="="):
        self.fill(x0, y, x1, y + 1, c)

    def coins(self, x, y, n, dx=1):
        for i in range(n):
            self.set(x + i * dx, y, "o")

    def arc(self, x0, x1, y, h):
        n = x1 - x0
        for i in range(n):
            t = (i + 0.5) / n
            self.set(x0 + i, y - int(round(h * 4 * t * (1 - t))), "o")

    def on(self, x):
        """Fila de pie sobre la superficie de la columna x."""
        return self.top[x] - 1

    def warp(self, a, b, kind, key=0):
        self.warps.append("@warp %d,%d -> %d,%d %s%s" % (a[0], a[1], b[0], b[1], kind, (" key=%d" % key) if key else ""))

    def text(self, title, region, theme, time, par, diff, kind, zone, comments=()):
        out = ["; WILMEN WORLD - %s" % title] + ["; " + c for c in comments]
        out += ["@title " + title, "@region %d" % region, "@theme %d" % theme, "@time %d" % time, "@par %d" % par,
                "@difficulty %d" % diff, "@kind " + kind, "@zone %d" % zone] + self.warps + self.extra
        out += ["".join(r) for r in self.g]
        return "\n".join(out) + "\n"

    def save(self, n, **kw):
        path = os.path.join(WORLD, "ww_%03d.txt" % n)
        open(path, "w").write(self.text(**kw))
        return path

    def preview(self, x0=0, x1=None):
        x1 = x1 or self.w
        return "\n".join("%2d %s" % (y, "".join(self.g[y][x0:x1])) for y in range(self.h))

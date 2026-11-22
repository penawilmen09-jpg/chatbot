#!/usr/bin/env python3
"""Arte de interfaz de WILMEN WORLD (hito 1): botón turquesa del menú (btn_teal) e icono de mundo (icon_world).
El botón sale de btn_green girando el tono; el icono es un globo dibujado con Pillow. Salida: assets/menu/."""
import colorsys, os
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "assets", "menu")


def teal_button():
    im = Image.open(os.path.join(OUT, "btn_green.png")).convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if s > 0.25 and 0.22 < h < 0.5:  # solo el cuerpo verde; el borde dorado, el contorno y el brillo se conservan
                h = (h + 0.14) % 1.0
            nr, ng, nb = colorsys.hsv_to_rgb(h, s, v)
            px[x, y] = (int(nr * 255), int(ng * 255), int(nb * 255), a)
    im.save(os.path.join(OUT, "btn_teal.png"))


def world_icon():
    S = 4
    im = Image.new("RGBA", (20 * S, 20 * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([1 * S, 1 * S, 19 * S, 19 * S], fill=(26, 18, 38, 255))
    d.ellipse([2 * S, 2 * S, 18 * S, 18 * S], fill=(58, 140, 230, 255))
    for poly in ([(5, 5), (9, 4), (11, 7), (8, 10), (5, 9)], [(11, 11), (15, 10), (16, 14), (12, 16), (10, 14)]):
        d.polygon([(x * S, y * S) for x, y in poly], fill=(90, 210, 110, 255))
    d.arc([2 * S, 2 * S, 18 * S, 18 * S], 200, 290, fill=(190, 230, 255, 255), width=S)
    im = im.resize((20, 20), Image.LANCZOS)
    im.save(os.path.join(OUT, "icon_world.png"))


if __name__ == "__main__":
    teal_button()
    world_icon()
    print("btn_teal.png e icon_world.png generados")

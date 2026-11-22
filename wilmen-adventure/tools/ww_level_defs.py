# Composición de los tres niveles de WILMEN WORLD del hito 2 (se ejecuta desde ww_levels.py).
# Cada nivel es una secuencia escrita a mano; los números son decisiones de diseño de ESE nivel.


def level1():
    """Nivel 1 - Sendero de las Luciérnagas (Bosque Esmeralda). Túneles a una bodega con llave, puerta con cerradura."""
    c = Cv()
    x = flat(c, 0, 26, foe=[(15, "w"), (21, "w")], coin=[(4, 12, 3)])
    c.set(3, 14, "P")
    x = stepping_pits(c, x, [(3, 4, 0), (4, 3, 1), (3, 4, 0), (4, 3, 2)], foe_on=[1])
    x = flat(c, x, 12, foe=[(5, "s"), (9, "w")], coin=[(2, 10, 3)])
    x = spike_run(c, x, 30, [(6, 2), (13, 3), (21, 2)], shelf=[(9, 10, 6)], foe=[(26, "w")])
    x = oneway_pits(c, x, [(3, 12, 4), (3, 11, 4), (4, 10, 4), (3, 12, 4)])
    x = checkpoint(c, x)
    # --- bifurcación: la boca del túnel A lleva a la bodega (llave + gema) y de ahí sale mucho más adelante
    xa = x
    x = flat(c, x, 18, foe=[(6, "j"), (12, "w")], coin=[(3, 15, 3)], prop=6)
    mouth_a = (xa + 14, 14)
    x = plateau(c, x, 8, 3, foe=[(3, "w")])
    x = mover_gap(c, x, 8, "m", coin_y=3)
    x = flat(c, x, 10, foe=[(4, "t")], coin=[(2, 8, 3)])
    x = crumble_run(c, x, [(2, 3), (3, 3), (2, 2), (3, 3)])
    x = flat(c, x, 12, foe=[(4, "w"), (9, "s")])
    c.set(x - 6, 14, "I")
    # --- torre hasta una repisa alta con una gema
    x, lx, ty = tower(c, x, [(1, 12), (5, 9), (1, 6)], top_y=6, ledge=6)
    c.set(lx + 2, ty - 1, "*")
    x = flat(c, x, 12, foe=[(5, "w"), (9, "j")], coin=[(2, 10, 3)])
    x = checkpoint(c, x)
    x = spike_run(c, x, 34, [(5, 2), (10, 2), (15, 3), (22, 2), (27, 2)], shelf=[(6, 11, 4), (16, 10, 5)], foe=[(12, "w"), (30, "s")])
    x = stepping_pits(c, x, [(4, 3, 0), (4, 3, 1), (5, 3, 0), (4, 3, 2), (4, 3, 0)], foe_on=[0, 3])
    mouth_c = (x + 3, 14)  # salida del túnel de la bodega, tras el tramo difícil
    x = flat(c, x, 16, foe=[(7, "w")], coin=[(2, 14, 3)])
    x = mover_gap(c, x, 9, "v", coin_y=4)
    x = flat(c, x, 12, foe=[(5, "w"), (8, "j")])
    c.set(x - 5, 14, "M")
    x = crumble_run(c, x, [(2, 3), (2, 3), (3, 2), (2, 3), (3, 3)])
    x = flat(c, x, 14, foe=[(4, "t"), (9, "w")], coin=[(2, 12, 3)])
    x = checkpoint(c, x)
    x = plateau(c, x, 10, 2, foe=[(3, "j"), (6, "w")])
    x = spike_run(c, x, 30, [(4, 3), (10, 3), (17, 4), (24, 2)], shelf=[(6, 11, 5), (13, 10, 5), (20, 11, 5)], foe=[(8, "w"), (27, "w")])
    # --- puerta con cerradura (1 llave) a una cámara con la tercera gema
    door_a = (x + 6, 14)
    x = flat(c, x, 20, foe=[(12, "w")], coin=[(2, 18, 3)])
    x = stepping_pits(c, x, [(3, 3, 1), (4, 3, 0), (3, 3, 2)], foe_on=[1])
    x = flat(c, x, 8, coin=[(1, 7, 3)])
    c.set(x - 4, 14, "F")
    x = flat(c, x, 6)
    main_end = x
    # --- Bodega (cueva): sala cerrada a la derecha del mapa
    gap = 12
    rx = main_end + gap
    c.fill(main_end, 0, rx, R, "#")
    cx0, cx1 = room(c, rx, 58, floor=15, top=3)
    ground(c, cx0, cx1, 15)
    cellar_in = (cx0 + 2, 14)
    c.set(cx0 + 3, 14, " ")
    # la bodega: tramo de pinchos y plataformas, llave al fondo, gema y salida de túnel
    spike_run(c, cx0 + 6, 14, [(3, 2), (8, 3)], shelf=[(5, 11, 4)], gt=15)
    for k in range(5):
        c.set(cx0 + 24 + k, 12, "=")
    c.set(cx0 + 26, 11, "U")
    c.set(cx0 + 36, 14, "w")
    c.set(cx0 + 40, 14, "w")
    c.set(cx0 + 44, 14, "I")
    cellar_out = (cx1 - 4, 14)
    c.set(cx0 + 33, 14, "*")
    # --- Cámara secreta (puerta con llave): sala pequeña
    bx = rx + 58 + 10
    c.fill(rx + 58, 0, bx, R, "#")
    bx0, bx1 = room(c, bx, 34, floor=15, top=4)
    ground(c, bx0, bx1, 15)
    c.set(bx0 + 2, 14, " ")
    vault_door = (bx0 + 2, 14)
    coins(c, bx0 + 5, bx0 + 28, 13)
    c.set(bx0 + 16, 10, "*")
    for k in range(5):
        c.set(bx0 + 14 + k, 12, "=")
    c.set(bx0 + 26, 14, "M")
    # --- conexiones reales
    warp(c, mouth_a, cellar_in, "tunnel")
    warp(c, cellar_out, mouth_c, "tunnel")
    warp(c, door_a, vault_door, "door", key=1, d=1)
    write(1, c, "Sendero de las Luciérnagas", 1, 1, 300, 2, [
        "Bosque Esmeralda. Dos túneles: uno lleva a la bodega (llave y gema) y de ahí sale mucho más adelante.",
        "La llave abre la puerta con cerradura de antes de la meta: tras ella hay una cámara con la tercera gema.",
    ])


def level2():
    """Nivel 2 - Cañón de Ámbar (Desierto Dorado). Verja obligatoria con candado; llave en una torre; túnel y puerta secretos."""
    c = Cv()
    x = flat(c, 0, 24, foe=[(14, "j"), (20, "w")], coin=[(4, 12, 3)])
    c.set(3, 14, "P")
    x = plateau(c, x, 10, 2, foe=[(3, "w"), (7, "s")])
    x = crumble_run(c, x, [(2, 3), (3, 3), (3, 2), (2, 3)])
    x = flat(c, x, 12, foe=[(4, "w"), (9, "t")])
    x = spike_run(c, x, 32, [(5, 3), (11, 2), (17, 3), (25, 2)], shelf=[(7, 10, 5), (18, 11, 5)], foe=[(14, "w"), (29, "j")])
    x = stepping_pits(c, x, [(4, 3, 0), (4, 3, 1), (5, 3, 0), (4, 3, 1)], foe_on=[2])
    x = checkpoint(c, x)
    # --- torre de la llave (opcional hasta que se llega a la verja: sin llave no se pasa)
    x, lx, ty = tower(c, x, [(1, 12), (5, 9), (1, 6), (6, 3)], top_y=3, ledge=6)
    c.set(lx + 2, ty - 1, "U")
    x = flat(c, x, 14, foe=[(6, "w"), (10, "j")], coin=[(2, 12, 3)])
    c.set(x - 6, 14, "I")
    xa = x
    x = flat(c, x, 12, foe=[(5, "s")], coin=[(2, 10, 3)])
    mouth_a = (xa + 8, 14)
    x = conveyor(c, x, 22, (4, 16, ">"), hazard=(17, 2), foe=[(19, "w")])
    x = mover_gap(c, x, 9, "m", coin_y=3)
    x = flat(c, x, 10, foe=[(4, "t"), (7, "w")], coin=[(2, 8, 3)])
    x = checkpoint(c, x)
    x = wind_lift(c, x)
    x = oneway_pits(c, x, [(3, 12, 4), (4, 10, 4), (4, 12, 4), (3, 9, 5)])
    x = flat(c, x, 12, foe=[(3, "w"), (8, "j")])
    x = crusher_hall(c, x, 22, [6, 12, 17], foe=[(9, "w")])
    mouth_c = (x + 4, 14)
    x = flat(c, x, 14, foe=[(5, "s"), (10, "w")], coin=[(2, 12, 3)])
    c.set(x - 5, 14, "M")
    x = spike_run(c, x, 36, [(4, 3), (9, 3), (15, 3), (22, 3), (28, 2)], shelf=[(5, 11, 5), (14, 10, 5), (23, 11, 5)], foe=[(11, "w"), (18, "j"), (32, "w")])
    x = checkpoint(c, x)
    # --- verja de la pirámide (cuesta 1 llave) y tramo final
    x = flat(c, x, 10, foe=[(4, "w")], coin=[(2, 8, 3)])
    vault_door = None
    door_a = (x + 6, 14)
    x = gate_wall(c, x, h=3, thick=2)
    x = flat(c, x, 16, foe=[(4, "s"), (8, "w"), (12, "j")], coin=[(2, 14, 3)])
    x = crumble_run(c, x, [(2, 3), (3, 3), (2, 3), (3, 2)])
    x = stepping_pits(c, x, [(3, 3, 1), (4, 3, 0), (3, 3, 2)], foe_on=[1])
    x = flat(c, x, 10, coin=[(1, 9, 3)])
    c.set(x - 4, 14, "F")
    x = flat(c, x, 6)
    main_end = x
    # gemas: una en la torre (junto a la llave, más arriba), una en la cámara del túnel, una en la cámara de la puerta
    c.set(lx + 3, ty - 3, "*")
    # --- Cueva de arena (túnel): sala con gema y un reloj grande
    rx = main_end + 12
    c.fill(main_end, 0, rx, R, "#")
    cx0, cx1 = room(c, rx, 60, floor=15, top=3)
    ground(c, cx0, cx1, 15)
    cave_in = (cx0 + 2, 14)
    spike_run(c, cx0 + 6, 18, [(3, 2), (10, 3)], shelf=[(5, 11, 4)])
    for k in range(5):
        c.set(cx0 + 28 + k, 11, "=")
    c.set(cx0 + 30, 10, "*")
    c.set(cx0 + 40, 14, "w")
    c.set(cx0 + 44, 14, "j")
    c.set(cx0 + 48, 14, "M")
    cave_out = (cx1 - 4, 14)
    # --- Cámara del faraón (puerta con llave) - exige guardar una llave extra: se consigue en la cueva
    c.set(cx0 + 20, 14, "U")
    bx = rx + 60 + 10
    c.fill(rx + 60, 0, bx, R, "#")
    bx0, bx1 = room(c, bx, 36, floor=15, top=4)
    ground(c, bx0, bx1, 15)
    vault_in = (bx0 + 2, 14)
    coins(c, bx0 + 5, bx0 + 30, 13)
    c.set(bx0 + 18, 10, "*")
    for k in range(5):
        c.set(bx0 + 16 + k, 12, "=")
    c.set(bx0 + 28, 14, "I")
    # la puerta con cerradura está justo antes de la verja
    warp(c, mouth_a, cave_in, "tunnel")
    warp(c, cave_out, mouth_c, "tunnel")
    warp(c, door_a, vault_in, "door", key=1)
    write(2, c, "Cañón de Ámbar", 2, 3, 285, 3, [
        "Desierto Dorado. La verja de la pirámide es obligatoria: la llave está en lo alto de la torre.",
        "El túnel lleva a la cueva de arena (gema y otra llave) y sale pasada la prensa. La puerta lleva a la cámara del faraón.",
    ])


def level3():
    """Nivel 3 - Fundición de Brasas (Reino Volcánico). Lava, géiseres, prensas; verja obligatoria y atajo por puerta."""
    c = Cv()
    x = flat(c, 0, 22, foe=[(13, "w"), (18, "j")], coin=[(4, 11, 3)])
    c.set(3, 14, "P")
    x = geyser_field(c, x, 20, [6, 12], foe=[(16, "w")])
    x = crumble_run(c, x, [(2, 3), (3, 3), (2, 3), (3, 2), (2, 3)], lava=True)
    x = flat(c, x, 10, foe=[(4, "w"), (7, "s")])
    x = mover_gap(c, x, 9, "m", lava=True, coin_y=3)
    x = flat(c, x, 10, foe=[(5, "t")])
    x = checkpoint(c, x)
    x = spike_run(c, x, 34, [(5, 3), (11, 3), (18, 2), (24, 3), (30, 2)], shelf=[(7, 10, 5), (19, 11, 5)], foe=[(14, "j"), (21, "w"), (31, "w")])
    xa = x
    x = flat(c, x, 12, foe=[(5, "j")])
    mouth_a = (xa + 8, 14)
    x = conveyor(c, x, 24, (4, 18, "<"), hazard=(2, 2), foe=[(20, "w")])
    x, lx, ty = tower(c, x, [(1, 12), (5, 9), (1, 6)], top_y=6, ledge=6)
    c.set(lx + 2, ty - 1, "U")
    x = flat(c, x, 12, foe=[(4, "w"), (8, "j")])
    c.set(x - 5, 14, "I")
    x = checkpoint(c, x)
    x = crusher_hall(c, x, 24, [6, 12, 18], foe=[(10, "w")])
    x = geyser_field(c, x, 22, [5, 11, 17], foe=[(8, "w")])
    x = crumble_run(c, x, [(2, 3), (3, 3), (2, 3), (3, 3), (2, 2)], lava=True)
    x = flat(c, x, 10, foe=[(4, "t"), (7, "w")])
    c.set(x - 4, 14, "M")
    # --- puerta con cerradura: atajo sobre el lago de lava (1 llave); sin ella hay que cruzarlo a pie
    door_a = (x + 6, 14)
    x = flat(c, x, 14, foe=[(8, "w")], coin=[(2, 12, 3)])
    x = checkpoint(c, x)
    x = stepping_pits(c, x, [(4, 3, 0), (5, 3, 1), (4, 3, 0), (5, 3, 2), (4, 3, 0)], foe_on=[0, 3])
    for xx in range(x - 40, x - 8):
        if c.get(xx, 15) == " ":
            c.set(xx, R - 2, "L")
            c.set(xx, R - 1, "L")
    mouth_c = (x + 3, 14)
    x = flat(c, x, 14, foe=[(6, "w"), (10, "s")])
    x = wind_lift(c, x)
    x = oneway_pits(c, x, [(3, 12, 4), (4, 10, 4), (4, 12, 4), (4, 9, 4)])
    x = flat(c, x, 12, foe=[(3, "j"), (8, "w")])
    x = crusher_hall(c, x, 26, [7, 13, 19], foe=[(11, "w"), (22, "j")])
    x = checkpoint(c, x)
    # --- verja del horno (1 llave) y gran final
    x = flat(c, x, 8, coin=[(1, 7, 3)])
    gate_x = x
    x = gate_wall(c, x, h=3, thick=2)
    x = flat(c, x, 14, foe=[(4, "w"), (8, "s"), (11, "j")], coin=[(2, 12, 3)])
    x = geyser_field(c, x, 18, [5, 10, 14], foe=[(7, "w")])
    x = crumble_run(c, x, [(2, 3), (3, 3), (3, 2), (2, 3)], lava=True)
    x = stepping_pits(c, x, [(3, 3, 1), (4, 3, 0), (4, 3, 2), (3, 3, 0)], foe_on=[1])
    x = flat(c, x, 10, coin=[(1, 9, 3)])
    c.set(x - 4, 14, "F")
    x = flat(c, x, 6)
    main_end = x
    c.set(lx + 4, ty - 3, "*")
    # --- Cámara de la forja (túnel): gema + llave
    rx = main_end + 12
    c.fill(main_end, 0, rx, R, "#")
    cx0, cx1 = room(c, rx, 62, floor=15, top=3)
    ground(c, cx0, cx1, 15)
    forge_in = (cx0 + 2, 14)
    spike_run(c, cx0 + 6, 16, [(3, 2), (9, 3)], shelf=[(5, 11, 4)])
    for xx in range(cx0 + 24, cx0 + 36):
        c.set(xx, 18, "L")
        c.set(xx, 19, "L")
        c.set(xx, 15, " ")
        c.set(xx, 16, " ")
        c.set(xx, 17, " ")
    for k in range(4):
        c.set(cx0 + 22 + k, 14, "c")
    c.set(cx0 + 25, 12, "*")
    for xx in range(cx0 + 24, cx0 + 36, 4):
        for k in range(2):
            c.set(xx + k, 13, "c")
    c.set(cx0 + 42, 14, "U")
    c.set(cx0 + 46, 14, "w")
    c.set(cx0 + 50, 14, "M")
    forge_out = (cx1 - 4, 14)
    # --- Sala del tesoro (puerta): gema
    bx = rx + 62 + 10
    c.fill(rx + 62, 0, bx, R, "#")
    bx0, bx1 = room(c, bx, 36, floor=15, top=4)
    ground(c, bx0, bx1, 15)
    vault_in = (bx0 + 2, 14)
    coins(c, bx0 + 5, bx0 + 30, 13)
    c.set(bx0 + 18, 10, "*")
    for k in range(5):
        c.set(bx0 + 16 + k, 12, "=")
    c.set(bx0 + 28, 14, "M")
    warp(c, mouth_a, forge_in, "tunnel")
    warp(c, forge_out, mouth_c, "tunnel")
    warp(c, door_a, vault_in, "door", key=1)
    write(3, c, "Fundición de Brasas", 3, 7, 320, 4, [
        "Reino Volcánico. Lava, géiseres y prensas. La verja del horno es obligatoria; la llave está en la torre.",
        "El túnel lleva a la forja (gema y otra llave) y sale al otro lado del lago de lava; la puerta lleva a la sala del tesoro.",
    ])


def build_all():
    level1()
    level2()
    level3()

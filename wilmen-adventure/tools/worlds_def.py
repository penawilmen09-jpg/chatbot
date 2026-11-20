"""Definiciones compartidas por el generador de niveles (levelgen) y el de arte (gen_art2).

PROPS[mundo] = lista de 9 elementos de atrezo. En el texto del nivel se escriben con los dígitos '1'..'9'
(posición en la lista + 1). Roles fijos por posición:
  1 grande (hito)  2 mediano  3 pequeño  4 pequeño 2  5 luz/animado  6 estructura  7 colgante  8 animado grande/medio  9 ancho bajo
Cada entrada: (nombre, ancho_px, alto_px, fotogramas, anclaje) con anclaje 'g' (apoyado en el suelo) o 'h' (cuelga del techo).
"""

ROLES = {1: "big", 2: "mid", 3: "small", 4: "small", 5: "light", 6: "struct", 7: "hang", 8: "anim", 9: "wide"}

PROPS = {
    1: [("arbol_gigante", 48, 96, 1, "g"), ("arbol", 32, 64, 1, "g"), ("arbusto_flores", 16, 12, 1, "g"),
        ("helecho_seta", 16, 14, 1, "g"), ("flor_mece", 16, 16, 2, "g"), ("poste_puente", 16, 24, 1, "g"),
        ("lianas", 16, 40, 1, "h"), ("tronco_setas", 32, 16, 1, "g"), ("hierba", 32, 10, 1, "g")],
    2: [("cristal_gigante", 40, 72, 1, "g"), ("cristal", 24, 44, 1, "g"), ("cristalitos", 16, 14, 1, "g"),
        ("seta_luminosa", 16, 16, 2, "g"), ("destello_cristal", 16, 24, 2, "g"), ("soporte_mina", 32, 32, 1, "g"),
        ("estalactita", 16, 40, 1, "h"), ("farol_mina", 16, 24, 2, "g"), ("rocas", 32, 12, 1, "g")],
    3: [("piramide", 64, 64, 1, "g"), ("palmera", 32, 56, 1, "g"), ("cactus", 16, 24, 1, "g"),
        ("huesos_vasija", 16, 12, 1, "g"), ("antorcha_arena", 16, 24, 2, "g"), ("arco_ruinas", 48, 40, 1, "g"),
        ("tela_colgante", 16, 32, 1, "h"), ("obelisco", 16, 56, 1, "g"), ("rocas_arena", 32, 12, 1, "g")],
    4: [("pico_hielo", 48, 80, 1, "g"), ("pino_nevado", 32, 56, 1, "g"), ("monton_nieve", 16, 10, 1, "g"),
        ("cristal_hielo", 16, 16, 1, "g"), ("farol_aldea", 16, 24, 2, "g"), ("cabana_nieve", 40, 32, 1, "g"),
        ("carambanos", 16, 32, 1, "h"), ("muneco_nieve", 16, 24, 1, "g"), ("rocas_hielo", 32, 12, 1, "g")],
    5: [("torre_gotica", 40, 96, 1, "g"), ("arbol_muerto", 32, 56, 1, "g"), ("lapida", 16, 20, 1, "g"),
        ("cruz", 16, 20, 1, "g"), ("antorcha_muro", 16, 28, 2, "g"), ("puerta_cripta", 40, 40, 1, "g"),
        ("cadena_estandarte", 16, 40, 1, "h"), ("fantasma", 16, 24, 2, "g"), ("huesos", 32, 10, 1, "g")],
    6: [("isla_pagoda", 48, 72, 1, "g"), ("arbol_nube", 32, 48, 1, "g"), ("flores_cielo", 16, 12, 1, "g"),
        ("torre_bandera", 16, 32, 1, "g"), ("molinillo", 24, 32, 2, "g"), ("poste_farol", 16, 28, 1, "g"),
        ("cesta_colgante", 16, 28, 1, "h"), ("molino_grande", 40, 72, 2, "g"), ("nube_baja", 32, 12, 1, "g")],
    7: [("pico_volcan", 48, 80, 1, "g"), ("obsidiana", 24, 48, 1, "g"), ("roca_lava", 16, 12, 1, "g"),
        ("grieta_brasas", 16, 16, 2, "g"), ("brasero", 16, 28, 2, "g"), ("yunque_forja", 32, 24, 1, "g"),
        ("estalactita_magma", 16, 40, 1, "h"), ("arbol_quemado", 32, 48, 1, "g"), ("rocas_ceniza", 32, 12, 1, "g")],
    8: [("arbol_jungla", 48, 96, 1, "g"), ("palmera_tropical", 32, 64, 1, "g"), ("helecho_gigante", 16, 16, 1, "g"),
        ("totem", 16, 32, 1, "g"), ("flor_brillante", 16, 20, 2, "g"), ("arco_templo", 48, 48, 1, "g"),
        ("lianas_largas", 16, 48, 1, "h"), ("seta_gigante", 24, 40, 1, "g"), ("raices", 32, 12, 1, "g")],
    9: [("chimenea_humo", 32, 88, 2, "g"), ("torre_tuberias", 24, 56, 1, "g"), ("caja", 16, 16, 1, "g"),
        ("barril", 16, 16, 1, "g"), ("vapor", 16, 24, 2, "g"), ("maquina", 40, 32, 1, "g"),
        ("cable_colgante", 16, 40, 1, "h"), ("engranaje_grande", 32, 32, 2, "g"), ("tuberias", 32, 12, 1, "g")],
    10: [("espira_dorada", 48, 96, 1, "g"), ("columna_arco", 24, 56, 1, "g"), ("cristal_vacio", 16, 16, 1, "g"),
         ("gema_flotante", 16, 16, 2, "g"), ("brasero_violeta", 16, 28, 2, "g"), ("portal_gigante", 48, 48, 1, "g"),
         ("estandarte", 16, 40, 1, "h"), ("orbe_pedestal", 16, 32, 2, "g"), ("escombros", 32, 12, 1, "g")],
}

# Tema de cada mundo para el nivel: lo que cae/flota en el aire y cómo se llama el líquido de los fosos
WORLD_KEY = {
    1: "bosque", 2: "cuevas", 3: "desierto", 4: "hielo", 5: "castillo",
    6: "islas", 7: "volcan", 8: "jungla", 9: "mecanico", 10: "final",
}

# Zonas visuales de cada mundo: niveles 1-3, 4-6 y 7-9 (+ arena del jefe, nivel 10)
def zone_of(idx):
    if idx >= 10:
        return 3
    if idx <= 3:
        return 0
    if idx <= 6:
        return 1
    return 2


# Qué trozos de nivel se usan (abreviaturas -> nombre real del trozo)
ABBR = dict(
    fl="flat", gp="gap", st="stairs", pl="platforms", bl="blocks", wl="wall", sp="spikes", tn="tunnel",
    mv="moving", vt="vertical", ga="gauntlet", ic="ice", cr="crumble", wi="wind", gy="geyser", mu="mud",
    cv="conveyor", cs="crusher", is_="islands", tr="treasure",
    hi="hills", mo="mountain", br="bridge", va="valley", wf="waterfall", ca="canopy", to="tower",
    pi="pillars", cn="cavern",
)

# 3 zonas de trozos por nivel (1-9). El nivel 7 de cada mundo es la cámara secreta; el 10, el jefe.
RECIPES = {
    1: {
        1: ["hi fl st", "hi br bl", "mo hi pl"],
        2: ["st wl hi", "tn pl gp", "ca hi st"],
        3: ["ca pl gp", "ca vt mv", "to pl ca"],
        4: ["hi wf br", "va st wf", "br va hi"],
        5: ["br hi br", "gp pl br", "mo br st"],
        6: ["hi hi mo", "st hi wl", "mo hi sp"],
        7: ["pl cn pl", "tr pl cn", "pl tr pl"],
        8: ["hi tn st", "cn pl hi", "tn ca hi"],
        9: ["hi mo st", "hi ca pl", "wf hi br"],
    },
    2: {
        1: ["fl hi cn", "cn pl st", "cn bl hi"],
        2: ["hi va pl", "va br cn", "wf va st"],
        3: ["tn cr pl", "vt tn wl", "cn mv sp"],
        4: ["cn st cn", "pl gp cn", "va hi tn"],
        5: ["vt pl cn", "vt cn st", "cn br hi"],
        6: ["mo cn hi", "pl sp mo", "cn va pl"],
        7: ["cn pl cn", "tr cn pl", "cn tr cn"],
        8: ["tn cn tn", "bl cr cn", "mv tn pl"],
        9: ["va br cn", "wf va pl", "cn mv va"],
    },
    3: {
        1: ["hi fl hi", "hi gp st", "mo hi pl"],
        2: ["hi va pl", "va bl hi", "st va pi"],
        3: ["pi wl hi", "pl pi sp", "mo pi gp"],
        4: ["hi hi br", "gp pl hi", "mv hi ga"],
        5: ["mo st gp", "wl vt pl", "gp br mo"],
        6: ["pi tn cn", "mo pi sp", "tn pl wl"],
        7: ["hi pl hi", "tr pl hi", "pl tr hi"],
        8: ["hi wi gp", "pl wi hi", "cr hi wi"],
        9: ["hi mo pi", "mo tn st", "mo cr pl"],
    },
    4: {
        1: ["hi fl ic", "hi gp st", "hi pl ic"],
        2: ["mo hi st", "mo mo pl", "vt mo hi"],
        3: ["cn ic cn", "tn pl cn", "cn sp st"],
        4: ["va ic br", "va pl va", "hi va gp"],
        5: ["fl hi bl", "ca hi wl", "br hi pl"],
        6: ["hi wi gp", "ic wi pl", "mo wi hi"],
        7: ["hi pl ic", "tr pl hi", "pl tr hi"],
        8: ["mo sp ic", "pl ic gp", "mo vt ic"],
        9: ["mo st mo", "vt mo pl", "mo mo cr"],
    },
    5: {
        1: ["br hi br", "to gp pl", "br wl st"],
        2: ["tn pl bl", "cn wl mv", "tn to pi"],
        3: ["st to vt", "to pl to", "vt gp to"],
        4: ["br gp pl", "va br cr", "br mv to"],
        5: ["tn bl wl", "pl cn sp", "vt tn pl"],
        6: ["cn sp cn", "tn cr gp", "cn mv wl"],
        7: ["pl cn pl", "tr cn pl", "cn tr pl"],
        8: ["to br to", "pl br to", "st to gp"],
        9: ["pi bl to", "tn pi ga", "to pl st"],
    },
    6: {
        1: ["hi pl is_", "is_ br pl", "hi gp is_"],
        2: ["is_ is_ pl", "ca is_ mv", "is_ vt is_"],
        3: ["wi pl is_", "to wi gp", "pl wi is_"],
        4: ["br is_ br", "pl br cr", "br mv br"],
        5: ["is_ cr wi", "pl is_ wi", "mv is_ gp"],
        6: ["wi vt wi", "is_ wi pl", "vt wi is_"],
        7: ["pl is_ pl", "tr is_ pl", "is_ tr pl"],
        8: ["ca is_ hi", "wf is_ ca", "bl is_ pl"],
        9: ["to br is_", "pi to pl", "vt to br"],
    },
    7: {
        1: ["hi mo gp", "st sp hi", "mo hi pl"],
        2: ["va br pl", "va mv hi", "br va st"],
        3: ["gy hi gp", "pl gy cr", "mo gy st"],
        4: ["mo wl sp", "cn pl wl", "vt mo cr"],
        5: ["br gp br", "cr br hi", "br mv mo"],
        6: ["mo va gy", "va pl cr", "mo cn vt"],
        7: ["pl cn pl", "tr pl cn", "pl tr pl"],
        8: ["tn cs cv", "wl cv sp", "pl cs mo"],
        9: ["cn va gy", "wf va br", "mo cn cr"],
    },
    8: {
        1: ["hi ca st", "ca bl gp", "hi ca pl"],
        2: ["mu va pl", "va cr hi", "mu br va"],
        3: ["pi hi wl", "to pi sp", "mo pl pi"],
        4: ["ca pl gp", "vt ca mv", "ca pl st"],
        5: ["mo pi ga", "to wl sp", "tn pi mo"],
        6: ["hi wf va", "wf br pl", "va wf ca"],
        7: ["pl cn pl", "tr pl cn", "pl tr pl"],
        8: ["hi mo st", "tn mu wl", "ca cr hi"],
        9: ["mo pi cr", "pl mo sp", "to pi gp"],
    },
    9: {
        1: ["hi cv pl", "ca cv gp", "to cs mv"],
        2: ["cv hi cv", "ca cv cs", "mo cv gp"],
        3: ["pl cs ca", "vt pl cv", "to cs pl"],
        4: ["cs pi pl", "mo cs cv", "cs ca to"],
        5: ["tn sp cr", "ca mv cn", "hi cv sp"],
        6: ["cv ca hi", "pl cv mv", "to cs cv"],
        7: ["pl cn pl", "tr pl cn", "pl tr pl"],
        8: ["to vt pl", "to br to", "vt to cv"],
        9: ["cn cs hi", "to pl ga", "mv cs ca"],
    },
    10: {
        1: ["st pi br", "to gp pl", "is_ br pi"],
        2: ["pi hi wl", "is_ pl pi", "to br mv"],
        3: ["is_ wi is_", "vt is_ pl", "is_ cr is_"],
        4: ["br is_ br", "br mv br", "br to br"],
        5: ["ca hi is_", "va br ca", "is_ wf pl"],
        6: ["to br to", "wl pi gy", "to vt cs"],
        7: ["pl cn pl", "tr pl cn", "pl tr pl"],
        8: ["cv pl cr", "wi is_ vt", "cs mv is_"],
        9: ["pi to sp", "br pi ga", "to mv to"],
    },
}
# Trozo de relleno por mundo (cuando hace falta alargar una zona en los niveles más difíciles)
FILLER = {1: ["hi", "pl"], 2: ["cn", "pl"], 3: ["hi", "pi"], 4: ["hi", "ic"], 5: ["tn", "to"],
          6: ["is_", "pl"], 7: ["mo", "gy"], 8: ["ca", "hi"], 9: ["cv", "ca"], 10: ["pi", "br"]}

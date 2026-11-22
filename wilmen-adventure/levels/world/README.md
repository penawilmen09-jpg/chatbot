# Niveles de WILMEN WORLD

`levels/world/ww_NNN.txt` (NNN = 001..120). Mismo formato de mapa que WILMEN ADVENTURE (una letra = una celda de 16 px,
20 filas; ver `levels/README.md`) más lo siguiente. Las líneas que empiezan por `;` son comentarios.

## Glifos nuevos
| Carácter | Significado |
|---|---|
| `T` | Boca de túnel (se entra con SALTO estando encima, o permaneciendo 0,35 s). Va sobre suelo firme |
| `A` | Puerta (se entra caminando hacia ella; si tiene cerradura gasta 1 llave la primera vez y queda abierta). Sobre suelo |
| `Q` | Verja con candado: columna de `Q` (mínimo 3 celdas). Cuesta 1 llave y queda abierta para siempre |
| `U` | Llave (cada llave se recoge una sola vez por partida; se gasta en verjas y puertas con cerradura) |
| `I` / `M` | Reloj de tiempo extra: +15 s / +30 s |
| `O` | Bandera de SALIDA SECRETA (morada): completa el nivel y abre un camino oculto en el mapa. Solo en los niveles 5, 9, 13 y 19 de cada región |
| `X` / `G` | Jefe de varias fases (castillo) y puerta de su arena (como en WILMEN ADVENTURE). La arena llega hasta el final del nivel y la meta `F` va tras ella |

## Directivas (`@clave valor`)
```
@title Nombre del nivel
@region 1..6         (Bosque Esmeralda, Desierto Dorado, Reino Volcánico, Reino Congelado, Océano Perdido, Reino de las Sombras)
@theme 1..10         (arte de WILMEN ADVENTURE reutilizado: tiles, fondo, enemigos y poder del héroe)
@time 300            (límite de tiempo en segundos; a cero el personaje muere y pierde una vida)
@difficulty 1..5
@kind normal|cave|house|fortress|secret|castle   (tipo de entrada en el mapa)
@zone 0..3           (variante del fondo)
@boss 1              (solo castillos)
@warp x,y -> x,y tunnel|door [key=N] [dir=1|-1]
```
`@warp` conecta DOS celdas (coordenadas de celda): cada una lleva el glifo `T` (túnel) o `A` (puerta). Es de ida y vuelta.
`key=N` (solo puertas) pone la cerradura en el primer extremo. `dir` indica a qué lado de la puerta aparece el jugador.

## Reloj
El reloj arranca al acabar la presentación del nivel. Cada punto de control guarda el tiempo restante; al perder una vida
(por tiempo o por otra causa) se reaparece en el último punto de control con ese tiempo, y nunca con menos de 60 s.
Los relojes suman segundos (con un máximo de +120 s sobre el límite del nivel).

## Cómo se hacen y se comprueban
Los niveles se componen a mano, pieza a pieza, en `tools/ww_level_defs.py` (usa las piezas de `tools/ww_levels.py`):
`python3 tools/ww_levels.py` los escribe. `python3 tools/ww_check.py` comprueba que la meta y todas las gemas, llaves y relojes
son alcanzables (con la física real de saltos, llaves que se gastan y túneles/puertas), que hay suficientes llaves, que el
límite de tiempo es razonable y que el nivel es largo y variado. `python3 tools/ww_preview.py N salida.png` dibuja una vista general.

## Mapa general
`levels/world/map.json` (generado por `tools/ww_map.py`, comprobado con `--check`) describe los 120 niveles (20 por región:
14 normales, 2 cuevas, 1 casa de bonificación, 1 fortaleza, 1 con ruta secreta y 1 castillo), sus caminos, puentes, ríos,
montañas y las condiciones que abren cada camino (nivel completado o salida secreta). El arte del mapa lo genera
`tools/gen_ww_map_art.py`. Una región solo es jugable si su estado es `playable`; las demás se ven «en construcción».

## Región 1: Bosque Esmeralda (20 niveles)
`tools/ww_r1_defs.py`: un nivel por función, cada uno con su concepto y su secuencia de piezas (`tools/ww_pieces.py`).
`python3 tools/ww_levels.py` los escribe en `ww_001.txt`..`ww_020.txt`; entre 700 y 1000 columnas cada uno.

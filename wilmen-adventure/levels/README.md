# Formato de los niveles

Cada nivel es un fichero de texto `levels/data/level_XX.txt` (XX = 01..20). Una letra = una celda de
16x16 px, 20 filas de alto. Las líneas que empiezan por `;` son comentarios. Puedes editarlos a mano
y volver a comprobarlos con `python3 tools/levelgen.py --check`.

| Carácter | Significado |
|---|---|
| `#` | Terreno sólido (la superficie y el relleno se dibujan solos) |
| `=` | Plataforma que se atraviesa desde abajo |
| `B` | Ladrillo: se rompe golpeándolo con la cabeza (o con el Impulso de Cristal) |
| `?` | Bloque con una moneda |
| `+` | Bloque con un corazón |
| `H` | Bloque **oculto** con vida extra (aparece al golpear desde abajo) |
| `K` | Bloque **oculto** con 5 monedas |
| `^` | Pinchos |
| `L` | Lava (daña y te lanza hacia arriba) |
| `o` | Moneda |
| `*` | Gema (3 por nivel) |
| `h` / `u` | Corazón / vida extra sueltos |
| `S` | Resorte |
| `m` / `v` | Plataforma móvil horizontal / vertical |
| `C` | Punto de control |
| `P` | Inicio del jugador |
| `F` | Meta (en niveles de jefe aparece al derrotarlo) |
| `w` `s` `j` `f` `t` | Enemigos: caminante, pinchudo (no se pisa), saltarín, volador, tirador |
| `X` | Jefe |
| `G` | Puerta de la arena del jefe (al cruzarla se cierra y empieza el combate) |
| `d` | Decoración |

# WILMEN WORLD · Bosque Esmeralda · 20 fichas de diseño (versión completa para revisión)

**Estado: solo diseño. No hay ningún nivel construido.** Los pasos A (entrar a puertas/túneles solo con SALTO) y B (enemigos y
trampas nuevos) están hechos y probados. Estas fichas sustituyen a las anteriores. Los 20 niveles se dibujan a mano, uno por
uno, **sin la biblioteca de piezas** con la que se hicieron los actuales.

## 0. Medidas de referencia (para entender las dimensiones)

1 celda = 16 px. La pantalla muestra unas 30 × 17 celdas (más ancha en móviles alargados).

| Capacidad | Valor real en el juego |
|---|---|
| Salto normal | sube ~3,5 celdas; cruza huecos de hasta 4-5 celdas con carrerilla |
| Seta vertical | sube ~7,5 celdas |
| Seta diagonal | lanza ~14 celdas hacia delante |
| Liana de 10 celdas | el asa oscila ±6,5 celdas; se suelta a ~400 px/s |
| Columna de burbujas | eleva hasta ~170 px/s (≈ 10 celdas en 1,3 s) |
| Corriente de agua | arrastra 80 px/s (más que andar contra ella) |
| Ascensor | sube 6 celdas con parada abajo (1 s) y arriba |
| Plataforma orbital | círculo de 3 celdas de radio |
| Puente derrumbable | cae en cadena desde la tabla pisada; se cruza corriendo sin parar (hasta ~40 tablas) |
| Plataformas que desaparecen | 3,6 s sólidas, 1,2 s ocultas; las cadenas están desfasadas para dar ritmo |

## 1. Reglas que cumplirá cada nivel

1. **Estructura propia**: ningún par de niveles comparte el tipo de recorrido. Ningún par consecutivo se parece en estructura ni en
   mecánica principal.
2. **Túneles únicos**: cada túnel, cueva o habitación subterránea tiene sus propias dimensiones, forma y recorrido. Ninguna sala
   se repite con otro color.
3. **Enemigos por comportamiento**: cada nivel usa un conjunto distinto y los coloca según el escenario, no a intervalos fijos.
4. **Mecánicas**: cada una debuta en un nivel que la enseña y vuelve después con otro uso. No hace falta usarlas todas siempre.
5. **Tamaño variable**: de 20 a 32 filas y de 340 a 900 columnas según el diseño. Tiempos ajustados a cada nivel.
6. **Se conserva**: cuenta atrás (a cero muere y pierde una vida), vidas, puntos de control, monedas, 3 gemas por nivel, llaves y
   guardado. Las puertas y túneles solo se entran con SALTO.
7. **Justo y completable**: dificultad creciente. Un nivel solo se da por terminado si (a) el validador lo da por completable,
   (b) sus mecánicas se comprueban en el motor y (c) la comparación con los demás confirma que es distinto. Las gemas más
   difíciles nunca bloquean el avance.
8. **Huecos del mapa que se respetan**: cuevas en 4 y 13, casa en 7, fortaleza en 10, nivel secreto en 19, castillo con jefe en 20;
   salidas secretas en 5 (→ casa 1-7), 9 (→ 1-15), 13 (→ 1-19) y 19 (→ túnel sellado al Océano).
9. Cada nivel tiene **al menos 1 llave** (para sus puertas) y 3 gemas; las llaves y las puertas están siempre en el mismo nivel.

## 2. Piezas disponibles

- **Mecánicas de la tanda 0**: setas, lianas, troncos rodantes, plataformas que desaparecen, puentes derrumbables,
  interruptores y bloques conmutables, corrientes y burbujas, dardos, péndulos, plataformas orbitales, ascensores.
- **Del juego original**: plataformas móviles (horizontal/vertical), resortes, plataformas que se desmoronan, carrito minero,
  perseguidor (roca que rueda), bloques ocultos y habitaciones secretas.
- **Enemigos**: caminante, pinchudo (no se pisa), saltarín, volador, disparador; **nuevos**: topo, guardián, murciélago,
  lanzarrocas. **Trampas**: prensas, dardos, péndulos, troncos, pinchos.

## 3. Matriz de comparación

| # | Nombre | Tipo | Tamaño | Estructura | Mecánica principal | Familia de enemigos | Trampas | Túnel |
|---|---|---|---|---|---|---|---|---|
| 1 | Sendero del Amanecer | normal | 520×20 | colinas horizontales | setas | caminante, saltarín | ninguna | corto recto con llave |
| 2 | Garganta de las Cascadas | normal | 360×32 | ascenso en 3 terrazas | corrientes y burbujas | volador, disparador | pinchos | pozo vertical |
| 3 | Puente de los Mil Pasos | normal | 820×22 | pilares y puentes, sin suelo | puentes y plataformas que desaparecen | murciélago, volador | dardos | corredor largo bajo el abismo |
| 4 | Cueva de las Raíces | cueva | 560×28 | red de 6 salas | interruptores | topo, lanzarrocas | pinchos | salas con bifurcación de 3 bocas |
| 5 | Copas Altas | normal | 420×32 | 7 árboles gigantes | lianas | murciélago, volador | — | hueco vertical del tronco |
| 6 | Pantano Hundido | normal | 680×20 | doble nivel (alto / inundado) | corrientes + troncos | topo, saltarín, disparador | troncos | tubería hundida inclinada |
| 7 | Aserradero del Leñador | casa | 380×30 | edificio de 3 pisos | ascensores | guardián | prensas, péndulos-sierra | chimenea con 2 codos |
| 8 | Salto del Duende | normal | 340×32 | descenso | burbujas como freno | murciélago, volador | pinchos, desmoronables | cueva en L tras la cascada |
| 9 | Templo de los Tres Sellos | normal | 600×26 | templo con 3 cámaras | interruptores en orden | guardián, disparador | dardos, péndulos | 3 pasadizos de 12/26/40 |
| 10 | Fortaleza de Raíces | fortaleza | 640×30 | patio + 2 torres | ascensores + orbitales | guardián, lanzarrocas | prensas | cámara de llaves |
| 11 | Abismo de las Lianas | normal | 700×24 | islotes unidos por lianas | lianas encadenadas | volador, saltarín | péndulos | 2 cuevas colgantes |
| 12 | Claro de las Setas | normal | 480×32 | pinball vertical | setas diagonales | saltarín, lanzarrocas | desaparecen | tobogán interior |
| 13 | Mina Abandonada | cueva | 620×26 | 3 galerías con vías | carritos + desmoronables | pinchudo, murciélago, topo | prensas | galerías con 4 bocas |
| 14 | Colina de los Búhos | normal | 520×30 | espiral exterior + atajos | camino alto y bajo | murciélago, guardián, lanzarrocas | troncos desde la cima | túnel espiral |
| 15 | Río Bifurcado | normal | 780×22 | dos brazos de río | corrientes + balsas orbitales | caminante, disparador | troncos | 2 cruces bajo el agua |
| 16 | Bosque Nocturno | normal | 900×20 | persecución | roca perseguidora | volador, murciélago | dardos | 3 atajos de huida |
| 17 | Sendero de Espinas | normal | 560×28 | carrera de precisión | plataformas diminutas | pinchudo, saltarín, lanzarrocas | prensas, dardos | cámara cerrada |
| 18 | Árbol Milenario | normal | 400×32 | interior hueco por pisos | interruptores + ascensor | topo, guardián, murciélago | péndulos | raíces → copa |
| 19 | Camino de los Susurros | secreta | 640×26 | laberinto de rutas | interruptores encadenados | guardián | suelos que desaparecen | 3 bucles |
| 20 | Castillo del Guardián | castillo | 700×24 | castillo + arena del jefe | repaso de todas | mezcla + jefe | todas | llave del jefe |

---

# 4. FICHAS

Notas de lectura: las columnas son aproximadas (±5). «Fila» cuenta desde arriba (fila 0 = techo del nivel). Los tamaños de
túneles son «ancho × alto» de la sala en celdas.

---

## 1-1 · Sendero del Amanecer  *(tanda 1)*
**Función en el juego**: el primer nivel; enseña a moverse, a recoger y a rebotar. Es el único nivel sin trampas.

**Datos**: normal · 520 × 20 · 300 s · dificultad 1/5 · puntos de control en las columnas 205, 300 y 420.

**Tema visual**: claro de bosque al amanecer, niebla baja, luz dorada, flores. Fondo de árboles lejanos.

**Terreno y plataformas**
- **A. Claro de salida (cols 0-60)**: suelo casi plano (fila 15) con dos desniveles de 1 celda. Sin vacíos. Un arco de monedas y un
  tronco caído (plataforma de 6 celdas, fila 13) para practicar el primer salto.
- **B. Primeras colinas (60-130)**: cuatro colinas suaves (alturas fila 15 → 13 → 15 → 12). Al pie de un risco de 8 celdas
  (col 100) hay una **seta vertical**; arriba, una repisa de 7 celdas con 8 monedas y la **gema 1**.
- **C. Fosos del salto (130-205)**: tres fosos de 3, 4 y 5 celdas entre islas de suelo de 8-10 celdas, y un cuarto foso de
  **12 celdas** (col 185-197). Salvarlo exige la **seta diagonal** (col 183); la alternativa es una escalera de tres plataformas
  `=` flotantes (más lenta, 4 saltos). Punto de control en col 205.
- **D. Bosque alto (205-300)**: el suelo sube en tres escalones a la fila 9. Copas bajas de 5-7 celdas como plataformas
  opcionales con monedas. Aquí está la boca del túnel corto (col 225).
- **E. Colinas del alba (300-420)**: cinco colinas redondeadas (fila 12-14) con claros entre ellas; sin vacíos. Reloj +15 s (col 360).
  Puerta de piedra con cerradura (col 392). Punto de control en col 420.
- **F. Cima (420-520)**: rampa larga hasta la roca de la meta (fila 4, col 505). Dos setas encadenadas (col 440 diagonal, col 462
  vertical) lanzan directamente a la roca; la alternativa es subir por la rampa de escalones (60 columnas más).

**Recorrido principal**: A → B (puede ignorar la repisa) → C con la seta diagonal → D → E → F con las dos setas → meta.
**Rutas alternativas**: repisa alta de B (gema 1); escalera flotante de C (sin seta); rampa de escalones de F (sin setas).

**Túneles, cuevas y puertas**
- **Túnel corto A/B** (col 225 → col 262): sala recta de **22 × 5** celdas bajo la colina; entrada y salida a 37 columnas de
  distancia. En su centro hay un pedestal con la **llave**; 1 caminante patrulla la sala. Sin trampas.
- **Puerta de piedra** (col 392, cerradura, 1 llave): lleva a la **Casita de piedra**, sala de **14 × 6** con 20 monedas y la
  **gema 2**; se vuelve por la misma puerta.
- **Boca oculta** (col 118, detrás de un árbol decorativo): cámara de **12 × 4** bajo el árbol hueco con 10 monedas y la **gema 3**.

**Enemigos y ubicación**
- **Caminante** ×5: cols 40 (claro A), 85 y 112 (colinas B), 330 y 372 (colinas E). Patrullas de 6-9 celdas, sin trampas cerca.
- **Saltarín** ×3: col 160 (primera isla de C, enseña el salto), col 175 (isla 3), col 340 (colina E).
- No hay voladores, ni disparadores, ni enemigos nuevos (se introducen desde el 1-2).

**Trampas y obstáculos**: ninguna. Los únicos peligros son los fosos de C y los enemigos.

**Mecánica especial**: **setas** (vertical, diagonal y encadenadas); se enseñan en ese orden.

**Secretos y recompensas**
- **Gema 1**: repisa de la seta vertical (B). **Gema 2**: Casita de piedra (puerta con llave). **Gema 3**: cámara bajo el árbol hueco.
- **1 llave** (túnel corto). **1 reloj** +15 s. ~120 monedas repartidas en arcos.

**Diferencias concretas respecto a los demás**
- Es el único nivel **sin ninguna trampa**; los demás empiezan en 1-2 con corrientes y pinchos.
- Es el único con el recorrido **totalmente horizontal sobre colinas** (los demás son verticales, sin suelo, cuevas, etc.).
- Tiene solo **dos comportamientos enemigos** (patrulla y salto); a partir del 1-2 aparecen disparadores y voladores.
- Las setas son aquí el centro; en 1-12 se usan en cadena vertical, y en 1-5 solo como apoyo.

---

## 1-2 · Garganta de las Cascadas  *(tanda 1)*
**Función en el juego**: enseña a leer el agua (corrientes y burbujas) y a subir un nivel vertical.

**Datos**: normal · 360 × 32 · 330 s · dificultad 1-2/5 · puntos de control en cols 120 (fin de la terraza 1), 220 y 300.

**Tema visual**: garganta de roca húmeda con tres cascadas en cadena, arcoíris, helechos y musgo.

**Terreno y plataformas** (se asciende en **3 terrazas** unidas por cascadas; no hay suelo continuo)
- **Terraza 1 «Valle del pozo» (cols 0-125, suelo en fila 29)**: salida en col 4. Una **poza** (cols 40-56) con una **corriente a
  la derecha** de 16 × 3 celdas sobre tres piedras de apoyo; hay que cruzarla dejándose llevar o saltando entre piedras.
  Después, rocas que suben (filas 27 y 25) hasta el pie de la **cascada 1** (cols 110-125, muro de la fila 12 a la 29).
- **Subida 1**: **columna de burbujas** (cols 118-120, filas 17-28) que eleva **11 celdas** hasta la terraza 2; alternativa:
  tres **plataformas verticales móviles** (col 100, 106 y 112) de 6 celdas de recorrido, más lentas.
- **Terraza 2 «Repisas del arcoíris» (cols 60-230, filas 17-19)**: **zigzag** de repisas de 4-6 celdas (derecha, vuelta a la
  izquierda, derecha). Entre cols 150-160 hay una **corriente a la izquierda** de 10 × 4 que empuja hacia atrás; se cruza
  saltando por una repisa elevada. Punto de control en 220.
- **Subida 2**: **cascada 2** (cols 225-240). Ruta A: burbujas (cols 232-233, filas 8-16, eleva 9 celdas). Ruta B: dos plataformas
  verticales (cols 214 y 222) y un resorte.
- **Terraza 3 «Cresta» (cols 150-360, filas 4-8)**: repisas estrechas y un puente de piedra de 18 celdas; la meta está en col 352,
  fila 3. Último tramo: **cascada 3** con una corriente a la derecha de 14 celdas de ancho y dos plataformas móviles
  horizontales.

**Recorrido principal**: terraza 1 (poza) → burbujas 1 → zigzag de terraza 2 → burbujas 2 → cresta → meta.
**Rutas alternativas**: móviles verticales en lugar de burbujas (1 y 2); el pozo interior (ver túneles) salta la mitad del zigzag.

**Túneles, cuevas y puertas**
- **Pozo vertical** (boca en la terraza 1, col 90 → boca superior en la terraza 2, col 160): sala vertical de **6 × 16** celdas
  con **5 salientes alternos** izquierda/derecha; se sube saltando de saliente en saliente. A media altura hay un **nicho con
  la llave** y la **gema 1** (desvío de 4 celdas).
- **Cueva tras la cascada 1** (boca oculta tras el agua, col 124, fila 28): sala de **18 × 6** con tres charcos y un cofre con la
  **gema 2**.
- **Puerta con cerradura** (terraza 3, col 300): lleva al **mirador**, sala de **12 × 6** con la **gema 3** y un reloj +30 s.

**Enemigos y ubicación**
- **Voladores** ×6: en la **terraza 2**, entre cols 130 y 200, patrullando 8 celdas a alturas de fila 10-15; son la defensa de la ruta
  de las burbujas.
- **Disparadores** ×2: col 205 (fila 16, mira a la izquierda) y col 275 (fila 8), cubriendo la subida de la cascada 2.
- **Ningún enemigo de suelo** y ningún enemigo en la terraza 1 (enseña el agua sin presión).

**Trampas y obstáculos**: tiras de **pinchos** de 3-5 celdas al pie de cada cascada; las corrientes a favor y en contra.

**Mecánica especial**: **corrientes de agua y burbujas** + plataformas móviles verticales.

**Secretos y recompensas**
- **Gema 1**: nicho del pozo. **Gema 2**: cueva tras la cascada 1. **Gema 3**: mirador (puerta con llave).
- **1 llave** (nicho del pozo). **2 relojes** (+15 s en terraza 2, +30 s en el mirador). Monedas siguiendo las columnas de burbujas.

**Diferencias concretas respecto a los demás**
- Es el único nivel que se resuelve **subiendo en 3 terrazas** con agua; el 1-8 es el opuesto (bajada) y el 1-6 es horizontal.
- Primer nivel con **enemigos en el aire** y **disparadores**, y sin enemigos terrestres.
- Su túnel es **vertical, estrecho (6 celdas) y se sube con salientes**; el de 1-1 es horizontal y recto.
- Usa agua como **mecánica**; en 1-6 y 1-15 el agua es horizontal y arrastra, aquí eleva.

---

## 1-3 · Puente de los Mil Pasos  *(tanda 1)*
**Función en el juego**: enseña a no detenerse (puentes que caen) y a leer el ritmo de las plataformas que desaparecen.

**Datos**: normal · 820 × 22 · 360 s · dificultad 2/5 · puntos de control en cols 190, 380 y 560.

**Tema visual**: abismo con niebla azulada, puentes de cuerda y madera entre torres de roca, arcos de piedra, águilas lejanas.

**Terreno y plataformas** (**no hay suelo continuo**: 12 pilares de roca separados por precipicios)
- **Pilar 1 (cols 0-40, fila 14)**: salida; un descanso largo para ver el abismo.
- **Puente 1 (cols 40-72, 30 tablas, fila 14)**: se derrumba al pisarlo; se cruza corriendo. Un arco de piedra lo cubre.
- **Pilar 2 (72-100)** y **cadena de plataformas que desaparecen (100-160)**: 5 plataformas de 3 celdas con alturas
  14-13-12-13-14 y huecos de 3 celdas; el puente de aquí «ya se cayó» y obliga a usar el ritmo (≈1 s por plataforma).
- **Pilar 3 (160-190, fila 12)**: punto de control (col 190).
- **Puente 2 largo (190-232, 40 tablas)**: el mayor de la fase; desciende 2 celdas a mitad de camino.
- **Pilar 4 (232-270)** y **campo de pilares diminutos (270-340)**: cuatro pilares de 3 celdas separados por 6 celdas, con
  plataformas que se **desmoronan** como apoyo intermedio.
- **Pilar 5 (340-380)** con punto de control; **puente 3 (380-410, 30 tablas)** y **puente 4 (440-470)** separados por un pilar de 6
  celdas.
- **Pilares 6-11 (470-760)**: pilares de 6-14 celdas a alturas distintas (fila 10-16) con huecos de 8-26 celdas salvados por
  puentes, cadenas que desaparecen y una **liana de 8 celdas** (única, de repaso) sobre el hueco más ancho.
- **Pilar 12 (760-820)**: el altar de la meta (col 810).

**Recorrido principal**: arriba, por los puentes (más rápido, arriesgado porque caen).
**Rutas alternativas**: el **túnel largo** inferior que se salta los puentes 2 y 3; las pasarelas de madera bajas (fila 18) en el
tramo 470-760 que sustituyen a los puentes pero con plataformas que desaparecen.

**Túneles, cuevas y puertas**
- **Corredor bajo el abismo** (boca en el pilar 3, col 188, fila 20 → salida en el pilar 7, col 520): sala recta de **62 × 5**
  celdas, con **6 lanzadardos** alternados arriba y abajo cada 8-10 celdas; un **nicho lateral de 4 × 4** con la **llave** a la
  mitad. Atajo de unos 330 columnas.
- **Puerta con cerradura** (pilar 12, col 790): lleva al **balcón del altar**, sala de **10 × 5** con la **gema 3** y un reloj
  +30 s.
- **Cámara del arco** (sin túnel: se llega desde un puente que cae rápido, col 340, fila 4): plataforma de **8 × 3** sobre el arco
  de piedra con la **gema 2**.

**Enemigos y ubicación**
- **Murciélagos** ×4, **colgados de los arcos de piedra** sobre los puentes: cols 55 (puente 1), 150 (cadena), 215 (puente 2) y 330
  (campo de pilares). Pican cuando cruzas por debajo.
- **Voladores** ×3: junto al puente 2 (col 205 y 220) y en el último hueco (col 640).
- **Ningún enemigo terrestre** (el abismo y los puentes son el reto).

**Trampas y obstáculos**: **dardos** en el túnel inferior; puentes derrumbables; plataformas que desaparecen; el vacío.

**Mecánica especial**: **puentes que se derrumban** + **plataformas que desaparecen** (debutan aquí).

**Secretos y recompensas**
- **Gema 1**: flotando sobre la cadena de plataformas que desaparecen (hay que cogerla a tiempo). **Gema 2**: cámara del arco.
  **Gema 3**: balcón del altar (puerta con llave).
- **1 llave** (nicho del corredor). **2 relojes** (+15 s en pilar 3, +30 s en el balcón).

**Diferencias concretas respecto a los demás**
- Único nivel **sin ningún tramo de suelo continuo** (12 pilares y vacío).
- Único con **puentes derrumbables como protagonistas** (en 1-17 son pequeños; en 1-15 hay balsas).
- Su túnel es un **corredor largo recto de 62 celdas con dardos**, distinto del corto de 1-1 y del pozo de 1-2.
- Primer nivel con **murciélagos**; en 1-5 cuelgan de ramas y en 1-13 de techos de mina.

---

## 1-4 · Cueva de las Raíces  *(tanda 1 · cueva)*
**Función en el juego**: enseña a modificar el escenario (interruptores y bloques) y a elegir caminos dentro de una cueva.

**Datos**: cueva · 560 × 28 · 360 s · dificultad 2-3/5 · puntos de control en salas 2, 4 y 5. Techo continuo salvo en la salida.

**Tema visual**: cueva de raíces gigantes entrelazadas, hongos luminosos azules, gotas de agua, tonos marrones y verdes.

**Terreno y plataformas** (red de **6 salas** a distintas alturas, todas distintas)
- **Sala 1 «Vestíbulo» (36 × 11)**: salida; suelo con dos escalones y hongos decorativos. Sin enemigos.
- **Pasillo A (14 × 3)**: bajo y recto hasta la sala 2.
- **Sala 2 «Columnas» (44 × 14)**: cinco columnas de piedra de 2 celdas de ancho; los huecos entre columnas tienen **pinchos** en 3
  de ellos. Al fondo, el **interruptor 1** y una pared de **bloques conmutables `)`** (cerrada) que tapan el pasillo B.
- **Pasillo B (16 × 4)**: se abre al activar el interruptor 1.
- **Sala 3 «Embudo» (28 de ancho arriba → 6 abajo, 16 de profundidad)**: se baja por **escalones en espiral invertida**.
  Desde aquí hay **bifurcación de 3 bocas**: superior (a sala 5), media (a sala 4) e inferior (alameda de topos de 36 × 4 que
  sube de vuelta cerca de la sala 2).
- **Sala 4 «Cámara circular» (24 × 24)**: anillo de plataformas alrededor de un pilar central; el **interruptor 2** está en lo alto
  del pilar y la **llave** en el anillo superior (se abre con ese interruptor, que invierte plataformas del anillo).
- **Sala 5 «Galería inclinada» (60 × 8)**: pendiente que sube 8 celdas, con **bloques `(` que se alternan** con el interruptor 2.
  Al final, la **puerta con cerradura** al tesoro.
- **Sala 6 «Tesoro» (20 × 10)**: cofre, gema y reloj. Solo se abre con la puerta (llave).
- **Salida**: un **pozo vertical de 5 × 12** al final de la sala 5 sube a un claro del bosque exterior (cols 520-560) donde está la meta.

**Recorrido principal**: 1 → pasillo A → 2 (activar interruptor 1) → pasillo B → 3 → boca media → 4 → 5 → pozo → meta.
**Rutas alternativas**: boca superior del embudo (directo a la sala 5 pero con lanzarrocas), boca inferior (alameda de topos que
devuelve a la sala 2 y permite saltarse el interruptor 1 con otro recorrido).

**Túneles, cuevas y puertas**: todo el nivel es una cueva; las salas son la red de túneles. Dos mini-túneles de acceso a
nichos: uno de **8 × 3** bajo la sala 2 (monedas) y otro de **10 × 4** sobre la sala 4 (reloj).

**Enemigos y ubicación**
- **Topos** ×7: 3 en la sala 2 (cols 90, 104, 120, sobre arena entre columnas) y 4 en la **alameda** (uno cada 8 celdas, en fila).
- **Lanzarrocas** ×3: 1 arriba del embudo (en la boca superior) y 2 al inicio de la galería inclinada, disparando hacia abajo.
- **Ningún volador**, ningún caminante.

**Trampas y obstáculos**: pinchos en la sala 2; **bloques que se cierran y abren** (interruptores); la pendiente de la galería.

**Mecánica especial**: **interruptores y bloques conmutables** (debutan aquí; hay que dejar el estado correcto para abrir cada
paso; el interruptor solo se activa al pisarlo, no mientras te quedas).

**Secretos y recompensas**
- **Gema 1**: sobre una columna de la sala 2 (saltando de columna en columna). **Gema 2**: anillo alto de la sala 4. **Gema 3**:
  sala del tesoro (puerta con llave).
- **1 llave** (sala 4). **2 relojes**. **Habitación secreta**: la sala 6, o el nicho sobre la sala 4 (solo con interruptor 2 apagado).

**Diferencias concretas respecto a los demás**
- Único nivel con **techo continuo y salas de formas distintas** conectadas en red; el 1-13 también es cueva pero con vías y carritos.
- Primer nivel con **topos y lanzarrocas** (comportamiento: emerger y lanzar en parábola).
- Su **bifurcación de 3 bocas** y su **pozo vertical de salida** no aparecen en ningún otro.
- Los interruptores aquí son una **puerta/pasillo**; en 1-9 se encadenan en un orden y en 1-18 se combinan con un ascensor.

---

## 1-5 · Copas Altas  *(tanda 1 · salida secreta → casa 1-7)*
**Función en el juego**: enseña a balancearse con las lianas, con un tramo guiado de setas.

**Datos**: normal · 420 × 32 · 330 s · dificultad 3/5 · puntos de control en las copas de los árboles 3 y 5. Salida secreta.

**Tema visual**: copas de árboles gigantes sobre un mar de nubes al atardecer; cielo naranja y violeta; pájaros.

**Terreno y plataformas** (7 árboles gigantes; no hay suelo continuo)
- **Suelo del bosque (cols 0-40, fila 30)**: salida y un tronco caído; el único suelo del nivel además de la meta.
- **Árboles** (troncos de 4-6 celdas de ancho) en las cols ≈ 30, 90, 150, 215, 275, 335 y 395. Sus **copas** de 8-14 celdas están
  a alturas distintas: filas 22, 16, 24, 10, 18, 8 y 12. Ramas gruesas (6-12 celdas) salen de los troncos a otras alturas.
- Entre copas hay vacíos de **10 a 22 celdas**, imposibles de saltar: hay que usar **lianas** (colgadas de ramas altas, 8-10
  celdas) o ramas intermedias.
- **Hueco 1 (árbol 1 → 2, 20 celdas)**: una liana de 9 celdas (primera, sola, para aprender).
- **Hueco 2 (árbol 2 → 3, 18 celdas)**: una **seta vertical** en una rama que lanza a la copa del árbol 3 (fila 24 → 16).
- **Hueco 3 (árbol 3 → 4, 22 celdas)**: **dos lianas encadenadas** (hay que soltar y enganchar la segunda).
- **Huecos 4-6**: liana larga + rama intermedia; los dos últimos tramos suben a las copas altas (fila 8 y 12).
- **Último árbol (col 395)**: la meta (fila 12).

**Recorrido principal (alto)**: lianas encadenadas, copas más altas; más rápido pero exige el timing de las lianas.
**Ruta baja**: ramas gruesas a fila 26 con **tres saltos largos de 5 celdas** que evitan las lianas (más lento y con murciélagos).

**Túneles, cuevas y puertas**
- **Hueco del tronco del árbol 4** (boca baja col 218, fila 27 → boca alta col 218, fila 17): sala vertical de **5 × 8** con
  **salientes alternos** que se suben saltando; en su cima hay una **puerta con cerradura** (col 222, fila 14) que lleva al
  **nido del pájaro**, sala de **10 × 5** con la **gema 3** y monedas.
- No hay otros túneles (el nivel es abierto).

**Enemigos y ubicación**
- **Murciélagos** ×4: colgados **bajo ramas gruesas altas**, cols 120, 180, 300 y 360; pican al pasar bajo ellos o al aterrizar
  de una liana.
- **Voladores** ×3: cruzan los huecos 3, 5 y 6 (cols 190, 310, 350) a media altura; no se pueden evitar, hay que cronometrar.
- **Sin enemigos terrestres**.

**Trampas y obstáculos**: no hay trampas; el reto es el timing de las lianas y el vacío.

**Mecánica especial**: **lianas** (balanceo real; se agarran en el aire, SALTO suelta con la velocidad del balanceo), con una
seta de apoyo. Debutan aquí.

**Secretos y recompensas**
- **Gema 1**: sobre la rama alta del árbol 2 (alcanzada con la seta vertical). **Gema 2**: en una liana de repaso (hay que
  balancearse más lejos de la ruta). **Gema 3**: nido del pájaro (puerta con llave).
- **Llave**: en un nido de la ruta baja (col 245, fila 27).
- **Salida secreta**: una rama por encima de la meta (col 408, fila 3), alcanzable con una liana larga de 12 celdas desde la copa
  del árbol 7; lleva a la **casa 1-7**.

**Diferencias concretas respecto a los demás**
- Único nivel con **7 árboles como único apoyo** (casi todo el recorrido sin suelo, en altura 32).
- Los enemigos son **solo aéreos** como en 1-2, pero aquí cuelgan de ramas y el reto principal es el balanceo, no el agua.
- Las lianas son la **mecánica nueva**; en 1-11 aparecen encadenadas en un abismo horizontal, y aquí se combinan con una seta
  y con subidas verticales.
- Su túnel es **un hueco de tronco de 5 × 8**, el más pequeño de la fase.

---

## 1-6 · Pantano Hundido  *(tanda 2)*
**Función en el juego**: enseña a elegir entre un camino seguro y otro rápido, mezclando corrientes laterales con troncos.

**Datos**: normal · 680 × 20 · 380 s · dificultad 3/5 · puntos de control en cols 170, 340 y 510.

**Tema visual**: pantano verde oscuro, nenúfares, niebla, luciérnagas, árboles retorcidos.

**Terreno y plataformas** (dos capas paralelas)
- **Capa alta (filas 8-12)**: troncos y plataformas de 6-9 celdas, con huecos de 3-4 celdas, a lo largo de todo el nivel.
- **Capa baja (filas 15-18)**: un lecho inundado con **corrientes laterales** de 20-40 celdas (derecha, izquierda, derecha) y
  piedras de apoyo.
- **Desniveles de transición** entre capas cada ~80 columnas (rampas y escalones).
- **Troncos rodantes**: tres tolvas en la capa alta que sueltan troncos que bajan por las rampas hacia la capa baja.

**Recorrido principal**: capa alta (más segura pero con huecos). **Ruta alternativa**: capa baja (más corta, con la corriente a
favor en dos tramos y en contra en uno).

**Túneles, cuevas y puertas**
- **Tubería hundida** (boca en capa baja col 255, fila 17 → salida col 415): túnel **horizontal inclinado de 30 × 4** (baja 3 celdas
  y sube 3) por debajo del lecho; con una **corriente interior** que empuja hacia delante y una llave a mitad.
- **Puerta con cerradura** (col 600): lleva a la **choza flotante** (12 × 5) con el cofre y la **gema 3**.

**Enemigos y ubicación**
- **Topos** ×5: emergen del barro en la capa baja (cols 120, 150, 280, 330, 450).
- **Saltarines** ×4 (ranas): en la capa alta, cols 90, 210, 360, 480.
- **Disparadores** ×2: sobre cañas en la capa alta (cols 300 y 550).

**Trampas y obstáculos**: **troncos rodantes** (tolvas en cols 130, 310, 500); corrientes que arrastran hacia huecos.

**Mecánica especial**: **corrientes + troncos** combinados.

**Secretos y recompensas**: **gema 1** en una piedra solitaria de la capa baja; **gema 2** en la capa alta, sobre un tronco de
difícil acceso; **gema 3** en la choza. **1 llave**, **1 reloj**. Habitación secreta: la choza flotante.

**Diferencias concretas respecto a los demás**: único nivel con **dos capas paralelas**; es el único con **tubería hundida
inclinada** y el único con **topos como mayoría de enemigos en el agua**. El agua aquí **arrastra**, mientras que en 1-2 eleva
y en 1-15 divide el recorrido.

---

## 1-7 · Aserradero del Leñador  *(tanda 2 · casa / bonus)*
**Función en el juego**: sala de recompensas con mecanismos; difícil de ver y fácil de jugar.

**Datos**: casa · 380 × 30 · 420 s · dificultad 2/5 (bonus) · puntos de control en el piso 2 y el piso 3.

**Tema visual**: interior de madera, engranajes, sierras decorativas, vigas, polvo de serrín.

**Terreno y plataformas** (edificio de 3 pisos)
- **Piso 1 «Patio de troncos» (filas 20-28)**: cinta de troncos que ruedan hacia la izquierda; plataformas y pilas de troncos.
- **Piso 2 «Sierra mayor» (filas 11-19)**: pasillo con **4 prensas** y **2 sierras (péndulos)**.
- **Piso 3 «Despacho» (filas 2-10)**: sala del tesoro con un **interruptor** que abre la bóveda.
- Unión: **2 ascensores** (cols 95 y 260) entre pisos 1-2-3.

**Recorrido principal**: piso 1 → ascensor 1 → piso 2 → ascensor 2 → piso 3.
**Rutas alternativas**: piso medio o piso alto; llegan al mismo despacho.

**Túneles, cuevas y puertas**
- **Chimenea de la fábrica**: túnel de **18 celdas con dos codos** que conecta el piso 1 con el 3 (atajo).
- **Puerta del despacho** (cerradura): sala de **10 × 6** con la **gema 3**.
- **Sótano de la sierra** (boca oculta tras la pila de troncos): **12 × 4**, con la **gema 2**.

**Enemigos y ubicación**: **guardianes** ×4 (2 en el piso 1 al pie de los ascensores, 2 en el piso 2 flanqueando la sierra). No hay
enemigos voladores.

**Trampas y obstáculos**: prensas del piso 2, sierras, troncos de la cinta.

**Mecánica especial**: **ascensores** con prensas.

**Secretos y recompensas**: bonus de monedas (≥150), **3 gemas** (la 1 en el piso 2 tras una sierra), **1 llave**, **2 relojes**.

**Diferencias concretas respecto a los demás**: único nivel **interior de 3 pisos**; los guardianes son aquí el único enemigo;
es de **bonus** y el más fácil entre los de la fase.

---

## 1-8 · Salto del Duende  *(tanda 2)*
**Función en el juego**: es el único descenso; enseña a usar las burbujas como freno y a caer con control.

**Datos**: normal · 340 × 32 · 300 s · dificultad 3/5 · puntos de control en las filas 12 y 21 de la bajada.

**Tema visual**: cascada enorme que cae a una poza con niebla; rocas mojadas; verdes y azules fríos; arcoíris al fondo.

**Terreno y plataformas** (se **baja** de la fila 4 a la 29, en 4 tramos)
- **Cima (cols 0-40, fila 4)**: salida sobre el borde de la cascada; una roca grande para ver el vacío.
- **Tramo 1 (filas 4-11, cols 40-110)**: repisas de 4-6 celdas en escalera descendente hacia la derecha; el hueco entre repisas es
  de 5 celdas de caída.
- **Tramo 2 (filas 11-18, cols 110-190)**: **caída guiada** entre dos paredes de 14 celdas de separación; hay **dos columnas de
  burbujas** (cols 140 y 165) que frenan la caída y permiten escoger dónde aterrizar; abajo, repisas pequeñas de 3 celdas.
- **Tramo 3 (filas 18-24, cols 190-270)**: **plataformas desmoronables** en zigzag (se rompen 0,6 s después de pisarlas); si
  se falla, se cae al tramo 4 con daño de pinchos.
- **Tramo 4 (filas 24-29, cols 270-340)**: poza final con piedras y un **puente de tronco**; la meta en col 330.

**Recorrido principal**: caída controlada con las burbujas del tramo 2 (rápido). **Ruta alternativa**: escalera de repisas de la
pared derecha (más lenta, con murciélagos).

**Túneles, cuevas y puertas**
- **Cueva tras la cascada** (boca oculta en la pared, col 120, fila 14): **3 salas en L** de **16 × 6**, **12 × 8** y **10 × 5**
  unidas por pasillos de 6 celdas; contiene la **llave** y la **gema 2**; sale a la repisa del tramo 3.
- **Puerta con cerradura** (poza, col 300): lleva a la **cámara bajo la poza**, de **14 × 5**, con la **gema 3**.

**Enemigos y ubicación**
- **Murciélagos** ×4: uno por tramo, colgados de salientes de roca (cols 80, 150, 230, 300), siempre sobre la ruta alternativa.
- **Voladores** ×3: en las caídas del tramo 2 (cols 130, 160, 180), obligan a elegir columna de burbujas.
- **Ningún enemigo terrestre** salvo el de la meta.

**Trampas y obstáculos**: **pinchos** al pie de cada tramo; plataformas desmoronables del tramo 3; el reloj.

**Mecánica especial**: **burbujas como freno** (no como ascenso).

**Secretos y recompensas**: **gema 1** en una repisa lateral solo alcanzable desde una burbuja; **gema 2** en la cueva; **gema 3** bajo
la poza. **1 llave**, **1 reloj +15 s**. Monedas que marcan la trayectoria correcta de caída.

**Diferencias concretas respecto a los demás**: único nivel donde se **desciende**; las burbujas **frenan** (en 1-2 elevan); no hay
ningún tramo horizontal largo; su cueva es una **L de tres salas** distinta del pozo de 1-2.

---

## 1-9 · Templo de los Tres Sellos  *(tanda 2 · salida secreta → 1-15)*
**Función en el juego**: puzle de ruinas; el jugador elige el orden de tres sellos.

**Datos**: normal · 600 × 26 · 400 s · dificultad 3-4/5 · puntos de control tras cada sello.

**Tema visual**: ruinas de piedra cubiertas de hiedra, columnas rotas, runas azules brillantes, luz de rendija.

**Terreno y plataformas**
- **Antesala (cols 0-110, fila 20)**: escalinatas de piedra de 1 celda y columnas; sin vacíos.
- **Patio central (cols 110-300, filas 14-22)**: terreno escalonado con cuatro puertas hacia las cámaras.
- **Sala Norte (cols 110-200, filas 2-12)**: pasillos estrechos (3 de alto) con nichos; plataformas de piedra.
- **Sala Este (cols 300-400, filas 12-22)**: sala de **suelo alto con 3 péndulos** y plataformas conmutables.
- **Sala Oeste (cols 20-110, filas 2-12)**: plataformas conmutables; alberga el tercer sello.
- **Cámara del ídolo (cols 520-600)**: se abre con los tres sellos; el ídolo central tapa un nicho secreto.

**Recorrido principal**: patio → las tres cámaras en el orden que se quiera (cada una pone un sello) → cámara del ídolo → meta.
**Rutas alternativas**: dos cámaras son opcionales si se toma el pasadizo secreto; el patio tiene un recorrido alto (por columnas)
y otro bajo.

**Túneles, cuevas y puertas**
- **3 pasadizos secretos** de **12, 26 y 40 celdas**: uno recto (12 × 3), uno en pendiente con dardos (26 × 4) y uno con codo y puerta
  con cerradura (40 × 4). Conectan antesala–Sala Norte, patio–Sala Este y Sala Oeste–cámara del ídolo.
- **Nicho del ídolo** (boca oculta tras el ídolo): sala de **8 × 4** con la **salida secreta**.

**Enemigos y ubicación**
- **Guardianes** ×3: uno en la antesala (col 70), dos en el patio (cols 160 y 240), vigilando las puertas de las cámaras.
- **Disparadores** ×3: en nichos de la Sala Norte (cols 130, 160, 190), mirando al pasillo.

**Trampas y obstáculos**: **dardos** cruzados en la Sala Norte; **péndulos** en la Sala Este; bloques conmutables.

**Mecánica especial**: **interruptores en orden libre** (grupo 1 y 2 más la llave como tercer sello).

**Secretos y recompensas**: 3 gemas (1 por cámara), **1 llave** (sello 3), **salida secreta** en el nicho del ídolo hacia 1-15, 1 reloj +15 s.

**Diferencias concretas respecto a los demás**: único nivel con **tres cámaras en orden libre**; único con **dardos y péndulos en
salas distintas**; sus 3 túneles tienen **longitudes distintas** (12, 26, 40) y trampas distintas.

---

## 1-10 · Fortaleza de Raíces  *(tanda 2 · fortaleza)*
**Función en el juego**: primer nivel de mecanismos; hay que recoger dos llaves.

**Datos**: fortaleza · 640 × 30 · 420 s · dificultad 4/5 · puntos de control al pie de cada torre y en el patio.

**Tema visual**: fortaleza de raíces gruesas entrelazadas con piedra; banderas verdes; luz de antorcha.

**Terreno y plataformas**
- **Entrada (cols 0-60, fila 26)**: muralla exterior con puerta; suelo plano.
- **Torre oeste (cols 60-150, filas 2-28)**: interior vertical de 5 pisos; se sube con **2 ascensores** (cols 80 y 120) y
  plataformas fijas; en la cima, la **llave 1**.
- **Patio central (cols 150-480, fila 24)**: suelo largo con un **puente levadizo** (cols 260-300) bajo dos prensas.
- **Torre este (cols 480-570, filas 2-28)**: se sube con **2 plataformas orbitales** y un ascensor; en la cima, la **llave 2**.
- **Muralla final (cols 570-640)**: puerta doble de dos llaves y la meta.

**Recorrido principal**: entrada → torre oeste → patio → torre este → puerta doble → meta.
**Rutas alternativas**: las almenas (fila 8) permiten saltarse parte del patio; los pasadizos entre torres.

**Túneles, cuevas y puertas**
- **Cámara de llaves** (puerta doble con 2 cerraduras, col 600): sala de **12 × 6** con la meta.
- **Pasadizo entre torres** (boca en la torre oeste, col 140, fila 25 → torre este, col 485): corredor de **26 × 4** con 2 prensas.
- **Armería** (boca oculta en la muralla): **10 × 4**, con la **gema 2**.

**Enemigos y ubicación**
- **Guardianes** ×5: 2 en la entrada, 2 en el patio flanqueando el puente levadizo, 1 en la cima de la torre este.
- **Lanzarrocas** ×3: en parapetos sobre el patio (cols 190, 340, 440).

**Trampas y obstáculos**: **prensas** (puente levadizo y pasadizo); huecos en las murallas.

**Mecánica especial**: **ascensores y orbitales** en vertical.

**Secretos y recompensas**: 3 gemas (1 en cada torre, 1 en la armería), **2 llaves**, 1 reloj +30 s.

**Diferencias concretas respecto a los demás**: único con **patio y dos torres de mecánica distinta**; el primero con **2 llaves
obligatorias**; su túnel es un **pasadizo con prensas entre torres**.

---

## 1-11 · Abismo de las Lianas  *(tanda 3)*
**Función en el juego**: repaso exigente de las lianas; ahora encadenadas.

**Datos**: normal · 700 × 24 · 340 s · dificultad 3-4/5 · puntos de control en cols 200, 400 y 560.

**Tema visual**: selva alta con raíces colgantes sobre un abismo oscuro; neblina verdosa; luciérnagas.

**Terreno y plataformas**
- **14 islotes** de 3-5 celdas, a alturas fila 10-18, separados por **12 a 24 celdas**. El primero es la salida (cols 0-20) y el
  último la meta (cols 680-700).
- **Lianas** colgadas de raíces en techos de piedra (filas 2-4): 2 o 3 por hueco, de 8-10 celdas, escalonadas para pasar de una a
  la siguiente soltando y enganchando.
- **Péndulos** entre liana y liana (6 en total), con la cuchilla a la altura de la cabeza al pasar.

**Recorrido principal**: la **cadena alta** de lianas (rápida). **Ruta alternativa**: la **cadena baja**, con huecos más cortos pero
sin ayuda de las raíces superiores (más saltos).

**Túneles, cuevas y puertas**
- **2 cuevas colgantes** bajo los islotes 4 y 9: de **14 × 6** (con la llave) y **10 × 8** (con la gema 3); se entra por una boca en la
  cara inferior del islote (T con SALTO) y se sale por otra boca en la cara superior.

**Enemigos y ubicación**
- **Voladores** ×5: en los huecos largos de la cadena alta (cols 120, 250, 380, 520, 620), entre dos lianas.
- **Saltarines** ×3: sobre los islotes más grandes (cols 150, 330, 450).

**Trampas y obstáculos**: **péndulos** entre lianas; el vacío.

**Mecánica especial**: **lianas encadenadas** con péndulos (a diferencia del 1-5, aquí se encadenan en un solo plano horizontal).

**Secretos y recompensas**: 3 gemas, **1 llave**, **3 vidas** en una plataforma que solo se alcanza con una liana alta.

**Diferencias concretas respecto a los demás**: nivel **horizontal sin suelo** con lianas (1-5 es vertical con árboles); sus cuevas son
**colgantes**, sin conexión interior entre sí; usa **péndulos** donde 1-5 no tenía trampas.

---

## 1-12 · Claro de las Setas  *(tanda 3)*
**Función en el juego**: pinball vertical de rebotes con precisión.

**Datos**: normal · 480 × 32 · 330 s · dificultad 3/5 · puntos de control en cols 160 y 320.

**Tema visual**: claro con setas gigantes, esporas luminosas flotantes, colores rojos y morados.

**Terreno y plataformas**
- **3 carriles de 160 columnas** (cols 0-160, 160-320, 320-480). Cada uno es una torre de setas y repisas que se sube **rebotando**:
  setas verticales (7 celdas) entre repisas escalonadas y setas diagonales que lanzan hasta el carril siguiente.
- Entre carriles hay **vacíos** de 12-14 celdas que se cruzan con la seta diagonal.
- **Plataformas que desaparecen** capan algunos tramos (3 en cada carril) para obligar a usar el ritmo.

**Recorrido principal**: carril 1 → diagonal → carril 2 → diagonal → carril 3 → meta alta (fila 3).
**Rutas alternativas**: en cada carril hay un camino de plataformas sin setas (más lento).

**Túneles, cuevas y puertas**
- **Tobogán interior**: túnel en **espiral descendente de 8 × 20** que lleva de la copa del carril 2 al pie del carril 3 (atajo).
- **Gruta bajo la seta mayor** (boca oculta): **12 × 5**, con la gema 3.
- **Puerta con cerradura** (carril 3): sala de **10 × 5** con la llave de recompensa de monedas.

**Enemigos y ubicación**: **saltarines** ×5 (2 por carril 1 y 2, 1 en el 3), **lanzarrocas** ×3 en las copas de las setas más altas
(cols 110, 240, 400).

**Trampas y obstáculos**: plataformas que desaparecen; el vacío entre carriles.

**Mecánica especial**: **setas diagonales encadenadas**.

**Secretos y recompensas**: 3 gemas (1 por carril), 1 llave, 1 reloj.

**Diferencias concretas respecto a los demás**: **vertical por rebotes**; sin lianas ni agua; su túnel es un **tobogán en espiral**.

---

## 1-13 · Mina Abandonada  *(tanda 3 · cueva · salida secreta → 1-19)*
**Función en el juego**: cueva con vías, carritos y vigas; da la salida secreta al nivel 1-19.

**Datos**: cueva · 620 × 26 · 380 s · dificultad 4/5 · puntos de control en cada galería.

**Tema visual**: mina de madera y raíles, linternas amarillas, polvo, vagonetas oxidadas.

**Terreno y plataformas**
- **3 galerías** horizontales: superior (fila 8), media (fila 15) e inferior (fila 21), de 160 a 200 celdas cada una.
- **Pozos verticales** de 6-8 celdas entre galerías, con **plataformas que se desmoronan** a modo de escalera.
- **Vías** con un **carrito minero** (V) en la galería media (cols 200-380): avanza solo; izquierda frena y derecha acelera.
- Techo continuo y soportes de madera.

**Recorrido principal**: galería media con el carrito. **Rutas alternativas**: superior (a pie, con murciélagos) o inferior
(desmoronables y topos).

**Túneles, cuevas y puertas**
- **Bifurcación de 4 bocas** al final de la galería media (a la superior, la inferior, a un nicho y a la sala de dinamita).
- **Pozo de ascensor roto** (6 × 14): se sube saltando entre vigas desmoronables.
- **Sala de dinamita** (boca oculta tras una bifurcación): **14 × 6** con la **salida secreta** a 1-19.

**Enemigos y ubicación**: **pinchudos** ×4 sobre las vías (patrullan; no se pisan), **murciélagos** ×3 en techos de la galería
superior, **topos** ×3 en la inferior.

**Trampas y obstáculos**: **prensas** en dos túneles de conexión; vías rotas; desmoronables.

**Mecánica especial**: **carrito minero** y **plataformas que se desmoronan**.

**Secretos y recompensas**: 3 gemas, 1 llave, **salida secreta** a 1-19, 1 reloj.

**Diferencias concretas respecto a los demás**: único con **carrito y vías**; es cueva como el 1-4 pero **abierta en galerías** con vías
y sin interruptores.

---

## 1-14 · Colina de los Búhos  *(tanda 3)*
**Función en el juego**: recorrido en espiral con atajos; dos llaves.

**Datos**: normal · 520 × 30 · 380 s · dificultad 3-4/5 · puntos de control en cada vuelta.

**Tema visual**: colina rocosa con estatuas de búho de piedra y ojos luminosos; crepúsculo.

**Terreno y plataformas**
- Una **colina central** de 40 celdas de ancho; alrededor, un **camino en espiral de 3 vueltas** (filas 26 → 17 → 8) con ramas
  de 8-12 celdas y escalones.
- **Camino bajo** (opcional): atajo por el interior de la colina con rocas rodantes.
- **Cima (cols 240-290, fila 4)**: mirador con vistas.

**Recorrido principal**: espiral exterior. **Rutas alternativas**: atajos interiores que cortan una vuelta (con troncos rodantes).

**Túneles, cuevas y puertas**
- **Túnel espiral interior** de **40 celdas** (4 de alto), con curvas que suben 6 filas; une la vuelta 1 con la 3.
- **Mirador de la cima** (puerta con cerradura): sala de **10 × 5** con la gema 3.

**Enemigos y ubicación**: **murciélagos** ×3 en salientes (cols 100, 260, 420), **guardianes** ×2 en curvas cerradas (cols 160 y
380), **lanzarrocas** ×1 en la cima.

**Trampas y obstáculos**: **troncos rodantes** (tolva en la cima, col 270) que bajan por las rampas de la espiral.

**Mecánica especial**: **camino alto y bajo** alrededor de una colina.

**Secretos y recompensas**: 3 gemas, **2 llaves** (una exterior, una interior), 1 reloj.

**Diferencias concretas respecto a los demás**: única **espiral exterior**; combina troncos desde la cima con guardianes y lanzarrocas;
su túnel es una **espiral de 40 celdas**.

---

## 1-15 · Río Bifurcado  *(tanda 3)*
**Función en el juego**: dos recorridos paralelos que se separan y se reúnen.

**Datos**: normal · 780 × 22 · 360 s · dificultad 4/5 · puntos de control en las bifurcaciones y en la unión.

**Tema visual**: río azul turquesa que se parte en dos brazos y vuelve a unirse; juncos y piedras.

**Terreno y plataformas**
- **Tramo común inicial (cols 0-180)**: orilla y plataformas hasta la **bifurcación**.
- **Brazo norte (cols 180-520, filas 4-12)**: recorrido **aéreo** con **balsas orbitales** y ramas.
- **Brazo sur (cols 180-520, filas 14-20)**: **a ras de agua**, con **corrientes** y piedras.
- **Isla central (col 350)**: cruce de ambos brazos.
- **Tramo común final (cols 520-780)** hasta la meta.

**Recorrido principal**: cualquiera de los brazos; **ruta alternativa**: pasar de un brazo a otro por la isla.

**Túneles, cuevas y puertas**: **2 cruces bajo el agua** de **14 y 22 celdas** que unen los brazos; **puerta con cerradura** en la
isla (gema 3).

**Enemigos y ubicación**: **caminantes** ×4 en el tramo común (cols 60, 120, 600, 700), **disparadores** ×3 en las orillas del brazo sur.

**Trampas y obstáculos**: **troncos** que bajan por el brazo sur; corrientes.

**Mecánica especial**: **corrientes + balsas orbitales**.

**Secretos y recompensas**: 3 gemas, 1 llave, **isla central** como secreto.

**Diferencias concretas respecto a los demás**: el río se **divide en dos recorridos de estructura distinta**; el 1-6 tiene dos
capas, aquí son dos brazos paralelos.

---

## 1-16 · Bosque Nocturno  *(tanda 4)*
**Función en el juego**: el único nivel de persecución; pide ritmo continuo y decisiones rápidas.

**Datos**: normal · 900 × 20 · 300 s · dificultad 4/5 · puntos de control en cols 230, 450 y 680 (la roca se reinicia en cada uno).

**Tema visual**: bosque de noche, luna grande, luciérnagas, siluetas negras de árboles; una roca con pinchos gigante que ruge
detrás de ti.

**Terreno y plataformas** (carrera larga en **4 tramos**; el suelo es continuo salvo los fosos)
- **Tramo 1 «Salida» (cols 0-230)**: suelo llano con troncos caídos de 1 celda (hay que saltarlos) y tres fosos de 3 celdas. La roca
  aparece en col 60 y empieza lenta (62 px/s).
- **Tramo 2 «Raíces» (230-450)**: suelo irregular con subidas y bajadas de 2 celdas; **setas** que ayudan a saltar fosos de 6-8
  celdas; la roca acelera.
- **Tramo 3 «Claros» (450-680)**: **dos caminos** paralelos separados por un seto: el de arriba (plataformas de 6 celdas, fila 10)
  y el de abajo (suelo, fila 15, con troncos y fosos). Hay dos atajos de huida.
- **Tramo 4 «Estampida» (680-900)**: pendiente descendente larga, fosos de 4-5 celdas y un último muro de 3 celdas antes de la meta
  (col 890). La roca va a máxima velocidad (112 px/s).

**Recorrido principal**: seguir el suelo sin detenerse. **Rutas alternativas**: en el tramo 3, el camino alto (más corto, más
saltos) o el bajo (más largo, más seguro); los **atajos de huida** (ver túneles) permiten sacar ventaja.

**Túneles, cuevas y puertas**
- **3 atajos de huida** de **10 × 3**, **13 × 3** y **16 × 4**, cada uno con su forma: recto, con un pequeño escalón central y con
  curva ascendente. Los dos primeros tienen dardos a media altura; el tercero acaba en el **refugio** (sala de **8 × 4**) con 2
  vidas.
- **Puerta con cerradura** (col 600): atajo directo al tramo 4 con la llave (que está en el atajo 2).

**Enemigos y ubicación**
- **Voladores** ×4: cruzan delante del jugador en los tramos 2 y 3 (cols 280, 340, 520, 600) a la altura de la cabeza, obligando a
  saltar o agacharse en el momento justo.
- **Murciélagos** ×3: colgados de ramas bajas del tramo 3 (cols 470, 540, 640), sobre el camino bajo.
- No hay enemigos terrestres: el peligro está detrás.

**Trampas y obstáculos**: **dardos** en cada tramo (cols 150, 260, 520, 700); troncos caídos y fosos; la roca que persigue.

**Mecánica especial**: **perseguidor** (la roca acelera poco a poco; si te alcanza te quita un corazón y se frena un instante).

**Secretos y recompensas**: 3 gemas (la 1 en una repisa alta del tramo 2, la 2 en el camino alto del tramo 3, la 3 en el refugio),
**1 llave**, 2 relojes +15 s (para compensar la presión).

**Diferencias concretas respecto a los demás**: único con **perseguidor**; el más largo (900) y el más bajo (20 filas); sin enemigos
terrestres; los túneles son **atajos de huida cortos** y no salas.

---

## 1-17 · Sendero de Espinas  *(tanda 4)*
**Función en el juego**: prueba de precisión; el más exigente técnicamente de la fase.

**Datos**: normal · 560 × 28 · 330 s · dificultad 4-5/5 · puntos de control en cols 160, 330 y 460.

**Tema visual**: matorral de espinas rojas y moradas, cielo rojizo de atardecer, hojas secas.

**Terreno y plataformas**
- **Orilla de salida (cols 0-30)** y **orilla de meta (cols 530-560)**: únicos suelos firmes. Entre ellos, un **mar de espinas**
  (filas 24-27) que mata al tocarlo.
- **Plataformas de 1 y 2 celdas** (80 en total) en zigzag vertical entre las filas 10 y 22; los saltos van de 3 a 5 celdas.
- **Tres islas de descanso** de 6 celdas (cols 160, 330 y 460) con punto de control.
- **Tramos**: 1) saltos fáciles de 3 celdas; 2) saltos de 4 con plataformas que **desaparecen**; 3) saltos largos con **dardos** cruzados;
  4) plataformas estrechas bajo **prensas**.

**Recorrido principal**: la ruta media, de precisión. **Rutas alternativas**: **ruta alta** (más corta, saltos de 5 celdas, sin
ayudas) y **ruta baja** (más larga, saltos de 3, con más enemigos).

**Túneles, cuevas y puertas**
- **Cámara cerrada** de **9 × 6**, entrada por una puerta con cerradura en la isla 2: contiene la **llave** del final y la gema 3; no
  se puede atravesar sin gastar la llave inicial (la llave inicial está en la isla 1).
- No hay túneles largos: el nivel es de campo abierto.

**Enemigos y ubicación**
- **Pinchudos** ×4: sobre las islas de descanso (no se pisan; hay que esquivarlos antes de cada punto de control).
- **Saltarines** ×3: en el tramo 1 (cols 60, 90, 120), en plataformas largas.
- **Lanzarrocas** ×3: en las orillas y en las islas 2 y 3, disparando a las plataformas intermedias.

**Trampas y obstáculos**: **prensas** (2 en el tramo 4, cols 400 y 430); **dardos** (tramo 3, 4 lanzadardos alternados); plataformas
que desaparecen (tramo 2); el mar de espinas.

**Mecánica especial**: **precisión** (plataformas diminutas, ritmo de las que desaparecen y dardos).

**Secretos y recompensas**: 3 gemas (1 en una plataforma aislada en la ruta alta, 2 en el tramo 3, 3 en la cámara cerrada),
**1 llave**, **nido de espinas** (habitación secreta con 3 vidas; solo accesible por la ruta baja).

**Diferencias concretas respecto a los demás**: el más **difícil**; sin suelo continuo y **sin puentes ni lianas** (todo es precisión
sobre plataformas pequeñas); es el único con **un mar de espinas** como terreno.

---

## 1-18 · Árbol Milenario  *(tanda 4)*
**Función en el juego**: interior vertical con pisos, ascensor e interruptores.

**Datos**: normal · 400 × 32 · 360 s · dificultad 4-5/5 · puntos de control en los pisos 2 y 4.

**Tema visual**: interior de un árbol hueco gigante, paredes de corteza, hongos luminosos y luciérnagas; luz que baja por una
abertura en lo alto.

**Terreno y plataformas**
- **Cinco pisos** (filas 28, 22, 16, 10, 4) que ocupan casi todo el ancho (400 columnas) pero **alternan el lado de la abertura**:
  el piso 1 se recorre de izquierda a derecha, el 2 de derecha a izquierda, etc. (una «espiral» plana).
- **Conexión entre pisos**: **ascensores** (cols 380, 20 y 380 alternos) y **rampas**; algunos tramos están cerrados por **bloques
  conmutables** que se abren con un interruptor del piso anterior.
- **Ramas exteriores** (ruta alternativa): una repisa por la pared derecha, fuera del tronco, con vacíos.
- **Copa (fila 2)**: la meta, al aire libre.

**Recorrido principal**: pisos 1 → 5 con los ascensores. **Rutas alternativas**: las ramas exteriores (más cortas, sin ascensor,
con murciélagos).

**Túneles, cuevas y puertas**
- **Raíces → copa**: túnel de **12 × 3** bajo el piso 1 (por las raíces) que sale directamente al piso 3; una **puerta con
  cerradura** en el piso 4 lleva a la **cámara del corazón del árbol**, sala de **10 × 6** con la gema 3 y un reloj.

**Enemigos y ubicación**
- **Topos** ×3: en el piso 1 (suelo de tierra, cols 100, 180, 260).
- **Guardianes** ×2: en los pisos 2 y 4 junto a los ascensores (cols 360 y 40).
- **Murciélagos** ×3: colgados de los techos del piso 3 y de las ramas exteriores (cols 150, 250, 330).

**Trampas y obstáculos**: **péndulos** (3 en los pisos 3 y 4); bloques conmutables que cierran el paso.

**Mecánica especial**: **interruptores + ascensores** (se encadenan: hay que activar el interruptor antes de llamar al ascensor).

**Secretos y recompensas**: 3 gemas (1 en el piso 2 tras un interruptor, 2 en una rama exterior, 3 en la cámara del corazón),
**1 llave**, 1 reloj +30 s.

**Diferencias concretas respecto a los demás**: **interior vertical por pisos**; el 1-4 es cueva horizontal y el 1-5 es exterior;
combina ascensor con interruptores (el 1-10 usa ascensores sin interruptores).

---

## 1-19 · Camino de los Susurros  *(tanda 4 · nivel secreto)*
**Función en el juego**: nivel secreto (se llega desde 1-13); poco combate y mucho recorrido.

**Datos**: secreta · 640 × 26 · 360 s · dificultad 4/5 · puntos de control en los cruces. **Salida al túnel sellado del Océano**
(cuando se complete).

**Tema visual**: sendero con niebla morada y luz fantasmal; árboles blancos; susurros (sonido).

**Terreno y plataformas**
- **Tres corredores paralelos** (filas 6, 13 y 20), de 200 celdas cada uno, **conectados por cruces** (cols 120, 240, 360, 480): se
  puede pasar de un corredor a otro, así que el nivel es un **laberinto** con varios caminos hasta la meta.
- **Suelos que desaparecen** en tramos de cada corredor (cadenas de 4-6 plataformas con huecos de 3).
- **Compuertas** (bloques conmutables) cierran algunos cruces; los **interruptores encadenados** (grupo 1 y 2) abren primero un cruce
  y luego otro.

**Recorrido principal**: el corredor central, abriendo las compuertas. **Rutas alternativas**: los corredores superior e inferior
(cada uno tiene una llave).

**Túneles, cuevas y puertas**
- **3 bucles**: túneles cortos de **14, 20 y 26 celdas** que devuelven al jugador a un corredor anterior (pero con las compuertas
  ya abiertas); el bucle de 26 contiene una **puerta con cerradura** a la **sala de los susurros** (12 × 6) con la gema 3.

**Enemigos y ubicación**: **guardián silencioso** ×2 (en el cruce de la col 240 y en el último), de ataque lento; sin otros enemigos.

**Trampas y obstáculos**: **suelos que desaparecen**; compuertas conmutables.

**Mecánica especial**: **interruptores encadenados** con bloques y rutas elegibles.

**Secretos y recompensas**: 3 gemas, **2 llaves** (una en cada corredor exterior), sala de los susurros, 1 reloj.

**Diferencias concretas respecto a los demás**: **laberinto de tres corredores**; es el nivel con **menos enemigos**; sus túneles son
**bucles**, no atajos.

---

## 1-20 · Castillo del Guardián  *(tanda 4 · castillo + jefe)*
**Función en el juego**: repaso final y combate contra el jefe de varias fases.

**Datos**: castillo · 700 × 24 · 360 s · dificultad 5/5 · puntos de control tras el patio, tras la torre y ante la arena.

**Tema visual**: castillo de raíces y piedra, vidrieras verdes, banderas, antorchas; la arena final con enredaderas.

**Terreno y plataformas**
- **Puerta exterior y patio (cols 0-160)**: suelo con tres fosos y **plataformas que desaparecen**.
- **Muralla (cols 160-320)**: pasarela con **dardos y prensas**.
- **Torre del reloj (cols 320-440, filas 2-22)**: se sube con **ascensores y orbitales**, e **interruptores** abren el paso.
- **Pasillo de las lianas (cols 440-540)**: **lianas** sobre un abismo.
- **Arena del jefe (cols 560-700)**: sala larga con columnas; el **jefe de varias fases** se activa al cruzar la puerta de la arena (G).

**Recorrido principal**: patio → muralla → torre → lianas → arena → meta (aparece al derrotar al jefe).
**Rutas alternativas**: una ruta opcional por el techo de la muralla (más difícil, con una gema).

**Túneles, cuevas y puertas**: **llave del jefe** (en la torre) para la puerta de la arena; **armería** secreta (10 × 4) con la gema 3.

**Enemigos y ubicación**: **mezcla** (guardianes en la muralla, lanzarrocas en la torre, murciélagos en el pasillo de lianas) y el
**jefe**.

**Trampas y obstáculos**: **todas**, escalonadas por zona.

**Mecánica especial**: **repaso** de las mecánicas, una por zona.

**Secretos y recompensas**: 3 gemas, 1 llave (para el jefe), armería.

**Diferencias concretas respecto a los demás**: **castillo con jefe de varias fases** y una sección de cada mecánica.

---

## 5. Cómo se comprobará que son distintos

- **Vista previa conjunta** de los niveles de cada tanda, y de los 20 al final.
- **Medidas automáticas**: perfil de altura, mapa de enemigos por columna, tipos de trampas y geometría de cada túnel; se
  rechaza cualquier par que coincida en demasiado.
- **Pruebas de motor** de cada mecánica usada y **recorrido real** de cada nivel con jugador virtual donde sea posible.
- **Pruebas del juego original** y de su guardado en cada entrega.

## 6. Tandas
- **Tanda 1 (1-1…1-5)**: se construye tras tu aprobación de estas fichas.
- **Tandas 2 a 4**: no se empiezan sin tu aprobación.

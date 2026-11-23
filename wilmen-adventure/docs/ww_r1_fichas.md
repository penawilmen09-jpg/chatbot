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
2. **Subsuelo explorable (nuevo)**: los túneles y cuevas son **redes reales** situadas bajo el nivel (no habitaciones sueltas
   para coger una gema). Cada red tiene como mínimo: **2 entradas**, **2 salidas distintas**, **1 bifurcación**, **1 camino secreto**
   y habitaciones de formas y tamaños diferentes. Las bocas de túnel (`T`, con SALTO) se usan solo como atajos o accesos secretos;
   el resto se recorre a pie. Ninguna sala se repite con otro color.
3. **Más exploración y rutas opcionales con recompensa que merece la pena**: además de gemas, hay **orbes de poder temporales**
   (llama, hielo, pulso, barrera, gigante), **vidas**, **corazones**, **relojes**, **atajos** y zonas con **monedas en cantidad**.
   Cada ruta opcional indica qué ofrece y qué cuesta (riesgo o tiempo).
4. **Cada enemigo y cada trampa tiene una función** escrita en la ficha: enseñar una mecánica, vigilar una ruta opcional,
   obligar a cronometrar una liana, proteger un secreto, etc. No hay enemigos de relleno.
5. **Reloj justo** (ver sección 1.1). **Llaves sin bloqueos** (ver sección 1.2).
6. **Mecánicas**: cada una debuta en un nivel que la enseña y vuelve después con otro uso.
7. **Tamaño variable**: de 20 a 32 filas y de 340 a 900 columnas, según el diseño.
8. **Se conserva**: cuenta atrás (a cero muere y pierde una vida), vidas, puntos de control, monedas, 3 gemas por nivel, llaves
   y guardado. Las puertas y túneles solo se entran con SALTO.
9. **Justo y completable**: dificultad creciente. Un nivel solo se da por terminado si (a) el validador lo da por completable,
   (b) sus mecánicas se comprueban en el motor, (c) un jugador virtual recorre su ruta principal y (d) la comparación con los
   demás confirma que es distinto. Las gemas más difíciles nunca bloquean el avance.
10. **Huecos del mapa que se respetan**: cuevas en 4 y 13, casa en 7, fortaleza en 10, nivel secreto en 19, castillo con jefe en 20;
    salidas secretas en 5 (→ casa 1-7), 9 (→ 1-15), 13 (→ 1-19) y 19 (→ túnel sellado al Océano).

### 1.1 Reloj: cómo se calcula para que no se muera injustamente
- Se miden **tres tiempos** de cada nivel con el validador y el jugador virtual:
  **(P)** ruta principal a ritmo normal (≈ 4 celdas/s de media incluyendo saltos y esperas);
  **(E)** recorrido de exploración completa (todas las rutas opcionales, gemas y secretos);
  **(L)** límite del reloj.
- **Regla**: `L = E × 1,25`, redondeado a la decena, y siempre `L ≥ 2,5 × P`. Es decir, hay tiempo para **explorarlo todo** y aún
  sobra un 25 %, y para quien solo va a la meta, el reloj es muy holgado.
- **Cada zona opcional tiene su reloj**: un reloj de +15 s o +30 s dentro o junto a la zona que **compensa con creces** el
  tiempo que cuesta visitarla. Ninguna exploración gasta tiempo neto.
- **Al reaparecer** (cambio a aplicar y probar antes de construir): el punto de control no solo guarda el tiempo, sino que
  garantiza **como mínimo el doble del tiempo de la ruta principal que queda hasta la meta** (nunca menos de 60 s hasta ahora).
  Así, morir con poco tiempo no deja una situación imposible.
- Cuando quedan menos de 45 s ya existe el aviso visual y sonoro del reloj (se mantiene).

### 1.2 Llaves: cómo se evita quedarse bloqueado
1. **La ruta principal hasta la meta no necesita ninguna llave** en los niveles 1-1 a 1-5. Todas las puertas con cerradura son
   opcionales y protegen recompensas. (Más adelante, en la fortaleza 1-10, habrá cerraduras obligatorias con sus propias reglas.)
2. **Todas las llaves de un nivel se pueden coger sin abrir ninguna puerta**: ninguna llave está detrás de una cerradura.
3. **Hay al menos tantas llaves como cerraduras** en cada nivel; así se pueden abrir todas en cualquier orden y gastar una llave
   en una puerta nunca impide abrir otra.
4. Las llaves ya cogidas y las puertas ya abiertas **se recuerdan** (si mueres o sales, no se pierden ni se vuelven a cobrar).
5. **Toda pared conmutable tiene un interruptor a cada lado**, y ninguna habitación tiene como única salida un interruptor ni una
   puerta cerrada: siempre se puede volver.
6. El validador comprueba estas reglas por simulación (todos los órdenes posibles de usar las llaves).

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
| 1 | Sendero del Amanecer | normal | 520×26 | colinas + madriguera | setas | caminante, saltarín | ninguna | madriguera suave de 7 espacios, 3 entradas/3 salidas |
| 2 | Garganta de las Cascadas | normal | 360×32 | ascenso en 3 terrazas + panal interior | corrientes y burbujas | volador, disparador | pinchos | panal vertical de 6 espacios, 4 entradas/3 salidas |
| 3 | Puente de los Mil Pasos | normal | 820×24 | pilares y puentes, sin suelo | puentes y plataformas que desaparecen | murciélago, volador | dardos | torres huecas y viaductos (~130 celdas) |
| 4 | Cueva de las Raíces | cueva | 560×28 | red de 11 espacios | interruptores | topo, lanzarrocas | pinchos | cueva completa, 2 entradas/3 salidas |
| 5 | Copas Altas | normal | 420×32 | 7 árboles gigantes | lianas | murciélago, volador | — | red de troncos y rama hueca de 56 celdas |
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
**Función en el juego**: el primer nivel. Enseña a moverse, a rebotar y a explorar un subsuelo sencillo. Es el único nivel sin trampas.

**Datos**: normal · **520 × 26** (superficie en las filas 5-16, subsuelo en las 17-25) · puntos de control en cols 205, 300 y 420.
**Reloj**: P (ruta principal) ≈ 110 s · E (explorarlo todo) ≈ 250 s · **L = 320 s**.
**Tema visual**: claro de bosque al amanecer, niebla baja, luz dorada; el subsuelo es una madriguera de raíces con luz cálida.

### Superficie
- **A. Claro de salida (cols 0-60)**: suelo casi plano con dos desniveles de 1 celda; arco de monedas y un tronco caído de 6 celdas.
- **B. Primeras colinas (60-130)**: cuatro colinas suaves. Al pie de un risco de 8 celdas (col 100) hay una **seta vertical**; arriba,
  una repisa de 7 celdas con 8 monedas y la **gema 1**.
- **C. Fosos del salto (130-205)**: tres fosos de 3, 4 y 5 celdas entre islas de 8-10, y un cuarto de **12 celdas** (cols 185-197).
  Se salva con la **seta diagonal** (col 183) o con una escalera de tres plataformas flotantes (más lenta, 4 saltos). Control en 205.
- **D. Bosque alto (205-300)**: el suelo sube en tres escalones; copas bajas opcionales con monedas.
- **E. Colinas del alba (300-420)**: cinco colinas redondeadas sin vacíos. Reloj +15 s (col 360). Puerta de piedra (col 392).
- **F. Cima (420-520)**: rampa hasta la roca de la meta (fila 4, col 505); dos setas encadenadas (col 440 diagonal, col 462 vertical)
  la alcanzan directamente; alternativa: rampa de escalones (60 columnas más).

### Subsuelo explorable: «La Madriguera» (cols 60-330, filas 17-25)
Una red de **7 espacios distintos**, 3 entradas y 3 salidas:
- **Entradas**: **E1** boca abierta en la superficie (col 66, escalera de 4 repisas hacia abajo); **E2** boca secreta en el árbol hueco
  (col 125, T con SALTO, cae en lo alto de la Raíz hueca); **E3** hoyo en el bosque alto (col 216) que cae en la Galería larga.
- **M1 «Zanja» (46 × 5, cols 70-116)**: pasillo largo con techo bajo que baja en suave pendiente; 1 caminante.
- **M2 «Raíz hueca» (14 × 9, cols 118-132)**: cámara vertical con repisas alternas cada 2 filas; en lo más alto, la **llave**.
- **M3 «Sala del eco» (20 × 7, ovalada, cols 134-154)**: es la **bifurcación principal**, con tres salidas: arriba hacia M6, al este hacia M4 y
  abajo hacia M5.
- **M4 «Galería larga» (56 × 4, cols 156-212, sube de la fila 22 a la 18)**: un reloj +15 s a mitad; a media galería, una **segunda
  bifurcación**: continúa hasta el pozo de salida X2 (col 226) o gira por el **pasadizo oculto M7**.
- **M5 «Despensa» (12 × 5)**: **habitación secreta** tras una pared de ladrillos (se rompe golpeando con la cabeza desde abajo): **orbe
  de pulso**, 15 monedas y la **gema 3**.
- **M6 «Balcón de raíces» (22 × 4)**: galería alta sobre M3 con una **vida extra** y una ventana que sale a la superficie (X1, col 175).
- **M7 «Pasadizo oculto» (34 × 3)**: discurre bajo las colinas hasta salir en la colina de las 300 (X3, junto al punto de control).
- **Salidas**: **X1** ventana de M6 (col 175), **X2** pozo con repisas al final de M4 (col 226), **X3** boca de M7 (col 300).

### Recorrido y rutas opcionales (con coste y premio)
| Ruta | Dónde | Coste | Premio |
|---|---|---|---|
| **Principal** | superficie A → F con las setas | nada | meta |
| Repisa de la seta vertical | B (col 100) | ~15 s | gema 1 + 8 monedas |
| Escalera flotante | C | más lenta | 10 monedas (alternativa a la seta) |
| Madriguera completa | M1-M7 | ~100 s | llave, orbe de pulso, vida, gema 3, reloj +15 s |
| Casita de piedra | puerta col 392 (1 llave) | ~20 s | gema 2, 20 monedas, 1 corazón |
| Atajo por M7 | de M4 a X3 | ~0 s | salta ~100 columnas de superficie |

### Enemigos y su función
- **Caminante (col 40)**: aislado en el claro; enseña a pisar sin riesgo.
- **Caminante (col 85)**: patrulla junto al pie de la seta vertical; enseña a esperar y entrar en el momento.
- **Saltarín (col 160)**: en la primera isla de C; enseña su salto (se agacha antes de saltar).
- **Saltarín (col 175)**: en la isla previa al foso grande; obliga a decidir entre seta diagonal y escalera.
- **Caminante en M1**: practica pisar en un espacio cerrado, sin caídas.
- **Caminante (col 330) + saltarín (col 340)**: examen combinado antes del reloj; repasan lo aprendido.
- **Caminante (col 372)**: vigila la puerta de piedra (protege una recompensa opcional).
No hay más enemigos: 8 en total.

### Trampas
Ninguna. Los únicos peligros son los fosos de C y los enemigos.

### Mecánica especial
**Setas** (vertical, diagonal y encadenadas, en ese orden).

### Llaves y cerraduras
| Llave | Dónde (libre, sin abrir nada) | Cerradura | Obligatoria |
|---|---|---|---|
| 1 llave | lo alto de M2 | Puerta de la Casita de piedra (col 392) | **No** |
Hay 1 llave para 1 cerradura. La ruta principal no necesita llaves.

### Secretos y recompensas
Gema 1 (repisa B) · gema 2 (Casita) · gema 3 (Despensa M5) · orbe de pulso · vida extra (M6) · 1 reloj +15 s en M4 y otro +15 s en
superficie · ~150 monedas.

### Diferencias concretas respecto a los demás
- Único sin trampas y único con recorrido **horizontal sobre colinas**.
- Su subsuelo es una **madriguera suave y bifurcada de 3 entradas / 3 salidas**; no tiene peligros (los demás subsuelos tienen
  dardos, corrientes, topos o interruptores).
- Solo dos comportamientos enemigos (patrulla y salto).

---

## 1-2 · Garganta de las Cascadas  *(tanda 1)*
**Función en el juego**: enseña a leer el agua (corrientes y burbujas), a subir en vertical y a explorar un subsuelo vertical.

**Datos**: normal · **360 × 32** · puntos de control en cols 120, 220 y 300.
**Reloj**: P ≈ 150 s · E ≈ 330 s · **L = 420 s**.
**Tema visual**: garganta de roca húmeda con tres cascadas en cadena, arcoíris, musgo; el subsuelo es roca con filtraciones y cristales.

### Superficie (3 terrazas unidas por cascadas)
- **Terraza 1 (cols 0-125, fila 29)**: poza (cols 40-56) con **corriente a la derecha** de 16 × 3 sobre tres piedras; rocas que suben hasta la
  cascada 1 (cols 110-125).
- **Subida 1**: **columna de burbujas** (cols 118-120, filas 17-28) que eleva 11 celdas; alternativa: tres móviles verticales.
- **Terraza 2 (60-230, filas 17-19)**: zigzag de repisas de 4-6 celdas; en cols 150-160 una **corriente a la izquierda** de 10 × 4.
- **Subida 2**: cascada 2 (cols 225-240): burbujas (cols 232-233) o dos móviles verticales y un resorte.
- **Terraza 3 (150-360, filas 4-8)**: repisas estrechas, puente de piedra de 18 celdas, meta en col 352; último tramo con corriente a la
  derecha de 14 celdas y dos móviles horizontales.

### Subsuelo explorable: «El Panal» (en la roca entre la terraza 2 y la 3, cols 88-250, filas 6-29)
Red de **6 espacios** con 4 entradas y 3 salidas:
- **Entradas**: **E1** boca del pozo en la terraza 1 (col 90); **E2** arco del arcoíris en la terraza 2 (col 150, subida de 3 celdas);
  **E3** boca secreta **tras la cascada 1** (col 124); **E4** ventana baja de la terraza 3 (col 186) desde el exterior.
- **P1 «Pozo» (6 × 14, cols 88-94, filas 15-29)**: cámara vertical con 5 salientes alternos; a media altura, un **nicho de 4 × 4** con la
  **llave A**. Sale arriba a la terraza 2 (X1).
- **P2 «Galería del goteo» (48 × 3, cols 150-198, fila 13)**: galería larga con goteras; recibe desde E2 y desemboca en P3.
- **P3 «Cámara de las cascadillas» (20 × 10, cols 198-218)**: sala con una cascada interior que forma una **columna de burbujas**; es la
  **bifurcación principal**: izquierda arriba (burbujas) hacia P5; derecha por escalones hacia P4; abajo una **puerta con cerradura**.
- **P4 «Sifón» (30 × 4, cols 220-250, filas 14-17)**: galería inundada con **corriente en contra**; al final, la **llave B** y salida X2 al
  balcón de la cascada 2.
- **P5 «Mirador interior» (26 × 5, cols 160-186, filas 6-10)**: galería alta con una ventana a la terraza 3 (salida X3, **atajo que se
  salta la cascada 2**) y la **despensa del arcoíris** tras una puerta con cerradura.
- **P6 «Cueva del arcoíris» (18 × 6)**: **habitación secreta** a la que se llega desde E3 (tras la cascada 1) por un pasadizo de 14 × 3; tiene
  un cofre (gema 2) y una vida extra.
- **Salidas**: X1 (terraza 2, junto al pozo), X2 (balcón de la cascada 2) y X3 (terraza 3, ventana de P5).

### Recorrido y rutas opcionales
| Ruta | Dónde | Coste | Premio |
|---|---|---|---|
| **Principal** | terraza 1 → burbujas → zigzag → burbujas → cresta | nada | meta |
| Móviles verticales | en lugar de burbujas | más lenta | seguridad (sin voladores) |
| El Panal (parte) | pozo → P2 → P3 → P5 → X3 | ~60 s | **atajo** que salta la cascada 2 y gema 1 en P2 |
| Panal completo | P1-P6 | ~150 s | 2 llaves, gema 1 y 2, vida, reloj +30 s |
| Mirador (puerta col 300) | terraza 3 | ~20 s | gema 3, 1 corazón, orbe de hielo |
| Despensa del arcoíris (puerta en P5) | P5 | ~15 s | 30 monedas y 1 vida |

### Enemigos y su función
- **Voladores ×2 sobre la columna de burbujas 1**: castigan quedarse parado en las burbujas; hay que subir moviéndose.
- **Voladores ×2 en P3**: patrullan en vertical y guardan la bifurcación; obligan a elegir camino mirando su ritmo.
- **Disparador (col 205, terraza 2)**: cubre el tramo hacia la cascada 2; obliga a usar las repisas como cobertura.
- **Disparador (col 275, terraza 3)**: protege el punto de control; fuerza a cronometrar el cruce.
No hay enemigos de suelo ni en la terraza 1 (el agua se aprende sin presión). 6 en total.

### Trampas
- **Pinchos al pie de cada cascada**: penalizan fallar la burbuja y hacen que el desvío sea una decisión.
- **Corriente en contra** (cols 150-160 y en P4): enseña que el agua también frena.

### Mecánica especial
**Corrientes de agua y burbujas**, más móviles verticales.

### Llaves y cerraduras
| Llave | Dónde (libre) | Cerradura | Obligatoria |
|---|---|---|---|
| Llave A | nicho del pozo (P1) | Mirador (puerta col 300) | No |
| Llave B | final del Sifón (P4) | Despensa del arcoíris (P5) | No |
Hay 2 llaves para 2 cerraduras, ambas opcionales. Cada llave está libre (ninguna está tras una cerradura).

### Secretos y recompensas
Gema 1 (P2) · gema 2 (P6, secreta) · gema 3 (Mirador) · 2 vidas (P6 y despensa) · orbe de hielo · 2 relojes (+30 s en el Panal, +15 s en
la terraza 2) · ~120 monedas siguiendo las columnas de burbujas.

### Diferencias concretas respecto a los demás
- Único que se resuelve **subiendo en 3 terrazas** con agua (el 1-8 es el opuesto).
- Su subsuelo es **vertical y compacto**, con 6 espacios y una bifurcación con puerta cerrada y atajo hacia la cresta.
- Primer nivel con **enemigos aéreos y disparadores**, y sin ningún enemigo terrestre.
- El agua **eleva**; en 1-6 y 1-15 arrastra horizontalmente.

---

## 1-3 · Puente de los Mil Pasos  *(tanda 1)*
**Función en el juego**: enseña a no detenerse (puentes que caen) y a leer el ritmo de las plataformas que desaparecen; el subsuelo
son torres huecas unidas por viaductos.

**Datos**: normal · **820 × 24** (superficie en las filas 9-17, subsuelo y viaductos en las 18-23) · puntos de control en cols 190, 380 y 560.
**Reloj**: P ≈ 170 s · E ≈ 340 s · **L = 430 s**.
**Tema visual**: abismo con niebla azulada, puentes de cuerda y madera entre torres de roca, arcos de piedra; interiores de piedra tallada.

### Superficie (12 pilares y vacío; sin suelo continuo)
- **Pilar 1 (0-40)**: salida. **Puente 1 (40-72, 30 tablas)**: se derrumba al pisarlo; lo cubre un arco de piedra.
- **Pilar 2 (72-100)** y **cadena de plataformas que desaparecen (100-160)**: 5 de 3 celdas, huecos de 3, alturas 14-13-12-13-14.
- **Pilar 3 (160-190)** con control. **Puente 2 largo (190-232, 40 tablas)** que baja 2 celdas a mitad.
- **Pilar 4 (232-270)** y **campo de pilares diminutos (270-340)**: cuatro de 3 celdas separados por 6, con desmoronables.
- **Pilar 5 (340-380)**, **puente 3 (380-410)** y **puente 4 (440-470)**.
- **Pilares 6-11 (470-760)**: pilares de 6-14 celdas a distintas alturas, huecos de 8-26 salvados por puentes, cadenas y **una liana de 8
  celdas**. **Pilar 12 (760-820)**: altar de la meta.

### Subsuelo explorable: «Las Torres Huecas» (pilares 3, 4/5 y 7, más viaductos)
Los pilares 3, 5 y 7 tienen **interior tallado**; los une una red de **viaductos cubiertos**, pasillos cerrados que cruzan el abismo y
permiten saltarse los puentes. Total ≈ 130 celdas de recorrido subterráneo.
- **Entradas**: **E1** escalera en la cima del pilar 3 (col 175); **E2** puerta oculta (T) en el costado del pilar 5 (col 355); **E3**
  entrada baja del pilar 7 (col 520) desde el exterior.
- **N1 «Salón del pilar 3» (20 × 8)**: sala de guardia con escalera; bifurcación: viaducto V1 hacia el este o escalera al sótano.
- **V1 «Viaducto del eco» (24 × 4)**: pasillo cubierto con **3 lanzadardos** alternados (arriba y abajo).
- **N2 «Cámara del pilar 5» (16 × 10)**: nudo vertical con **bifurcación**: arriba (sale al extremo del puente 3, salida X1), abajo (el
  **sumidero**, un pozo con la llave B) y al este el viaducto largo.
- **V2 «Pasaje largo» (38 × 5)**: corredor con 4 lanzadardos y un **nicho lateral de 4 × 4** con la **llave A**.
- **S1 «Galería del tesoro» (14 × 5)**: **habitación secreta** tras una pared de ladrillos en V2: orbe de gigante, una vida y la **gema 1**.
- **N3 «Salón del pilar 7» (18 × 7)**: salida arriba a la cima del pilar 7 (X2) y salida abajo al pilar 8 (X3); una **puerta con cerradura**
  a la **cámara sellada** (10 × 5).
- **Salidas**: X1 (puente 3), X2 (cima del pilar 7), X3 (pilar 8, secreta).

### Recorrido y rutas opcionales
| Ruta | Dónde | Coste | Premio |
|---|---|---|---|
| **Principal** | superficie por los puentes | nada (pide ritmo) | meta |
| Pasarelas bajas | tramo 470-760 (fila 18) | más lento | evita puentes, con plataformas que desaparecen |
| Torres huecas (atajo) | N1 → V1 → N2 → V2 → N3 | ~70 s (ahorra ~100) | evita los puentes 2 y 3 y los voladores |
| Torres huecas completas | + sumidero + S1 | ~140 s | 2 llaves, gema 1, orbe de gigante, vida, reloj +30 s |
| Cámara del arco | col 340, fila 4 | ~25 s | gema 2 y reloj +15 s |
| Balcón del altar | puerta col 790 | ~20 s | gema 3, reloj +30 s, corazón |
| Cámara sellada | puerta en N3 | ~20 s | orbe de barrera y 50 monedas |

### Enemigos y su función
- **Murciélago (col 55)**: sobre el puente 1; obliga a cruzar corriendo en vez de andar.
- **Murciélago (col 150)**: sobre la cadena que desaparece; castiga quedarse en una plataforma.
- **Murciélago (col 215)**: sobre el puente 2; comprueba que se cruza sin parar.
- **Murciélago (col 330)**: guarda la ruta hacia la cámara del arco.
- **Voladores ×2 (cols 205 y 220, puente 2)**: son el motivo para elegir el viaducto como alternativa.
No hay enemigos dentro de las torres: el reto allí son los dardos. 6 en total.

### Trampas
- **Dardos** en V1 y V2: obligan a cronometrar en un espacio cerrado (sin esquivar con el salto en el aire).
- **Puentes derrumbables** y **plataformas que desaparecen**: enseñan el ritmo.

### Mecánica especial
**Puentes que se derrumban** y **plataformas que desaparecen**.

### Llaves y cerraduras
| Llave | Dónde (libre) | Cerradura | Obligatoria |
|---|---|---|---|
| Llave A | nicho de V2 | Balcón del altar (col 790) | No |
| Llave B | sumidero de N2 | Cámara sellada (N3) | No |
2 llaves para 2 cerraduras; ambas opcionales y libres.

### Secretos y recompensas
Gema 1 (S1) · gema 2 (cámara del arco) · gema 3 (balcón) · orbe de gigante · orbe de barrera · 1 vida · 3 relojes (+15 s arco, +30 s
torres, +30 s balcón).

### Diferencias concretas respecto a los demás
- **Sin ningún tramo de suelo continuo** y con subsuelo hecho de **torres y viaductos** (no cuevas excavadas).
- Primer nivel con **murciélagos** y con **dardos en espacio cerrado**.
- Los puentes son protagonistas; en 1-5 son lianas y en 1-1 setas.

---

## 1-4 · Cueva de las Raíces  *(tanda 1 · cueva)*
**Función en el juego**: enseña a modificar el escenario (interruptores y bloques) y es la cueva más grande y explorable de la tanda 1.

**Datos**: cueva · **560 × 28** · puntos de control en salas 2, 4 y 5. Techo continuo salvo en las salidas.
**Reloj**: P ≈ 190 s · E ≈ 380 s · **L = 480 s**.
**Tema visual**: raíces gigantes entrelazadas, hongos luminosos azules, gotas de agua; zonas más cálidas junto al tesoro.

### Red de 11 espacios, 2 entradas y 3 salidas
- **Entradas**: **E1** vestíbulo (col 0); **E2** «Boca del barranco», un agujero en la ladera exterior (col 420, fila 8) que cae a la parte alta de
  la sala 5 (se llega por la ladera exterior).
- **Sala 1 «Vestíbulo» (36 × 11)**: salida; suelo en dos escalones; hongos decorativos.
- **Pasillo A (14 × 3)**: bajo y recto.
- **Sala 2 «Columnas» (44 × 14)**: cinco columnas de 2 celdas; pinchos en 3 huecos. Al fondo el **interruptor 1** y la pared `)` que tapa el
  pasillo B (hay otro interruptor 1 al otro lado del pasillo, por si se vuelve).
- **Pasillo B (16 × 4)**: se abre con el interruptor 1.
- **Sala 3 «Embudo» (28 arriba → 6 abajo, 16 de profundidad)**: espiral invertida de escalones. **Bifurcación de 3 bocas**: superior (a
  sala 5), media (a sala 4) e inferior (alameda de topos).
- **«Alameda» (36 × 4)**: pasadizo largo y estrecho con topos que vuelve a la sala 2 (camino alternativo que se salta el interruptor 1); en
  su extremo, la **llave B**.
- **Sala 4 «Cámara circular» (24 × 24)**: anillo de plataformas alrededor de un pilar; **interruptor 2** en lo alto (con su espejo en la entrada de
  la galería) y la **llave A** en el anillo superior.
- **«Manantial» (30 × 4)**: galería inundada con corriente a la derecha bajo la sala 4; lleva a la **puerta del manantial** (cerradura) y a
  la **salida X2** al exterior, a la derecha de la meta (premio: una vida).
- **Sala 5 «Galería inclinada» (60 × 8)**: sube 8 celdas; bloques `(` que alternan con el interruptor 2; al final, la puerta del tesoro y el
  pozo de salida.
- **Sala 6 «Tesoro» (20 × 10)**: cofre, gema 3 y reloj.
- **«Telaraña» (16 × 6)**: **habitación secreta** a la que se accede rompiendo ladrillos al final de la galería; orbe de hielo y la **gema 2**.
- **Salidas**: **X1** pozo de 5 × 12 al final de la galería (a la meta, col 540); **X2** manantial (exterior); **X3** «chimenea del tesoro»
  (secreta, de la sala 6 a un saliente sobre la meta, con 30 monedas).

### Recorrido y rutas opcionales
| Ruta | Dónde | Coste | Premio |
|---|---|---|---|
| **Principal** | 1 → A → 2 (interruptor 1) → B → 3 → 4 → 5 → pozo → meta | nada | meta |
| Boca superior del embudo | directa a la sala 5 | arriesgada (lanzarrocas) | ahorra ~50 s |
| Alameda de topos | de la sala 3 a la 2 | ~40 s | llave B y salta el interruptor 1 |
| Manantial | bajo la sala 4 | ~40 s | llave B (alternativa), vida y salida X2 |
| Telaraña | fin de la galería | ~25 s | gema 2 y orbe de hielo |
| Tesoro | puerta de la sala 5 | ~20 s | gema 3, cofre y reloj +30 s |
| Gema 1 | columnas de la sala 2 | ~15 s | gema 1 (se llega saltando de columna a columna) |

### Enemigos y su función
- **Topos ×3 en la sala 2** (entre columnas, cols 90, 104, 120): obligan a cruzar con ritmo mientras se evitan los pinchos.
- **Topos ×3 en la alameda** (uno cada 12 celdas): castigan correr sin mirar; avisan temblando 0,6 s.
- **Lanzarrocas (arriba del embudo)**: cubre la bajada; hace que las bocas inferiores sean una alternativa atractiva.
- **Lanzarrocas ×2 al inicio de la galería inclinada**: disparan en pendiente; los huecos de los bloques sirven de cobertura.
No hay caminantes ni voladores. 9 en total.

### Trampas
- **Pinchos** de la sala 2 (separan las columnas; obligan a saltar entre ellas).
- **Bloques conmutables**: son el puzle; cada pared tiene un interruptor a cada lado, así nunca se queda cerrada una habitación.

### Mecánica especial
**Interruptores y bloques conmutables** (el interruptor solo actúa al pisarlo; el estado se reinicia al reaparecer).

### Llaves y cerraduras
| Llave | Dónde (libre) | Cerradura | Obligatoria |
|---|---|---|---|
| Llave A | anillo alto de la sala 4 | Tesoro (sala 5) | No |
| Llave B | final de la alameda | Puerta del manantial | No |
2 llaves para 2 cerraduras; ambas opcionales y libres. La salida X1 (pozo) está siempre abierta.

### Secretos y recompensas
Gema 1 (columnas) · gema 2 (Telaraña) · gema 3 (Tesoro) · orbe de hielo · vida (manantial) · 2 relojes (+30 s tesoro, +15 s sala 4) · 30 monedas
en la chimenea.

### Diferencias concretas respecto a los demás
- Único **nivel-cueva con 11 espacios de formas distintas** (rectangular, ovalada, embudo, anillo, pendiente, galerías inundadas).
- Primer nivel con **topos y lanzarrocas**.
- La **bifurcación de 3 bocas** y las **3 salidas** (pozo, manantial, chimenea secreta) no se repiten en otro nivel.
- Los interruptores aquí son **puertas y pasillos**; en 1-9 se encadenan en orden libre y en 1-18 se unen a un ascensor.

---

## 1-5 · Copas Altas  *(tanda 1 · salida secreta → casa 1-7)*
**Función en el juego**: enseña a balancearse con las lianas; el subsuelo son ramas y troncos huecos.

**Datos**: normal · **420 × 32** · puntos de control en las copas de los árboles 3 y 5.
**Reloj**: P ≈ 140 s · E ≈ 270 s · **L = 340 s**.
**Tema visual**: copas de árboles gigantes sobre un mar de nubes al atardecer; interior de los troncos con luz ámbar.

### Superficie (7 árboles; casi sin suelo)
- **Suelo del bosque (cols 0-40, fila 30)**: salida; es el único suelo del nivel además de la meta.
- **Árboles** (troncos de 4-6 celdas) en cols ≈ 30, 90, 150, 215, 275, 335 y 395; copas de 8-14 celdas a filas 22, 16, 24, 10, 18, 8 y 12.
- **Vacíos de 10 a 22 celdas** entre copas, imposibles de saltar.
- **Hueco 1 (20 celdas)**: una liana de 9 celdas (para aprender).
- **Hueco 2 (18)**: **seta vertical** en una rama que lanza a la copa 3.
- **Hueco 3 (22)**: **dos lianas encadenadas**.
- **Huecos 4-6**: liana larga + rama intermedia; los dos últimos suben a las copas altas. **Último árbol (col 395)**: la meta.

### Subsuelo explorable: «La Red del Tronco» (troncos 4 y 5, y la rama hueca que los une)
Un sistema de **cavidades dentro de la madera**: dos troncos huecos unidos por una gran rama hueca. 5 espacios, 3 entradas y 3 salidas.
- **Entradas**: **E1** boca baja del tronco 4 (col 218, fila 27); **E2** agujero en la rama alta del tronco 5 (fila 20, desde la copa 5);
  **E3** ventana oculta (T con SALTO) en el costado del tronco 4 (fila 20).
- **T4 «Tronco hueco» (5 × 14, cols 214-219, filas 14-28)**: cámara vertical con salientes alternos; es el nudo del sistema.
- **«Rama hueca» (56 × 3, cols 218-274, filas 22-24)**: túnel horizontal dentro de la rama gruesa que une el tronco 4 y el 5; a mitad, una **bifurcación**:
  arriba (escalera a una ventana, salida X2) y abajo (la **despensa** secreta).
- **T5 «Tronco 5» (6 × 10, cols 272-278, filas 10-20)**: sube a la copa 5 (salida X3, justo en el punto de control).
- **«Despensa de la ardilla» (12 × 6)**: **habitación secreta** (pared de ladrillos): orbe de barrera, 25 monedas y la **gema 2**.
- **«Nido del pájaro» (10 × 5)**: tras una **puerta con cerradura** en lo alto del tronco 4 (fila 14); gema 3 y una vida.
- **Salidas**: **X1** cima del tronco 4 (fila 14, a una rama alta), **X2** ventana de la rama hueca, **X3** cima del tronco 5.

### Recorrido y rutas opcionales
| Ruta | Dónde | Coste | Premio |
|---|---|---|---|
| **Principal (alta)** | lianas encadenadas por las copas | pide timing | meta |
| Ruta baja | ramas gruesas (fila 26) con 3 saltos de 5 celdas | más lenta, con murciélagos | llave A (nido bajo col 245) |
| Red del tronco (atajo) | E1 → T4 → rama hueca → T5 | ~45 s (ahorra ~80) | se salta los huecos 3 y 4 (sin lianas) |
| Red completa | + despensa + nido | ~100 s | llave A y B, gema 2 y 3, orbe, vida, reloj +30 s |
| Liana de repaso | cerca del árbol 6 | ~20 s | gema 1 |
| Salida secreta | rama sobre la meta (col 408, fila 3) | ~25 s | casa 1-7 (bonus) |

### Enemigos y su función
- **Murciélago (col 120)**: protege el aterrizaje de la liana 1; castiga soltarse demasiado pronto.
- **Murciélago (col 300)**: vigila la salida de la ventana de la rama hueca; hace que el atajo no sea gratis.
- **Murciélago (col 360)**: sobre la última liana; examen final de timing.
- **Volador (col 190, hueco 3)**: pasa a media altura; obliga a esperar el momento de soltar.
- **Volador (col 310, hueco 5)**: mismo papel en el tramo siguiente, con la liana más larga.
No hay enemigos terrestres ni dentro de los troncos. 5 en total.

### Trampas
Ninguna; el reto es el vacío y el balanceo.

### Mecánica especial
**Lianas** (se agarran en el aire; SALTO suelta con la velocidad del balanceo), con una seta de apoyo.

### Llaves y cerraduras
| Llave | Dónde (libre) | Cerradura | Obligatoria |
|---|---|---|---|
| Llave A | nido de la ruta baja (col 245, fila 27) | Nido del pájaro (tronco 4) | No |
| Llave B | final de la rama hueca | Terraza del atardecer (puerta en la copa 5: 40 monedas y orbe de gigante) | No |
2 llaves para 2 cerraduras; ambas opcionales y libres.

### Secretos y recompensas
Gema 1 (liana de repaso) · gema 2 (despensa) · gema 3 (nido) · 2 orbes (barrera, gigante) · vida (nido) · 1 reloj +30 s en la rama hueca ·
**salida secreta** a la casa 1-7.

### Diferencias concretas respecto a los demás
- Único con **7 árboles como único apoyo**; casi todo el recorrido sin suelo, en altura 32.
- Su subsuelo es una **red de cavidades dentro de la madera** (troncos y una rama hueca de 56 celdas): vertical, horizontal y con bifurcación.
- Enemigos **solo aéreos y con funciones de timing**; no hay trampas.
- Las lianas son la mecánica; en 1-11 se encadenan en un abismo horizontal y aquí se mezclan con la seta y la subida.

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

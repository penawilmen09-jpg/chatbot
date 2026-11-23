# WILMEN WORLD · Bosque Esmeralda · 20 fichas de diseño (versión para revisión)

Estado: **solo diseño, ningún nivel construido todavía.** Los pasos A (puertas/túneles solo con SALTO) y B (enemigos y trampas
nuevos) ya están hechos y probados. Estas fichas sustituyen por completo a las anteriores: los 20 niveles se dibujan a mano,
uno por uno, **sin la biblioteca de piezas** con la que se hicieron los actuales.

## 0. Reglas que cumplirá cada nivel

1. **Estructura propia**: ningún par de niveles comparte el tipo de recorrido (ver la matriz del punto 2). Ningún par
   consecutivo se parece ni en estructura ni en mecánica principal.
2. **Túneles únicos**: cada túnel, cueva o habitación subterránea tiene su propia geometría, dimensiones y recorrido
   (largo/corto, horizontal/vertical, recto/en bifurcación, con trampas o sin ellas). Ninguna sala se repite con otro color.
3. **Enemigos por comportamiento, no por aspecto**: cada nivel usa un conjunto de comportamientos distinto y los coloca según
   el escenario (no hay "un enemigo cada X columnas").
4. **Mecánicas**: cada una debuta en un nivel que la enseña y vuelve después con otro uso. No hace falta usarlas todas en todos.
5. **Altura y longitud variables**: de 20 a 32 filas; de 340 a 900 columnas según el diseño. Los tiempos se ajustan al nivel.
6. **Conservado**: reloj con cuenta atrás (a cero muere y pierde una vida), vidas, puntos de control, monedas, 3 gemas por nivel,
   llaves y guardado. Entrada a puertas/túneles **solo con SALTO**.
7. **Justo y completable**: dificultad creciente. Un nivel solo se da por terminado si (a) el validador lo da por completable,
   (b) sus mecánicas se prueban en el motor y (c) la comparación con los demás niveles confirma que es distinto.
   Las gemas más difíciles nunca bloquean el avance.
8. Casillas del mapa que se respetan: 4 y 13 cuevas, 7 casa, 10 fortaleza, 19 ruta secreta, 20 castillo con jefe; salidas
   secretas en 5, 9, 13 y 19.

## 1. Banco de piezas disponibles

- **Mecánicas (tanda 0)**: setas, lianas, troncos rodantes, plataformas que desaparecen, puentes derrumbables, interruptores y
  bloques conmutables, corrientes de agua y burbujas, dardos, péndulos, plataformas orbitales, ascensores.
- **Del juego original (ya existentes)**: plataformas móviles, resortes, plataformas que se desmoronan, carritos mineros,
  perseguidor (roca que rueda), bloques ocultos y habitaciones secretas.
- **Enemigos**: caminante (patrulla y persigue), pinchudo (no se pisa), saltarín, volador, disparador; **nuevos**: topo
  (emerge del suelo), guardián (escudo y carga), murciélago (pica desde el techo), lanzarrocas (parábola). Prensas.

## 2. Matriz de comparación

| # | Nombre | Tipo | Tamaño | Estructura | Mecánica principal | Familia de enemigos | Trampas | Túnel |
|---|---|---|---|---|---|---|---|---|
| 1 | Sendero del Amanecer | normal | 520×20 | colinas horizontales | setas | caminante, saltarín | ninguna | corto con llave |
| 2 | Garganta de las Cascadas | normal | 360×32 | ascenso vertical | corrientes y burbujas | volador, disparador | pinchos | pozo vertical |
| 3 | Puente de los Mil Pasos | normal | 820×22 | puentes sin suelo | puentes y plataformas que desaparecen | murciélago, volador | dardos | trampa horizontal bajo el abismo |
| 4 | Cueva de las Raíces | cueva | 560×28 | red de salas | interruptores | topo, lanzarrocas | pinchos | salas con bifurcación |
| 5 | Copas Altas | normal | 420×32 | árboles gigantes | lianas | murciélago, volador | – | hueco del tronco |
| 6 | Pantano Hundido | normal | 680×20 | doble nivel (alto/inundado) | corrientes + troncos | topo, saltarín, disparador | troncos | tubería hundida |
| 7 | Aserradero del Leñador | casa | 380×30 | edificio de 3 pisos | ascensores | guardián | prensas | conductos de la fábrica |
| 8 | Salto del Duende | normal | 340×32 | descenso | burbujas como freno | murciélago, volador | pinchos, desmoronables | cueva tras la cascada |
| 9 | Templo de los Tres Sellos | normal | 600×26 | templo con ruinas | interruptores + trampas | guardián, disparador | dardos, péndulos | pasadizos secretos |
| 10 | Fortaleza de Raíces | fortaleza | 640×30 | patio y torres | ascensores + orbitales | guardián, lanzarrocas | prensas | cámara de llaves |
| 11 | Abismo de las Lianas | normal | 700×24 | lianas encadenadas | lianas | volador, saltarín | péndulos | sin túneles (cuevas colgantes) |
| 12 | Claro de las Setas | normal | 480×32 | pinball vertical | setas + diagonales | saltarín, lanzarrocas | desaparecen | tobogán interior |
| 13 | Mina Abandonada | cueva | 620×26 | galerías con carritos | carritos + desmoronables | pinchudo, murciélago, topo | prensas | galerías en bifurcación |
| 14 | Colina de los Búhos | normal | 520×30 | espiral alrededor de una colina | caminos superior e inferior | murciélago, guardián, lanzarrocas | rocas rodantes | túnel espiral |
| 15 | Río Bifurcado | normal | 780×22 | dos ríos que se separan | corrientes + orbitales | caminante, disparador | troncos | cruces bajo el agua |
| 16 | Bosque Nocturno | normal | 900×20 | persecución | perseguidor | volador, murciélago | dardos | atajos de huida |
| 17 | Sendero de Espinas | normal | 560×28 | carrera de precisión | plataformas diminutas | pinchudo, saltarín, lanzarrocas | prensas, dardos, desaparecen | cámara cerrada |
| 18 | Árbol Milenario | normal | 400×32 | espiral interior | interruptores + ascensor | topo, guardián, murciélago | péndulos | raíces → copa |
| 19 | Camino de los Susurros | secreta | 640×26 | laberinto de rutas | interruptores encadenados | guardián (silencioso) | suelos que desaparecen | bucles |
| 20 | Castillo del Guardián | castillo | 700×24 | castillo + jefe | todas, a modo de repaso | mezcla | todas | llave del jefe |

---

## 3. Fichas

### 1-1 · Sendero del Amanecer (tanda 1) — *aprende a moverte y a rebotar*
- **Tema visual**: claro al amanecer, niebla baja, luz dorada entre los árboles.
- **Terreno**: 520×20. Colinas suaves que suben y bajan, **sin fosos** en la primera mitad; sólo claros largos y pequeños desniveles.
  Segunda mitad con tres fosos cortos.
- **Mecánica principal (debut)**: **setas**. Primero una vertical que sube a una repisa con monedas; después una diagonal para
  cruzar el primer foso; al final dos setas encadenadas que lanzan a la meta alta.
- **Enemigos**: caminante (patrulla y persigue), saltarín (primer encuentro en el foso). Ninguno más.
- **Trampas**: ninguna (es el nivel de aprendizaje).
- **Rutas**: abajo, el camino fácil por los claros; arriba, la ruta de repisas con setas (monedas y la 2ª gema).
- **Túneles/puertas**: un túnel **corto** (boca-sala-boca) bajo una colina con la llave; una puerta de piedra más adelante.
- **Habitación secreta**: una cámara bajo el árbol hueco con 10 monedas (se entra por SALTO en una boca escondida).
- **Recompensas**: 3 gemas (visible en la ruta alta, tras la seta diagonal, en la cámara secreta), 1 llave, 1 reloj +15 s.
- **Dificultad**: 1/5. Tiempo 300 s.

### 1-2 · Garganta de las Cascadas (tanda 1) — *aprende a leer el agua*
- **Tema visual**: garganta de roca húmeda con tres cascadas en cadena y arcoíris.
- **Terreno**: 360×32 (nivel vertical). Se asciende por repisas escalonadas pegadas a las paredes; no hay suelo continuo.
- **Mecánica principal (debut)**: **corrientes de agua y burbujas** (columnas de burbujas que elevan; corrientes laterales
  que empujan hacia el vacío) más **plataformas móviles** verticales.
- **Enemigos**: voladores (en las columnas de aire), disparador en una repisa. Ningún enemigo de suelo.
- **Trampas**: pinchos al pie de cada cascada.
- **Rutas**: por la izquierda, burbujas (rápida pero con voladores); por la derecha, repisas y móviles (lenta y segura).
- **Túneles/puertas**: un **pozo vertical** dentro de la roca (subida de 14 celdas con salientes alternos) que une la
  zona baja con la media; una puerta con llave tras la segunda cascada.
- **Habitación secreta**: la cueva detrás de la primera cascada (se entra por una boca oculta tras el agua).
- **Recompensas**: 3 gemas (una en cada cascada), 1 llave, 1 reloj.
- **Dificultad**: 1-2/5. Tiempo 330 s.

### 1-3 · Puente de los Mil Pasos (tanda 1) — *aprende a no detenerte*
- **Tema visual**: abismo de niebla con puentes de cuerda y madera entre torres de roca.
- **Terreno**: 820×22. **No hay suelo continuo**: pilares de roca separados por precipicios de distintos anchos.
- **Mecánica principal (debut)**: **puentes que se derrumban** (cruzarlos sin parar) y **plataformas que desaparecen**
  (cadenas con ritmo) cuando falta el puente.
- **Enemigos**: murciélagos colgados de los arcos de roca, voladores cerca de los puentes largos.
- **Trampas**: dardos en el túnel bajo el abismo; el vacío es la trampa principal.
- **Rutas**: arriba, los puentes (rápido, arriesgado: se caen); abajo, un camino por pasarelas de madera con desaparecer.
- **Túneles/puertas**: un **túnel horizontal largo** (60 celdas) bajo el abismo con dardos alternados, que permite saltarse
  los puentes 2 y 3; una puerta con llave en el pilar final.
- **Habitación secreta**: una cámara sobre un arco de roca, accesible sólo desde un puente que se derrumba rápido.
- **Recompensas**: 3 gemas (puente 2, túnel inferior, cámara), 1 llave, 1 reloj +30 s.
- **Dificultad**: 2/5. Tiempo 360 s.

### 1-4 · Cueva de las Raíces (tanda 1, cueva) — *aprende a cambiar el escenario*
- **Tema visual**: cueva de raíces gigantes con hongos luminosos y gotas de agua.
- **Terreno**: 560×28. **Red de 6 salas** a distintas alturas unidas por pasillos de formas diferentes (sala-embudo, sala con
  columnas, galería inclinada, cámara circular). Techo continuo.
- **Mecánica principal (debut)**: **interruptores y bloques conmutables**: raíces que cierran un pasillo y abren otro;
  hay que alternar el interruptor para abrir el camino correcto.
- **Enemigos**: topos (emergen del suelo de las salas), lanzarrocas desde repisas altas.
- **Trampas**: pinchos en el suelo de la sala de columnas.
- **Rutas**: dos ramas tras la sala 3 (una por arriba con lanzarrocas, otra por abajo con topos) que se juntan en la sala 5.
- **Túneles/puertas**: el propio sistema de cuevas son los túneles; una **bifurcación** de tres bocas; una puerta con llave
  hacia la sala del tesoro.
- **Habitación secreta**: la sala 6, sólo se abre si se deja el interruptor en una posición concreta.
- **Recompensas**: 3 gemas (una por cada rama y una en la sala secreta), 1 llave, 2 relojes.
- **Dificultad**: 2-3/5. Tiempo 360 s.

### 1-5 · Copas Altas (tanda 1, salida secreta → casa 1-7) — *aprende a balancearte*
- **Tema visual**: copas de árboles gigantes sobre un mar de nubes, atardecer.
- **Terreno**: 420×32. Sube por ramas y troncos; el "suelo" son ramas anchas, con vacíos entre las copas.
- **Mecánica principal (debut)**: **lianas** (balanceo real) para pasar de un árbol a otro, con una seta que lanza a la copa.
- **Enemigos**: murciélagos en las ramas altas, voladores que cruzan entre árboles.
- **Trampas**: ninguna aparte del vacío (el reto es la liana).
- **Rutas**: ruta baja por ramas gruesas (más lenta, 3 saltos largos), ruta alta por lianas (más rápida).
- **Túneles/puertas**: un **hueco dentro de un tronco** (vertical, 8 celdas) que sube de una rama baja a una alta con una puerta con llave.
- **Habitación secreta**: la **salida secreta**: una rama por encima de la meta, sólo alcanzable con una liana larga.
- **Recompensas**: 3 gemas (en puntos altos de lianas), 1 llave, salida secreta a la casa 1-7.
- **Dificultad**: 3/5. Tiempo 330 s.

### 1-6 · Pantano Hundido (tanda 2) — *camino alto o camino inundado*
- **Tema visual**: pantano verde oscuro con nenúfares y niebla.
- **Terreno**: 680×20 en **dos capas**: troncos y plataformas altas / un lecho inundado con corriente.
- **Mecánica principal**: **corrientes laterales** combinadas con **troncos rodantes** que bajan por los desniveles.
- **Enemigos**: topos (emergen del barro), saltarines (ranas), disparadores sobre cañas.
- **Trampas**: troncos que ruedan; zonas sin apoyo.
- **Rutas**: arriba por las plataformas (más segura), abajo por el lecho inundado (más corta, con corriente).
- **Túneles/puertas**: una **tubería hundida** (túnel horizontal inclinado, 30 celdas) que cruza el pantano bajo el agua.
- **Habitación secreta**: una choza flotante con un cofre, accesible por la ruta inundada.
- **Recompensas**: 3 gemas, 1 llave, 1 reloj. **Dificultad**: 3/5. Tiempo 380 s.

### 1-7 · Aserradero del Leñador (tanda 2, casa/bonus) — *sala de tesoros con mecanismos*
- **Tema visual**: interior de madera con engranajes, sierras decorativas y vigas.
- **Terreno**: 380×30. **Edificio de 3 pisos** unidos por ascensores.
- **Mecánica principal**: **ascensores**, con **prensas** y troncos en cintas.
- **Enemigos**: guardianes (leñadores acorazados); no hay enemigos voladores.
- **Trampas**: prensas.
- **Rutas**: piso medio o piso alto (llegan al mismo despacho).
- **Túneles/puertas**: **conductos de la fábrica** (túnel de 18 celdas con curvas) que conectan los pisos; puerta del despacho con llave.
- **Habitación secreta**: el sótano de la sierra.
- **Recompensas**: bonus (muchas monedas), 3 gemas, 1 llave, 2 relojes. **Dificultad**: 2/5 (es de bonus). Tiempo 420 s.

### 1-8 · Salto del Duende (tanda 2) — *descenso*
- **Tema visual**: cascada enorme que cae a una poza con niebla.
- **Terreno**: 340×32. **Se baja** desde lo alto de la cascada hasta la poza.
- **Mecánica principal**: **burbujas como freno** (columnas que frenan la caída) y plataformas desmoronables.
- **Enemigos**: murciélagos, voladores.
- **Trampas**: pinchos al pie y desmoronables.
- **Rutas**: por la izquierda, caída libre con frenos; por la derecha, escalones con desmoronables.
- **Túneles/puertas**: **cueva tras la cascada** (3 salas, geometría en L) con la llave.
- **Habitación secreta**: cámara bajo la poza.
- **Recompensas**: 3 gemas, 1 llave, 1 reloj. **Dificultad**: 3/5. Tiempo 300 s.

### 1-9 · Templo de los Tres Sellos (tanda 2, salida secreta → 1-15) — *puzle de ruinas*
- **Tema visual**: ruinas de templo cubiertas de hiedra.
- **Terreno**: 600×26. Salas de templo con **plataformas de piedra y escalinatas**.
- **Mecánica principal**: **interruptores y bloques**: hay 3 sellos que abrir en orden.
- **Enemigos**: guardianes, disparadores.
- **Trampas**: dardos en los pasillos, **péndulos** en la sala del ídolo.
- **Rutas**: el orden de los sellos es libre; dos salas son opcionales.
- **Túneles/puertas**: **pasadizos secretos** entre las salas (3 túneles de longitudes distintas).
- **Habitación secreta**: la cámara del ídolo con la **salida secreta**.
- **Recompensas**: 3 gemas, 1 llave, salida secreta → 1-15. **Dificultad**: 3-4/5. Tiempo 400 s.

### 1-10 · Fortaleza de Raíces (tanda 2, fortaleza) — *patio y torres*
- **Tema visual**: fortaleza de raíces enredadas y piedra.
- **Terreno**: 640×30. Patio central y **dos torres** que se recorren en vertical.
- **Mecánica principal**: **ascensores y plataformas orbitales**.
- **Enemigos**: guardianes, lanzarrocas en las almenas.
- **Trampas**: prensas en el puente levadizo.
- **Rutas**: torre izquierda o derecha (cada una da una llave; hacen falta 2).
- **Túneles/puertas**: **cámara de llaves** con puerta doble; pasadizo entre torres.
- **Habitación secreta**: la armería.
- **Recompensas**: 3 gemas, **2 llaves**, 1 reloj. **Dificultad**: 4/5. Tiempo 420 s.

### 1-11 · Abismo de las Lianas (tanda 3) — *balanceo encadenado*
- **Tema visual**: selva alta con raíces colgantes sobre un abismo.
- **Terreno**: 700×24. Plataformas pequeñas separadas por huecos que sólo se cruzan **balanceándose**.
- **Mecánica principal**: **lianas encadenadas** y péndulos.
- **Enemigos**: voladores, saltarines.
- **Trampas**: péndulos entre liana y liana.
- **Rutas**: dos cadenas de lianas (alta y baja) que se cruzan.
- **Túneles/puertas**: **cuevas colgantes** (2 salas) con la llave.
- **Habitación secreta**: una plataforma sobre las lianas con 3 vidas extra.
- **Recompensas**: 3 gemas, 1 llave. **Dificultad**: 3-4/5. Tiempo 340 s.

### 1-12 · Claro de las Setas (tanda 3) — *pinball vertical*
- **Tema visual**: claro con setas gigantes y esporas.
- **Terreno**: 480×32. Se sube por **rebotes**.
- **Mecánica principal**: **setas verticales y diagonales** encadenadas.
- **Enemigos**: saltarines, lanzarrocas.
- **Trampas**: plataformas que desaparecen.
- **Rutas**: tres caminos de rebote con distinta altura.
- **Túneles/puertas**: **tobogán interior** (túnel que baja en espiral).
- **Habitación secreta**: gruta bajo la seta mayor.
- **Recompensas**: 3 gemas, 1 llave. **Dificultad**: 3/5. Tiempo 330 s.

### 1-13 · Mina Abandonada (tanda 3, cueva, salida secreta → 1-19)
- **Tema visual**: mina de madera y raíles, linternas.
- **Terreno**: 620×26. **Galerías** a varias alturas conectadas por vías.
- **Mecánica principal**: **carritos mineros** y **plataformas que se desmoronan**.
- **Enemigos**: pinchudos, murciélagos, topos.
- **Trampas**: prensas, vías rotas.
- **Rutas**: galería superior o inferior.
- **Túneles/puertas**: **galerías en bifurcación** (4 bocas); pozo de ascensor roto.
- **Habitación secreta**: sala de dinamita con la **salida secreta**.
- **Recompensas**: 3 gemas, 1 llave, salida secreta → 1-19. **Dificultad**: 4/5. Tiempo 380 s.

### 1-14 · Colina de los Búhos (tanda 3) — *espiral*
- **Tema visual**: colina rocosa con búhos de piedra.
- **Terreno**: 520×30. Un camino **en espiral** alrededor de una colina.
- **Mecánica principal**: **camino superior e inferior** (el segundo, más corto, con rocas).
- **Enemigos**: murciélagos, guardianes, lanzarrocas.
- **Trampas**: rocas rodantes.
- **Rutas**: espiral exterior o atajos por dentro.
- **Túneles/puertas**: **túnel en espiral** interior.
- **Habitación secreta**: mirador de la cima.
- **Recompensas**: 3 gemas, **2 llaves**. **Dificultad**: 3-4/5. Tiempo 380 s.

### 1-15 · Río Bifurcado (tanda 3) — *dos ríos*
- **Tema visual**: río que se parte en dos brazos y se vuelve a unir.
- **Terreno**: 780×22. Los brazos tienen estructura distinta.
- **Mecánica principal**: **corrientes** y **plataformas orbitales** como balsas.
- **Enemigos**: caminantes, disparadores.
- **Trampas**: troncos.
- **Rutas**: brazo norte (aéreo) o sur (a ras de agua).
- **Túneles/puertas**: **cruces bajo el agua**.
- **Habitación secreta**: isla central.
- **Recompensas**: 3 gemas, 1 llave. **Dificultad**: 4/5. Tiempo 360 s.

### 1-16 · Bosque Nocturno (tanda 4) — *persecución*
- **Tema visual**: bosque de noche, luciérnagas, una roca gigante te persigue.
- **Terreno**: 900×20. Larga carrera con obstáculos.
- **Mecánica principal**: **perseguidor** (la roca) y saltos continuos.
- **Enemigos**: voladores, murciélagos.
- **Trampas**: dardos.
- **Rutas**: una principal y atajos de huida.
- **Túneles/puertas**: túneles cortos de escape.
- **Habitación secreta**: refugio al final de un atajo.
- **Recompensas**: 3 gemas, 1 llave. **Dificultad**: 4/5. Tiempo 300 s.

### 1-17 · Sendero de Espinas (tanda 4) — *precisión*
- **Tema visual**: matorral de espinas.
- **Terreno**: 560×28. **Plataformas diminutas** sobre un mar de espinas.
- **Mecánica principal**: **precisión** (plataformas pequeñas, que desaparecen).
- **Enemigos**: pinchudos, saltarines, lanzarrocas.
- **Trampas**: prensas, dardos, desaparecen.
- **Rutas**: dos rutas de precisión de distinta longitud.
- **Túneles/puertas**: **cámara cerrada** con llave.
- **Habitación secreta**: nido de espinas.
- **Recompensas**: 3 gemas, 1 llave. **Dificultad**: 4-5/5. Tiempo 330 s.

### 1-18 · Árbol Milenario (tanda 4) — *espiral interior*
- **Tema visual**: interior de un árbol hueco gigante.
- **Terreno**: 400×32. **Espiral** que sube por dentro.
- **Mecánica principal**: **interruptores y ascensor**.
- **Enemigos**: topos, guardianes, murciélagos.
- **Trampas**: péndulos.
- **Rutas**: espiral interior o ramas exteriores.
- **Túneles/puertas**: **raíces → copa**.
- **Habitación secreta**: la cámara del corazón del árbol.
- **Recompensas**: 3 gemas, 1 llave. **Dificultad**: 4-5/5. Tiempo 360 s.

### 1-19 · Camino de los Susurros (tanda 4, nivel secreto)
- **Tema visual**: sendero niebla morada.
- **Terreno**: 640×26. **Laberinto de rutas**.
- **Mecánica principal**: **interruptores encadenados** y suelos que desaparecen.
- **Enemigos**: guardián silencioso (casi sin enemigos).
- **Trampas**: suelos que desaparecen.
- **Rutas**: tres, con bucles.
- **Túneles/puertas**: **bucles** entre rutas.
- **Habitación secreta**: la sala de los susurros.
- **Recompensas**: 3 gemas, **2 llaves**. **Dificultad**: 4/5. Tiempo 360 s.

### 1-20 · Castillo del Guardián (tanda 4, castillo + jefe)
- **Tema visual**: castillo de raíces y piedra.
- **Terreno**: 700×24, con arena final.
- **Mecánica principal**: repaso de todas las mecánicas.
- **Enemigos**: mezcla, y el **jefe de varias fases**.
- **Trampas**: todas, escalonadas.
- **Rutas**: una principal y una opcional.
- **Túneles/puertas**: llave del jefe.
- **Habitación secreta**: armería.
- **Recompensas**: 3 gemas, 1 llave. **Dificultad**: 5/5. Tiempo 360 s.

---

## 4. Cómo se comprobará que son distintos

- **Vista previa conjunta** de los niveles de cada tanda (y al final de los 20) para comparar estructuras a simple vista.
- **Medidas automáticas**: perfil de altura, mapa de enemigos por columna, tipos de trampas y geometría de cada túnel; se
  rechaza cualquier par de niveles que coincida en demasiado.
- **Pruebas de motor** de cada mecánica usada y **recorrido real** de cada nivel con un jugador virtual donde sea posible.
- **Pruebas del juego original** y de su guardado en cada entrega.

## 5. Tandas
- **Tanda 1 (1-1…1-5)**: se construyen tras tu aprobación de estas fichas. Enseñan setas, corrientes, puentes/desaparecer,
  interruptores y lianas.
- **Tanda 2 (1-6…1-10)**, **Tanda 3 (1-11…1-15)**, **Tanda 4 (1-16…1-20)**: no se empiezan sin tu aprobación.

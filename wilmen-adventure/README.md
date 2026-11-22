# WILMEN ADVENTURE

Juego de plataformas 2D de 16 bits para **Android** hecho con **Godot 4.3 y GDScript**.
100 niveles, 10 mundos, 10 jefes, 10 poderes, guardado automático. Funciona sin Internet, sin
anuncios y sin compras. Todo el arte y el audio son originales y se generan con los scripts de
`tools/` (no hay recursos externos).

## Versión 2.0: 100 niveles, 10 mundos

| Mundo | Niveles | Jefe | Poder | Mecánicas propias |
|---|---|---|---|---|
| 1 Bosque Esmeralda | 1-10 | Rey Tronco | Chispa Esmeralda | resortes, bloques ocultos |
| 2 Cuevas de Cristal | 11-20 | Golem de Cristal | Impulso de Cristal | túneles, ascensores, plataformas móviles |
| 3 Desierto Perdido | 21-30 | Rey Escarabajo | Escudo Solar | fosos anchos, pinchos |
| 4 Reino de Hielo | 31-40 | Yeti Gélido | Aliento Helado | suelo resbaladizo |
| 5 Castillo de las Sombras | 41-50 | Señor de las Sombras | Paso Sombrío | lava |
| 6 Islas Voladoras | 51-60 | Águila Tormenta | Ráfaga Celeste | corrientes de viento, islas, plataformas frágiles |
| 7 Reino Volcánico | 61-70 | Dragón de Magma | Llamarada | géiseres de lava, lava |
| 8 Jungla Salvaje | 71-80 | Gorila Ancestral | Salto Salvaje | barro, plataformas frágiles |
| 9 Mundo Mecánico | 81-90 | Coloso Mecánico | Pulso Eléctrico | cintas transportadoras, prensas |
| 10 Reino Final | 91-100 | Emperador del Vacío | Nova Final | todas las anteriores |

En cada mundo: niveles 1-9 normales (el **7 es una cámara secreta** con tesoro y música propia) y el **10 es el jefe**.
Los 20 niveles de la versión 1 se conservan íntegros: son los niveles 1-3 y 10 de los mundos 1-5.

**Desbloqueo (sin pagos ni anuncios).** Partida nueva: solo el nivel 1. El nivel *n+1* se abre únicamente cuando
**todos** los niveles 1..n están completados (llegar a la meta). Se valida en tres sitios: el mapa
(`Game.start_level()`), el botón *Siguiente* y la propia escena del nivel (`level.gd` rechaza cargar un nivel
bloqueado aunque se abra directamente). Perder no desbloquea nada. Se guarda automáticamente.

**Migración del guardado.** Un guardado de la versión 1 (20 niveles) se convierte solo al primer arranque
(copia de seguridad en `wilmen_save_v1_backup.json`): los niveles completados, gemas, puntuaciones, vidas y
ajustes se conservan. Como los niveles nuevos (4-9 de cada mundo) no se habían jugado, el desbloqueo consecutivo
te devuelve a ellos; tus niveles antiguos siguen marcados como completados y se rejuegan cuando los alcances.

**Recompensas de mundo.** Derrotar al jefe por primera vez: +3 vidas y +5000 puntos.

**Música (31 pistas originales sintetizadas).** Una canción principal por mundo (10), una alternativa por mundo
para los niveles 5-9 (10), música secreta (niveles x7), de castillo (niveles 6-9 de los mundos 5 y 10),
4 de jefe (mundos 1-3, 4-6, 7-9 y final), victoria de nivel, victoria de mundo, derrota, mapa y título.
Cambian solas con fundido cruzado (crossfade). Volumen y silencio independientes para música y efectos
(Opciones y menú de pausa).

## Estado de las pruebas

Todas se ejecutan **dentro de Godot 4.3 (headless)** en GitHub Actions (`.github/workflows/wilmen-android-apk.yml`):

- Validación de los 100 niveles (`python3 tools/levelgen.py --check`): inicio→meta y 3 gemas alcanzables, sin duplicados.
- `tests/smoke_test.gd`: recursos y audio, ausencia de red, desbloqueo (partida nueva, carga directa de niveles
  bloqueados, completar/saltar/perder), migración y persistencia, carga de los 100 niveles, música por mundo y
  de jefe, los 10 jefes completos, mecánicas nuevas, enemigos, poderes, menús y un bot.
- `tests/persist_write.gd` + `tests/persist_check.gd`: dos procesos de Godot distintos (cerrar y abrir el juego).
- Tras exportar: el APK se firma, se comprueba su firma y que **no** pide el permiso INTERNET.

No se puede probar automáticamente: la sensación de juego (dificultad, saltos, jefes), cómo suena la música,
la respuesta de los botones táctiles en un móvil real ni la instalación del APK en un dispositivo.

## Cómo abrirlo y jugar en el ordenador

1. Instala [Godot 4.3](https://godotengine.org/download) (versión estándar, no .NET).
2. Abre Godot → **Importar** → selecciona `wilmen-adventure/project.godot`.
3. Espera a que importe los recursos y pulsa **F5**.

Controles de teclado: flechas o **A/D** mover · **Espacio / W / Z** saltar (pulsa otra vez en el aire para
el doble salto) · **X / Shift / K** poder · **Esc / P** pausa. También funciona un mando.
Los botones táctiles aparecen solos en móviles; en el ordenador se activan en Opciones → Controles táctiles.

## Probar en el motor

```bash
godot --headless --path wilmen-adventure --import
godot --headless --path wilmen-adventure --script res://tests/smoke_test.gd
godot --headless --path wilmen-adventure --script res://tests/persist_write.gd
godot --headless --path wilmen-adventure --script res://tests/persist_check.gd
```
(o `tests/run_all.sh`; imprime `ok`/`FALLO` y devuelve código 0/1).

## Crear el APK

### Opción A – En tu ordenador (Godot)
1. Instala Godot 4.3 y, desde **Editor → Administrar plantillas de exportación**, las plantillas 4.3.
2. Instala **JDK 17** y el **Android SDK** (lo más fácil: Android Studio; necesitas *platform-tools*,
   *build-tools 34.0.0* y *platform android-34*).
3. **Editor → Ajustes del editor → Exportar → Android**: indica la ruta del SDK, la del JDK y un
   *debug keystore* (puedes crearlo con
   `keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12`).
4. **Proyecto → Exportar…** → preset *Android* (ya está configurado en `export_presets.cfg`) → **Exportar proyecto**.
   Paquete: `com.wilmen.adventure`, orientación horizontal (sensor), arm64 + armeabi-v7a.
5. Para publicar en Google Play necesitas una clave de firma propia (release) y exportar AAB; no se incluye ninguna clave en el repositorio.

### Opción B – Con GitHub Actions (recomendada)
Cada *push* que cambie `wilmen-adventure/` (o *Actions → Run workflow*) valida los niveles, ejecuta las pruebas en
Godot y, si pasan, exporta un **APK release** firmado y lo publica como artefacto `WilmenAdventure-APK-2.0.N`.
El *version code* sube solo (100 + nº de ejecución) y la clave de firma es siempre la misma (`android/README.md`),
así que cada APK nuevo se instala encima del anterior. Para Google Play usa tu propia clave (ver `android/README.md`).

## Estructura

```
project.godot          configuración (480x270 base, horizontal, renderer Compatibility)
export_presets.cfg     preset de exportación a Android
autoload/              Game (estado y guardado), Audio, Transition (fundidos)
characters/player/     Wilmen
enemies/               enemigos y jefes
items/                 monedas, gemas, bloques, resortes, meta, checkpoints, proyectiles, plataformas
levels/                level.gd (un único script construye los 20 niveles) y levels/data/*.txt (mapas)
ui/                    título, selección de nivel, HUD, botones táctiles multitáctiles, final
assets/                pixel art generado (PNG)       audio/   música (OGG) y efectos (WAV)
tools/                 generadores de arte, audio y niveles + validador + vista previa
tests/                 prueba de humo para Godot
```

## Regenerar o editar contenido

```bash
pip install pillow numpy soundfile
python3 tools/gen_art.py              # arte
python3 tools/gen_audio.py            # música y efectos
python3 tools/levelgen.py             # regenera y valida los 20 niveles (sobrescribe levels/data)
python3 tools/levelgen.py --check     # valida los niveles editados a mano
python3 tools/preview_level.py 7      # dibuja el nivel 7 en un PNG
```

Los niveles son texto plano (ver `levels/README.md`): puedes retocarlos a mano y validarlos.

### Sobre el validador de niveles
`levelgen.py` comprueba, con un modelo de saltos **conservador** (salto simple ≈ 3 casillas de altura y 4 de
longitud; doble salto ≈ 5 y 7), que desde el inicio se llega a la meta y a las 3 gemas, y que un hueco de 7
casillas o una pared de 8 se detectan como imposibles. Es una aproximación de la física real de Godot,
no una simulación exacta; la comprobación definitiva es jugar cada nivel.

## Guardado, desbloqueo y pruebas (v2.0 final)

- **Guardado** (`user://wilmen_save.json`, formato v3): lista explícita de niveles abiertos (`unlocked`) que solo crece.
  Rejugar un nivel solo fusiona gemas/mejor puntuación; nunca cierra niveles posteriores. Escritura atómica con `.bak`,
  copia automática de seguridad antes de migrar (`_v1_backup`, `_v2_backup`), claves desconocidas conservadas.
  En Opciones: **Copiar mi partida** / **Restaurar** (texto `WILMEN-SAVE:...` en el portapapeles) y **Borrar** (guarda copia antes).
- **Desbloqueo**: solo el nivel 1 en partida nueva; completar el nivel n abre el n+1. Se valida en el mapa, en `Game.start_level()` y al cargar la escena.
- **Congelamiento al elegir niveles anteriores**: un tween en bucle creado en el mapa apuntaba a botones liberados al cambiar de mundo/escena.
  Ahora el tween pertenece al botón (`b.create_tween()`). `tests/flow_test.gd` recorre el flujo real (16 ciclos de repetición, 50 cambios de mundo).
- **Franja negra**: el parallax no cubría el viewport ampliado (`expand`) y `Camera2D.offset` saltaba los límites; ver `levels/parallax_bg.gd`.
- **Pruebas** (CI): `tests/smoke_test.gd`, `tests/persist_*.gd`, `tests/flow_test.gd`, `tests/render_test.gd` (11 resoluciones, rotación, redimensionado en vivo).
- **Compilaciones**: APK (pruebas) y AAB (Google Play) como artefactos de GitHub Actions; la clave de firma de prueba está en `android/`.

## Gran expansión (v2.1)

Todo se consigue jugando; no hay compras ni anuncios y funciona sin Internet. El progreso nuevo vive en la clave `ext`
del mismo guardado (`autoload/progress.gd`); una partida anterior (sin `ext`) carga intacta y se amplía sola.

- **Tesoros**: cofres normal / raro / especial / secreto (`N R E Z` en los niveles), gemas especiales (`J`), botín
  guardado por nivel y número (`Progress.treasures`). Un cofre abierto no vuelve a dar nada.
- **Habitaciones secretas** (`tools/secrets_pass.py`): paredes falsas (`Y`), puertas secretas (`D`), bóvedas selladas con
  ladrillos (`B`) cuya llave es un orbe gigante, y sótanos con trampilla. Se descubren al atravesarlas y se guardan.
- **Poderes temporales** (orbes `e i k l q`, cofres): Fuego, Hielo, Electricidad (con relámpagos entre enemigos), Escudo
  protector (resiste un golpe) y Gigante (más grande y fuerte; daña al jefe una sola vez por transformación).
  Cada uno con sonido, aura y efecto propios.
- **Vehículos** (`V` + estación `y`): carrito minero, barco, plataforma voladora y mecha (`items/vehicle.gd`), con los
  mismos botones táctiles; y **persecuciones** (`r` + `y`, `items/chaser.gd`). Todos los tramos se pueden cruzar a pie.
- **Personalización**: 8 trajes, 10 sombreros, 5 armaduras, 6 efectos y 3 apariencias especiales (`Extras > Vestuario`).
- **Misiones y logros**: sin daño, 3 gemas y contrarreloj por nivel; 25 logros; pantalla de estadísticas.
- **Modos** (`Extras > Modos`, se abren con el progreso): contrarreloj, desafío (1 corazón), niveles bonus, supervivencia
  por oleadas y desafío de jefes (la vida del jefe no cambia). No tocan el progreso de la historia.
- **Recompensas por mundo completado**: un cosmético especial por cada mundo (`Progress.WORLD_COSMETICS`).

Herramientas: `gen_expansion.py` (arte), `gen_sfx2.py` (sonidos), `secrets_pass.py` / `vehicles_pass.py` (niveles).
Pruebas rápidas: `godot --headless --script res://tests/smoke_test.gd -- --exp` y `-- --exp2`.

## Anuncios recompensados (preparación, etapas 1-2: solo proveedor falso)

Estado: **desactivados**. `autoload/ads.gd` tiene `ADS_ENABLED = false`, no hay SDK, ni red, ni anuncios reales, y la
interfaz no muestra ningún botón de anuncios mientras no haya un proveedor activo.

- Opción A: en la pantalla «Sin vidas» (solo historia) aparece «Ver anuncio y obtener +1 vida». Si el anuncio se completa,
  el jugador recibe exactamente 1 vida y continúa desde el último punto de control. Es voluntario y sin límite.
  Cerrar el anuncio antes, un fallo, falta de carga o de confirmación no dan nada. Un identificador por petición impide
  que un callback repetido dé más de una vida.
- Banner: solo en el menú principal (lo enciende `title.gd` al entrar y lo apaga al salir). No hay intersticiales.
- No toca el guardado: lo único que cambia es `lives`, con `Game.add_life()`. Formato y claves de `wilmen_save.json` iguales.
- Proveedor de pruebas: `ads/mock_provider.gd`. En escritorio: `godot --path . -- --ads-mock` (o `WILMEN_ADS_MOCK=1`)
  muestra un cuadro «ANUNCIO DE PRUEBA» con «Ver completo», «Cerrar antes» y «Simular fallo», y un banner simulado.
- Pruebas: `godot --headless --path . --script res://tests/smoke_test.gd -- --ads` (también dentro de la batería completa).

## WILMEN WORLD (segundo modo, en desarrollo por hitos)

Un modo nuevo e **independiente** de WILMEN ADVENTURE, inspirado en la estructura de exploración de los juegos de plataformas
con mapa general (regiones, caminos, túneles, puertas, secretos y castillos), todo original. Se elige en el menú principal con
el botón «WILMEN WORLD». Plan: 6 regiones de 20 niveles (120), niveles largos, reloj con cuenta atrás, túneles y puertas con
llaves, 6 jefes principales y 3 secretos.

- **Hito 1 (hecho):** modo independiente, guardado propio, botón del menú y pantalla de inicio del modo.
- **Mapa explorable y región 1 (E1, hecha):** el botón del menú lleva a un mapa 2D con 6 regiones y los 120 niveles (`ui/ww_map.gd`, datos en `levels/world/map.json`): el héroe camina por los caminos, se abren rutas al completar niveles o encontrar salidas secretas, hay puentes, ríos, montañas, túneles, cuevas y castillos. La región 1 (Bosque Esmeralda) tiene sus 20 niveles reales (700-1000 columnas) y el jefe del castillo (`enemies/ww_boss.gd`, 3 fases); las regiones 2 a 6 se ven «en construcción».
- **Hito 2 (hecho):** reloj con cuenta atrás (a cero el personaje muere y pierde una vida), relojes de tiempo extra, túneles y
  puertas que llevan a otra zona del nivel, llaves, verjas y puertas con cerradura, formato de nivel ampliado
  (`levels/world/README.md`) y tres niveles largos de prueba jugables desde «ELEGIR NIVEL» en la pantalla del modo. Nivel
  nuevo: `levels/ww_level.gd` (reutiliza el nivel de WILMEN ADVENTURE) y `ui/ww_hud.gd`. Mientras se juega, la partida de
  WILMEN ADVENTURE se guarda en memoria y se restaura al salir (`Game.world_enter/world_leave`) y no se escribe nada en su archivo.
- **Partida propia:** `user://wilmen_world_save.json` (autoload `WW`, `autoload/ww.gd`). Monedas, gemas, vidas, llaves y
  progreso son del modo; **no** se lee ni se escribe `wilmen_save.json`, y `Game.save_game()` nunca escribe en el archivo de
  WILMEN WORLD. Solo se comparte (en lectura) la apariencia del héroe. `WW.save_game()` se niega a escribir sobre el archivo
  de WILMEN ADVENTURE.
- **Regiones:** Bosque Esmeralda, Desierto Dorado, Reino Volcánico, Reino Congelado, Océano Perdido, Reino de las Sombras.
- **Pruebas:** `godot --headless --path . --script res://tests/smoke_test.gd -- --ww` (también en la batería completa). Incluye una
  huella de los 100 niveles originales para detectar cualquier cambio accidental.

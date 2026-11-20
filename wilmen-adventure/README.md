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

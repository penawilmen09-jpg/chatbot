# WILMEN ADVENTURE

Juego de plataformas 2D de 16 bits para **Android** hecho con **Godot 4.3 y GDScript**.
20 niveles, 5 mundos, 5 jefes, 5 poderes, guardado automático. Funciona sin Internet, sin
anuncios y sin compras. Todo el arte y el audio son originales y se generan con los scripts de
`tools/` (no hay recursos externos).

## Estado honesto de este proyecto

| Qué | Estado |
|---|---|
| Sintaxis de los 23 scripts GDScript | Comprobada con `gdparse` (gramática de GDScript 4) |
| Rutas `res://`, escenas, sonidos y músicas referenciadas | Comprobadas por script: todas existen |
| 20 niveles: inicio → meta y las 3 gemas alcanzables | **Validado** con `tools/levelgen.py --check` (modelo de saltos conservador; ver abajo) |
| Fusión de colisiones del terreno | Probada con una réplica en Python sobre los 20 niveles |
| Arte (personaje, enemigos, jefes, tiles, fondos) | Generado y revisado visualmente en imágenes |
| **Ejecución dentro de Godot** | **NO probada**: el entorno donde se escribió no permitió ejecutar el motor |
| **Sensación de juego** (saltos, dificultad, jefes) | **NO probada**: hay que jugarlo y ajustar |
| **Música y efectos** | Generados y comprobados por código, **no escuchados** |
| **APK de Android / controles táctiles en un móvil** | **NO generado ni probado** |

Es decir: el proyecto está completo y preparado, pero es normal que la primera ejecución en Godot
destape algún error de ejecución o necesite ajustes. Para detectarlos rápido hay una prueba
automática dentro del motor (`tests/smoke_test.gd`, ver más abajo).

## Cómo abrirlo y jugar en el ordenador

1. Instala [Godot 4.3](https://godotengine.org/download) (versión estándar, no .NET).
2. Abre Godot → **Importar** → selecciona `wilmen-adventure/project.godot`.
3. Espera a que importe los recursos y pulsa **F5**.

Controles de teclado: flechas o **A/D** mover · **Espacio / W / Z** saltar (pulsa otra vez en el aire para
el doble salto) · **X / Shift / K** poder · **Esc / P** pausa. También funciona un mando.
Los botones táctiles aparecen solos en móviles; en el ordenador se activan en Opciones → Controles táctiles.

## Prueba automática en el motor

```bash
godot --headless --path wilmen-adventure --import
godot --headless --path wilmen-adventure --script res://tests/smoke_test.gd
```

Carga los 20 niveles, comprueba que cada uno tiene jugador, meta, 3 gemas (y jefe + puerta en los
niveles 4, 8, 12, 16 y 20) y deja correr un "bot" 8 segundos en el nivel 1. Devuelve código 0 si todo va bien.

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

### Opción B – Con GitHub Actions
El flujo `.github/workflows/wilmen-android-apk.yml` instala Godot, las plantillas y el SDK, ejecuta la
prueba de humo y exporta un APK de depuración como artefacto descargable. Se lanza desde la pestaña
**Actions → WILMEN ADVENTURE - APK de Android → Run workflow**. *(Escrito siguiendo la documentación
de Godot, pero no se ha ejecutado todavía.)*

## El juego

**Mundos y niveles** (x-4 es siempre un jefe):

| Mundo | Niveles | Jefe | Poder de Wilmen |
|---|---|---|---|
| 1 Bosque Esmeralda | Claro del Bosque · Sendero de las Raíces · Copas de los Árboles · Guarida del Rey Tronco | Rey Tronco | Chispa Esmeralda (proyectil que rebota) |
| 2 Cuevas de Cristal | Galería Brillante · Lago Subterráneo · Mina Abandonada · Corazón de Cristal | Golem de Cristal | Impulso de Cristal (embestida que rompe bloques) |
| 3 Desierto Perdido | Dunas Doradas · Oasis Espejismo · Ruinas de Arena · Tumba del Escarabajo | Rey Escarabajo | Escudo Solar (invulnerable 4 s) |
| 4 Reino de Hielo (suelo resbaladizo) | Llanura Helada · Cumbres Nevadas · Cavernas de Escarcha · Trono del Yeti | Yeti Gélido | Aliento Helado (congela enemigos) |
| 5 Castillo de las Sombras (lava) | Puente Sombrío · Salón de Antorchas · Torre del Vacío · El Señor de las Sombras | Señor de las Sombras | Paso Sombrío (teletransporte corto) |

**Sistemas**: movimiento con aceleración, salto de altura variable, *coyote time*, *jump buffer*, doble salto;
3 corazones por vida, vidas (se gana una cada 100 monedas), puntuación, 3 gemas por nivel, bloques de
ladrillo rompibles, bloques `?`, bloques de corazón, **bloques ocultos** (vida extra y monedas), nichos secretos,
resortes, plataformas móviles, pinchos, lava, puntos de control, meta. Enemigos: caminante (persigue sin
tirarse por los bordes), pinchudo (no se pisa), saltarín, volador y tirador, con el aspecto de cada mundo.
Cada jefe tiene 3-4 ataques propios y una fase 2 más rápida; si pierdes una vida el combate se reinicia.

**Guardado**: automático al completar un nivel, al volver al menú y al pasar la app a segundo plano
(`user://wilmen_save.json`: niveles desbloqueados, gemas, mejores puntuaciones, vidas, ajustes).

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

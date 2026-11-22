# Aventura 3D

Plataformas 3D con cámara lateral, estilo cartoon, hecho con **Godot 4.4.1 (GDScript)**.
Todo el contenido (personaje, escenario, controles) es original y se genera por código: no hay recursos de terceros.

> Estado: **Etapa 1** (proyecto, protagonista, movimiento, cámara, nivel de prueba, controles Android).

## Jugar en PC

1. Instala [Godot 4.4.1](https://godotengine.org/download/archive/4.4.1-stable/) (versión estándar, no .NET).
2. Abre la carpeta `aventura-3d/` desde el gestor de proyectos y pulsa **F5**.

| Acción | Teclado | Mando |
|---|---|---|
| Mover | `A`/`D` o `←`/`→` | Cruceta / stick izq. |
| Saltar | `Espacio`, `W`, `↑` o `Z` | A |
| Correr | `Shift` o `X` | X / RB |
| Volver al inicio | `R` | Y |

Para ver los botones táctiles en PC con el ratón: `godot --path . -- --touch-ui`.

## Obtener el APK para tu teléfono Android

El APK necesita las herramientas oficiales del SDK de Android (`apksigner`, `adb`). En el entorno donde se
desarrolló la primera etapa la descarga de ese SDK estaba bloqueada, por lo que **el APK se genera en GitHub
Actions** con el flujo `.github/workflows/aventura-3d-apk.yml`:

1. Sube la rama a GitHub (el flujo se ejecuta solo al cambiar `aventura-3d/`) o lánzalo a mano:
   *Actions → "Aventura 3D - APK de depuración" → Run workflow*.
2. Cuando termine, abre el run y descarga el artefacto **aventura-3d-debug-apk** (zip con el `.apk`).
3. Pasa el `.apk` al teléfono (cable, Drive, Telegram…), ábrelo y acepta *Instalar apps de orígenes desconocidos*.
   O por USB con depuración activada: `adb install -r aventura-3d-debug.apk`.
4. Si quieres, guarda el archivo en `aventura-3d/builds/` (está en `.gitignore`).

El flujo también ejecuta la prueba automática del juego antes de exportar.

### Construirlo en tu propio ordenador

Necesitas: Godot 4.4.1, **plantillas de exportación 4.4.1** (Editor → Gestionar plantillas), **JDK 17**,
**Android SDK** con `platform-tools` y `build-tools;35.0.1` (basta instalar Android Studio o las *command-line tools*).
En *Editor → Configuración del editor → Export → Android* indica la ruta del SDK, la del JDK y una clave de
depuración (`keytool -genkey -v -keystore debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000`).
Después: *Proyecto → Exportar → Android (APK debug) → Exportar proyecto*, o

```
godot --headless --path . --export-debug "Android (APK debug)" builds/aventura-3d-debug.apk
```

Configuración Android ya incluida (`export_presets.cfg`): paquete `com.aventura3d.prueba`, arm64-v8a + armeabi-v7a,
orientación horizontal (sensor), modo inmersivo, renderizador *Compatibility* (OpenGL ES 3, el más compatible con móviles).
Sin Gradle: no hace falta NDK ni plantilla de compilación.

## Estructura

```
scenes/main.tscn            Escena principal (nivel + jugador + cámara + UI)
scenes/player/player.tscn   Protagonista (CharacterBody3D)
scenes/levels/level_01.tscn Cielo, luz y entorno del nivel 1
scenes/ui/                  Controles táctiles y HUD
scripts/autoload/           Registro de acciones de entrada (teclado/mando)
scripts/player/             player.gd (movimiento) y player_model.gd (modelo + animaciones)
scripts/camera/             side_camera.gd (cámara lateral)
scripts/level/              level_builder.gd (utilidades reutilizables) y level_01.gd (diseño)
scripts/ui/                 touch_controls.gd, hud.gd
scripts/tests/              Pruebas automáticas y capturas
```

## Pruebas

```
godot --headless --fixed-fps 60 --path . -s res://scripts/tests/smoke_test.gd
```
Comprueba aterrizaje, caminar/correr, altura y corte del salto, doble salto (apagado/encendido), límites,
un bot que recorre el nivel entero saltando huecos y muros, respawn al caer y seguimiento de cámara.

## Notas de diseño

- Doble salto listo pero desactivado: `double_jump_enabled = true` en el jugador (se activará con un poder).
- Salto variable, *coyote time* y *jump buffer* para controles precisos.
- Interpolación de física activada para movimiento fluido en pantallas de 90/120 Hz.
- La decoración repetida (árboles, flores, arbustos) usa `MultiMesh` para rendir bien en móviles.

## Hoja de ruta

1. Proyecto, protagonista, movimiento, cámara, nivel de prueba, controles Android ← **hecho**
2. Mejores escenarios, objetos, plataformas especiales
3. Enemigos, monedas, cajas sorpresa, poderes
4. Mundos: bosque, desierto, nieve, volcán, castillo
5. Jefes, niveles secretos, recompensas, progresión
6. Menú, selección de niveles, guardado, ajustes
7. Optimización final, pruebas en Android, APK

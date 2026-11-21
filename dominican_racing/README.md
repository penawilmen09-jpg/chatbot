# DOMINICAN RACING

Juego 2D de carreras de montaña para Android, hecho en **Godot 4.3 (GDScript)**. Todo el arte (dibujo vectorial en código) y el audio (síntesis propia, `tools/gen_audio.gd`) es original.

**APK instalable:** `dist/DominicanRacing.apk` (release, firmada, arm64-v8a + armeabi-v7a, minSdk 21, horizontal).

## Contenido
- Física propia: suspensión independiente por rueda (shape-cast + muelle/amortiguador), tracción limitada por fricción, freno, marcha atrás, inercia, saltos, control de rotación en el aire, vuelco por techo/cabeza.
- 11 vehículos (Jeep Dominicano inicial, clásico, moto, 4x4, buggy, quad, monster, deportivo, camión, guagua, especial desbloqueable con 20 niveles), cada uno con físicas, tamaño y diseño propios.
- 5 mejoras independientes por vehículo (motor, suspensión, neumáticos, combustible, tracción) × 5 niveles con precios progresivos; afectan de verdad a las físicas.
- 5 mundos (Campo, Montañas, Desierto, Ciudad, Tropical) × 5 niveles + modo infinito; terreno procedural sin huecos (colinas, pendientes, baches, rampas/saltos, puentes, dunas), parallax, cámara suave.
- Monedas (sueltas, grupos, en el aire), bidones de combustible, economía, tienda, garaje, mapas, resultados con desglose de recompensas.
- Guardado atómico en `user://` con copia de seguridad y recuperación de archivos dañados.
- HUD táctil multitoque (acelerar/frenar mientras se mantiene pulsado), pausa, ajustes de audio, perfil.

## Estructura
```
scripts/autoload   SaveManager (guardado/economía), Nav (pantallas/transiciones), Sfx (audio)
scripts/data       VehicleDefs, WorldDefs (datos, niveles, recompensas)
scripts/vehicle    Vehicle (física), VehicleArt (dibujo), VehicleView, VehiclePreview
scripts/world      TerrainGen, TerrainChunk, TerrainManager, PickupField, Decor, fondo parallax
scripts/ui         UIKit, HUD, Pedal, ResultsPanel, Backdrop
scripts/screens    menú, garaje, tienda, mapas, ajustes, gameplay
tools/             gen_audio.gd (regenera assets/audio), build_apk.sh
tests/             sim_test (conducción), game_test (integración), shot (capturas)
```

## Compilar
```
GODOT=/ruta/godot tools/build_apk.sh debug     # build/DominicanRacing-debug.apk
GODOT=/ruta/godot tools/build_apk.sh release   # build/DominicanRacing.apk
```
Requiere Godot 4.3 con plantillas de exportación, JDK 17+, build-tools de Android (apksigner/zipalign) y las rutas en *Editor Settings* (`export/android/android_sdk_path`, `java_sdk_path`). Firma de producción: variables `GODOT_ANDROID_KEYSTORE_RELEASE_PATH/_USER/_PASSWORD`. Sin ellas, el script crea un keystore **de prueba** en `~/.dominican-racing/`; **usa el tuyo para publicar** (otra firma obliga a desinstalar antes de actualizar).

## Pruebas
```
godot --headless --fixed-fps 60 --path . res://tests/game_test.tscn                       # 54 comprobaciones
godot --headless --fixed-fps 60 --path . res://tests/sim_test.tscn -- all all 60 bot       # conducción
```

# DOMINICAN RACING

Juego 2D de carreras de montaña para Android, hecho en **Godot 4.3 (GDScript)**. Todo el arte (dibujo vectorial en código) y el audio (síntesis propia, `tools/gen_audio.gd`) es original.

**APK instalable (v2.0.0):** `dist/DominicanRacing.apk` (release, firmada, arm64-v8a + armeabi-v7a, minSdk 21, horizontal).

## Contenido (v2.0 – recorrido infinito)
- **Sin metas ni niveles:** se conduce mientras haya combustible y no haya accidente. La distancia no tiene límite; el récord se actualiza en vivo.
- **Terreno procedural infinito** (`TerrainGen`): colinas, pendientes largas, valles, subidas fuertes, rampas/saltos, baches, puentes y dunas; la dificultad sube con la distancia. Cada partida usa una semilla nueva; los tramos y puntos antiguos se liberan para ahorrar memoria.
- **6 biomas encadenados con transiciones suaves** (`BiomeTrack`): Campo Dominicano, Montañas Tropicales, Zona Rural, Desierto, Bosque y Carretera de Montaña (orden aleatorio por partida).
- Física con suspensión independiente por rueda (shape-cast + muelle/amortiguador), tracción limitada por fricción, freno, marcha atrás, saltos, control en el aire, vuelco/choque grave.
- 11 vehículos con conductor, 5 mejoras por vehículo que cambian las físicas; el especial se desbloquea al superar 2500 m.
- Gráficos cartoon: paralaje de 4 capas con bruma, sol, nubes y pájaros; suelo con estratos y hierba; decoración sombreada (palmeras, árboles, pinos, casas, graneros, rocas, guardarraíles...); sombras, polvo y destellos de monedas.
- Monedas (líneas, grupos y arcos aéreos), bidones de gasolina a distancias variables, HUD táctil, resultados, tienda, garaje y guardado robusto.

## Estructura
```
scripts/autoload   SaveManager (guardado/economía), Nav (pantallas/transiciones), Sfx (audio)
scripts/data       VehicleDefs, BiomeDefs, BiomeTrack, WorldDefs (escala, dificultad, recompensas)
scripts/vehicle    Vehicle (física), VehicleArt (dibujo), VehicleView, VehiclePreview
scripts/world      TerrainGen, TerrainChunk, TerrainManager, PickupField, Decor, fondo parallax
scripts/ui         UIKit, HUD, Pedal, ResultsPanel, Backdrop
scripts/screens    menú, garaje, tienda, ajustes, gameplay
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
godot --headless --fixed-fps 60 --path . res://tests/sim_test.tscn -- all all 120 bot       # conducción
```

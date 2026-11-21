# 🇩🇴 BARRIO RD

Videojuego **3D de mundo abierto** en tercera persona, inspirado en la vida cotidiana de República Dominicana.
Corre en el navegador (Three.js + WebGL), optimizado para móvil (Samsung Galaxy S23 Ultra) y preparado para convertirse en APK.

> Este proyecto vive en la carpeta `barrio-rd/` y es **independiente** del chatbot (WILMEN AI) que está en la raíz del repositorio. No se modificó ningún archivo del chatbot.

---

## ▶️ Cómo abrir el juego

Requisitos: Node.js 18+.

```bash
cd barrio-rd
npm install        # solo la primera vez
npm run dev        # servidor de desarrollo (muestra la URL en la red local)
```

### En tu teléfono Android
1. Teléfono y computadora/Codespace en la **misma red Wi-Fi** → abre la URL `http://IP-DE-TU-PC:5173` en Chrome.
2. Si usas **GitHub Codespaces** o Claude Code en la nube: reenvía el puerto **5173** (pestaña *Ports*, visibilidad *Public*) y abre la URL pública en Chrome del móvil.
3. Para jugar a pantalla completa: botón **⛶** (arriba a la derecha) o menú de Chrome → *Añadir a pantalla de inicio* (el juego incluye `manifest` y se abre en horizontal).

### Versión de producción
```bash
npm run build      # genera dist/ (estático, sin servidor)
npm run preview    # sirve dist/ en el puerto 4173
```
`dist/` se puede publicar en cualquier hosting estático (GitHub Pages, Netlify, Vercel…).

### Atajos de prueba (parámetros en la URL)
| Parámetro | Efecto |
|---|---|
| `?spawn=casa` | Empieza en el portón de Mi Casa Real (`patio`, `piscina`, `escalera`, `balcon`, `sala`, `habitacion`, `colmado`, `calle`) |
| `?hour=21` | Hora del día (0–24) |
| `?fps=1` | Muestra FPS, draw calls y posición |
| `?auto=1` | Salta el botón JUGAR |
| `?new=1` | Ignora la partida guardada |

---

## 🎮 Cómo jugar

**Teléfono**
- **Joystick izquierdo** (flotante: aparece donde pones el pulgar) → caminar en cualquier dirección.
- **Arrastrar con el pulgar derecho** en cualquier parte libre → mover la cámara.
- **CORRER** (toca para activar/desactivar) → correr.
- **Botón verde contextual** (aparece cerca de algo interactuable) → interactuar.
- ☰ menú: gráficos, sensibilidad, sonido, hora del día, guardar, ir a Mi Casa Real.

**Teclado (pruebas en PC)**: `WASD` mover · `Shift` correr · `E` interactuar · flechas ←/→ o arrastrar con el ratón: cámara · rueda: zoom · `Esc`: menú.

Una flecha ➤ arriba indica la dirección de **Mi Casa Real**. Desde el barrio camina hacia el este (la calle Duarte) hasta el portón verde.

---

## ✅ Qué funciona (Fase 1)

- **Motor**: Three.js + Vite, bucle con delta-time, carga con barra de progreso, ajuste automático de calidad por FPS.
- **Personaje** 3D con articulaciones: idle, caminar y correr (mezcla por velocidad), giro hacia la dirección de movimiento.
- **Cámara** en tercera persona con órbita, zoom, colisión con paredes y seguimiento amortiguado.
- **Controles**: joystick táctil flotante, botón correr, arrastre de cámara, botón de interacción; teclado/ratón.
- **Barrio dominicano**: calle Duarte y calle Mella, aceras con contén, líneas de tráfico, policías acostados, pasos de cebra, decenas de casas de cemento y bloques (generadas de forma paramétrica, cada una distinta) (techo plano con tinaco y varillas, techo de zinc, balcones con rejas, verjas con portón, marquesinas, medidores de luz), **colmado** con mostrador, estantes, neveras, mesa de dominó, bocinas con merengue y colmadero, **motores** (CG 150, CG 300, motoconchos), carro, guagua, **postes eléctricos** con transformadores, luminarias y **cables** entre postes y hacia las casas, cancha de baloncesto, palmeras, árboles, plátanos y plantas tropicales.
- **MI CASA REAL** (réplica 3D de tus 3 fotos, geometría real — no hay fotos pegadas):
  - Dos niveles, paredes verde claro y detalles turquesa.
  - Arcada de 5 vanos con **columnas turquesa y arcos verdes**, porche con comedor.
  - **Sala accesible** en planta baja (2 puertas, ventanas con rejas) y **habitación accesible** en la planta alta (ventanal con cortinas).
  - **Balcón** corrido con balaustres torneados alternados verde/turquesa y pasamanos.
  - **Escalera exterior curva** de peldaños de ladrillo rojizo, con barandas helicoidales y pilares.
  - **Piscina** con borde de ladrillo, agua animada, baranda de acero y chorritos.
  - **Palmeras de coco** altas (instanciadas, con balanceo), plantas ti rojas, jengibre rosado, plumeros, croton, macetas, tumbonas turquesa, columna de concreto con varillas, muro perimetral con portón.
- **Colisiones**: paredes, columnas, barandas, ventanas, muebles, troncos, postes, motos, piscina. Escaleras y balcones caminables por alturas (pisos múltiples).
- **Ciclo día/noche** con sol/luna, cielo con estrellas, luces de farolas y ventanas nocturnas.
- **Audio procedural** (sin archivos): brisa, pájaros, pasos y **merengue** que se oye más fuerte cerca del colmado.
- **Guardado local** automático (posición, dinero, hora, ajustes).
- **Optimización móvil**: geometría fusionada por trozos (pocas draw calls), vegetación con `InstancedMesh`, texturas procedurales generadas por código (0 descargas; no se usan texturas comprimidas porque no hay archivos de textura), LOD de detalles pequeños por distancia, sombras que siguen al jugador, resolución dinámica, carga progresiva por zonas.

## 🚧 Pendiente (siguientes fases)

| Área | Estado |
|---|---|
| Subir/bajar y **conducir vehículos** | Modelos listos en `VehicleCatalog`; falta controlador de conducción y animación de montar |
| Tiendas / colmado interactivo, **compra** | El colmadero ya existe e interactúa (diálogo); falta catálogo y pago |
| Trabajos y misiones | `GameState` tiene `job`/`quests`; falta sistema de misiones |
| Inventario, personalización | Estado preparado (`inventory`, `appearance`) |
| Tráfico y peatones | Sin implementar (los vehículos estáticos ya están) |
| Natación en la piscina | La piscina bloquea el paso; no se puede nadar aún |
| Más barrios / ciudad | Sistema de zonas listo (ver abajo) |
| Modelos GLB/texturas fotográficas | Todo es geometría y texturas procedurales; se pueden añadir `.glb` con `GLTFLoader` |
| APK | Pendiente (ver *Hacia Android*) |

---

## 🧱 Arquitectura (`src/`)

```
config.js                 parámetros globales y paleta
main.js                   arranque + pantalla de carga
core/
  Game.js                 renderer, luces, bucle, ajustes, calidad adaptativa, menú, guardado
  ZoneManager.js          carga/descarga progresiva de zonas
  Batch.js                fusión de geometrías por material y por trozo (chunks) + capa 'fine' (LOD)
  Builder.js              "pincel" local: cajas, paredes con huecos, colisiones, suelos
  Colliders.js            colisiones 2D con rango vertical + superficies caminables (escaleras, pisos)
  Materials.js, Textures.js   materiales y texturas procedurales
character/                HumanModel (modelo + animación), Player (movimiento, escaleras, gravedad)
camera/                   ThirdPersonCamera
controls/                 Input (teclado, ratón, táctil)
world/                    Barrio (definición de ZONAS), Streets, Flora (vegetación instanciada), Props, Places
buildings/                HouseBuilder (casa dominicana paramétrica), Colmado
special/                  CasaReal  ← la casa de las fotos
vehicles/                 VehicleCatalog (motos, carros, guagua)
interactions/             Interactions (puntos de interacción)
systems/                  GameState, SaveSystem, DayNight
ui/                       UI (HUD, diálogos, toasts)
audio/                    AudioSystem (WebAudio procedural)
```

### Cómo continuar sin perder trabajo
1. **Nuevo lugar/barrio**: añade una entrada a `ZONES` en `world/Barrio.js` (`id`, `box`, `loadDist`, `build(ctx)`). Se carga y descarga sola según la distancia.
2. **Nuevo edificio**: crea un archivo en `buildings/` que use `new Builder(ctx, frame, ctx.group)` (ver `Colmado.js`) y llámalo desde una zona.
3. **Nuevo vehículo**: añade una entrada a `VEHICLES` en `vehicles/VehicleCatalog.js`.
4. **Nueva interacción** (tienda, puerta, misión): `ctx.interactions.add({ x, z, y, radius, label, icon, action: (game) => … })`.
5. **Dinero/progreso**: `game.state.addMoney(n)`, `game.state.data.*` (se guarda solo).
6. Todo se ajusta en `config.js`. Usa `?spawn=…` y `?fps=1` para probar rápido.
7. Haz commits pequeños: cada módulo es independiente, así que un cambio en `special/CasaReal.js` no afecta al resto.

### Hacia Android (APK) — cuando quieras
El juego es una web estática (`npm run build` → `dist/`). Camino recomendado y gratuito: **Capacitor**
(`npm i @capacitor/core @capacitor/cli @capacitor/android`, `npx cap init`, `npx cap add android`, apuntar `webDir` a `dist`, `npx cap sync`, compilar con Android Studio). También funciona como **PWA instalable** (ya incluye `manifest.webmanifest`).

---

## 📸 Sobre la Casa Real
Las fotos se usaron como **referencia visual** para proporciones, colores y elementos (arcada, escalera curva de ladrillo, balcones con balaustres, piscina, palmeras, vegetación). El código está comentado en `special/CasaReal.js` y todas las medidas son constantes editables al inicio del archivo (`HX0`, `ZF`, `H0`, `POOL`…), por si quieres ajustar la casa para que se parezca todavía más.

## 🧪 Pruebas realizadas (en Chromium headless con WebGL por software)
- Arranque sin errores de consola; 4 zonas cargadas (`centro`, `casaReal`, `oeste`, `este`).
- Controles táctiles reales (eventos de toque): joystick, multitoque (mover + girar cámara), soltar, botón correr (5.2 m/s).
- Escalera curva: el jugador sube de y=0 a y=3.54 (balcón) caminando; baranda frontal, muros del patio, piscina, ventanas, columnas, postes y verjas bloquean; se entra a la sala (planta baja) y a la habitación (planta alta) por sus puertas.
- Capturas de revisión: calle, colmado, fachada, escalera, balcón, piscina, sala y noche.

**No probado en un teléfono físico**: el rendimiento real en el Galaxy S23 Ultra debe confirmarse jugando (usa `?fps=1` para ver FPS y draw calls; en las pruebas el barrio usa ~180 draw calls y ~190k triángulos). Los gráficos son *estilizados de bajo/medio detalle* (geometría y texturas procedurales), no fotorrealistas: para acercarse más habría que añadir modelos `.glb` y texturas reales (fase siguiente).

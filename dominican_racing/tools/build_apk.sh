#!/usr/bin/env bash
# Compila la APK de DOMINICAN RACING.
#   tools/build_apk.sh debug      -> build/DominicanRacing-debug.apk (firma de depuración)
#   tools/build_apk.sh release    -> build/DominicanRacing.apk       (firma de producción)
#
# Requisitos: Godot 4.3 + plantillas de exportación 4.3.stable, JDK 17+, Android build-tools (apksigner).
# Variables: GODOT (ruta al ejecutable), ANDROID_SDK_PATH y JAVA_SDK_PATH (editor settings),
# Firma de producción: GODOT_ANDROID_KEYSTORE_RELEASE_PATH / _USER / _PASSWORD.
# Si no existen se crea un keystore de prueba en ~/.dominican-racing/ (CAMBIAR para publicar en Play Store).
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
MODE="${1:-release}"
mkdir -p build

"$GODOT" --headless --path . --import >/dev/null 2>&1 || true

if [ "$MODE" = "debug" ]; then
  "$GODOT" --headless --path . --export-debug Android build/DominicanRacing-debug.apk
else
  if [ -z "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-}" ]; then
    KDIR="$HOME/.dominican-racing"
    mkdir -p "$KDIR"
    if [ ! -f "$KDIR/release.keystore" ]; then
      PASS="$(head -c 18 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 20)"
      keytool -genkeypair -keystore "$KDIR/release.keystore" -alias dominicanracing \
        -storepass "$PASS" -keypass "$PASS" -keyalg RSA -keysize 2048 -validity 10000 \
        -dname "CN=Dominican Racing, O=Dominican Racing, C=DO" >/dev/null 2>&1
      printf 'GODOT_ANDROID_KEYSTORE_RELEASE_PATH=%s\nGODOT_ANDROID_KEYSTORE_RELEASE_USER=dominicanracing\nGODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=%s\n' \
        "$KDIR/release.keystore" "$PASS" > "$KDIR/release.env"
      chmod 600 "$KDIR/release.env"
    fi
    set -a; . "$KDIR/release.env"; set +a
  fi
  "$GODOT" --headless --path . --export-release Android build/DominicanRacing.apk
fi
echo "Listo: $(ls -1 build/*.apk | tr '\n' ' ')"

#!/bin/bash
# Genera la APK "WILMEN WORLD TEST" (independiente de la normal).
#  - applicationId distinto  : com.wilmen.adventure.test  (se instala a la vez que la normal; datos y partidas separados)
#  - nombre visible          : WILMEN WORLD TEST
#  - fichero marcador        : wilmen_test_build.flag  (activa WW.test_unlock: todo desbloqueado + cartera de pruebas)
# Uso: tools/build_test_apk.sh SALIDA.apk [versionCode]
set -e
OUT=$(realpath -m "$1"); CODE=${2:-1}
SRC=$(cd "$(dirname "$0")/.." && pwd)
G=${GODOT:-/tmp/godot_dl/Godot_v4.3-stable_linux.x86_64}
W=$(mktemp -d)
cp -r "$SRC" "$W/p" && cd "$W/p"
rm -rf .godot
echo "WILMEN WORLD TEST" > wilmen_test_build.flag
sed -i 's|^package/unique_name=.*|package/unique_name="com.wilmen.adventure.test"|; s|^package/name=.*|package/name="WILMEN WORLD TEST"|; s|^version/code=.*|version/code='"$CODE"'|; s|^version/name=\(.*\)"$|version/name=\1-TEST"|; s|^include_filter="\(.*\)"$|include_filter="\1, wilmen_test_build.flag"|' export_presets.cfg
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=$PWD/android/wilmen-sideload.keystore GODOT_ANDROID_KEYSTORE_RELEASE_USER=wilmen GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=wilmenadventure
"$G" --headless --import >/dev/null 2>&1 || true
mkdir -p build
"$G" --headless --export-release "Android" build/test.apk
cp build/test.apk "$OUT"
rm -rf "$W"
echo "APK de pruebas: $OUT"

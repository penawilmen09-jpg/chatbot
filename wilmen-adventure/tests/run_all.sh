#!/usr/bin/env bash
# Ejecuta todas las pruebas en Godot 4.3 headless (requiere `godot` en el PATH).
set -euo pipefail
cd "$(dirname "$0")/.."
godot --headless --path . --import
godot --headless --path . --script res://tests/smoke_test.gd
godot --headless --path . --script res://tests/smoke_test.gd -- --mech
godot --headless --path . --script res://tests/persist_write.gd
godot --headless --path . --script res://tests/persist_check.gd

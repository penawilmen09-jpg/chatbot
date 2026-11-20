# Firma del APK

`wilmen-sideload.keystore` es una clave **pública de instalación directa (sideload)**: contraseña
`wilmenadventure`, alias `wilmen`. Sirve para que cada APK nuevo se pueda instalar *encima* del anterior
sin desinstalar el juego (Android exige que la firma sea la misma).

No es una clave secreta. **Para publicar en Google Play** crea la tuya, guárdala fuera del repositorio y
añade estos *secrets* en GitHub (Settings → Secrets → Actions); el flujo de CI los usará en lugar de esta:

- `ANDROID_KEYSTORE_BASE64` (el .keystore en base64), `ANDROID_KEYSTORE_ALIAS`, `ANDROID_KEYSTORE_PASSWORD`

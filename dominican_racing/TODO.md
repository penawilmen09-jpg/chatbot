# Estado y pendientes

## Hecho y probado (headless + capturas con render real)
- Guardado/recuperación, economía, compras, mejoras, progresión, recompensas (tests/game_test.gd).
- Partida completa con la escena real: cuenta atrás, pedales táctiles simulados, freno, pausa, fin por combustible, resultados.
- Conducción de los 11 vehículos en los 5 mundos con un piloto automático (tests/sim_test.gd).
- Exportación APK debug y release firmadas; manifiesto verificado (landscape, sin permisos, minSdk 21).

## Sin verificar (requiere dispositivo)
- Ejecución real en un teléfono Android: rendimiento (60 FPS), multitoque real, sonido, back/pausa del sistema.
- Balance fino de dificultad/economía y sensación de manejo (solo comprobado con bots).

## Ideas futuras
- Keystore propio de producción y AAB para Google Play.
- Más tipos de obstáculos, logros, nube de guardado, localización a otros idiomas.

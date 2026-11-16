# Interfaz y tutorial de la versión integrada

Base copiada de `origin/provicional_V1`, commit `1296d76139d720e2d4ddd1b4b8c1b85e4774a206`. El video `Killawasi-jugabilidad-1296d76-30s.mp4` se utilizó como referencia visual. La copia se hizo en `p6/interfaz-tutorial-perfil`; no se hizo merge.

## Distribución actual

La partida utiliza `ui/game_hud.gd`: cinco recursos en columna arriba a la izquierda, reloj/carga arriba, Configuración a la derecha, misión en la esquina inferior izquierda, accesos inferiores y ayuda de Timmy. `ui/game_drawer.gd` contiene los mismos cajones de acciones, mensajes, controles, ciencia y mejoras que se usan durante la enseñanza. Los controles se presentan con dibujos de ratón y teclas.

Construir selecciona una imagen y coloca un holograma 3D válido dentro del domo. Hielo descubre zonas, selecciona un destino y recoge/regresa con el robot. Procesar y reparar usan las acciones temporizadas del juego. Se conserva la jugabilidad de la rama de referencia, sin las pruebas antiguas de puntos numerados del escudo o de tres clics del procesador.

## Curso común antes del perfil

`ui/intro.gd` ejecuta 24 lecciones en inglés y español. Timmy señala el control siguiente, explica cada cambio y espera el resultado de las prácticas. Las cinco barras se resaltan como indicadores y no requieren clic. Las recompensas de práctica aparecen tras terminar una tarea real de procesar hielo: Timmy explica el objetivo, señala Más → Procesar hielo y espera el agua. Recuperación explica las dos reglas como texto, sin elegir un rol ni abrir demostraciones. El final se presenta primero con Timmy; el botón Finalizar/Finish abre la celebración de ejemplo. Estas actividades usan únicamente el estado aislado del curso.

Se utiliza `scenes/juego.tscn` con `ui/tutorial_game.gd`, que hereda la partida real. Cámara, modelos, colocación, rutas de hielo, acciones, paneles, recursos y voz se reutilizan. La enseñanza mantiene sus recursos sin consumo pasivo para que el niño pueda leer y escuchar a su ritmo; las acciones conservan sus controles y efectos. El hielo viaja físicamente y las reparaciones/procesamiento requieren esperar.

`ui/tutorial_state.gd` crea estado independiente. `ui/tutorial_save.gd` conserva el progreso solo en memoria. `RunSession` y la expedición toman el estado de su partida anfitriona mediante `game._gs()`. Practicar, repetir u omitir el curso no reemplaza una partida guardada.

Al terminar u omitir: perfil con nombre de llamada y edad, después menú principal y finalmente Jugar. Al repetir desde el menú, se vuelve al menú sin pedir el perfil de nuevo. Cadete corresponde a 7–9 años; Ingeniero, a 10–12. La energía de la base u oxígeno a cero activa la recuperación: checkpoint en Cadete y reinicio de expedición en Ingeniero. La batería del robot a cero detiene al robot.

## Mensajes y respuesta visual

Los mensajes de recursos ofrecen Resolver con Timmy. En el tutorial, el aviso de agua conduce al procesador y solo se considera resuelto cuando hay agua nueva. Los botones de las tarjetas ancladas al mundo se conservan entre fotogramas, evitando que pierdan el clic o el foco. La recuperación real muestra el aviso, lee su explicación y hace una transición breve a negro al restaurar o reiniciar.

La selección de idioma muestra English/Spanish en inglés e Inglés/Español en español. Se mantienen Zira y Sabina como preferencias de voz; dependen de las voces disponibles en Windows.

## Archivos de extensión

- `ui/tutorial_steps.gd`: orden del curso.
- `ui/intro.gd`: condiciones, instrucciones y control que se señala.
- `i18n/tutorial_guidance.gd`: textos EN/ES.
- `ui/tutorial_coach.gd`: resaltado sin interceptar clics.
- `ui/controls_view.gd` y `ui/control_glyph.gd`: controles visuales compartidos.
- `ui/live_game.gd`, `ui/game_drawer.gd` y `ui/game_hud.gd`: partida e interfaz compartidas.
- `data/missions/supplies.json`: reparto editable del equipo.
- `scenes/juego.tscn`: modelo del robot usado por partida y tutorial. La vista del perfil usa `ui/astronaut_preview.gd`; el fondo del menú, `ui/world_backdrop.gd`.

No se generaron nuevas ilustraciones ni se descargaron nuevos datos NASA durante esta fase. Se reutilizaron los modelos, imágenes, cartas y datos de la rama del equipo.

### Revisión visual final

Se compararon los cajones con `provicional_V1` en `2771313` y se aplicaron sus correcciones de distribución. El diálogo del tutorial adapta su altura al texto; los botones compartidos ajustan sus rótulos al espacio disponible y las pestañas seleccionadas usan texto claro. La tarjeta Place/Cancel se oculta solo en la enseñanza. Se conserva el comportamiento de las acciones y el guardado. La prueba adicional de límites y contraste está en `ui/tests/test_visual_layout.gd`.

## Verificación

Resultados y cobertura en `docs/AUDITORIA_INTERFAZ_TUTORIAL.md`. Las pruebas usan copias y archivos dedicados. `SaveManager.storage_directory` permite aislar las pruebas de slots; el valor vacío conserva las rutas normales del juego.

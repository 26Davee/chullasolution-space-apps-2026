# Interfaz y tutorial de la partida unificada

Rama: `p6/interfaz-tutorial-perfil`, creada a partir del trabajo local de `unificacion_v1_proyect`, sin merges. Distribución vigente autorizada el 15 de noviembre de 2026: referencia visual `opcion-3-configuracion.zip`, conservando los minijuegos.

## Distribución y navegación

- Cinco recursos agrupados en una columna superior izquierda: energía de la base, agua, oxígeno, escudo y batería del robot. El reloj, hielo, estrellas y modo aparecen en una banda superior independiente.
- Barra inferior compartida: Construir, Hielo, Reparar, Misiones y Más. Más abre Procesar hielo, Recargar robot, Mejoras, Álbum científico, Centro de Control y Ayuda de Timmy.
- Configuración está arriba a la derecha y contiene Idioma, Sonido y narración, Controles y Guardar y volver al inicio. La salida pide confirmación.
- Construir abre un catálogo lateral con imágenes, unidades y coste. Elegir una imagen inicia el holograma 3D del equipo; colocar una pieza válida consume inventario y energía. Cancelar conserva las unidades.
- Los minijuegos abren paneles contextuales que dejan visible parte del mundo. Misiones, árbol de mejoras, álbum y lectura detallada conservan sus vistas dedicadas.
- La cámara inicial de `scenes/juego.tscn` usa distancia 32 y ángulo de 44 grados. Movimiento, zoom y selección de modelos conservan los controladores del equipo.

`ui/station_rail.gd` contiene la barra inferior y `ui/navigation_menu.gd` los menús Más/Configuración; los reutilizan tutorial y partida. Los paneles pausan reloj, simulación y movimiento; la interfaz y la narración permanecen disponibles. El foco de teclado se mantiene dentro de los diálogos.

## Menú principal y conservación de la partida

`ui/home_menu.gd` ofrece Jugar/Reanudar, Opciones, Volver a ver el tutorial e Iniciar desde cero. La confirmación precede al reinicio y Cancelar conserva la expedición. El reinicio usa la misma restauración de estado que el menú de la partida, mediante `LiveGame.restore_run_for_transition`.

Cerrar y volver a abrir conserva la partida; el menú permite elegir qué hacer. Iniciar desde cero elimina la progresión de la expedición y conserva nombre, edad/modo, idioma y preferencias. Las transiciones mantienen el mundo detenido mientras se restaura.

El recorrido inicial es Tutorial común → Perfil → Menú principal. Nombre y edad se solicitan en ui/player_setup.gd después de las explicaciones; la edad determina el modo. Saltar tutorial va directamente al perfil. Si se cierra durante ese paso, la siguiente apertura retoma el perfil. El tutorial no muestra nombre personal ni modo asignado. Repasarlo conserva la expedición y los datos ya confirmados.

## Tutorial completo en ambos roles e idiomas

`ui/tutorial_steps.gd` define 24 pasos comunes: llegada, presentación, base, cinco recursos, construcción, hielo, procesamiento, reparación, recarga, misiones, alertas, cartas, suministros, mejoras, álbum, configuración, ciclo solar, recuperación, celebración y confirmación final. El perfil posterior contiene nombre y edad.

Cadete corresponde a 7–9 años; Ingeniero a 10–12. Los controles y el tutorial se comparten. La práctica de recuperación es general; las reglas se explican al elegir la edad, después del tutorial. En la partida, la recuperación presenta checkpoint para Cadete y reinicio completo para Ingeniero. La derrota sigue el contrato vigente de la rama: energía de la base u oxígeno en cero; la batería del robot agotada detiene su movimiento.

Se comprueban los cuatro recorridos: Cadete EN, Cadete ES, Ingeniero EN e Ingeniero ES. Los textos incluyen los botones reales de la nueva navegación. La voz prefiere Zira en inglés y Sabina en español, según las voces instaladas en Windows.

### Componentes compartidos

- `ui/build_practice.gd`: tarjetas ilustradas y colocación real sobre un mundo aislado, usando el mismo `PlacementSystem`, holograma, colisiones y giro con R.
- `ui/ice_survey_panel.gd` y `ui/scan_radar.gd`: elegir zona, ruta visible, barrido animado, descubrimiento con icono y recogida. `ui/ice_expedition.gd` mueve el robot, extrae y regresa; conserva las tres zonas, existencias y estados de cancelación/reintento.
- `ui/station_sequence.gd` y `ui/repair_marks.gd`: procesamiento ordenado con imágenes y flujo de iconos; puntos dañados de reparación con animación de barra.
- `ui/recharge_panel.gd`: el mismo modelo de robot, regreso al domo y recarga; la demostración llena una batería local y la partida conserva sus costes y movimiento reales.
- `ui/notification_center.gd`: avisos por atención, descubrimientos e historial, lectura, resolución con Timmy y estado leído. Se abre la categoría pertinente para encontrar mensajes nuevos.
- `ui/reward_view.gd`: misión, estrellas, carta ilustrada y suministros. Lo usan las entregas reales y la demostración.
- `ui/tutorial_events.gd` y `ui/tutorial_mailbox.gd`: ejemplos identificados como práctica de agua baja, tormenta y carta del Centro de Control, más recuperación/final. No escriben en GameState, inventario, misiones ni guardado.
- `ui/outcome_art.gd` y `ui/run_transition.gd`: celebraciones y transiciones reales y de práctica.

Las cartas de práctica son comunicaciones ficticias del juego. Las cartas científicas reales conservan los JSON y fuentes del equipo; no se añadieron datos científicos nuevos.

## Guía durante la partida

`ui/task_guide.gd` espera eventos reales: abrir, seleccionar, explorar, colocar y terminar acciones. Una falta de agua puede encadenar construir procesador → buscar hielo → regresar → procesar → comprobar que suba la reserva.

Las primeras tareas ofrecen guía; cerrarla evita repetirla automáticamente y Ayuda permite retomarla. Las pistas de `ui/context_hint.gd` consideran recursos, edificios, expedición y misión. Mientras se explica la colocación se detiene el consumo de recursos y se mantiene el control del holograma; viajar y esperar resultados permiten que el tiempo avance.

Los avisos destacados de `ui/alert_banner.gd` aparecen de uno en uno, con icono y acceso a Resolver. Los urgentes adelantan a los informativos. Se ocultan al abrir paneles y colocar piezas. El Centro de Control actualiza alertas por ID, sin acumular copias; las resueltas pasan al historial.

## Contratos y persistencia

- GameState conserva el único reloj y la evaluación temporal de misiones. El tiempo visible de misión empieza a las 06:00; anochece a los 240 segundos y amanece a los 480. Iluminación y HUD siguen esa fase.
- `progression/run_session.gd` guarda recursos, mundo, inventario, misiones, entregas, cartas leídas, mensajes y guía, junto al checkpoint.
- Cadete restaura el checkpoint de misión. Ingeniero reinicia la expedición. Recompensas y suministros se entregan una sola vez por ID.
- `data/missions/supplies.json` mantiene el reparto inicial editable autorizado; no representa cantidades científicas.
- El saldo del HUD usa SaveManager. El tanque amplía la reserva y el árbol controla el límite de paneles.
- El robot se referencia como recurso `3_robot` en `scenes/juego.tscn`; en el perfil posterior, `astronaut_model_path` de `ui/intro.gd`. El fondo y la recarga también usan la ruta del modelo en `ui/world_backdrop.gd` y `ui/recharge_panel.gd`. Se reutilizan las escenas y materiales de P3.

Se conserva el fallback de P1: `simulation/simulacion.gd` no está en esta rama. Una simulación independiente necesitará aportar serialización/restauración compatible. Esta fase verifica interfaz e integración; no certifica el balance de una campaña completa ni los textos científicos del equipo.

## Verificación y recursos

- `ui/tests/test_tutorial.gd`: los cuatro recorridos completos, prácticas, navegación, edades, idiomas y aislamiento de datos.
- `ui/tests/test_main_navigation.gd`: Saltar tutorial, guardado del perfil, relanzamiento, Reanudar, cancelación y confirmación de Iniciar desde cero.
- `ui/tests/test_task_lessons.gd`: guía y acciones reales, orden, resultados efectivos, límites de controles, reintento y recuperación animada.
- `ui/tests/test_interaction.gd`: selección de máquinas, reloj/sol y viajes físicos a las tres zonas.
- `ui/tests/test_live_game.gd`: columna, pausa, inventario, recompensas únicas, compras, persistencia, ambos modos y final de las dieciséis misiones.
- `tests/test_flujo.gd`: integración general.

Las pruebas usan una copia aislada y guardados separados de la partida personal. La revisión gráfica nativa cubre inglés/español y ventana pequeña; capturas fuera del repositorio.

Los ZIP del equipo se usaron como referencia visual, sin incorporar sus PNG al juego. Se reutilizan las ilustraciones y modelos existentes; no se generaron nuevas imágenes ni grabaciones con IA.

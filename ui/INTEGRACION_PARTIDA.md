# Interfaz de la partida unificada

Implementado sobre `unificacion_v1_proyect` (base fde4510), 15 de noviembre de 2026.

## Pantalla y navegación

La escena de juego usa `ui/live_game.gd`, adaptador que hereda las acciones y el mundo de `core/juego.gd`. Conserva modelos, cámara y colocación del equipo. Comparte paleta, botones, iconos, voz, Misiones y Upgrades con el tutorial.

`ui/live_hud.gd` presenta cinco barras en una fila: energía de la base, agua, oxígeno, escudo y batería del robot. El reloj, hielo y estrellas tienen una cabecera de contraste. La misión ocupa la esquina inferior izquierda; el centro queda libre. Las estaciones están en una columna lateral con icono y nombre; el menú superior contiene opciones, ayuda, reinicio y regreso al inicio. Construir usa un cajón contextual con imágenes, existencias y coste visible.

Los paneles pausan reloj, recursos, expedición, acciones temporizadas, movimiento y animaciones del mundo. Se cierran con botón o Escape; el foco de teclado se mantiene dentro. Recuperación y victoria requieren una decisión explícita. Se conserva la proporción 16:9 (mínimo 960×540), con márgenes en otras proporciones.

## Conexiones de las 14 funciones

| Función | Implementación |
|---|---|
| Ayuda de Timmy | Pistas concretas por recursos/misión y guía de primeras tareas que espera acciones y resultados reales. |
| Centro de Control | Atención, descubrimientos e historial; detalle, lectura y resolución guiada, sin duplicar alertas. |
| Misión activa | Campos reales de MissionManager, progreso de triggers y detalle en Misiones. Texto breve en `ui/mission_goals.json`. |
| Celebración | Una transacción por misión, estrellas, carta, suministros y animación. Cerrar reconoce el aviso. |
| Suministros | Tabla editable `data/missions/supplies.json`, inventario persistente y entregas únicas por ID. |
| Construcción | Consume una unidad tras colocación válida, paga energía y conserva modelos/posiciones. Añade el tanque de agua. Cancelar no consume existencias. |
| Science | Cartas ilustradas realmente desbloqueadas por misiones y mejoras, lectura y fuentes del equipo. |
| Alertas | Banner con icono, borde, texto y botón Resolver; una alerta a la vez y prioridad para las urgentes. Historial persistente. |
| Acciones | Validaciones de energía, hielo, distancia, inventario y espacio; barras de procesamiento/reparación. |
| Mejoras | Conserva el árbol; muestra requisitos o estrellas pendientes, saldo autorizado y carta tras comprar. |
| Recuperación | Pantallas por modo y causa, transición animada al checkpoint o reinicio completo. Conserva perfil/opciones. |
| Guardado y pausa | Autoguardado cada 30 s activos, al completar misión, colocar, comprar, ir al menú y cerrar. Reanudar conserva el mundo. Escritura temporal, respaldo y avisos de fallo. |
| Final | Comprueba todos los IDs del catálogo; resumen, Science, menú y nueva expedición con confirmación. |
| Ayuda/estados | Controles reales, colección vacía, módulos agotados, jardín bloqueado, carga/guardado y voz no disponible. |

## Contratos corregidos

- GameState es el único dueño del reloj y de la evaluación temporal de misiones.
- El saldo del HUD sigue a SaveManager, incluida la resta de compras.
- El hielo distingue extraer de regresar al domo. La recarga comprueba batería del robot y recarga activa.
- La derrota sigue el contrato existente: energía **de la base** u oxígeno en cero. La batería del robot agotada detiene el movimiento y puede recargarse con sol o en el domo.
- El tanque amplía la reserva; más procesadores amplían un lote. El límite de paneles sigue el árbol.

## Guardado y datos editables

`progression/run_session.gd` reúne estado, triggers/contadores, módulos colocados, posición/destino, temporizadores, inventario, entregas, historial y avisos pendientes. Guarda sesión y checkpoint a través de SaveManager. Ambos modos usan el mismo componente.

El guardado mantiene los campos antiguos y añade `expedicion` y `perfil`. Un guardado antiguo no contiene posiciones del mundo: no pueden reconstruirse; la nueva sesión empieza a registrarlas. Un JSON corrupto se conserva como `.invalid` y se intenta recuperar `.bak`.

El reparto de suministros es una **propuesta inicial autorizada**, no una regla científica. Editar `starter` o cantidades por misión en `data/missions/supplies.json`. Los cambios se aplican a futuras entregas; no duplican las registradas. Se conservan `missions.json` y el catálogo del árbol.

## Recursos y modelos

Se reutilizan ilustraciones de `assets/ui/activities/`, Timmy y el fondo lunar. El tanque usa una región de la lámina de revisión del modelo del equipo, sin alterar el original. No se generaron modelos ni ilustraciones con IA en esta fase. Los iconos son vectores compartidos.

El personaje real se referencia en `scenes/juego.tscn` como recurso `3_robot`; el del tutorial en la propiedad `astronaut_model_path` de `ui/intro.gd`. Mantener nodos/controladores y revisar orientación/animaciones al sustituirlo.

## Validación

- `ui/tests/test_tutorial.gd`: recorridos EN/ES, edades, ratón/teclado y paneles.
- `ui/tests/test_live_game.gd`: fila de barras, reloj único, pausa real, inventario, recompensas únicas, compras, guardado/restauración, modos, retorno real al domo, victoria, respaldo y tutorial sin perder la partida.
- `tests/test_flujo.gd`: flujo integrado actualizado a conservar/reanudar.
- Revisión visual nativa en Godot 4.7.2 con guardados separados; capturas fuera del repositorio.

La simulación externa `simulation/simulacion.gd` no existe en esta rama: se conserva el fallback de P1. Al incorporar una simulación independiente, P2 deberá aportar serialización/restauración compatible. Esta implementación no valida el balance de toda la campaña ni verifica científicamente los textos de los JSON del equipo. Las voces dependen del sistema (preferencia Zira EN, Sabina ES).

## Revisión de interacción tras probar la partida · 2026-11-15

- Acciones en `ui/station_rail.gd`: nueve accesos con icono, color y nombre, compartidos por tutorial y partida. El menú superior queda para ajustes, ayuda y regreso al inicio.
- Inicio y tutorial usan `ui/world_backdrop.gd`, con los mismos modelos y materiales del mundo real; ya no enseñan una base ilustrada distinta. El tutorial incluye la batería del robot y sus cinco barras.
- Las primeras aperturas de cada estación se acompañan con Timmy. Se guardan en `RunSession.learned`; ambos modos comparten la guía. Se puede repetir la explicación desde Ayuda.
- Misión completada presenta la carta con imagen y título, además de estrellas y suministros. Una compra de mejora muestra confirmación, efecto y saldo antes/después.
- `interaction/station_bindings.gd` añade volúmenes para seleccionar máquinas. `ClickToMove.station_clicked` abre los mismos controles que la columna lateral. Las áreas de selección usan capa 16 y no bloquean movimiento ni colocación.
- `ui/ice_expedition.gd` distingue viajar, extraer, volver, bloqueo y reposo. Planifica rutas por las colisiones reales con `interaction/route_planner.gd`, regresa automáticamente y permite cancelar/reintentar. Los viajes antiguos sin estos estados se liberan al restaurar.
- El mapa descubre tres puntos reales, con reservas propias, registrados en el guardado. Coordenadas y reservas están en `IceExpedition.ZONES`.
- El reloj visible es de misión: 06:00 al empezar, 18:00 a los 240 segundos y siguiente amanecer a los 480. No pretende representar horas terrestres de una lunación. Las tasas de balance existentes se conservan. `AmbienteLunar.set_solar_time` y el indicador del HUD siguen la misma fase.
- Se detiene la voz al cerrar/cambiar diálogos o ir al menú. Cada instancia de voz reconoce si es dueña de la narración activa, evitando que una pantalla antigua interrumpa a otra.
- `ui/tests/test_interaction.gd` prueba clic real por rayo de cámara sobre un procesador, fases del reloj, primera guía, persistencia y recorridos físicos completos a los tres puntos.

Comprobación nativa de voz en Windows: narración activa antes de cerrar = true; tras cerrar = false y cola pendiente vacía. Se ejecutó con volumen de prueba cero.

## Tareas guiadas y avisos visibles · 2026-11-15

- `ui/task_guide.gd` conserva una máquina de estados para ambos modos. Los eventos de abrir, seleccionar, explorar, colocar y completar acciones avanzan la explicación; abrir una ventana no significa haber aprendido. La primera ejecución ofrece guía; cerrarla evita insistir automáticamente y Ayuda permite retomarla.
- La falta de agua puede encadenar construir procesador → explorar hielo → volver al domo → añadir, encender y recoger agua. La guía termina cuando sube la reserva real. Reparación espera la subida real del escudo y recarga espera batería suficiente. En una tormenta se enseña a regresar y protegerse sin pedir reparar un escudo lleno.
- Mientras Timmy explica la colocación se detiene el consumo de recursos, conservando el control del holograma. Al viajar o esperar un resultado, el tiempo y la simulación continúan. Los paneles completos mantienen la pausa habitual.
- `ui/station_sequence.gd` comparte los controles ordenados de procesamiento/reparación entre práctica y partida. Solo la partida paga y aplica resultados, mediante las acciones existentes del equipo.
- `ui/ice_survey_panel.gd` comparte elegir zona → explorar → recoger. Las tres zonas tienen existencias reales en `ui/ice_expedition.gd`; explorar una zona la descubre físicamente. Un viaje bloqueado mantiene su selección al reabrir y ofrece Reintentar.
- `ui/build_practice.gd` usa un mundo de práctica aislado y el mismo `PlacementSystem`: holograma, colisiones, giro con R y colocación sobre terreno. No consume inventario ni avanza misiones reales. El ajuste en `interaction/placement_system.gd` conserva las coordenadas del evento para funcionar dentro del SubViewport.
- `ui/task_guide_view.gd` coloca a Timmy en una tarjeta temporal junto a la base o en una banda compacta dentro de la tarea. `ui/context_hint.gd` reúne las pistas. El aprendizaje y la tarea activa se guardan con la expedición.
- `ui/notification_center.gd` separa avisos por propósito, muestra un mensaje seleccionado y permite resolverlo con Timmy. `RunSession` actualiza alertas estables por recurso/tormenta en lugar de acumular copias; las resueltas pasan al historial. Abrir un detalle lo marca leído.
- `ui/alert_banner.gd` presenta avisos destacados bajo las barras, sin tapar el menú lateral. Se ocultan detrás de paneles y durante la colocación; los errores de Construir aparecen sobre el cajón sin cubrir sus tarjetas.
- `ui/outcome_art.gd` y `ui/run_transition.gd` añaden una celebración suave y una transición con icono/texto al recuperar o reiniciar. La restauración ocurre con la pantalla oscurecida y el mundo detenido. Reiniciar está disponible también antes del final, con confirmación.
- Nuevos textos reutilizables EN/ES en `i18n/tasks.gd`. Se mantienen las voces preferidas Zira/Sabina y los diseños de Misiones/Upgrades.

Prueba adicional: `ui/tests/test_task_lessons.gd` verifica colocación real, orden de controles, resultados efectivos, cancelación/reintento, primeras tareas, prioridad de avisos, recuperación animada en ambos modos y victoria. Las pruebas usan archivos separados del guardado del jugador. La revisión visual cubre inglés/español, ventana 1280×720 y una ventana más pequeña.

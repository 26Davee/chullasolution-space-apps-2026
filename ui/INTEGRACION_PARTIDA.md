# Interfaz de la partida unificada

Implementado sobre `unificacion_v1_proyect` (base fde4510), 15 de noviembre de 2026.

## Pantalla y navegación

La escena de juego usa `ui/live_game.gd`, adaptador que hereda las acciones y el mundo de `core/juego.gd`. Conserva modelos, cámara y colocación del equipo. Comparte paleta, botones, iconos, voz, Misiones y Upgrades con el tutorial.

`ui/live_hud.gd` presenta cinco barras en una fila: energía de la base, agua, oxígeno, escudo y batería del robot. El reloj, hielo y estrellas tienen una cabecera de contraste. La misión ocupa la esquina inferior izquierda; el centro queda libre. Las acciones se abren desde el menú. Construir usa un cajón contextual con imágenes, existencias y coste visible.

Los paneles pausan reloj, recursos, expedición, acciones temporizadas, movimiento y animaciones del mundo. Se cierran con botón o Escape; el foco de teclado se mantiene dentro. Recuperación y victoria requieren una decisión explícita. Se conserva la proporción 16:9 (mínimo 960×540), con márgenes en otras proporciones.

## Conexiones de las 14 funciones

| Función | Implementación |
|---|---|
| Ayuda de Timmy | Objetivo pendiente, nombre del jugador, consejo anterior, lectura y controles. |
| Centro de Control | Historial persistente, contador de mensajes nuevos, tormentas/ciclo y lectura con Timmy. |
| Misión activa | Campos reales de MissionManager, progreso de triggers y detalle en Misiones. Texto breve en `ui/mission_goals.json`. |
| Celebración | Una transacción por misión, estrellas, carta, suministros y animación. Cerrar reconoce el aviso. |
| Suministros | Tabla editable `data/missions/supplies.json`, inventario persistente y entregas únicas por ID. |
| Construcción | Consume una unidad tras colocación válida, paga energía y conserva modelos/posiciones. Añade el tanque de agua. Cancelar no consume existencias. |
| Science | Cartas ilustradas realmente desbloqueadas por misiones y mejoras, lectura y fuentes del equipo. |
| Alertas | Recursos bajos, noche, amanecer y tormentas; cola de avisos con texto/voz e historial. Prioridad para tormentas. |
| Acciones | Validaciones de energía, hielo, distancia, inventario y espacio; barras de procesamiento/reparación. |
| Mejoras | Conserva el árbol; muestra requisitos o estrellas pendientes, saldo autorizado y carta tras comprar. |
| Recuperación | Cadete restaura checkpoint de misión; Ingeniero reinicia base, recursos, inventario y progresión. Conserva perfil/opciones. |
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

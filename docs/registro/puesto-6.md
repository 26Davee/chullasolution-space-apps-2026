# Registro del puesto 6 · Interfaz, tutorial y textos

Persona: <!-- nombre -->  ·  Usuario de GitHub: <!-- usuario -->

Este archivo es **solo tuyo**: nadie más lo edita, así que no hay choques. Anota al momento, no al final. El puesto 1 junta los seis registros antes del envío.

## 1. Uso de IA

NASA pide reconocer todo lo hecho con ayuda de IA.

| Fecha y hora | Qué hice con IA (código, texto, imagen, sonido) | Herramienta | Dónde quedó (archivo) | Qué revisé o cambié yo |
|---|---|---|---|---|
| 2026-11-14 · sesión de trabajo | Tutorial compartido para cadete/ingeniero, HUD de cinco barras, reloj, ventanas, árbol visual, misiones, traducciones y pruebas | Codex | ui/intro.gd, ui/tutorial_*.gd, ui/player_profile.gd, ui/hud.gd, ui/game_bridge.gd, ui/progression_catalog.gd, ui/upgrade_tree.gd, ui/mission_list.gd, ui/ui_kit.gd, ui/ui_icon.gd, ui/mission_clock.gd, ui/game_panels.gd, ui/astronaut_preview.gd, ui/tests/, i18n/en.gd, i18n/es.gd | Comprobación automática de ambos recorridos y revisión de capturas EN/ES. La integrante revisará el resultado en su equipo. Se reutilizaron las imágenes existentes y el astronauta de P3. No se generaron imágenes ni grabaciones nuevas en esta fase. |
| 2026-11-14 · actualización visual | Siete ilustraciones low-poly para módulos, mapa, reparación y base provisional; menú, demostraciones interactivas, tablero científico y transición final | Codex + image_gen integrado | assets/ui/activities/ (prompts en generation.json), ui/visual_activity.gd, ui/section_menu.gd, ui/expedition_preview.gd, ui/intro.gd, ui/astronaut_preview.gd, i18n/en.gd, i18n/es.gd | Recorridos cadete/ingeniero, clic y teclado, interacciones sin alterar recursos y capturas EN/ES. Misiones, Upgrades y modelo de P3 sin cambios. |
| 2026-11-14 · claridad de interacción | Rótulo del astronauta, menú de icono a la derecha y borde guiado amarillo, única vista de construcción y retirada de accesos flotantes | Codex | ui/intro.gd, ui/expedition_preview.gd, ui/visual_activity.gd, i18n/en.gd, i18n/es.gd, ui/tests/test_tutorial.gd | Revisión EN/ES, sustitución de módulos en una única vista y capturas nativas. Se reutilizaron las ilustraciones existentes. |
| 2026-11-14 · menú y reanudación | Menú posterior al tutorial, Jugar/Opciones/Repetir, regreso y reanudación de sesión, selección Zira/Sabina y ruta de astronauta configurable | Codex | ui/home_menu.gd, ui/intro.gd, ui/expedition_preview.gd, ui/timmy_voice.gd, ui/astronaut_preview.gd, i18n/, ui/tests/test_tutorial.gd | Pruebas de ambos modos, ausencia de inicios duplicados, conservación de la instancia al reanudar y comprobación nativa de Microsoft Zira/Microsoft Sabina. Se reutilizaron las imágenes existentes. |
| 2026-11-15 · revisión de unificación | Comparación de ramas, diagnóstico visual/funcional y plan de los 14 puntos adaptado al robot confirmado por la integrante | Codex | ui/PLAN_MEJORAS_UNIFICACION.md | Pruebas existentes PASS/FALLOS: 0; capturas de UI integrada y diagnósticos de misión, batería, saldo y reloj en copia con guardados separados. Sin cambios en scripts, escenas o modelos de producción. |

| 2026-11-15 · integración autorizada | HUD compacto, iconos, Timmy, mensajes, Science real, suministros/inventario, celebraciones, pausa/reanudación, checkpoint y final sobre unificacion_v1_proyect | Codex | ui/live_*.gd, ui/science_collection.gd, ui/mission_goals.json, progression/run_session.gd, core/, progression/, scenes/juego.tscn, i18n/, data/missions/supplies.json, pruebas y guía ui/INTEGRACION_PARTIDA.md | Pruebas EN/ES de tutorial y partida, recuperación, entregas únicas, persistencia y capturas nativas. Ajustes de conexiones de otros puestos autorizados por la integrante. Se reutilizó arte/modelos del equipo, sin nuevas ilustraciones IA ni consultas NASA adicionales. El reparto de suministros es propuesta editable. |

| 2026-11-15 · correcciones tras prueba de la integrante | Columna compartida, inicio/tutorial con modelos reales, guía de primeras acciones, cartas y compras explícitas, clic en máquinas, sincronía solar, rutas y tres zonas de hielo, cancelación de voz | Codex | ui/station_rail.gd, ui/world_backdrop.gd, ui/ice_expedition.gd, ui/live_game.gd, ui/intro.gd, interaction/station_bindings.gd, interaction/route_planner.gd, interaction/click_to_move.gd, world/ambiente_lunar.gd, i18n/interaction.gd, pruebas | Se reutilizó arte y modelos del equipo. Pruebas de recorrido físico, selección real de máquina, tutorial EN/ES y capturas nativas. El reloj se rotula como tiempo de misión; no se descargaron datos ni se generó arte nuevo. |

## 2. Material de terceros

Imagen, sonido, fuente, modelo o código que no hicimos nosotros.

| Qué es | Autor | Dónde lo conseguí (enlace) | Licencia | Dónde se usa |
|---|---|---|---|---|
| | | | | |

## 3. Datos de NASA

| Dato | Enlace oficial | Fecha de descarga | Unidades | Qué le hice (reducir, convertir…) | Dónde se usa |
|---|---|---|---|---|---|
| | | | | | |

Recuerda: lo que **no** viene de NASA (por ejemplo, los números inventados del juego) se rotula como **unidades de juego**.

### Fuentes de las tarjetas científicas de ejemplo · 2026-11-14

Texto resumido para niños; las ilustraciones son generadas con IA y no fotografías de NASA. Sin descarga de mediciones ni cambio de unidades.

- Energía solar: https://science.nasa.gov/learn/heat/big-ideas/big-idea-3-1/
- Agua y hielo: https://science.nasa.gov/moon/moon-water-and-ices/
- Atmósfera lunar: https://science.nasa.gov/moon/lunar-atmosphere/
- Radiación y entorno lunar: https://science.nasa.gov/moon/weather-on-the-moon/


### 2026-11-15 · curso sobre provicional_V1 y auditoría

Codex asistió en la copia del contenido de origin/provicional_V1 (1296d76), el tutorial guiado EN/ES sobre el juego real, el aislamiento del progreso de práctica, controles vectoriales, avisos, recuperación visual, correcciones de entrada/foco, pruebas y documentación. Copia autorizada por la integrante; sin merge. Se usó el video Killawasi-jugabilidad-1296d76-30s.mp4 como referencia visual local. Se reutilizaron las imágenes, modelos, JSON y contenido científico del equipo. No se generó arte nuevo ni se consultaron nuevas fuentes NASA. FFmpeg se utilizó solo fuera del repositorio para revisar el video.

Incluye cambios de conexión en core/game_state.gd, core/juego.gd, core/main.gd, progression/run_session.gd, progression/save_manager.gd e interaction/placement_system.gd; además del contenido copiado de la rama del equipo. Su alcance fue autorizado en esta conversación. Validación registrada en docs/AUDITORIA_INTERFAZ_TUTORIAL.md; siete pruebas y revisión visual nativa.

### 2026-11-15 · pulido visual final por capturas de la integrante

Codex asistió en el ajuste de altura del diálogo de Timmy, contención y ajuste de texto de botones, contraste de selección de Upgrades y presentación de avisos traducidos. Se comparó `provicional_V1` en `2771313` y se reutilizaron únicamente sus ajustes visuales del cajón. La tarjeta Place/Cancel se oculta solo en el tutorial y se separan sus avisos breves del diálogo. Se añadió una prueba de límites visuales EN/ES y se revisaron capturas nativas. Esta revisión no modifica balance, misiones, inventarios ni reglas de guardado. No se generaron imágenes ni se consultaron nuevas fuentes NASA.

Validación final de este pulido: ocho pruebas aprobadas y revisión de catorce capturas nativas EN/ES.

### 2026-11-15 · tamaños estables y error EN/ES

Codex asistió en la reproducción y corrección del botón que crecía al reconstruir un panel oculto, separación del texto y las acciones en las tarjetas de partidas, y conexión faltante de `guardar_idioma`. Incluye ajustes de interfaz en core/main.gd y preferencia de idioma en progression/save_manager.gd, además de los controles compartidos y pruebas de regresión. Se verificaron cinco grupos de pruebas y ocho capturas nativas EN/ES; los datos de prueba se aislaron de las partidas reales. Sin nuevas imágenes, fuentes externas, datos NASA ni cambios de balance.

# Auditoría de interfaz y recorridos · 2026-11-15

Rama: `p6/interfaz-tutorial-perfil`. Base del juego: `provicional_V1` en `1296d76`. Referencia visual: video de 30 segundos proporcionado por la integrante. Se copió la rama de referencia; no se hizo merge.

## Correcciones realizadas

- Tutorial sobre la escena y acciones reales, con Timmy indicando el control siguiente y esperando resultados.
- Barras explicativas sin clic obligatorio; controles con dibujos de ratón y teclas.
- Avisos automáticos de recompensas, recuperación de ambos modos y final; sin botón flotante de práctica.
- Resolver con Timmy funcional en la práctica del aviso de agua.
- Nombre y edad después del curso; omitir, repetir y regresar al menú conservan sus recorridos.
- English/Spanish e Inglés/Español según idioma; selección de Zira/Sabina conservada.
- Capa de interfaz que dejaba interceptados los clics en terreno corregida.
- La colocación valida la posición del clic, evitando confirmar una posición anterior del holograma.
- Tarjetas de máquinas conservan botones y foco entre fotogramas.
- Cancelar construcción/viaje y cerrar recuperación no dejan el tutorial sin salida.
- Transición visual al checkpoint o reinicio, con bloqueo de entrada durante el efecto y liberación al terminar.
- Datos de prueba y curso aislados de las partidas reales.

## Cobertura automatizada

| Prueba | Recorridos verificados |
|---|---|
| `ui/tests/test_tutorial.gd` | Curso completo EN/ES, controles reales, holograma con rayo físico y validación, escanear/seleccionar/viajar/volver, procesar, reparar, recargar, mensajes, entrega automática, compra de mejora, ciencia, idioma/voz, ambas recuperaciones y final. Comprueba que los recursos y guardado reales no cambien. |
| `ui/tests/test_tutorial_detours.gd` | Cancelar construcción y expedición; reintentar; salir antes de terminar la explicación de recuperación; dos demostraciones obligatorias; idioma y detención de voz. |
| `ui/tests/test_main_navigation.gd` | Nueva partida, omitir antes del perfil, nombre requerido, Cadete/Ingeniero, menú antes de Jugar, revisión sin repetir datos, reanudar, dos slots independientes y cancelar reinicio. |
| `ui/tests/test_outcomes.gd` | Energía y oxígeno a cero en ambos modos; batería del robot no causa derrota; botón correcto de recuperación; transición y liberación de entrada; restauración de checkpoint o reinicio real; perfil conservado; preferencias Zira/Sabina. |
| `ui/tests/test_live_game.gd` | Paneles, pausa, guardado/carga, respaldo corrupto, entregas únicas, inventario, costes, mejoras, recuperación, 16 misiones y final único, tres slots, borrado aislado, objetivos nocturnos y límites visuales. |
| `ui/tests/test_interaction.gd` | Clic físico en máquina, panel compartido, recorrido real de las tres zonas de hielo, cancelar, sincronía sol/noche, límites del domo, expansión y recogida de suministros. |
| `tests/test_flujo.gd` | Inicio, estado, recursos y señales, cobro de energía, pausa, reanudación y conservación del mundo. |

Resultado: las siete pruebas finalizan sin fallos de sus verificaciones.

## Revisión visual

Godot 4.7.2, ventana 1280 × 720, renderizador Compatibility en Windows. Capturas nativas de base, Construir, controles, mensajes, recuperación y recompensas en EN/ES. Se corrigieron los cruces entre Timmy y el aviso de recuperación y se ajustó la altura del listado de controles. También se revisan las pantallas reales de pérdida y su transición.

Las verificaciones automatizadas cubren los recorridos descritos, no todas las combinaciones posibles de acciones de un jugador. Las cantidades científicas, balance y dificultad se conservan del equipo; no se realizó una validación científica adicional ni una sesión de evaluación con niños.

## Pulido visual final · 2026-11-15

Comparación con `origin/provicional_V1` en `2771313`. Se reutilizaron sus ajustes de tamaño y ajuste de texto de los cajones. Esta revisión modifica únicamente presentación; conserva las mecánicas y el flujo de acciones de la versión anterior de esta rama.

- El diálogo de Timmy mide el párrafo completo y coloca los botones debajo, con separación y sin cubrir la barra inferior.
- Las tarjetas y botones se ajustan al ancho disponible al cambiar de sección. Los textos largos EN/ES pueden ocupar dos líneas.
- Las pestañas seleccionadas de Upgrades mantienen letras claras sobre fondo azul y borde amarillo.
- La tarjeta duplicada Place/Cancel se oculta durante el tutorial; el holograma y los controles del juego se conservan.
- Los avisos breves del tutorial aparecen separados del diálogo de Timmy.
- El mensaje de recursos muestra una frase traducida con el nombre del recurso, en lugar de `live.resource`.

La prueba `ui/tests/test_visual_layout.gd` comprueba el espacio de los párrafos, separación de botones, límites de paneles y pies, cambios de ancho entre secciones, contraste de la pestaña seleccionada y ausencia de cruces con los avisos automáticos. Se revisaron catorce capturas nativas EN/ES de los casos comunicados por la integrante.

Resultado final de esta revisión: ocho pruebas aprobadas (las siete anteriores y la nueva prueba visual), junto con catorce capturas nativas en inglés y español.

## Corrección de crecimiento al actualizar y cambio de idioma · 2026-11-15

Se reprodujo el fallo pendiente al reconstruir el panel de procesamiento después de ocultar su pie: el botón conservaba 300 píxeles de altura en inglés y 400 en español. Las verificaciones estáticas anteriores no cubrían esa transición. El ajuste compartido de botones ahora calcula hasta dos líneas con el ancho disponible, sin el ajuste automático nativo que inflaba el contenedor oculto; mantiene el pie en 48 píxeles.

Las tarjetas de partidas separan nombre, progreso y fecha del área de acciones; las ranuras vacías usan dos líneas. Al refrescar el idioma, los controles anteriores salen inmediatamente del contenedor. Se implementó la llamada faltante `SaveManager.guardar_idioma`: la preferencia se guarda en los metadatos de la interfaz y se recupera al abrir el menú o cargar otra partida, sin crear una expedición ni modificar sus recursos. La selección de idioma desde Ajustes utiliza la misma preferencia. Los metadatos anteriores sin este campo siguen siendo válidos.

Validación: cinco grupos de pruebas aprobados (navegación principal, tutorial completo EN/ES, alternativas del tutorial, juego integrado y límites visuales). Se añadieron comprobaciones del cambio real EN/ES, recarga de metadatos, conservación del idioma al reanudar, separación de textos y acciones, reconstrucción repetida del procesamiento y altura de los botones después de las acciones reales. Se revisaron ocho capturas nativas EN/ES de partidas, procesamiento, audio y mensajes en Godot 4.7.2 Compatibility a 1280 × 720. Pruebas ejecutadas sobre una copia con datos aislados. El aviso del motor headless sobre el almacén de certificados de Windows es independiente de los scripts; la ejecución gráfica finaliza sin errores.

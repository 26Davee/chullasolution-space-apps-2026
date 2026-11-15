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

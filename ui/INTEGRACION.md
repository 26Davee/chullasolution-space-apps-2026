# Interfaz P6: tutorial y conexión con el juego

## Probar esta fase

Abrir `ui/intro.tscn` en Godot 4 y ejecutar **F6**. F5 sigue usando la escena principal que administra P1. El proyecto ya tiene TTS habilitado; el botón Audio permite escoger una voz instalada, probarla, ajustar volumen/velocidad y silenciar. Inglés inicia seleccionado; español es opcional. No hace falta instalar una biblioteca adicional para la versión de escritorio: se reutiliza `ui/timmy_voice.gd` y el TTS del sistema. La disponibilidad de voces depende del equipo. La exportación web necesita su propia comprobación de voz en el navegador.

El recorrido es compartido: aterrizaje → Timmy → alias → grupo de edad → cuatro recursos → acciones de la base → misiones → mejoras → ciencia → día/noche → recuperación → «Sí, iniciar». Los pasos interactivos requieren tocar el control resaltado antes de continuar. Tab/Mayús+Tab mueven el foco; Enter o Espacio activa el botón enfocado; Esc cierra la ventana abierta o abre Audio.

- **7–9 años:** perfil `mode = "cadete"`; al llegar Energía o Oxígeno de la tripulación a 0 se solicita `checkpoint`.
- **10–12 años:** perfil `mode = "ingeniero"`; al llegar Energía o Oxígeno de la tripulación a 0 se solicita `restart`.
- El perfil confirmado conserva el alias y grupo de edad durante el repaso. No hay cuenta, contraseña ni fecha de nacimiento.
- El tutorial usa una instantánea de práctica: no consume recursos, concede estrellas, desbloquea mejoras ni cambia partidas reales.

## Archivos y reutilización

| Archivo | Responsabilidad |
|---|---|
| `intro.gd` / `intro.tscn` | Presentación, diálogo, navegación, transiciones y ventanas |
| `home_menu.gd` | Menú con Jugar/Reanudar, Opciones y repetición del tutorial |
| `player_profile.gd` | Única correspondencia edad/modo/recuperación |
| `tutorial_steps.gd` / `tutorial_controller.gd` | Un recorrido de 19 pasos para ambos modos, con objetivos interactivos |
| `ui_kit.gd` / `ui_icon.gd` | Colores, botones, foco, textos e iconos compartidos |
| `hud.gd` / `hud.tscn` | Cuatro barras en una fila, porcentajes, contadores y reloj |
| `mission_clock.gd` | Presentación del reloj; no ejecuta la simulación |
| `section_menu.gd` | Menú de icono en la esquina superior derecha, con siete accesos |
| `visual_activity.gd` | Demostraciones visuales de construcción, mapa, procesamiento, reparación y tablero científico |
| `game_panels.gd` | Adaptador de compatibilidad que reutiliza visual_activity.gd |
| `expedition_preview.gd` | Fondo provisional de la expedición; las estaciones se abren desde el menú |
| `progression_catalog.gd` | Lectura de los JSON e inyección de datos |
| `upgrade_tree.gd` | Árbol visual de cuatro ramas, selección, coste y solicitud de compra |
| `mission_list.gd` | Lista desplazable, objetivo, recompensa y estado de misión |
| `game_bridge.gd` | Adaptador de lectura y señales entre UI y P1/P2/P5 |
| `astronaut_preview.gd` | Instancia el modelo existente `assets/3d/robot_humanoide.tscn` con cámara y luces |
| `../i18n/en.gd`, `../i18n/es.gd` | Textos de la interfaz y del tutorial |

Se mantienen las imágenes actuales de fondo, Timmy y nave de `assets/ui/`. No se reconstruye ni edita el robot de P3. Los iconos pequeños se dibujan en Godot y se reutilizan.

## P5: conectar misiones y árbol

P6 entrega **la parte gráfica**. P5 conserva la evaluación de objetivos, dificultad, recompensas, prerrequisitos, compras y efectos sobre el juego.

Publicar los archivos suministrados en estas rutas, o cambiar las propiedades exportadas de la escena de inicio:

- `res://data/missions/upgrades.json`: objeto `arbol_habilidades.ramas[]`, cada rama con `id` y `mejoras[]`. Cada mejora conserva `id`, `nivel`, `costo`, `requisito`, `nombre` y `efecto.descripcion`.
- `res://data/missions/missions.json`: objeto `misiones[]`, con `id`, `mision`, `objetivo` y `puntos.cadete/ingeniero`.
- Si P5 ya los carga, puede entregar los dos diccionarios mediante `intro.set_progression_catalogs(upgrades, missions)`.
- Incluir `*.json` en los archivos de la exportación si se leen mediante FileAccess.

La vista de práctica funciona sin publicar todavía los JSON: contiene los 12 identificadores de mejora, sus costes/prerrequisitos y las 16 misiones del material recibido. Esos datos solo son una vista de entrenamiento; **no sustituyen los catálogos del juego real**. La cuarta rama es Herramientas, según el JSON actual. No se aplica el ejemplo de Automatizar de la imagen a la lógica.

Entregar a `bridge.set_progression_state(...)` el estado autorizado:

```gdscript
bridge.set_progression_state({
    "current_mission": "mision_01",
    "completed_missions": [],
    "unlocked_upgrades": []
})
```

Las estrellas proceden exclusivamente de `estrellas_actualizadas(total)`; la UI no vuelve a sumar la recompensa de `mision_completada`. La señal `bridge.upgrade_requested(id)` solicita una compra: P5 debe validarla, descontar estrellas y emitir el estado final. Un clic nunca concede por sí solo la mejora. Durante el entrenamiento las compras están desactivadas, pero todos los nodos se pueden inspeccionar. Los textos conocidos usan traducciones por ID; nuevas misiones/mejoras usan los textos del JSON como alternativa.

También se pueden usar `upgrade_tree.gd` y `mission_list.gd` dentro de la escena del juego, llamando `configure(items, state, false, profile.mode)` y actualizando su estado con `set_progression_state`.

## P1/P2: recursos, inicio y recuperación

El adaptador busca `/root/GameState` y, como alternativa, `/root/GlobalBus`. Se puede configurar `game_state_path` o llamar `bridge.bind_state(bus)`. Tolera que el bus todavía no exista.

Señales de entrada del diccionario recibido:

```gdscript
recurso_actualizado(id: String, value: float, maximum: float)
estrellas_actualizadas(total: int)
ciclo_solar_cambiado(day: bool)
mision_completada(id: String, reward: int, card: Dictionary)
mejora_desbloqueada(id: String, branch: String, level: int)
```

IDs de barras: `energia`, `agua`, `oxigeno`, `escudo`. Hielo es un contador. Cada porcentaje respeta el máximo recibido: 120/150 de energía muestra 80 %. Los números son **unidades de juego**.

El reloj acepta el tiempo acumulado `tiempo_juego`. Para la presentación se proyectan los 300 segundos de día y 180 de noche del material a un reloj 06:00–18:00–06:00 y se incrementa el día cada ciclo. No es una duración lunar real ni modifica el reloj de P2. Si P2 dispone de un reloj propio, proporcionar `dia_mision` y `minutos_mision` (minutos desde medianoche), o llamar `bridge.receive_mission_clock(day, minutes)`: esos valores tienen prioridad.

Al confirmar el final del tutorial se muestra el menú de inicio con imagen y Jugar, Opciones y Ver de nuevo el tutorial. La partida todavía no inicia. Al pulsar Jugar se repite el oscurecimiento y se muestra la base provisional; entonces `intro.mission_requested(profile)` se emite **una sola vez**. P1 debe conectar esa señal para guardar el perfil, cargar la escena de la expedición e iniciar la simulación. Perfil:

```gdscript
{
    "nickname": "Alex", "age_group": "7_9", "mode": "cadete",
    "language": "en", "voice_enabled": true, "tutorial_completed": true
}
```

La UI de la expedición puede reutilizar `hud.tscn`, `section_menu.gd` y un `GameBridge` nuevo: conectar `state_changed` a `hud.set_state`, `section_menu.section_requested` a las acciones/ventanas de P4/P5, y llamar `bridge.begin_live(profile)`. El entrenamiento no inicia ni pausa por su cuenta la simulación.

Al llegar Energía del robot o Oxígeno de la tripulación a 0 en juego real, `bridge.recovery_requested(policy, profile)` se emite una vez hasta que ambos vuelvan a ser positivos. P1/P2/P5 deben implementar la recuperación y publicar el nuevo estado:

- `checkpoint`: restaurar el último checkpoint del cadete.
- `restart`: reiniciar toda la expedición del ingeniero, incluidas misiones, recursos, estrellas y mejoras; conservar perfil, idioma y ajustes de voz.

**P2 debe emitir `energia = 0` u `oxigeno = 0`.** Este módulo no borra guardados ni aplica reinicios por su cuenta.

## Validación de esta fase

Pruebas automatizadas: `Godot --headless --path . --script res://ui/tests/test_tutorial.gd`. Se debe comprobar el código de salida y la ausencia de SCRIPT ERROR, además del mensaje PASS.

Se probaron ambos recorridos completos en inglés/español, clic y teclado, selección obligatoria de edad, acciones guiadas, cuatro barras alineadas, máximo dinámico, catálogos e intención de compra, recompensas sin duplicar y recuperación al llegar a cero. Se revisaron capturas nativas a 1280×720 y una ventana de 960×540. La voz nativa cuenta con controles y selección de voces del sistema; debe probarse también en el equipo y plataforma finales.

La simulación de acciones, la persistencia/checkpoints, la dificultad real y el cambio a la expedición siguen en los módulos de sus responsables. El tablero científico incluye cuatro ejemplos con enlaces oficiales; las tarjetas adicionales de P5 deben conservar sus fuentes verificadas.

## Actualización visual · 14 de noviembre de 2026

- El robot conserva el modelo de P3 (`robot_humanoide.tscn`), sin panel detrás, con rotación continua de 55 grados por segundo.
- Los accesos están en el botón de menú, solo con icono, arriba a la derecha. Su borde amarillo señala los pasos guiados. El HUD mantiene las cuatro barras juntas.
- Construcción: seleccionar una de cuatro ilustraciones y mostrarla en una única vista de práctica; otro módulo reemplaza el anterior.
- Expedición: mapa ilustrado con tres zonas seleccionables, trazado de ruta y exploración de posibles depósitos de hielo. El mapa y los resultados son ficticios para entrenar.
- Procesamiento: secuencia interactiva de hielo, energía y agua, con iconos de salida y repetición.
- Reparación: tres puntos sobre el domo y barra local que avanza hasta completar la demostración.
- Ciencia: cuatro descubrimientos con ilustraciones, narración al seleccionarlos, tachuelas que se pueden poner/quitar y botón para abrir su fuente. Las tachuelas se conservan dentro de la sesión de la interfaz; no representan desbloqueos reales de P5.
- Misiones y Upgrades conservan sus archivos y diseño.
- Al finalizar el tutorial aparece el menú de inicio. Jugar abre la base provisional mediante una transición. Esta vista no ejecuta la simulación 3D; P1 puede sustituirla al recibir mission_requested.

Las siete ilustraciones nuevas fueron generadas con la herramienta integrada image_gen y están en **assets/ui/activities/**. Los archivos originales generados se conservaron; el conjunto de prompts y nombres finales está en **assets/ui/activities/generation.json**. Se reutilizan imágenes entre actividades y tablero; no se generaron ni sustituyeron modelos 3D.

Fuentes de los cuatro ejemplos científicos (consultadas el 2026-11-14; texto resumido para niños, ilustraciones de IA):

| Tarjeta | Fuente oficial |
|---|---|
| Energía del Sol | https://science.nasa.gov/learn/heat/big-ideas/big-idea-3-1/ |
| Hielo lunar oculto | https://science.nasa.gov/moon/moon-water-and-ices/ |
| Trae tu propio aire | https://science.nasa.gov/moon/lunar-atmosphere/ |
| Un hogar seguro | https://science.nasa.gov/moon/weather-on-the-moon/ |

Las demostraciones y los pines son estado de interfaz. La colección real, el consumo, los viajes, las reparaciones y la construcción siguen dependiendo de los módulos de P2/P4/P5.

### Ajuste de claridad de la interfaz

El rótulo del astronauta está centrado sobre el modelo en una cápsula negra. El menú se abre desde un único icono arriba a la derecha y mantiene borde amarillo mientras Timmy pide usarlo. Se eliminaron los accesos flotantes sobre el paisaje. Construcción tiene una única vista de demostración, con los botones Colocar/Reemplazar; ya no aparecen tres casillas que puedan confundirse con capacidad de la base. El crédito By: ChullaSolution está en el pie; los diálogos muestran los controles de teclado en su espacio de ayuda.

## Menú de inicio, regreso y reanudación

El flujo vigente es **tutorial → menú de inicio → Jugar → base de prueba**. El menú tiene imagen de fondo y un recuadro con tres botones. Opciones abre los controles de voz, volumen y velocidad existentes. Ver de nuevo el tutorial repite el aterrizaje y el recorrido, conservando el perfil.

La pantalla de prueba tiene **Volver al menú**. Ese botón conserva la misma instancia de la pantalla y el estado de la sesión; el menú pasa a mostrar **Reanudar partida**. Jugar y Reanudar comparten el efecto de oscurecimiento. Reanudar no vuelve a emitir mission_requested ni crea una partida nueva.

Señales para P1/P2 al incorporar la simulación real:

- `home_entered()`: el menú ya terminó su transición y recibe interacción.
- `expedition_entered()`: la pantalla de juego ya terminó su transición.
- `pause_requested(true)`: detener la simulación, el reloj y el consumo de recursos al volver al menú.
- `pause_requested(false)` y `resume_requested(profile)`: continuar la partida existente.
- `mission_requested(profile)`: solo la primera pulsación de Jugar inicia la partida.

La interfaz conserva la sesión en memoria. El guardado permanente y la pausa efectiva de los sistemas de juego siguen a cargo de P1/P2; las señales anteriores son el punto de conexión. La escena global y los módulos de simulación no fueron modificados.

## Voces predeterminadas

`ui/timmy_voice.gd` selecciona Zira para inglés y Sabina para español por su nombre, sin depender del orden de las voces del sistema. Una selección manual en Opciones tiene prioridad. Si la voz no existe en otro equipo, se usa una voz disponible de ese idioma; si no hay ninguna, se mantiene la lectura en pantalla.

Comprobación nativa en Windows de esta sesión: **en → Microsoft Zira**, **es → Microsoft Sabina**. La elección y los textos se comprobaron sin modificar la configuración de voces de Windows.

## Cambiar el modelo del astronauta

1. Guardar el nuevo modelo o su escena en la carpeta acordada con P3, por ejemplo `res://assets/3d/nuevo_astronauta.tscn`. Se admiten escenas .tscn y modelos importados .glb/.gltf con raíz Node3D.
2. Abrir `ui/intro.tscn` y seleccionar su nodo raíz.
3. En el Inspector, cambiar **Astronaut Model Path** por la ruta nueva. El valor actual es `res://assets/3d/astronauta.tscn`.
4. Si el tamaño de importación cambia, ajustar **Astronaut Model Scale** en ese mismo Inspector.

No hace falta cambiar código. Si P3 sustituye el modelo conservando exactamente el archivo y la ruta actuales, no hay que cambiar la propiedad. La cámara y las luces de la presentación se mantienen en `ui/astronaut_preview.gd`; un modelo con origen o proporciones diferentes podría necesitar que P3 normalice su escena.

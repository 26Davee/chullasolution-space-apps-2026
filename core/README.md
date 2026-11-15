# `core/` · Puesto 1 · Integración y coordinación

**Dueño:** puesto 1. Solo el dueño cambia estos archivos; los demás piden lo que necesiten en el grupo.
**Pareja de revisión:** puesto 6.

## Qué es
Arranque del juego y el script que conecta las partes.

## Qué va aquí
- `main.gd`: crea el juego, conecta las escenas de cada puesto y reparte el reloj del juego.
- Nada de lógica de otro puesto.

## Qué NO va aquí
- Reglas de la simulación (van en `simulation/`).
- Dibujo de interfaz (va en `ui/`).

## Con quién te coordinas
Todos: cada puesto te dice qué escena conectar.

## Tu primera tarea
Sáb 09:15 la estructura y el proyecto de Godot ya están subidos (comprueba que F5 muestra la Luna de prueba); 10:15 diriges la firma de contratos; 11:30 publicas el esqueleto y pruebas el enlace en una ventana privada.

## Antes de pedir un Pull Request
- El juego abre con F5.
- Anotaste en tu registro lo que usaste de IA, de terceros o de NASA.

## Estado actual (puesto 1)

- `game_state.gd`: autoload `GameState`. Las 21 variables y 12 señales del diccionario, límites, `pagar`, `instantanea()` y acciones (`solicitar_construir`, `solicitar_viaje_hielo`, `solicitar_procesar_hielo`, `solicitar_reparar_escudo`). Enchufa `simulation/simulacion.gd` y reenvía sus señales.
- `main.gd`: flujo de pantallas: intro (puesto 6) → aterrizaje (puesto 3) → juego. Traduce el modo `cadet/engineer` de la intro a `cadete/ingeniero`.
- `juego.gd`: arma el juego: mundo de Carlos, astronauta con animación de Nicolás, cámara orbital, clic para mover, colocación de piezas, misiones de Gael y HUD.
- `hud_juego.gd`: conecta el HUD visual del puesto 6 con GameState y conserva las acciones, misión y carta NASA del juego.

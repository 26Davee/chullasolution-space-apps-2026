extends Node3D
## Escena de juego (provisional, puesto 1): luz, suelo, cámara semiisométrica y
## el astronauta de Carlos, más un panel de depuración con el estado vivo.
##
## Los puestos reemplazan sus partes por las reales sin tocar este flujo:
##   - Nicolás (puesto 4): la cámara y el movimiento del astronauta.
##   - Carlos (puesto 3): el terreno y los módulos.
##   - Andrea (puesto 6): el HUD (el panel de depuración se retira al final).

signal salir_al_menu

@onready var _camara: Camera3D = $Camara
@onready var _astronauta: Node3D = $Astronauta
@onready var _debug: Label = $Interfaz/Debug


func _ready() -> void:
	_camara.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	_astronauta.rotation.y = PI  # mira hacia la cámara
	GameState.recurso_actualizado.connect(_refrescar_debug_ignorando)
	GameState.partida_iniciada.connect(_refrescar_debug_ignorando)
	_refrescar_debug()


func _exit_tree() -> void:
	if GameState.recurso_actualizado.is_connected(_refrescar_debug_ignorando):
		GameState.recurso_actualizado.disconnect(_refrescar_debug_ignorando)
	if GameState.partida_iniciada.is_connected(_refrescar_debug_ignorando):
		GameState.partida_iniciada.disconnect(_refrescar_debug_ignorando)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		GameState.terminar_partida()
		salir_al_menu.emit()


func _process(_delta: float) -> void:
	_refrescar_debug()


func _refrescar_debug_ignorando(_a = null, _b = null, _c = null) -> void:
	_refrescar_debug()


func _refrescar_debug() -> void:
	var g := GameState
	_debug.text = "[ESTADO — panel provisional]\n" \
		+ "Modo: %s    Tiempo: %d s    %s\n" % [g.modo_juego, int(g.tiempo_juego), "DÍA" if g.es_dia else "NOCHE"] \
		+ "Energía %.0f/%.0f   Agua %.0f/%.0f   Oxígeno %.0f   Vida %.0f   Escudo %.0f   Hielo %d\n" \
			% [g.energia, g.maximo_de("energia"), g.agua, g.agua_max, g.oxigeno, g.vida, g.escudo, g.hielo] \
		+ "Estrellas %d   Paneles %d   Simulación: %s\n" % [g.estrellas, g.paneles_instalados, "conectada" if g.hay_simulacion() else "pendiente"] \
		+ "Esc = volver al título"

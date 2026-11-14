extends Node
## Main — flujo de pantallas: intro (puesto 6) → aterrizaje (puesto 3) → juego. Dueño: puesto 1.
##
## El perfil que entrega la intro trae "mode" ("cadet" o "engineer"). Aquí se traduce a los
## modos del diccionario ("cadete" / "ingeniero") y se arranca GameState.

const INTRO := preload("res://ui/intro.tscn")
const ATERRIZAJE := preload("res://world/landing_intro.tscn")
const JUEGO := preload("res://scenes/juego.tscn")

var _pantalla: Node = null
var _perfil: Dictionary = {}


func _ready() -> void:
	mostrar_intro()


func mostrar_intro() -> void:
	GameState.reiniciar()
	var intro := INTRO.instantiate()
	intro.mission_requested.connect(_al_pedir_mision)
	_cambiar_pantalla(intro)


func mostrar_aterrizaje() -> void:
	var aterrizaje := ATERRIZAJE.instantiate()
	aterrizaje.completed.connect(mostrar_juego, CONNECT_DEFERRED | CONNECT_ONE_SHOT)
	_cambiar_pantalla(aterrizaje)


func mostrar_juego() -> void:
	var modo: String = GameState.MODO_INGENIERO if _perfil.get("mode", "cadet") == "engineer" else GameState.MODO_CADETE
	GameState.iniciar_partida(modo)
	var juego := JUEGO.instantiate()
	juego.salir_al_menu.connect(_volver_a_la_intro, CONNECT_DEFERRED)
	if juego.has_method("configurar"):
		juego.configurar(_perfil)
	_cambiar_pantalla(juego)


func _al_pedir_mision(perfil: Dictionary) -> void:
	_perfil = perfil
	call_deferred("mostrar_aterrizaje")


func _volver_a_la_intro() -> void:
	GameState.terminar_partida()
	mostrar_intro()


func _cambiar_pantalla(nueva: Node) -> void:
	if _pantalla != null:
		_pantalla.queue_free()
	_pantalla = nueva
	add_child(nueva)

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
var _intro: Control = null
var _juego: Node = null


func _ready() -> void:
	mostrar_intro()


func mostrar_intro() -> void:
	GameState.reiniciar()
	var intro := INTRO.instantiate()
	_intro = intro
	intro.mission_requested.connect(_al_pedir_mision)
	intro.pause_requested.connect(_al_pausar_partida)
	intro.resume_requested.connect(_reanudar_partida)
	_cambiar_pantalla(intro)


func mostrar_aterrizaje() -> void:
	var aterrizaje := ATERRIZAJE.instantiate()
	aterrizaje.completed.connect(mostrar_juego, CONNECT_DEFERRED | CONNECT_ONE_SHOT)
	_cambiar_pantalla(aterrizaje)


func mostrar_juego() -> void:
	var modo: String = GameState.MODO_INGENIERO if _perfil.get("mode", "cadet") == "engineer" else GameState.MODO_CADETE
	GameState.iniciar_partida(modo)
	var juego := JUEGO.instantiate()
	_juego = juego
	juego.salir_al_menu.connect(_volver_a_la_intro, CONNECT_DEFERRED)
	if juego.has_method("configurar"):
		juego.configurar(_perfil)
	_cambiar_pantalla(juego)


func _al_pedir_mision(perfil: Dictionary) -> void:
	_perfil = perfil
	if is_instance_valid(_juego):
		_reanudar_partida(perfil)
		return
	call_deferred("mostrar_aterrizaje")


func _volver_a_la_intro() -> void:
	if not is_instance_valid(_juego) or not is_instance_valid(_intro):
		return
	GameState.en_partida = false
	_juego.process_mode = Node.PROCESS_MODE_DISABLED
	_juego.hide()
	_intro.show()
	_intro.call("show_pause_menu")
	_pantalla = _intro


func _al_pausar_partida(paused: bool) -> void:
	GameState.en_partida = not paused
	if paused and is_instance_valid(_juego):
		_juego.process_mode = Node.PROCESS_MODE_DISABLED
		_juego.hide()


func _reanudar_partida(_perfil_reanudado: Dictionary) -> void:
	if not is_instance_valid(_juego) or not is_instance_valid(_intro):
		return
	GameState.en_partida = true
	_juego.process_mode = Node.PROCESS_MODE_INHERIT
	_juego.show()
	_intro.hide()
	_pantalla = _juego


func _cambiar_pantalla(nueva: Node) -> void:
	if _pantalla == _intro and nueva != _intro:
		_intro.hide()
	elif _pantalla != null and _pantalla != nueva:
		_pantalla.queue_free()
	_pantalla = nueva
	if nueva.get_parent() != self:
		add_child(nueva)
	nueva.show()

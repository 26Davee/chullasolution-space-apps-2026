extends Node
## Keeps the real world alive while menus/tutorial review are open.
const ESCENA_INTRO := "res://ui/intro.tscn"
const ESCENA_JUEGO := "res://scenes/juego.tscn"
var _pantalla: Node
var _juego: Node3D
var _intro: Control
var _menu: Control
var _menu_layer: CanvasLayer
var _transitioning = false

func _gs() -> Node:
	return get_node("/root/GameState")
func _ready() -> void:
	preload("res://ui/ui_kit.gd").register_translations()
	var data: Dictionary = _gs().obtener_save_manager().obtener_datos_completos()
	var profile: Dictionary = data.get("perfil",{})
	if bool(profile.get("tutorial_completed",false)):
		_gs().modo_juego = _gs().aplicar_perfil(profile)
		mostrar_titulo()
	else:
		_show_intro(false)
	if not _gs().obtener_save_manager().ultimo_error.is_empty(): call_deferred("_show_load_notice")

func _show_intro(review: bool) -> void:
	if is_instance_valid(_juego):
		_juego.set_paused(true)
		_show_world(false)
	if is_instance_valid(_menu): _menu.hide()
	if is_instance_valid(_intro): _intro.queue_free()
	_intro = load(ESCENA_INTRO).instantiate()
	_intro.language = _gs().idioma
	if review:
		_intro.tutorial.player.nickname = _gs().nombre_astronauta
		_intro.tutorial.player.choose_age("7_9" if _gs().modo_juego == "cadete" else "10_12")
	_intro.mission_requested.connect(func(profile):
		if review:
			_intro.hide()
			mostrar_titulo()
		else: _al_solicitar_mision_desde_intro(profile)
	)
	if review:
		_intro.home_entered.connect(func():
			_intro.hide()
			mostrar_titulo()
		)
	add_child(_intro)
	_pantalla = _intro

func _al_solicitar_mision_desde_intro(profile: Dictionary) -> void:
	var mode = _gs().aplicar_perfil(profile)
	iniciar_juego(mode)

func iniciar_juego(mode: String) -> void:
	if is_instance_valid(_intro):
		_intro.queue_free()
		_intro = null
	if is_instance_valid(_menu_layer): _menu_layer.hide()
	if is_instance_valid(_juego):
		_show_world(true)
		_juego.set_paused(false)
	else:
		_gs().iniciar_partida(mode)
		_gs().aplicar_legado()
		_juego = load(ESCENA_JUEGO).instantiate()
		_juego.salir_al_menu.connect(mostrar_titulo)
		add_child(_juego)
	_pantalla = _juego
	_juego.call_deferred("_maybe_show_reward")
	_juego.call_deferred("check_recovery")

func mostrar_titulo() -> void:
	if is_instance_valid(_juego):
		_juego.set_paused(true)
		_show_world(false)
	_gs().en_partida = false
	if is_instance_valid(_intro): _intro.hide()
	if is_instance_valid(_menu_layer): _menu_layer.queue_free()
	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = 20
	add_child(_menu_layer)
	_menu = preload("res://ui/home_menu.gd").new()
	_menu.size = Vector2(1280,720)
	_menu.nickname = _gs().nombre_astronauta
	var saved: Dictionary = _gs().obtener_save_manager().obtener_datos_completos().get("expedicion",{})
	_menu.resume_available = is_instance_valid(_juego) or not saved.is_empty()
	_menu_layer.add_child(_menu)
	_menu.play_requested.connect(_play_with_fade)
	_menu.options_requested.connect(_menu_options)
	_menu.tutorial_requested.connect(func(): _menu_layer.hide(); _show_intro(true))
	_pantalla = _menu
	_menu.play_button.grab_focus()

func _play_with_fade() -> void:
	if _transitioning: return
	_transitioning = true
	var fade_layer = CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.size = Vector2(1280,720)
	fade.modulate.a = 0
	fade_layer.add_child(fade)
	var tween = create_tween()
	tween.tween_property(fade,"modulate:a",1.0,0.45)
	await tween.finished
	var mode = str(_gs().preferencias.get("mode",_gs().modo_juego))
	iniciar_juego(mode)
	await get_tree().process_frame
	tween = create_tween()
	tween.tween_property(fade,"modulate:a",0.0,0.45)
	await tween.finished
	fade_layer.queue_free()
	_transitioning = false

func _menu_options() -> void:
	if not is_instance_valid(_juego):
		_gs().iniciar_partida(str(_gs().preferencias.get("mode","cadete")))
		_juego = load(ESCENA_JUEGO).instantiate()
		_juego.home_paused = true
		_juego.salir_al_menu.connect(mostrar_titulo)
		add_child(_juego)
		await get_tree().process_frame
		await get_tree().process_frame
	_show_world(true)
	_juego.set_paused(true)
	_menu_layer.hide()
	_juego.options_from_home = true
	if not _juego.options_closed.is_connected(mostrar_titulo): _juego.options_closed.connect(mostrar_titulo)
	_juego._open_audio_modal()

func mostrar_menu_modo() -> void:
	_show_intro(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(_juego) and _juego.session != null:
		_juego.session.save_run()

func _show_load_notice() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 80
	add_child(layer)
	var ui = preload("res://ui/ui_kit.gd")
	var shade = ColorRect.new()
	shade.size = Vector2(1280,720)
	shade.color = Color(0.01,0.03,0.06,0.85)
	layer.add_child(shade)
	var panel = ui.panel(layer,Rect2(280,210,720,300),ui.INK)
	var key = "live.load_backup" if _gs().obtener_save_manager().respaldo_recuperado else "live.load_fresh"
	ui.label(panel,tr(key),Rect2(32,34,656,160),25,ui.WHITE)
	var button = ui.button(panel,tr("live.continue"),Rect2(32,220,656,50),func(): layer.queue_free(),true)
	button.grab_focus()

func _show_world(value: bool) -> void:
	if not is_instance_valid(_juego): return
	_juego.visible = value
	if is_instance_valid(_juego.interfaz): _juego.interfaz.visible = value
	if not value and is_instance_valid(_juego._voice): _juego._voice.stop()

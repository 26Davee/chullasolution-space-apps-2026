extends Node
## Keeps the real world alive while menus/tutorial review are open.
const ESCENA_INTRO := "res://ui/intro.tscn"
const ESCENA_JUEGO := "res://scenes/juego.tscn"
var _pending_tutorial_slot := 1
var _pantalla: Node
var _juego: Node3D
var _intro: Control
var _menu: Control
var _menu_layer: CanvasLayer
var _slots_panel: Control
var _slot_setup: Control
var _transitioning = false
var _fade_layer: CanvasLayer
var _fade_token: int = 0

func _gs() -> Node:
	return get_node("/root/GameState")
func _ready() -> void:
	preload("res://ui/ui_kit.gd").register_translations()
	var sm: Node = _gs().obtener_save_manager()
	var data: Dictionary = sm.obtener_datos_completos()
	var profile: Dictionary = data.get("perfil", {})
	if profile.is_empty() and sm.hay_algun_slot_ocupado():
		for info in sm.listar_slots():
			if bool(info.get("occupied", false)):
				sm.seleccionar_slot(int(info.get("slot", 1)))
				data = sm.obtener_datos_completos()
				profile = data.get("perfil", {})
				break
	if not profile.is_empty():
		_gs().modo_juego = _gs().aplicar_perfil(profile)
	mostrar_titulo()
	if not sm.ultimo_error.is_empty(): call_deferred("_show_load_notice")

func _show_intro(review: bool, preset_profile: Dictionary = {}) -> void:
	if is_instance_valid(_juego):
		_juego.set_paused(true)
		_show_world(false)
	if is_instance_valid(_menu): _menu.hide()
	if is_instance_valid(_slot_setup):
		_slot_setup.queue_free()
		_slot_setup = null
	if is_instance_valid(_intro): _intro.queue_free()
	_intro = load(ESCENA_INTRO).instantiate()
	_intro.language = str(preset_profile.get("language", _gs().idioma))
	_intro.auto_start_tutorial = true
	_intro.launch_direct_to_game = not review
	if review:
		var current_profile: Dictionary = _gs().preferencias.duplicate(true)
		if str(current_profile.get("nickname", "")).is_empty():
			current_profile["nickname"] = _gs().nombre_astronauta
		if str(current_profile.get("age_group", "")).is_empty():
			current_profile["age_group"] = "7_9" if _gs().modo_juego == "cadete" else "10_12"
		_intro.apply_profile_dict(current_profile)
	elif not preset_profile.is_empty():
		_intro.apply_profile_dict(preset_profile)
	_intro.home_entered.connect(func():
		var sm: Node = _gs().obtener_save_manager()
		sm.marcar_tutorial_visto(true)
		_gs().idioma = _intro.language
		_gs().voz_activa = not _intro.voice.muted
		for key in ["voice_enabled","voice_volume","voice_rate","voices"]:
			if _intro.state.preferencias.has(key): _gs().preferencias[key] = _intro.state.preferencias[key]
		_gs().preferencias["voice_enabled"] = _gs().voz_activa
		_intro.queue_free()
		_intro = null
		if review: mostrar_titulo()
		else: _create_slot_setup(_pending_tutorial_slot)
	)
	add_child(_intro)
	_pantalla = _intro

func _al_solicitar_mision_desde_intro(profile: Dictionary) -> void:
	var updated := profile.duplicate(true)
	updated["tutorial_completed"] = true
	var mode: String = _gs().aplicar_perfil(updated)
	var sm: Node = _gs().obtener_save_manager()
	if sm != null and sm.has_method("marcar_tutorial_visto"):
		sm.marcar_tutorial_visto(true)
	if sm != null and sm.has_method("guardar_perfil"):
		sm.guardar_perfil(_gs().preferencias)
	iniciar_juego(mode)

func iniciar_juego(mode: String) -> void:
	if is_instance_valid(_slot_setup):
		_slot_setup.queue_free()
		_slot_setup = null
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
		if _juego.get("session") != null and not _juego.session.loading and not _juego.home_paused and _gs().en_partida:
			_juego.session.save_run()
		_juego.set_paused(true)
		_show_world(false)
	_gs().en_partida = false
	if is_instance_valid(_intro): _intro.hide()
	if is_instance_valid(_slot_setup):
		_slot_setup.queue_free()
		_slot_setup = null
	if is_instance_valid(_slots_panel):
		_slots_panel.queue_free()
		_slots_panel = null
	if is_instance_valid(_menu_layer): _menu_layer.queue_free()
	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = 20
	add_child(_menu_layer)
	var sm: Node = _gs().obtener_save_manager()
	var panel := preload("res://ui/save_slots_panel.gd").new()
	panel.is_home_screen = true
	panel.save_manager = sm
	var saved: Dictionary = sm.obtener_datos_completos().get("expedicion", {})
	panel.resume_available = is_instance_valid(_juego) or not saved.is_empty()
	panel.slot_selected.connect(func(slot_id: int, is_new_game: bool):
		if is_new_game:
			nueva_partida_en_slot(slot_id)
		else:
			cargar_slot(slot_id)
	)
	panel.slot_deleted.connect(func(slot_id: int):
		if slot_id == sm.active_slot and is_instance_valid(_juego):
			_juego.queue_free()
			_juego = null
		sm.borrar_slot(slot_id)
		if slot_id == sm.active_slot:
			_gs().reiniciar()
		var after_saved: Dictionary = sm.obtener_datos_completos().get("expedicion", {})
		panel.resume_available = is_instance_valid(_juego) or not after_saved.is_empty()
		panel.refresh()
	)
	panel.tutorial_requested.connect(func():
		_menu_layer.hide()
		_show_intro(true)
	)
	panel.options_requested.connect(_menu_options)
	panel.language_changed.connect(func(lang: String):
		_gs().idioma = lang
		TranslationServer.set_locale(lang)
		sm.guardar_idioma(lang)
		panel.refresh()
	)
	_menu_layer.add_child(panel)
	_slots_panel = panel
	_menu = panel
	_pantalla = panel
	if panel.play_button != null:
		panel.play_button.grab_focus()


func _open_slots_modal() -> void:
	mostrar_titulo()


func nueva_partida_en_slot(slot_id: int) -> void:
	var sm: Node = _gs().obtener_save_manager()
	if is_instance_valid(_juego):
		if _juego.get("session") != null and not _juego.session.loading and slot_id != sm.active_slot:
			_juego.session.save_run()
		_juego.queue_free()
		_juego = null
	if is_instance_valid(_slots_panel):
		_slots_panel.queue_free()
		_slots_panel = null
	if is_instance_valid(_slot_setup):
		_slot_setup.queue_free()
		_slot_setup = null
	sm.borrar_slot(slot_id)
	sm.seleccionar_slot(slot_id)
	_gs().reiniciar()
	if not is_instance_valid(_menu_layer):
		_menu_layer = CanvasLayer.new()
		_menu_layer.layer = 20
		add_child(_menu_layer)
	_menu_layer.show()
	if not sm.fue_tutorial_visto():
		_pending_tutorial_slot = slot_id
		_menu_layer.hide()
		_show_intro(false)
		return
	_create_slot_setup(slot_id)

func _create_slot_setup(slot_id: int) -> void:
	_menu_layer.show()
	var setup := preload("res://ui/new_slot_setup.gd").new()
	setup.slot_id = slot_id
	setup.language = _gs().idioma
	setup.confirmed.connect(_on_new_slot_confirmed)
	setup.cancelled.connect(mostrar_titulo)
	_menu_layer.add_child(setup)
	_slot_setup = setup
	_menu = setup
	_pantalla = setup


func _on_new_slot_confirmed(profile: Dictionary) -> void:
	var sm: Node = _gs().obtener_save_manager()
	var updated := profile.duplicate(true)
	updated["voice_enabled"] = _gs().voz_activa
	for key in ["voice_volume","voice_rate","voices"]:
		if _gs().preferencias.has(key): updated[key] = _gs().preferencias[key]
	var seen: bool = sm != null and sm.has_method("fue_tutorial_visto") and sm.fue_tutorial_visto()
	updated["tutorial_completed"] = seen
	var mode: String = _gs().aplicar_perfil(updated)
	if sm != null and sm.has_method("guardar_perfil"):
		sm.guardar_perfil(_gs().preferencias)
	if is_instance_valid(_slot_setup):
		_slot_setup.queue_free()
		_slot_setup = null
	if is_instance_valid(_menu_layer):
		_menu_layer.hide()
	if not seen:
		_show_intro(false, updated)
	else:
		_gs().modo_juego = mode
		mostrar_titulo()


func cargar_slot(slot_id: int) -> void:
	var sm: Node = _gs().obtener_save_manager()
	if is_instance_valid(_slots_panel):
		_slots_panel.queue_free()
		_slots_panel = null
	if slot_id == sm.active_slot and is_instance_valid(_juego) and not _juego.home_paused:
		_play_with_fade()
		return
	if is_instance_valid(_juego):
		if _juego.get("session") != null and not _juego.session.loading and not _juego.home_paused:
			_juego.session.save_run()
		_juego.queue_free()
		_juego = null
	sm.seleccionar_slot(slot_id)
	var data: Dictionary = sm.obtener_datos_completos()
	var profile: Dictionary = data.get("perfil", {})
	_gs().reiniciar()
	if not profile.is_empty():
		_gs().modo_juego = _gs().aplicar_perfil(profile)
	else:
		_gs().modo_juego = str(sm.obtener_modo_preferido())
	_play_with_fade()

func _play_with_fade() -> void:
	_fade_token += 1
	var token := _fade_token
	if is_instance_valid(_fade_layer):
		_fade_layer.queue_free()
		_fade_layer = null
	_transitioning = true
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	_fade_layer = fade_layer
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.size = Vector2(1280, 720)
	fade.modulate.a = 0
	fade_layer.add_child(fade)
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.35)
	await tween.finished
	if token != _fade_token or not is_instance_valid(fade_layer):
		return
	var mode: String = str(_gs().preferencias.get("mode", _gs().modo_juego))
	iniciar_juego(mode)
	_transitioning = false
	await get_tree().process_frame
	if token != _fade_token or not is_instance_valid(fade_layer):
		return
	tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 0.35)
	await tween.finished
	if is_instance_valid(fade_layer):
		fade_layer.queue_free()
	if _fade_layer == fade_layer:
		_fade_layer = null

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
	nueva_partida_en_slot(_gs().obtener_save_manager().active_slot)

func _notification(what: int) -> void:
	if (what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE) and is_instance_valid(_juego) and _juego.get("session") != null and not _juego.session.loading:
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

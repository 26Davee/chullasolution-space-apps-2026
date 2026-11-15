extends "res://core/juego.gd"
## Live UI adapter: world actions stay in core/juego and P4, run transactions in RunSession.
signal options_closed
var options_from_home = false
var _swapping_modal = false
const SessionScript = preload("res://progression/run_session.gd")
const LiveHud = preload("res://ui/live_hud.gd")
const ScienceCollection = preload("res://ui/science_collection.gd")
const MODULES := ["panel_solar", "procesador_hielo", "generador_oxigeno", "tanque_agua", "jardin"]
const MODULE_ART := {"panel_solar": "solar", "procesador_hielo": "processor", "generador_oxigeno": "oxygen", "jardin": "garden"}
var session: Node
var home_paused = false
var _session_ready = false
var _last_advice = ""
var _toast_queue: Array = []
var _alerted: Dictionary = {}
var _goal_progress: ProgressBar
var _timmy_button: Button
var _mail_button: Button
var _focus_before: Control
var _action = ""
var _action_remaining = 0.0
var _action_total = 0.0
var _action_progress: ProgressBar
var _action_panel: Panel
var _action_label: Label
var _telemetry_timer = 0.0
var _voice_refresh_elapsed = 0.0
var _audio_voice_signature = ""
var _goals: Dictionary = {}
var _mail_badge: Label
var rail: Control
var ice: Node
var _coach_target = ""
var _trip_collected = false
var _trip_ice = 0
var _trip_alerted = false

func tx(key: String, values: Dictionary = {}) -> String:
	return tr("live." + key).format(values)

func _post_ready_init() -> void:
	var gs = _gs()
	if not gs.en_partida: gs.iniciar_partida(gs.modo_juego)
	ice = preload("res://ui/ice_expedition.gd").new()
	add_child(ice)
	ice.setup(self)
	ice.changed.connect(_on_ice_changed)
	click_to_move.station_clicked.connect(_on_station_clicked)
	_bind_stations()
	session = SessionScript.new()
	add_child(session)
	session.setup(self)
	session.reward_ready.connect(func(_reward): _maybe_show_reward())
	session.checkpoint_saved.connect(func(ok): _show_toast(tx("checkpoint" if ok else "save_error")))
	session.campaign_finished.connect(func(): _maybe_show_reward())
	session.begin()
	_session_ready = true
	_bridge._zero_handled = false
	_bridge.configure_profile({"nickname": _player_name(), "mode": gs.modo_juego})
	gs.obtener_mission_manager().progreso_objetivo_actualizado.connect(func(_id, _done, _total): _refresh_active_mission_panel())
	gs.obtener_mission_manager().mision_fallida.connect(func(id, text):
		session.add_message("failure:" + id + ":" + str(roundi(gs.tiempo_juego)), "text", {"text": text})
		_show_toast(text, 5.0)
	)
	placement_system.piece_catalog[&"tanque_agua"] = load("res://assets/3d/tanque_agua.tscn")
	placement_system.placement_rejected.connect(func(_id, _reason): _show_toast(tx("blocked")))
	_sync_all_from_state()
	_refresh_mail_badge()
	if session.restored or home_paused or DisplayServer.get_name() == "headless":
		_activar_camara_juego()
		set_paused(home_paused)
		call_deferred("_maybe_show_reward")
		_bridge._check_failure()
		if DisplayServer.get_name() != "headless": call_deferred("_offer_tour")
	else:
		gs.en_partida = false
		_start_landing_cinematic()

func _setup_bridge_and_ui() -> void:
	var goal_data = JSON.new()
	if FileAccess.file_exists("res://ui/mission_goals.json") and goal_data.parse(FileAccess.get_file_as_string("res://ui/mission_goals.json")) == OK and goal_data.data is Dictionary:
		_goals = goal_data.data
	_catalog = CatalogScript.new()
	_bridge = BridgeScript.new()
	add_child(_bridge)
	_voice = VoiceScript.new()
	add_child(_voice)
	var gs = _gs()
	_voice.muted = not gs.voz_activa
	_voice.volume = int(gs.preferencias.get("voice_volume", 85))
	_voice.rate = float(gs.preferencias.get("voice_rate", 0.95))
	_voice.selected_voices = gs.preferencias.get("voices", {}).duplicate(true)
	_bridge.bind_state(gs)
	_bridge.begin_live({"nickname": _player_name(), "mode": gs.modo_juego})
	_bridge.state_changed.connect(_on_bridge_state_changed)
	_bridge.content_changed.connect(_on_bridge_content_changed)
	_bridge.upgrade_requested.connect(_on_upgrade_requested)
	_bridge.recovery_requested.connect(_on_recovery_requested)
	_ui_root = Control.new()
	_ui_root.name = "GameOverlay"
	_ui_root.size = Vector2(1280,720)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interfaz.add_child(_ui_root)
	_hud = LiveHud.new()
	_hud.position = Vector2(16, 8)
	_ui_root.add_child(_hud)
	_hud.resource_pressed.connect(_on_resource_pressed)
	_hud.set_mode(gs.modo_juego)
	_build_side_mission_card()
	_build_top_toolbar()
	_build_bottom_dock()
	_build_placement_and_toast()
	debug_label.hide()

func _build_side_mission_card() -> void:
	_mission_panel = UI.panel(_ui_root, Rect2(16, 594, 408, 110), Color("#071b32ee"), 16)
	_mission_title = UI.label(_mission_panel, "", Rect2(14,10,380,24), 16, UI.GOLD, true)
	_mission_desc = UI.label(_mission_panel, "", Rect2(14,38,380,44), 16, UI.WHITE)
	_mission_desc.max_lines_visible = 2
	_mission_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_mission_panel.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: _open_section_modal("missions")
	)
	_goal_progress = ProgressBar.new()
	_goal_progress.show_percentage = false
	_goal_progress.add_theme_font_size_override("font_size", 1)
	_goal_progress.add_theme_stylebox_override("background", UI.style(Color("#34445e")))
	_goal_progress.add_theme_stylebox_override("fill", UI.style(UI.CYAN))
	_mission_panel.add_child(_goal_progress)
	_goal_progress.position = Vector2(14,90)
	_goal_progress.size = Vector2(220,6)
	_mission_reward = UI.label(_mission_panel, "", Rect2(244,82,150,20), 13, UI.CYAN)
	_storm_badge = UI.panel(_ui_root, Rect2(432,144,416,42), Color("#631b1bee"),12)
	_storm_badge.hide()
	_storm_label = UI.label(_storm_badge, "", Rect2(14,7,388,28),15,UI.WHITE,true)

func icon_button(parent: Node, kind: String, rect: Rect2, label: String, callback: Callable, active := false) -> Button:
	var button = UI.button(parent, "", rect, callback, active)
	button.tooltip_text = label
	button.set_meta("accessible_name", label)
	var icon = Icon.new()
	icon.kind = kind
	icon.disc = false
	icon.tint = UI.INK if active else UI.CYAN
	icon.size = Vector2(28,28)
	icon.position = (rect.size - icon.size)/2
	button.add_child(icon)
	return button

func _build_top_toolbar() -> void:
	_menu_button = icon_button(_ui_root,"menu",Rect2(1208,8,56,40),tx("menu"),_open_section_menu,true)
	rail = preload("res://ui/station_rail.gd").new()
	rail.position = Vector2(1116,146)
	_ui_root.add_child(rail)
	rail.section_requested.connect(_on_dock_action)
	_cam_button = icon_button(_ui_root,"camera",Rect2(1044,644,56,56),tx("help"),_toggle_camera_target)
	_timmy_button = UI.button(_ui_root,"Timmy",Rect2(1116,636,148,60),_open_timmy,true)
	_mail_button = rail.buttons.messages
	_mail_badge = UI.label(_mail_button,"",Rect2(124,-7,24,24),13,UI.INK,true)
	var badge_style = UI.style(UI.GOLD,Color.TRANSPARENT,0,12)
	badge_style.content_margin_left = 0
	badge_style.content_margin_right = 0
	_mail_badge.add_theme_stylebox_override("normal",badge_style)
	_mail_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mail_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mail_badge.size = Vector2(24,24)

func _build_bottom_dock() -> void:
	# A contextual drawer replaces the permanent eight-button dock.
	_build_tray = UI.panel(_ui_root,Rect2(16,486,1024,218),Color("#071b32fa"),18)
	_build_tray.mouse_filter = Control.MOUSE_FILTER_STOP
	_build_tray.hide()
	_controls_hint = UI.label(_ui_root,"",Rect2(440,676,600,22),13,UI.WHITE)
	_controls_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controls_hint.hide()

func _build_placement_and_toast() -> void:
	_placement_banner = UI.panel(_ui_root,Rect2(296,158,688,48),Color("#071b32f7"),14)
	_placement_banner.hide()
	_placement_label = UI.label(_placement_banner,"",Rect2(18,10,652,28),16,UI.GOLD,true)
	_toast_panel = UI.panel(_ui_root,Rect2(436,594,608,66),Color("#071b32f7"),16)
	_toast_panel.hide()
	_toast_label = UI.label(_toast_panel,"",Rect2(18,12,572,44),17,UI.WHITE)
	_action_panel = UI.panel(_ui_root,Rect2(436,526,608,56),Color("#102b46f7"),14)
	_action_panel.hide()
	_action_label = UI.label(_action_panel,"",Rect2(16,6,576,26),16,UI.CYAN,true)
	_action_progress = ProgressBar.new()
	_action_progress.show_percentage = false
	_action_progress.add_theme_font_size_override("font_size",1)
	_action_panel.add_child(_action_progress)
	_action_progress.position = Vector2(16,36)
	_action_progress.size = Vector2(576,8)

func _process(delta: float) -> void:
	super._process(delta)
	if not _session_ready: return
	if _toast_timer <= 0 and not _toast_queue.is_empty() and not is_instance_valid(_modal_layer) and not home_paused:
		var item: Dictionary = _toast_queue.pop_front()
		_toast_label.text = str(item.text)
		_toast_timer = float(item.seconds)
		_toast_panel.show()
		if bool(item.get("voice",false)): _speak(str(item.text))
	if _modal_kind == "audio":
		_voice_refresh_elapsed += delta
		if _voice_refresh_elapsed >= 0.5:
			_voice_refresh_elapsed = 0
			_refresh_audio_voices()
	if not _gs().en_partida: return
	if not _action.is_empty():
		_action_remaining -= delta
		_action_progress.value = 100 * (1 - maxf(_action_remaining,0) / _action_total)
		if _action_remaining <= 0:
			var action = _action
			_action = ""
			_action_panel.hide()
			if action == "processing": super._run_processing()
			else: super._run_repair()
	_telemetry_timer += delta
	if _telemetry_timer >= 0.5:
		_telemetry_timer = 0
		_refresh_active_mission_panel()
		_check_resource_alerts()
		_hud.set_state(_bridge.get_state())
		_mail_button.tooltip_text = tx("messages") + " · %d" % session.unread_count()
		_mail_badge.visible = session.unread_count() > 0
		_mail_badge.text = str(session.unread_count())

func set_paused(paused: bool) -> void:
	if paused and is_instance_valid(_voice): _voice.stop()
	home_paused = paused
	_apply_pause()

func _apply_pause() -> void:
	var blocked = home_paused or is_instance_valid(_modal_layer) or _landing_active or (session != null and session.finished)
	_gs().en_partida = not blocked
	_set_gameplay_input_enabled(not blocked)
	placement_system.set_process_unhandled_input(not blocked)
	placement_system.set_physics_process(not blocked)
	# Robot animations and movement are paused with the world; UI and voice remain active.
	robot.process_mode = Node.PROCESS_MODE_DISABLED if blocked else Node.PROCESS_MODE_INHERIT
	for node in [mundo, vicuna, tormenta, estructuras_colocadas]:
		node.process_mode = Node.PROCESS_MODE_DISABLED if blocked else Node.PROCESS_MODE_INHERIT

func _on_landing_completed() -> void:
	super._on_landing_completed()
	_apply_pause()
	_maybe_show_reward()
	call_deferred("_offer_tour")

func _open_modal(kind: String, title: String, panel_size: Vector2) -> Control:
	if is_instance_valid(_voice): _voice.stop()
	_focus_before = get_viewport().gui_get_focus_owner()
	_swapping_modal = true
	var panel = super._open_modal(kind,title,panel_size)
	_swapping_modal = false
	_build_tray.hide()
	_toast_panel.hide()
	_mission_panel.hide()
	_apply_pause()
	UI.label(panel,tx("paused"),Rect2(28,panel_size.y-30,panel_size.x-56,22),12,UI.CYAN)
	call_deferred("_trap_focus")
	return panel

func _close_modal() -> void:
	if is_instance_valid(_voice): _voice.stop()
	for queued in _toast_queue:
		if queued.has("voice"): queued.voice = false
	var notify_home = options_from_home and not _swapping_modal
	super._close_modal()
	if notify_home:
		options_from_home = false
		options_closed.emit()
	if is_instance_valid(_mission_panel): _mission_panel.show()
	if _session_ready:
		_apply_pause()
		call_deferred("_maybe_show_reward")
	if is_instance_valid(_focus_before) and _focus_before.is_visible_in_tree(): _focus_before.grab_focus()

func _trap_focus() -> void:
	if not is_instance_valid(_modal_layer): return
	var controls: Array[Control] = []
	for node in _modal_layer.find_children("*","Control",true,false):
		if node.is_visible_in_tree() and node.focus_mode == Control.FOCUS_ALL and not (node is BaseButton and node.disabled): controls.append(node)
	if controls.is_empty(): return
	for i in controls.size():
		controls[i].focus_next = controls[i].get_path_to(controls[(i+1)%controls.size()])
		controls[i].focus_previous = controls[i].get_path_to(controls[posmod(i-1,controls.size())])
	controls[0].grab_focus()

func _open_section_menu() -> void:
	var panel = _open_modal("menu",tx("menu"),Vector2(580,470))
	UI.button(panel,tx("settings"),Rect2(28,88,524,52),_open_audio_modal)
	UI.button(panel,tx("help"),Rect2(28,154,524,52),_open_controls)
	UI.button(panel,"Timmy · "+tx("help"),Rect2(28,220,524,52),func(): _show_coach("tour"))
	UI.button(panel,tx("home"),Rect2(28,300,524,54),_return_home,true)
	UI.button(panel,tx("back"),Rect2(28,370,524,48),_close_modal)

func _on_dock_action(id: String) -> void:
	if session != null and not session.learned.has(id):
		_show_coach(id)
	else:
		_perform_station(id)

func _perform_station(id: String) -> void:
	if id == "construction": _build_catalog()
	elif id in ["expedition","processing","repair","rest"]: _open_action(id)
	elif id == "messages": _open_messages()
	else: _open_section_modal(id)

func _open_section_modal(section: String) -> void:
	var panel = _open_modal("section:"+section,tx(section),Vector2(1200,672))
	var holder = Control.new()
	holder.position = Vector2(28,78)
	holder.size = Vector2(1144,548)
	panel.add_child(holder)
	if section in ["missions","upgrades"]:
		var items: Array[Dictionary] = _catalog.upgrades(false) if section == "upgrades" else _catalog.missions(false)
		var view: Control = (UpgradeTreeScript if section == "upgrades" else MissionListScript).new()
		view.size = holder.size
		view.configure(items,_build_progression_dict(),false,_gs().modo_juego)
		holder.add_child(view)
		if view.has_signal("purchase_requested"): view.purchase_requested.connect(_on_upgrade_requested)
		_progression_view = view
	elif section == "science":
		var science = ScienceCollection.new()
		science.size = holder.size
		science.cards = _science_cards()
		holder.add_child(science)
		science.narration_requested.connect(_speak)

func _science_cards() -> Array:
	var result: Array = []
	var gs = _gs()
	var sm: Node = gs.obtener_save_manager()
	var mm: Node = gs.obtener_mission_manager()
	for mission in mm.obtener_todas_las_misiones():
		if sm.obtener_cartas_desbloqueadas().has("carta_"+str(mission.id)):
			var card: Dictionary = mm.obtener_mision_localizada(mission).get("carta_nasa",{}).duplicate(true)
			if not card.is_empty():
				card["art"] = _mission_art(str(mission.id))
				result.append(card)
	var tree: Node = gs.obtener_tech_tree()
	for id in sm.obtener_mejoras_compradas():
		var card: Dictionary = tree.obtener_mejora_localizada(tree.obtener_mejora(id)).get("carta_nasa",{}).duplicate(true)
		if not card.is_empty():
			card["art"] = "solar" if id in ["panel_extra","bateria_modular","celulas_optimizadas"] else ("repair" if id in ["reparar_barato","mas_resistencia","alerta_temprana"] else ("garden" if id == "jardin_lunar" else "processor"))
			result.append(card)
	return result

func _build_catalog() -> void:
	if session == null: return
	for child in _build_tray.get_children(): child.queue_free()
	_build_buttons.clear()
	UI.label(_build_tray,tx("inventory"),Rect2(18,10,900,26),18,UI.CYAN,true)
	UI.button(_build_tray,tx("close"),Rect2(906,8,100,30),func():
		_build_tray.hide()
		_mission_panel.show()
	)
	for i in MODULES.size():
		var id: String = MODULES[i]
		var stock = int(session.inventory.get(id,0))
		var button = UI.button(_build_tray,"",Rect2(16+i*200,46,192,158),_start_build.bind(id))
		button.name = "Module_"+id
		module_picture(button,id,Rect2(6,6,180,76))
		UI.label(button,module_name(id),Rect2(10,86,172,28),15,UI.WHITE,true)
		UI.label(button,tx("stock",{"n":stock}),Rect2(10,112,172,24),14,UI.GOLD)
		UI.label(button,tx("cost",{"n":module_cost(id)}),Rect2(10,138,172,18),12,UI.CYAN)
		if stock == 0:
			button.modulate = Color(0.72,0.79,0.85)
		button.tooltip_text = tx("cost",{"n":module_cost(id)})
		_build_buttons[id] = button
	_build_tray.show()
	_mission_panel.hide()

func module_name(id: String) -> String:
	return tx("tank") if id == "tanque_agua" else tr("structures."+id)
func module_cost(id: String) -> int:
	return int(STRUCTURE_COST.get(id,10))
func module_picture(parent: Node,id: String,rect: Rect2) -> void:
	var image = TextureRect.new()
	if id == "tanque_agua":
		var atlas = AtlasTexture.new()
		atlas.atlas = load("res://assets/3d/revision/tanque_agua.jpg")
		atlas.region = Rect2(736,1810,308,308)
		image.texture = atlas
	else:
		image.texture = load("res://assets/ui/activities/"+str(MODULE_ART[id])+"-v1.png")
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if id == "tanque_agua" else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.position = rect.position
	image.size = rect.size
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)

func _refresh_build_tray_labels() -> void: pass
func _refresh_dock_states() -> void: pass
func _update_cam_button_label() -> void:
	if is_instance_valid(_cam_button): _cam_button.tooltip_text = "C · "+("Robot" if _camera_on_robot else "Base")
func _refresh_controls_hint() -> void: pass

func _start_build(id: String) -> void:
	if session == null: return
	if int(session.inventory.get(id,0)) <= 0:
		_show_toast(tx("no_stock"))
		return
	if id == "panel_solar" and _gs().paneles_instalados >= _structure_limit(id):
		_show_toast(_msg("Desbloquea Panel solar extra en Mejoras para ampliar el límite.","Unlock Extra Solar Panel in Upgrades to expand the limit."))
		return
	if id == "jardin" and not _has_upgrade("jardin_lunar"):
		_show_toast(tx("garden_locked"))
		return
	if not _gs().puede_pagar("energia",module_cost(id)):
		_show_toast(_msg("Energía insuficiente.","Not enough base energy."))
		return
	_build_tray.hide()
	_mission_panel.hide()
	_pending_build_id = id
	placement_system.keep_placing_with_shift = false
	placement_system.start_placement(StringName(id))

func _on_piece_placed(piece_id: StringName, _position: Vector3) -> void:
	var id = str(piece_id)
	var gs = _gs()
	if session == null or int(session.inventory.get(id,0)) <= 0 or not gs.puede_pagar("energia",module_cost(id)):
		var last = estructuras_colocadas.get_child(estructuras_colocadas.get_child_count()-1)
		last.queue_free()
		_show_toast(tx("no_stock"))
		return
	gs.pagar("energia",module_cost(id))
	session.inventory[id] = int(session.inventory[id])-1
	match id:
		"panel_solar": gs.paneles_instalados += 1
		"procesador_hielo": gs.procesador_instalado = true
		"generador_oxigeno": gs.generador_instalado = true
		"jardin": gs.jardin_instalado = true
		"tanque_agua": gs.agua_max += 50.0
	_pending_build_id = ""
	gs.notificar_evento_mision("estructura_construida",{"id_estructura":id,"total_paneles":gs.paneles_instalados})
	_show_toast(tx("module_done",{"module":module_name(id)}))
	_bind_stations()
	session.save_run()
	_sync_all_from_state()
	_mission_panel.show()

func _on_placement_cancelled(_id: StringName) -> void:
	_pending_build_id = ""
	_mission_panel.show()

func _update_placement_banner(placing: bool) -> void:
	_placement_banner.visible = placing
	_placement_label.text = tx("place")
	if placing: _mission_panel.hide()
	elif not is_instance_valid(_modal_layer): _mission_panel.show()

func _open_action(id: String) -> void:
	if id == "expedition":
		_open_ice_map()
		return
	var panel = _open_modal("action:"+id,tx(id),Vector2(900,600))
	var picture_id = "ice_map" if id == "expedition" else ("repair" if id == "repair" else "processor")
	if id == "rest": picture_id = "solar"
	var image = TextureRect.new()
	image.texture = load("res://assets/ui/activities/"+picture_id+"-v1.png")
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.position = Vector2(28,82)
	image.size = Vector2(480,366)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(image)
	if id == "expedition":
		# Two clear destinations, matched to the actual world rather than invented ice deposits.
		icon_button(panel,"base",Rect2(66,340,64,64),tx("return_dome"),_return_to_dome,true)
		icon_button(panel,"ice",Rect2(402,162,64,64),tx("expedition"),func(): _execute_action(id))
	var instructions = {"expedition": _msg("1. Viaja al cráter helado.\n2. Extrae hielo.\n3. Vuelve al domo.\n\nUsa la batería del robot. Evita las tormentas.","1. Travel to the ice crater.\n2. Collect ice.\n3. Return to the dome.\n\nUses robot battery. Watch for storms."), "processing": _msg("HIELO → PROCESADOR → AGUA\n\nProcesa hasta 3 bloques. Necesitas estar en la base, un procesador y energía.","ICE → PROCESSOR → WATER\n\nProcess up to 3 blocks. Requires a processor, base energy and being near the base."), "repair": _msg("ENERGÍA → REPARACIÓN → ESCUDO\n\nRepara 25 puntos de escudo. Necesitas 12 de energía (8 con la mejora).","ENERGY → REPAIR → SHIELD\n\nRestore 25 shield points. Uses 12 base energy (8 with the upgrade)."), "rest":tx("low_robot")}
	UI.label(panel,str(instructions[id]),Rect2(540,90,332,290),22,UI.WHITE)
	var gs = _gs()
	var status = ""
	if id == "processing": status = _msg("Hielo disponible: %d","Ice available: %d") % gs.hielo
	elif id == "repair": status = _msg("Escudo: %d%%","Shield: %d%%") % roundi(gs.escudo)
	else: status = _msg("Batería: %d%%","Battery: %d%%") % roundi(gs.energia_robot)
	UI.label(panel,status,Rect2(540,392,332,48),22,UI.GOLD,true)
	UI.button(panel,tx(id),Rect2(28,474,844,56),func(): _execute_action(id),true)
	if id in ["expedition","rest"]:
		UI.button(panel,tx("return_dome"),Rect2(540,326,332,48),_return_to_dome)

func _return_to_dome() -> void:
	_close_modal()
	if ice != null: ice.return_home()

func _execute_action(id: String) -> void:
	_close_modal()
	match id:
		"expedition": _run_expedition()
		"rest": _run_rest()
		"processing": _run_processing()
		"repair": _run_repair()

func _run_processing() -> void:
	var gs = _gs()
	if not gs.procesador_instalado or gs.hielo <= 0 or _robot_distance_to_processing_zone() > DOME_RECHARGE_RADIUS or not gs.puede_pagar("energia",mini(gs.hielo,_processor_capacity())*0.5):
		super._run_processing()
		return
	_begin_action("processing",1.2 if _has_upgrade("procesar_rapido") else 2.4)

func _run_repair() -> void:
	var gs = _gs()
	if gs.escudo >= 99.5 or not gs.puede_pagar("energia",8 if _has_upgrade("reparar_barato") else 12):
		super._run_repair()
		return
	_begin_action("repair",3.0)

func _begin_action(id: String, seconds: float) -> void:
	if not _action.is_empty():
		_show_toast(tx("action_busy"))
		return
	_action = id
	_action_total = seconds
	_action_remaining = seconds
	_action_label.text = tx("process_action" if id == "processing" else "repair_action")
	_action_panel.show()
	_action_progress.value = 0

func _tick_expedition(delta: float) -> void:
	if ice != null: ice.tick(delta)

func _open_timmy() -> void:
	var panel = _open_modal("timmy",tx("timmy"),Vector2(850,530))
	var image = TextureRect.new()
	image.texture = load("res://assets/ui/timmy.png")
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.position = Vector2(28,92)
	image.size = Vector2(220,310)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(image)
	var speech = UI.panel(panel,Rect2(270,84,552,220),Color("#193750"),20)
	var label = UI.label(speech,_next_advice(),Rect2(22,18,508,184),22,UI.WHITE)
	UI.button(panel,tx("next"),Rect2(270,326,552,48),func():
		_last_advice = _next_advice()
		label.text = _last_advice
		_speak(_last_advice)
	,true)
	UI.button(panel,tx("advice"),Rect2(270,388,266,48),func():
		label.text = _last_advice if not _last_advice.is_empty() else _next_advice()
		_speak(label.text)
	)
	UI.button(panel,tx("repeat"),Rect2(552,388,270,48),func(): _speak(label.text))
	UI.button(panel,tx("help"),Rect2(270,450,552,42),_open_controls)

func _next_advice() -> String:
	var mission: Dictionary = _gs().obtener_mision_activa_localizada()
	var objectives: Array = mission.get("objetivo",[])
	var done: Array = _gs().obtener_mission_manager().obtener_triggers_cumplidos()
	var triggers: Array = mission.get("trigger",[])
	var index = mini(maxi(0,objectives.size()-1), int(floor(float(done.size())*objectives.size()/maxi(1,triggers.size()))))
	return tx("hint",{"name":_player_name(),"goal":str(objectives[index]) if not objectives.is_empty() else tx("victory")})

func _open_controls() -> void:
	var panel = _open_modal("help",tx("help"),Vector2(740,470))
	UI.label(panel,tx("controls"),Rect2(32,90,676,260),25,UI.WHITE)
	UI.button(panel,tx("repeat"),Rect2(32,374,676,48),func(): _speak(tx("controls")),true)

func _speak(text: String) -> void:
	_voice.speak(text,TranslationServer.get_locale())

func _refresh_active_mission_panel() -> void:
	if not is_instance_valid(_mission_title): return
	var gs = _gs()
	var m: Dictionary = gs.obtener_mision_activa_localizada()
	if m.is_empty():
		_mission_title.text = tx("victory") if session != null and session.all_missions_complete() else tr("mission.none")
		_mission_desc.text = ""
		_mission_reward.text = ""
		return
	var triggers: Array = m.get("trigger",[])
	var done: Array = gs.obtener_mission_manager().obtener_triggers_cumplidos()
	var goals: Array = m.get("objetivo",[])
	_mission_title.text = str(m.get("mision",""))
	var index = mini(maxi(0,goals.size()-1), int(floor(float(done.size())*goals.size()/maxi(1,triggers.size()))))
	_mission_desc.text = str(_goals.get("es" if TranslationServer.get_locale().begins_with("es") else "en",{}).get(str(m.id),str(goals[index]) if not goals.is_empty() else ""))
	_mission_panel.tooltip_text = "\n".join(goals)
	_goal_progress.max_value = maxi(1,triggers.size())
	_goal_progress.value = done.size()
	_mission_reward.text = tx("progress",{"done":done.size(),"total":triggers.size()})

func _on_mision_completada(_id: String, _stars: int, _card: Dictionary) -> void:
	_sync_all_from_state()

func _on_upgrade_requested(id: String) -> void:
	var tree: Node = _gs().obtener_tech_tree()
	var result: Dictionary = tree.puede_comprar(id)
	if not bool(result.get("ok",false)):
		_show_toast(_upgrade_reason(id,result),4)
		return
	if _gs().comprar_mejora(id):
		session.save_run()
		_sync_all_from_state()
		if is_instance_valid(_progression_view): _progression_view.set_progression_state(_build_progression_dict())
		_open_upgrade_receipt(id)

func _check_resource_alerts() -> void:
	var gs = _gs()
	var ids = ["energia","agua","oxigeno","escudo","energia_robot"]
	var keys = ["low_energy","low_water","low_oxygen","low_shield","low_robot"]
	for i in ids.size():
		var id: String = ids[i]
		var value = float(gs.get(id))
		if value > 30: _alerted.erase(id)
		if value <= 20 and not _alerted.has(id):
			_alerted[id] = true
			var text = tx("low",{"resource":tr("hud."+id+".nombre"),"action":tx(keys[i])})
			session.add_message("low:"+id+":"+str(roundi(gs.tiempo_juego)),"text",{"text":text})
			_queue_alert(text,5)

func _on_advertencia_nube(seconds: float) -> void:
	super._on_advertencia_nube(seconds)
	if session != null:
		session.add_message("storm:"+str(roundi(_gs().tiempo_juego)),"storm",{})
		_queue_alert(tx("storm"),5,true)
		if _gs().en_viaje_hielo: _trip_alerted = true

func _on_ciclo_solar_cambiado(day: bool) -> void:
	super._on_ciclo_solar_cambiado(day)
	if session != null:
		session.add_message("cycle:"+str(roundi(_gs().tiempo_juego)),"day" if day else "night",{})
		_queue_alert(tx("day" if day else "night"),4)

func _show_toast(message: String, seconds: float = 2.6) -> void:
	var clean = message.replace("⚡"," energy").replace("🔋"," battery").replace("★"," stars").replace("✓", "").replace("⚠","")
	for item in _toast_queue:
		if str(item.text) == clean: return
	_toast_queue.append({"text":clean,"seconds":seconds})
	if _toast_queue.size() > 8: _toast_queue.pop_front()

func _open_messages() -> void:
	var panel = _open_modal("messages",tx("messages"),Vector2(1000,630))
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(28,84)
	scroll.size = Vector2(944,496)
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation",12)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)
	if session == null or session.messages.is_empty():
		UI.label(col,tx("no_messages"),Rect2(0,0,920,90),22)
		return
	for item in session.messages:
		var text = message_text(item)
		var button = UI.button(col,text,Rect2(0,0,920,92),func():
			session.mark_read(str(item.id))
			_speak(text)
		)
		button.custom_minimum_size = Vector2(920,92)
		button.add_theme_font_size_override("font_size",20)
		button.pressed.connect(func():
			UI.paint(button)
			_refresh_mail_badge()
		)
		if not bool(item.get("read",false)): button.add_theme_stylebox_override("normal",UI.style(Color("#193750"),UI.GOLD,2))

func message_text(item: Dictionary) -> String:
	var data: Dictionary = item.get("data",{})
	match str(item.kind):
		"text": return str(data.get("text",""))
		"mission":
			var name = CatalogScript.text("misiones."+str(data.id)+".titulo",str(data.id))
			return tx("mail_mission",{"name":name})
		"welcome": return tx("welcome",{"name":_player_name()})
		_: return tx(str(item.kind))

func _maybe_show_reward() -> void:
	if not _session_ready or _landing_active or home_paused or is_instance_valid(_modal_layer): return
	if not session.pending_rewards.is_empty():
		_open_reward(session.pending_rewards[0])
	elif session.finished:
		_open_victory()

func _open_reward(reward: Dictionary) -> void:
	var panel = _open_modal("reward",tx("reward"),Vector2(940,600))
	var title = CatalogScript.text("misiones."+str(reward.id)+".titulo",str(reward.id))
	UI.label(panel,title,Rect2(28,82,884,50),28,UI.GOLD,true)
	UI.label(panel,tx("reward_detail",{"stars":reward.stars}),Rect2(28,142,884,36),22,UI.WHITE)
	var card = UI.panel(panel,Rect2(28,204,420,240),Color("#193750"),18)
	UI.label(card,gx("letter"),Rect2(18,12,384,28),17,UI.GOLD,true)
	module_picture(card,_mission_module(str(reward.id)),Rect2(16,58,166,140))
	var science_title = ""
	for mission in session.mm.obtener_todas_las_misiones():
		if str(mission.id) == str(reward.id): science_title = str(session.mm.obtener_mision_localizada(mission).get("carta_nasa",{}).get("titulo",""))
	UI.label(card,science_title,Rect2(198,58,204,104),22,UI.WHITE,true)
	UI.label(card,gx("letter_saved"),Rect2(18,200,384,34),14,UI.CYAN)
	UI.label(panel,tx("supplies"),Rect2(476,204,436,32),20,UI.CYAN,true)
	var supply_scroll = ScrollContainer.new()
	supply_scroll.position = Vector2(476,246)
	supply_scroll.size = Vector2(436,198)
	supply_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(supply_scroll)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	supply_scroll.add_child(column)
	if reward.get("supplies",{}).is_empty():
		UI.label(panel,gx("no_supplies"),Rect2(476,264,418,126),23,UI.WHITE)
	for id in reward.get("supplies",{}):
		var item = UI.panel(column,Rect2(0,0,416,170),Color("#193750"),16)
		item.custom_minimum_size = Vector2(416,170)
		module_picture(item,str(id),Rect2(12,12,166,142))
		UI.label(item,"%s ×%d" % [module_name(id),int(reward.supplies[id])],Rect2(194,44,204,84),22,UI.WHITE,true)
	UI.button(panel,tx("view_card"),Rect2(28,494,420,54),func():
		session.acknowledge_reward(str(reward.id))
		_open_section_modal("science")
	,true)
	UI.button(panel,tx("continue"),Rect2(476,494,436,54),func():
		session.acknowledge_reward(str(reward.id))
		_close_modal()
	)
	(panel.get_child(1) as Button).pressed.connect(func(): session.acknowledge_reward(str(reward.id)))
	_pop_in(panel)
	_speak(tx("reward")+" "+title+". "+gx("letter")+": "+science_title+". "+gx("letter_saved"))

func _open_victory() -> void:
	var panel = _open_modal("victory",tx("victory"),Vector2(900,550))
	(panel.get_child(1) as Button).hide()
	UI.label(panel,tx("victory_text",{"n":session.mm.obtener_todas_las_misiones().size()}),Rect2(44,96,812,110),30,UI.WHITE,true)
	var text = "%s: %d     %s: %d\n%s: %d" % [tx("completed"),session.sm.obtener_misiones_completadas().size(),tx("learn"),_science_cards().size(),tx("stars"),session.sm.obtener_estrellas_totales()]
	UI.label(panel,text,Rect2(44,244,812,90),23,UI.CYAN)
	UI.button(panel,tx("view_card"),Rect2(28,386,264,54),func(): _open_section_modal("science"))
	UI.button(panel,tx("home"),Rect2(308,386,264,54),_return_home)
	UI.button(panel,tx("new_game"),Rect2(588,386,284,54),_confirm_new_game,true)
	_pop_in(panel)

func _confirm_new_game() -> void:
	var panel = _open_modal("new_game",tx("new_game"),Vector2(700,350))
	UI.label(panel,tx("confirm_restart"),Rect2(28,88,644,112),24,UI.WHITE)
	UI.button(panel,tx("cancel"),Rect2(28,238,310,48),_open_victory)
	UI.button(panel,tx("new_game"),Rect2(358,238,314,48),func():
		var mode = _gs().modo_juego
		session.reset_run(mode)
		session.save_run()
		_bridge._zero_handled = false
		_close_modal()
		_sync_all_from_state()
		_hud.set_mode(mode)
	,true)

func _on_recovery_requested(policy: String, _profile: Dictionary) -> void:
	if not _session_ready or session.loading or _modal_kind == "recovery" or session.finished: return
	var panel = _open_modal("recovery",tx("failed"),Vector2(780,440))
	(panel.get_child(1) as Button).hide()
	UI.label(panel,tx("failure_reason"),Rect2(28,86,724,52),24,UI.GOLD,true)
	UI.label(panel,tx("engineer_recovery" if policy == "restart" else "cadet_recovery"),Rect2(28,156,724,120),22,UI.WHITE)
	UI.button(panel,tx("restart" if policy == "restart" else "recover"),Rect2(28,320,450,54),func():
		session.recover()
		_bridge._zero_handled = false
		_close_modal()
		_alerted.clear()
		_toast_queue.clear()
		_sync_all_from_state()
		_apply_pause()
	,true)
	UI.button(panel,tx("home"),Rect2(498,320,254,54),_return_home)

func _return_home() -> void:
	set_paused(true)
	if session != null and not session.save_run():
		home_paused = false
		var error_panel = _open_modal("save_error",tx("settings"),Vector2(720,370))
		UI.label(error_panel,tx("save_error"),Rect2(28,90,664,128),23,UI.WHITE)
		UI.button(error_panel,tx("back"),Rect2(28,258,320,48),_close_modal)
		UI.button(error_panel,tx("home"),Rect2(368,258,324,48),_return_home,true)
		return
	_close_modal()
	_voice.stop()
	salir_al_menu.emit()

func _open_audio_modal() -> void:
	var panel = _open_modal("audio",tx("settings"),Vector2(760,594))
	var gs = _gs()
	UI.button(panel,"EN",Rect2(28,82,150,44),func(): _set_language("en"),gs.idioma == "en")
	UI.button(panel,"ES",Rect2(194,82,150,44),func(): _set_language("es"),gs.idioma == "es")
	UI.button(panel,tr("intro.voice_off" if _voice.muted else "intro.voice_on"),Rect2(374,82,358,44),func():
		_voice.muted = not _voice.muted
		_save_preferences()
		_open_audio_modal()
	,not _voice.muted)
	UI.label(panel,tx("voice")+" · "+("Sabina" if gs.idioma == "es" else "Zira"),Rect2(28,150,704,30),20,UI.CYAN,true)
	_voice_choice = OptionButton.new()
	_voice_choice.position = Vector2(28,190)
	_voice_choice.size = Vector2(704,44)
	_voice_choice.add_theme_font_size_override("font_size",19)
	UI.paint(_voice_choice)
	panel.add_child(_voice_choice)
	var voices: Array = _voice.voices_for(gs.idioma)
	_voice_choice.add_item("Sabina" if gs.idioma == "es" else "Zira")
	_voice_choice.set_item_metadata(0,"")
	for voice in voices:
		_voice_choice.add_item(str(voice.name))
		_voice_choice.set_item_metadata(_voice_choice.item_count-1,str(voice.id))
		if str(_voice.selected_voices.get(gs.idioma,"")) == str(voice.id): _voice_choice.select(_voice_choice.item_count-1)
	_voice_choice.item_selected.connect(func(index):
		_voice.set_voice(gs.idioma,str(_voice_choice.get_item_metadata(index)))
		_save_preferences()
	)
	_audio_status = UI.label(panel,"",Rect2(28,246,704,48),16,UI.WHITE)
	_audio_voice_signature = ""
	_refresh_audio_voices()
	for i in 2:
		UI.label(panel,tx("volume" if i == 0 else "speed"),Rect2(28,314+i*70,200,28),20,UI.WHITE)
		var slider = HSlider.new()
		slider.min_value = 0 if i == 0 else 0.7
		slider.max_value = 100 if i == 0 else 1.3
		slider.step = 5 if i == 0 else 0.05
		slider.value = _voice.volume if i == 0 else _voice.rate
		slider.position = Vector2(250,314+i*70)
		slider.size = Vector2(482,36)
		panel.add_child(slider)
		slider.value_changed.connect(func(value):
			if i == 0: _voice.volume = int(value)
			else: _voice.rate = float(value)
			_save_preferences()
		)
	UI.button(panel,tr("v2.test"),Rect2(28,482,704,50),func(): _speak(tx("welcome",{"name":_player_name()})),true)

func _save_preferences() -> void:
	var gs = _gs()
	gs.voz_activa = not _voice.muted
	gs.preferencias.merge({"nickname":_player_name(),"mode":gs.modo_juego,"language":gs.idioma,"voice_enabled":not _voice.muted,"voice_volume":_voice.volume,"voice_rate":_voice.rate,"voices":_voice.selected_voices.duplicate(true)},true)
	if session != null: session.save_run()

func _set_language(language: String) -> void:
	_gs().idioma = language
	TranslationServer.set_locale(language)
	await get_tree().process_frame
	_voice.stop()
	_save_preferences()
	_hud.refresh()
	rail.refresh()
	_refresh_active_mission_panel()
	_menu_button.tooltip_text = tx("menu")
	_timmy_button.tooltip_text = tx("timmy")
	_open_audio_modal()
func _toggle_language() -> void:
	_set_language("en" if _gs().idioma == "es" else "es")

func _unhandled_input(event: InputEvent) -> void:
	if _landing_active or (home_paused and not is_instance_valid(_modal_layer)): return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _modal_kind in ["recovery","victory"]: return
			if is_instance_valid(_modal_layer):
				if _modal_kind == "reward" and session != null and not session.pending_rewards.is_empty(): session.acknowledge_reward(str(session.pending_rewards[0].id))
				_close_modal()
			elif placement_system.is_placing(): placement_system.cancel_placement()
			elif _build_tray.visible:
				_build_tray.hide()
				_mission_panel.show()
			else: _open_section_menu()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_C and not is_instance_valid(_modal_layer):
			_toggle_camera_target()
			get_viewport().set_input_as_handled()

func capture_world() -> Dictionary:
	var placed: Array = []
	for child in estructuras_colocadas.get_children():
		if child.is_queued_for_deletion(): continue
		placed.append({"id":str(child.get_meta(&"piece_id",&"")),"position":[child.position.x,child.position.y,child.position.z],"rotation":[child.rotation.x,child.rotation.y,child.rotation.z]})
	var destination: Vector3 = click_to_move.get("_destino")
	return {"placed":placed,"robot":[robot.position.x,robot.position.y,robot.position.z],"rotation":[robot.rotation.x,robot.rotation.y,robot.rotation.z],"moving":bool(click_to_move.get("_moviendo")),"destination":[destination.x,destination.y,destination.z],"expedition":_expedition_pending,"expedition_time":_expedition_timer,"storm_time":_storm_remaining,"storm_count":_storm_count,"storm_profile":_storm_profile.duplicate(),"next_storm":_next_storm_profile.duplicate(),"warning":_storm_warning_emitted,"overload":_gen_overload_timer,"cooldown":_gen_overload_cooldown,"action":_action,"action_remaining":_action_remaining,"action_total":_action_total,"ice":ice.capture() if ice != null else {},"trip_collected":_trip_collected,"trip_ice":_trip_ice,"trip_alerted":_trip_alerted}

func restore_world(data: Dictionary) -> void:
	if placement_system.is_placing(): placement_system.cancel_placement()
	for child in estructuras_colocadas.get_children(): child.free()
	var catalog: Dictionary = placement_system.piece_catalog
	for item in data.get("placed",[]):
		var id = str(item.get("id",""))
		if not catalog.has(StringName(id)): continue
		var piece: Node3D = catalog[StringName(id)].instantiate()
		piece.set_meta(&"piece_id",StringName(id))
		estructuras_colocadas.add_child(piece)
		piece.position = array_vector(item.get("position",[0,0,0]))
		piece.rotation = array_vector(item.get("rotation",[0,0,0]))
	robot.position = array_vector(data.get("robot",[-3.6,0,9.6]))
	robot.rotation = array_vector(data.get("rotation",[0,-2.618,0]))
	if robot is CharacterBody3D: robot.velocity = Vector3.ZERO
	click_to_move.set("_moviendo",bool(data.get("moving",false)))
	click_to_move.set("_destino",array_vector(data.get("destination",[-3.6,0,9.6])))
	click_to_move.set("_tiempo_atascado",0.0)
	_expedition_pending = bool(data.get("expedition",false))
	_expedition_timer = float(data.get("expedition_time",0))
	_storm_remaining = float(data.get("storm_time",0))
	_storm_count = int(data.get("storm_count",0))
	_storm_profile = data.get("storm_profile",SPE_STORM_PROFILES[0]).duplicate()
	_next_storm_profile = data.get("next_storm",SPE_STORM_PROFILES[0]).duplicate()
	_storm_warning_emitted = bool(data.get("warning",false))
	_gen_overload_timer = float(data.get("overload",0))
	_gen_overload_cooldown = float(data.get("cooldown",0))
	_trip_collected = bool(data.get("trip_collected",false))
	_trip_ice = int(data.get("trip_ice",0))
	_trip_alerted = bool(data.get("trip_alerted",false))
	_action = str(data.get("action",""))
	_action_remaining = float(data.get("action_remaining",0))
	_action_total = float(data.get("action_total",1))
	_action_panel.visible = not _action.is_empty()
	_action_label.text = tx("process_action" if _action == "processing" else "repair_action")
	if ice != null: ice.restore(data.get("ice",{}))
	_bind_stations()
	_expedition_pending = false
	_pending_build_id = ""
	_bridge._zero_handled = false
	_sync_all_from_state()

func array_vector(value: Array) -> Vector3:
	if value.size() != 3: return Vector3.ZERO
	return Vector3(float(value[0]),float(value[1]),float(value[2]))

func _upgrade_reason(id: String, result: Dictionary) -> String:
	var reason = str(result.get("motivo",""))
	if reason.begins_with("falta_requisito:"):
		var req = reason.get_slice(":",1)
		return tx("required",{"name":CatalogScript.text("upgrades."+req+".nombre",req)})
	if reason == "estrellas_insuficientes":
		var item: Dictionary = _gs().obtener_tech_tree().obtener_mejora(id)
		return tx("need_stars",{"n":maxi(0,int(item.get("costo",0))-_gs().estrellas)})
	return tr("tree.owned") if reason == "ya_comprada" else _msg("Esta mejora no está disponible.","This upgrade is unavailable.")

func _build_progression_dict() -> Dictionary:
	var data = super._build_progression_dict()
	var mm: Node = _gs().obtener_mission_manager()
	data["objective_done"] = mm.obtener_triggers_cumplidos().size()
	data["objective_total"] = mm.obtener_mision_activa().get("trigger",[]).size()
	return data

func _tick_fallback_simulation(delta: float) -> void:
	super._tick_fallback_simulation(delta)
	_gs().generador_pausado = _gen_overload_timer > 0
	_gs().robot_en_domo = _robot_distance_to_dome() <= DOME_RECHARGE_RADIUS
	var environment = mundo.get_node_or_null("Ambiente")
	if environment != null and environment.has_method("set_solar_time"): environment.set_solar_time(_gs().tiempo_juego)

func _finish_local_expedition() -> void:
	var gs = _gs()
	var yield_ice = 8 if gs.herramienta_nivel >= 3 else (5 if gs.herramienta_nivel == 2 else 3)
	var cost = 10.0 if gs.herramienta_nivel >= 3 else (13.0 if gs.herramienta_nivel == 2 else 16.0)
	_trip_ice = mini(yield_ice,maxi(0,EXPEDITION_ICE_CAP-gs.hielo))
	gs.cambiar_recurso("hielo",_trip_ice)
	gs.pagar_robot(cost)
	_trip_collected = true
	gs.notificar_evento_mision("hielo_extraido_crater",{"hielo_obtenido":_trip_ice})
	_show_toast(_msg("Hielo recogido. Vuelve al domo con el mapa de Viaje al hielo.","Ice collected. Return to the dome using the Ice trip map."),4)
	_sync_all_from_state()

func _on_robot_arrived(destination: Vector3) -> void:
	super._on_robot_arrived(destination)
	if ice != null: ice.arrived(destination)

func _mission_art(id: String) -> String:
	var number = int(id.get_slice("_",1))
	var arts = ["solar","ice_map","processor","oxygen","solar","solar","solar","repair","repair","ice_map","oxygen","repair","processor","repair","garden","garden"]
	return str(arts[clampi(number-1,0,15)])

func _processor_capacity() -> int:
	var count = 0
	for child in estructuras_colocadas.get_children():
		if str(child.get_meta(&"piece_id",&"")) == "procesador_hielo": count += 1
	return 3 * maxi(1,count)

func _queue_alert(text: String, seconds: float, urgent := false) -> void:
	for item in _toast_queue:
		if str(item.text) == text: return
	var entry = {"text":text,"seconds":seconds,"voice":true}
	if urgent: _toast_queue.push_front(entry)
	else: _toast_queue.append(entry)

func _pop_in(panel: Control) -> void:
	panel.pivot_offset = panel.size/2
	panel.scale = Vector2(0.96,0.96)
	panel.modulate.a = 0
	var animation = create_tween().set_parallel(true)
	animation.tween_property(panel,"scale",Vector2.ONE,0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animation.tween_property(panel,"modulate:a",1.0,0.18)

func check_recovery() -> void:
	if not _session_ready: return
	_bridge._read_snapshot()
	_bridge._zero_handled = false
	_bridge._check_failure()

func _refresh_mail_badge() -> void:
	if session == null or not is_instance_valid(_mail_badge): return
	_mail_badge.visible = session.unread_count() > 0
	_mail_badge.text = str(session.unread_count())

func _refresh_audio_voices() -> void:
	if not is_instance_valid(_voice_choice) or not is_instance_valid(_audio_status): return
	var language = _gs().idioma
	var voices: Array = _voice.voices_for(language)
	var signature = str(voices)+language
	if signature != _audio_voice_signature:
		_audio_voice_signature = signature
		_voice_choice.clear()
		_voice_choice.add_item("Sabina" if language == "es" else "Zira")
		_voice_choice.set_item_metadata(0,"")
		for voice in voices:
			_voice_choice.add_item(str(voice.name))
			_voice_choice.set_item_metadata(_voice_choice.item_count-1,str(voice.id))
			if str(_voice.selected_voices.get(language,"")) == str(voice.id): _voice_choice.select(_voice_choice.item_count-1)
	_audio_status.text = tr("v2.audio_muted") if _voice.muted else (tx("voice_missing") if voices.is_empty() else tr("v2.audio_ready"))

func _run_rest() -> void:
	var gs = _gs()
	# Checking a full battery at the charger is a valid completed recharge.
	if gs.energia_robot >= 99.5 and _robot_distance_to_dome() <= DOME_RECHARGE_RADIUS:
		gs.notificar_evento_mision("robot_dentro_domo",{})
		gs.notificar_evento_mision("recarga_bateria_activa",{})
		gs.notificar_evento_mision("energia_alcanzada_90",{})
	super._run_rest()

func gx(key: String, values: Dictionary = {}) -> String:
	return tr("guide."+key).format(values)

func _offer_tour() -> void:
	if session == null or home_paused or _landing_active or _modal_layer != null or session.finished: return
	if not session.learned.has("tour"): _show_coach("tour")

func _show_coach(id: String) -> void:
	_coach_target = id
	rail.set_attention("construction" if id == "tour" else id)
	var panel = _open_modal("coach",gx("tour_title") if id == "tour" else "Timmy · "+tx(id),Vector2(890,500))
	var portrait = TextureRect.new()
	portrait.texture = load("res://assets/ui/timmy.png")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.position = Vector2(24,96)
	portrait.size = Vector2(194,300)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(portrait)
	if id == "tour":
		var entries = preload("res://ui/station_rail.gd").ITEMS
		for i in entries.size():
			var tile = UI.panel(panel,Rect2(244+(i%3)*204,94+(i/3)*86,192,72),Color("#193750"),12)
			var icon = Icon.new()
			icon.kind = entries[i][1]
			icon.tint = UI.CYAN
			icon.size = Vector2(28,28)
			icon.position = Vector2(12,22)
			tile.add_child(icon)
			UI.label(tile,tx(entries[i][0]),Rect2(52,10,130,52),18,UI.WHITE,true).vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	else:
		UI.label(panel,gx(id),Rect2(244,92,616,264),22,UI.WHITE)
	UI.button(panel,gx("try"),Rect2(244,388,616,54),func():
		session.learned[id] = true
		session.save_run()
		_close_modal()
		if id != "tour": _perform_station(id)
		else: rail.set_attention("construction")
	,true)
	_speak(gx(id))

func _bind_stations() -> void:
	var binder = preload("res://interaction/station_bindings.gd")
	for pair in [["Capsula","rest"],["Domo","repair"],["TanqueAgua","water"],["CraterHielo","expedition"]]:
		var node = mundo.get_node_or_null(pair[0])
		if node != null: binder.bind(node,pair[1])
	var sections = {"panel_solar":"energy","procesador_hielo":"processing","generador_oxigeno":"oxygen","tanque_agua":"water","jardin":"garden"}
	for piece in estructuras_colocadas.get_children():
		if piece.is_queued_for_deletion(): continue
		binder.bind(piece,str(sections.get(str(piece.get_meta("piece_id","")),"construction")))

func _on_station_clicked(section: String, _station: Node3D) -> void:
	if section in ["energy","water","oxygen","garden"]:
		_open_resource_station(section)
	else: _on_dock_action(section)

func _open_resource_station(section: String) -> void:
	var ids = {"energy":"energia","water":"agua","oxygen":"oxigeno","garden":"oxigeno"}
	var id: String = ids[section]
	var panel = _open_modal("resource_station",tr("hud."+id+".nombre"),Vector2(760,480))
	module_picture(panel,{"energy":"panel_solar","water":"tanque_agua","oxygen":"generador_oxigeno","garden":"jardin"}[section],Rect2(28,92,270,230))
	UI.label(panel,tr("hud."+id+".help"),Rect2(326,92,406,200),24,UI.WHITE)
	UI.label(panel,"%d / %d" % [_gs().valor_de(id),_gs().maximo_de(id)],Rect2(326,308,406,40),26,UI.GOLD,true)
	UI.button(panel,tx("processing" if section == "water" else "upgrades"),Rect2(28,382,704,52),func():
		_close_modal()
		_on_dock_action("processing" if section == "water" else "upgrades")
	,true)

func _run_expedition() -> void:
	if ice != null: ice.start(ice.selected)

func _on_ice_changed() -> void:
	if ice == null: return
	if ice.phase != "idle":
		_action_panel.show()
		_action_label.text = gx(ice.phase)
		_action_progress.value = 25 if ice.phase == "going" else (75 if ice.phase == "returning" else 50)
	elif _action.is_empty(): _action_panel.hide()
	if session != null and not session.loading: session.save_run()

func _open_ice_map() -> void:
	var panel = _open_modal("ice_map",tx("expedition"),Vector2(960,622))
	var image = TextureRect.new()
	image.texture = load("res://assets/ui/activities/ice_map-v1.png")
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.position = Vector2(28,84)
	image.size = Vector2(510,396)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(image)
	var markers = [Vector2(330,174),Vector2(92,104),Vector2(362,352)]
	for i in ice.ZONES.size():
		var zone: Dictionary = ice.ZONES[i]
		var id: String = zone.id
		if not ice.discovered.has(id): continue
		var button = icon_button(panel,"ice",Rect2(markers[i],Vector2(58,58)),gx(str(zone.name)),func():
			ice.selected = id
			_open_ice_map()
		,id == ice.selected)
		button.disabled = ice.phase != "idle" and id != ice.selected
		UI.panel(panel,Rect2(markers[i]+Vector2(-50,62),Vector2(160,40)),Color("#071b32f4"),10)
		UI.label(panel,gx(str(zone.name)),Rect2(markers[i]+Vector2(-50,62),Vector2(160,40)),15,UI.WHITE,true)
	var current: Dictionary = ice.zone(ice.selected)
	UI.label(panel,gx(str(current.name)),Rect2(566,88,366,50),27,UI.GOLD,true)
	UI.label(panel,gx("zone_stock",{"n":ice.stock.get(ice.selected,0)}),Rect2(566,158,366,40),22,UI.WHITE)
	UI.label(panel,gx(ice.phase),Rect2(566,218,366,82),23,UI.CYAN,true)
	UI.button(panel,gx("scan"),Rect2(566,334,366,54),func():
		ice.discover()
		_open_ice_map()
	).disabled = ice.discovered.size() >= ice.ZONES.size()
	UI.button(panel,tx("return_dome"),Rect2(566,406,366,54),_return_to_dome)
	if ice.phase in ["idle","blocked"]:
		UI.button(panel,gx("retry") if ice.phase == "blocked" else tx("expedition"),Rect2(28,506,600,56),func():
			_close_modal()
			if ice.phase == "blocked": ice.retry()
			else: ice.start(ice.selected)
		,true)
	else:
		UI.label(panel,gx(ice.phase),Rect2(28,510,600,52),24,UI.CYAN,true)
	UI.button(panel,gx("stop_trip"),Rect2(650,506,282,56),func():
		ice.cancel()
		_close_modal()
	)

func _mission_module(id: String) -> String:
	var art = _mission_art(id)
	return {"solar":"panel_solar","processor":"procesador_hielo","oxygen":"generador_oxigeno","garden":"jardin","repair":"panel_solar","ice_map":"procesador_hielo"}.get(art,"panel_solar")

func _open_upgrade_receipt(id: String) -> void:
	var item: Dictionary = session.gs.obtener_tech_tree().obtener_mejora(id)
	var title = CatalogScript.text("upgrades."+id+".nombre",id)
	var effect = CatalogScript.text("upgrades."+id+".efecto","")
	var after = session.sm.obtener_estrellas_disponibles()
	var panel = _open_modal("upgrade_receipt",gx("upgrade_installed"),Vector2(860,510))
	var icon = Icon.new()
	icon.kind = "check"
	icon.tint = UI.CYAN
	icon.position = Vector2(36,92)
	icon.size = Vector2(96,96)
	panel.add_child(icon)
	UI.label(panel,title,Rect2(164,88,664,72),30,UI.GOLD,true)
	UI.label(panel,effect,Rect2(36,214,792,126),25,UI.WHITE)
	UI.label(panel,gx("star_receipt",{"before":after+int(item.get("costo",0)),"after":after}),Rect2(164,166,664,34),23,UI.CYAN,true)
	UI.button(panel,gx("back_tree"),Rect2(28,390,392,54),func(): _open_section_modal("upgrades"),true)
	UI.button(panel,tx("view_card"),Rect2(440,390,392,54),func(): _open_section_modal("science"))
	_pop_in(panel)
	_speak(gx("upgrade_installed")+". "+title+". "+effect)

func _on_resource_pressed(id: String) -> void:
	var stations = {"energia":"energy","agua":"water","oxigeno":"oxygen","escudo":"repair","energia_robot":"rest"}
	_on_station_clicked(str(stations.get(id,"energy")),mundo)

func _on_robot_started_walk(destination: Vector3) -> void:
	super._on_robot_started_walk(destination)
	if ice != null and not ice.route_driven and ice.phase in ["going","mining","returning"]:
		ice.phase = "blocked"
		ice._route.clear()
		ice._request_route = false
		ice.changed.emit()

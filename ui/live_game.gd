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
var alerts: Control
var _transition_active := false
var guide: Node
var _sequence_view: Control
var _survey_view: Control
var _navigation_view: Control
var ice: Node
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
	guide = preload("res://ui/task_guide.gd").new()
	add_child(guide)
	guide.setup(self)
	session.reward_ready.connect(func(_reward): _maybe_show_reward())
	session.checkpoint_saved.connect(func(ok):
		_show_toast(tx("checkpoint" if ok else "save_error"))
		if ok and alerts != null: alerts.publish("saved",tx("checkpoint"),tr("outcome.safe"),"checkpoint","",false)
	)
	session.campaign_finished.connect(func(): _maybe_show_reward())
	session.begin()
	_session_ready = true
	if guide.active(): guide.refresh(false)
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
	_hud.position = Vector2(22,20)
	_ui_root.add_child(_hud)
	_hud.resource_pressed.connect(_on_resource_pressed)
	_hud.set_mode(gs.modo_juego)
	_build_side_mission_card()
	_build_top_toolbar()
	_build_bottom_dock()
	_build_placement_and_toast()
	alerts = preload("res://ui/alert_banner.gd").new()
	_ui_root.add_child(alerts)
	alerts.solve_requested.connect(func(task):
		alerts.dismiss_current()
		guide.start(task)
	)
	debug_label.hide()

func _build_side_mission_card() -> void:
	_mission_panel = UI.panel(_ui_root,Rect2(22,628,292,76),Color("#101e34ec"),14)
	_mission_title = UI.label(_mission_panel,"",Rect2(12,6,268,20),14,UI.GOLD,true)
	_mission_title.max_lines_visible = 1
	_mission_desc = UI.label(_mission_panel,"",Rect2(12,27,268,30),13,UI.WHITE)
	_mission_desc.max_lines_visible = 2
	_mission_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_mission_panel.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: _open_section_modal("missions")
	)
	_goal_progress = ProgressBar.new()
	_goal_progress.show_percentage = false
	_goal_progress.add_theme_stylebox_override("background",UI.style(Color("#34445e")))
	_goal_progress.add_theme_stylebox_override("fill",UI.style(UI.CYAN))
	_mission_panel.add_child(_goal_progress)
	_goal_progress.position = Vector2(12,63)
	_goal_progress.size = Vector2(174,5)
	_mission_reward = UI.label(_mission_panel,"",Rect2(196,56,86,18),11,UI.CYAN)
	_storm_badge = UI.panel(_ui_root,Rect2(332,184,500,40),Color("#631b1bee"),12)
	_storm_badge.hide()
	_storm_label = UI.label(_storm_badge,"",Rect2(14,6,472,28),15,UI.WHITE,true)

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
	_menu_button = UI.button(_ui_root,"",Rect2(1096,20,168,40),_open_section_menu)
	var gear = Icon.new()
	gear.kind = "settings"
	gear.disc = false
	gear.tint = UI.CYAN
	gear.position = Vector2(12,10)
	gear.size = Vector2(20,20)
	_menu_button.add_child(gear)
	UI.label(_menu_button,tr("nav.settings"),Rect2(42,4,120,32),15,UI.WHITE,true).name = "Caption"
	rail = preload("res://ui/station_rail.gd").new()
	rail.position = Vector2(414,636)
	_ui_root.add_child(rail)
	rail.section_requested.connect(_on_dock_action)
	rail.utility_requested.connect(func(action):
		if action == "more": _open_more_menu()
	)
	_cam_button = icon_button(_ui_root,"camera",Rect2(1098,660,40,40),tx("help"),_toggle_camera_target)
	_timmy_button = UI.button(_ui_root,"Timmy",Rect2(1154,660,110,40),_open_timmy,true)
	_cam_button.hide()
	_mail_button = rail.utility_buttons.more
	_mail_badge = UI.label(_mail_button,"",Rect2(66,-8,24,24),13,UI.INK,true)
	var badge_style = UI.style(UI.GOLD,Color.TRANSPARENT,0,12)
	badge_style.content_margin_left = 0
	badge_style.content_margin_right = 0
	_mail_badge.add_theme_stylebox_override("normal",badge_style)
	_mail_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mail_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mail_badge.size = Vector2(24,24)

func _build_bottom_dock() -> void:
	# A contextual drawer replaces the permanent eight-button dock.
	_build_tray = UI.panel(_ui_root,Rect2(856,78,400,540),Color("#071b32fa"),18)
	_build_tray.mouse_filter = Control.MOUSE_FILTER_STOP
	_build_tray.hide()
	_controls_hint = UI.label(_ui_root,"",Rect2(440,676,600,22),13,UI.WHITE)
	_controls_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controls_hint.hide()

func _build_placement_and_toast() -> void:
	_placement_banner = UI.panel(_ui_root,Rect2(296,158,688,48),Color("#071b32f7"),14)
	_placement_banner.hide()
	_placement_label = UI.label(_placement_banner,"",Rect2(18,10,652,28),16,UI.GOLD,true)
	_toast_panel = UI.panel(_ui_root,Rect2(448,552,400,66),Color("#071b32f7"),16)
	_toast_panel.hide()
	_toast_label = UI.label(_toast_panel,"",Rect2(16,10,368,48),16,UI.WHITE)
	_action_panel = UI.panel(_ui_root,Rect2(448,482,400,56),Color("#102b46f7"),14)
	_action_panel.hide()
	_action_label = UI.label(_action_panel,"",Rect2(16,6,368,26),16,UI.CYAN,true)
	_action_progress = ProgressBar.new()
	_action_progress.show_percentage = false
	_action_progress.add_theme_font_size_override("font_size",1)
	_action_panel.add_child(_action_progress)
	_action_progress.position = Vector2(16,36)
	_action_progress.size = Vector2(368,8)

func _process(delta: float) -> void:
	super._process(delta)
	if not _session_ready: return
	if alerts != null: alerts.blocked = home_paused or _modal_layer != null or _transition_active or placement_system.is_placing()
	_storm_badge.visible = (_gs().nube_activa or _gs().alerta_nube) and not alerts.blocked and alerts.current.is_empty()
	_storm_label.text = _storm_label.text.replace("⚠","").strip_edges()
	if guide != null and not home_paused:
		guide.tick(delta)
	if _toast_timer <= 0 and not _toast_queue.is_empty() and not is_instance_valid(_modal_layer) and not home_paused and not placement_system.is_placing():
		var item: Dictionary = _toast_queue.pop_front()
		_toast_panel.position = Vector2(448,552)
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
	_gs().en_partida = not blocked and not (guide != null and guide.learning_pause())
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
	if is_instance_valid(alerts):
		alerts.blocked = true
		alerts.hide()
	_build_tray.hide()
	_toast_panel.hide()
	_mission_panel.hide()
	_apply_pause()
	UI.label(panel,tx("paused"),Rect2(28,panel_size.y-30,panel_size.x-56,22),12,UI.CYAN)
	call_deferred("_trap_focus")
	if guide != null: guide.layout()
	return panel

func _close_modal() -> void:
	for item in [rail,_menu_button,_timmy_button,_hud]:
		if is_instance_valid(item): item.z_index = 0
	if is_instance_valid(_voice): _voice.stop()
	for queued in _toast_queue:
		if queued.has("voice"): queued.voice = false
	if rail != null: rail.set_current("")
	var notify_home = options_from_home and not _swapping_modal
	super._close_modal()
	if notify_home:
		options_from_home = false
		options_closed.emit()
	if is_instance_valid(_mission_panel): _mission_panel.show()
	_sequence_view = null
	_survey_view = null
	if guide != null: guide.panel_closed()
	if _session_ready:
		if is_instance_valid(alerts): alerts.blocked = home_paused or _transition_active or placement_system.is_placing()
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
	_open_navigation("settings")
func _open_more_menu() -> void:
	_open_navigation("more")
func _open_navigation(page: String) -> void:
	var panel = _open_drawer(page,tr("nav."+page),Vector2(400,500 if page == "more" else 390))
	rail.set_current("more" if page == "more" else "")
	_navigation_view = preload("res://ui/navigation_menu.gd").new()
	_navigation_view.page = page
	_navigation_view.position = Vector2(28,80)
	_navigation_view.size = Vector2(344,panel.size.y-116)
	panel.add_child(_navigation_view)
	_navigation_view.action_requested.connect(func(action):
		match action:
			"language": _open_language_settings()
			"audio": _open_audio_modal()
			"controls": _open_controls()
			"exit": _confirm_exit()
			"timmy": _open_timmy()
			_: _on_dock_action(action)
	)
	call_deferred("_trap_focus")
func _open_drawer(kind: String, title: String, dimensions: Vector2) -> Control:
	var panel = _open_modal(kind,title,dimensions)
	panel.position = Vector2(1256-dimensions.x,78)
	panel.get_child(0).add_theme_font_size_override("font_size",22)
	(_modal_layer.get_child(0) as ColorRect).color.a = 0.12
	for item in [rail,_menu_button,_timmy_button,_hud]: item.z_index = 60
	if guide != null: guide.layout()
	return panel
func _open_language_settings() -> void:
	var panel = _open_drawer("language",tr("nav.language"),Vector2(400,340))
	for i in 2:
		var lang: String = ["en","es"][i]
		UI.button(panel,"English" if i == 0 else "Español",Rect2(28,90+i*70,344,56),func(): _set_language(lang),_gs().idioma == lang)
	UI.button(panel,tr("nav.back_settings"),Rect2(28,250,344,48),_open_section_menu)
func _confirm_exit() -> void:
	var panel = _open_drawer("exit",tr("nav.exit"),Vector2(400,320))
	UI.label(panel,tr("nav.exit_body"),Rect2(28,88,344,104),20,UI.WHITE)
	UI.button(panel,tx("cancel"),Rect2(28,220,116,52),_open_section_menu)
	UI.button(panel,tr("nav.save_exit"),Rect2(156,220,216,52),_return_home,true)

func _on_dock_action(id: String) -> void:
	if is_instance_valid(_modal_layer): _close_modal()
	if guide != null and not guide.active():
		var tasks = {"expedition":"ice","processing":"process","repair":"repair","rest":"recharge"}
		var task: String = tasks.get(id,"")
		if id == "construction" and _gs().paneles_instalados == 0: task = "build"
		if id == "repair" and _gs().escudo >= 99.5: task = ""
		if not task.is_empty() and not session.learned.has("task:"+task) and not session.learned.has("skip_task:"+task):
			guide.start(task)
			if str(guide.state.stage).ends_with("_wait"): return
			var target: String = guide.target()
			if not target.is_empty() and target != id:
				_perform_station(target)
				return
	_perform_station(id)
	rail.set_current(id)

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
	UI.label(_build_tray,tx("construction"),Rect2(16,10,260,30),23,UI.GOLD,true)
	UI.label(_build_tray,tr("nav.build_choose"),Rect2(16,44,368,24),14,UI.CYAN)
	var close = UI.button(_build_tray,tx("close"),Rect2(304,10,80,30),func():
		_build_tray.hide()
		_mission_panel.show()
		rail.set_current("")
		if guide != null: guide.build_closed()
	)
	close.add_theme_font_size_override("font_size",12)
	for i in MODULES.size():
		var id: String = MODULES[i]
		var stock = int(session.inventory.get(id,0))
		var button = UI.button(_build_tray,"",Rect2(16+(i%2)*192,72+(i/2)*156,176,148),_start_build.bind(id))
		button.name = "Module_"+id
		module_picture(button,id,Rect2(6,6,164,64))
		UI.label(button,module_name(id),Rect2(10,76,156,32),14,UI.WHITE,true)
		UI.label(button,tx("stock",{"n":stock}),Rect2(10,108,156,18),13,UI.GOLD)
		UI.label(button,tx("cost",{"n":module_cost(id)}),Rect2(10,128,156,18),12,UI.CYAN)
		if stock == 0: button.modulate = Color(0.72,0.79,0.85)
		button.tooltip_text = tx("cost",{"n":module_cost(id)})
		_build_buttons[id] = button
	_build_tray.show()
	_toast_queue.clear()
	_toast_timer = 0
	_toast_panel.hide()
	rail.set_current("construction")
	if guide != null: guide.notify("station_open",{"section":"construction"})

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
	if guide != null and guide.active() and guide.state.stage == "build_select" and str(guide.state.module) != id:
		guide.refresh(true)
		return
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
	if guide != null: guide.notify("module_selected",{"module":id})

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
	rail.set_current("")
	if guide != null: guide.notify("module_placed",{"module":id})
	_bind_stations()
	session.save_run()
	_sync_all_from_state()
	_mission_panel.show()

func _on_placement_cancelled(_id: StringName) -> void:
	_pending_build_id = ""
	rail.set_current("")
	if guide != null: guide.build_closed()
	_mission_panel.show()

func _update_placement_banner(placing: bool) -> void:
	_placement_banner.visible = placing
	_placement_label.text = tx("place")
	if placing:
		_mission_panel.hide()
		_toast_panel.hide()
		_toast_timer = 0
	elif not is_instance_valid(_modal_layer): _mission_panel.show()

func _open_action(id: String) -> void:
	if id == "expedition": _open_ice_map(); return
	if id in ["processing","repair"]:
		var panel = _open_drawer("action:"+id,tx(id),Vector2(760,540))
		var view = preload("res://ui/station_sequence.gd").new()
		view.section = id
		view.training = false
		view.initial_shield = _gs().escudo
		view.blocked_reason = _action_problem(id)
		view.allowed = view.blocked_reason.is_empty()
		view.position = Vector2(28,180)
		view.size = Vector2(704,324)
		panel.add_child(view)
		_sequence_view = view
		view.step_performed.connect(func(section,index):
			if guide != null: guide.notify(section+"_step",{"index":index})
		)
		view.narration_requested.connect(func(text):
			if guide == null or not guide.active(): _speak(text)
		)
		view.completed.connect(func(): _execute_action(id))
		if guide != null:
			guide.notify("station_open",{"section":id})
			guide.layout()
		return
	var panel = _open_drawer("action:rest",tx("rest"),Vector2(400,550))
	var view = preload("res://ui/recharge_panel.gd").new()
	view.position = Vector2(28,84)
	view.size = Vector2(344,400)
	view.battery = _gs().energia_robot
	view.near_dome = _robot_distance_to_dome() <= DOME_RECHARGE_RADIUS
	view.recharge_requested.connect(func(): _execute_action("rest"))
	view.return_requested.connect(_return_to_dome)
	panel.add_child(view)
	if guide != null:
		guide.notify("station_open",{"section":"rest"})
		guide.layout()

func _action_problem(id: String) -> String:
	var gs = _gs()
	if not _action.is_empty(): return tx("action_busy")
	if id == "processing":
		if not gs.procesador_instalado: return tr("hint.build_processor")
		if gs.hielo <= 0: return tr("hint.water_ice")
		if _robot_distance_to_processing_zone() > DOME_RECHARGE_RADIUS: return tr("flow.near_base")
		if gs.agua_max-gs.agua < 5: return tr("flow.tank_full")
		if not gs.puede_pagar("energia",mini(gs.hielo,_processor_capacity())*0.5): return tr("flow.no_energy")
	elif id == "repair":
		if gs.escudo >= 99.5: return tr("flow.shield_full")
		if not gs.puede_pagar("energia",8 if _has_upgrade("reparar_barato") else 12): return tr("flow.no_energy")
	return ""

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
	var hint = preload("res://ui/context_hint.gd").get_hint(self)
	var panel = _open_drawer("timmy",tx("timmy"),Vector2(400,520))
	var image = TextureRect.new()
	image.texture = load("res://assets/ui/timmy.png")
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.position = Vector2(24,92)
	image.size = Vector2(106,180)
	panel.add_child(image)
	UI.label(panel,_player_name(),Rect2(146,82,226,30),21,UI.GOLD,true)
	UI.label(panel,str(hint.text),Rect2(146,122,226,198),19,UI.WHITE)
	UI.button(panel,tr("flow.guide_me"),Rect2(28,346,344,52),func():
		_close_modal()
		if guide.active(): guide.refresh(true)
		else: guide.start(str(hint.task),str(hint.get("module","")))
	,true)
	UI.button(panel,tr("v2.repeat"),Rect2(28,414,164,46),func(): _speak(str(hint.text)))
	UI.button(panel,tr("nav.controls"),Rect2(204,414,168,46),_open_controls)
	_speak(str(hint.text))

func _next_advice() -> String:
	return str(preload("res://ui/context_hint.gd").get_hint(self).text)

func _open_controls() -> void:
	var panel = _open_drawer("help",tr("nav.controls"),Vector2(400,570))
	UI.label(panel,tx("controls"),Rect2(28,88,344,350),18,UI.WHITE)
	UI.button(panel,tx("repeat"),Rect2(28,464,164,48),func(): _speak(tx("controls")),true)
	UI.button(panel,tx("back"),Rect2(204,464,168,48),_open_section_menu)

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
		session.add_message("upgrade:"+id,"upgrade",{"id":id})
		_open_upgrade_receipt(id)

func _check_resource_alerts() -> void:
	var gs = _gs()
	var ids = ["energia","agua","oxigeno","escudo","energia_robot"]
	var keys = ["low_energy","low_water","low_oxygen","low_shield","low_robot"]
	for i in ids.size():
		var id: String = ids[i]
		var value = float(gs.get(id))
		if value > 30:
			_alerted.erase(id)
			session.resolve_message("alert:"+id)
			alerts.dismiss("alert:"+id)
		if value <= 20 and not _alerted.has(id):
			_alerted[id] = true
			var text = tx("low",{"resource":tr("hud."+id+".nombre"),"action":tx(keys[i])})
			session.add_message("alert:"+id,"resource",{"resource":id})
			if guide != null: guide.offer_alert(id)
			var tasks = {"agua":"water","oxigeno":"oxygen","energia":"energy","escudo":"repair","energia_robot":"recharge"}
			alerts.publish("alert:"+id,tr("notice.resource").format({"resource":tr("hud."+id+".nombre")}),tx(keys[i]),("robot_battery" if id == "energia_robot" else id),str(tasks[id]),value <= 10)

func _on_advertencia_nube(seconds: float) -> void:
	super._on_advertencia_nube(seconds)
	if session != null:
		session.add_message("storm:"+str(roundi(_gs().tiempo_juego)),"storm",{})
		alerts.publish("storm",tr("notice.storm"),tx("storm"),"escudo","storm",true)
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
	var panel = _open_modal("messages",tx("messages"),Vector2(1200,672))
	var center = preload("res://ui/notification_center.gd").new()
	center.game = self
	var has_alert = session.messages.any(func(item): return str(item.kind) in ["resource","storm"] and not item.get("resolved",false))
	if not has_alert:
		center._page = "discoveries" if session.messages.any(func(item): return str(item.kind) in ["mission","upgrade"] and not item.get("read",false)) else "history"
	center.position = Vector2(28,78)
	center.size = Vector2(1144,548)
	panel.add_child(center)
	center.guide_requested.connect(func(task,module): _close_modal(); guide.start(task,module))
	center.section_requested.connect(_open_section_modal)
	center.narration_requested.connect(_speak)

func message_text(item: Dictionary) -> String:
	var data: Dictionary = item.get("data",{})
	match str(item.kind):
		"resource":
			var id = str(data.resource)
			var keys = {"agua":"low_water","energia":"low_energy","oxigeno":"low_oxygen","escudo":"low_shield","energia_robot":"low_robot"}
			return tx("low",{"resource":tr("hud."+id+".nombre"),"action":tx(str(keys.get(id,"low_water")))})
		"upgrade": return gx("upgrade_installed")+". "+CatalogScript.text("upgrades."+str(data.id)+".nombre",str(data.id))
		"text","letter": return str(data.get("text",""))
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
	var science_title = ""
	for mission in session.mm.obtener_todas_las_misiones():
		if str(mission.id) == str(reward.id): science_title = str(session.mm.obtener_mision_localizada(mission).get("carta_nasa",{}).get("titulo",""))
	var view = preload("res://ui/reward_view.gd").new()
	view.position = Vector2(28,82)
	view.size = Vector2(884,466)
	view.mission_title = title
	view.science_title = science_title
	view.card_module = _mission_module(str(reward.id))
	view.stars = int(reward.stars)
	view.supplies = reward.get("supplies",{}).duplicate()
	view.picture_builder = module_picture
	view.module_title = module_name
	view.acknowledged.connect(func(science):
		session.acknowledge_reward(str(reward.id))
		if science: _open_section_modal("science")
		else: _close_modal()
	)
	panel.add_child(view)
	(panel.get_child(1) as Button).pressed.connect(func(): session.acknowledge_reward(str(reward.id)))
	_pop_in(panel)
	_speak(tx("reward")+" "+title+". "+gx("letter")+": "+science_title+". "+gx("letter_saved"))


func _open_victory() -> void:
	var panel = _open_modal("victory",tr("outcome.victory"),Vector2(1120,650))
	(panel.get_child(1) as Button).hide()
	panel.add_theme_stylebox_override("panel",UI.style(Color("#071b32f7"),UI.GOLD,3,24))
	var art = preload("res://ui/outcome_art.gd").new()
	art.kind = "victory"
	art.size = panel.size
	panel.add_child(art)
	var star = Icon.new()
	star.kind = "star"
	star.tint = UI.GOLD
	star.position = Vector2(44,108)
	star.size = Vector2(128,128)
	panel.add_child(star)
	UI.label(panel,tx("victory_text",{"n":session.mm.obtener_todas_las_misiones().size()}),Rect2(210,102,860,140),32,UI.WHITE,true)
	var totals = [[tx("completed"),session.sm.obtener_misiones_completadas().size()],[tx("learn"),_science_cards().size()],[tx("stars"),session.sm.obtener_estrellas_totales()]]
	for i in 3:
		var card = UI.panel(panel,Rect2(32+i*360,298,336,142),Color("#193750"),18)
		UI.label(card,str(totals[i][1]),Rect2(18,12,300,66),50,UI.GOLD,true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.label(card,str(totals[i][0]),Rect2(18,88,300,42),21,UI.CYAN,true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.button(panel,tx("view_card"),Rect2(32,522,336,60),func(): _open_section_modal("science"))
	UI.button(panel,tx("home"),Rect2(392,522,336,60),_return_home)
	UI.button(panel,tx("new_game"),Rect2(752,522,336,60),_confirm_new_game,true)
	_pop_in(panel)
	_speak(tr("outcome.victory")+" "+_player_name()+". "+tx("victory_text",{"n":session.mm.obtener_todas_las_misiones().size()}))

func _confirm_new_game() -> void:
	var finished = session.finished
	var panel = _open_modal("new_game",tx("restart"),Vector2(760,390))
	UI.label(panel,tx("confirm_restart"),Rect2(28,88,704,142),24,UI.WHITE)
	UI.button(panel,tx("cancel"),Rect2(28,278,340,50),func():
		if finished: _open_victory()
		else: _open_section_menu()
	)
	UI.button(panel,tx("restart"),Rect2(388,278,344,50),func(): _play_run_transition(true,true),true)

func _on_recovery_requested(policy: String, _profile: Dictionary) -> void:
	if not _session_ready or session.loading or _modal_kind == "recovery" or session.finished or _transition_active: return
	if guide != null: guide.stop()
	var panel = _open_modal("recovery",tr("outcome.engineer" if policy == "restart" else "outcome.cadet"),Vector2(900,550))
	(panel.get_child(1) as Button).hide()
	panel.add_theme_stylebox_override("panel",UI.style(Color("#1e192cf7"),Color("#ff927a"),3,22))
	var art = preload("res://ui/outcome_art.gd").new()
	art.kind = "defeat"
	art.size = panel.size
	panel.add_child(art)
	var icon = Icon.new()
	icon.kind = "oxigeno" if _gs().oxigeno <= 0 else "energia"
	icon.tint = Color("#ff927a")
	icon.position = Vector2(34,94)
	icon.size = Vector2(112,112)
	panel.add_child(icon)
	var resource = tr("hud.oxigeno.nombre" if _gs().oxigeno <= 0 else "hud.energia.nombre")
	UI.label(panel,tr("outcome.reason").format({"resource":resource}),Rect2(182,94,680,108),27,UI.GOLD,true)
	UI.label(panel,tx("engineer_recovery" if policy == "restart" else "cadet_recovery"),Rect2(34,250,832,116),23,UI.WHITE)
	UI.button(panel,tx("restart" if policy == "restart" else "recover"),Rect2(28,432,530,56),func(): _play_run_transition(policy == "restart",false),true)
	UI.button(panel,tx("home"),Rect2(578,432,294,56),_return_home)
	_pop_in(panel)
	_speak(tr("outcome.reason").format({"resource":resource})+" "+tx("engineer_recovery" if policy == "restart" else "cadet_recovery"))

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
	var panel = _open_drawer("audio",tr("nav.audio"),Vector2(400,580))
	var gs = _gs()
	UI.button(panel,tr("intro.voice_off" if _voice.muted else "intro.voice_on"),Rect2(28,82,344,44),func():
		_voice.muted = not _voice.muted
		_save_preferences()
		_open_audio_modal()
	,not _voice.muted)
	UI.label(panel,tx("voice")+" · "+("Sabina" if gs.idioma == "es" else "Zira"),Rect2(28,142,344,30),18,UI.CYAN,true)
	_voice_choice = OptionButton.new()
	_voice_choice.position = Vector2(28,180)
	_voice_choice.size = Vector2(344,44)
	_voice_choice.add_theme_font_size_override("font_size",16)
	UI.paint(_voice_choice)
	panel.add_child(_voice_choice)
	_voice_choice.item_selected.connect(func(index):
		_voice.set_voice(gs.idioma,str(_voice_choice.get_item_metadata(index)))
		_save_preferences()
	)
	_audio_status = UI.label(panel,"",Rect2(28,234,344,64),14,UI.WHITE)
	_audio_voice_signature = ""
	_refresh_audio_voices()
	for i in 2:
		UI.label(panel,tx("volume" if i == 0 else "speed"),Rect2(28,310+i*66,344,26),17,UI.WHITE)
		var slider = HSlider.new()
		slider.min_value = 0 if i == 0 else 0.7
		slider.max_value = 100 if i == 0 else 1.3
		slider.step = 5 if i == 0 else 0.05
		slider.value = _voice.volume if i == 0 else _voice.rate
		slider.position = Vector2(28,340+i*66)
		slider.size = Vector2(344,26)
		panel.add_child(slider)
		slider.value_changed.connect(func(value):
			if i == 0: _voice.volume = int(value)
			else: _voice.rate = float(value)
			_save_preferences()
		)
	UI.button(panel,tr("v2.test"),Rect2(28,466,164,48),func(): _speak(tx("welcome",{"name":_player_name()})),true)
	UI.button(panel,tx("back"),Rect2(204,466,168,48),_open_section_menu)

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
	if guide != null and guide.active(): guide.refresh(false)
	_refresh_active_mission_panel()
	_menu_button.tooltip_text = tr("nav.settings")
	_menu_button.get_node("Caption").text = tr("nav.settings")
	_timmy_button.tooltip_text = tx("timmy")
	_open_language_settings()
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
				if guide != null: guide.build_closed()
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
	return {"task_guide":guide.capture() if guide != null else {},"placed":placed,"robot":[robot.position.x,robot.position.y,robot.position.z],"rotation":[robot.rotation.x,robot.rotation.y,robot.rotation.z],"moving":bool(click_to_move.get("_moviendo")),"destination":[destination.x,destination.y,destination.z],"expedition":_expedition_pending,"expedition_time":_expedition_timer,"storm_time":_storm_remaining,"storm_count":_storm_count,"storm_profile":_storm_profile.duplicate(),"next_storm":_next_storm_profile.duplicate(),"warning":_storm_warning_emitted,"overload":_gen_overload_timer,"cooldown":_gen_overload_cooldown,"action":_action,"action_remaining":_action_remaining,"action_total":_action_total,"ice":ice.capture() if ice != null else {},"trip_collected":_trip_collected,"trip_ice":_trip_ice,"trip_alerted":_trip_alerted}

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
	if guide != null: guide.restore(data.get("task_guide",{}))
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
	if guide != null: guide.notify("recharge_started")

func gx(key: String, values: Dictionary = {}) -> String:
	return tr("guide."+key).format(values)

func _offer_tour() -> void:
	if session == null or home_paused or _landing_active or _modal_layer != null or session.finished: return
	if guide.active(): guide.refresh(true); return
	if not session.learned.has("task:build") and _gs().paneles_instalados == 0: guide.start("build","panel_solar")

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
	if ice != null: _open_ice_map()

func _on_ice_changed() -> void:
	if ice == null: return
	if ice.phase != "idle":
		_action_panel.show()
		_action_label.text = gx(ice.phase)
		_action_progress.value = 25 if ice.phase == "going" else (75 if ice.phase == "returning" else 50)
	elif _action.is_empty(): _action_panel.hide()
	if session != null and not session.loading: session.save_run()

func _open_ice_map() -> void:
	var panel = _open_drawer("ice_map",tx("expedition"),Vector2(760,540))
	var view = preload("res://ui/ice_survey_panel.gd").new()
	view.training = false
	view.position = Vector2(28,180)
	view.size = Vector2(704,324)
	view.set_state(ice.capture())
	panel.add_child(view)
	_survey_view = view
	view.scan_requested.connect(func(id):
		ice.scan(id)
		view.set_state(ice.capture())
	)
	view.step_performed.connect(func(event):
		if guide != null and event != "collect_requested": guide.notify(event)
	)
	view.trip_requested.connect(func(id):
		if ice.start(id):
			if guide != null: guide.notify("collect_requested")
			_close_modal()
	)
	view.return_requested.connect(_return_to_dome)
	view.cancel_requested.connect(func(): ice.cancel(); _close_modal())
	view.retry_requested.connect(func(): ice.retry(); _close_modal())
	view.narration_requested.connect(func(text):
		if guide == null or not guide.active(): _speak(text)
	)
	if guide != null:
		guide.notify("station_open",{"section":"expedition"})
		guide.layout()

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

func _on_nube_finalizada() -> void:
	super._on_nube_finalizada()
	if session != null: session.resolve_message("storm")
	if alerts != null: alerts.dismiss("storm")

func _play_run_transition(restart: bool, manual: bool) -> void:
	if _transition_active: return
	_transition_active = true
	var mode = _gs().modo_juego
	home_paused = true
	_voice.stop()
	_apply_pause()
	var effect = preload("res://ui/run_transition.gd").new()
	effect.kind = "restart" if restart else "checkpoint"
	effect.message = tr("outcome.restart" if restart else "outcome.checkpoint")
	effect.midpoint.connect(func():
		restore_run_for_transition(restart,mode)
	)
	effect.finished.connect(func():
		_transition_active = false
		home_paused = false
		_apply_pause()
		if not restart: alerts.publish("checkpoint",tr("outcome.restored"),tr("outcome.saved"),"checkpoint","",false)
		if guide.active(): guide.refresh(true)
		elif manual: _offer_tour()
	)
	interfaz.add_child(effect)

func restore_run_for_transition(restart: bool, mode: String) -> void:
	if restart: session.reset_run(mode)
	else: session.recover()
	_gs().en_partida = false
	session.save_run()
	_bridge._zero_handled = false
	_alerted.clear()
	alerts.clear()
	_toast_queue.clear()
	_close_modal()
	_sync_all_from_state()
	_hud.set_mode(mode)
	_apply_pause()

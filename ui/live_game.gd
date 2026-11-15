extends "res://core/juego.gd"
## Adaptador HUD en partida: conecta simulación/RunSession con GameHud, GameDrawer y WorldCallout.
signal options_closed

var options_from_home := false
var _recovering := false
var _swapping_modal := false

const SessionScript = preload("res://progression/run_session.gd")
const GameHudScript = preload("res://ui/game_hud.gd")
const GameDrawerScript = preload("res://ui/game_drawer.gd")
const WorldCalloutScript = preload("res://ui/world_callout.gd")
const SupplyDropScript = preload("res://interaction/supply_drop.gd")

const MODULES := ["panel_solar", "procesador_hielo", "generador_oxigeno", "tanque_agua", "jardin"]
const MODULE_ART := {"panel_solar": "solar", "procesador_hielo": "processor", "generador_oxigeno": "oxygen", "jardin": "garden"}
const UPGRADE_DROPS := {"panel_extra": "panel_solar", "jardin_lunar": "jardin"}
const PASSIVE_TRIGGERS := ["partida_iniciada"]

var _active_drop_id := ""
var _pending_pickup_drop_id := ""
var session: Node
var home_paused := false
var _session_ready := false
var _toast_queue: Array = []
var _alerted: Dictionary = {}
var _focus_before: Control
var _action := ""
var _action_remaining := 0.0
var _action_total := 0.0
var _telemetry_timer := 0.0
var _voice_refresh_elapsed := 0.0
var _audio_voice_signature := ""
var _goals: Dictionary = {}
var _callout_mode := ""
var _coach_target := ""
var _trip_collected := false
var _trip_ice := 0
var _trip_alerted := false

var _drawer: Panel
var _place_callout: Panel
var _world_callout: Panel
var ice: Node


func tx(key: String, values: Dictionary = {}) -> String:
	return tr("live." + key).format(values)


func gx(key: String, values: Dictionary = {}) -> String:
	return tr("guide." + key).format(values)


func _post_ready_init() -> void:
	var gs := _gs()
	if not gs.en_partida:
		gs.iniciar_partida(gs.modo_juego)
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
	var mm: Node = gs.obtener_mission_manager()
	mm.progreso_objetivo_actualizado.connect(func(_id, _done, _total): _refresh_active_mission_panel())
	mm.simulacro_supertormenta_solicitado.connect(_on_m14_superstorm_requested)
	mm.mision_activa_cambiada.connect(_on_mission_activated)
	mm.mision_fallida.connect(func(id, text):
		session.add_message("failure:" + id + ":" + str(roundi(gs.tiempo_juego)), "text", {"text": text})
		_show_toast(text, 5.0)
	)
	placement_system.piece_catalog[&"tanque_agua"] = load("res://assets/3d/tanque_agua.tscn")
	placement_system.dome_center = _dome_world_pos()
	placement_system.placement_rejected.connect(func(_id, reason): _show_toast(tx("outside_dome") if reason == "outside_dome" else tx("blocked")))
	_sync_all_from_state()
	_refresh_mail_badge()
	if session.restored or home_paused or DisplayServer.get_name() == "headless":
		_activar_camara_juego()
		set_paused(home_paused)
		call_deferred("_maybe_show_reward")
		_bridge._check_failure()
		if DisplayServer.get_name() != "headless":
			call_deferred("_offer_tour")
	else:
		gs.en_partida = false
		_start_landing_cinematic()


func _setup_bridge_and_ui() -> void:
	var goal_data := JSON.new()
	if FileAccess.file_exists("res://ui/mission_goals.json") and goal_data.parse(FileAccess.get_file_as_string("res://ui/mission_goals.json")) == OK and goal_data.data is Dictionary:
		_goals = goal_data.data
	_catalog = CatalogScript.new()
	_bridge = BridgeScript.new()
	add_child(_bridge)
	_voice = VoiceScript.new()
	add_child(_voice)

	var gs := _gs()
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
	_ui_root.size = Vector2(1280, 720)
	_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interfaz.add_child(_ui_root)

	_hud = GameHudScript.new()
	_ui_root.add_child(_hud)
	_hud.resource_pressed.connect(_on_resource_pressed)
	_hud.dock_pressed.connect(_on_dock_action)
	_hud.settings_pressed.connect(_open_section_menu)
	_hud.timmy_pressed.connect(_open_timmy)
	_hud.mission_pressed.connect(func(): _on_dock_action("missions"))
	_hud.storm_notice_pressed.connect(func(): _open_section_drawer("messages"))
	_hud.set_mode(gs.modo_juego)
	_storm_badge = _hud.storm_banner

	_drawer = GameDrawerScript.new()
	_ui_root.add_child(_drawer)
	_drawer.close_requested.connect(_close_drawer)
	_drawer.navigate_requested.connect(_on_drawer_action)

	_place_callout = WorldCalloutScript.new()
	_ui_root.add_child(_place_callout)
	_world_callout = WorldCalloutScript.new()
	_ui_root.add_child(_world_callout)
	_world_callout.closed.connect(func():
		_callout_mode = ""
		_sync_dock_highlight()
	)

	_build_placement_and_toast()


func _build_side_mission_card() -> void: pass
func _build_top_toolbar() -> void: pass
func _build_bottom_dock() -> void: pass
func _refresh_build_tray_labels() -> void: pass
func _refresh_dock_states() -> void:
	_sync_dock_highlight()
func _refresh_controls_hint() -> void: pass
func _update_cam_button_label() -> void: pass


func _build_placement_and_toast() -> void:
	_toast_panel = UI.panel(_ui_root, Rect2(360, 560, 520, 58), Color("#0c1c31f2"), 14)
	_toast_panel.hide()
	_toast_label = UI.label(_toast_panel, "", Rect2(16, 6, 488, 46), 14, UI.WHITE, true)
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _process(delta: float) -> void:
	super._process(delta)
	if not _session_ready:
		return
	if _toast_timer <= 0.0 and not _toast_queue.is_empty() and not is_instance_valid(_modal_layer) and not home_paused:
		var item: Dictionary = _toast_queue.pop_front()
		_toast_label.text = str(item.text)
		_toast_timer = float(item.seconds)
		var drawer_open := is_instance_valid(_drawer) and _drawer.visible
		_toast_panel.position.x = 320.0 if drawer_open else 380.0
		_toast_panel.show()
		if bool(item.get("voice", false)):
			_speak(str(item.text))
	if is_instance_valid(_drawer) and _drawer.visible and _drawer.kind == "settings:audio":
		_voice_refresh_elapsed += delta
		if _voice_refresh_elapsed >= 0.5:
			_voice_refresh_elapsed = 0.0
			_refresh_audio_voices()
	if _gs().en_partida and not _action.is_empty():
		_action_remaining -= delta
		var pct := 100.0 * (1.0 - maxf(_action_remaining, 0.0) / maxf(_action_total, 0.01))
		if is_instance_valid(_drawer) and _drawer.visible and _drawer.kind == "processing":
			_drawer.update_processing_progress(pct)
		if _action_remaining <= 0.0:
			var action := _action
			_action = ""
			if action == "processing":
				super._run_processing()
				if is_instance_valid(_drawer) and _drawer.visible and _drawer.kind == "processing":
					_open_section_drawer("processing")
			elif action == "collect_drop":
				_complete_supply_drop_pickup()
			else:
				super._run_repair()
			if _session_ready and not session.loading:
				session.save_run()

	_telemetry_timer += delta
	if _telemetry_timer >= 0.5:
		_telemetry_timer = 0.0
		_refresh_active_mission_panel()
		_check_resource_alerts()
		_hud.set_state(_bridge.get_state())
		_refresh_mail_badge()

	_refresh_storm_banner()
	_refresh_world_callouts()


func set_paused(paused: bool) -> void:
	if paused and is_instance_valid(_voice):
		_voice.stop()
	home_paused = paused
	_apply_pause()


func _apply_pause() -> void:
	var drawer_paused: bool = is_instance_valid(_drawer) and bool(_drawer.blocks_world())
	var blocked: bool = home_paused or is_instance_valid(_modal_layer) or drawer_paused or _landing_active or (session != null and session.finished)
	_gs().en_partida = not blocked
	_set_gameplay_input_enabled(not blocked)
	placement_system.set_process_unhandled_input(not blocked)
	placement_system.set_physics_process(not blocked)
	robot.process_mode = Node.PROCESS_MODE_DISABLED if blocked else Node.PROCESS_MODE_INHERIT
	for node in [mundo, vicuna, tormenta, estructuras_colocadas]:
		node.process_mode = Node.PROCESS_MODE_DISABLED if blocked else Node.PROCESS_MODE_INHERIT


func _on_landing_completed() -> void:
	super._on_landing_completed()
	_apply_pause()
	_maybe_show_reward()
	call_deferred("_offer_tour")


func _open_modal(kind: String, title: String, panel_size: Vector2) -> Control:
	if is_instance_valid(_voice):
		_voice.stop()
	_close_drawer()
	_focus_before = get_viewport().gui_get_focus_owner()
	_swapping_modal = true
	var panel := super._open_modal(kind, title, panel_size)
	_swapping_modal = false
	_toast_panel.hide()
	_apply_pause()
	UI.label(panel, tx("paused"), Rect2(28, panel_size.y - 30, panel_size.x - 56, 22), 12, UI.CYAN)
	call_deferred("_trap_focus")
	return panel


func _close_modal() -> void:
	if is_instance_valid(_voice):
		_voice.stop()
	for queued in _toast_queue:
		if queued.has("voice"):
			queued.voice = false
	var notify_home := options_from_home and not _swapping_modal
	super._close_modal()
	if notify_home:
		options_from_home = false
		options_closed.emit()
	if _session_ready:
		_apply_pause()
		call_deferred("_maybe_show_reward")
	if is_instance_valid(_focus_before) and _focus_before.is_visible_in_tree():
		_focus_before.grab_focus()


func _trap_focus() -> void:
	if not is_instance_valid(_modal_layer):
		return
	var controls: Array[Control] = []
	for node in _modal_layer.find_children("*", "Control", true, false):
		if node.is_visible_in_tree() and node.focus_mode == Control.FOCUS_ALL and not (node is BaseButton and node.disabled):
			controls.append(node)
	if controls.is_empty():
		return
	for i in controls.size():
		controls[i].focus_next = controls[i].get_path_to(controls[(i + 1) % controls.size()])
		controls[i].focus_previous = controls[i].get_path_to(controls[posmod(i - 1, controls.size())])
	controls[0].grab_focus()


func _close_drawer() -> void:
	if is_instance_valid(_voice):
		_voice.stop()
	if is_instance_valid(_drawer):
		_drawer.close_drawer()
	if options_from_home:
		options_from_home = false
		options_closed.emit()
	_sync_dock_highlight()
	if _session_ready:
		_apply_pause()
		call_deferred("_maybe_show_reward")


func _sync_dock_highlight() -> void:
	if not is_instance_valid(_hud):
		return
	var active := ""
	if is_instance_valid(_drawer) and _drawer.visible:
		match _drawer.kind:
			"construction": active = "construction"
			"expedition": active = "expedition"
			"missions": active = "missions"
			"more", "processing", "upgrades", "science", "messages": active = "more"
	elif placement_system.is_placing():
		active = "construction"
	elif _callout_mode == "repair_prompt" or _action == "repair":
		active = "repair"
	elif _callout_mode == "rest_prompt" or _gs().descansando_en_domo:
		active = "more"
	elif _callout_mode == "crater_prompt" or (ice != null and ice.phase != "idle"):
		active = "expedition"
	_hud.set_active_tab(active)


func _open_section_menu() -> void:
	if _session_ready and not session.loading:
		session.save_run()
	if is_instance_valid(_drawer) and _drawer.visible and _drawer.kind.begins_with("settings"):
		_close_drawer()
		return
	_open_section_drawer("settings")


func _on_dock_action(id: String) -> void:
	if is_instance_valid(_drawer) and _drawer.visible and _drawer.kind == id:
		_close_drawer()
		return
	if id == "repair" and _callout_mode == "repair_prompt":
		_callout_mode = ""
		_sync_dock_highlight()
		return
	if session != null and id in ["construction", "expedition", "processing", "repair", "rest", "missions", "upgrades", "science", "messages"] and not session.learned.has(id):
		_show_coach(id)
	else:
		_perform_station(id)


func _perform_station(id: String) -> void:
	if id == "more":
		_open_section_drawer("more")
	elif id == "repair":
		_close_drawer()
		_callout_mode = "repair_prompt"
		_sync_dock_highlight()
	elif id == "rest":
		_close_drawer()
		_callout_mode = "rest_prompt"
		_sync_dock_highlight()
	elif id == "timmy":
		_open_timmy()
	else:
		_open_section_drawer(id)


func _open_section_drawer(section: String, extra: Dictionary = {}) -> void:
	if is_instance_valid(_modal_layer):
		_close_modal()
	_callout_mode = ""
	var data := _build_drawer_data(section, extra)
	_drawer.open_section(section, data)
	_sync_dock_highlight()
	_apply_pause()


func _build_drawer_data(section: String, extra: Dictionary) -> Dictionary:
	var gs := _gs()
	match section:
		"more":
			return {"title": tx("hud_more_tab"), "icon": "menu", "tint": UI.CYAN, "unread": session.unread_count() if session != null else 0}
		"construction":
			var mods: Array = []
			for id in MODULES:
				var tex: Texture2D = null
				if id == "tanque_agua":
					var atlas := AtlasTexture.new()
					atlas.atlas = load("res://assets/3d/revision/tanque_agua.jpg")
					atlas.region = Rect2(736, 1810, 308, 308)
					tex = atlas
				else:
					tex = load("res://assets/ui/activities/" + str(MODULE_ART[id]) + "-v1.png")
				var count := _structure_count(gs, id)
				var limit := _structure_limit(id)
				var stock := int(session.inventory.get(id, 0)) if session != null else 0
				var upgrade_gated: bool = (id == "panel_solar" and count >= limit and not _has_upgrade("panel_extra")) or (id == "jardin" and count >= limit and not _has_upgrade("jardin_lunar"))
				mods.append({
					"id": id,
					"name": module_name(id),
					"stock": stock,
					"installed": count,
					"limit": limit,
					"cost": module_cost(id),
					"locked": count >= limit,
					"need_upgrade": upgrade_gated,
					"texture": tex,
					"has_picture": true,
				})
			return {"title": tx("construction"), "icon": "construction", "tint": UI.GOLD, "modules": mods}
		"expedition":
			var zones: Array = []
			if ice != null:
				for item in ice.ZONES:
					var zid := str(item.id)
					if ice.discovered.has(zid):
						zones.append({"id": zid, "name": gx(str(item.name)), "stock": int(ice.stock.get(zid, 0))})
			return {
				"title": tx("expedition"),
				"icon": "ice",
				"tint": Color("#68b9ff"),
				"zones": zones,
				"selected": ice.selected if ice != null else "crater",
				"phase": ice.phase if ice != null else "idle",
				"can_scan": ice != null and ice.discovered.size() < ice.ZONES.size(),
			}
		"processing":
			var running := (_action == "processing")
			var pct := 100.0 * (1.0 - maxf(_action_remaining, 0.0) / maxf(_action_total, 0.01)) if running else 0.0
			return {
				"title": tx("process_running_title") if running else tx("processing"),
				"icon": "agua",
				"tint": Color("#68b9ff"),
				"running": running,
				"progress": pct,
				"ice": int(gs.hielo),
				"capacity": _processor_capacity(),
			}
		"missions":
			var prog := _build_progression_dict()
			return {
				"title": tx("missions"),
				"icon": "missions",
				"tint": UI.CYAN,
				"items": _catalog.missions(false),
				"current_id": str(prog.get("current_mission", "")),
				"completed": prog.get("completed_missions", []),
				"objective_done": int(prog.get("objective_done", 0)),
				"objective_total": int(prog.get("objective_total", 1)),
				"mode": str(gs.modo_juego),
			}
		"upgrades":
			var prog := _build_progression_dict()
			return {
				"title": tx("upgrades"),
				"icon": "upgrades",
				"tint": Color("#b4a4ff"),
				"items": _catalog.upgrades(false),
				"unlocked": prog.get("unlocked_upgrades", []),
				"stars": int(gs.estrellas),
			}
		"science":
			return {"title": tx("science"), "icon": "science", "tint": Color("#7fe7bf"), "cards": _science_cards()}
		"messages":
			var list: Array = []
			if session != null:
				for item in session.messages:
					list.append({"id": str(item.id), "kind": str(item.kind), "text": message_text(item), "unread": not bool(item.get("read", false)), "resource":str(item.get("data",{}).get("resource","agua"))})
			return {"title": tx("messages"), "icon": "messages", "tint": UI.CYAN, "items": list}
		"timmy", "coach":
			return {
				"title": str(extra.get("title", "Timmy")),
				"icon": "timmy",
				"tint": UI.GOLD,
				"subtitle": str(extra.get("subtitle", tx("next"))),
				"body": str(extra.get("body", _next_advice())),
				"confirm_label": str(extra.get("confirm_label", tx("understood"))),
				"coach_id": str(extra.get("coach_id", "")),
			}
		"resource":
			return extra
		"settings":
			return {"title": tx("hud_settings"), "icon": "settings", "tint": Color("#c7d6e6")}
		"settings:language":
			return {"title": tx("settings_lang"), "icon": "menu", "tint": UI.CYAN}
		"settings:audio":
			var voices: Array = _voice.voices_for(gs.idioma) if is_instance_valid(_voice) else []
			return {
				"title": tx("settings_audio"),
				"icon": "audio",
				"tint": UI.CYAN,
				"muted": _voice.muted if is_instance_valid(_voice) else true,
				"lang": gs.idioma,
				"voices": voices,
				"selected_voice": str(_voice.selected_voices.get(gs.idioma, "")) if is_instance_valid(_voice) else "",
				"volume": _voice.volume if is_instance_valid(_voice) else 85,
				"rate": _voice.rate if is_instance_valid(_voice) else 0.95,
			}
		"settings:controls":
			return {"title": tx("help"), "icon": "target", "tint": UI.CYAN}
		"settings:exit":
			return {"title": tx("settings_exit"), "icon": "warning", "tint": Color("#ff927a")}
	return {"title": tx(section)}


func _on_drawer_action(target: String, payload: Dictionary) -> void:
	match target:
		"guide_alert":
			var resource := str(payload.get("resource","agua"))
			if resource in ["agua","oxigeno"]:
				_show_coach("processing" if _gs().hielo > 0 else "expedition")
			elif resource == "energia_robot": _show_coach("rest")
			elif resource == "escudo": _show_coach("repair")
			else: _show_coach("construction")
		"open_section":
			_open_section_drawer(str(payload.get("id", "more")), payload)
		"open_action":
			_perform_station(str(payload.get("id", "rest")))
		"build_module":
			_start_build(str(payload.get("id", "")))
		"select_ice_zone":
			if ice != null:
				ice.selected = str(payload.get("id", "crater"))
			_open_section_drawer("expedition")
		"scan_ice":
			if ice != null:
				ice.discover()
			_open_section_drawer("expedition")
		"return_dome":
			_close_drawer()
			if ice != null:
				ice.return_home()
		"start_ice":
			_close_drawer()
			if ice != null:
				if ice.phase == "blocked":
					ice.retry()
				else:
					ice.start(ice.selected)
		"cancel_ice":
			if ice != null:
				ice.cancel()
			_close_drawer()
		"run_processing":
			_run_processing()
		"refresh_upgrades":
			_open_section_drawer("upgrades")
		"buy_upgrade":
			_on_upgrade_requested(str(payload.get("id", "")))
		"refresh_science":
			_open_section_drawer("science")
		"read_message":
			if session != null:
				session.mark_read(str(payload.get("id", "")))
			_refresh_mail_badge()
			_speak(str(payload.get("text", "")))
			_open_section_drawer("messages")
		"speak":
			_speak(str(payload.get("text", "")))
		"confirm_timmy":
			var cid := str(payload.get("coach_id", ""))
			if not cid.is_empty() and session != null:
				session.learned[cid] = true
				session.save_run()
				_close_drawer()
				if cid != "tour":
					_perform_station(cid)
			else:
				_close_drawer()
		"set_language":
			_set_language(str(payload.get("lang", "es")))
		"toggle_mute":
			_voice.muted = not _voice.muted
			_save_preferences()
			_open_section_drawer("settings:audio")
		"select_voice":
			_voice.set_voice(_gs().idioma, str(payload.get("id", "")))
			_save_preferences()
		"set_volume":
			_voice.volume = int(payload.get("value", 85))
			_save_preferences()
		"set_rate":
			_voice.rate = float(payload.get("value", 0.95))
			_save_preferences()
		"test_voice":
			_speak(tx("welcome", {"name": _player_name()}))
		"return_home":
			_close_drawer()
			_return_home()


func _science_cards() -> Array:
	var result: Array = []
	var gs := _gs()
	var sm: Node = gs.obtener_save_manager()
	var mm: Node = gs.obtener_mission_manager()
	for mission in mm.obtener_todas_las_misiones():
		if sm.obtener_cartas_desbloqueadas().has("carta_" + str(mission.id)):
			var card: Dictionary = mm.obtener_mision_localizada(mission).get("carta_nasa", {}).duplicate(true)
			if not card.is_empty():
				card["art"] = _mission_art(str(mission.id))
				result.append(card)
	var tree: Node = gs.obtener_tech_tree()
	for id in sm.obtener_mejoras_compradas():
		var card: Dictionary = tree.obtener_mejora_localizada(tree.obtener_mejora(id)).get("carta_nasa", {}).duplicate(true)
		if not card.is_empty():
			card["art"] = "solar" if id in ["panel_extra", "bateria_modular", "celulas_optimizadas"] else ("repair" if id in ["reparar_barato", "mas_resistencia", "alerta_temprana"] else ("garden" if id == "jardin_lunar" else "processor"))
			result.append(card)
	return result


func module_name(id: String) -> String:
	return tx("tank") if id == "tanque_agua" else tr("structures." + id)


func module_cost(id: String) -> int:
	return int(STRUCTURE_COST.get(id, 10))


func _start_build(id: String) -> void:
	if session == null:
		return
	var gs := _gs()
	var count := _structure_count(gs, id)
	var limit := _structure_limit(id)
	if count >= limit:
		if id == "panel_solar" and not _has_upgrade("panel_extra"):
			_show_toast(_msg("Desbloquea Panel Solar Extra en Mejoras para ampliar el límite.", "Unlock Extra Solar Panel in Upgrades to expand the limit."))
		elif id == "jardin" and not _has_upgrade("jardin_lunar"):
			_show_toast(tx("garden_locked"))
		else:
			_show_toast(_msg("Límite de %s alcanzado (%d/%d)." % [module_name(id), count, limit], "%s limit reached (%d/%d)." % [module_name(id), count, limit]))
		return
	if int(session.inventory.get(id, 0)) <= 0:
		_show_toast(tx("no_stock"))
		return
	if not gs.puede_pagar("energia", module_cost(id)):
		_show_toast(_msg("Energía insuficiente.", "Not enough base energy."))
		return
	_close_drawer()
	_pending_build_id = id
	placement_system.keep_placing_with_shift = false
	placement_system.start_placement(StringName(id))
	_sync_dock_highlight()


func _on_piece_placed(piece_id: StringName, _position: Vector3) -> void:
	var id := str(piece_id)
	var gs := _gs()
	var last: Node = null
	if is_instance_valid(estructuras_colocadas) and estructuras_colocadas.get_child_count() > 0:
		var cand := estructuras_colocadas.get_child(estructuras_colocadas.get_child_count() - 1)
		if str(cand.get_meta(&"piece_id", &"")) == id:
			last = cand
	var count := _structure_count(gs, id, last)
	var limit := _structure_limit(id)
	if count >= limit:
		if is_instance_valid(last):
			last.queue_free()
		_pending_build_id = ""
		_show_toast(_msg("Límite de %s alcanzado (%d/%d)." % [module_name(id), limit, limit], "%s limit reached (%d/%d)." % [module_name(id), limit, limit]))
		return
	if session == null or int(session.inventory.get(id, 0)) <= 0 or not gs.puede_pagar("energia", module_cost(id)):
		if is_instance_valid(last):
			last.queue_free()
		_pending_build_id = ""
		_show_toast(tx("no_stock"))
		return
	gs.pagar("energia", module_cost(id))
	session.inventory[id] = int(session.inventory[id]) - 1
	match id:
		"panel_solar": gs.paneles_instalados += 1
		"procesador_hielo": gs.procesador_instalado = true
		"generador_oxigeno": gs.generador_instalado = true
		"jardin": gs.jardin_instalado = true
		"tanque_agua": gs.agua_max += 50.0
	_pending_build_id = ""
	gs.notificar_evento_mision("estructura_construida", {"id_estructura": id, "total_paneles": gs.paneles_instalados})
	_show_toast(tx("module_done", {"module": module_name(id)}))
	_bind_stations()
	session.save_run()
	_sync_all_from_state()
	_sync_dock_highlight()


func _on_placement_cancelled(_id: StringName) -> void:
	_pending_build_id = ""
	if is_instance_valid(_place_callout):
		_place_callout.hide()
	_sync_dock_highlight()


func _update_placement_banner(placing: bool) -> void:
	if not placing and is_instance_valid(_place_callout):
		_place_callout.hide()
	_sync_dock_highlight()


func _run_processing() -> void:
	var gs := _gs()
	if not gs.procesador_instalado or gs.hielo <= 0 or _robot_distance_to_processing_zone() > _dome_recharge_radius() or not gs.puede_pagar("energia", mini(gs.hielo, _processor_capacity()) * 0.5):
		super._run_processing()
		return
	_begin_action("processing", 3.0 if _has_upgrade("procesar_rapido") else 5.0)
	_open_section_drawer("processing")


func _run_repair() -> void:
	var gs := _gs()
	if gs.escudo >= 99.5:
		super._run_repair()
		return
	if not gs.puede_pagar("energia", _repair_energy_cost()):
		super._run_repair()
		return
	_callout_mode = ""
	_begin_action("repair", _repair_time_seconds())


func _begin_action(id: String, seconds: float) -> void:
	if not _action.is_empty():
		_show_toast(tx("action_busy"))
		return
	_action = id
	_action_total = seconds
	_action_remaining = seconds
	_sync_dock_highlight()


func _tick_expedition(delta: float) -> void:
	if ice != null:
		ice.tick(delta)


func _open_timmy() -> void:
	_open_section_drawer("timmy", {"title": "Timmy", "subtitle": tx("next"), "body": _next_advice(), "confirm_label": tx("understood")})


func _visible_mission_counts(m: Dictionary) -> Dictionary:
	var triggers: Array = m.get("trigger", [])
	var mm: Node = _gs().obtener_mission_manager()
	var done: Array = mm.obtener_triggers_cumplidos() if mm != null else []
	var vis_total := 0
	var vis_done := 0
	for t in triggers:
		var tid := str(t)
		if PASSIVE_TRIGGERS.has(tid):
			continue
		vis_total += 1
		if done.has(tid):
			vis_done += 1
	if vis_total == 0:
		vis_total = maxi(1, triggers.size())
		vis_done = done.size()
	return {"done": vis_done, "total": vis_total}


func _storm_eta_suffix(id: String) -> String:
	var gs := _gs()
	if gs == null or not (id in ["mision_10", "mision_12", "mision_14", "mision_16"]):
		return ""
	if bool(gs.nube_activa) or bool(gs.alerta_nube) or not _storms_unlocked_for_mission(gs):
		return ""
	return tx("storm_eta", {"s": maxi(1, int(ceil(float(gs.tiempo_para_nube))))})


func _next_advice() -> String:
	var mission: Dictionary = _gs().obtener_mision_activa_localizada()
	var objectives: Array = mission.get("objetivo", [])
	var counts := _visible_mission_counts(mission)
	var index := mini(maxi(0, objectives.size() - 1), int(floor(float(counts.done) * objectives.size() / maxi(1, int(counts.total)))))
	var text := tx("hint", {"name": _player_name(), "goal": str(objectives[index]) if not objectives.is_empty() else tx("victory")})
	var eta := _storm_eta_suffix(str(mission.get("id", "")))
	if not eta.is_empty():
		text += " " + eta + "."
	return text


func _speak(text: String) -> void:
	if is_instance_valid(_voice):
		_voice.speak(text, TranslationServer.get_locale())


func _refresh_active_mission_panel() -> void:
	if not is_instance_valid(_hud):
		return
	var gs := _gs()
	var m: Dictionary = gs.obtener_mision_activa_localizada()
	if m.is_empty():
		var fallback_title := tx("victory") if session != null and session.all_missions_complete() else tr("mission.none")
		_hud.set_mission_summary(fallback_title, 1, 1)
		return
	var counts := _visible_mission_counts(m)
	var goals: Array = m.get("objetivo", [])
	var index := mini(maxi(0, goals.size() - 1), int(floor(float(counts.done) * goals.size() / maxi(1, int(counts.total)))))
	var short_desc := str(_goals.get("es" if TranslationServer.get_locale().begins_with("es") else "en", {}).get(str(m.id), str(m.get("mision", ""))))
	if short_desc.is_empty() and not goals.is_empty():
		short_desc = str(goals[index])
	var details := str(m.get("mision", "")) + "\n" + "\n".join(goals)
	var eta := _storm_eta_suffix(str(m.id))
	if not eta.is_empty():
		details += "\n" + eta
	_hud.set_mission_summary(short_desc, int(counts.done), int(counts.total), details)


func _refresh_storm_banner() -> void:
	if not is_instance_valid(_hud):
		return
	var gs := _gs()
	if gs == null:
		return
	if bool(gs.nube_activa):
		var sec_rem := maxi(0, int(ceil(_storm_remaining)))
		_hud.set_storm_alert(true, tx("storm_now", {"s": sec_rem}), tx("storm_sub"))
	elif bool(gs.alerta_nube) and float(gs.tiempo_para_nube) > 0.0:
		var sec_warn := maxi(1, int(ceil(gs.tiempo_para_nube)))
		_hud.set_storm_alert(true, tx("storm_in", {"s": sec_warn}), tx("storm_sub"))
	else:
		_hud.set_storm_alert(false)


func _refresh_world_callouts() -> void:
	var hide_world: bool = _landing_active or home_paused or is_instance_valid(_modal_layer) or (is_instance_valid(_drawer) and bool(_drawer.blocks_world()))
	var right_margin: float = (_drawer.size.x + 28.0) if (is_instance_valid(_drawer) and _drawer.visible) else 16.0
	if is_instance_valid(_place_callout):
		if hide_world or not placement_system.is_placing() or _pending_build_id.is_empty():
			_place_callout.hide()
		else:
			var valid: bool = placement_system.has_valid_target()
			var cost := module_cost(_pending_build_id)
			var info := tx("place_valid", {"n": cost}) if valid else tx("place_invalid")
			_place_callout.configure({
				"icon": "construction",
				"tint": UI.CYAN if valid else Color("#ff927a"),
				"title": module_name(_pending_build_id),
				"body": info,
				"body_color": Color("#d3e1ee") if valid else Color("#ff927a"),
				"world_pos": placement_system.get_ghost_position() + Vector3(0, 1.8, 0),
				"width": 256,
				"actions": [
					{"text": tx("cancel"), "primary": false, "callback": func(): placement_system.cancel_placement()},
					{"text": tx("place_confirm"), "primary": true, "disabled": not valid, "callback": func(): placement_system.confirm_current()},
				],
			})
			_place_callout.update_screen_position(camara, -14.0, right_margin)

	if not is_instance_valid(_world_callout):
		return
	if hide_world:
		_world_callout.hide()
		return

	var gs := _gs()
	var dome_pos := _dome_world_pos()
	var robot_pos := robot.global_position if is_instance_valid(robot) else dome_pos
	if _action == "repair":
		var pct := 100.0 * (1.0 - maxf(_action_remaining, 0.0) / maxf(_action_total, 0.01))
		_world_callout.configure({
			"icon": "repair", "tint": Color("#7fe7bf"),
			"title": tx("repair_running_title"), "body": tx("repair_running_desc"),
			"show_bar": true, "progress": pct, "bar_color": Color("#7fe7bf"),
			"world_pos": dome_pos + Vector3(0, 3.0, 0), "width": 248,
		})
	elif _action == "collect_drop":
		var drop_node := _find_drop_node(_active_drop_id)
		var pct := 100.0 * (1.0 - maxf(_action_remaining, 0.0) / maxf(_action_total, 0.01))
		_world_callout.configure({
			"icon": "construction", "tint": UI.GOLD,
			"title": tx("drop_collecting"),
			"show_bar": true, "progress": pct, "bar_color": UI.GOLD,
			"world_pos": (drop_node.global_position if is_instance_valid(drop_node) else robot_pos) + Vector3(0, 1.8, 0), "width": 236,
		})
	elif ice != null and ice.phase in ["going", "mining", "returning", "blocked"]:
		var zone_pos: Vector3 = ice.zone(ice.selected).position
		if ice.phase == "returning":
			_world_callout.configure({
				"icon": "escudo", "tint": Color("#68b9ff"),
				"title": tx("ice_returning_title"), "body": tx("ice_returning_desc", {"n": maxi(1, int(ice.collected))}),
				"show_bar": true, "progress": 72.0, "bar_color": Color("#68b9ff"),
				"world_pos": dome_pos + Vector3(0, 3.0, 0), "width": 248,
			})
		elif ice.phase == "blocked":
			_world_callout.configure({
				"icon": "warning", "tint": Color("#ff927a"),
				"title": gx("blocked"),
				"world_pos": robot_pos + Vector3(0, 2.2, 0), "width": 266,
				"actions": [
					{"text": gx("stop_trip"), "primary": false, "callback": func(): ice.cancel()},
					{"text": gx("retry"), "primary": true, "callback": func(): ice.retry()},
				],
			})
		else:
			_world_callout.configure({
				"icon": "ice", "tint": Color("#68b9ff"),
				"title": tx("ice_mining_title") if ice.phase == "mining" else gx("going"),
				"body": tx("ice_mining_desc"),
				"show_bar": true, "progress": 55.0 if ice.phase == "mining" else 28.0, "bar_color": Color("#7fe7bf"),
				"world_pos": (zone_pos if ice.phase == "mining" else robot_pos) + Vector3(0, 2.0, 0), "width": 252,
				"actions": [{"text": gx("stop_trip"), "primary": false, "expand": false, "callback": func(): ice.cancel()}],
			})
	elif bool(gs.descansando_en_domo):
		_world_callout.configure({
			"icon": "robot_battery", "tint": Color("#b4a4ff"),
			"title": tx("rest_running_title"), "body": tx("rest_running_desc"),
			"show_bar": true, "progress": float(gs.energia_robot), "bar_color": Color("#b4a4ff"),
			"world_pos": robot_pos + Vector3(0, 2.1, 0), "width": 248,
		})
	elif (bool(gs.alerta_nube) or bool(gs.nube_activa)) and _robot_distance_to_dome() > _dome_recharge_radius():
		_world_callout.configure({
			"icon": "escudo", "tint": Color("#68b9ff"),
			"title": tx("shelter_title"), "body": tx("shelter_desc"),
			"world_pos": dome_pos + Vector3(0, 3.0, 0), "width": 244,
			"actions": [{"text": tx("return_dome"), "primary": true, "expand": false, "callback": _return_to_dome}],
		})
	elif _callout_mode == "repair_prompt":
		var repair_cost := _repair_energy_cost()
		_world_callout.configure({
			"icon": "repair", "tint": Color("#68b9ff"),
			"title": tx("repair_title"), "body": tx("repair_summary", {"pct": roundi(gs.escudo)}),
			"show_bar": true, "progress": float(gs.escudo), "bar_color": Color("#ff927a"),
			"closable": true, "world_pos": dome_pos + Vector3(0, 3.0, 0), "width": 256,
			"actions": [{"text": tx("repair_btn_cost", {"n": repair_cost}), "primary": true, "callback": _run_repair}],
		})
	elif _callout_mode == "rest_prompt":
		var near := _robot_distance_to_dome() <= _dome_recharge_radius()
		_world_callout.configure({
			"icon": "robot_battery", "tint": Color("#b4a4ff"),
			"title": tx("rest"), "body": tx("rest_summary", {"pct": roundi(gs.energia_robot)}),
			"show_bar": true, "progress": float(gs.energia_robot), "bar_color": Color("#b4a4ff"),
			"closable": true, "world_pos": robot_pos + Vector3(0, 2.1, 0), "width": 256,
			"actions": [{"text": tx("rest_start_btn") if near else tx("return_dome"), "primary": true, "callback": _finish_rest_prompt}],
		})
	elif _callout_mode == "crater_prompt":
		var crater := mundo.get_node_or_null("CraterHielo") as Node3D
		_world_callout.configure({
			"icon": "ice", "tint": Color("#68b9ff"),
			"title": tx("ice_crater_title"), "body": tx("ice_crater_desc"),
			"closable": true, "world_pos": (crater.global_position if crater != null else dome_pos) + Vector3(0, 1.8, 0), "width": 244,
			"actions": [{"text": tx("expedition"), "primary": true, "expand": false, "callback": _open_expedition_callout}],
		})
	else:
		_world_callout.hide()
		return

	_world_callout.update_screen_position(camara, -18.0, right_margin)


func _finish_rest_prompt() -> void:
	_callout_mode = ""
	if _robot_distance_to_dome() <= _dome_recharge_radius():
		_run_rest()
	else:
		_return_to_dome()


func _open_expedition_callout() -> void:
	_callout_mode = ""
	_open_section_drawer("expedition")


func _on_mision_completada(_id: String, _stars: int, _card: Dictionary) -> void:
	_sync_all_from_state()


func _on_upgrade_requested(id: String) -> void:
	var tree: Node = _gs().obtener_tech_tree()
	var result: Dictionary = tree.puede_comprar(id)
	if not bool(result.get("ok", false)):
		_show_toast(_upgrade_reason(id, result), 4.0)
		return
	if _gs().comprar_mejora(id):
		if EXPANSION_UPGRADES.has(id):
			_sync_dome_scale(true)
		if UPGRADE_DROPS.has(id):
			_spawn_upgrade_supply_drop(id)
		session.save_run()
		_sync_all_from_state()
		_open_upgrade_receipt(id)


func _check_resource_alerts() -> void:
	var gs := _gs()
	var ids := ["energia", "agua", "oxigeno", "escudo", "energia_robot"]
	var keys := ["low_energy", "low_water", "low_oxygen", "low_shield", "low_robot"]
	for i in ids.size():
		var id: String = ids[i]
		var value := float(gs.get(id))
		if value > 30.0:
			_alerted.erase(id)
		if value <= 20.0 and not _alerted.has(id):
			_alerted[id] = true
			var text := tx("low", {"resource": tr("hud." + id + ".nombre"), "action": tx(keys[i])})
			session.add_message("low:" + id + ":" + str(roundi(gs.tiempo_juego)), "text", {"text": text})
			_queue_alert(text, 5.0)


func _on_advertencia_nube(seconds: float) -> void:
	super._on_advertencia_nube(seconds)
	if session != null:
		session.add_message("storm:" + str(roundi(_gs().tiempo_juego)), "storm", {})
		_queue_alert(tx("storm"), 5.0, true)
		if _gs().en_viaje_hielo:
			_trip_alerted = true


func _on_ciclo_solar_cambiado(day: bool) -> void:
	super._on_ciclo_solar_cambiado(day)
	if session != null:
		session.add_message("cycle:" + str(roundi(_gs().tiempo_juego)), "day" if day else "night", {})
		_queue_alert(tx("day" if day else "night"), 4.0)


func _show_toast(message: String, seconds: float = 2.6) -> void:
	var clean := message.replace("⚡", " energy").replace("🔋", " battery").replace("★", " stars").replace("✓", "").replace("⚠", "")
	for item in _toast_queue:
		if str(item.text) == clean:
			return
	_toast_queue.append({"text": clean, "seconds": seconds})
	if _toast_queue.size() > 8:
		_toast_queue.pop_front()


func message_text(item: Dictionary) -> String:
	var data: Dictionary = item.get("data", {})
	match str(item.kind):
		"text": return str(data.get("text", ""))
		"mission":
			var name_txt := CatalogScript.text("misiones." + str(data.id) + ".titulo", str(data.id))
			return tx("mail_mission", {"name": name_txt})
		"resource": return tr("visual.resource_notice").format({"resource":tr("hud."+str(data.get("resource","agua"))+".nombre")})
		"welcome": return tx("welcome", {"name": _player_name()})
		_: return tx(str(item.kind))


func _maybe_show_reward() -> void:
	if not _session_ready or _landing_active or home_paused or is_instance_valid(_modal_layer):
		return
	if not session.pending_rewards.is_empty():
		_open_reward(session.pending_rewards[0])
	elif session.finished:
		_open_victory()


func _open_reward(reward: Dictionary) -> void:
	var panel := _open_modal("reward", tx("reward_title"), Vector2(560, 440))
	var m_title := CatalogScript.text("misiones." + str(reward.id) + ".titulo", str(reward.id))
	UI.label(panel, m_title, Rect2(28, 72, 504, 34), 20, UI.WHITE, true)

	var star_box := UI.panel(panel, Rect2(28, 114, 150, 38), Color("#193750"), 12)
	UI.label(star_box, "+%d ★" % int(reward.stars), Rect2(14, 7, 122, 24), 16, UI.GOLD, true)

	var y := 166.0
	var supplies: Dictionary = reward.get("supplies", {})
	if not supplies.is_empty():
		var sup_parts: Array[String] = []
		for sid in supplies:
			sup_parts.append("%s ×%d" % [module_name(str(sid)), int(supplies[sid])])
		var sup_box := UI.panel(panel, Rect2(28, y, 504, 62), Color("#132740"), 12)
		UI.label(sup_box, tx("supplies"), Rect2(14, 6, 220, 18), 12, UI.CYAN, true)
		var sup_lbl := UI.label(sup_box, ", ".join(sup_parts), Rect2(14, 24, 476, 32), 14, UI.WHITE, false)
		sup_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		y += 72.0

	var science_title := ""
	for mission in session.mm.obtener_todas_las_misiones():
		if str(mission.id) == str(reward.id):
			science_title = str(session.mm.obtener_mision_localizada(mission).get("carta_nasa", {}).get("titulo", ""))
	if not science_title.is_empty():
		var sci_box := UI.panel(panel, Rect2(28, y, 504, 62), Color("#132740"), 12)
		UI.label(sci_box, gx("letter"), Rect2(14, 6, 300, 18), 12, UI.GOLD, true)
		var sci_lbl := UI.label(sci_box, science_title, Rect2(14, 24, 476, 32), 14, UI.WHITE, false)
		sci_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	UI.button(panel, tx("view_card"), Rect2(28, 356, 242, 48), func():
		session.acknowledge_reward(str(reward.id))
		_close_modal()
		_open_section_drawer("science")
	)
	UI.button(panel, tx("continue"), Rect2(290, 356, 242, 48), func():
		session.acknowledge_reward(str(reward.id))
		_close_modal()
	, true)
	(panel.get_child(1) as Button).pressed.connect(func(): session.acknowledge_reward(str(reward.id)))
	_pop_in(panel)
	_speak(tx("reward_title") + " " + m_title + ". " + science_title)


func _open_victory() -> void:
	var panel := _open_modal("victory", tx("victory"), Vector2(820, 480))
	(panel.get_child(1) as Button).hide()
	UI.label(panel, tx("victory_text", {"n": session.mm.obtener_todas_las_misiones().size()}), Rect2(36, 92, 748, 96), 26, UI.WHITE, true)
	var summary := "%s: %d     %s: %d\n%s: %d" % [tx("completed"), session.sm.obtener_misiones_completadas().size(), tx("learn"), _science_cards().size(), tx("stars"), session.sm.obtener_estrellas_totales()]
	UI.label(panel, summary, Rect2(36, 210, 748, 86), 21, UI.CYAN)
	UI.button(panel, tx("view_card"), Rect2(28, 344, 240, 50), func():
		_close_modal()
		_open_section_drawer("science")
	)
	UI.button(panel, tx("home"), Rect2(286, 344, 240, 50), _return_home)
	UI.button(panel, tx("new_game"), Rect2(544, 344, 248, 50), _confirm_new_game, true)
	_pop_in(panel)


func _confirm_new_game() -> void:
	var panel := _open_modal("new_game", tx("new_game"), Vector2(680, 330))
	UI.label(panel, tx("confirm_restart"), Rect2(28, 88, 624, 100), 22, UI.WHITE)
	UI.button(panel, tx("cancel"), Rect2(28, 224, 300, 48), _open_victory)
	UI.button(panel, tx("new_game"), Rect2(348, 224, 304, 48), func():
		var mode := str(_gs().modo_juego)
		session.reset_run(mode)
		session.save_run()
		_bridge._zero_handled = false
		_close_modal()
		_sync_all_from_state()
		_hud.set_mode(mode)
	, true)


func _on_recovery_requested(policy: String, _profile: Dictionary) -> void:
	if _recovering or not _session_ready or session.loading or _modal_kind == "recovery" or session.finished:
		return
	var panel := _open_modal("recovery", tx("failed"), Vector2(740, 420))
	(panel.get_child(1) as Button).hide()
	UI.label(panel, tx("failure_reason"), Rect2(28, 84, 684, 48), 22, UI.GOLD, true)
	UI.label(panel, tx("engineer_recovery" if policy == "restart" else "cadet_recovery"), Rect2(28, 148, 684, 116), 20, UI.WHITE)
	UI.button(panel, tx("restart" if policy == "restart" else "recover"), Rect2(28, 304, 420, 52), func():
		_recover_with_fade()
	, true)
	UI.button(panel, tx("home"), Rect2(468, 304, 244, 52), _return_home)

	_pop_in(panel)
	_speak(tx("failed")+". "+tx("failure_reason")+". "+tx("engineer_recovery" if policy == "restart" else "cadet_recovery"))

func _return_home() -> void:
	set_paused(true)
	if session != null and not session.save_run():
		home_paused = false
		var error_panel := _open_modal("save_error", tx("hud_settings"), Vector2(680, 340))
		UI.label(error_panel, tx("save_error"), Rect2(28, 86, 624, 116), 20, UI.WHITE)
		UI.button(error_panel, tx("back"), Rect2(28, 238, 300, 48), _close_modal)
		UI.button(error_panel, tx("home"), Rect2(348, 238, 304, 48), _return_home, true)
		return
	_close_modal()
	_voice.stop()
	salir_al_menu.emit()


func _open_audio_modal() -> void:
	_open_section_drawer("settings:audio")


func _save_preferences() -> void:
	var gs := _gs()
	gs.voz_activa = not _voice.muted
	gs.preferencias.merge({"nickname": _player_name(), "mode": gs.modo_juego, "language": gs.idioma, "voice_enabled": not _voice.muted, "voice_volume": _voice.volume, "voice_rate": _voice.rate, "voices": _voice.selected_voices.duplicate(true)}, true)
	if session != null:
		session.save_run()


func _set_language(language: String) -> void:
	var sm: Node = _gs().obtener_save_manager()
	if sm.has_method("guardar_idioma"): sm.guardar_idioma(language)
	_gs().idioma = language
	TranslationServer.set_locale(language)
	await get_tree().process_frame
	_voice.stop()
	_save_preferences()
	_hud.refresh()
	_refresh_active_mission_panel()
	_open_section_drawer("settings:language")


func _toggle_language() -> void:
	_set_language("en" if _gs().idioma == "es" else "es")


func _unhandled_input(event: InputEvent) -> void:
	if _landing_active or (home_paused and not is_instance_valid(_modal_layer) and not (is_instance_valid(_drawer) and _drawer.visible)):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _modal_kind in ["recovery", "victory"]:
				return
			if is_instance_valid(_modal_layer):
				if _modal_kind == "reward" and session != null and not session.pending_rewards.is_empty():
					session.acknowledge_reward(str(session.pending_rewards[0].id))
				_close_modal()
			elif is_instance_valid(_drawer) and _drawer.visible:
				_close_drawer()
			elif placement_system.is_placing():
				placement_system.cancel_placement()
			elif not _callout_mode.is_empty():
				_callout_mode = ""
				_sync_dock_highlight()
			else:
				_open_section_menu()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_C and not is_instance_valid(_modal_layer) and not (is_instance_valid(_drawer) and _drawer.blocks_world()):
			_toggle_camera_target()
			get_viewport().set_input_as_handled()


func capture_world() -> Dictionary:
	var placed: Array = []
	for child in estructuras_colocadas.get_children():
		if child.is_queued_for_deletion():
			continue
		placed.append({"id": str(child.get_meta(&"piece_id", &"")), "position": [child.position.x, child.position.y, child.position.z], "rotation": [child.rotation.x, child.rotation.y, child.rotation.z]})
	var destination: Vector3 = click_to_move.get("_destino")
	return {"placed": placed, "robot": [robot.position.x, robot.position.y, robot.position.z], "rotation": [robot.rotation.x, robot.rotation.y, robot.rotation.z], "moving": bool(click_to_move.get("_moviendo")), "destination": [destination.x, destination.y, destination.z], "expedition": _expedition_pending, "expedition_time": _expedition_timer, "storm_time": _storm_remaining, "storm_count": _storm_count, "storm_profile": _storm_profile.duplicate(), "next_storm": _next_storm_profile.duplicate(), "warning": _storm_warning_emitted, "overload": _gen_overload_timer, "cooldown": _gen_overload_cooldown, "action": _action, "action_remaining": _action_remaining, "action_total": _action_total, "ice": ice.capture() if ice != null else {}, "trip_collected": _trip_collected, "trip_ice": _trip_ice, "trip_alerted": _trip_alerted}


func restore_world(data: Dictionary) -> void:
	if placement_system.is_placing():
		placement_system.cancel_placement()
	for child in estructuras_colocadas.get_children():
		child.free()
	var catalog: Dictionary = placement_system.piece_catalog
	for item in data.get("placed", []):
		var id := str(item.get("id", ""))
		if not catalog.has(StringName(id)):
			continue
		var piece: Node3D = catalog[StringName(id)].instantiate()
		piece.set_meta(&"piece_id", StringName(id))
		estructuras_colocadas.add_child(piece)
		piece.position = array_vector(item.get("position", [0, 0, 0]))
		piece.rotation = array_vector(item.get("rotation", [0, 0, 0]))
	robot.position = array_vector(data.get("robot", [-3.6, 0, 9.6]))
	robot.rotation = array_vector(data.get("rotation", [0, -2.618, 0]))
	if robot is CharacterBody3D:
		robot.velocity = Vector3.ZERO
	click_to_move.set("_moviendo", bool(data.get("moving", false)))
	click_to_move.set("_destino", array_vector(data.get("destination", [-3.6, 0, 9.6])))
	click_to_move.set("_tiempo_atascado", 0.0)
	_expedition_pending = bool(data.get("expedition", false))
	_expedition_timer = float(data.get("expedition_time", 0))
	_storm_remaining = float(data.get("storm_time", 0))
	_storm_count = int(data.get("storm_count", 0))
	_storm_profile = data.get("storm_profile", SPE_STORM_PROFILES[0]).duplicate()
	_next_storm_profile = data.get("next_storm", SPE_STORM_PROFILES[0]).duplicate()
	_storm_warning_emitted = bool(data.get("warning", false))
	_gen_overload_timer = float(data.get("overload", 0))
	_gen_overload_cooldown = float(data.get("cooldown", 0))
	_trip_collected = bool(data.get("trip_collected", false))
	_trip_ice = int(data.get("trip_ice", 0))
	_trip_alerted = bool(data.get("trip_alerted", false))
	_action = str(data.get("action", ""))
	_action_remaining = float(data.get("action_remaining", 0))
	_action_total = float(data.get("action_total", 1))
	if ice != null:
		ice.restore(data.get("ice", {}))
	if _action == "collect_drop":
		_action = ""
	_bind_stations()
	_restore_pending_drops()
	_expedition_pending = false
	_pending_build_id = ""
	_callout_mode = ""
	_bridge._zero_handled = false
	_sync_all_from_state()


func array_vector(value: Array) -> Vector3:
	if value.size() != 3:
		return Vector3.ZERO
	return Vector3(float(value[0]), float(value[1]), float(value[2]))


func _upgrade_reason(id: String, result: Dictionary) -> String:
	var reason := str(result.get("motivo", ""))
	if reason.begins_with("falta_requisito:"):
		var req := reason.get_slice(":", 1)
		return tx("required", {"name": CatalogScript.text("upgrades." + req + ".nombre", req)})
	if reason == "estrellas_insuficientes":
		var item: Dictionary = _gs().obtener_tech_tree().obtener_mejora(id)
		return tx("need_stars", {"n": maxi(0, int(item.get("costo", 0)) - _gs().estrellas)})
	return tr("tree.owned") if reason == "ya_comprada" else _msg("Esta mejora no está disponible.", "This upgrade is unavailable.")


func _build_progression_dict() -> Dictionary:
	var data := super._build_progression_dict()
	var mm: Node = _gs().obtener_mission_manager()
	var counts := _visible_mission_counts(mm.obtener_mision_activa())
	data["objective_done"] = int(counts.done)
	data["objective_total"] = int(counts.total)
	return data


func _on_m14_superstorm_requested(_id_mision: String) -> void:
	var gs := _gs()
	if gs == null:
		return
	var mm: Node = gs.obtener_mission_manager()
	if mm != null and mm.obtener_triggers_cumplidos().has("escudo_llego_cero"):
		_m14_superstorm_armed = false
		return
	_m14_superstorm_armed = true
	_gen_overload_cooldown = 0.0
	if not bool(gs.nube_activa) and not bool(gs.alerta_nube):
		gs.tiempo_para_nube = minf(float(gs.tiempo_para_nube), _storm_warning_seconds() + 6.0)
		_storm_warning_emitted = false


func _on_mission_activated(mision: Dictionary) -> void:
	var id := str(mision.get("id", ""))
	var gs := _gs()
	if gs == null or id.is_empty():
		return
	if id == "mision_11" and float(gs.agua) > 10.0 and gs.en_partida and (session == null or not session.loading):
		gs.fijar_recurso("agua", 9.0)
		var text := tx("m11_leak")
		if session != null:
			session.add_message("m11_leak", "text", {"text": text})
		_queue_alert(text, 4.5, true)
	elif id == "mision_14":
		_on_m14_superstorm_requested(id)
	else:
		_m14_superstorm_armed = false


func _tick_fallback_simulation(delta: float) -> void:
	super._tick_fallback_simulation(delta)
	_gs().generador_pausado = _gen_overload_timer > 0
	_gs().robot_en_domo = _robot_distance_to_dome() <= _dome_recharge_radius()
	var environment := mundo.get_node_or_null("Ambiente")
	if environment != null and environment.has_method("set_solar_time"):
		environment.set_solar_time(_gs().tiempo_juego)


func _on_robot_arrived(destination: Vector3) -> void:
	super._on_robot_arrived(destination)
	if ice != null:
		ice.arrived(destination)
	if not _pending_pickup_drop_id.is_empty():
		var pending_node := _find_drop_node(_pending_pickup_drop_id)
		if is_instance_valid(pending_node):
			var dist := Vector2(robot.global_position.x - pending_node.global_position.x, robot.global_position.z - pending_node.global_position.z).length()
			if dist <= 4.2:
				var id := _pending_pickup_drop_id
				_pending_pickup_drop_id = ""
				_begin_drop_collection(id)
	if _session_ready and not session.loading:
		session.save_run()


func _mission_art(id: String) -> String:
	var number := int(id.get_slice("_", 1))
	var arts := ["solar", "ice_map", "processor", "oxygen", "solar", "solar", "solar", "repair", "repair", "ice_map", "oxygen", "repair", "processor", "repair", "garden", "garden"]
	return str(arts[clampi(number - 1, 0, 15)])


func _processor_capacity() -> int:
	var count := 0
	for child in estructuras_colocadas.get_children():
		if str(child.get_meta(&"piece_id", &"")) == "procesador_hielo":
			count += 1
	return 3 * maxi(1, count)


func _queue_alert(text: String, seconds: float, urgent := false) -> void:
	for item in _toast_queue:
		if str(item.text) == text:
			return
	var entry := {"text": text, "seconds": seconds, "voice": true}
	if urgent:
		_toast_queue.push_front(entry)
	else:
		_toast_queue.append(entry)


func _pop_in(panel: Control) -> void:
	panel.pivot_offset = panel.size / 2
	panel.scale = Vector2(0.96, 0.96)
	panel.modulate.a = 0
	var animation := create_tween().set_parallel(true)
	animation.tween_property(panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animation.tween_property(panel, "modulate:a", 1.0, 0.18)


func check_recovery() -> void:
	if not _session_ready:
		return
	_bridge._read_snapshot()
	_bridge._zero_handled = false
	_bridge._check_failure()


func _refresh_mail_badge() -> void:
	if session == null or not is_instance_valid(_hud):
		return
	_hud.set_unread_count(session.unread_count())


func _refresh_audio_voices() -> void:
	if not is_instance_valid(_drawer) or not is_instance_valid(_drawer._voice_choice) or not is_instance_valid(_drawer._audio_status):
		return
	var language := str(_gs().idioma)
	var voices: Array = _voice.voices_for(language)
	var signature := str(voices) + language
	if signature != _audio_voice_signature:
		_audio_voice_signature = signature
		_drawer._voice_choice.clear()
		_drawer._voice_choice.add_item("Sabina" if language == "es" else "Zira")
		_drawer._voice_choice.set_item_metadata(0, "")
		for voice in voices:
			_drawer._voice_choice.add_item(str(voice.name))
			_drawer._voice_choice.set_item_metadata(_drawer._voice_choice.item_count - 1, str(voice.id))
			if str(_voice.selected_voices.get(language, "")) == str(voice.id):
				_drawer._voice_choice.select(_drawer._voice_choice.item_count - 1)
	_drawer._audio_status.text = tr("v2.audio_muted") if _voice.muted else (tx("voice_missing") if voices.is_empty() else tr("v2.audio_ready"))


func _run_rest() -> void:
	var gs := _gs()
	if gs.energia_robot >= 99.5 and _robot_distance_to_dome() <= _dome_recharge_radius():
		gs.notificar_evento_mision("robot_dentro_domo", {})
		gs.notificar_evento_mision("recarga_bateria_activa", {})
		gs.notificar_evento_mision("energia_alcanzada_90", {})
	super._run_rest()


func _return_to_dome() -> void:
	_close_drawer()
	_callout_mode = ""
	if ice != null:
		ice.return_home()


func _offer_tour() -> void:
	if session == null or home_paused or _landing_active or _modal_layer != null or session.finished:
		return
	if not session.learned.has("tour"):
		_show_coach("tour")


func _show_coach(id: String) -> void:
	_coach_target = id
	var title := gx("tour_title") if id == "tour" else "Timmy · " + tx(id)
	_open_section_drawer("coach", {
		"title": title,
		"subtitle": title,
		"body": gx(id),
		"confirm_label": gx("try"),
		"coach_id": id,
	})
	_speak(gx(id))


func _bind_stations() -> void:
	var binder := preload("res://interaction/station_bindings.gd")
	for pair in [["Capsula", "repair"], ["TanqueAgua", "water"], ["CraterHielo", "expedition"]]:
		var node := mundo.get_node_or_null(pair[0])
		if node != null:
			binder.bind(node, pair[1])
	var sections := {"panel_solar": "energy", "procesador_hielo": "processing", "generador_oxigeno": "oxygen", "tanque_agua": "water", "jardin": "garden"}
	for piece in estructuras_colocadas.get_children():
		if piece.is_queued_for_deletion():
			continue
		binder.bind(piece, str(sections.get(str(piece.get_meta("piece_id", "")), "construction")))


func _on_station_clicked(section: String, station: Node3D) -> void:
	if section == "supply_drop":
		_collect_supply_drop(station)
		return
	if section in ["energy", "water", "oxygen", "garden"]:
		_open_resource_station(section)
	elif section == "expedition" and ice != null and ice.phase == "idle" and station != null and station.name == "CraterHielo":
		_close_drawer()
		_callout_mode = "crater_prompt"
		_sync_dock_highlight()
	else:
		_on_dock_action(section)


func _clear_supply_drops() -> void:
	if not is_instance_valid(mundo):
		return
	for child in mundo.get_children():
		if child.name.begins_with("SupplyDrop_"):
			child.free()


func _restore_pending_drops() -> void:
	_clear_supply_drops()
	_active_drop_id = ""
	_pending_pickup_drop_id = ""
	if session == null:
		return
	for entry in session.pending_drops:
		if entry is Dictionary:
			_create_drop_node(entry, true)


func _spawn_upgrade_supply_drop(upgrade_id: String) -> void:
	if session == null or not UPGRADE_DROPS.has(upgrade_id):
		return
	if session.spawned_upgrade_drops.has(upgrade_id):
		return
	session.spawned_upgrade_drops.append(upgrade_id)
	var piece_id := str(UPGRADE_DROPS[upgrade_id])
	var factor := _dome_factor()
	var spots: Array[Vector3] = [
		Vector3(10.5, 0.0, -9.5) * factor,
		Vector3(-11.5, 0.0, -9.0) * factor,
		Vector3(13.0, 0.0, 10.0) * factor,
	]
	var chosen: Vector3 = spots[session.pending_drops.size() % spots.size()]
	var entry := {"id": upgrade_id, "upgrade_id": upgrade_id, "piece_id": piece_id, "position": [chosen.x, chosen.y, chosen.z]}
	session.pending_drops.append(entry)
	_create_drop_node(entry, false)
	_show_toast(tx("drop_spawned", {"item": module_name(piece_id)}), 4.2)


func _create_drop_node(entry: Dictionary, immediate_landed: bool) -> Node3D:
	if not is_instance_valid(mundo):
		return null
	var id := str(entry.get("id", ""))
	var piece_id := str(entry.get("piece_id", "panel_solar"))
	var pos := array_vector(entry.get("position", [10.0, 0.0, -9.0]))
	var node := SupplyDropScript.new()
	node.name = "SupplyDrop_" + id
	mundo.add_child(node)
	node.start_drop(pos, id, piece_id, "+1 " + module_name(piece_id), immediate_landed)
	return node


func _find_drop_node(drop_id: String) -> Node3D:
	if not is_instance_valid(mundo):
		return null
	return mundo.get_node_or_null("SupplyDrop_" + drop_id) as Node3D


func _collect_supply_drop(station: Node3D) -> void:
	if station == null or session == null:
		return
	var drop_id := str(station.get_meta("drop_id", ""))
	if drop_id.is_empty():
		return
	var dist := Vector2(robot.global_position.x - station.global_position.x, robot.global_position.z - station.global_position.z).length()
	if dist > 3.6 and is_instance_valid(click_to_move) and click_to_move.has_method("ordenar_destino"):
		_pending_pickup_drop_id = drop_id
		click_to_move.call("ordenar_destino", station.global_position)
		_show_toast(tx("drop_collecting"), 2.2)
		return
	_begin_drop_collection(drop_id)


func _begin_drop_collection(drop_id: String) -> void:
	if not _action.is_empty():
		_show_toast(tx("action_busy"))
		return
	_active_drop_id = drop_id
	_begin_action("collect_drop", 0.8)


func _complete_supply_drop_pickup() -> void:
	var drop_id := _active_drop_id
	_active_drop_id = ""
	if session == null or drop_id.is_empty():
		return
	var piece_id := ""
	var remaining: Array = []
	for entry in session.pending_drops:
		if entry is Dictionary and str(entry.get("id", "")) == drop_id:
			piece_id = str(entry.get("piece_id", ""))
		else:
			remaining.append(entry)
	session.pending_drops = remaining
	var node := _find_drop_node(drop_id)
	if is_instance_valid(node):
		node.queue_free()
	if not piece_id.is_empty():
		session.inventory[piece_id] = int(session.inventory.get(piece_id, 0)) + 1
		_sync_all_from_state()
		_show_toast(tx("drop_collected", {"count": 1, "module": module_name(piece_id)}), 3.5)
	if _session_ready and not session.loading:
		session.save_run()


func _open_resource_station(section: String) -> void:
	var ids := {"energy": "energia", "water": "agua", "oxygen": "oxigeno", "garden": "oxigeno", "shield": "escudo", "robot": "energia_robot"}
	var id: String = str(ids.get(section, "energia"))
	var textures := {"energy": "solar", "water": "processor", "oxygen": "oxygen", "garden": "garden", "shield": "repair", "robot": "solar"}
	var ctas := {"energy": ["res_view_upgrades", "upgrades"], "water": ["processing", "processing"], "oxygen": ["res_view_upgrades", "upgrades"], "garden": ["res_view_upgrades", "upgrades"], "shield": ["repair", "repair"], "robot": ["rest", "rest"]}
	var gs := _gs()
	var pct := roundi(clampf(float(gs.valor_de(id)) / maxf(float(gs.maximo_de(id)), 1.0), 0.0, 1.0) * 100.0)
	var color_idx := GameHudScript.IDS.find(id)
	var color: Color = GameHudScript.COLORS[color_idx] if color_idx >= 0 else UI.GOLD
	var cta: Array = ctas.get(section, ["res_view_upgrades", "upgrades"])
	var cta_target: String = str(cta[1])
	var res_title := tr("hud." + id + ".nombre")
	if id == "oxigeno":
		res_title = res_title.replace(" (4)", "")
	_open_section_drawer("resource", {
		"title": res_title,
		"icon": "robot_battery" if id == "energia_robot" else id,
		"tint": color,
		"color": color,
		"percent": pct,
		"help": tr("hud." + id + ".help"),
		"texture_path": "res://assets/ui/activities/" + str(textures.get(section, "solar")) + "-v1.png",
		"cta_label": tx(str(cta[0])),
		"cta_target": cta_target,
	})


func _on_resource_pressed(id: String) -> void:
	var map := {"energia": "energy", "agua": "water", "oxigeno": "oxygen", "escudo": "shield", "energia_robot": "robot"}
	_open_resource_station(str(map.get(id, "energy")))


func _on_ice_changed() -> void:
	if ice == null:
		return
	_refresh_world_callouts()
	_sync_dock_highlight()
	if is_instance_valid(_drawer) and _drawer.visible and _drawer.kind == "expedition":
		_open_section_drawer("expedition")
	if session != null and not session.loading:
		session.save_run()


func _mission_module(id: String) -> String:
	var art := _mission_art(id)
	return {"solar": "panel_solar", "processor": "procesador_hielo", "oxygen": "generador_oxigeno", "garden": "jardin", "repair": "panel_solar", "ice_map": "procesador_hielo"}.get(art, "panel_solar")


func _open_upgrade_receipt(id: String) -> void:
	var item: Dictionary = session.gs.obtener_tech_tree().obtener_mejora(id)
	var title := CatalogScript.text("upgrades." + id + ".nombre", id)
	var effect := CatalogScript.text("upgrades." + id + ".efecto", "")
	var after: int = int(session.sm.obtener_estrellas_disponibles())
	var panel := _open_modal("upgrade_receipt", gx("upgrade_installed"), Vector2(580, 380))
	UI.label(panel, title, Rect2(28, 76, 524, 38), 22, UI.GOLD, true)
	UI.label(panel, gx("star_receipt", {"before": after + int(item.get("costo", 0)), "after": after}), Rect2(28, 118, 524, 28), 16, UI.CYAN, true)
	UI.label(panel, effect, Rect2(28, 162, 524, 110), 17, UI.WHITE)
	UI.button(panel, gx("back_tree"), Rect2(28, 294, 252, 48), func():
		_close_modal()
		_open_section_drawer("upgrades")
	, true)
	UI.button(panel, tx("view_card"), Rect2(300, 294, 252, 48), func():
		_close_modal()
		_open_section_drawer("science")
	)
	_pop_in(panel)
	_speak(gx("upgrade_installed") + ". " + title + ". " + effect)


func _on_robot_started_walk(destination: Vector3) -> void:
	super._on_robot_started_walk(destination)
	if ice != null and not ice.route_driven and ice.phase in ["going", "mining", "returning"]:
		ice.phase = "blocked"
		ice._route.clear()
		ice._request_route = false
		ice.changed.emit()

func _recover_with_fade() -> void:
	if _recovering: return
	_recovering = true
	_voice.stop()
	var previous_pause := home_paused
	home_paused = true
	_apply_pause()
	var fade := ColorRect.new()
	fade.size = Vector2(1280,720)
	fade.color = Color.BLACK
	fade.modulate.a = 0.0
	fade.z_index = 200
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_root.add_child(fade)
	var tween := create_tween()
	tween.tween_property(fade,"modulate:a",1.0,0.28)
	await tween.finished
	session.recover()
	_reset_storm_ui_state()
	_bridge._zero_handled = false
	_close_modal()
	_alerted.clear()
	_toast_queue.clear()
	_sync_all_from_state()
	_apply_pause()
	tween = create_tween()
	tween.tween_property(fade,"modulate:a",0.0,0.32)
	await tween.finished
	fade.queue_free()
	home_paused = previous_pause
	_recovering = false
	_apply_pause()
	_maybe_show_reward()

func _input(_event: InputEvent) -> void:
	if _recovering: get_viewport().set_input_as_handled()

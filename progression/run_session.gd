extends Node
## A single run, shared by both modes. World and mission snapshots travel together.
signal reward_ready(reward: Dictionary)
signal checkpoint_saved(success: bool)
signal campaign_finished()
const STATE_FIELDS := ["generador_pausado", "robot_en_domo", "energia", "energia_robot", "hielo", "agua", "agua_max", "oxigeno", "escudo", "modo_juego", "tiempo_juego", "es_dia", "tiempo_ciclo_solar", "alerta_nube", "tiempo_para_nube", "nube_activa", "en_viaje_hielo", "descansando_en_domo", "herramienta_nivel", "paneles_instalados", "procesador_instalado", "generador_instalado", "jardin_instalado", "bateria_instalada"]
var game: Node
var gs: Node
var sm: Node
var mm: Node
var learned: Dictionary = {}
var read_cards: Dictionary = {}
var inventory: Dictionary = {}
var delivered: Array = []
var messages: Array = []
var pending_rewards: Array = []
var pending_drops: Array = []
var spawned_upgrade_drops: Array = []
var checkpoint: Dictionary = {}
var finished = false
var loading = false
var restored = false
var _supplies: Dictionary = {}
var _autosave = 0.0

func setup(host: Node) -> void:
	game = host
	gs = game._gs()
	sm = gs.obtener_save_manager()
	mm = gs.obtener_mission_manager()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/missions/supplies.json"))
	if parsed is Dictionary: _supplies = parsed
	gs.mision_completada.connect(_on_mission)

func begin() -> void:
	loading = true
	var stored: Dictionary = sm.obtener_datos_completos().get("expedicion", {})
	var current: Variant = stored.get("current", {})
	var saved_checkpoint: Variant = stored.get("checkpoint", {})
	var had_saved_session_data := stored.has("current") or stored.has("checkpoint")
	var session_restored := false
	if current is Dictionary and _validar_restauracion(current):
		session_restored = restore(current)
		if session_restored:
			checkpoint = saved_checkpoint.duplicate(true) if saved_checkpoint is Dictionary and _validar_restauracion(saved_checkpoint) else current.duplicate(true)
	if not session_restored and saved_checkpoint is Dictionary and _validar_restauracion(saved_checkpoint):
		session_restored = restore(saved_checkpoint)
		if session_restored:
			checkpoint = saved_checkpoint.duplicate(true)
			_announce_recovery("Hubo un problema con el último guardado. Recuperamos el último punto seguro.", "The latest save had a problem. We restored the last safe checkpoint.")
	if not session_restored and had_saved_session_data:
		var backup_data: Dictionary = sm.leer_respaldo()
		var backup_expedition: Variant = backup_data.get("expedicion", {})
		if backup_expedition is Dictionary:
			var backup_current: Variant = backup_expedition.get("current", {})
			var backup_checkpoint: Variant = backup_expedition.get("checkpoint", {})
			var backup_snapshot: Variant = backup_current
			if not (backup_current is Dictionary and _validar_restauracion(backup_current)):
				backup_snapshot = backup_checkpoint
			if backup_snapshot is Dictionary and _validar_restauracion(backup_snapshot):
				session_restored = restore(backup_snapshot)
				if session_restored:
					checkpoint = backup_checkpoint.duplicate(true) if backup_checkpoint is Dictionary and _validar_restauracion(backup_checkpoint) else backup_snapshot.duplicate(true)
					_announce_recovery("El último guardado no era compatible. Cargamos una copia anterior segura.", "The latest save was incompatible. We loaded a previous safe copy.")
	restored = session_restored
	if not session_restored:
		inventory = _supplies.get("starter", {}).duplicate(true)
		for id in sm.obtener_misiones_completadas(): _deliver(id)
		add_message("welcome", "welcome", {})
		finished = all_missions_complete()
		checkpoint = capture()
	loading = false
	save_run()

func _announce_recovery(message_es: String, message_en: String) -> void:
	var notice := message_es if TranslationServer.get_locale().begins_with("es") else message_en
	var notice_id := "save_recovered:" + str(Time.get_ticks_msec())
	push_warning("RunSession: " + notice)
	add_message(notice_id, "text", {"text": notice})
	if is_instance_valid(game) and game.has_method("_show_toast"):
		game.call_deferred("_show_toast", notice, 5.0)

func _process(delta: float) -> void:
	if gs == null or not gs.en_partida or loading or finished: return
	_autosave += delta
	if _autosave >= 10.0:
		_autosave = 0
		save_run()

func _deliver(id: String) -> Dictionary:
	if delivered.has(id): return {}
	delivered.append(id)
	var items: Dictionary = _supplies.get("missions", {}).get(id, {}).duplicate(true)
	for key in items: inventory[key] = int(inventory.get(key, 0)) + int(items[key])
	return items

func _on_mission(id: String, stars: int, _card: Dictionary) -> void:
	if loading or delivered.has(id): return
	var items = _deliver(id)
	var reward = {"id": id, "stars": stars, "supplies": items}
	pending_rewards.append(reward)
	add_message("mission:" + id, "mission", reward)
	# MissionManager activates the next mission after emitting completion.
	call_deferred("_finish_mission_transaction")

func _finish_mission_transaction() -> void:
	if loading: return
	if str(gs.modo_juego) == "cadete":
		checkpoint = capture()
		checkpoint_saved.emit(save_run())
	else:
		save_run()
	if not finished and all_missions_complete():
		finished = true
		save_run()
		campaign_finished.emit()
	if not pending_rewards.is_empty(): reward_ready.emit(pending_rewards[0])

func all_missions_complete() -> bool:
	var all: Array = mm.obtener_todas_las_misiones()
	if all.is_empty(): return false
	for mission in all:
		if not mission is Dictionary: return false
		var mission_id := str(mission.get("id", ""))
		if mission_id.is_empty() or not sm.esta_mision_completada(mission_id): return false
	return true

func acknowledge_reward(id: String) -> void:
	pending_rewards = pending_rewards.filter(func(r): return str(r.id) != id)
	# A restored checkpoint must not replay a reward already acknowledged.
	if not checkpoint.is_empty(): checkpoint["pending_rewards"] = pending_rewards.duplicate(true)
	save_run()

func add_message(id: String, kind: String, data: Dictionary) -> void:
	for item in messages:
		if str(item.id) == id: return
	messages.push_front({"id": id, "kind": kind, "data": data.duplicate(true), "read": false, "day_seconds": gs.tiempo_juego})
	if messages.size() > 60: messages.resize(60)

func unread_count() -> int:
	var total = 0
	for item in messages:
		if not bool(item.get("read", false)): total += 1
	return total

func mark_read(id: String) -> void:
	for item in messages:
		if str(item.id) == id: item.read = true
	save_run()

func capture() -> Dictionary:
	var state = {}
	for field in STATE_FIELDS: state[field] = gs.get(field)
	var legacy: Dictionary = sm.obtener_datos_completos()
	legacy.erase("expedicion")
	legacy.erase("perfil")
	return {"learned": learned.duplicate(true), "read_cards": read_cards.duplicate(true), "state": state, "missions": mm.capturar_estado(), "legacy": legacy, "world": game.capture_world(), "inventory": inventory.duplicate(true), "delivered": delivered.duplicate(), "messages": messages.duplicate(true), "pending_rewards": pending_rewards.duplicate(true), "pending_drops": pending_drops.duplicate(true), "spawned_upgrade_drops": spawned_upgrade_drops.duplicate(), "finished": finished}

func save_run() -> bool:
	if loading: return false
	return sm.guardar_expedicion({"current": capture(), "checkpoint": checkpoint.duplicate(true)}, gs.preferencias)

func restore(snapshot: Dictionary) -> bool:
	if not _validar_restauracion(snapshot): return false
	loading = true
	gs.en_partida = false
	gs.reiniciar()
	sm.restaurar_progreso(snapshot.get("legacy", {}))
	var state: Dictionary = snapshot.get("state", {})
	for field in STATE_FIELDS:
		if state.has(field): gs.set(field, state[field])
	var mission_state: Dictionary = snapshot.get("missions", {}).duplicate(true)
	if not mission_state.has("mode"):
		mission_state["mode"] = str(state.get("modo_juego", gs.modo_juego))
	mm.restaurar_estado(mission_state)
	gs.estrellas = sm.obtener_estrellas_disponibles()
	learned = snapshot.get("learned",{}).duplicate(true)
	read_cards = snapshot.get("read_cards",{}).duplicate(true)
	inventory = snapshot.get("inventory", {}).duplicate(true)
	delivered = snapshot.get("delivered", []).duplicate()
	messages = snapshot.get("messages", []).duplicate(true)
	pending_rewards = snapshot.get("pending_rewards", []).duplicate(true)
	pending_drops = snapshot.get("pending_drops", []).duplicate(true)
	spawned_upgrade_drops = snapshot.get("spawned_upgrade_drops", []).duplicate()
	finished = bool(snapshot.get("finished", false))
	game.restore_world(snapshot.get("world", {}))
	if not bool(gs.alerta_nube) and not bool(gs.nube_activa) and game != null and game.has_method("_reset_storm_ui_state"):
		game.call("_reset_storm_ui_state")
	loading = false
	gs._emitir_todos_los_recursos(true)
	gs._emitir_energia_robot(true)
	gs.estrellas_actualizadas.emit(gs.estrellas)
	return true

func _validar_restauracion(snapshot: Dictionary) -> bool:
	var state: Variant = snapshot.get("state", null)
	var missions: Variant = snapshot.get("missions", {})
	var world: Variant = snapshot.get("world", {})
	var legacy: Variant = snapshot.get("legacy", {})
	if typeof(state) != TYPE_DICTIONARY or typeof(missions) != TYPE_DICTIONARY \
			or typeof(world) != TYPE_DICTIONARY or typeof(legacy) != TYPE_DICTIONARY:
		return false
	var mode := str(state.get("modo_juego", ""))
	if mode != "cadete" and mode != "ingeniero":
		return false
	for field in STATE_FIELDS:
		if not state.has(field): continue
		var saved_value: Variant = state[field]
		var current_value: Variant = gs.get(field)
		if typeof(current_value) == TYPE_FLOAT:
			if not _numero_snapshot_valido(saved_value): return false
		elif typeof(current_value) == TYPE_INT:
			if not _entero_snapshot_valido(saved_value): return false
		elif typeof(saved_value) != typeof(current_value):
			return false
	if not _validar_estado_misiones(missions, mode): return false
	if not _validar_estado_sesion(snapshot): return false
	return _validar_mundo(world)

func _validar_estado_misiones(missions: Dictionary, mode: String) -> bool:
	if missions.has("mode") and (typeof(missions.mode) != TYPE_STRING or str(missions.mode) != mode):
		return false
	if missions.has("active") and typeof(missions.active) != TYPE_STRING:
		return false
	for key in ["triggers", "events"]:
		if missions.has(key) and typeof(missions[key]) != TYPE_DICTIONARY: return false
	for key in ["night", "garden", "min_energy"]:
		if missions.has(key) and not _numero_snapshot_valido(missions[key]): return false
	for key in ["trips", "storms"]:
		if missions.has(key) and not _entero_snapshot_valido(missions[key]): return false
	return true

func _validar_estado_sesion(snapshot: Dictionary) -> bool:
	for key in ["learned", "read_cards", "inventory"]:
		if typeof(snapshot.get(key, {})) != TYPE_DICTIONARY: return false
	var inventory_data: Dictionary = snapshot.get("inventory", {})
	for amount in inventory_data.values():
		if not _entero_snapshot_valido(amount): return false
	for key in ["delivered", "messages", "pending_rewards", "pending_drops", "spawned_upgrade_drops"]:
		if typeof(snapshot.get(key, [])) != TYPE_ARRAY: return false
	for id in snapshot.get("delivered", []):
		if typeof(id) != TYPE_STRING or str(id).is_empty(): return false
	for message in snapshot.get("messages", []):
		if typeof(message) != TYPE_DICTIONARY or typeof(message.get("data", {})) != TYPE_DICTIONARY:
			return false
		if message.has("day_seconds") and not _numero_snapshot_valido(message.day_seconds): return false
	for reward in snapshot.get("pending_rewards", []):
		if typeof(reward) != TYPE_DICTIONARY or typeof(reward.get("supplies", {})) != TYPE_DICTIONARY:
			return false
		if str(reward.get("id", "")).is_empty() or not _entero_snapshot_valido(reward.get("stars", 0)):
			return false
		for amount in reward.supplies.values():
			if not _entero_snapshot_valido(amount): return false
	if snapshot.has("finished") and typeof(snapshot.finished) != TYPE_BOOL: return false
	return true

func _validar_mundo(world: Dictionary) -> bool:
	var placed: Variant = world.get("placed", [])
	if typeof(placed) != TYPE_ARRAY: return false
	for item in placed:
		if typeof(item) != TYPE_DICTIONARY: return false
		if item.has("position") and not _vector_snapshot_valido(item.position): return false
		if item.has("rotation") and not _vector_snapshot_valido(item.rotation): return false
	for key in ["robot", "rotation", "destination"]:
		if world.has(key) and not _vector_snapshot_valido(world[key]): return false
	for key in ["expedition_time", "storm_time", "overload", "cooldown", "action_remaining", "action_total"]:
		if world.has(key) and not _numero_snapshot_valido(world[key]): return false
	for key in ["storm_profile", "next_storm"]:
		if world.has(key) and typeof(world[key]) != TYPE_DICTIONARY: return false
	if not str(world.get("action", "")).is_empty() and float(world.get("action_total", 1.0)) <= 0.0:
		return false
	var ice_data: Variant = world.get("ice", {})
	if typeof(ice_data) != TYPE_DICTIONARY: return false
	for key in ["discovered", "route"]:
		if ice_data.has(key) and typeof(ice_data[key]) != TYPE_ARRAY: return false
	if ice_data.has("stock") and typeof(ice_data.stock) != TYPE_DICTIONARY: return false
	if ice_data.has("target") and not _vector_snapshot_valido(ice_data.target): return false
	if ice_data.has("trip_tool") and typeof(ice_data.trip_tool) != TYPE_DICTIONARY: return false
	for point in ice_data.get("route", []):
		if not _vector_snapshot_valido(point): return false
	return true

func _vector_snapshot_valido(value: Variant) -> bool:
	if typeof(value) != TYPE_ARRAY or value.size() != 3: return false
	for component in value:
		if not _numero_snapshot_valido(component): return false
	return true

func _numero_snapshot_valido(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))

func _entero_snapshot_valido(value: Variant) -> bool:
	return _numero_snapshot_valido(value) and float(value) >= 0.0 \
		and is_equal_approx(float(value), float(int(value)))

func recover() -> void:
	if str(gs.modo_juego) == "cadete" and _validar_restauracion(checkpoint):
		restore(checkpoint.duplicate(true))
	else:
		reset_run(str(gs.modo_juego))
	gs.alerta_nube = false
	gs.nube_activa = false
	gs.tiempo_para_nube = maxf(float(gs.tiempo_para_nube), 45.0)
	if game != null and game.has_method("_reset_storm_ui_state"):
		game.call("_reset_storm_ui_state")
	gs.en_partida = true
	save_run()

func reset_run(mode: String) -> void:
	loading = true
	sm.reiniciar_legado()
	gs.iniciar_partida(mode)
	mm.restaurar_estado({"active": "mision_01", "mode": mode})
	mm.notificar_evento("partida_iniciada", {"modo": mode})
	inventory = _supplies.get("starter", {}).duplicate(true)
	learned.clear()
	read_cards.clear()
	delivered.clear()
	messages.clear()
	pending_rewards.clear()
	pending_drops.clear()
	spawned_upgrade_drops.clear()
	finished = false
	game.restore_world({})
	loading = false
	checkpoint = capture()

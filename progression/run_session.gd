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
var checkpoint: Dictionary = {}
var finished = false
var loading = false
var restored = false
var _supplies: Dictionary = {}
var _autosave = 0.0

func setup(host: Node) -> void:
	game = host
	gs = get_node("/root/GameState")
	sm = gs.obtener_save_manager()
	mm = gs.obtener_mission_manager()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/missions/supplies.json"))
	if parsed is Dictionary: _supplies = parsed
	gs.mision_completada.connect(_on_mission)

func begin() -> void:
	loading = true
	var stored: Dictionary = sm.obtener_datos_completos().get("expedicion", {})
	if not stored.is_empty() and stored.get("current") is Dictionary and stored.current.has("state"):
		restore(stored.current)
		checkpoint = stored.get("checkpoint", {}).duplicate(true)
		restored = true
	else:
		inventory = _supplies.get("starter", {}).duplicate(true)
		for id in sm.obtener_misiones_completadas(): _deliver(id)
		add_message("welcome", "welcome", {})
		finished = all_missions_complete()
		checkpoint = capture()
	loading = false
	save_run()

func _process(delta: float) -> void:
	if gs == null or not gs.en_partida or loading or finished: return
	_autosave += delta
	if _autosave >= 30.0:
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
		if not sm.esta_mision_completada(str(mission.id)): return false
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
	return {"learned": learned.duplicate(true), "read_cards": read_cards.duplicate(true), "state": state, "missions": mm.capturar_estado(), "legacy": legacy, "world": game.capture_world(), "inventory": inventory.duplicate(true), "delivered": delivered.duplicate(), "messages": messages.duplicate(true), "pending_rewards": pending_rewards.duplicate(true), "finished": finished}

func save_run() -> bool:
	if loading: return false
	return sm.guardar_expedicion({"current": capture(), "checkpoint": checkpoint.duplicate(true)}, gs.preferencias)

func restore(snapshot: Dictionary) -> void:
	loading = true
	gs.en_partida = false
	gs.reiniciar()
	sm.restaurar_progreso(snapshot.get("legacy", {}))
	for field in STATE_FIELDS:
		if snapshot.get("state", {}).has(field): gs.set(field, snapshot.state[field])
	mm.restaurar_estado(snapshot.get("missions", {}))
	gs.estrellas = sm.obtener_estrellas_disponibles()
	learned = snapshot.get("learned",{}).duplicate(true)
	read_cards = snapshot.get("read_cards",{}).duplicate(true)
	inventory = snapshot.get("inventory", {}).duplicate(true)
	delivered = snapshot.get("delivered", []).duplicate()
	messages = snapshot.get("messages", []).duplicate(true)
	pending_rewards = snapshot.get("pending_rewards", []).duplicate(true)
	finished = bool(snapshot.get("finished", false))
	game.restore_world(snapshot.get("world", {}))
	loading = false
	gs._emitir_todos_los_recursos(true)
	gs._emitir_energia_robot(true)
	gs.estrellas_actualizadas.emit(gs.estrellas)

func recover() -> void:
	if str(gs.modo_juego) == "cadete" and not checkpoint.is_empty():
		restore(checkpoint.duplicate(true))
	else:
		reset_run(str(gs.modo_juego))
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
	finished = false
	game.restore_world({})
	loading = false
	checkpoint = capture()

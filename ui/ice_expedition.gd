extends Node
## One explicit, recoverable state machine for all ice zones.
signal changed()
const Planner = preload("res://interaction/route_planner.gd")
const Binder = preload("res://interaction/station_bindings.gd")
const ZONES := [
	{"id":"crater","name":"zone_crater","position":Vector3(-21,0,14),"stock":18},
	{"id":"ridge","name":"zone_ridge","position":Vector3(-22,0,-9),"stock":24},
	{"id":"basin","name":"zone_basin","position":Vector3(19,0,17),"stock":30}]
var game: Node3D
var phase := "idle"
var route_kind := "going"
var selected := "crater"
var discovered: Array = ["crater"]
var stock: Dictionary = {"crater":18,"ridge":24,"basin":30}
var collected := 0
var alerted := false
var route_driven := false
var _route: Array[Vector3] = []
var _target := Vector3.ZERO
var _request_route := false
var _mining := 0.0
var _idle_time := 0.0
var _zones: Dictionary = {}
func setup(host: Node3D) -> void:
	game = host
	_zones["crater"] = game.mundo.get_node("CraterHielo")
	Binder.bind(_zones.crater,"expedition")
func _gs() -> Node: return game.get_node("/root/GameState")
func zone(id: String) -> Dictionary:
	var factor := float(game._dome_factor()) if game != null and game.has_method("_dome_factor") else 1.0
	for item in ZONES:
		if str(item.id) == id:
			var out: Dictionary = item.duplicate(true)
			out["position"] = Vector3(item.position) * factor
			return out
	var fallback: Dictionary = ZONES[0].duplicate(true)
	fallback["position"] = Vector3(ZONES[0].position) * factor
	return fallback
func discover() -> void:
	for item in ZONES:
		if not discovered.has(str(item.id)):
			discovered.append(str(item.id))
			_spawn_zone(str(item.id))
			changed.emit()
			return
func _spawn_zone(id: String) -> void:
	if _zones.has(id): return
	var node = load("res://assets/3d/crater_hielo.tscn").instantiate()
	node.name = "IceZone_"+id
	game.mundo.add_child(node)
	node.position = zone(id).position
	node.scale = Vector3.ONE * 0.72
	Binder.bind(node,"expedition")
	_zones[id] = node
func sync_zone_positions() -> void:
	for id in _zones:
		var node := _zones[id] as Node3D
		if is_instance_valid(node):
			node.position = zone(str(id)).position
func start(id: String) -> bool:
	if phase != "idle":
		game._show_toast(game.gx("trip_busy"))
		return false
	if not discovered.has(id) or int(stock.get(id,0)) <= 0:
		game._show_toast(game.gx("zone_empty"))
		return false
	if _gs().hielo >= 10:
		game._show_toast(game.gx("cargo_full"))
		return false
	if _gs().energia_robot < 15:
		game._show_toast(game.tx("low_robot"))
		return false
	selected = id
	collected = 0
	alerted = false
	_gs().descansando_en_domo = false
	_gs().en_viaje_hielo = true
	_gs().notificar_evento_mision("viaje_hielo_iniciado",{})
	var center: Vector3 = zone(id).position
	var approach: Vector3 = game.robot.global_position-center
	approach.y = 0
	if approach.length() < 0.01: approach = Vector3.BACK
	_target = center+approach.normalized()*(4.7 if id == "crater" else 3.7)
	phase = "going"
	route_kind = "going"
	_request_route = true
	changed.emit()
	return true
func _physics_process(_delta: float) -> void:
	if game == null or not _gs().en_partida or not _request_route: return
	_request_route = false
	var excluded: Array[RID] = []
	if game.robot is CollisionObject3D: excluded.append(game.robot.get_rid())
	_route = Planner.plan(game,game.robot.global_position,_target,excluded)
	if _route.is_empty():
		phase = "blocked"
		changed.emit()
	else: _next_waypoint()
func _next_waypoint() -> void:
	if _route.is_empty(): return
	route_driven = true
	game.click_to_move.ordenar_destino(_route.pop_front())
	route_driven = false
	_idle_time = 0
func tick(delta: float) -> void:
	if not _gs().en_partida: return
	if _gs().alerta_nube and phase != "idle": alerted = true
	if phase == "mining":
		_mining -= delta
		if _mining <= 0: _extract()
	elif phase in ["going","returning"] and not _request_route:
		if not bool(game.click_to_move.get("_moviendo")):
			_idle_time += delta
			if _idle_time > 1.5:
				phase = "blocked"
				changed.emit()
func arrived(destination: Vector3) -> void:
	if phase == "idle": return
	var dome_radius := float(game._dome_recharge_radius()) if game != null and game.has_method("_dome_recharge_radius") else float(game.DOME_RECHARGE_RADIUS)
	if game._robot_distance_to_dome() <= dome_radius and phase in ["returning","blocked"]:
		_finish_return()
		return
	if phase not in ["going","returning"]: return
	if Vector2(game.robot.global_position.x-destination.x,game.robot.global_position.z-destination.z).length() > 0.9:
		phase = "blocked"
		_route.clear()
		changed.emit()
		return
	if not _route.is_empty():
		_next_waypoint()
	elif phase == "going":
		phase = "mining"
		_mining = 3.0
		changed.emit()
	else:
		phase = "blocked"
		changed.emit()
func _extract() -> void:
	var gs = _gs()
	var lvl := int(gs.herramienta_nivel)
	var amount: int = game._ice_yield_for_tool(lvl) if game != null and game.has_method("_ice_yield_for_tool") else (8 if lvl >= 3 else (5 if lvl == 2 else 3))
	collected = mini(mini(amount,10-gs.hielo),int(stock.get(selected,0)))
	stock[selected] = int(stock.get(selected,0))-collected
	gs.cambiar_recurso("hielo",collected)
	var cost: float = game._ice_extraction_cost_for_tool(lvl) if game != null and game.has_method("_ice_extraction_cost_for_tool") else (10.0 if lvl >= 3 else 16.0)
	gs.pagar_robot(cost)
	gs.notificar_evento_mision("hielo_extraido_crater",{"hielo_obtenido":collected})
	game._show_toast(game.gx("ice_collected",{"n":collected}))
	return_home()
func return_home() -> void:
	_route.clear()
	_target = game._dome_world_pos()+Vector3(-3,0,6)
	phase = "returning"
	route_kind = "returning"
	_request_route = true
	_gs().en_viaje_hielo = true
	changed.emit()
func retry() -> void:
	if phase != "blocked": return
	phase = route_kind
	_request_route = true
	changed.emit()
func cancel() -> void:
	game.click_to_move.set("_moviendo",false)
	_route.clear()
	_request_route = false
	phase = "idle"
	_gs().en_viaje_hielo = false
	# Carried ice stays in inventory; cancelling never grants a return-to-base objective.
	changed.emit()
func _finish_return() -> void:
	_gs().en_viaje_hielo = false
	phase = "idle"
	_route.clear()
	if collected > 0 or alerted:
		_gs().notificar_evento_mision("viaje_hielo_completado",{"hielo_obtenido":collected,"en_alerta_nube":alerted})
	collected = 0
	alerted = false
	game._show_toast(game.gx("trip_home"))
	changed.emit()
func capture() -> Dictionary:
	var path: Array = []
	for point in _route: path.append([point.x,point.y,point.z])
	return {"route_kind":route_kind,"phase":phase,"selected":selected,"discovered":discovered.duplicate(),"stock":stock.duplicate(),"collected":collected,"alerted":alerted,"target":[_target.x,_target.y,_target.z],"route":path,"request_route":_request_route,"mining":_mining}
func restore(data: Dictionary) -> void:
	route_kind = str(data.get("route_kind","returning" if int(data.get("collected",0)) > 0 else "going"))
	phase = str(data.get("phase","idle"))
	if phase not in ["idle","going","mining","returning","blocked"]: phase = "idle"
	selected = str(data.get("selected","crater"))
	discovered = data.get("discovered",["crater"]).duplicate()
	stock = data.get("stock",{"crater":18,"ridge":24,"basin":30}).duplicate()
	for id in _zones.keys():
		if id != "crater": _zones[id].free(); _zones.erase(id)
	for id in discovered: _spawn_zone(str(id))
	collected = int(data.get("collected",0))
	alerted = bool(data.get("alerted",false))
	_target = game.array_vector(data.get("target",[0,0,0]))
	_route.clear()
	for point in data.get("route",[]): _route.append(game.array_vector(point))
	_request_route = bool(data.get("request_route",false))
	_mining = float(data.get("mining",0))
	if phase in ["going","returning"]: _request_route = true
	_gs().en_viaje_hielo = phase != "idle"
	changed.emit()

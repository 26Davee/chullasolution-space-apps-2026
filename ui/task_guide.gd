extends Node
## Events advance the lesson only after the player performs the expected real action.
const View = preload("res://ui/task_guide_view.gd")
var game: Node
var view: Control
var state: Dictionary = {}
var pending: Array = []
var _speech := ""
var _completion_left := 0.0
func setup(host: Node) -> void:
	game = host
	view = View.new()
	game._ui_root.add_child(view)
	view.repeat_requested.connect(func(): game._speak(_speech))
	view.stop_requested.connect(func():
		if active(): game.session.learned["skip_task:"+str(state.task)] = true
		stop()
	)
func active() -> bool: return bool(state.get("active",false))
func learning_pause() -> bool:
	return active() and str(state.get("stage","")).get_slice("_",1) not in ["return","wait"]
func start(task: String, module := "") -> void:
	state = {"active":true,"task":task,"stage":"","module":module,"ice_before":game._gs().hielo,"water_before":game._gs().agua,"shield_before":game._gs().escudo,"oxygen_before":game._gs().oxigeno,"energy_before":game._gs().energia}
	_choose()
func offer_alert(resource: String) -> void:
	var task = {"agua":"water","oxigeno":"oxygen","energia":"energy","escudo":"repair","energia_robot":"recharge"}.get(resource,"")
	if task.is_empty() or (game.session.learned.has("task:"+task) or game.session.learned.has("skip_task:"+task)): return
	if active() or _completion_left > 0:
		if not pending.has(task): pending.append(task)
	else: start(task)
func stop() -> void:
	state["active"] = false
	pending.clear()
	_completion_left = 0
	view.hide()
	game._voice.stop()
	game.rail.set_attention("")
	game._apply_pause()
	if game.session != null and not game.session.loading: game.session.save_run()
func _choose() -> void:
	var gs = game._gs()
	var task: String = state.get("task","")
	if task == "water" or task == "oxygen" and gs.agua <= 10:
		if not gs.procesador_instalado: _build("procesador_hielo")
		elif gs.hielo <= 0: _begin_ice()
		elif game._robot_distance_to_processing_zone() > game.DOME_RECHARGE_RADIUS: _stage("base_return")
		elif gs.agua_max-gs.agua < 5: _stage("tank_wait")
		elif gs.energia < mini(gs.hielo,game._processor_capacity())*0.5: _wait_for_power(mini(gs.hielo,game._processor_capacity())*0.5)
		else: _stage("process_open")
	elif task == "oxygen":
		if not gs.generador_instalado: _build("generador_oxigeno")
		else: _stage("oxygen_wait")
	elif task == "energy":
		if int(game.session.inventory.get("panel_solar",0)) > 0 and gs.paneles_instalados < game._structure_limit("panel_solar") and gs.energia >= game.module_cost("panel_solar"): _build("panel_solar")
		else: _stage("energy_wait")
	elif task == "build": _build(str(state.get("module","panel_solar")) if not str(state.get("module","")).is_empty() else "panel_solar")
	elif task == "ice": _begin_ice()
	elif task == "process":
		if not gs.procesador_instalado: _build("procesador_hielo")
		elif gs.hielo <= 0: _begin_ice()
		elif game._robot_distance_to_processing_zone() > game.DOME_RECHARGE_RADIUS: _stage("base_return")
		elif gs.energia < mini(gs.hielo,game._processor_capacity())*0.5: _stage("power_wait")
		else: _stage("process_open")
	elif task == "storm":
		if game._robot_distance_to_dome() > game.DOME_RECHARGE_RADIUS: _stage("storm_return")
		elif gs.escudo < 75: _repair_or_power()
		else: _stage("storm_wait")
	elif task == "repair": _repair_or_power()
	elif task == "recharge": _stage("recharge_open")
func _begin_ice() -> void:
	state.ice_before = maxi(0,game._gs().hielo-game.ice.collected) if game.ice.phase != "idle" else game._gs().hielo
	_stage("ice_return" if game.ice.phase != "idle" else "ice_open")
func _repair_or_power() -> void:
	if game._gs().energia < (8 if game._has_upgrade("reparar_barato") else 12): _wait_for_power(8 if game._has_upgrade("reparar_barato") else 12)
	elif game._gs().escudo >= 99.5: _stage("shield_wait")
	else: _stage("repair_open")
func _wait_for_power(amount: float) -> void:
	state.required_energy = amount
	_stage("power_wait")
func build_closed() -> void:
	if active() and str(state.stage).begins_with("build_"): _stage("build_open")
func _build(module: String) -> void:
	state.module = module
	if module == "jardin" and not game._has_upgrade("jardin_lunar"): _stage("garden_unlock")
	elif game._gs().energia < game.module_cost(module): _wait_for_power(game.module_cost(module))
	else: _stage("build_open")
func _stage(stage: String) -> void:
	state.stage = stage
	if stage == "process_open": state.water_before = game._gs().agua
	if stage == "repair_open": state.shield_before = game._gs().escudo
	refresh(true)
	game._apply_pause()
func notify(event: String, data: Dictionary = {}) -> void:
	if not active(): return
	var stage: String = state.stage
	match event:
		"station_open":
			var section: String = str(data.get("section",""))
			if stage == "build_open" and section == "construction": _stage("build_select")
			elif stage == "ice_open" and section == "expedition": _stage("ice_zone")
			elif stage == "process_open" and section == "processing": _stage("process_0")
			elif stage == "repair_open" and section == "repair": _stage("repair_0")
			elif stage == "recharge_open" and section == "rest": _stage("recharge_return" if game._robot_distance_to_dome() > game.DOME_RECHARGE_RADIUS else "recharge_click")
		"module_selected":
			if stage == "build_select" and str(data.get("module","")) == str(state.module): _stage("build_place")
		"module_placed":
			if stage in ["build_select","build_place"] and str(data.get("module","")) == str(state.module):
				if state.task == "build": _finish()
				else: _choose()
		"zone_selected":
			if stage in ["ice_zone","ice_scan"]: _stage("ice_scan")
		"zone_scanned":
			if stage in ["ice_zone","ice_scan"]: _stage("ice_collect")
		"collect_requested":
			if stage == "ice_collect": _stage("ice_return")
		"processing_step":
			var i := int(data.get("index",0))
			if stage == "process_"+str(i): _stage("process_"+str(i+1) if i < 2 else "process_wait")
		"repair_step":
			var i := int(data.get("index",0))
			if stage == "repair_"+str(i): _stage("repair_"+str(i+1) if i < 2 else "repair_wait")
		"recharge_started":
			if stage == "recharge_click": _stage("recharge_wait")
func panel_closed() -> void:
	if not active(): return
	var stage: String = state.stage
	if stage.begins_with("process_") and stage != "process_wait": state.stage = "process_open"
	elif stage.begins_with("repair_") and stage != "repair_wait": state.stage = "repair_open"
	elif stage in ["ice_zone","ice_scan","ice_collect"]: state.stage = "ice_open"
	refresh(false)
func tick(delta: float) -> void:
	if not active():
		if _completion_left > 0:
			_completion_left -= delta
			if _completion_left <= 0:
				view.hide()
		if _completion_left <= 0 and not pending.is_empty() and game._modal_layer == null and not game.home_paused:
			start(str(pending.pop_front()))
		return
	var gs = game._gs()
	var stage: String = state.stage
	if stage == "ice_return" and game.ice.phase == "idle" and gs.hielo <= int(state.get("ice_before",0)):
		_stage("ice_open")
	elif stage == "ice_return" and game.ice.phase == "idle" and game._robot_distance_to_dome() <= game.DOME_RECHARGE_RADIUS and gs.hielo > int(state.get("ice_before",0)):
		if state.task == "ice": _finish()
		else: _choose()
	elif stage == "base_return" and game._robot_distance_to_processing_zone() <= game.DOME_RECHARGE_RADIUS: _choose()
	elif stage == "garden_unlock" and game._has_upgrade("jardin_lunar"): _build("jardin")
	elif stage == "process_wait" and gs.agua > float(state.water_before)+1:
		if state.task == "oxygen": _choose()
		else: _finish()
	elif stage == "repair_wait" and gs.escudo > float(state.shield_before)+1:
		if state.task == "storm": _choose()
		else: _finish()
	elif stage == "shield_wait" and gs.escudo < 99.5: _choose()
	elif stage == "power_wait" and gs.energia >= float(state.get("required_energy",12)): _choose()
	elif stage == "tank_wait" and gs.agua_max-gs.agua >= 5: _choose()
	elif stage == "storm_return" and game._robot_distance_to_dome() <= game.DOME_RECHARGE_RADIUS: _choose()
	elif stage == "storm_wait" and not gs.alerta_nube and not gs.nube_activa: _finish()
	elif stage == "recharge_return" and game._robot_distance_to_dome() <= game.DOME_RECHARGE_RADIUS: _stage("recharge_open")
	elif stage == "recharge_wait" and gs.energia_robot >= 90: _finish()
	elif stage == "oxygen_wait" and gs.oxigeno >= minf(95,float(state.oxygen_before)+5): _finish()
	elif stage == "energy_wait" and gs.energia >= minf(95,float(state.energy_before)+5): _finish()
	layout()
func _finish() -> void:
	state.active = false
	game.session.learned["task:"+str(state.task)] = true
	_speech = tr("task.finish."+str(state.task))
	view.present("Timmy · "+tr("flow.done"),_speech)
	_completion_left = 7
	game._speak(_speech)
	game.rail.set_attention("")
	game._apply_pause()
	game.session.save_run()
func target() -> String:
	var stage: String = state.get("stage","")
	if stage in ["base_return","storm_return"]: return "expedition"
	if stage == "garden_unlock": return "upgrades"
	if stage.begins_with("build_"): return "construction"
	if stage.begins_with("ice_"): return "expedition"
	if stage.begins_with("process_"): return "processing"
	if stage.begins_with("repair_"): return "repair"
	if stage.begins_with("recharge_"): return "rest"
	return ""
func refresh(narrate := false) -> void:
	if not active(): return
	_speech = tr("task.step."+str(state.stage)).format({"module":game.module_name(str(state.get("module","panel_solar")))})
	view.present("Timmy · "+tr("task.title."+str(state.task)),_speech)
	game.rail.set_attention(target())
	if str(state.stage) == "build_select":
		var button = game._build_buttons.get(str(state.module))
		if is_instance_valid(button): button.add_theme_stylebox_override("normal",preload("res://ui/ui_kit.gd").style(Color("#22475d"),Color("#ffc64f"),3))
	layout()
	if narrate and not game.home_paused and not game._landing_active: game._speak(_speech)
func layout() -> void:
	if not view.visible: return
	var compact: bool = game._modal_kind in ["ice_map","action:processing","action:repair","action:rest"] and is_instance_valid(game._modal_layer) and game._modal_content().size.x >= 600
	if compact:
		var panel: Control = game._modal_content()
		view.position = panel.position+Vector2(28,72)
		view.set_compact(true,panel.size.x-56)
	elif game._modal_kind == "action:rest":
		view.position = Vector2(22,416)
		view.set_compact(false,408)
	elif game._modal_layer != null:
		view.hide()
	else:
		view.position = Vector2(22,416)
		view.set_compact(false,408)
func capture() -> Dictionary: return {"state":state.duplicate(true),"pending":pending.duplicate()}
func restore(data: Dictionary) -> void:
	_completion_left = 0
	_speech = ""
	state = data.get("state",{}).duplicate(true)
	pending = data.get("pending",[]).duplicate()
	view.hide()

extends SceneTree
var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	print(("OK " if value else "FAIL ")+message)
	if not value: failures.append(message)
func _initialize() -> void: call_deferred("run")
func frames(n: int = 3) -> void:
	for i in n: await process_frame
func run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var sm = gs.obtener_save_manager()
	sm.save_path = "user://killawasi_lesson_test.json"
	sm.reiniciar_legado()
	gs.aplicar_perfil({"nickname":"Alex","mode":"cadete","language":"en","voice_enabled":false,"tutorial_completed":true})
	gs.iniciar_partida("cadete")
	var game = load("res://scenes/juego.tscn").instantiate()
	root.add_child(game)
	await frames()
	game.set_process(false)
	gs.set_process(false)
	game._voice.muted = true
	game.guide.start("build","panel_solar")
	check(game.guide.state.stage == "build_open" and not gs.en_partida,"Lesson pauses resource drain while explaining")
	game._on_dock_action("construction")
	check(game.guide.state.stage == "build_select","Opening Build advances to selecting the actual module")
	game._start_build("panel_solar")
	check(game.guide.state.stage == "build_place" and not game.session.learned.has("task:build"),"Choosing a module alone does not complete building lesson")
	game.camara.set_process(false)
	game.camara.position = Vector3(8,18,25)
	game.camara.look_at(Vector3(-3,0,8))
	var point = game.camara.unproject_position(Vector3(-8,0,16))
	var motion = InputEventMouseMotion.new()
	motion.position = point
	game.placement_system._unhandled_input(motion)
	await physics_frame
	await physics_frame
	var click = InputEventMouseButton.new()
	click.position = point
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	game.placement_system._unhandled_input(click)
	await frames()
	check(game.session.learned.has("task:build") and gs.paneles_instalados == 1,"Real validated 3D placement finishes building lesson")
	game.robot.position = Vector3(-3,0,6)
	gs.procesador_instalado = true
	gs.hielo = 3
	gs.agua = 5
	game.guide.start("water")
	game._on_dock_action("processing")
	var seq = game._sequence_view
	check(game.guide.state.stage == "process_0" and seq != null,"Water lesson opens real ordered controls")
	seq._process_action(2)
	check(seq._process_step == 0,"Processing cannot skip loading and powering")
	seq._process_action(0)
	check(game.guide.state.stage == "process_1" and gs.agua == 5,"Timmy waits for each actual step without granting water early")
	seq._process_action(1)
	seq._process_action(2)
	check(game._action == "processing" and game.guide.state.stage == "process_wait","Third step starts the real processing action")
	game._process(3)
	game.guide.tick(0)
	check(gs.agua > 5 and game.session.learned.has("task:water"),"Water lesson finishes only after reserve actually rises")
	gs.agua = 5
	game._check_resource_alerts()
	game.session.add_message("alert:agua","resource",{"resource":"agua"})
	game.session.add_message("alert:agua","resource",{"resource":"agua"})
	var water_messages = game.session.messages.filter(func(item): return str(item.id) == "alert:agua")
	check(water_messages.size() == 1,"Repeated resource alerts update one message, not a stack")
	game._open_messages()
	check(game._modal_kind == "messages","New notification center opens")
	game._close_modal()
	gs.agua = 40
	game._check_resource_alerts()
	check(water_messages[0].resolved,"Fixed resource alert moves to resolved history")
	gs.escudo = 40
	game.guide.start("repair")
	game._on_dock_action("repair")
	seq = game._sequence_view
	seq._patch(2)
	check(seq._patched.is_empty(),"Repair cannot jump directly to the final patch")
	for i in 3: seq._patch(i)
	game._process(4)
	game.guide.tick(0)
	check(gs.escudo > 40 and game.session.learned.has("task:repair"),"Ordered repair changes real shield and completes lesson")
	game.guide.stop()
	gs.hielo = 0
	game.ice.surveyed.clear()
	game.guide.start("ice")
	game._on_dock_action("expedition")
	var survey = game._survey_view
	survey._choose_zone(0)
	check(survey._collect_button.disabled,"Real collection is locked before scanning")
	survey._scan_zone()
	check(game.ice.surveyed.has("crater") and game.guide.state.stage == "ice_collect","Scanning finds the real site and advances Timmy")
	survey._collect()
	check(game.ice.phase == "going" and game.guide.state.stage == "ice_return","Collect starts travel; lesson remains unfinished until return")
	game.ice.cancel()
	game.guide.stop()
	# A blocked trip restores its selected zone and retry control.
	game.ice.phase = "blocked"
	game.ice.selected = "ridge"
	game.ice.surveyed.ridge = true
	game._open_ice_map()
	check(game._survey_view.selected == "ridge" and not game._survey_view._collect_button.disabled,"Reopened blocked map preserves the site and offers retry")
	game._close_modal()
	game.ice.cancel()
	game.guide.stop()
	game.session.learned.erase("task:process")
	gs.procesador_instalado = true
	gs.hielo = 2
	game.robot.position = Vector3(-3,0,6)
	game._on_dock_action("processing")
	check(game.guide.active() and game.guide.state.stage == "process_0","First use starts an actual step-by-step lesson automatically")
	game.guide.view.stop_requested.emit()
	game._close_modal()
	game._on_dock_action("processing")
	check(not game.guide.active(),"Closing guidance is respected on later opens; help can restart it")
	game._close_modal()
	game.alerts.clear()
	game.alerts.blocked = false
	game.alerts.publish("saved","Saved","Safe","checkpoint","",false)
	game.alerts._process(0)
	game.alerts.publish("storm","Storm","Return home","escudo","storm",true)
	game.alerts._process(0)
	check(str(game.alerts.current.get("id","")) == "storm","Urgent alert takes priority over routine information")
	game.alerts.clear()
	gs.escudo = 100
	gs.alerta_nube = true
	game.guide.start("storm")
	check(game.guide.state.stage == "storm_wait" and gs.en_partida,"Storm guidance does not request a pointless repair of a full shield")
	gs.alerta_nube = false
	game.guide.tick(0)
	check(game.session.learned.has("task:storm"),"Storm guidance ends when the warning is over")
	game.guide.stop()
	gs.energia = 5
	gs.procesador_instalado = false
	game.guide.start("water")
	check(game.guide.state.stage == "power_wait" and gs.en_partida,"Waiting for construction energy keeps regeneration running")
	gs.energia = 15
	game.guide.tick(0)
	check(game.guide.state.stage == "build_open","Available power resumes the correct missing module")
	game.guide.stop()
	gs.procesador_instalado = true
	gs.agua = gs.agua_max
	gs.hielo = 2
	game.guide.start("water")
	check(game.guide.state.stage == "tank_wait" and gs.en_partida,"A full tank does not demand impossible processing or freeze time")
	game.guide.stop()
	game.ice.phase = "returning"
	game.ice.collected = 3
	gs.hielo = 3
	game.guide.start("ice")
	check(game.guide.state.stage == "ice_return","Help for a trip in progress waits for return instead of asking to scan again")
	game.ice.phase = "idle"
	game.robot.position = Vector3(-3,0,6)
	game.guide.tick(0)
	check(game.session.learned.has("task:ice"),"An existing expedition can finish its guidance on actual arrival")
	game.guide.stop()
	# Confirm restart is available during an unfinished expedition and runs a transition.
	game._open_section_menu()
	var has_restart = false
	for b in game._modal_layer.find_children("*","Button",true,false):
		if b.text == game.tx("restart"): has_restart = true
	check(has_restart,"In-game menu offers restart before victory")
	game._play_run_transition(true,true)
	await create_timer(1.8).timeout
	check(gs.nombre_astronauta == "Alex" and gs.paneles_instalados == 0 and sm.obtener_misiones_completadas().is_empty(),"Animated manual restart clears expedition and preserves profile")
	check(not game._transition_active,"Restart transition releases controls")
	# Cadet restores the full saved snapshot through the animated path.
	game.guide.stop()
	gs.agua = 57
	gs.paneles_instalados = 2
	game.session.checkpoint = game.session.capture()
	gs.agua = 0
	gs.paneles_instalados = 4
	game._on_recovery_requested("checkpoint",{})
	check(game._modal_kind == "recovery" and not gs.en_partida,"Zero resource opens a paused recovery screen")
	game._play_run_transition(false,false)
	await create_timer(1.8).timeout
	check(gs.agua == 57 and gs.paneles_instalados == 2 and not game._transition_active,"Cadet animation restores checkpoint resources and modules")
	game.guide.stop()
	gs.modo_juego = "ingeniero"
	gs.paneles_instalados = 4
	gs.oxigeno = 0
	game._on_recovery_requested("restart",{})
	check(game._modal_kind == "recovery","Engineer receives its own recovery message")
	game._play_run_transition(true,false)
	await create_timer(1.8).timeout
	check(gs.paneles_instalados == 0 and gs.modo_juego == "ingeniero" and gs.nombre_astronauta == "Alex","Engineer animation resets progress and preserves profile and mode")
	game._open_victory()
	check(game._modal_kind == "victory" and not gs.en_partida,"Victory opens an animated summary and pauses the world")
	game.queue_free()
	await frames()
	print("LESSON FAILURES: ",failures)
	quit(0 if failures.is_empty() else 1)

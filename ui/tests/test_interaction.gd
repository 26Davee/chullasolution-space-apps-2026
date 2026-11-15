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
	sm.save_path = "user://killawasi_interaction_test.json"
	sm.reiniciar_legado()
	gs.aplicar_perfil({"nickname":"Alex","mode":"cadete","language":"en","voice_enabled":false,"tutorial_completed":true})
	gs.iniciar_partida("cadete")
	var game = load("res://scenes/juego.tscn").instantiate()
	root.add_child(game)
	await frames()
	game.set_process(false)
	gs.set_process(false)
	game._voice.muted = true
	check(game.rail.buttons.size() == 9,"Nine labelled stations are directly accessible")
	game.guide.start("process")
	game._on_dock_action("processing")
	check(game.guide.active() and game._modal_kind == "action:processing" and not gs.en_partida,"First task opens real controls with paused guidance")
	game._close_modal()
	game._on_station_clicked("processing",game.mundo)
	check(game._modal_kind == "action:processing","Machine opens same real processing panel")
	game._close_modal()
	# Test picking a rendered machine via the real camera ray.
	var processor = load("res://assets/3d/procesador_hielo.tscn").instantiate()
	processor.set_meta("piece_id",&"procesador_hielo")
	game.estructuras_colocadas.add_child(processor)
	processor.position = Vector3(8,0,12)
	game._bind_stations()
	game.camara.set_process(false)
	game.camara.position = Vector3(15,10,24)
	game.camara.look_at(processor.global_position+Vector3(0,1,0))
	await physics_frame
	game.click_to_move._pos_clic = game.camara.unproject_position(processor.global_position+Vector3(0,1,0))
	game.click_to_move._procesar_clic()
	check(game._modal_kind == "action:processing","Actual mouse ray on processor opens the shared panel")
	game._close_modal()
	check(not game._voice.is_speaking(),"Closing panel stops its voice")
	game.ice.discover()
	game.ice.discover()
	check(game.ice.discovered.size() == 3 and game.mundo.has_node("IceZone_basin"),"Discoveries spawn actual additional ice sites")
	var portable: Dictionary = game.ice.capture()
	game.ice.restore(portable)
	check(game.ice.discovered.size() == 3,"Discovered ice sites persist")
	game.ice.phase = "going"
	game.ice.cancel()
	check(not gs.en_viaje_hielo and game.ice.phase == "idle","Cancelled expedition clears pending state")
	var clock = load("res://ui/mission_clock.gd")
	check(clock.display({"tiempo_juego":240}).time == "18:00","Sunset at 18:00")
	check(clock.display({"tiempo_juego":480}).time == "06:00","Sunrise at 06:00")
	game._hud.set_state({"tiempo_juego":360,"es_dia":true})
	check(game._hud._phase_icon.kind == "moon" and game._hud._clock.text.contains("NIGHT"),"HUD phase cannot drift from clock, even with stale telemetry")
	var ambient = game.mundo.get_node("Ambiente")
	ambient.set_solar_time(120)
	check(ambient.get_node("Cielo/DistantSun").visible and ambient.get_node("Sol").light_energy > 0.9,"Midday sun is visible and bright")
	ambient.set_solar_time(360)
	check(not ambient.get_node("Cielo/DistantSun").visible and ambient.get_node("Sol").light_energy < 0.2,"Night follows the same solar phase")
	# Exercise physics movement for a full collection-and-return loop, not just forced mission events.
	Engine.time_scale = 6
	gs.en_partida = true
	game.session.learned.expedition = true
	game.guide.stop()
	game.ice.scan("crater")
	check(game.ice.start("crater"),"Trip can start")
	var phases: Array = []
	for i in 1200:
		await physics_frame
		game.ice.tick(root.get_physics_process_delta_time())
		if not phases.has(game.ice.phase): phases.append(game.ice.phase)
		if game.ice.phase in ["idle","blocked"]: break
	print("TRIP PHASES: ",phases," POSITION: ",game.robot.global_position)
	check(game.ice.phase == "idle" and gs.hielo > 0 and game._robot_distance_to_dome() <= game.DOME_RECHARGE_RADIUS,"Robot actually collects ice and returns without pending trip")
	for zone_id in ["ridge","basin"]:
		gs.energia_robot = 100
		check(game.ice.start(zone_id),"Discovered site can start: "+zone_id)
		for i in 1600:
			await physics_frame
			game.ice.tick(root.get_physics_process_delta_time())
			if game.ice.phase in ["idle","blocked"]: break
		print("ZONE ",zone_id," STATUS ",game.ice.phase," POS ",game.robot.global_position)
		check(game.ice.phase == "idle","Discovered site completes real movement: "+zone_id)
	Engine.time_scale = 1
	game.queue_free()
	await frames()
	print("INTERACTION FAILURES: ",failures)
	quit(0 if failures.is_empty() else 1)

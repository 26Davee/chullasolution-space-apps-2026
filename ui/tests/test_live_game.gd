extends SceneTree
## Runs against a dedicated save. Never loads/replaces the player's expedition.
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
	sm.save_path = OS.get_environment("KILLAWASI_TEST_SAVE")
	if sm.save_path.is_empty(): sm.save_path = "user://killawasi_ui_test.json"
	sm.reiniciar_legado()
	gs.aplicar_perfil({"nickname":"Test Cadet","mode":"cadete","age_group":"7_9","language":"en","voice_enabled":false,"tutorial_completed":true})
	gs.iniciar_partida("cadete")
	var game = load("res://scenes/juego.tscn").instantiate()
	root.add_child(game)
	await frames()
	game._voice.muted = true
	game.set_process(false)
	gs.set_process(false)
	check(game._session_ready,"Live session initialized")
	check(not game._hud._mission_label.text.is_empty() and not game._hud._clock.text.is_empty(),"Real mission pill and top telemetry visible")
	var last_y = -1.0
	for id in game._hud.IDS:
		var card: Control = game._hud.resource_buttons[id]
		check(card.position.x == 8 and card.position.y > last_y,"All five bars share a stacked column: "+id)
		last_y = card.position.y
	game._open_section_menu()
	var before = gs.tiempo_juego
	gs._process(2)
	game._tick_expedition(2)
	check(not gs.en_partida and gs.tiempo_juego == before,"Settings drawer truly pauses world and clock")
	check(not game.click_to_move.is_physics_processing(),"Movement pauses behind pausing drawer")
	game._close_drawer()
	game._open_section_drawer("construction")
	check(game._drawer.kind == "construction" and gs.en_partida and game.click_to_move.is_physics_processing(),"Construction drawer keeps world live")
	game._close_drawer()
	for sec in ["more", "expedition", "processing", "missions", "upgrades", "science", "messages", "timmy", "settings", "settings:language", "settings:audio", "settings:controls", "settings:exit"]:
		game._open_section_drawer(sec)
	check(game._drawer.kind == "settings:exit", "All new HUD drawers open cleanly")
	game._close_drawer()
	gs._process(1)
	game._tick_fallback_simulation(1)
	check(is_equal_approx(gs.tiempo_juego-before,1),"Clock advances exactly once")
	var mm = gs.obtener_mission_manager()
	var m: Dictionary = mm.obtener_mision_activa()
	mm._completar_mision_activa(m)
	await frames()
	var stock = game.session.inventory.duplicate(true)
	var stars = sm.obtener_estrellas_disponibles()
	check(stock.get("tanque_agua",0) == 1,"Editable mission supply delivered")
	mm._completar_mision_activa(m)
	game.session._on_mission(str(m.id),1,{})
	check(game.session.inventory == stock and sm.obtener_estrellas_disponibles() == stars,"Repeated completion cannot duplicate rewards")
	check(game.session.pending_rewards.size() == 1,"One pending celebration per mission")
	game.session.acknowledge_reward(str(m.id))
	game._close_modal()
	check(not game._science_cards().is_empty(),"Science shows real unlocked discovery")
	game._on_upgrade_requested("panel_extra")
	check(gs.estrellas == sm.obtener_estrellas_disponibles() and gs.estrellas == stars-1,"HUD wallet equals authoritative balance after purchase")
	# Place a real model, including metadata required by placement restoration.
	var piece = load("res://assets/3d/panel_solar.tscn").instantiate()
	piece.set_meta(&"piece_id",&"panel_solar")
	game.estructuras_colocadas.add_child(piece)
	piece.position = Vector3(16,0,10)
	game._on_piece_placed(&"panel_solar",piece.position)
	check(game.session.inventory.panel_solar == 0 and gs.paneles_instalados == 1,"Placement consumes one real inventory item")
	var snapshot: Dictionary = game.session.capture()
	game.session.checkpoint = snapshot.duplicate(true)
	gs.fijar_recurso("agua",1)
	game.robot.position = Vector3(40,0,40)
	game.session.inventory.panel_solar = 99
	game.session.recover()
	check(is_equal_approx(gs.agua,float(snapshot.state.agua)) and game.session.inventory.panel_solar == 0,"Cadet restores resource and inventory checkpoint")
	check(game.estructuras_colocadas.get_child_count() == 1 and game.estructuras_colocadas.get_child(0).position == Vector3(16,0,10),"Cadet restores placed model and position")
	check(game.session.save_run(),"Expedition serialized to dedicated save")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(sm.save_path))
	check(parsed is Dictionary and parsed.expedicion.current.world.placed.size() == 1,"On-disk JSON contains world state")
	var portable: Dictionary = parsed.expedicion.current
	game.session.restore(portable)
	check(game.estructuras_colocadas.get_child_count() == 1,"Disk round trip restores models")
	# Both loss modes use exactly the same components.
	gs.modo_juego = "ingeniero"
	game.session.recover()
	check(sm.obtener_misiones_completadas().is_empty() and sm.obtener_mejoras_compradas().is_empty(),"Engineer clears mission and upgrade progress")
	check(game.estructuras_colocadas.get_child_count() == 0 and game.session.inventory.panel_solar == 1,"Engineer resets world and starter inventory")
	check(gs.nombre_astronauta == "Test Cadet","Recovery keeps profile")
	game._close_modal()
	# A completed ice extraction alone must never count as returning home.
	mm.activar_mision("mision_02")
	gs.en_viaje_hielo = true
	gs.robot_en_domo = false
	mm.notificar_evento("hielo_extraido_crater",{"hielo_obtenido":3})
	mm.evaluar_estado_simulacion(gs.obtener_estado_diccionario(),0)
	check(not mm.obtener_triggers_cumplidos().has("retorno_domo_completado"),"Mining at crater is not a return to the dome")
	game.robot.position = Vector3(0,0,3)
	game.ice.phase = "returning"
	game.ice.collected = 3
	game._on_robot_arrived(game.robot.position)
	check(sm.esta_mision_completada("mision_02"),"Arrival at dome completes the real trip")
	await frames()
	game.session.pending_rewards.clear()
	game._close_modal()
	mm.activar_mision("mision_05")
	gs.energia_robot = 100
	game._run_rest()
	check(sm.esta_mision_completada("mision_05"),"Full battery can satisfy a charger visit without wasting power")
	await frames()
	game.session.pending_rewards.clear()
	game._close_modal()
	# Completing every authoritative mission raises the campaign ending only once.
	var endings: Array = []
	game.session.campaign_finished.connect(func(): endings.append(true))
	for mission in mm.obtener_todas_las_misiones():
		if not sm.esta_mision_completada(str(mission.id)): mm._completar_mision_activa(mission)
	await frames()
	check(game.session.all_missions_complete() and game.session.finished,"All sixteen missions produce ending")
	check(endings.size() == 1,"Ending event is emitted once")
	check(game.session.delivered.size() == 16,"Every mission delivery tracked once")
	# Atomic saves keep a usable backup when the current JSON is corrupt.
	game.session.save_run()
	var broken = FileAccess.open(sm.save_path,FileAccess.WRITE)
	broken.store_string("{invalid")
	broken.close()
	sm.cargar_progreso()
	check(sm.respaldo_recuperado and FileAccess.file_exists(sm.save_path+".invalid"),"Corrupt save preserves original and recovers backup")
	# Keep the real world while navigating home and resume.
	game.queue_free()
	await frames()
	sm.reiniciar_legado()
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	main.iniciar_juego("cadete")
	await frames()
	main._juego.set_process(false)
	main._juego._voice.muted = true
	gs.agua = 37
	var instance_id = main._juego.get_instance_id()
	main._juego._return_home()
	await frames()
	check(not gs.en_partida and main._menu.resume_available,"Home offers resume and pauses")
	main.iniciar_juego("cadete")
	await frames()
	check(main._juego.get_instance_id() == instance_id and gs.agua == 37,"Resume retains actual world and resources")
	main._juego._return_home()
	await frames()
	main._menu_layer.hide()
	main._show_intro(true)
	await frames()
	check(not main._juego.interfaz.visible and not gs.en_partida,"Tutorial review hides live HUD and pauses real run")
	main._intro.hide()
	main.mostrar_titulo()
	main.iniciar_juego("cadete")
	await frames()
	check(main._juego.get_instance_id() == instance_id and gs.agua == 37,"Tutorial review preserves the expedition")
	# Storm badge recovery reset: stale storm alert/active flags and badge must clear on recover()
	gs.alerta_nube = true
	gs.nube_activa = true
	gs.tiempo_para_nube = 10.0
	if is_instance_valid(main._juego._storm_badge):
		main._juego._storm_badge.visible = true
	main._juego.session.recover()
	await frames()
	check(not gs.alerta_nube and not gs.nube_activa and (main._juego._storm_badge == null or not main._juego._storm_badge.visible), "Storm badge and alert flags reset cleanly on checkpoint recovery")
	# Multi-slot save isolation & delete
	var slot_sm = preload("res://progression/save_manager.gd").new()
	slot_sm.save_path = slot_sm.ruta_slot(1)
	root.add_child(slot_sm)
	slot_sm.borrar_slot(1)
	slot_sm.borrar_slot(2)
	slot_sm.seleccionar_slot(1)
	slot_sm.guardar_expedicion({"current": {"state": {"tiempo_juego": 500.0}}}, {"nickname": "SlotUno", "mode": "cadet", "tutorial_completed": true})
	slot_sm.seleccionar_slot(2)
	slot_sm.guardar_expedicion({"current": {"state": {"tiempo_juego": 120.0}}}, {"nickname": "SlotDos", "mode": "engineer", "tutorial_completed": true})
	var slots_list: Array = slot_sm.listar_slots()
	check(slots_list.size() == 3 and slots_list[0].occupied and slots_list[1].occupied and not slots_list[2].occupied, "Three save slots report occupied/empty accurately")
	slot_sm.seleccionar_slot(1)
	check(str(slot_sm.obtener_datos_completos().get("perfil", {}).get("nickname", "")) == "SlotUno", "Switching slots restores slot 1 data without overwrite")
	var slots_panel = preload("res://ui/save_slots_panel.gd").new()
	slots_panel.save_manager = slot_sm
	root.add_child(slots_panel)
	await frames()
	check(slots_panel.is_inside_tree(), "Save slots panel renders cleanly with 3 slots")
	slots_panel.queue_free()
	slot_sm.borrar_slot(2)
	check(not slot_sm.leer_slot_resumen(2).occupied and slot_sm.leer_slot_resumen(1).occupied, "Deleting slot 2 clears only slot 2")
	slot_sm.borrar_slot(1)
	slot_sm.queue_free()
	main.queue_free()
	await frames()
	print("LIVE FAILURES: ",failures)
	quit(0 if failures.is_empty() else 1)

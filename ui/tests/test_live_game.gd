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
	sm.storage_directory = "user://killawasi_ui_test_slots"
	DirAccess.make_dir_recursive_absolute(sm.storage_directory)
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
	check(game._hud._mission_count.text == "0/2","M01 counter starts at 0/2 excluding passive entry")
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
	var water_before_invalid_restore: float = gs.agua
	var malformed_snapshot: Dictionary = portable.duplicate(true)
	malformed_snapshot["world"]["placed"] = "invalid"
	check(not game.session.restore(malformed_snapshot),"Malformed snapshot is rejected before restore")
	check(is_equal_approx(gs.agua,water_before_invalid_restore) and game.estructuras_colocadas.get_child_count() == 1,"Rejected restore leaves resources and placed models unchanged")
	game.session.restore(portable)
	check(game.estructuras_colocadas.get_child_count() == 1,"Disk round trip restores models")
	var invalid_current: Dictionary = portable.duplicate(true)
	invalid_current["world"]["placed"] = "invalid"
	check(sm.guardar_expedicion({"current":invalid_current,"checkpoint":portable},gs.preferencias),"Incompatible current snapshot prepared for recovery test")
	gs.fijar_recurso("agua",1)
	game.session.begin()
	check(game.session.restored and is_equal_approx(gs.agua,float(portable.state.agua)),"Invalid current save falls back to the latest valid checkpoint")
	check(not game.session.messages.is_empty() and str(game.session.messages[0].id).begins_with("save_recovered:"),"Checkpoint recovery is explained in the message center")
	check(game.session.save_run(),"Valid run is persisted before backup recovery test")
	check(sm.guardar_expedicion({"current":invalid_current,"checkpoint":invalid_current},gs.preferencias),"Incompatible main save and checkpoint prepared")
	gs.fijar_recurso("agua",1)
	game.session.begin()
	check(game.session.restored and is_equal_approx(gs.agua,float(portable.state.agua)),"When main save and checkpoint are invalid, the valid slot backup is restored")
	check(not game.session.messages.is_empty() and str(game.session.messages[0].id).begins_with("save_recovered:"),"Backup recovery is explained in the message center")
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
	slot_sm.storage_directory = "user://killawasi_slot_isolation_test"
	slot_sm.save_path = slot_sm._slot_path(1)
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
	# Deleting slot 1 must retire legacy save_data.json so restarting never revives it
	var leg_dir := "user://killawasi_legacy_migration_test"
	DirAccess.make_dir_recursive_absolute(leg_dir)
	var leg_file := leg_dir.path_join("legacy_save.json")
	for f_name in ["meta.json", "slot_1.json", "slot_1.json.bak", "legacy_save.json", "legacy_save.json.migrated"]:
		var fp := leg_dir.path_join(f_name)
		if FileAccess.file_exists(fp):
			DirAccess.remove_absolute(fp)
	var lf := FileAccess.open(leg_file, FileAccess.WRITE)
	lf.store_string(JSON.stringify({"estrellas_totales": 10, "perfil": {"nickname": "LegacyPilot", "mode": "cadete", "tutorial_completed": true}}))
	lf.close()
	var leg_sm1 = preload("res://progression/save_manager.gd").new()
	leg_sm1.storage_directory = leg_dir
	leg_sm1.legacy_save_path = leg_file
	root.add_child(leg_sm1)
	await frames()
	check(leg_sm1.leer_slot_resumen(1).occupied, "First launch migrates legacy save into slot 1")
	leg_sm1.borrar_slot(1)
	check(not leg_sm1.leer_slot_resumen(1).occupied, "Deleting slot 1 clears slot 1 immediately")
	leg_sm1.queue_free()
	await frames()
	var leg_sm2 = preload("res://progression/save_manager.gd").new()
	leg_sm2.storage_directory = leg_dir
	leg_sm2.legacy_save_path = leg_file
	root.add_child(leg_sm2)
	await frames()
	check(not leg_sm2.leer_slot_resumen(1).occupied, "Restarting after deleting slot 1 never revives legacy save")
	leg_sm2.queue_free()
	# Linearity & upgrade alignment + HUD bounds verification
	var lg: Node = main._juego
	var lg_mm: Node = gs.obtener_mission_manager()
	var lg_sm: Node = gs.obtener_save_manager()
	lg_sm._datos["estrellas_disponibles"] = 24
	lg_sm._datos["estrellas_totales"] = 24
	gs.estrellas = 24
	check(lg._structure_limit("jardin") == 1, "Base garden limit is 1 before jardin_lunar")
	lg.session.inventory["jardin"] = int(lg.session.inventory.get("jardin", 0)) + 1
	var j_piece := Node3D.new()
	j_piece.set_meta(&"piece_id", &"jardin")
	lg.estructuras_colocadas.add_child(j_piece)
	j_piece.position = Vector3(12, 0, 12)
	lg._on_piece_placed(&"jardin", j_piece.position)
	check(lg._structure_count(gs, "jardin") == 1 and gs.jardin_instalado, "First garden can be placed from M14 supply without upgrade")
	gs.jardin_instalado = false
	for u_id in ["procesar_rapido", "generador_eficiente", "jardin_lunar"]:
		lg._on_upgrade_requested(u_id)
	lg._close_modal()
	check(not gs.jardin_instalado and lg._structure_limit("jardin") == 2 and lg.session.spawned_upgrade_drops.has("jardin_lunar"), "jardin_lunar drops +1 garden pod and raises limit to 2 without auto-installing")
	check(lg._ice_yield_for_tool(1) == 3 and lg._ice_yield_for_tool(2) == 4 and lg._ice_yield_for_tool(3) == 7 and lg._ice_yield_for_tool(4) == 10, "Ice extraction yields match upgrades.json (3/4/7/10)")
	check(lg._ice_extraction_cost_for_tool(1) == 16 and lg._ice_extraction_cost_for_tool(2) == 13 and lg._ice_extraction_cost_for_tool(3) == 10 and lg._ice_extraction_cost_for_tool(4) == 8, "Ice extraction battery cost matches upgrades.json (16/13/10/8)")
	check(lg._storm_warning_seconds() == 20.0 and lg._repair_time_seconds() == 3.0 and lg._repair_energy_cost() == 20, "Base storm warning, repair time, and cadet repair cost match")
	for u_id in ["reparar_barato", "mas_resistencia", "alerta_temprana"]:
		lg._on_upgrade_requested(u_id)
	lg._close_modal()
	check(lg._storm_warning_seconds() == 40.0 and lg._repair_time_seconds() == 2.0 and lg._repair_energy_cost() == 15, "Upgraded warning/repair timings and cost match upgrades.json")
	# M06 sunset & M07 3-minute night triggers
	lg_mm.activar_mision("mision_06")
	lg_mm.evaluar_estado_simulacion({"es_dia": true, "tiempo_ciclo_solar": 180.0, "paneles_instalados": 2, "energia": 92.0}, 0.1)
	check(lg_sm.esta_mision_completada("mision_06"), "M06 completes at 180s dusk sunset")
	lg_mm.activar_mision("mision_07")
	lg_mm.evaluar_estado_simulacion({"es_dia": false, "energia": 55.0, "oxigeno": 60.0, "escudo": 60.0}, 181.0)
	check(lg_mm.obtener_triggers_cumplidos().has("noche_3_minutos_transcurrida"), "M07 night trigger fires at 180s (3 minutes)")
	lg_mm.evaluar_estado_simulacion({"es_dia": true, "energia": 55.0, "oxigeno": 60.0, "escudo": 60.0}, 0.1)
	check(lg_sm.esta_mision_completada("mision_07"), "M07 completes after 180s night and dawn arrival")
	# M09 full-shield repair inspection & M11 two-trip completion
	lg_mm.activar_mision("mision_09")
	gs.escudo = 100.0
	lg._run_repair()
	lg_mm.evaluar_estado_simulacion({"escudo": 100.0}, 0.1)
	check(lg_sm.esta_mision_completada("mision_09"), "M09 completes when inspecting/repairing shield already at 100%")
	lg_mm.activar_mision("mision_11")
	lg_mm.notificar_evento("retorno_domo_completado")
	lg_mm.notificar_evento("retorno_domo_completado")
	lg_mm.evaluar_estado_simulacion({"agua": 9.0, "oxigeno": 60.0}, 0.1)
	check(lg_sm.esta_mision_completada("mision_11"), "M11 completes cleanly after 2 ice trips")
	lg_mm.activar_mision("mision_14")
	check(lg._m14_superstorm_armed, "M14 superstorm trigger arms next storm profile")
	# HUD & Drawer bounds within 1280x720
	for id in lg._hud.resource_buttons:
		var rcard: Control = lg._hud.resource_buttons[id]
		var rrect: Rect2 = rcard.get_global_rect()
		check(rrect.position.x >= 0.0 and rrect.end.x <= 1280.0 and rrect.end.y <= 720.0, "HUD resource card inside viewport: " + id)
	for sec in ["construction", "missions", "upgrades", "messages", "settings:audio"]:
		lg._open_section_drawer(sec)
		await frames()
		var drect: Rect2 = lg._drawer.get_global_rect()
		check(drect.position.x >= 0.0 and drect.end.x <= 1280.0 and drect.end.y <= 720.0, "Drawer stays inside 1280x720: " + sec)
		var overflow := false
		for child in lg._drawer._content.get_children():
			if child is Control and child.get_global_rect().end.x > drect.end.x + 1.0:
				overflow = true
		check(not overflow, "Drawer content children stay within drawer right edge: " + sec)
		if sec == "settings:audio":
			var sliders: Array = lg._drawer._content.find_children("", "HSlider", true, false)
			var rate_ok := false
			for s_node in sliders:
				if s_node is HSlider and s_node.max_value < 10.0:
					s_node.value = 1.25
					for lbl in s_node.get_parent().find_children("", "Label", true, false):
						if lbl is Label and lbl.text == "1.25x":
							rate_ok = true
			check(rate_ok, "Audio rate slider formats decimal cleanly")
	lg._close_drawer()
	main.queue_free()
	await frames()
	print("LIVE FAILURES: ",failures)
	quit(0 if failures.is_empty() else 1)

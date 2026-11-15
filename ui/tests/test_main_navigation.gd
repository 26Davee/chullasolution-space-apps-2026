extends SceneTree
var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	print(("OK " if value else "FAIL ")+message)
	if not value: failures.append(message)
func _initialize() -> void: call_deferred("run")
func frames(n: int = 3) -> void:
	for i in n: await process_frame
func wait_transition(main: Node) -> void:
	var limit := Time.get_ticks_msec()+10000
	while main._transitioning and Time.get_ticks_msec() < limit: await process_frame
	check(not main._transitioning,"Transition completes and releases navigation")
func run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var sm = gs.obtener_save_manager()
	sm.save_path = "user://killawasi_navigation_test.json"
	sm.reiniciar_legado()
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	var intro = main._intro
	intro.voice.muted = true
	intro._skip_tutorial()
	await intro.profile_setup_entered
	check(intro._in_profile and intro.nickname.is_empty() and intro.tutorial.player.age_group.is_empty(),"Skip goes directly to a separate profile without assigning a name or mode")
	check(sm.obtener_datos_completos().get("perfil",{}).get("tutorial_completed",false),"Skipping is remembered before entering personal data")
	main.queue_free()
	await frames()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	intro = main._intro
	intro.voice.muted = true
	check(intro._in_profile,"Closing during setup resumes setup instead of repeating the tutorial")
	intro.setup_screen.name_field.text = "Sam"
	intro.setup_screen.name_field.text_changed.emit("Sam")
	check(intro.setup_screen.continue_button.disabled,"Profile requires an explicit age")
	intro.setup_screen.age_buttons["10_12"].pressed.emit()
	intro.setup_screen.continue_button.pressed.emit()
	await intro.home_entered
	check(intro.tutorial.player.mode_id() == "ingeniero" and intro.tutorial.player.locked,"Age determines the mode only after profile confirmation")
	check(sm.obtener_datos_completos().get("perfil",{}).get("age_group","") == "10_12","Confirmed profile is saved before pressing Play")
	check(intro.home_screen.restart_button.is_visible_in_tree(),"Initial home also offers Start from scratch")
	main.queue_free()
	await frames()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	check(is_instance_valid(main._menu) and not is_instance_valid(main._intro),"Reopening after skipping opens the main menu")
	main.iniciar_juego("ingeniero")
	await frames()
	var game = main._juego
	game._voice.muted = true
	gs.set_process(false)
	game.set_process(false)
	game.guide.stop()
	gs.agua = 37
	gs.paneles_instalados = 2
	game.session.save_run()
	check(game._menu_button.get_child(0).kind == "settings" and game.rail.utility_buttons.has("more"),"Settings is separate from the bottom More button")
	game._open_section_menu()
	game._navigation_view.buttons.exit.pressed.emit()
	for button in game._modal_layer.find_children("*","Button",true,false):
		if button.text == game.tr("nav.save_exit"): button.pressed.emit(); break
	await frames()
	var menu = main._menu
	check(menu.resume_available and menu.restart_button.is_visible_in_tree(),"Home shows Resume and Start from scratch together")
	menu.restart_button.pressed.emit()
	check(is_instance_valid(menu._restart_confirmation) and gs.agua == 37,"Start over asks before changing progress")
	menu._restart_confirmation.find_child("CancelRestart",true,false).pressed.emit()
	check(gs.agua == 37 and gs.paneles_instalados == 2,"Cancel preserves the expedition")
	menu.restart_button.pressed.emit()
	menu._restart_confirmation.find_child("ConfirmRestart",true,false).pressed.emit()
	await wait_transition(main)
	check(gs.nombre_astronauta == "Sam" and gs.modo_juego == "ingeniero","Start over preserves the name and chosen difficulty")
	check(gs.paneles_instalados == 0 and game.estructuras_colocadas.get_child_count() == 0,"Start over resets the real expedition")
	check(sm.obtener_misiones_completadas().is_empty(),"Start over clears mission progress")
	check(sm.obtener_datos_completos().get("perfil",{}).get("tutorial_completed",false),"Start over keeps tutorial preferences for the next launch")
	game.guide.stop()
	gs.agua = 43
	game.session.save_run()
	game._return_home()
	await frames()
	main.queue_free()
	await frames()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	check(main._menu.resume_available,"A new app session offers the saved expedition")
	main.iniciar_juego("ingeniero")
	await frames()
	main._juego.set_process(false)
	main._juego._voice.muted = true
	check(gs.agua == 43,"Reopening and resuming preserves the saved water reserve")
	main.queue_free()
	await frames()
	print("NAVIGATION FAILURES: ",failures)
	quit(0 if failures.is_empty() else 1)

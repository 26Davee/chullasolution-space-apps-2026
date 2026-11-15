extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
    print(("OK " if value else "FAIL ")+message)
    if not value: failures.append(message)
func frames(n := 4) -> void:
    for i in n: await process_frame
func run() -> void:
    root.size = Vector2i(1280,720)
    await frames()
    var gs = root.get_node("GameState")
    gs.set_process(false)
    gs.preferencias["voice_enabled"] = false
    var sm = gs.obtener_save_manager()
    sm.storage_directory = "user://killawasi_navigation_test"
    DirAccess.make_dir_recursive_absolute(sm.storage_directory)
    for i in [1,2,3]: sm.borrar_slot(i)
    sm.marcar_tutorial_visto(false)
    sm.seleccionar_slot(1)
    var main = load("res://scenes/main.tscn").instantiate()
    root.add_child(main)
    await frames()
    main.nueva_partida_en_slot(1)
    await frames(6)
    check(is_instance_valid(main._intro) and not is_instance_valid(main._slot_setup),"New expedition teaches before asking for name and age")
    main._intro.voice.muted = true
    main._intro._finish()
    await create_timer(0.5).timeout
    check(not is_instance_valid(main._intro) and is_instance_valid(main._slot_setup),"Skip ends training and frees its world before profile")
    check(sm.fue_tutorial_visto(),"Skipping is remembered")
    var setup = main._slot_setup
    setup.age_buttons["7_9"].pressed.emit()
    check(setup.start_button.disabled,"A call sign is required along with age")
    setup.name_field.text = "Alex"
    setup.name_field.text_changed.emit("Alex")
    setup.start_button.pressed.emit()
    await frames()
    check(is_instance_valid(main._slots_panel) and not is_instance_valid(main._juego),"Profile returns to the main menu before Play")
    check(sm.leer_slot_resumen(1).occupied and sm.leer_slot_resumen(1).nickname == "Alex","Profile is saved in its chosen slot")
    main.cargar_slot(1)
    await create_timer(1.0).timeout
    await frames()
    check(is_instance_valid(main._juego) and gs.modo_juego == "cadete","Play opens the actual cadet expedition")
    main._juego.set_process(false)
    gs.fijar_recurso("agua",37)
    main._juego.session.save_run()
    main.mostrar_titulo()
    main._show_intro(true)
    await frames(6)
    main._intro.voice.muted = true
    main._intro._finish()
    await create_timer(0.5).timeout
    check(not is_instance_valid(main._intro) and not is_instance_valid(main._slot_setup),"Review/Skip returns to menu without asking for profile again")
    check(gs.agua == 37,"Review preserves the existing expedition")
    main.cargar_slot(1)
    await create_timer(1.0).timeout
    check(gs.agua == 37,"Resume keeps the saved water reserve")
    main.mostrar_titulo()
    main.nueva_partida_en_slot(2)
    await frames(5)
    check(is_instance_valid(main._slot_setup) and not is_instance_valid(main._intro),"A later expedition can go directly to profile")
    setup = main._slot_setup
    setup.age_buttons["10_12"].pressed.emit()
    setup.name_field.text = "Sam"
    setup.name_field.text_changed.emit("Sam")
    setup.start_button.pressed.emit()
    await frames()
    check(gs.modo_juego == "ingeniero" and sm.leer_slot_resumen(2).nickname == "Sam","Age 10–12 selects Engineer after training")
    check(sm.leer_slot_resumen(1).nickname == "Alex","A second profile preserves the first slot")
    main.cargar_slot(2)
    await create_timer(1.0).timeout
    var game = main._juego
    game.set_process(false)
    game.session.learned["tour"] = true
    game._close_drawer()
    var before = game.session.capture()
    game._confirm_new_game()
    for button in game._modal_layer.find_children("*","Button",true,false):
        if button.text == game.tx("cancel"): button.pressed.emit(); break
    check(game.session.capture() == before,"Cancel Start over preserves resources, missions and placed modules")
    main.queue_free()
    await frames()
    print("NAVIGATION FAILURES: ",failures)
    quit(0 if failures.is_empty() else 1)

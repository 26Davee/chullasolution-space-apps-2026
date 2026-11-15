extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
    print(("OK " if value else "FAIL ")+message)
    if not value: failures.append(message)
func frames(n := 5) -> void:
    for i in n: await process_frame
func escape() -> void:
    for down in [true,false]:
        var event := InputEventKey.new()
        event.keycode = KEY_ESCAPE
        event.pressed = down
        root.push_input(event,true)
func run() -> void:
    root.size = Vector2i(1280,720)
    await frames()
    root.get_node("GameState").preferencias["voice_enabled"] = false
    var lesson = load("res://ui/intro.tscn").instantiate()
    root.add_child(lesson)
    await frames(8)
    var game = lesson.game
    lesson.voice.muted = true
    lesson.index = lesson.STEPS.find("construction")
    lesson._show_step()
    game._on_dock_action("construction")
    game._on_drawer_action("build_module",{"id":"panel_solar"})
    check(game.placement_system.is_placing(),"Build starts the actual hologram")
    escape()
    await frames()
    check(not game.placement_system.is_placing() and not lesson.done,"Cancel never falsely completes the building lesson")
    if is_instance_valid(game._modal_layer): game._close_modal()
    game._close_drawer()
    await frames()
    check(is_instance_valid(lesson.coach.target),"Timmy offers a real control to restart a cancelled build")
    lesson.index = lesson.STEPS.find("expedition")
    lesson._show_step()
    game._on_dock_action("expedition")
    game._on_drawer_action("scan_ice",{})
    game._on_drawer_action("select_ice_zone",{"id":"ridge"})
    game._on_drawer_action("start_ice",{})
    game._on_drawer_action("cancel_ice",{})
    await frames()
    check(game.ice.phase == "idle" and lesson.stage == 2 and not lesson.done,"Cancelling a trip returns to the start-trip instruction")
    game._open_section_drawer("expedition")
    await frames()
    check(is_instance_valid(lesson.coach.target) and lesson.coach.target.text == tr("live.ice_start_btn"),"Cancelled ice lesson has a working next button")
    lesson.index = lesson.STEPS.find("recovery")
    lesson._show_step()
    await create_timer(1.2).timeout
    check(is_instance_valid(game._modal_layer),"Recovery arrives as an automatic notice")
    escape()
    await create_timer(1.3).timeout
    check(is_instance_valid(game._modal_layer) and not lesson.done,"Closing recovery early cannot leave an impossible step")
    lesson._recovery_buttons.cadet.pressed.emit()
    check(lesson._recovery_continue.disabled,"One recovery demonstration cannot stand in for both roles")
    lesson._recovery_buttons.engineer.pressed.emit()
    lesson._recovery_continue.pressed.emit()
    await frames()
    check(lesson.done,"Both recovery demonstrations release Continue")
    lesson.index = lesson.STEPS.find("settings")
    lesson._show_step()
    game._open_section_drawer("settings:language")
    await frames()
    check(is_instance_valid(lesson._find_button("Spanish")),"English language screen names Spanish correctly")
    game._on_drawer_action("set_language",{"lang":"es"})
    await frames()
    check(is_instance_valid(lesson._find_button("Español")),"Spanish screen uses its translated language names")
    game._close_drawer()
    check(not lesson.voice.is_speaking(),"Closing a drawer stops its narration")
    lesson.queue_free()
    await frames()
    print("DETOUR FAILURES: ",failures)
    quit(0 if failures.is_empty() else 1)

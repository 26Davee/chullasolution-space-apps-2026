extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
    if not value:
        failures.append(message)
        push_error(message)
func frames(n := 3) -> void:
    for i in n: await process_frame
func click(control: Control) -> void:
    check(is_instance_valid(control),"Expected a real visible control")
    if not is_instance_valid(control): return
    if control is BaseButton and control.disabled: return
    var point := control.get_global_rect().get_center()
    for down in [true,false]:
        var event := InputEventMouseButton.new()
        event.button_index = MOUSE_BUTTON_LEFT
        event.pressed = down
        event.position = point
        event.global_position = point
        root.push_input(event,true)
func place(game: Node3D) -> void:
    game.camara.set_process(false)
    game.camara.position = Vector3(18,30,34)
    game.camara.look_at(Vector3(0,0,0))
    for point in [Vector3(8,0,8),Vector3(-8,0,-8),Vector3(10,0,-6),Vector3(-10,0,6)]:
        var pos: Vector2 = game.camara.unproject_position(point)
        var motion := InputEventMouseMotion.new()
        motion.position = pos
        motion.global_position = pos
        root.push_input(motion,true)
        await physics_frame
        await physics_frame
        game.placement_system._update_preview(pos)
        print("PLACE ",point," mouse ",root.get_mouse_position()," hovered ",root.gui_get_hovered_control()," target ",game.placement_system.has_valid_target()," reason ",game.placement_system.get_reject_reason())
        if not game.placement_system.has_valid_target(): continue
        for down in [true,false]:
            var event := InputEventMouseButton.new()
            event.button_index = MOUSE_BUTTON_LEFT
            event.pressed = down
            event.position = pos
            event.global_position = pos
            root.push_input(event,true)
        await frames()
        if not game.placement_system.is_placing(): return
    check(false,"Actual hologram can be placed on clear ground inside the dome")
func run() -> void:
    root.size = Vector2i(1280,720)
    await frames()
    var real = root.get_node("GameState")
    real.set_process(false)
    real.preferencias["voice_enabled"] = false
    var resources: Dictionary = real.obtener_estado_diccionario().duplicate(true)
    var saved: Dictionary = real.obtener_save_manager().obtener_datos_completos().duplicate(true)
    Engine.time_scale = 6
    for lang in ["en","es"]:
        var lesson = load("res://ui/intro.tscn").instantiate()
        lesson.language = lang
        root.add_child(lesson)
        await frames(5)
        lesson.voice.muted = true
        check(lesson.state != real and lesson.game.session.gs == lesson.state,"Lesson services are isolated from the real player")
        check(lesson.state.obtener_save_manager().get_script().resource_path == "res://ui/tutorial_save.gd","Practice has a memory-only save")
        var last_step := ""
        var visits := 0
        var actions := 0
        var wait := 0
        while not lesson._transitioning and visits < 2500:
            visits += 1
            if last_step != lesson.step:
                last_step = lesson.step
                wait = 0
                print("LESSON ",lang," ",last_step)
            if lesson.step in lesson.RESOURCE_IDS:
                check(lesson.done,"Bars only explain; no click is needed")
                for button in lesson.game._hud.resource_buttons.values():
                    check(button.focus_mode == Control.FOCUS_NONE and button.mouse_filter == Control.MOUSE_FILTER_IGNORE,"Bars cannot demand an interaction")
            if lesson.done:
                click(lesson.primary_button)
            elif lesson.step == "construction" and lesson.game.placement_system.is_placing():
                await place(lesson.game)
                if lesson.game.placement_system.is_placing(): break
            elif is_instance_valid(lesson.coach.target):
                click(lesson.coach.target)
                actions += 1
            await create_timer(0.12).timeout
            await frames(2)
            if lesson.game._drawer.visible and lesson.game._drawer._footer.visible:
                for button in lesson.game._drawer._footer.get_children():
                    if button is Button:
                        check(button.size.y <= 48.0,"Action completion keeps a compact button: "+lang+" "+last_step)
                        check(button.get_global_rect().end.y <= lesson.game._drawer.get_global_rect().end.y-2,"Action footer stays inside the panel")
            wait += 1
            if wait > 400:
                check(false,"Lesson stalled: "+lang+" "+last_step+" stage "+str(lesson.stage)+" drawer "+lesson.game._drawer.kind+" ice "+lesson.game.ice.phase+" playing "+str(lesson.state.en_partida)+" remaining "+str(lesson.game.ice._mining))
                break
        check(lesson._transitioning,"The complete guided lesson reaches its end: "+lang)
        check(actions > 15,"The lesson exercised the real buttons, not completion shortcuts")
        check(real.obtener_estado_diccionario() == resources,"Practice preserves real resources and mission state")
        check(real.obtener_save_manager().obtener_datos_completos() == saved,"Practice cannot replace a player save")
        lesson.queue_free()
        await frames()
    Engine.time_scale = 1
    var skip = load("res://ui/intro.tscn").instantiate()
    root.add_child(skip)
    await frames(5)
    skip.voice.muted = true
    var finished: Array = []
    skip.home_entered.connect(func(): finished.append(true))
    click(skip.skip_button)
    await create_timer(0.5).timeout
    check(finished == [true],"Skip exits the lesson once")
    check(not skip.voice.is_speaking(),"Leaving the lesson stops narration")
    skip.queue_free()
    await frames()
    print("TUTORIAL FAILURES: ",failures)
    quit(0 if failures.is_empty() else 1)

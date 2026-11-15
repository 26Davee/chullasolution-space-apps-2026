extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
    print(("OK " if value else "FAIL ")+message)
    if not value: failures.append(message)
func frames(n := 5) -> void:
    for i in n: await process_frame
func run() -> void:
    root.size = Vector2i(1280,720)
    await frames()
    var gs = root.get_node("GameState")
    gs.set_process(false)
    var sm = gs.obtener_save_manager()
    sm.save_path = "user://killawasi_outcome_test.json"
    for mode in ["cadete","ingeniero"]:
        for resource in ["energia","oxigeno"]:
            sm.reiniciar_legado()
            gs.aplicar_perfil({"nickname":"Alex","mode":mode,"age_group":"7_9" if mode == "cadete" else "10_12","language":"en" if resource == "energia" else "es","voice_enabled":false,"tutorial_completed":true})
            gs.iniciar_partida(mode)
            var game = load("res://scenes/juego.tscn").instantiate()
            root.add_child(game)
            await frames()
            game.set_process(false)
            game._voice.muted = true
            game._close_drawer()
            gs.fijar_recurso("agua",36)
            sm.registrar_mision_completada("mision_01",2)
            game.session.checkpoint = game.session.capture()
            gs.cambiar_energia_robot(-100)
            check(game._modal_kind != "recovery","Robot battery at zero is not an expedition loss: "+mode)
            gs.fijar_recurso("agua",1)
            gs.fijar_recurso(resource,0)
            await frames()
            check(game._modal_kind == "recovery","Zero "+resource+" opens the loss screen: "+mode)
            var expected: String = game.tx("recover" if mode == "cadete" else "restart")
            var action: Button
            for button in game._modal_layer.find_children("*","Button",true,false):
                if button.text == expected: action = button
            check(is_instance_valid(action),"The loss screen offers the correct recovery policy")
            if is_instance_valid(action): action.pressed.emit()
            check(game._recovering,"Recovery starts a visible transition")
            await create_timer(0.8).timeout
            await frames()
            check(not game._recovering and game._modal_kind != "recovery","The transition finishes and releases the game")
            check(gs.energia > 0 and gs.oxigeno > 0,"Recovery clears the failure condition")
            if mode == "cadete":
                check(gs.agua == 36 and sm.esta_mision_completada("mision_01"),"Cadet restores checkpoint resources and mission progress")
            else:
                check(gs.agua == 20 and sm.obtener_misiones_completadas().is_empty(),"Engineer restarts resources and missions")
            check(gs.nombre_astronauta == "Alex" and gs.modo_juego == mode,"Recovery preserves the player's profile")
            game.queue_free()
            await frames()
    var voices = load("res://ui/timmy_voice.gd")
    var en: Array[Dictionary] = [{"id":"zira","name":"Microsoft Zira Desktop"},{"id":"david","name":"Microsoft David"}]
    var es: Array[Dictionary] = [{"id":"sabina","name":"Microsoft Sabina Desktop"},{"id":"helena","name":"Microsoft Helena"}]
    check(voices.pick_voice(en,"en-US") == "zira" and voices.pick_voice(es,"es-MX") == "sabina","Zira and Sabina remain the default narration voices")
    print("OUTCOME FAILURES: ",failures)
    quit(0 if failures.is_empty() else 1)

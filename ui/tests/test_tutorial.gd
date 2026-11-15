extends SceneTree
## Run with: Godot --headless --path . --script res://ui/tests/test_tutorial.gd
const Controller = preload("res://ui/tutorial_controller.gd")
const Profile = preload("res://ui/player_profile.gd")
const Bridge = preload("res://ui/game_bridge.gd")

class FakeVoice extends Node:
    var selected_voices: Dictionary = {}
    var muted := false
    var volume := 85
    var rate := 0.95
    var phrases: Array[String] = []
    var last_language := ""
    func status_code(_language: String) -> String: return "ready"
    func voices_for(_language: String) -> Array[Dictionary]:
        return [{"id":"test", "name":"Test voice"}]
    func available(_language: String) -> bool: return true
    func voice_id(_language: String) -> String: return "test"
    func set_voice(_language: String, _id: String) -> void: pass
    func stop() -> void: pass
    func is_speaking() -> bool: return false
    func speak(text: String, language: String) -> bool:
        if muted: return false
        phrases.append(text)
        last_language = language
        return true

class FakeBus extends Node:
    signal recurso_actualizado(id: String, value: float, maximum: float)
    signal estrellas_actualizadas(total: int)
    signal ciclo_solar_cambiado(day: bool)
    signal mision_completada(id: String, reward: int, card: Dictionary)
    signal mejora_desbloqueada(id: String, branch: String, level: int)
    signal vicuna_mensaje_mostrado(index: int, key: String)
    var energia := 60.0
    var oxigeno := 100.0
    var estrellas := 0
    var hielo := 0
    var es_dia := true
    var bateria_instalada := false

var failures: Array[String] = []
var completed_flows := 0
var starts: Array[Dictionary] = []
var recoveries: Array[String] = []

func _initialize() -> void:
    call_deferred("run")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
        push_error(message)

func click(button: Button) -> void:
    if not is_instance_valid(button):
        check(false, "Missing button")
        return
    var p := button.get_global_rect().get_center()
    for pressed in [true, false]:
        var event := InputEventMouseButton.new()
        event.position = p
        event.global_position = p
        event.button_index = MOUSE_BUTTON_LEFT
        event.pressed = pressed
        root.push_input(event, true)

func key(code: int) -> void:
    for pressed in [true, false]:
        var event := InputEventKey.new()
        event.keycode = code
        event.pressed = pressed
        root.push_input(event, true)

func run() -> void:
    var voices = load("res://ui/timmy_voice.gd")
    var english: Array[Dictionary] = [{"id":"david","name":"Microsoft David"},{"id":"zira","name":"Microsoft Zira Desktop"}]
    var spanish: Array[Dictionary] = [{"id":"helena","name":"Microsoft Helena"},{"id":"sabina","name":"Microsoft Sabina Desktop"}]
    check(voices.pick_voice(english, "en-US") == "zira", "Zira is the English default")
    check(voices.pick_voice(spanish, "es_MX") == "sabina", "Sabina is the Spanish default")
    check(voices.pick_voice(english, "en", "david") == "david", "An explicit voice choice takes priority")
    check(voices.pick_voice(english, "es") == "david", "Unavailable preferred voice falls back safely")
    var profile = Profile.new()
    check(not profile.choose_age("6"), "Unsupported ages are rejected")
    profile.choose_age("7_9")
    check(profile.mode_id() == "cadete", "7–9 maps to Cadet")
    profile.choose_age("10_12")
    check(profile.mode_id() == "ingeniero", "10–12 maps to Engineer")
    profile.locked = true
    check(not profile.choose_age("7_9"), "Confirmed age is locked for this expedition")
    check(Profile.recovery_for("cadete") == "checkpoint", "Cadet recovery policy")
    check(Profile.recovery_for("ingeniero") == "restart", "Engineer recovery policy")
    for test_case in [
        {"age":"7_9", "mode":"cadete", "language":"en"},
        {"age":"10_12", "mode":"ingeniero", "language":"es"},
        {"age":"7_9", "mode":"cadete", "language":"es"},
        {"age":"10_12", "mode":"ingeniero", "language":"en"}
    ]:
        await run_flow(test_case)
    check(completed_flows == 4, "Both roles must finish in each language without script exceptions")
    await test_bridge()
    await test_catalog_and_purchases()
    var clock = load("res://ui/mission_clock.gd")
    check(clock.display({"tiempo_juego": 240.0}) == {"year":1,"month":1,"day":1,"time":"18:00"}, "Sunset agrees with mission clock at 18:00")
    check(clock.display({"tiempo_juego": 480.0}) == {"year":1,"month":1,"day":2,"time":"06:00"}, "Next sunrise agrees with 06:00")
    check(clock.display({"tiempo_juego": 172680.0}) == {"year":2,"month":1,"day":1,"time":"00:00"}, "Calendar carries months and years")
    check(clock.display({"dia_mision": 6, "minutos_mision": 125}) == {"year":1,"month":1,"day":6,"time":"02:05"}, "Authoritative mission clock overrides projection")
    if failures.is_empty():
        print("PASS: all four role/language combinations, 24 shared tutorial steps plus profile, EN/ES, mouse/keyboard, age gates, HUD targets, panels, profile, providers, failure-zero edge, dynamic maximum and authoritative stars")
    else:
        print("FAIL: ", failures)
    quit(0 if failures.is_empty() else 1)

func run_flow(test_case: Dictionary) -> void:
    root.size = Vector2i(1280, 720)
    var starts_before := starts.size()
    var pauses: Array[bool] = []
    var resumes: Array[Dictionary] = []
    var intro: Control = load("res://ui/intro.tscn").instantiate()
    root.add_child(intro)
    await process_frame
    var original: Node = intro.voice
    var fake := FakeVoice.new()
    intro.add_child(fake)
    intro.voice = fake
    original.queue_free()
    intro.mission_requested.connect(func(data: Dictionary): starts.append(data))
    intro.pause_requested.connect(func(paused: bool): pauses.append(paused))
    intro.resume_requested.connect(func(data: Dictionary): resumes.append(data))
    await intro._change_language(test_case.language)
    click(intro.primary_button)
    check(intro.step == "landing", "Start button begins landing")
    click(intro.primary_button)
    check(intro.step == "arrival", "Landing can be skipped")
    var attempts := 0
    while intro.step != "done" and attempts < 35:
        attempts += 1
        intro._finish_reveal()
        var before: String = intro.step
        var target: String = intro.tutorial.target()
        if not target.is_empty():
            check(intro.primary_button.disabled, "Required tutorial action gates Continue: " + target)
            var parts := target.split(":")
            if parts[0] == "event":
                var state_before: Dictionary = intro.bridge.get_state()
                if parts[1] == "alert":
                    for i in 3: await process_frame
                    click(intro._demo_alert._solve)
                    await process_frame
                    var reader = intro._activity_view.reader
                    click(reader._scroll.get_child(0).get_child(0))
                else:
                    click(intro._event_button)
                    if parts[1] == "supplies": click(intro._activity_view.continue_button)
                    elif parts[1] == "recovery":
                        click(intro._activity_view.action_button)
                        var effect: Control = intro.canvas.get_child(intro.canvas.get_child_count()-1)
                        check(effect.kind == "practice","Shared tutorial does not assign a recovery mode")
                        await intro.practice_event_completed
                    elif parts[1] == "ending": click(intro._activity_view.action_button)
                if is_instance_valid(intro.modal): key(KEY_ESCAPE)
                check(intro.bridge.get_state() == state_before,"Event practice preserves the actual game state: "+parts[1])
            elif parts[0] == "resource":
                click(intro.hud.resource_buttons[parts[1]])
            else:
                check(not intro.menu_button.visible,"No duplicate hamburger in the tutorial")
                if intro.station_rail.buttons.has(parts[1]):
                    check(intro.station_rail.buttons[parts[1]].get_theme_stylebox("normal").border_color == intro.GOLD,"The primary target is highlighted")
                    click(intro.station_rail.buttons[parts[1]])
                else:
                    check(intro.station_rail.utility_buttons.more.get_theme_stylebox("normal").border_color == intro.GOLD,"More highlights a secondary target")
                    click(intro.station_rail.utility_buttons.more)
                    click(intro._menu_view.buttons["messages" if parts[1] == "letters" else parts[1]])
                check(intro.modal_kind == "section:" + parts[1], "Real HUD button opens its panel")
                check(is_instance_valid(intro.modal), "Panel is visible")
                if parts[1] == "upgrades":
                    check(intro._progression_view._nodes.size() == 12, "All twelve upgrades are drawn")
                    check(intro._progression_view._lines.size() == 8, "Prerequisite connections are drawn")
                    click(intro._progression_view._nodes["panel_extra"])
                    check(intro._progression_view._buy.disabled, "Training cannot purchase upgrades")
                    check(not intro._progression_view._detail.text.begins_with("upgrades."), "Upgrade labels are translated")
                elif parts[1] == "missions":
                    check(intro._progression_view._buttons.size() == 16, "All sixteen missions are drawn")
                    intro._progression_view._select("mision_16")
                    check(not intro._progression_view._objectives.text.begins_with("misiones."), "Mission objectives are translated")
                if is_instance_valid(intro._activity_view):
                    var activity = intro._activity_view
                    var state_before: Dictionary = intro.bridge.get_state()
                    match parts[1]:
                        "rest":
                            click(activity._return)
                            check(activity.near_dome,"Recharge first returns to the dome")
                            click(activity._charge)
                            await activity.completed
                            check(activity.battery == 100,"Recharge practice shows the battery filling")
                        "letters":
                            await process_frame
                            click(activity.reader._scroll.get_child(0).get_child(0))
                        "construction":
                            check(activity._module_buttons[1].find_children("*","TextureRect",true,false).size() == 1,"Choose a picture before placing its 3D hologram")
                            click(activity._module_buttons[1])
                            await place_practice(activity,Vector3(-8,0,16))
                            check(activity.placed.get_child_count() == 1, "Practice places a real 3D module with the shared hologram")
                            click(activity._module_buttons[2])
                            await place_practice(activity,Vector3(4,0,16))
                            check(activity._placed_module == 2, "Another module can be placed using the same controls")
                        "expedition":
                            click(activity._zone_buttons[1])
                            click(activity._scan_button)
                            check(activity._scanning and activity._collect_button.disabled, "Radar scan runs before collection unlocks")
                            await activity._radar.completed
                            check(activity._scanned.has(1), "A map zone can be scanned")
                            click(activity._collect_button)
                        "processing":
                            click(activity._process_buttons[2])
                            check(activity._process_step == 0, "Processing cannot skip steps")
                            for button in activity._process_buttons: click(button)
                            check(activity._process_step == 3, "Ice processing demo completes")
                            await process_frame
                            check(activity._feedback.position.y + activity._feedback.size.y <= activity.size.y - 62, "Processing feedback stays above reset button")
                        "repair":
                            for button in activity._patch_buttons: click(button)
                            check(activity._patched.size() == 3, "Three shield spots can be repaired")
                            activity._reset_repair()
                            await create_timer(0.35).timeout
                            check(activity._shield_bar.value == activity.initial_shield and activity._patched.is_empty(), "Reset cancels pending repair animation")
                        "science":
                            for card_index in range(4):
                                activity._choose_card(card_index, false)
                                await process_frame
                                check(activity._card_fact.position.y + activity._card_fact.size.y <= activity._counter.position.y - 6, "Science fact fits above pin controls")
                            click(activity._pin_cards[1])
                            click(activity._pin_button)
                            check(activity._pins.has(1), "A discovery can be pinned to the board")
                            click(activity._pin_button)
                            check(not activity._pins.has(1), "A discovery can be unpinned")
                            activity._pin_card()
                            intro._open_section("science")
                            check(intro._activity_view._pins.has(1), "Pinned discoveries survive closing and reopening the board")
                    check(intro.bridge.get_state() == state_before, "Visual demonstrations leave game state unchanged")
                key(KEY_ESCAPE)
                check(intro.modal_kind.is_empty(), "Esc closes game panel")
            check(not intro.primary_button.disabled, "Action unlocks Continue")
        check(not intro.spoken_text.contains("{name}"), "Narration resolves placeholders")
        check(intro.dialogue_label.position.y + intro.dialogue_label.size.y <= intro.primary_button.position.y - 10, "Dialogue stays above navigation buttons: " + before)
        if before == "base":
            check(intro.hud.visible, "Four-resource HUD appears")
            check(intro.hud.resource_buttons.size() == 5, "HUD exposes the same five bars as live play")
            check(intro.station_rail.visible and intro.station_rail.position.y > 600, "The same bottom dock appears with the HUD")
            intro.hud.set_state({"energia":{"value":120.0,"max":150.0}})
            check(intro.hud.values.energia.text == "80%", "Bar percentage respects upgraded capacity")
            var last_y := -1.0
            for resource_id in intro.hud.bars:
                check(intro.hud.resource_buttons[resource_id].position.x == 6 and intro.hud.resource_buttons[resource_id].position.y > last_y,"All five resources share the approved column")
                last_y = intro.hud.resource_buttons[resource_id].position.y
                var bar: ProgressBar = intro.hud.bars[resource_id]
                check(bar.position.y + bar.size.y <= intro.hud.resource_buttons[resource_id].size.y, "Resource bar fits inside its card")
            intro.hud.set_state(intro.bridge.get_state())
            check(intro.bridge.get_state().estrellas == 0, "Practice does not award real stars")
        check(intro.tutorial.player.age_group.is_empty() and intro.nickname.is_empty(),"Tutorial does not ask for personal data or choose a mode: "+before)
        click(intro.primary_button)
        check(intro.step != before, "Continue advances: " + before)
    check(intro.step == "done", "Tutorial reaches confirmation")
    if intro._transitioning: await intro.profile_setup_entered
    check(intro._in_profile and is_instance_valid(intro.setup_screen),"Tutorial finishes before the profile screen")
    check(intro.setup_screen.avatar.get_child(0).transparent_bg,"The supplied robot model keeps a transparent profile preview")
    check(intro.setup_screen.avatar._model.scene_file_path == "res://assets/3d/robot_humanoide.tscn","Profile reuses the supplied 3D model")
    check(intro.setup_screen.continue_button.disabled,"A call sign and age are required after training")
    intro.setup_screen.name_field.text = "Alex"
    intro.setup_screen.name_field.text_changed.emit("Alex")
    click(intro.setup_screen.age_buttons[test_case.age])
    click(intro.setup_screen.continue_button)
    if intro._transitioning: await intro.home_entered
    check(intro._in_home and intro.tutorial.player.mode_id() == test_case.mode,"Profile selects the correct mode before home")
    check(not intro.hud.visible and not intro.menu_button.visible, "Home menu has no game HUD")
    check(starts.size() == starts_before, "Completing tutorial does not start a game")
    check(intro.home_screen._greeting.position.y + intro.home_screen._greeting.size.y <= intro.home_screen.play_button.position.y - 8, "Home greeting stays above the buttons")
    check(intro.home_screen.play_button.text == intro.tr("home.play"), "First visit offers Play")
    click(intro.home_screen.options_button)
    check(intro.modal_kind == "nav:settings","Options opens the shared Settings page")
    click(intro._menu_view.buttons.audio)
    check(intro.modal_kind == "audio", "Sound and narration opens its controls")
    key(KEY_TAB)
    check(root.gui_get_focus_owner() == intro.audio_toggle, "Modal traps Tab focus")
    key(KEY_ESCAPE)
    check(intro.modal_kind.is_empty(), "Esc closes audio panel")
    click(intro.home_screen.play_button)
    click(intro.home_screen.play_button)
    if intro._transitioning: await intro.expedition_entered
    check(intro._in_expedition and is_instance_valid(intro.play_screen), "Play fades into the base preview")
    check(intro.play_screen._goal.position.y + intro.play_screen._goal.size.y <= 676, "Welcome message fits above the footer")
    check(starts.size() == starts_before + 1, "Repeated Play input starts the game once")
    check(starts[-1].mode == test_case.mode and starts[-1].age_group == test_case.age, "Canonical profile is emitted")
    check(starts[-1].nickname == "Alex" and starts[-1].tutorial_completed, "Completion includes name and status")
    check(fake.last_language == test_case.language, "Voice uses the selected language")
    var original_play_id: int = intro.play_screen.get_instance_id()
    var original_state: Dictionary = intro.bridge.get_state()
    click(intro.play_screen._review)
    if intro._transitioning: await intro.home_entered
    check(intro._in_home and pauses == [true], "Back to menu requests a pause")
    check(intro.home_screen.play_button.text == intro.tr("home.resume"), "Returning home offers Resume game")
    click(intro.home_screen.tutorial_button)
    check(intro.step == "landing", "Watch tutorial again repeats the landing")
    click(intro.primary_button)
    check(intro.step == "arrival" and intro.nickname == "Alex", "Review keeps the existing profile")
    intro.step = "ready"
    intro._render(false)
    click(intro.primary_button)
    if intro._transitioning: await intro.home_entered
    check(starts.size() == starts_before + 1, "Review cannot emit a duplicate start")
    click(intro.home_screen.play_button)
    if intro._transitioning: await intro.expedition_entered
    check(intro.play_screen.get_instance_id() == original_play_id, "Resume preserves the same play scene")
    check(intro.bridge.get_state() == original_state, "Resume preserves resource state")
    check(pauses == [true, false] and resumes.size() == 1, "Resume emits the unpause contract")
    check(starts.size() == starts_before + 1, "Resume does not restart the game")
    completed_flows += 1
    intro.queue_free()
    await process_frame

func test_bridge() -> void:
    var bridge := Bridge.new()
    root.add_child(bridge)
    var bus := FakeBus.new()
    root.add_child(bus)
    bridge.bind_state(bus)
    bridge.recovery_requested.connect(func(policy: String, _data: Dictionary): recoveries.append(policy))
    bus.recurso_actualizado.emit("energia", 0.0, 100.0)
    check(recoveries.is_empty(), "Training cannot trigger live recovery")
    check(bridge.get_state().energia.value == 60.0, "Practice snapshot is isolated from live state")
    bus.recurso_actualizado.emit("energia", 60.0, 100.0)
    bridge.begin_live({"mode":"cadete", "nickname":"Alex"})
    bus.recurso_actualizado.emit("energia", 0.0, 100.0)
    bus.recurso_actualizado.emit("energia", 0.0, 100.0)
    check(recoveries == ["checkpoint"], "Energy zero requests checkpoint only once")
    bus.recurso_actualizado.emit("energia", 100.0, 100.0)
    bridge.configure_profile({"mode":"ingeniero", "nickname":"Alex"})
    bus.recurso_actualizado.emit("oxigeno", 0.0, 100.0)
    check(recoveries == ["checkpoint", "restart"], "Engineer crew oxygen zero requests full restart")
    check(bus.oxigeno == 100.0 and bus.energia == 60.0, "UI never writes simulation state")
    bus.recurso_actualizado.emit("energia", 120.0, 150.0)
    check(bridge.get_state().energia.max == 150.0, "Energy maximum is dynamic")
    bus.mision_completada.emit("mision_01", 1, {})
    check(bridge.get_state().estrellas == 0, "Mission reward is not counted twice")
    bus.estrellas_actualizadas.emit(1)
    check(bridge.get_state().estrellas == 1, "Authoritative stars update the HUD")
    var scene := PackedScene.new()
    var node := Control.new()
    node.set_script(load("res://ui/tests/panel_fixture.gd"))
    scene.pack(node)
    node.free()
    bridge.register_panel("upgrades", scene)
    bridge.training = true
    var panel := bridge.instantiate_panel("upgrades")
    check(panel != null and panel.training, "Injected panel gets read-only training context")
    root.add_child(panel)
    check(panel.ready_saw_training, "Context is set before panel ready")
    panel.queue_free()
    bridge.queue_free()
    bus.queue_free()
    await process_frame

func test_catalog_and_purchases() -> void:
    var catalog = load("res://ui/progression_catalog.gd").new()
    catalog.upgrades_path = "res://missing_upgrades.json"
    catalog.missions_path = "res://missing_missions.json"
    check(catalog.upgrades(true).size() == 12 and catalog.missions(true).size() == 16, "Training has complete preview metadata")
    check(catalog.upgrades(false).is_empty() and catalog.missions(false).is_empty(), "Preview data never pretends to be live")
    catalog.set_data(
        {"arbol_habilidades":{"ramas":[{"id":"energia","mejoras":[{"id":"custom_upgrade","nivel":1,"costo":7,"requisito":null}]}]}},
        {"misiones":[{"id":"custom_mission","puntos":{"cadete":3,"ingeniero":4}}]}
    )
    check(catalog.upgrades(false)[0].costo == 7 and catalog.missions(false)[0].id == "custom_mission", "Injected JSON overrides preview metadata")
    catalog = load("res://ui/progression_catalog.gd").new()
    var view = load("res://ui/upgrade_tree.gd").new()
    view.size = Vector2(884, 456)
    view.configure(catalog.upgrades(true), {"stars":3,"unlocked_upgrades":[]}, false, "cadete")
    root.add_child(view)
    var requests: Array[String] = []
    view.purchase_requested.connect(func(id: String): requests.append(id))
    view._select("panel_extra")
    check(not view._buy.disabled, "Affordable first upgrade is available")
    click(view._buy)
    check(requests == ["panel_extra"], "Buy sends an intent to progression")
    check(not view._owned("panel_extra"), "UI cannot grant its own upgrade")
    view._select("bateria_modular")
    check(view._buy.disabled, "Prerequisite gates the next upgrade")
    view.set_progression_state({"stars":3,"unlocked_upgrades":["panel_extra"]})
    check(not view._buy.disabled, "Authoritative unlock enables the dependent upgrade")
    view.queue_free()
    await process_frame

func place_practice(activity: Control, point: Vector3) -> void:
    var viewport: SubViewport = activity.world_view.viewport
    var pos: Vector2 = activity.world_view.camera.unproject_position(point)
    var motion := InputEventMouseMotion.new()
    motion.position = pos
    motion.global_position = pos
    viewport.push_input(motion,true)
    await physics_frame
    await physics_frame
    var press := InputEventMouseButton.new()
    press.position = pos
    press.global_position = pos
    press.button_index = MOUSE_BUTTON_LEFT
    press.pressed = true
    viewport.push_input(press,true)
    await physics_frame

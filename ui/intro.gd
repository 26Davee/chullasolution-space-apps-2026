extends Control
## A guided lesson running the actual integrated game with independent in-memory state.
signal mission_requested(profile: Dictionary)
signal home_entered()
const UI = preload("res://ui/ui_kit.gd")
const STEPS = preload("res://ui/tutorial_steps.gd").IDS
const RESOURCE_IDS := {"energy":"energia","water":"agua","oxygen":"oxigeno","shield":"escudo","robot":"energia_robot"}
var language := "en"
var auto_start_tutorial := true
var launch_direct_to_game := false
var game: Node3D
var state: Node
var voice: Node
var canvas: Control
var coach: Control
var bubble: Panel
var portrait: TextureRect
var dialogue_label: Label
var primary_button: Button
var back_button: Button
var repeat_button: Button
var skip_button: Button
var index := 0
var step: String:
    get: return STEPS[index]
var stage := 0
var done := false
var _last_hint := ""
var _last_actions: Dictionary = {}
var _notice_opened := false
var _notice_pending := false
var _step_revision := 0
var _recovery: Control
var _transitioning := false
var _water_before := 0.0
var _shield_before := 0.0
var _battery_before := 0.0
var _completed_steps: Dictionary = {}
var _settings_seen := false
var _settings_visited: Dictionary = {}
var _awaiting_solve := false
var _focused_target := 0
var _profile: Dictionary = {}
var _recovery_demos: Dictionary = {}
var _recovery_buttons: Dictionary = {}
var _recovery_continue: Button
var _progress: Label
func apply_profile_dict(profile: Dictionary) -> void:
    # Profile belongs to the menu. The common lesson never assigns name or mode.
    _profile = profile.duplicate(true)
    language = str(profile.get("language",language))
func _ready() -> void:
    mouse_filter = MOUSE_FILTER_IGNORE
    UI.register_translations()
    TranslationServer.set_locale(language)
    state = preload("res://ui/tutorial_state.gd").new()
    state.idioma = language
    var preferences: Dictionary = get_node("/root/GameState").preferencias
    for key in ["voice_enabled","voice_volume","voice_rate","voices"]:
        if preferences.has(key): state.preferencias[key] = preferences[key]
    state.voz_activa = bool(preferences.get("voice_enabled",true))
    add_child(state)
    game = load("res://scenes/juego.tscn").instantiate()
    game.set_script(preload("res://ui/tutorial_game.gd"))
    game.lesson_state = state
    add_child(game)
    game.lesson_action.connect(_on_action)
    game.salir_al_menu.connect(_leave_notice)
    var layer := CanvasLayer.new()
    layer.layer = 50
    add_child(layer)
    canvas = Control.new()
    canvas.size = Vector2(1280,720)
    canvas.mouse_filter = MOUSE_FILTER_IGNORE
    layer.add_child(canvas)
    coach = preload("res://ui/tutorial_coach.gd").new()
    canvas.add_child(coach)
    portrait = TextureRect.new()
    portrait.texture = load("res://assets/ui/timmy.png")
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.position = Vector2(32,434)
    portrait.size = Vector2(170,190)
    portrait.mouse_filter = MOUSE_FILTER_IGNORE
    canvas.add_child(portrait)
    bubble = UI.panel(canvas,Rect2(212,464,650,158),Color("#071b32fa"),20)
    bubble.mouse_filter = MOUSE_FILTER_STOP
    UI.label(bubble,"Timmy",Rect2(18,8,90,28),21,UI.GOLD,true)
    _progress = UI.label(bubble,"",Rect2(520,10,110,24),15,UI.CYAN,true)
    _progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    dialogue_label = UI.label(bubble,"",Rect2(18,42,614,64),19,UI.WHITE)
    back_button = UI.button(bubble,tr("v2.back"),Rect2(18,114,92,34),_back)
    repeat_button = UI.button(bubble,tr("v2.repeat"),Rect2(120,114,108,34),_repeat)
    primary_button = UI.button(bubble,tr("v2.next"),Rect2(502,112,130,36),_advance,true)
    for button in [back_button,repeat_button,primary_button]:
        button.add_theme_font_size_override("font_size",16)
        for state_name in ["normal","hover","pressed","focus","disabled"]:
            var box = button.get_theme_stylebox(state_name).duplicate()
            box.content_margin_left = 6
            box.content_margin_right = 6
            button.add_theme_stylebox_override(state_name,box)
    skip_button = UI.button(canvas,tr("lesson.skip"),Rect2(310,18,90,32),_finish)
    skip_button.add_theme_font_size_override("font_size",14)
    await get_tree().process_frame
    await get_tree().process_frame
    voice = game._voice
    for button in game._hud.resource_buttons.values():
        button.mouse_filter = MOUSE_FILTER_IGNORE
        button.focus_mode = FOCUS_NONE
        button.mouse_default_cursor_shape = CURSOR_ARROW
    game._hud._timmy_btn.pressed.connect(_repeat)
    _show_step()
func _show_step() -> void:
    _step_revision += 1
    _notice_pending = false
    stage = 0
    done = _completed_steps.has(step)
    _last_actions.clear()
    if game.ice.phase != "idle": game.ice.cancel()
    if state.energia < 40: state.fijar_recurso("energia",60)
    _notice_opened = false
    _settings_seen = false
    _settings_visited.clear()
    _awaiting_solve = false
    _last_hint = ""
    game.training_alert = step == "alerts" and not done
    game._hud.set_storm_alert(false)
    if is_instance_valid(voice): voice.stop()
    game._close_drawer()
    if is_instance_valid(game._modal_layer): game._close_modal()
    if game.placement_system.is_placing(): game.placement_system.cancel_placement()
    back_button.disabled = index == 0
    primary_button.text = tr("tutorial.yes") if step == "ready" else tr("v2.next")
    var passive := step in ["arrival","base","cycle","ready"] or RESOURCE_IDS.has(step)
    if passive: done = true
    if step == "expedition":
        game.ice.discovered = ["crater"]
        game.ice.selected = "crater"
        game.ice.stock = {"crater":18,"ridge":24,"basin":30}
    if step == "repair":
        state.fijar_recurso("escudo",65)
        _shield_before = state.escudo
    if step == "recharge":
        state.energia_robot = 45
        game._hud.set_state(game._bridge.get_state())
        _battery_before = state.energia_robot
    if step == "processing":
        state.fijar_recurso("agua",20)
        state.hielo = maxi(3,state.hielo)
        _ensure_processor()
        _water_before = state.agua
    if step == "alerts":
        game.training_alert = true
        state.fijar_recurso("agua",5)
        state.hielo = maxi(3,state.hielo)
        _water_before = state.agua
        _ensure_processor()
        game.session.add_message("training:water","resource",{"resource":"agua"})
        game._hud.set_unread_count(game.session.unread_count())
        game._hud.set_storm_alert(true,tr("hud.agua.nombre"),tr("tutorial.alert_body"))
    if step == "letters":
        game.session.add_message("training:letter","text",{"text":tr("tutorial.letter_body")})
        game._refresh_mail_badge()
    if step == "cycle":
        state.tiempo_juego = 360
        state.es_dia = false
        game._hud.set_state(game._bridge.get_state())
    else:
        state.tiempo_juego = 0
        state.es_dia = true
    if step in ["supplies","recovery","ending"] and not done: _auto_notice(step)
    _refresh_guide()
func _ensure_processor() -> void:
    if state.procesador_instalado: return
    var model = load("res://assets/3d/procesador_hielo.tscn").instantiate()
    game.estructuras_colocadas.add_child(model)
    model.set_meta("piece_id",&"procesador_hielo")
    model.position = Vector3(-10,0,0)
    state.procesador_instalado = true
func _on_action(action: String, payload: Dictionary) -> void:
    _last_actions[action] = payload
    match step:
        "construction":
            if action == "build_module": stage = 1
        "expedition":
            if action == "scan_ice": stage = 1
            if action == "select_ice_zone" and stage >= 1: stage = 2
            if action == "start_ice" and stage >= 2: stage = 3
            if action == "cancel_ice": stage = 2
        "controls":
            if action == "open_section" and payload.get("id") == "settings:controls": _complete()
        "missions":
            if action == "dock" and payload.get("id") == "missions": _complete()
        "settings":
            if action == "open_section" and str(payload.get("id","")).begins_with("settings:"):
                _settings_seen = true
                _settings_visited[str(payload.id)] = true
        "letters":
            if action == "read_message" and payload.get("id") == "training:letter": _complete()
        "upgrades":
            if action == "buy_upgrade" and state.obtener_save_manager().esta_mejora_comprada(str(payload.id)): _complete()
        "science":
            if action == "speak": _complete()
        "alerts":
            if action == "guide_alert":
                _awaiting_solve = true
                game._open_section_drawer("processing")
    if action == "leave":
        if step == "ending": _leave_notice()
        else: _finish()
func _complete() -> void:
    done = true
    _completed_steps[step] = true
func _process(_delta: float) -> void:
    if not is_instance_valid(game) or not game._session_ready or _transitioning: return
    if is_instance_valid(voice): language = state.idioma
    var factor := minf(size.x/1280.0,size.y/720.0)
    canvas.scale = Vector2.ONE*factor
    canvas.position = (size-Vector2(1280,720)*factor)/2
    canvas.visible = not game._landing_active and is_visible_in_tree()
    if not canvas.visible: return
    if step == "construction" and stage == 1 and game.estructuras_colocadas.get_children().any(func(node): return str(node.get_meta("piece_id","")) == "panel_solar"): _complete()
    if step == "expedition" and stage >= 3 and game.ice.phase == "idle" and state.hielo > 0: _complete()
    if step == "expedition" and stage >= 3 and game.ice.phase == "idle" and state.hielo == 0: stage = 2
    if step in ["supplies","recovery","ending"] and not done and not _notice_opened and not _notice_pending and not is_instance_valid(game._modal_layer): _auto_notice(step)
    if step == "recovery" and _notice_opened and not done and not is_instance_valid(game._modal_layer):
        _notice_opened = false
        _auto_notice("recovery")
    if step == "processing" and state.agua > _water_before and game._action.is_empty(): _complete()
    if step == "repair" and state.escudo > _shield_before and game._action.is_empty(): _complete()
    if step == "recharge" and state.energia_robot >= 99: _complete()
    if step == "alerts" and _awaiting_solve and state.agua > _water_before and game._action.is_empty():
        game.training_alert = false
        game._hud.set_storm_alert(false)
        _complete()
    if step == "settings" and _settings_visited.has("settings:language") and _settings_visited.has("settings:audio") and not game._drawer.visible: _complete()
    if step in ["supplies","ending"] and _notice_opened and not is_instance_valid(game._modal_layer): _complete()
    _refresh_guide()
func _find_button(text: String, parent: Node = null) -> Control:
    var host: Node = parent if parent != null else game._drawer
    for button in host.find_children("*","Button",true,false):
        if button.is_queued_for_deletion(): continue
        if button.is_visible_in_tree() and (button.text == text or button.tooltip_text == text):
            return button
    return null
func _refresh_guide() -> void:
    if not game._session_ready or game._landing_active: return
    var target: Control
    var text := tr("tutorial."+step) if RESOURCE_IDS.has(step) else tr("lesson."+step)
    var drawer: Panel = game._drawer
    var open := drawer.visible
    var kind: String = drawer.kind if open else ""
    if done and not (RESOURCE_IDS.has(step) or step in ["arrival","base","cycle","ready"]):
        text = tr("lesson.close")
        if is_instance_valid(game._modal_layer): target = _find_button(tr("live.continue"),game._modal_layer)
        elif open: target = drawer.get_node("Header/CloseButton")
        else: target = primary_button
    elif RESOURCE_IDS.has(step):
        target = game._hud.resource_buttons[RESOURCE_IDS[step]]
    else:
        match step:
            "controls","settings":
                if not open: target = game._hud._settings_btn
                elif kind == "settings":
                    if step == "controls": target = _find_button(tr("live.help"))
                    elif not _settings_visited.has("settings:language"): target = _find_button(tr("live.settings_lang"))
                    elif not _settings_visited.has("settings:audio"): target = _find_button(tr("live.settings_audio"))
                    else:
                        target = drawer.get_node("Header/CloseButton")
                        text = tr("lesson.close")
                elif step == "settings" and kind == "settings:language":
                    target = _find_button(tr("live.back_settings"))
                elif step == "settings" and kind == "settings:audio":
                    target = _find_button(tr("live.audio_back"))
            "construction":
                if stage == 0:
                    target = _find_button("") if kind == "construction" else game._hud.dock_buttons.construction
                    if kind == "construction": target = drawer.find_child("Module_panel_solar",true,false)
                elif game.placement_system.is_placing():
                    text = tr("lesson.pick")
                else:
                    stage = 0
            "expedition":
                if not open or kind != "expedition": target = game._hud.dock_buttons.expedition
                elif stage == 0:
                    text = tr("lesson.scan")
                    target = _find_button(tr("live.ice_scan_btn"))
                elif stage == 1:
                    text = tr("lesson.zone")
                    target = _find_button(tr("guide.zone_ridge"))
                elif stage == 2:
                    text = tr("lesson.start")
                    target = _find_button(tr("guide.retry") if game.ice.phase == "blocked" else tr("live.ice_start_btn"))
                else:
                    text = tr("lesson.wait")
                    if game.ice.phase == "blocked": target = _find_button(tr("guide.retry"))
            "processing":
                if not game._action.is_empty(): text = tr("lesson.wait")
                elif kind == "processing": target = _find_button(tr("live.process_start_btn"))
                elif kind == "more": target = _find_button(tr("live.processing"))
                else: target = game._hud.dock_buttons.more
            "repair","recharge":
                if not game._action.is_empty() or state.descansando_en_domo: text = tr("lesson.wait")
                elif game._world_callout.visible:
                    text = tr("lesson.repair" if step == "repair" else "lesson.charge")
                    for button in game._world_callout._buttons_row.get_children():
                        if button is Button and not button.is_queued_for_deletion(): target = button
                elif step == "repair": target = game._hud.dock_buttons.repair
                elif kind == "more": target = _find_button(tr("live.rest"))
                else: target = game._hud.dock_buttons.more
            "missions": target = game._hud.dock_buttons.missions
            "alerts":
                if _awaiting_solve:
                    text = tr("lesson.wait") if not game._action.is_empty() else tr("lesson.solved") if done else tr("lesson.processing")
                    if kind == "processing": target = _find_button(tr("live.process_start_btn"))
                    elif kind == "more": target = _find_button(tr("live.processing"))
                    else: target = game._hud.dock_buttons.more
                elif kind == "messages": target = _find_button(tr("lesson.solve"))
                else: target = game._hud._storm_btn
            "recovery":
                if is_instance_valid(game._modal_layer):
                    target = _recovery_buttons.get("cadet" if not _recovery_demos.has("cadet") else "engineer") if _recovery_demos.size() < 2 else _recovery_continue
            "ending":
                if is_instance_valid(game._modal_layer): target = _find_button(tr("live.home"),game._modal_layer)
            "supplies":
                if is_instance_valid(game._modal_layer): target = _find_button(tr("live.continue"),game._modal_layer)
            "letters","upgrades","science":
                var section: String = {"letters":"messages"}.get(step,step)
                if kind == section:
                    if step == "letters": target = _find_button(tr("tutorial.letter_body"))
                    elif step == "upgrades":
                        target = _find_button(tr("live.upgrades_unlock"))
                        text = tr("lesson.upgrade")
                    else:
                        target = _find_button(tr("live.science_listen"))
                        text = tr("lesson.listen")
                elif kind == "more": target = _find_button(tr("live."+section))
                else: target = game._hud.dock_buttons.more
    var modal_open := is_instance_valid(game._modal_layer)
    if modal_open and step == "recovery": text = tr("coach.recovery")
    if modal_open and step == "supplies": text = tr("coach.reward")
    if modal_open and step == "ending": text = tr("visual.ending_hint")
    if done and not open and not modal_open and not RESOURCE_IDS.has(step) and step not in ["arrival","base","cycle","ready"]:
        text = tr("visual.continue_hint")
    if step == "alerts" and done: text = tr("lesson.solved")
    back_button.text = tr("v2.back")
    repeat_button.text = tr("v2.repeat")
    skip_button.text = tr("lesson.skip")
    primary_button.text = tr("tutorial.yes" if step == "ready" else "v2.next")
    dialogue_label.text = text
    _layout_dialogue(modal_open)
    _progress.text = str(index+1)+" / "+str(STEPS.size())
    bubble.tooltip_text = tr("lesson.training")+" · "+str(index+1)+"/"+str(STEPS.size())
    primary_button.disabled = not done
    coach.point_at(target,"",false,false)
    if is_instance_valid(target) and target.focus_mode != FOCUS_NONE and not (target is BaseButton and target.disabled):
        var id := target.get_instance_id()
        if id != _focused_target:
            _focused_target = id
            target.grab_focus()
    if _last_hint != text:
        _last_hint = text
        if is_instance_valid(voice): voice.speak(text,language)
func _advance() -> void:
    if not done or _transitioning: return
    if step == "ready":
        _finish()
        return
    index += 1
    _show_step()
func _back() -> void:
    if index <= 0 or _transitioning: return
    index -= 1
    _show_step()
func _repeat() -> void:
    if is_instance_valid(voice): voice.speak(dialogue_label.text,language)
func _leave_notice() -> void:
    if is_instance_valid(game._modal_layer): game._close_modal()
    game.session.finished = false
    _complete()
func _auto_notice(expected: String) -> void:
    if _notice_pending: return
    _notice_pending = true
    var revision := _step_revision
    await get_tree().create_timer(1.0).timeout
    if revision != _step_revision: return
    _notice_pending = false
    if not is_inside_tree() or step != expected or done or _transitioning or is_instance_valid(game._modal_layer): return
    _notice_opened = true
    if expected == "supplies":
        var sm: Node = state.obtener_save_manager()
        sm.registrar_mision_completada("mision_01",3,"carta_mision_01")
        game.session.inventory["panel_solar"] = int(game.session.inventory.get("panel_solar",0))+1
        game._open_reward({"id":"mision_01","stars":3,"supplies":{"panel_solar":1}})
    elif expected == "recovery":
        _open_recovery()
    else:
        var sm: Node = state.obtener_save_manager()
        for mission in game.session.mm.obtener_todas_las_misiones():
            if not sm.esta_mision_completada(str(mission.id)): sm.registrar_mision_completada(str(mission.id),1,"carta_"+str(mission.id))
        game._open_victory()
func _open_recovery() -> void:
    var panel: Control = game._open_modal("training_recovery",tr("recovery.title"),Vector2(800,460))
    (panel.get_child(1) as Button).hide()
    _recovery_demos.clear()
    _recovery_buttons.clear()
    UI.label(panel,tr("recovery.trigger"),Rect2(28,74,744,36),20,UI.GOLD,true)
    var result = UI.label(panel,tr("recovery.battery"),Rect2(28,334,744,48),17,UI.CYAN)
    var continue_btn = UI.button(panel,tr("live.continue"),Rect2(516,394,256,42),func():
        game._close_modal()
        _complete()
    ,true)
    _recovery_continue = continue_btn
    continue_btn.disabled = true
    for i in 2:
        var id: String = ["cadet","engineer"][i]
        var card = UI.panel(panel,Rect2(28+i*382,124,362,194),Color("#15364d"),16)
        UI.label(card,tr("recovery."+id+".title"),Rect2(16,12,330,34),22,UI.WHITE,true)
        UI.label(card,tr("recovery."+id+".short"),Rect2(16,56,330,86),19,UI.WHITE)
        var button = UI.button(card,tr("recovery."+id+".demo"),Rect2(16,148,330,36),func():
            _recovery_demos[id] = true
            result.text = tr("recovery."+id+".result")
            voice.speak(result.text,language)
            var tween = create_tween()
            tween.tween_property(card,"modulate:a",0.3,0.2)
            tween.tween_property(card,"modulate:a",1.0,0.3)
            continue_btn.disabled = _recovery_demos.size() != 2
        ,true)
        _recovery_buttons[id] = button
        button.name = "Recovery_"+id
        button.add_theme_font_size_override("font_size",15)
func _finish() -> void:
    if _transitioning: return
    _transitioning = true
    if is_instance_valid(voice): voice.stop()
    game.set_paused(true)
    var fade := ColorRect.new()
    fade.color = Color.BLACK
    fade.modulate.a = 0
    fade.size = Vector2(1280,720)
    fade.mouse_filter = MOUSE_FILTER_STOP
    fade.z_index = 100
    canvas.add_child(fade)
    var tween := create_tween()
    tween.tween_property(fade,"modulate:a",1.0,0.35)
    await tween.finished
    home_entered.emit()
func _exit_tree() -> void:
    if is_instance_valid(voice): voice.stop()

func _layout_dialogue(modal_open: bool) -> void:
    # Measure wrapped text before positioning its footer; translations can use more lines.
    var font_size := 15 if modal_open else 19
    var text_width := 172.0 if modal_open else 614.0
    dialogue_label.add_theme_font_size_override("font_size",font_size)
    dialogue_label.size.x = text_width
    var font := dialogue_label.get_theme_font("font")
    var line_height := font.get_height(font_size) + 3.0
    var text_height := ceilf(maxf(dialogue_label.get_minimum_size().y,dialogue_label.get_line_count()*line_height)) + 4.0
    var height := maxf(206.0 if modal_open else 158.0,text_height+104.0)
    bubble.position = Vector2(16 if modal_open else 212,626.0-height)
    bubble.size = Vector2(208 if modal_open else 650,height)
    dialogue_label.size = Vector2(text_width,text_height)
    portrait.position = Vector2(52 if modal_open else 32,bubble.position.y-186 if modal_open else bubble.position.y-30)
    var footer_y := height-46.0
    for button in [back_button,repeat_button,primary_button]:
        button.position.y = footer_y
        button.add_theme_font_size_override("font_size",13 if modal_open else 16)
    back_button.visible = not modal_open
    back_button.position.x = 14 if modal_open else 18
    back_button.size.x = 70 if modal_open else 92
    repeat_button.position.x = 12 if modal_open else 120
    repeat_button.size.x = 86 if modal_open else 108
    primary_button.position.x = 104 if modal_open else 502
    primary_button.size.x = 96 if modal_open else 130
    _progress.position.x = 90 if modal_open else 520

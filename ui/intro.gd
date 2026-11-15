extends Control

signal mission_requested(profile: Dictionary)
signal recovery_requested(policy: String, profile: Dictionary)
signal expedition_entered()
signal home_entered()
signal restart_requested(profile: Dictionary)
signal practice_event_completed(action: String)
signal profile_setup_entered()
signal pause_requested(paused: bool)
signal resume_requested(profile: Dictionary)

const UI = preload("res://ui/ui_kit.gd")
const Tutorial = preload("res://ui/tutorial_controller.gd")
const StepData = preload("res://ui/tutorial_steps.gd")

@export_file("*.json") var upgrades_json_path := "res://data/missions/upgrades.json"
@export_file("*.json") var missions_json_path := "res://data/missions/missions.json"
@export var upgrades_panel_scene: PackedScene
@export var missions_panel_scene: PackedScene
@export var science_panel_scene: PackedScene
@export var game_state_path := NodePath("/root/GameState")
@export_file("*.tscn", "*.glb", "*.gltf") var astronaut_model_path := "res://assets/3d/robot_humanoide.tscn"
@export_range(0.01, 5.0) var astronaut_model_scale := 1.0

const DESIGN := Vector2(1280, 720)
const STEPS = StepData.IDS
const BG = preload("res://assets/ui/moon_base.png")
const TIMMY = preload("res://assets/ui/timmy.png")
const INK = UI.INK
const GOLD = UI.GOLD
const CYAN = UI.CYAN
const WHITE = UI.WHITE

var tutorial = Tutorial.new()
var step: String:
    get: return tutorial.step_id
    set(value): tutorial.step_id = value
var nickname: String:
    get: return tutorial.player.nickname
    set(value): tutorial.player.nickname = value
var selected_mode: String:
    get: return "engineer" if tutorial.player.mode_id() == "ingeniero" else "cadet"
var catalog = preload("res://ui/progression_catalog.gd").new()
var station_rail: Control
var world_view: Control
var _progression_view: Control
var bridge: Node
var hud: Control
var _gate_hint: Label
var _age_buttons: Dictionary = {}
var _start_emitted := false
var _skip_requested := false
var _transitioning := false
var _in_expedition := false
var _in_home := false
var _in_profile := false
var setup_screen: Control
var home_screen: Control
var play_screen: Control
var menu_button: Button
var _settings_button: Button
var _menu_view: Control
var _activity_view: Control
var _event_button: Button
var _demo_alert: Control
var _discovery_pins: Dictionary = {}
var _modal_rect := Rect2(320, 96, 640, 580)
var language := "en"
var spoken_text := ""
var voice: Node
var canvas: Control
var body: Control
var art: Control
var portrait: TextureRect
var language_buttons: Dictionary = {}
var audio_button: Button
var dialogue_label: Label
var name_field: LineEdit
var primary_button: Button
var reveal_tween: Tween
var landing_tween: Tween
var portrait_tween: Tween
var modal: Control
var modal_kind := ""
var focus_before_modal: Control
var modal_focus: Array[Control] = []
var voice_choice: OptionButton
var audio_message: Label
var audio_toggle: Button
var _voice_signature := ""
var _voice_state := "disabled"
var _talking := false

func _ready() -> void:
    UI.register_translations()
    TranslationServer.set_locale(language)
    theme = Theme.new()
    theme.default_font_size = 22
    voice = preload("res://ui/timmy_voice.gd").new()
    add_child(voice)
    var state_node = get_node_or_null(game_state_path)
    if state_node != null and state_node.get("preferencias") is Dictionary:
        var prefs: Dictionary = state_node.preferencias
        voice.muted = not bool(prefs.get("voice_enabled",true))
        voice.volume = int(prefs.get("voice_volume",85))
        voice.rate = float(prefs.get("voice_rate",0.95))
        voice.selected_voices = prefs.get("voices",{}).duplicate()
    bridge = preload("res://ui/game_bridge.gd").new()
    catalog.upgrades_path = upgrades_json_path
    catalog.missions_path = missions_json_path
    bridge.state_path = game_state_path
    add_child(bridge)
    bridge.register_panel("upgrades", upgrades_panel_scene)
    bridge.register_panel("missions", missions_panel_scene)
    bridge.register_panel("science", science_panel_scene)
    bridge.start_requested.connect(mission_requested.emit)
    bridge.content_changed.connect(_refresh_progression_view)
    bridge.state_changed.connect(_on_game_state_changed)
    bridge.recovery_requested.connect(_on_recovery_requested)
    _build()
    resized.connect(_resize_canvas)
    _resize_canvas()
    _render(false)
    var timer := Timer.new()
    timer.wait_time = 0.5
    timer.timeout.connect(_update_audio_ui)
    add_child(timer)
    timer.start()

func _build() -> void:
    world_view = preload("res://ui/world_backdrop.gd").new()
    add_child(world_view)
    canvas = Control.new()
    canvas.size = DESIGN
    add_child(canvas)
    art = preload("res://ui/intro_art.gd").new()
    art.size = DESIGN
    canvas.add_child(art)
    body = Control.new()
    body.size = DESIGN
    canvas.add_child(body)
    portrait = TextureRect.new()
    portrait.texture = TIMMY
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portrait.position = Vector2(22,310)
    portrait.size = Vector2(220,300)
    portrait.visible = false
    canvas.add_child(portrait)
    _panel(canvas, Rect2(16, 8, 1248, 40), Color(0.025, 0.075, 0.14, 0.82), 18).name = "IntroHeader"
    _label(canvas, "KILLAWASI", Rect2(30, 8, 200, 34), 27, WHITE, true).name = "IntroBrand"
    menu_button = Button.new()
    menu_button.hide()
    canvas.add_child(menu_button)
    for i in range(2):
        var locale: String = ["en", "es"][i]
        var button := _button(canvas, locale.to_upper(), Rect2(680 + i * 66, 10, 56, 36), _change_language.bind(locale))
        button.toggle_mode = true
        button.autowrap_mode = TextServer.AUTOWRAP_OFF
        button.add_theme_font_size_override("font_size", 18)
        button.tooltip_text = "English" if locale == "en" else "Español"
        language_buttons[locale] = button
    audio_button = _button(canvas, "", Rect2(820, 10, 132, 36), _open_audio)
    _button(canvas, "", Rect2(964, 10, 192, 36), _open_help).name = "HelpButton"
    _panel(canvas, Rect2(24, 694, 208, 24), Color(0, 0, 0, 0.8), 8)
    _label(canvas, "", Rect2(36, 696, 184, 20), 13, Color("#d8e5ef")).name = "TeamCredit"
    _label(canvas, "", Rect2(942, 698, 302, 20), 13, Color("#b9c9dc")).name = "ArtCredit"
    hud = preload("res://ui/live_hud.gd").new()
    hud.tutorial_layout = true
    hud.position = Vector2(22,20)
    canvas.add_child(hud)
    hud.resource_pressed.connect(_on_resource_pressed)
    hud.visible = false
    station_rail = preload("res://ui/station_rail.gd").new()
    station_rail.position = Vector2(414,636)
    canvas.add_child(station_rail)
    station_rail.hide()
    _demo_alert = preload("res://ui/alert_banner.gd").new()
    canvas.add_child(_demo_alert)
    _demo_alert.solve_requested.connect(func(_task): _open_section("messages"))
    station_rail.utility_requested.connect(func(action):
        if action == "more": _open_navigation("more")
    )
    _settings_button = _button(canvas,"",Rect2(1096,20,168,40),_open_navigation.bind("settings"))
    var gear = preload("res://ui/ui_icon.gd").new()
    gear.kind = "settings"
    gear.disc = false
    gear.tint = CYAN
    gear.position = Vector2(12,10)
    gear.size = Vector2(20,20)
    _settings_button.add_child(gear)
    _label(_settings_button,tr("nav.settings"),Rect2(42,4,120,32),15,WHITE,true).name = "Caption"
    station_rail.section_requested.connect(func(section):
        _open_section(section)
    )

func _resize_canvas() -> void:
    if not is_instance_valid(canvas):
        return
    var factor := minf(size.x / DESIGN.x, size.y / DESIGN.y)
    canvas.scale = Vector2.ONE * factor
    canvas.position = (size - DESIGN * factor) / 2.0

func _style(color: Color, border := Color.TRANSPARENT, width := 0, radius := 14) -> StyleBoxFlat:
    return UI.style(color, border, width, radius)

func _paint_button(button: Button, active := false) -> void:
    UI.paint(button, active)

func _button(parent: Node, text: String, rect: Rect2, callback: Callable, active := false) -> Button:
    return UI.button(parent, text, rect, callback, active)

func _label(parent: Node, text: String, rect: Rect2, font_size := 22, color := WHITE, bold := false) -> Label:
    return UI.label(parent, text, rect, font_size, color, bold)

func _panel(parent: Node, rect: Rect2, color: Color, radius := 22) -> Panel:
    return UI.panel(parent, rect, color, radius)

func _t(key: String) -> String:
    var mode: String = tutorial.player.mode_id()
    return tr(key).format({
        "name": _display_name(), "mode": tr("mode." + mode) if not mode.is_empty() else "",
        "current": STEPS.find(step) + 1, "total": STEPS.size()
    })

func _render(speak_now := true) -> void:
    if _in_profile: return
    if _in_home:
        _update_nav()
        home_screen.refresh_texts()
        bridge.configure_profile(get_profile())
        return
    if _in_expedition:
        _update_nav()
        hud.refresh()
        play_screen.refresh_texts()
        bridge.configure_profile(get_profile())
        return
    voice.stop()
    if reveal_tween and reveal_tween.is_running():
        reveal_tween.kill()
    for child in body.get_children():
        body.remove_child(child)
        child.queue_free()
    dialogue_label = null
    name_field = null
    primary_button = null
    _gate_hint = null
    _event_button = null
    if is_instance_valid(_demo_alert): _demo_alert.clear()
    _age_buttons.clear()
    spoken_text = ""
    var show_timmy := step in STEPS or step == "done"
    var was_visible := portrait.visible
    portrait.visible = show_timmy
    if show_timmy and not was_visible:
        portrait.position.y = 340
        portrait_tween = create_tween()
        portrait_tween.tween_property(portrait, "position:y", 310.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    art.set("show_ship", step == "landing")
    art.queue_redraw()
    if step == "start":
        _render_start()
    elif step == "landing":
        _render_landing()
    else:
        _render_dialogue()
    hud.visible = tutorial.needs_hud() or step == "done"
    if step == "alerts":
        _demo_alert.publish("practice:water",tr("notice.resource").format({"resource":tr("hud.agua.nombre")}),tr("tutorial.alert_body"),"agua","water",true)
    menu_button.hide()
    station_rail.visible = hud.visible and not _in_home
    station_rail.set_attention(tutorial.target().get_slice(":",1) if tutorial.target().begins_with("section:") else "")
    hud.set_state(bridge.get_state())
    hud.set_mode(tutorial.player.mode_id())
    hud.set_target(tutorial.target())
    hud.set_practice(bridge.training)
    bridge.configure_profile(get_profile())
    _refresh_tutorial_controls()
    _update_nav()
    _update_audio_ui()
    if step in STEPS and speak_now:
        bridge.report_tutorial_step(STEPS.find(step), tutorial.dialogue_key())
    if speak_now:
        _speak_current()

func _render_start() -> void:
    var hero = TextureRect.new()
    hero.texture = TIMMY
    hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hero.position = Vector2(940,244)
    hero.size = Vector2(290,420)
    body.add_child(hero)
    _panel(body,Rect2(838,136,372,100),Color("#071b32ee"),20)
    _label(body,tr("guide.entry_invite"),Rect2(862,152,324,76),27,GOLD,true)
    _label(body, _t("v2.hero_badge"), Rect2(66, 194, 600, 32), 17, CYAN, true)
    _label(body, "KILLAWASI", Rect2(62, 238, 650, 104), 78, WHITE, true)
    _label(body, _t("v2.hero_title"), Rect2(66, 352, 560, 116), 40, WHITE, true)
    _label(body, _t("v2.hero_body"), Rect2(68, 480, 500, 68), 22, Color("#d9e8f5"))
    primary_button = _button(body, _t("v2.start"), Rect2(66, 564, 270, 64), _start_landing, true)
    var skip_btn := _button(body, _t("v2.skip_tutorial"), Rect2(350, 564, 210, 64), _skip_tutorial)
    skip_btn.name = "SkipTutorialButton"
    _button(body, _t("v2.help"), Rect2(574, 564, 176, 64), _open_help)
    _label(body, _t("ui.controls"), Rect2(68, 646, 580, 30), 16, Color("#d4e4f1"))
    primary_button.grab_focus()

func _render_landing() -> void:
    spoken_text = _t("v2.landing")
    _panel(body, Rect2(360, 540, 560, 112), Color(0.03, 0.09, 0.17, 0.92))
    _label(body, _t("v2.landing"), Rect2(390, 554, 510, 40), 29, WHITE, true)
    _label(body, _t("v2.landing_body"), Rect2(390, 602, 510, 36), 20, Color("#d5e6f4"))
    primary_button = _button(body, _t("v2.skip"), Rect2(1040, 106, 196, 48), _finish_landing)
    primary_button.grab_focus()

func _render_dialogue() -> void:
    if step == "age":
        _label(body, _t("profile.age_title"), Rect2(360,148,850,52), 34, WHITE, true)
        _age_card("7_9", Rect2(360,220,402,164))
        _age_card("10_12", Rect2(784,220,402,164))
    elif step == "name":
        _panel(body, Rect2(948,146,250,40), Color(0, 0, 0, 0.9), 12)
        var astronaut_title := _label(body, _t("profile.astronaut"), Rect2(958,151,230,30), 20, WHITE, true)
        astronaut_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        astronaut_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        var preview := preload("res://ui/astronaut_preview.gd").new()
        preview.model_path = astronaut_model_path
        preview.model_scale = astronaut_model_scale
        preview.position = Vector2(958,190)
        preview.size = Vector2(230,200)
        body.add_child(preview)

    var bubble := _panel(body, Rect2(270,414,828,206), Color(0.025, 0.075, 0.145, 0.97), 24)
    bubble.mouse_filter = Control.MOUSE_FILTER_STOP
    bubble.gui_input.connect(_bubble_input)
    _panel(body, Rect2(294,422,138,32), GOLD, 12)
    _label(body, "Timmy", Rect2(312,424,100,26), 24, INK, true)
    _label(body, _t("v2.guide"), Rect2(450,426,530,24), 15, CYAN, true)
    if not str(tutorial.definition().get("demo","")).is_empty():
        _event_button = _button(body,tr("tutorial.show_demo"),Rect2(700,322,330,56),_open_tutorial_event.bind(str(tutorial.definition().demo)),true)
    if step in STEPS:
        var progress := _label(body, _t("v2.step"), Rect2(976,422,94,24), 16, Color("#bcd3e4"))
        progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    var key: String = tutorial.dialogue_key() if step != "done" else ("tutorial.done_review" if _has_profile() else "tutorial.done")
    spoken_text = _t(key)
    dialogue_label = _label(body, spoken_text, Rect2(306,458,744,84), 21, WHITE)
    if step == "name":
        dialogue_label.size.y = 34
        name_field = LineEdit.new()
        name_field.position = Vector2(306,502)
        name_field.size = Vector2(350,44)
        name_field.max_length = 18
        name_field.text = nickname
        name_field.placeholder_text = _t("v2.name_placeholder")
        name_field.add_theme_stylebox_override("normal", _style(Color("#16354f"), Color("#7b9fb9"), 1))
        name_field.add_theme_stylebox_override("focus", _style(Color("#16354f"), CYAN, 3))
        body.add_child(name_field)
        name_field.text_changed.connect(func(value: String): nickname = value)
        name_field.text_submitted.connect(_submit_name)
        _label(body, _t("v2.name_hint"), Rect2(680,506,380,44), 17, Color("#c2d8e9"))
    var next_text := "tutorial.yes" if step == "ready" else "v2.next"
    if step == "done":
        next_text = "tutorial.review"
    primary_button = _button(body, _t(next_text), Rect2(924,558,150,50), _advance, true)
    if step != "arrival" and step != "done":
        var review := step == "ready"
        _button(body, _t("tutorial.review" if review else "v2.back"), Rect2(306,558,126,50), _review_tutorial if review else _back)
    _button(body, _t("v2.repeat"), Rect2(448,558,116,50), _speak_current)
    _gate_hint = _label(body, "", Rect2(584,562,320,46), 15, Color("#bcd3e4"))
    if bool(tutorial.definition().get("typewriter", false)):
        dialogue_label.visible_characters = 0
        reveal_tween = create_tween()
        reveal_tween.tween_property(dialogue_label, "visible_characters", spoken_text.length(), clampf(spoken_text.length() / 38.0, 0.8, 3.5))

func _age_card(group: String, rect: Rect2) -> void:
    var selected: bool = tutorial.player.age_group == group
    var card := _button(body, "", rect, _select_age.bind(group), selected)
    card.name = "Age_" + group
    card.toggle_mode = true
    card.set_pressed_no_signal(selected)
    _age_buttons[group] = card
    var color := INK if selected else WHITE
    _label(card, tr("profile.age." + group), Rect2(24, 16, 350, 44), 29, color, true)
    _label(card, tr("profile.age." + group + ".body"), Rect2(24, 67, 352, 70), 20, color)
    _label(card, _t("v2.selected" if selected else "v2.choose"), Rect2(24, 140, 352, 26), 16, color, true)

func _select_age(group: String) -> void:
    if tutorial.player.choose_age(group):
        _render(false)

func _start_landing() -> void:
    step = "landing"
    art.set("landing_progress", 0.0)
    _render()
    landing_tween = create_tween()
    landing_tween.tween_method(_set_landing, 0.0, 1.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    landing_tween.tween_callback(_finish_landing)

func _skip_tutorial() -> void:
    if _transitioning: return
    _skip_requested = true
    voice.stop()
    tutorial.completed = true
    _transition_to("home" if _has_profile() else "profile")

func _has_profile() -> bool:
    return not tutorial.player.nickname.strip_edges().is_empty() and tutorial.player.age_group in ["7_9","10_12"]


func _set_landing(value: float) -> void:
    art.set("landing_progress", value)
    art.queue_redraw()

func _finish_landing() -> void:
    if step != "landing":
        return
    if landing_tween and landing_tween.is_running():
        landing_tween.kill()
    _set_landing(1.0)
    step = "arrival"
    _render()

func _finish_reveal() -> void:
    if reveal_tween and reveal_tween.is_running():
        reveal_tween.kill()
    if is_instance_valid(dialogue_label):
        dialogue_label.visible_characters = -1

func _advance() -> void:
    if _transitioning: return
    if reveal_tween and reveal_tween.is_running():
        _finish_reveal()
        return
    if step == "done":
        _review_tutorial()
        return
    if not tutorial.advance():
        return
    _render()
    if tutorial.completed:
        _transition_to("home" if _has_profile() else "profile")

func _back() -> void:
    tutorial.back()
    _render()

func _bubble_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _finish_reveal()

func _submit_name(_value: String) -> void:
    get_viewport().set_input_as_handled()
    _advance()

func _display_name() -> String:
    if not _in_home and not _in_profile and not _in_expedition: return tr("tutorial.explorer")
    return tutorial.player.display_name()

func get_profile() -> Dictionary:
    var profile: Dictionary = tutorial.player.export_profile(language, not voice.muted, tutorial.completed)
    profile.merge({"voice_volume": voice.volume, "voice_rate": voice.rate, "voices": voice.selected_voices.duplicate(true)})
    return profile

func _change_language(locale: String) -> void:
    if locale == language:
        _update_nav()
        return
    language = locale
    TranslationServer.set_locale(language)
    await get_tree().process_frame
    if is_instance_valid(station_rail): station_rail.refresh()
    _render(step != "start")

func _update_nav() -> void:
    var header_visible := not hud.visible and not _in_home and not _in_profile
    canvas.get_node("IntroHeader").visible = header_visible
    canvas.get_node("IntroBrand").visible = header_visible
    for button in language_buttons.values(): button.visible = header_visible
    audio_button.visible = header_visible
    canvas.get_node("HelpButton").visible = header_visible
    _settings_button.visible = hud.visible and not _in_home and not _in_profile
    _settings_button.get_node("Caption").text = tr("nav.settings")
    canvas.get_node("TeamCredit").text = tr("ui.team_credit")
    for locale in language_buttons:
        var button: Button = language_buttons[locale]
        button.set_pressed_no_signal(locale == language)
        _paint_button(button, locale == language)
    var help_button := canvas.get_node("HelpButton") as Button
    help_button.text = _t("v2.help")
    var credit := canvas.get_node("ArtCredit") as Label
    credit.text = _t("v2.ai_credit")
    credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _speak_current() -> void:
    if spoken_text.is_empty():
        return
    voice.speak(spoken_text, language)
    _update_audio_ui()

func _update_audio_ui() -> void:
    _voice_state = voice.status_code(language)
    _talking = voice.is_speaking()
    audio_button.text = _t("v2.settings") + ("  ●" if _voice_state == "ready" and not voice.muted else "  ○")
    audio_button.tooltip_text = _audio_summary()
    if modal_kind == "audio" and is_instance_valid(audio_message):
        audio_message.text = _audio_summary()
        _refresh_voice_choices()

func _audio_summary() -> String:
    if voice.muted:
        return _t("v2.audio_muted")
    if _voice_state == "ready":
        return _t("v2.audio_ready")
    if _voice_state == "loading":
        return _t("v2.audio_loading")
    return _t("v2.audio_missing")

func _process(_delta: float) -> void:
    if is_instance_valid(_demo_alert): _demo_alert.blocked = step != "alerts" or is_instance_valid(modal) or _in_home or _in_expedition
    if is_instance_valid(portrait) and portrait.visible:
        if not portrait_tween or not portrait_tween.is_running():
            portrait.position.y = 310.0 + sin(Time.get_ticks_msec() / 700.0) * (2.5 if _talking else 1.0)

func _open_modal(kind: String, title: String, wide := false) -> void:
    if is_instance_valid(modal):
        _close_modal()
    _finish_reveal()
    voice.stop()
    focus_before_modal = get_viewport().gui_get_focus_owner()
    modal_kind = kind
    modal_focus.clear()
    _modal_rect = Rect2(40,24,1200,596) if wide else Rect2(320, 96, 640, 580)
    if kind.begins_with("nav:"):
        _modal_rect = Rect2(856,78,400,500 if kind == "nav:more" else 390)
    elif kind == "audio": _modal_rect = Rect2(856,78,400,540)
    elif kind == "section:rest": _modal_rect = Rect2(856,78,400,550)
    if kind == "section:upgrades":
        _modal_rect = Rect2(60, 56, 1160, 632)
    modal = Control.new()
    modal.size = DESIGN
    modal.z_index = 30
    body.hide()
    portrait.hide()
    station_rail.z_index = 40 if _modal_rect.end.y <= 620 else 0
    canvas.add_child(modal)
    var shade := ColorRect.new()
    shade.color = Color(0.01,0.025,0.06,0.12 if kind.begins_with("nav:") or kind in ["audio","section:rest"] else 0.6)
    shade.size = DESIGN
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    modal.add_child(shade)
    var panel := _panel(modal, _modal_rect, Color("#0c243d"), 24)
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    _label(modal, title, Rect2(_modal_rect.position + Vector2(38, 30), Vector2(_modal_rect.size.x - 176, 48)), 22 if _modal_rect.size.x <= 400 else 30, WHITE, true)
    var close := _button(modal, _t("v2.close"), Rect2(_modal_rect.end.x - 138, _modal_rect.position.y + 28, 104, 44), _close_modal)
    modal_focus.append(close)

func _open_menu() -> void:
    _open_navigation("more")
func _open_navigation(page: String) -> void:
    if _transitioning: return
    _open_modal("nav:"+page,tr("nav."+page))
    station_rail.set_current("more" if page == "more" else "")
    _menu_view = preload("res://ui/navigation_menu.gd").new()
    _menu_view.page = page
    _menu_view.position = _modal_rect.position+Vector2(28,80)
    _menu_view.size = Vector2(344,_modal_rect.size.y-116)
    modal.add_child(_menu_view)
    _menu_view.action_requested.connect(func(action):
        match action:
            "language": _open_language_menu()
            "audio": _open_audio()
            "controls","timmy": _open_help()
            "exit":
                _close_modal()
                if _in_expedition: _return_to_home()
                else: _skip_tutorial()
            _: _open_section("letters" if action == "messages" and step == "letters" else action)
    )
    for button in _menu_view.buttons.values(): modal_focus.append(button)
    _trap_modal_focus()
func _open_language_menu() -> void:
    _open_modal("nav:language",tr("nav.language"))
    for i in 2:
        var lang: String = ["en","es"][i]
        var button = _button(modal,"English" if i == 0 else "Español",Rect2(_modal_rect.position+Vector2(28,94+i*76),Vector2(344,56)),func():
            await _change_language(lang)
            _open_language_menu()
        ,language == lang)
        modal_focus.append(button)
    modal_focus.append(_button(modal,tr("nav.back_settings"),Rect2(_modal_rect.position+Vector2(28,270),Vector2(344,48)),_open_navigation.bind("settings")))
    _trap_modal_focus()

func _open_help() -> void:
    _open_modal("help", _t("v2.help_title"))
    _label(modal, _t("tutorial.help_body"), Rect2(360, 206, 560, 306), 24, WHITE)
    _label(modal, _t("ui.controls"), Rect2(360, 564, 560, 62), 20, CYAN)
    _trap_modal_focus()

func _open_audio() -> void:
    _open_modal("audio",tr("nav.audio"))
    var origin := _modal_rect.position+Vector2(28,80)
    audio_toggle = _button(modal,_t("v2.audio_enabled"),Rect2(origin,Vector2(344,44)),_toggle_audio,not voice.muted)
    audio_toggle.toggle_mode = true
    audio_toggle.set_pressed_no_signal(not voice.muted)
    modal_focus.append(audio_toggle)
    _label(modal,_t("v2.voice"),Rect2(origin+Vector2(0,60),Vector2(344,26)),18,CYAN)
    voice_choice = OptionButton.new()
    voice_choice.position = origin+Vector2(0,98)
    voice_choice.size = Vector2(344,44)
    _paint_button(voice_choice)
    modal.add_child(voice_choice)
    voice_choice.item_selected.connect(_select_voice)
    modal_focus.append(voice_choice)
    _voice_signature = ""
    _refresh_voice_choices(true)
    for i in 2:
        _label(modal,_t("v2.volume" if i == 0 else "v2.speed"),Rect2(origin+Vector2(0,154+i*70),Vector2(230,26)),18,WHITE)
        var value_label = _label(modal,str(voice.volume)+"%" if i == 0 else "%.2fx" % voice.rate,Rect2(origin+Vector2(248,154+i*70),Vector2(90,26)),18,GOLD)
        var slider = HSlider.new()
        slider.position = origin+Vector2(0,184+i*70)
        slider.size = Vector2(344,26)
        slider.min_value = 0 if i == 0 else 0.7
        slider.max_value = 100 if i == 0 else 1.3
        slider.step = 5 if i == 0 else 0.05
        slider.value = voice.volume if i == 0 else voice.rate
        modal.add_child(slider)
        slider.value_changed.connect(func(value):
            if i == 0:
                voice.volume = int(value)
                value_label.text = str(int(value))+"%"
            else:
                voice.rate = float(value)
                value_label.text = "%.2fx" % value
        )
        modal_focus.append(slider)
    modal_focus.append(_button(modal,_t("v2.test"),Rect2(origin+Vector2(0,302),Vector2(164,46)),_test_voice,true))
    modal_focus.append(_button(modal,tr("nav.back_short"),Rect2(origin+Vector2(176,302),Vector2(168,46)),_open_navigation.bind("settings")))
    audio_message = _label(modal,_audio_summary(),Rect2(origin+Vector2(0,366),Vector2(344,82)),15,WHITE)
    _trap_modal_focus()

func _refresh_voice_choices(force := false) -> void:
    if not is_instance_valid(voice_choice):
        return
    var voices: Array = voice.voices_for(language)
    var signature := str(voices)
    if not force and signature == _voice_signature:
        return
    _voice_signature = signature
    voice_choice.clear()
    if voices.is_empty():
        voice_choice.add_item(_t("v2.no_voices"))
        voice_choice.disabled = true
        return
    voice_choice.disabled = false
    var chosen: String = voice.voice_id(language)
    for i in range(voices.size()):
        voice_choice.add_item(str(voices[i]["name"]))
        voice_choice.set_item_metadata(i, str(voices[i]["id"]))
        if str(voices[i]["id"]) == chosen:
            voice_choice.select(i)

func _select_voice(index: int) -> void:
    voice.set_voice(language, str(voice_choice.get_item_metadata(index)))

func _toggle_audio() -> void:
    voice.muted = not voice.muted
    voice.stop()
    audio_toggle.set_pressed_no_signal(not voice.muted)
    _paint_button(audio_toggle, not voice.muted)
    _update_audio_ui()

func _test_voice() -> void:
    voice.speak(_t("v2.test_phrase"), language)
    _update_audio_ui()

func _trap_modal_focus() -> void:
    var count := modal_focus.size()
    for i in range(count):
        modal_focus[i].focus_next = modal_focus[(i + 1) % count].get_path()
        modal_focus[i].focus_previous = modal_focus[(i - 1 + count) % count].get_path()
    if count > 0:
        modal_focus[0].grab_focus()

func _close_modal() -> void:
    var was_section := modal_kind.begins_with("section:")
    station_rail.z_index = 0
    station_rail.set_current("")
    if not _in_home and not _in_expedition:
        body.show()
        portrait.visible = step in STEPS or step == "done"
    voice.stop()
    if is_instance_valid(modal):
        canvas.remove_child(modal)
        modal.queue_free()
    modal = null
    modal_kind = ""
    voice_choice = null
    audio_message = null
    _progression_view = null
    _menu_view = null
    _activity_view = null
    modal_focus.clear()
    if is_instance_valid(focus_before_modal) and focus_before_modal.is_inside_tree():
        focus_before_modal.grab_focus()
    _refresh_tutorial_controls(false)
    if was_section and tutorial.can_advance() and is_instance_valid(primary_button):
        primary_button.grab_focus()

func _input(_event: InputEvent) -> void:
    if _transitioning: get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_ESCAPE:
        if is_instance_valid(modal):
            _close_modal()
        else:
            _open_audio()
        get_viewport().set_input_as_handled()


func _refresh_tutorial_controls(move_focus := true) -> void:
    if not is_instance_valid(primary_button) or not step in STEPS:
        return
    primary_button.disabled = not tutorial.can_advance()
    if is_instance_valid(_gate_hint):
        if step == "age" and tutorial.player.age_group.is_empty():
            _gate_hint.text = _t("tutorial.choose_age")
        elif not tutorial.target().is_empty():
            _gate_hint.text = _t("tutorial.action_done" if tutorial.can_advance() else "tutorial.try_control")
        else:
            _gate_hint.text = _t("ui.controls")
    if not move_focus or is_instance_valid(modal):
        return
    if step == "name":
        name_field.grab_focus()
    elif step == "age" and tutorial.player.age_group.is_empty():
        _age_buttons["7_9"].grab_focus()
    elif primary_button.disabled and hud.visible:
        if tutorial.target().begins_with("section:"):
            var section: String = tutorial.target().get_slice(":",1)
            if station_rail.buttons.has(section): station_rail.buttons[section].grab_focus()
            else: station_rail.utility_buttons.more.grab_focus()
        elif tutorial.target().begins_with("event:"):
            if is_instance_valid(_event_button): _event_button.grab_focus()
            elif step == "alerts" and is_instance_valid(_demo_alert): _demo_alert._solve.grab_focus()
        else: hud.focus_target()
    else:
        primary_button.grab_focus()

func _on_resource_pressed(id: String) -> void:
    tutorial.record_action("resource:" + id)
    _refresh_tutorial_controls(false)
    if tutorial.target() == "resource:" + id:
        primary_button.grab_focus()
    else:
        _open_modal("resource", tr("hud." + id + ".nombre"))
        _label(modal, tr("hud." + id + ".help"), Rect2(360, 222, 560, 180), 26, WHITE)
        _trap_modal_focus()

func _open_section(section: String) -> void:
    bridge.request_panel(section)
    _open_modal("section:" + section, tr("actions." + section), true)
    station_rail.set_current(section)
    if section == "rest":
        _label(modal,tr("flow.practice"),Rect2(_modal_rect.position+Vector2(38,74),Vector2(324,20)),12,CYAN,true)
    var holder := Control.new()
    holder.position = _modal_rect.position + Vector2(38, 96)
    holder.size = _modal_rect.size - Vector2(76, 124)
    modal.add_child(holder)
    var supplied: Control = bridge.instantiate_panel(section)
    if supplied != null:
        _progression_view = supplied
        holder.add_child(supplied)
        supplied.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        for control in supplied.find_children("*", "Control", true, false):
            if control.focus_mode != Control.FOCUS_NONE and control.is_visible_in_tree():
                if not control is BaseButton or not control.disabled:
                    modal_focus.append(control)
    elif section in ["upgrades", "missions"]:
        var items: Array[Dictionary] = catalog.upgrades(bridge.training) if section == "upgrades" else catalog.missions(bridge.training)
        if not items.is_empty():
            var script: Script = preload("res://ui/upgrade_tree.gd") if section == "upgrades" else preload("res://ui/mission_list.gd")
            _progression_view = script.new()
            _progression_view.size = holder.size
            _progression_view.configure(items, bridge.get_progression_state(), bridge.training, "cadete" if bridge.training else tutorial.player.mode_id())
            holder.add_child(_progression_view)
            _progression_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
            if _progression_view.has_signal("purchase_requested"):
                _progression_view.connect("purchase_requested", bridge.request_upgrade)
            for control in _progression_view.find_children("*", "Control", true, false):
                if control.focus_mode != Control.FOCUS_NONE and control.is_visible_in_tree():
                    if not control is BaseButton or not control.disabled:
                        modal_focus.append(control)
        else:
            _label(holder, _t("panels.unavailable"), Rect2(0, 48, holder.size.x, 160), 24)
    elif bridge.training:
        if section == "rest":
            _activity_view = preload("res://ui/recharge_panel.gd").new()
            _activity_view.training = true
            _activity_view.near_dome = false
        elif section in ["messages","letters","recovery","ending"]:
            _activity_view = preload("res://ui/tutorial_events.gd").new()
            _activity_view.scenario = section
            _activity_view.mode = ""
            _activity_view.recovery_requested.connect(_play_practice_recovery)
        elif section == "supplies":
            _activity_view = preload("res://ui/reward_view.gd").new()
            _activity_view.training = true
            _activity_view.mission_title = tr("tutorial.sample_mission")
            _activity_view.science_title = tr("science.solar.title")
            _activity_view.stars = 3
            _activity_view.supplies = {"panel_solar":1,"procesador_hielo":1}
            _activity_view.acknowledged.connect(func(science):
                tutorial.record_action("event:supplies")
                _refresh_tutorial_controls(false)
                if science: _open_section("science")
                else: _close_modal()
            )
        elif section == "construction":
            _activity_view = preload("res://ui/build_practice.gd").new()
        elif section == "expedition":
            _activity_view = preload("res://ui/ice_survey_panel.gd").new()
        elif section in ["processing","repair"]:
            _activity_view = preload("res://ui/station_sequence.gd").new()
            _activity_view.section = section
        else:
            _activity_view = preload("res://ui/visual_activity.gd").new()
            _activity_view.section = section
        if section == "science": _activity_view.set_pinned_cards(_discovery_pins)
        _activity_view.size = holder.size
        holder.add_child(_activity_view)
        if _activity_view.has_signal("completed"):
            _activity_view.completed.connect(func():
                tutorial.record_action(tutorial.target() if tutorial.target().begins_with("event:") else "section:"+section)
                _refresh_tutorial_controls(false)
            )
        if _activity_view.has_signal("narration_requested"):
            _activity_view.narration_requested.connect(func(text: String): voice.speak(text, language))
        for control in _activity_view.find_children("*", "Control", true, false):
            if control.focus_mode != Control.FOCUS_NONE and control.is_visible_in_tree():
                modal_focus.append(control)
    else:
        _label(holder, _t("panels.unavailable"), Rect2(0, 48, holder.size.x, 160), 24)
    if section not in ["construction","expedition","processing","repair","messages","letters","supplies","recovery","ending","rest"]:
        tutorial.record_action("section:" + section)
    _refresh_tutorial_controls(false)
    _trap_modal_focus()

func _review_tutorial() -> void:
    if _transitioning: return
    _prepare_tutorial_review()
    tutorial.step_id = "base"
    _render()

func _watch_tutorial() -> void:
    if _transitioning: return
    _prepare_tutorial_review()
    _start_landing()

func _prepare_tutorial_review() -> void:
    hud.tutorial_layout = true
    _skip_requested = false
    _in_home = false
    _in_profile = false
    _in_expedition = false
    if is_instance_valid(setup_screen): setup_screen.hide()
    if is_instance_valid(home_screen): home_screen.hide()
    if is_instance_valid(play_screen): play_screen.hide()
    body.visible = true
    art.visible = true
    tutorial.completed = false

func _on_game_state_changed(state: Dictionary) -> void:
    if is_instance_valid(hud):
        hud.set_state(state)
        hud.set_practice(bridge.training and not _in_expedition)
    _refresh_progression_view()

func _on_recovery_requested(policy: String, profile: Dictionary) -> void:
    recovery_requested.emit(policy, profile)

func set_progression_panels(upgrades: PackedScene, missions: PackedScene) -> void:
    upgrades_panel_scene = upgrades
    missions_panel_scene = missions
    if is_instance_valid(bridge):
        bridge.register_panel("upgrades", upgrades)
        bridge.register_panel("missions", missions)

func report_tutorial_action(action: String) -> void:
    tutorial.record_action(action)
    _refresh_tutorial_controls(false)

func set_progression_catalogs(upgrades: Dictionary, missions: Dictionary) -> void:
    catalog.set_data(upgrades, missions)

func _refresh_progression_view() -> void:
    if is_instance_valid(_progression_view) and _progression_view.has_method("set_progression_state"):
        _progression_view.call("set_progression_state", bridge.get_progression_state())

func _begin_expedition() -> void:
    if not _in_home or _transitioning: return
    _transition_to("expedition")

func _return_to_home() -> void:
    if not _in_expedition or _transitioning: return
    _transition_to("home")

func _transition_to(destination: String) -> void:
    if _transitioning: return
    _transitioning = true
    if is_instance_valid(primary_button): primary_button.disabled = true
    var fade := ColorRect.new()
    fade.color = Color.BLACK
    fade.size = DESIGN
    fade.modulate.a = 0
    fade.z_index = 100
    fade.mouse_filter = Control.MOUSE_FILTER_STOP
    canvas.add_child(fade)
    var transition := create_tween()
    transition.tween_interval(0.65 if destination == "home" and not _in_expedition else 0.1)
    transition.tween_property(fade, "modulate:a", 1.0, 0.65).set_trans(Tween.TRANS_SINE)
    transition.tween_callback(_show_home_screen if destination == "home" else (_show_profile_screen if destination == "profile" else _show_play_screen))
    transition.tween_interval(0.15)
    transition.tween_property(fade, "modulate:a", 0.0, 0.65).set_trans(Tween.TRANS_SINE)
    await transition.finished
    canvas.remove_child(fade)
    fade.queue_free()
    _transitioning = false
    if destination == "home":
        home_screen.play_button.grab_focus()
        home_entered.emit()
    elif destination == "profile":
        setup_screen.name_field.grab_focus()
        profile_setup_entered.emit()
    else:
        station_rail.buttons.construction.grab_focus()
        if not _start_emitted:
            _start_emitted = true
            bridge.request_start(get_profile())
        else:
            pause_requested.emit(false)
            resume_requested.emit(get_profile())
        expedition_entered.emit()

func _show_home_screen() -> void:
    _in_profile = false
    if is_instance_valid(setup_screen): setup_screen.hide()
    var was_playing := _in_expedition
    voice.stop()
    _in_home = true
    _in_expedition = false
    body.hide()
    portrait.hide()
    art.hide()
    hud.hide()
    station_rail.hide()
    menu_button.hide()
    if is_instance_valid(play_screen): play_screen.hide()
    if not is_instance_valid(home_screen):
        home_screen = preload("res://ui/home_menu.gd").new()
        home_screen.size = DESIGN
        home_screen.nickname = _display_name()
        canvas.add_child(home_screen)
        canvas.move_child(home_screen, 0)
        home_screen.play_requested.connect(_begin_expedition)
        home_screen.options_requested.connect(_open_navigation.bind("settings"))
        home_screen.tutorial_requested.connect(_watch_tutorial)
        home_screen.restart_requested.connect(func(): restart_requested.emit(get_profile()))
    home_screen.nickname = _display_name()
    home_screen.resume_available = _start_emitted
    home_screen.refresh_texts()
    station_rail.hide()
    home_screen.show()
    _update_nav()
    if was_playing: pause_requested.emit(true)

func _show_play_screen() -> void:
    hud.tutorial_layout = false
    _in_home = false
    _in_expedition = true
    body.hide()
    portrait.hide()
    art.hide()
    if is_instance_valid(home_screen): home_screen.hide()
    hud.show()
    station_rail.show()
    menu_button.hide()
    hud.set_target("")
    hud.set_practice(false)
    if not is_instance_valid(play_screen):
        play_screen = preload("res://ui/expedition_preview.gd").new()
        play_screen.size = DESIGN
        play_screen.nickname = _display_name()
        canvas.add_child(play_screen)
        canvas.move_child(play_screen, 0)
        play_screen.menu_requested.connect(_return_to_home)
    play_screen.nickname = _display_name()
    play_screen.refresh_texts()
    play_screen.show()
    _update_nav()

func _open_tutorial_event(event: String) -> void:
    if event == "settings":
        tutorial.record_action("event:settings")
        _refresh_tutorial_controls(false)
        _open_navigation("settings")
    else: _open_section(event)
func _play_practice_recovery() -> void:
    voice.stop()
    var effect = preload("res://ui/run_transition.gd").new()
    effect.kind = "practice"
    effect.message = tr("tutorial.retry_demo")
    effect.finished.connect(func():
        tutorial.record_action("event:recovery")
        _close_modal()
        _refresh_tutorial_controls()
        practice_event_completed.emit("recovery")
    )
    canvas.add_child(effect)

func _show_profile_screen() -> void:
    voice.stop()
    _in_profile = true
    _in_home = false
    _in_expedition = false
    body.hide()
    portrait.hide()
    art.hide()
    hud.hide()
    station_rail.hide()
    _settings_button.hide()
    if is_instance_valid(home_screen): home_screen.hide()
    if not is_instance_valid(setup_screen):
        setup_screen = preload("res://ui/player_setup.gd").new()
        setup_screen.model_path = astronaut_model_path
        canvas.add_child(setup_screen)
        setup_screen.narration_requested.connect(func(text): voice.speak(text,language))
        setup_screen.confirmed.connect(func(callsign,group):
            tutorial.player.locked = false
            tutorial.player.nickname = callsign
            tutorial.player.choose_age(group)
            tutorial.player.locked = true
            tutorial.completed = true
            _transition_to("home")
        )
    setup_screen.show()
    _update_nav()

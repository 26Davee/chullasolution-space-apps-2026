extends Control

signal mission_requested(profile: Dictionary)

const DESIGN := Vector2(1280, 720)
const STEPS := ["arrival", "introduce", "name", "mode", "ready"]
const BG = preload("res://assets/ui/moon_base.png")
const TIMMY = preload("res://assets/ui/timmy.png")
const INK := Color("#071b32")
const GOLD := Color("#ffc64f")
const CYAN := Color("#59e0dc")
const WHITE := Color("#f3f7fc")

var step := "start"
var nickname := ""
var selected_mode := "cadet"
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
var _bold: FontVariation

func _ready() -> void:
    var catalogs := {
        "en": preload("res://i18n/en.gd").MESSAGES,
        "es": preload("res://i18n/es.gd").MESSAGES
    }
    for locale in catalogs:
        var translation := Translation.new()
        translation.locale = locale
        for key in catalogs[locale]:
            translation.add_message(key, catalogs[locale][key])
        TranslationServer.add_translation(translation)
    TranslationServer.set_locale(language)
    _bold = FontVariation.new()
    _bold.base_font = ThemeDB.fallback_font
    _bold.variation_embolden = 0.6
    theme = Theme.new()
    theme.default_font_size = 22
    voice = preload("res://ui/timmy_voice.gd").new()
    add_child(voice)
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
    var background := TextureRect.new()
    background.texture = BG
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
    portrait.position = Vector2(0, 295)
    portrait.size = Vector2(330, 425)
    portrait.visible = false
    canvas.add_child(portrait)
    _panel(canvas, Rect2(24, 20, 1232, 64), Color(0.025, 0.075, 0.14, 0.82), 18)
    _label(canvas, "INTI KILLA", Rect2(44, 34, 310, 40), 27, WHITE, true)
    for i in range(2):
        var locale: String = ["en", "es"][i]
        var button := _button(canvas, locale.to_upper(), Rect2(760 + i * 66, 30, 56, 44), _change_language.bind(locale))
        button.toggle_mode = true
        button.autowrap_mode = TextServer.AUTOWRAP_OFF
        button.add_theme_font_size_override("font_size", 18)
        button.tooltip_text = "English" if locale == "en" else "Español"
        language_buttons[locale] = button
    audio_button = _button(canvas, "", Rect2(900, 30, 132, 44), _open_audio)
    _button(canvas, "", Rect2(1044, 30, 192, 44), _open_help).name = "HelpButton"
    _label(canvas, "", Rect2(942, 698, 302, 20), 13, Color("#b9c9dc")).name = "ArtCredit"

func _resize_canvas() -> void:
    if not is_instance_valid(canvas):
        return
    var factor := minf(size.x / DESIGN.x, size.y / DESIGN.y)
    canvas.scale = Vector2.ONE * factor
    canvas.position = (size - DESIGN * factor) / 2.0

func _style(color: Color, border := Color.TRANSPARENT, width := 0, radius := 14) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(radius)
    style.content_margin_left = 16
    style.content_margin_right = 16
    return style

func _paint_button(button: Button, active := false) -> void:
    button.add_theme_stylebox_override("normal", _style(GOLD if active else Color("#102b46"), Color("#536e87"), 0 if active else 1))
    button.add_theme_stylebox_override("hover", _style(Color("#ffdb85") if active else Color("#20465f"), CYAN, 2))
    button.add_theme_stylebox_override("pressed", _style(GOLD if active else Color("#295873"), CYAN, 2))
    button.add_theme_stylebox_override("disabled", _style(Color("#173047")))
    button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, CYAN, 3))
    for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
        button.add_theme_color_override(state, INK if active else WHITE)
    button.add_theme_color_override("font_disabled_color", Color("#8da1b5"))

func _button(parent: Node, text: String, rect: Rect2, callback: Callable, active := false) -> Button:
    var button := Button.new()
    button.text = text
    button.position = rect.position
    button.size = rect.size
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _paint_button(button, active)
    button.pressed.connect(callback)
    parent.add_child(button)
    return button

func _label(parent: Node, text: String, rect: Rect2, font_size := 22, color := WHITE, bold := false) -> Label:
    var label := Label.new()
    label.text = text
    label.position = rect.position
    label.size = rect.size
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    if bold:
        label.add_theme_font_override("font", _bold)
    parent.add_child(label)
    return label

func _panel(parent: Node, rect: Rect2, color: Color, radius := 22) -> Panel:
    var panel := Panel.new()
    panel.position = rect.position
    panel.size = rect.size
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_theme_stylebox_override("panel", _style(color, Color(0.48, 0.77, 0.84, 0.38), 1, radius))
    parent.add_child(panel)
    return panel

func _t(key: String) -> String:
    return tr(key).format({
        "name": _display_name(),
        "mode": tr("v2." + selected_mode),
        "current": STEPS.find(step) + 1,
        "total": STEPS.size()
    })

func _render(speak_now := true) -> void:
    voice.stop()
    if reveal_tween and reveal_tween.is_running():
        reveal_tween.kill()
    for child in body.get_children():
        body.remove_child(child)
        child.queue_free()
    dialogue_label = null
    name_field = null
    primary_button = null
    spoken_text = ""
    var show_timmy := step in STEPS or step == "done"
    var was_visible := portrait.visible
    portrait.visible = show_timmy
    if show_timmy and not was_visible:
        portrait.position.y = 325
        portrait_tween = create_tween()
        portrait_tween.tween_property(portrait, "position:y", 295.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    art.set("show_ship", step != "start")
    art.queue_redraw()
    if step == "start":
        _render_start()
    elif step == "landing":
        _render_landing()
    else:
        _render_dialogue()
    _update_nav()
    _update_audio_ui()
    if speak_now:
        _speak_current()

func _render_start() -> void:
    _label(body, _t("v2.hero_badge"), Rect2(66, 194, 600, 32), 17, CYAN, true)
    _label(body, "INTI KILLA", Rect2(62, 238, 650, 104), 78, WHITE, true)
    _label(body, _t("v2.hero_title"), Rect2(66, 352, 560, 116), 40, WHITE, true)
    _label(body, _t("v2.hero_body"), Rect2(68, 480, 500, 68), 22, Color("#d9e8f5"))
    primary_button = _button(body, _t("v2.start"), Rect2(66, 564, 310, 64), _start_landing, true)
    _button(body, _t("v2.help"), Rect2(392, 564, 180, 64), _open_help)
    _label(body, _t("v2.controls"), Rect2(68, 646, 580, 30), 16, Color("#d4e4f1"))
    primary_button.grab_focus()

func _render_landing() -> void:
    spoken_text = _t("v2.landing")
    _panel(body, Rect2(360, 540, 560, 112), Color(0.03, 0.09, 0.17, 0.92))
    _label(body, _t("v2.landing"), Rect2(390, 554, 510, 40), 29, WHITE, true)
    _label(body, _t("v2.landing_body"), Rect2(390, 602, 510, 36), 20, Color("#d5e6f4"))
    primary_button = _button(body, _t("v2.skip"), Rect2(1040, 106, 196, 48), _finish_landing)
    primary_button.grab_focus()

func _render_dialogue() -> void:
    if step == "mode":
        _label(body, _t("v2.mode_title"), Rect2(360, 164, 850, 56), 34, WHITE, true)
        _mode_card("cadet", Rect2(360, 246, 402, 176))
        _mode_card("engineer", Rect2(784, 246, 402, 176))
    elif step == "ready" or step == "done":
        _panel(body, Rect2(804, 346, 382, 70), Color(0.035, 0.1, 0.18, 0.94))
        _label(body, _display_name() + "  ·  " + _t("v2." + selected_mode), Rect2(826, 362, 340, 44), 24, GOLD, true)
    var bubble := _panel(body, Rect2(270, 474, 974, 214), Color(0.025, 0.075, 0.145, 0.97), 24)
    bubble.mouse_filter = Control.MOUSE_FILTER_STOP
    bubble.gui_input.connect(_bubble_input)
    _panel(body, Rect2(294, 444, 138, 44), GOLD, 12)
    _label(body, "Timmy", Rect2(318, 449, 100, 34), 24, INK, true)
    _label(body, _t("v2.guide"), Rect2(450, 447, 530, 28), 15, CYAN, true)
    if step in STEPS:
        var progress := _label(body, _t("v2.step"), Rect2(1126, 482, 88, 26), 16, Color("#bcd3e4"))
        progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    spoken_text = _t("v2." + step)
    dialogue_label = _label(body, spoken_text, Rect2(306, 508, 890, 82), 27, WHITE)
    if step == "name":
        dialogue_label.size.y = 42
        name_field = LineEdit.new()
        name_field.position = Vector2(306, 556)
        name_field.size = Vector2(420, 48)
        name_field.max_length = 18
        name_field.text = nickname
        name_field.placeholder_text = _t("v2.name_placeholder")
        name_field.add_theme_stylebox_override("normal", _style(Color("#16354f"), Color("#7b9fb9"), 1))
        name_field.add_theme_stylebox_override("focus", _style(Color("#16354f"), CYAN, 3))
        body.add_child(name_field)
        name_field.text_changed.connect(func(value: String): nickname = value)
        name_field.text_submitted.connect(_submit_name)
        _label(body, _t("v2.name_hint"), Rect2(748, 558, 440, 48), 17, Color("#c2d8e9"))
        name_field.grab_focus()
    var next_text := "v2.launch" if step == "ready" else "v2.next"
    if step == "done":
        next_text = "v2.restart"
    primary_button = _button(body, _t(next_text), Rect2(1054, 618, 158, 50), _advance, true)
    if step != "arrival" and step != "done":
        _button(body, _t("v2.back"), Rect2(306, 618, 100, 50), _back)
    _button(body, _t("v2.repeat"), Rect2(422, 618, 132, 50), _speak_current)
    _label(body, _t("v2.controls"), Rect2(574, 627, 462, 40), 15, Color("#bcd3e4"))
    if step != "name":
        primary_button.grab_focus()
    if step == "arrival" or step == "introduce":
        dialogue_label.visible_characters = 0
        reveal_tween = create_tween()
        reveal_tween.tween_property(dialogue_label, "visible_characters", spoken_text.length(), clampf(spoken_text.length() / 38.0, 0.8, 3.5))

func _mode_card(mode: String, rect: Rect2) -> void:
    var selected := selected_mode == mode
    var card := _button(body, "", rect, _select_mode.bind(mode), selected)
    card.name = "Mode_" + mode
    card.toggle_mode = true
    card.set_pressed_no_signal(selected)
    var color := INK if selected else WHITE
    _label(card, _t("v2." + mode), Rect2(24, 16, 350, 44), 29, color, true)
    _label(card, _t("v2." + mode + "_body"), Rect2(24, 67, 352, 70), 20, color)
    _label(card, _t("v2.selected" if selected else "v2.choose"), Rect2(24, 140, 352, 26), 16, color, true)

func _select_mode(mode: String) -> void:
    selected_mode = mode
    _render(false)

func _start_landing() -> void:
    step = "landing"
    art.set("landing_progress", 0.0)
    _render()
    landing_tween = create_tween()
    landing_tween.tween_method(_set_landing, 0.0, 1.0, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    landing_tween.tween_callback(_finish_landing)

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
    if reveal_tween and reveal_tween.is_running():
        _finish_reveal()
        return
    if step == "ready":
        var profile := get_profile()
        step = "done"
        _render()
        mission_requested.emit(profile)
    elif step == "done":
        nickname = ""
        selected_mode = "cadet"
        step = "start"
        _set_landing(0.0)
        _render(false)
    elif step in STEPS:
        var index := STEPS.find(step)
        step = STEPS[index + 1]
        _render()

func _back() -> void:
    var index := STEPS.find(step)
    if index > 0:
        step = STEPS[index - 1]
        _render()

func _bubble_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _finish_reveal()

func _submit_name(_value: String) -> void:
    get_viewport().set_input_as_handled()
    _advance()

func _display_name() -> String:
    var clean := nickname.replace("<", "").replace(">", "").replace("&", " ").strip_edges()
    return clean if not clean.is_empty() else tr("v2.default_name")

func get_profile() -> Dictionary:
    return {
        "nickname": _display_name(), "mode": selected_mode,
        "language": language, "voice_enabled": not voice.muted
    }

func _change_language(locale: String) -> void:
    if locale == language:
        _update_nav()
        return
    language = locale
    TranslationServer.set_locale(language)
    _render(step != "start")

func _update_nav() -> void:
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
    if is_instance_valid(portrait) and portrait.visible:
        if not portrait_tween or not portrait_tween.is_running():
            portrait.position.y = 295.0 + sin(Time.get_ticks_msec() / 700.0) * (2.5 if _talking else 1.0)

func _open_modal(kind: String, title: String) -> void:
    if is_instance_valid(modal):
        _close_modal()
    _finish_reveal()
    voice.stop()
    focus_before_modal = get_viewport().gui_get_focus_owner()
    modal_kind = kind
    modal_focus.clear()
    modal = Control.new()
    modal.size = DESIGN
    modal.z_index = 30
    canvas.add_child(modal)
    var shade := ColorRect.new()
    shade.color = Color(0.01, 0.025, 0.06, 0.8)
    shade.size = DESIGN
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    modal.add_child(shade)
    var panel := _panel(modal, Rect2(320, 96, 640, 580), Color("#0c243d"), 24)
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    _label(modal, title, Rect2(358, 126, 440, 48), 30, WHITE, true)
    var close := _button(modal, _t("v2.close"), Rect2(822, 124, 104, 44), _close_modal)
    modal_focus.append(close)

func _open_help() -> void:
    _open_modal("help", _t("v2.help_title"))
    _label(modal, _t("v2.help_body"), Rect2(360, 206, 560, 306), 24, WHITE)
    _label(modal, _t("v2.controls"), Rect2(360, 564, 560, 62), 20, CYAN)
    _trap_modal_focus()

func _open_audio() -> void:
    _open_modal("audio", _t("v2.audio_title"))
    audio_toggle = _button(modal, _t("v2.audio_enabled"), Rect2(360, 190, 560, 48), _toggle_audio, not voice.muted)
    audio_toggle.toggle_mode = true
    audio_toggle.set_pressed_no_signal(not voice.muted)
    modal_focus.append(audio_toggle)
    _label(modal, _t("v2.voice"), Rect2(360, 254, 560, 30), 20, Color("#bed6e7"))
    voice_choice = OptionButton.new()
    voice_choice.position = Vector2(360, 288)
    voice_choice.size = Vector2(560, 48)
    _paint_button(voice_choice)
    modal.add_child(voice_choice)
    voice_choice.item_selected.connect(_select_voice)
    modal_focus.append(voice_choice)
    _voice_signature = ""
    _refresh_voice_choices(true)
    _label(modal, _t("v2.volume"), Rect2(360, 350, 430, 28), 20, Color("#bed6e7"))
    var volume_label := _label(modal, str(voice.volume) + "%", Rect2(830, 350, 90, 28), 20, GOLD)
    var volume_slider := HSlider.new()
    volume_slider.position = Vector2(360, 386)
    volume_slider.size = Vector2(560, 28)
    volume_slider.min_value = 0
    volume_slider.max_value = 100
    volume_slider.value = voice.volume
    volume_slider.step = 5
    modal.add_child(volume_slider)
    volume_slider.value_changed.connect(func(value: float):
        voice.volume = int(value)
        volume_label.text = str(int(value)) + "%"
    )
    modal_focus.append(volume_slider)
    _label(modal, _t("v2.speed"), Rect2(360, 428, 430, 28), 20, Color("#bed6e7"))
    var speed_label := _label(modal, "%.2fx" % voice.rate, Rect2(830, 428, 90, 28), 20, GOLD)
    var speed_slider := HSlider.new()
    speed_slider.position = Vector2(360, 464)
    speed_slider.size = Vector2(560, 28)
    speed_slider.min_value = 0.7
    speed_slider.max_value = 1.2
    speed_slider.step = 0.05
    speed_slider.value = voice.rate
    modal.add_child(speed_slider)
    speed_slider.value_changed.connect(func(value: float):
        voice.rate = value
        speed_label.text = "%.2fx" % value
    )
    modal_focus.append(speed_slider)
    var test := _button(modal, _t("v2.test"), Rect2(360, 514, 560, 52), _test_voice, true)
    modal_focus.append(test)
    audio_message = _label(modal, _audio_summary(), Rect2(360, 588, 560, 64), 18, Color("#c4d9e9"))
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
    voice.stop()
    if is_instance_valid(modal):
        canvas.remove_child(modal)
        modal.queue_free()
    modal = null
    modal_kind = ""
    voice_choice = null
    audio_message = null
    modal_focus.clear()
    if is_instance_valid(focus_before_modal) and focus_before_modal.is_inside_tree():
        focus_before_modal.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_ESCAPE:
        if is_instance_valid(modal):
            _close_modal()
        else:
            _open_audio()
        get_viewport().set_input_as_handled()


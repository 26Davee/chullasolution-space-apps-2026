extends Control
signal play_requested()
signal options_requested()
signal tutorial_requested()
const UI = preload("res://ui/ui_kit.gd")
var nickname := ""
var resume_available := false
var play_button: Button
var options_button: Button
var tutorial_button: Button
var _badge: Label
var _title: Label
var _greeting: Label

func _ready() -> void:
    var image := TextureRect.new()
    image.texture = load("res://assets/ui/moon_base.png")
    image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(image)
    image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    UI.panel(self, Rect2(740, 176, 480, 476), Color(0.025, 0.075, 0.145, 0.97), 24)
    _badge = UI.label(self, "", Rect2(770, 196, 420, 28), 16, UI.CYAN, true)
    _title = UI.label(self, "KILLAWASI", Rect2(770, 238, 420, 64), 44, UI.WHITE, true)
    _greeting = UI.label(self, "", Rect2(770, 310, 420, 62), 21, Color("#d7e6f3"))
    play_button = UI.button(self, "", Rect2(770, 390, 420, 62), play_requested.emit, true)
    options_button = UI.button(self, "", Rect2(770, 468, 420, 54), options_requested.emit)
    tutorial_button = UI.button(self, "", Rect2(770, 538, 420, 64), tutorial_requested.emit)
    tutorial_button.add_theme_font_size_override("font_size", 21)
    refresh_texts()

func refresh_texts() -> void:
    _badge.text = tr("home.badge")
    _greeting.text = tr("home.greeting").format({"name":nickname})
    play_button.text = tr("home.resume" if resume_available else "home.play")
    options_button.text = tr("home.options")
    tutorial_button.text = tr("home.tutorial")

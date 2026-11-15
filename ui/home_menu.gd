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
    var backdrop = preload("res://ui/world_backdrop.gd").new()
    add_child(backdrop)
    var shade = ColorRect.new()
    shade.color = Color(0.01,0.04,0.09,0.34)
    shade.size = Vector2(1280,720)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)
    var timmy = TextureRect.new()
    timmy.texture = load("res://assets/ui/timmy.png")
    timmy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    timmy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    timmy.position = Vector2(70,220)
    timmy.size = Vector2(310,400)
    timmy.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(timmy)
    UI.label(self,"KILLAWASI",Rect2(48,46,650,90),64,UI.WHITE,true)
    UI.label(self,tr("guide.menu_blurb"),Rect2(54,146,620,64),24,UI.CYAN,true)
    UI.panel(self, Rect2(740, 176, 480, 476), Color(0.025, 0.075, 0.145, 0.97), 24)
    _badge = UI.label(self, "", Rect2(770, 196, 420, 28), 16, UI.CYAN, true)
    _title = UI.label(self, "KILLAWASI", Rect2(770, 238, 420, 64), 34, UI.WHITE, true)
    _greeting = UI.label(self, "", Rect2(770, 310, 420, 62), 21, Color("#d7e6f3"))
    play_button = UI.button(self, "", Rect2(770, 390, 420, 62), play_requested.emit, true)
    options_button = UI.button(self, "", Rect2(770, 468, 420, 54), options_requested.emit)
    tutorial_button = UI.button(self, "", Rect2(770, 538, 420, 64), tutorial_requested.emit)
    tutorial_button.add_theme_font_size_override("font_size", 21)
    refresh_texts()

func refresh_texts() -> void:
    _title.text = tr("home.badge")
    _badge.text = tr("guide.menu_tag")
    _greeting.text = tr("home.greeting").format({"name":nickname})
    play_button.text = tr("home.resume" if resume_available else "home.play")
    options_button.text = tr("home.options")
    tutorial_button.text = tr("home.tutorial")

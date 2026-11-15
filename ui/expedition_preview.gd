extends Control
signal menu_requested()
const UI = preload("res://ui/ui_kit.gd")
var nickname := ""
var _welcome: Label
var _goal: Label
var _badge: Label
var _review: Button

func _ready() -> void:
    var image := TextureRect.new()
    image.texture = load("res://assets/ui/activities/playfield-v1.png")
    image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(image)
    image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _badge = UI.label(self, "", Rect2(30, 278, 480, 28), 17, UI.CYAN, true)
    UI.panel(self, Rect2(22,558,292,124), Color(0.025, 0.075, 0.145, 0.96), 20)
    _welcome = UI.label(self, "", Rect2(34,574,268,30),22, UI.GOLD, true)
    _goal = UI.label(self, "", Rect2(34,614,268,52),15, UI.WHITE)
    _review = UI.button(self, "", Rect2(1030, 634, 220, 52), menu_requested.emit)
    _review.add_theme_font_size_override("font_size", 18)
    refresh_texts()

func refresh_texts() -> void:
    _badge.text = tr("preview.badge")
    _welcome.text = tr("preview.welcome").format({"name":nickname})
    _goal.text = tr("preview.goal")
    _review.text = tr("preview.exit")

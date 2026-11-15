extends Control
signal play_requested()
signal options_requested()
signal tutorial_requested()
signal slots_requested()
const UI = preload("res://ui/ui_kit.gd")
var nickname := ""
var resume_available := false
var active_slot := 1
var slot_summary := {}
var play_button: Button
var slots_button: Button
var options_button: Button
var tutorial_button: Button
var _badge: Label
var _title: Label
var _greeting: Label
var _slot_footer: Label

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
    UI.panel(self, Rect2(740, 128, 480, 540), Color(0.025, 0.075, 0.145, 0.97), 24)
    _badge = UI.label(self, "", Rect2(770, 146, 420, 26), 15, UI.CYAN, true)
    _title = UI.label(self, "KILLAWASI", Rect2(770, 176, 420, 54), 34, UI.WHITE, true)
    _greeting = UI.label(self, "", Rect2(770, 236, 420, 54), 20, Color("#d7e6f3"))
    play_button = UI.button(self, "", Rect2(770, 304, 420, 58), play_requested.emit, true)
    slots_button = UI.button(self, "", Rect2(770, 376, 420, 54), slots_requested.emit)
    options_button = UI.button(self, "", Rect2(770, 444, 420, 52), options_requested.emit)
    tutorial_button = UI.button(self, "", Rect2(770, 510, 420, 58), tutorial_requested.emit)
    tutorial_button.add_theme_font_size_override("font_size", 20)
    _slot_footer = UI.label(self, "", Rect2(770, 584, 420, 62), 14, Color("#9bb6cc"))
    refresh_texts()

func refresh_texts() -> void:
    _title.text = tr("home.badge")
    _badge.text = "%s · %s" % [tr("guide.menu_tag"), tr("live.slot_label").format({"slot": active_slot})]
    _greeting.text = tr("home.greeting").format({"name":nickname})
    play_button.text = tr("home.resume" if resume_available else "home.play")
    if is_instance_valid(slots_button):
        slots_button.text = tr("live.slots_button")
    options_button.text = tr("home.options")
    tutorial_button.text = tr("home.tutorial")
    if is_instance_valid(_slot_footer):
        if bool(slot_summary.get("occupied", false)):
            var done := int(slot_summary.get("missions_done", 0))
            var stars := int(slot_summary.get("stars_total", 0))
            _slot_footer.text = "%s · %d ★" % [tr("live.slot_missions").format({"done": done}), stars]
        else:
            _slot_footer.text = tr("live.slot_empty")

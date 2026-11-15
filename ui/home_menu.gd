extends Control
signal play_requested()
signal options_requested()
signal tutorial_requested()
signal restart_requested()
const UI = preload("res://ui/ui_kit.gd")
var nickname := ""
var resume_available := false
var play_button: Button
var options_button: Button
var tutorial_button: Button
var restart_button: Button
var _restart_confirmation: Control
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
    UI.panel(self, Rect2(740, 150, 480, 536), Color(0.025, 0.075, 0.145, 0.97), 24)
    _badge = UI.label(self, "", Rect2(770, 170, 420, 28), 16, UI.CYAN, true)
    _title = UI.label(self, "KILLAWASI", Rect2(770, 210, 420, 54), 34, UI.WHITE, true)
    _greeting = UI.label(self, "", Rect2(770, 276, 420, 62), 21, Color("#d7e6f3"))
    play_button = UI.button(self, "", Rect2(770, 354, 420, 58), play_requested.emit, true)
    options_button = UI.button(self, "", Rect2(770, 426, 420, 52), options_requested.emit)
    tutorial_button = UI.button(self, "", Rect2(770, 492, 420, 58), tutorial_requested.emit)
    tutorial_button.add_theme_font_size_override("font_size", 21)
    restart_button = UI.button(self, "", Rect2(770, 566, 420, 58), _confirm_restart)
    restart_button.name = "StartOverButton"
    restart_button.add_theme_stylebox_override("normal", UI.style(Color("#192b42"), Color("#ff927a"), 2))
    refresh_texts()

func refresh_texts() -> void:
    _title.text = tr("home.badge")
    _badge.text = tr("guide.menu_tag")
    _greeting.text = tr("home.greeting").format({"name":nickname})
    play_button.text = tr("home.resume" if resume_available else "home.play")
    options_button.text = tr("home.options")
    tutorial_button.text = tr("home.tutorial")
    restart_button.text = tr("nav.start_over")

func _confirm_restart() -> void:
    if is_instance_valid(_restart_confirmation): return
    _restart_confirmation = Control.new()
    _restart_confirmation.name = "RestartConfirmation"
    _restart_confirmation.size = Vector2(1280,720)
    _restart_confirmation.z_index = 30
    add_child(_restart_confirmation)
    var shade = ColorRect.new()
    shade.color = Color(0.01,0.03,0.07,0.85)
    shade.size = Vector2(1280,720)
    _restart_confirmation.add_child(shade)
    var panel = UI.panel(_restart_confirmation,Rect2(300,190,680,340),UI.INK)
    panel.mouse_filter = MOUSE_FILTER_STOP
    UI.label(panel,tr("nav.start_over"),Rect2(28,24,624,52),30,UI.GOLD,true)
    UI.label(panel,tr("live.confirm_restart"),Rect2(28,98,624,112),24,UI.WHITE)
    var cancel = UI.button(panel,tr("live.cancel"),Rect2(28,252,300,56),_cancel_restart)
    cancel.name = "CancelRestart"
    var confirm = UI.button(panel,tr("nav.start_over"),Rect2(352,252,300,56),func():
        _restart_confirmation.queue_free()
        _restart_confirmation = null
        restart_requested.emit()
    ,true)
    confirm.name = "ConfirmRestart"
    cancel.focus_next = cancel.get_path_to(confirm)
    cancel.focus_previous = cancel.focus_next
    confirm.focus_next = confirm.get_path_to(cancel)
    confirm.focus_previous = confirm.focus_next
    cancel.grab_focus()
func _cancel_restart() -> void:
    if is_instance_valid(_restart_confirmation): _restart_confirmation.queue_free()
    _restart_confirmation = null
    restart_button.grab_focus()
func _unhandled_key_input(event: InputEvent) -> void:
    if is_instance_valid(_restart_confirmation) and event.is_action_pressed("ui_cancel"):
        _cancel_restart()
        get_viewport().set_input_as_handled()

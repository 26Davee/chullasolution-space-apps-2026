extends Control
signal resource_pressed(id: String)
const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")
const Clock = preload("res://ui/mission_clock.gd")
const RESOURCES := ["energia", "agua", "oxigeno", "vida", "escudo"]
const COLORS := {"energia": Color("#ffc64f"), "agua": Color("#68b9ff"), "oxigeno": Color("#7fe7bf"), "vida": Color("#54d7d6"), "escudo": Color("#ff927a")}
var resource_buttons: Dictionary = {}
var bars: Dictionary = {}
var values: Dictionary = {}
var _labels: Dictionary = {}
var _state: Dictionary = {}
var _target := ""
var _mode := ""
var _counters: Label
var _day: Label
var _phase: Label
var _practice: Label
var _tool: Label

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    size = Vector2(1220, 188)
    for i in range(RESOURCES.size()):
        _resource(RESOURCES[i], Rect2(i * 246, 0, 236, 88))
    UI.panel(self, Rect2(0, 100, 920, 54), Color("#0a2139"), 14)
    _counters = UI.label(self, "", Rect2(18, 111, 280, 32), 18, UI.GOLD, true)
    _tool = UI.label(self, "", Rect2(308, 111, 300, 32), 17, Color("#c7dce9"))
    _phase = UI.label(self, "", Rect2(616, 111, 286, 32), 17, UI.CYAN)
    _phase.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    UI.panel(self, Rect2(940, 100, 280, 54), Color("#0a2139"), 14)
    _day = UI.label(self, "", Rect2(954, 109, 252, 36), 24, UI.WHITE, true)
    _day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _practice = UI.label(self, tr("tutorial.practice_badge"), Rect2(0, 164, 1220, 22), 15, UI.CYAN)
    refresh()

func _resource(id: String, rect: Rect2) -> void:
    var card := UI.button(self, "", rect, resource_pressed.emit.bind(id))
    card.name = "Resource_" + id
    resource_buttons[id] = card
    var icon := Icon.new()
    icon.kind = id
    icon.tint = COLORS[id]
    icon.position = Vector2(12, 18)
    icon.size = Vector2(40, 40)
    card.add_child(icon)
    _labels[id] = UI.label(card, "", Rect2(62, 10, 162, 28), 20, UI.WHITE, true)
    values[id] = UI.label(card, "", Rect2(166, 43, 58, 28), 18, UI.WHITE, true)
    values[id].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    var bar := ProgressBar.new()
    bar.position = Vector2(62, 50)
    bar.size = Vector2(96, 16)
    bar.show_percentage = false
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    # Hidden percentage text still affects ProgressBar minimum height in Godot.
    bar.add_theme_font_size_override("font_size", 1)
    bar.add_theme_stylebox_override("background", UI.style(Color("#34445d"), Color.TRANSPARENT, 0, 8))
    bar.add_theme_stylebox_override("fill", UI.style(COLORS[id], Color.TRANSPARENT, 0, 8))
    card.add_child(bar)
    bar.size = Vector2(96, 16)
    bars[id] = bar

func set_state(state: Dictionary) -> void:
    _state = state.duplicate(true)
    if is_node_ready(): refresh()

func set_target(target: String) -> void:
    _target = target
    if is_node_ready(): refresh()

func set_mode(mode: String) -> void:
    _mode = mode
    if is_node_ready(): refresh()

func set_practice(practice: bool) -> void:
    if is_instance_valid(_practice): _practice.visible = practice

func refresh() -> void:
    for id in RESOURCES:
        var entry: Dictionary = _state.get(id, {"value": 0.0, "max": 100.0})
        var maximum := maxf(float(entry.get("max", 100)), 1)
        var value := clampf(float(entry.get("value", 0)), 0, maximum)
        bars[id].max_value = maximum
        bars[id].value = value
        values[id].text = "%d %%" % roundi(value / maximum * 100)
        _labels[id].text = tr("hud." + id + ".nombre")
        var card: Button = resource_buttons[id]
        card.tooltip_text = "%s · %d / %d\n%s" % [tr("hud." + id + ".nombre"), roundi(value), roundi(maximum), tr("hud." + id + ".help")]
        UI.paint(card)
        if _target == "resource:" + id:
            card.add_theme_stylebox_override("normal", UI.style(Color("#183b50"), UI.GOLD, 3))
    _counters.text = tr("hud.counters").format({"ice": int(_state.get("hielo", 0)), "stars": int(_state.get("estrellas", 0))})
    _day.text = tr("hud.clock").format(Clock.display(_state))
    _phase.text = tr("hud.day" if _state.get("es_dia", true) else "hud.night")
    if not _mode.is_empty(): _phase.text += " · " + tr("mode." + _mode)
    var tools := ["pala", "pico", "taladro_manual", "taladro_mochila"]
    var level := clampi(int(_state.get("herramienta_nivel", 1)), 1, 4)
    _tool.text = tr("hud.tool").format({"tool": tr("tools." + tools[level - 1])})
    _practice.text = tr("tutorial.practice_badge")

func focus_target() -> void:
    var parts := _target.split(":")
    if parts.size() == 2:
        if parts[0] == "resource" and resource_buttons.has(parts[1]): resource_buttons[parts[1]].grab_focus()

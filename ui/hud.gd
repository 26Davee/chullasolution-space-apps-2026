extends Control
signal resource_pressed(id: String)
const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")
const Clock = preload("res://ui/mission_clock.gd")
const RESOURCES := ["energia", "agua", "oxigeno", "escudo"]
const COLORS := {"energia": Color("#ffc64f"), "agua": Color("#68b9ff"), "oxigeno": Color("#7fe7bf"), "escudo": Color("#ff927a")}
var resource_buttons: Dictionary = {}
var bars: Dictionary = {}
var values: Dictionary = {}
var _labels: Dictionary = {}
var _units: Dictionary = {}
var _state: Dictionary = {}
var _target := ""
var _mode := ""
var _show_robot_bar := false
var _status_panel: Panel
var _robot_panel: Panel
var _robot_title: Label
var _robot_bar: ProgressBar
var _robot_value: Label
var _counters: Label
var _day: Label
var _phase: Label
var _practice: Label
var _tool: Label

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    size = Vector2(1220, 188)
    for i in range(RESOURCES.size()):
        _resource(RESOURCES[i], Rect2(i * 308, 0, 296, 88))
    _robot_panel = UI.panel(self, Rect2(0, 100, 324, 54), Color("#0a2139"), 14)
    _robot_panel.mouse_filter = Control.MOUSE_FILTER_PASS
    _robot_panel.visible = false
    var r_icon := Icon.new()
    r_icon.kind = "robot_battery"
    r_icon.tint = Color("#74e8ff")
    r_icon.position = Vector2(10, 11)
    r_icon.size = Vector2(32, 32)
    _robot_panel.add_child(r_icon)
    _robot_title = UI.label(_robot_panel, "", Rect2(48, 4, 182, 20), 13, Color("#bfe9ff"), true)
    _robot_bar = ProgressBar.new()
    _robot_bar.position = Vector2(48, 28)
    _robot_bar.size = Vector2(182, 14)
    _robot_bar.show_percentage = false
    _robot_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _robot_bar.add_theme_font_size_override("font_size", 1)
    _robot_bar.add_theme_stylebox_override("background", UI.style(Color("#34445d"), Color.TRANSPARENT, 0, 7))
    _robot_bar.add_theme_stylebox_override("fill", UI.style(Color("#74e8ff"), Color.TRANSPARENT, 0, 7))
    _robot_panel.add_child(_robot_bar)
    _robot_value = UI.label(_robot_panel, "100 %", Rect2(236, 13, 76, 28), 16, UI.WHITE, true)
    _robot_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

    _status_panel = UI.panel(self, Rect2(0, 100, 860, 54), Color("#0a2139"), 14)
    _counters = UI.label(_status_panel, "", Rect2(16, 11, 260, 32), 18, UI.GOLD, true)
    _tool = UI.label(_status_panel, "", Rect2(282, 11, 280, 32), 17, Color("#c7dce9"))
    _phase = UI.label(_status_panel, "", Rect2(568, 11, 276, 32), 17, UI.CYAN)
    _phase.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    UI.panel(self, Rect2(878, 100, 342, 54), Color("#0a2139"), 14)
    _day = UI.label(self, "", Rect2(890, 109, 318, 36), 21, UI.WHITE, true)
    _day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _day.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _practice = UI.label(self, tr("tutorial.practice_badge"), Rect2(0, 164, 1220, 22), 15, UI.CYAN)
    _layout_row2()
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
    _labels[id] = UI.label(card, "", Rect2(62, 8, 222, 26), 19, UI.WHITE, true)
    values[id] = UI.label(card, "", Rect2(226, 38, 58, 26), 17, UI.WHITE, true)
    values[id].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _units[id] = UI.label(card, "", Rect2(62, 65, 224, 18), 12, Color("#b9e1f5"))
    var bar := ProgressBar.new()
    bar.position = Vector2(62, 44)
    bar.size = Vector2(156, 15)
    bar.show_percentage = false
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    # Hidden percentage text still affects ProgressBar minimum height in Godot.
    bar.add_theme_font_size_override("font_size", 1)
    bar.add_theme_stylebox_override("background", UI.style(Color("#34445d"), Color.TRANSPARENT, 0, 8))
    bar.add_theme_stylebox_override("fill", UI.style(COLORS[id], Color.TRANSPARENT, 0, 8))
    card.add_child(bar)
    bar.size = Vector2(156, 15)
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

func set_show_robot_bar(visible_flag: bool) -> void:
    _show_robot_bar = visible_flag
    if is_node_ready():
        _layout_row2()
        refresh()

func _layout_row2() -> void:
    if not is_instance_valid(_status_panel):
        return
    if is_instance_valid(_robot_panel):
        _robot_panel.visible = _show_robot_bar
    if _show_robot_bar:
        _status_panel.position = Vector2(334, 100)
        _status_panel.size = Vector2(534, 54)
        _counters.position = Vector2(12, 11)
        _counters.size = Vector2(204, 32)
        _counters.add_theme_font_size_override("font_size", 15)
        _tool.position = Vector2(218, 11)
        _tool.size = Vector2(162, 32)
        _tool.add_theme_font_size_override("font_size", 15)
        _phase.position = Vector2(382, 11)
        _phase.size = Vector2(140, 32)
        _phase.add_theme_font_size_override("font_size", 15)
    else:
        _status_panel.position = Vector2(0, 100)
        _status_panel.size = Vector2(860, 54)
        _counters.position = Vector2(16, 11)
        _counters.size = Vector2(260, 32)
        _counters.add_theme_font_size_override("font_size", 18)
        _tool.position = Vector2(282, 11)
        _tool.size = Vector2(280, 32)
        _tool.add_theme_font_size_override("font_size", 17)
        _phase.position = Vector2(568, 11)
        _phase.size = Vector2(276, 32)
        _phase.add_theme_font_size_override("font_size", 17)

func refresh() -> void:
    var mode_name := _mode if not _mode.is_empty() else str(_state.get("modo_juego", "cadete"))
    var diff := 0.75 if mode_name == "cadete" else 1.0
    var storm_active := bool(_state.get("nube_activa", false))
    for id in RESOURCES:
        var entry: Dictionary = _state.get(id, {"value": 0.0, "max": 100.0})
        var maximum := maxf(float(entry.get("max", 100)), 1)
        var value := clampf(float(entry.get("value", 0)), 0, maximum)
        bars[id].max_value = maximum
        bars[id].value = value
        values[id].text = "%d %%" % roundi(value / maximum * 100)
        _labels[id].text = tr("hud." + id + ".nombre")
        var unit_text := _kid_unit_label(id, value, maximum, diff, storm_active)
        if _units.has(id):
            _units[id].text = unit_text
        var card: Button = resource_buttons[id]
        card.tooltip_text = "%s · %s\n%s" % [tr("hud." + id + ".nombre"), unit_text, tr("hud." + id + ".help")]
        UI.paint(card)
        if _target == "resource:" + id:
            card.add_theme_stylebox_override("normal", UI.style(Color("#183b50"), UI.GOLD, 3))
    if is_instance_valid(_robot_panel) and _show_robot_bar:
        var r_entry: Dictionary = _state.get("energia_robot", {"value": 100.0, "max": 100.0})
        var r_max := maxf(float(r_entry.get("max", 100.0)), 1.0)
        var r_val := clampf(float(r_entry.get("value", 100.0)), 0.0, r_max)
        var r_pct := roundi(r_val / r_max * 100.0)
        var drive_hours := roundi((r_val / r_max) * (5420.0 / 300.0))
        _robot_bar.max_value = r_max
        _robot_bar.value = r_val
        _robot_value.text = "%d %%" % r_pct
        if bool(_state.get("descansando_en_domo", false)):
            _robot_title.text = tr("hud.unit.robot_charging")
        else:
            _robot_title.text = "%s · ~%dh" % [tr("hud.energia_robot.nombre"), drive_hours]
        _robot_panel.tooltip_text = "%s · %.1f / 5.4 kWh (%s)\n%s" % [
            tr("hud.energia_robot.nombre"),
            (r_val / r_max) * 5.42,
            tr("hud.unit.robot_ready").format({"hours": drive_hours}),
            tr("hud.energia_robot.help"),
        ]
    var ice_blocks := int(_state.get("hielo", 0))
    _counters.text = tr("hud.counters").format({
        "ice": ice_blocks,
        "ice_max": 10,
        "liters": ice_blocks * 10,
        "stars": int(_state.get("estrellas", 0)),
    })
    var clock_data := Clock.display(_state)
    var clock_key := "hud.clock"
    var clock_size := 24
    if int(clock_data.get("year", 1)) > 1:
        clock_key = "hud.clock_year"
        clock_size = 19
    elif int(clock_data.get("month", 1)) > 1:
        clock_key = "hud.clock_month"
        clock_size = 22
    _day.add_theme_font_size_override("font_size", clock_size)
    _day.text = tr(clock_key).format(clock_data)
    _phase.text = tr("hud.day" if _state.get("es_dia", true) else "hud.night")
    if not _mode.is_empty(): _phase.text += " · " + tr("mode." + _mode)
    var tools := ["pala", "pico", "taladro_manual", "taladro_mochila"]
    var level := clampi(int(_state.get("herramienta_nivel", 1)), 1, 4)
    _tool.text = tr("hud.tool").format({"tool": tr("tools." + tools[level - 1])})
    _practice.text = tr("tutorial.practice_badge")

func _kid_unit_label(id: String, value: float, maximum: float, diff: float, storm_active: bool) -> String:
    match id:
        "energia":
            # 100% = 2,000 kWh; minimum 4-crew night load = 113.2 kWh/day (* diff)
            var kwh := value * 20.0
            var daily_kwh := 113.23 * diff
            var days_left := kwh / maxf(daily_kwh, 1.0)
            return tr("hud.unit.days_base").format({"days": "%.1f" % days_left})
        "agua":
            # 100% = 200 Liters potable reserve
            return tr("hud.unit.liters").format({"liters": roundi(value * 2.0), "max_liters": roundi(maximum * 2.0)})
        "oxigeno":
            # 100% = 50 kg O2; 4 humans consume 3.40 kg/day (* diff)
            var kg_o2 := value * 0.50
            var days_air := kg_o2 / (3.40 * diff)
            return tr("hud.unit.days_air").format({"days": "%.1f" % days_air})
        "escudo":
            return tr("hud.unit.shield_storm" if storm_active else "hud.unit.shield_ok")
    return ""

func focus_target() -> void:
    var parts := _target.split(":")
    if parts.size() == 2:
        if parts[0] == "resource" and resource_buttons.has(parts[1]): resource_buttons[parts[1]].grab_focus()

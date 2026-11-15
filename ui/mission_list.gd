extends Control
const UI = preload("res://ui/ui_kit.gd")
const Catalog = preload("res://ui/progression_catalog.gd")
var _items: Array[Dictionary] = []
var _progress: Dictionary = {}
var _mode := "cadete"
var _selected := ""
var _training := true
var _title: Label
var _reward: Label
var _objectives: Label
var _status: Label
var _buttons: Dictionary = {}

func configure(items: Array[Dictionary], progress: Dictionary, training: bool, mode := "cadete") -> void:
    _items = items.duplicate(true)
    _progress = progress.duplicate(true)
    _training = training
    _mode = mode
    if is_node_ready():
        _build()

func set_tutorial_mode(value: bool) -> void:
    _training = value

func _ready() -> void:
    _build()

func _build() -> void:
    for child in get_children():
        remove_child(child)
        child.queue_free()
    _buttons.clear()
    UI.label(self, tr("mission.log"), Rect2(0, 0, 280, 30), 19, UI.CYAN, true)
    var scroll := ScrollContainer.new()
    scroll.position = Vector2(0, 40)
    scroll.size = Vector2(286, 404)
    scroll.follow_focus = true
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(scroll)
    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 8)
    scroll.add_child(list)
    for item in _items:
        var id := str(item.id)
        var button := UI.button(list, Catalog.text("misiones." + id + ".titulo", str(item.get("mision", id))), Rect2(0, 0, 264, 66), _select.bind(id))
        button.custom_minimum_size = Vector2(264, 66)
        button.add_theme_font_size_override("font_size", 16)
        button.name = "Mission_" + id
        _buttons[id] = button
    _title = UI.label(self, "", Rect2(312, 40, 564, 92), 27, UI.WHITE, true)
    _reward = UI.label(self, "", Rect2(312, 144, 564, 30), 20, UI.GOLD, true)
    _objectives = UI.label(self, "", Rect2(312, 198, 564, 196), 22, UI.WHITE)
    _status = UI.label(self, "", Rect2(312, 410, 564, 32), 18, UI.CYAN)
    if _selected.is_empty() and not _items.is_empty():
        _selected = str(_progress.get("current_mission", "")) if not _training else str(_items[0].id)
        if _selected.is_empty(): _selected = str(_items[0].id)
    _select(_selected)

func _select(id: String) -> void:
    _selected = id
    for key in _buttons:
        UI.paint(_buttons[key], key == id)
    for item in _items:
        if str(item.id) != id:
            continue
        _title.text = Catalog.text("misiones." + id + ".titulo", str(item.get("mision", id)))
        var points: Dictionary = item.get("puntos", {})
        _reward.text = tr("mission.reward").format({"stars": int(points.get(_mode, 0))})
        var fallback := "\n".join(item.get("objetivo", []))
        _objectives.text = Catalog.text("misiones." + id + ".objetivo", fallback)
        if _training:
            _status.text = tr("mission.preview")
        elif id in _progress.get("completed_missions", []):
            _status.text = tr("mission.completed")
        else:
            _status.text = tr("mission.current" if id == _progress.get("current_mission", "") else "mission.upcoming")
            if id == _progress.get("current_mission", "") and _progress.has("objective_total"):
                _status.text += " · " + tr("live.progress").format({"done": _progress.get("objective_done", 0), "total": _progress.objective_total})

func set_progression_state(state: Dictionary) -> void:
    _progress = state.duplicate(true)
    _select(_selected)

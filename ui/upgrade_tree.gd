extends Control
signal purchase_requested(id: String)
const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")
const Catalog = preload("res://ui/progression_catalog.gd")
const COLORS := [Color("#ffc64f"), Color("#54d7d6"), Color("#ff927a"), Color("#bc9fff")]
var _items: Array[Dictionary] = []
var _progress: Dictionary = {}
var _training := true
var _selected := ""
var _nodes: Dictionary = {}
var _lines: Array = []
var _roots: Array = []
var _colors: Dictionary = {}
var _detail: Label
var _effect: Label
var _buy: Button
var _status: Label
var _cost: Label

func configure(items: Array[Dictionary], progress: Dictionary, training: bool, _mode := "") -> void:
    _items = items.duplicate(true)
    _progress = progress.duplicate(true)
    _training = training
    if is_node_ready(): _build()

func set_tutorial_mode(value: bool) -> void:
    _training = value

func _ready() -> void:
    _build()

func _build() -> void:
    for child in get_children():
        remove_child(child)
        child.queue_free()
    _nodes.clear()
    _lines.clear()
    _roots.clear()
    _colors.clear()
    var map_width := size.x - 310.0
    var height := size.y
    var branches: Array[String] = []
    for item in _items:
        var branch := str(item.get("branch", ""))
        if not branch in branches: branches.append(branch)
    var width := map_width / maxf(branches.size(), 1)
    var base_center := Vector2(map_width / 2.0, height - 58)
    for i in range(branches.size()):
        var heading := UI.label(self, Catalog.text("branches." + branches[i], branches[i]), Rect2(i * width, 0, width, 38), 20, COLORS[i % COLORS.size()], true)
        heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    for item in _items:
        var id := str(item.id)
        var branch_index := branches.find(str(item.get("branch", "")))
        var color: Color = COLORS[branch_index % COLORS.size()]
        _colors[id] = color
        var level := clampi(int(item.get("nivel", 1)), 1, 3)
        var row_space := (height - 154.0) / 3.0
        var center := Vector2((branch_index + 0.5) * width, height - 176.0 - (level - 1) * row_space)
        var button := UI.button(self, "", Rect2(center - Vector2(31, 31), Vector2(62, 62)), _select.bind(id))
        button.name = "Upgrade_" + id
        button.tooltip_text = Catalog.text("upgrades." + id + ".nombre", str(item.get("nombre", id)))
        var icon := Icon.new()
        icon.name = "StateIcon"
        icon.position = Vector2(14, 14)
        icon.size = Vector2(34, 34)
        icon.disc = false
        button.add_child(icon)
        var badge := UI.panel(button, Rect2(42, 7, 44, 26), Color("#142c46"), 13)
        var cost := UI.label(badge, "%d ★" % int(item.get("costo", item.get("costo_estrellas", 0))), Rect2(0, 0, 44, 26), 14, color, true)
        cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        UI.panel(self, Rect2(center.x - width / 2 + 6, center.y + 36, width - 12, 46), Color("#0c243d"), 10)
        var caption := UI.label(self, button.tooltip_text, Rect2(center.x - width / 2 + 8, center.y + 36, width - 16, 44), 16, UI.WHITE, true)
        caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        _nodes[id] = button
        if item.get("requisito") == null:
            _roots.append([base_center, center, color])
    for item in _items:
        var requirement: Variant = item.get("requisito")
        if requirement != null and _nodes.has(str(requirement)):
            var from: Button = _nodes[str(requirement)]
            var to: Button = _nodes[str(item.id)]
            _lines.append([from.position + Vector2(31, 31), to.position + Vector2(31, 31), _colors[str(item.id)]])
    var base_icon := Icon.new()
    base_icon.kind = "base"
    base_icon.tint = UI.GOLD
    base_icon.position = base_center - Vector2(32, 32)
    base_icon.size = Vector2(64, 64)
    add_child(base_icon)
    var base_label := UI.label(self, tr("tree.base"), Rect2(base_center.x - 100, base_center.y + 38, 200, 24), 18, UI.GOLD, true)
    base_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var side_x := map_width + 20.0
    UI.panel(self, Rect2(side_x, 0, 290, height), Color("#071b32"), 18)
    UI.label(self, tr("tree.inspect"), Rect2(side_x + 18, 16, 254, 54), 17, UI.CYAN)
    _detail = UI.label(self, "", Rect2(side_x + 18, 84, 254, 80), 26, UI.GOLD, true)
    _effect = UI.label(self, "", Rect2(side_x + 18, 180, 254, height - 338), 20, UI.WHITE)
    _cost = UI.label(self, "", Rect2(side_x + 18, height - 154, 254, 28), 19, UI.GOLD, true)
    _status = UI.label(self, "", Rect2(side_x + 18, height - 116, 254, 42), 16, Color("#c4dbeb"))
    _buy = UI.button(self, tr("tree.buy"), Rect2(side_x + 18, height - 60, 254, 44), _request_purchase, true)
    _buy.add_theme_font_size_override("font_size", 17)
    if _selected.is_empty() and not _items.is_empty(): _selected = str(_items[0].id)
    _select(_selected)
    queue_redraw()

func _draw() -> void:
    for i in range(28):
        var point := Vector2(fmod(i * 83.0 + 17, maxf(size.x - 310, 1)), fmod(i * 113.0 + 33, maxf(size.y - 16, 1)))
        draw_circle(point, 1.1, Color(0.5, 0.75, 0.9, 0.22))
    for line in _roots + _lines:
        var color: Color = line[2]
        color.a = 0.48
        draw_line(line[0], line[1], color, 4, true)

func _owned(id: String) -> bool:
    return id in _progress.get("unlocked_upgrades", [])

func _can_buy(item: Dictionary) -> bool:
    var requirement: Variant = item.get("requisito")
    var cost := int(item.get("costo", item.get("costo_estrellas", 0)))
    return not _owned(str(item.id)) and (requirement == null or _owned(str(requirement))) and int(_progress.get("stars", 0)) >= cost

func _item_status(item: Dictionary) -> String:
    if _owned(str(item.id)): return tr("tree.owned")
    return tr("tree.available" if _can_buy(item) else "tree.locked")

func _select(id: String) -> void:
    _selected = id
    for item in _items:
        var key := str(item.id)
        var node: Button = _nodes[key]
        var color: Color = _colors[key]
        var owned := _owned(key)
        node.add_theme_stylebox_override("normal", UI.style(color if owned else Color("#102b46"), UI.WHITE if key == id else color, 4 if key == id else 2, 31))
        node.add_theme_stylebox_override("hover", UI.style(Color("#25465d"), UI.WHITE, 3, 31))
        node.add_theme_stylebox_override("pressed", UI.style(Color("#36586e"), UI.GOLD, 4, 31))
        node.add_theme_stylebox_override("focus", UI.style(Color.TRANSPARENT, UI.CYAN, 3, 31))
        var icon: Control = node.get_node("StateIcon")
        icon.kind = "check" if owned else ("base" if _can_buy(item) else "lock")
        icon.tint = UI.INK if owned else color
        icon.queue_redraw()
        if key != id: continue
        _detail.text = Catalog.text("upgrades." + id + ".nombre", str(item.get("nombre", id)))
        var effect: Dictionary = item.get("efecto", {})
        _effect.text = Catalog.text("upgrades." + id + ".efecto", str(effect.get("descripcion", "")))
        _cost.text = tr("tree.cost").format({"cost": int(item.get("costo", item.get("costo_estrellas", 0)))})
        _status.text = tr("tree.practice_help") if _training else _item_status(item)
        _buy.text = tr("tree.practice") if _training else tr("tree.buy")
        _buy.disabled = _training or not _can_buy(item)
        _buy.tooltip_text = tr("tree.practice_help") if _training else tr("tree.purchase_help")

func _request_purchase() -> void:
    if not _training and not _buy.disabled: purchase_requested.emit(_selected)

func set_progression_state(state: Dictionary) -> void:
    _progress = state.duplicate(true)
    _select(_selected)

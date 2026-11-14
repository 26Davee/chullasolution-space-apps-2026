extends Control
## Reusable, local-only visual demonstrations. Never changes game resources.
signal narration_requested(text: String)
const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")
const ART := "res://assets/ui/activities/"
const MODULES := ["panel_solar", "procesador_hielo", "generador_oxigeno", "jardin"]
const IMAGES := ["solar", "processor", "oxygen", "garden"]
const SCIENCE := [
    {"id":"solar", "image":"solar", "url":"https://science.nasa.gov/learn/heat/big-ideas/big-idea-3-1/"},
    {"id":"ice", "image":"ice_map", "url":"https://science.nasa.gov/moon/moon-water-and-ices/"},
    {"id":"air", "image":"oxygen", "url":"https://science.nasa.gov/moon/lunar-atmosphere/"},
    {"id":"shield", "image":"repair", "url":"https://science.nasa.gov/moon/weather-on-the-moon/"}
]
var section := "construction"
var _selected_module := 0
var _placed_module := -1
var _module_buttons: Array[Button] = []
var _plots: Array[Button] = []
var _plot_images: Array[TextureRect] = []
var _feedback: Label
var _heading: Label
var _zone_buttons: Array[Button] = []
var _zone := -1
var _scanned: Dictionary = {}
var _scan_button: Button
var _route: Line2D
var _process_step := 0
var _process_buttons: Array[Button] = []
var _flow_icons: Array[Control] = []
var _patched: Dictionary = {}
var _patch_buttons: Array[Button] = []
var _shield_tween: Tween
var _shield_bar: ProgressBar
var _shield_value: Label
var _pin_cards: Array[Button] = []
var _pins: Dictionary = {}
var _selected_card := 0
var _pin_button: Button
var _source_button: Button
var _counter: Label
var _card_title: Label
var _card_fact: Label
var _card_art: TextureRect

func _ready() -> void:
    UI.label(self, tr("visual.practice"), Rect2(0, 0, 884, 30), 16, UI.CYAN, true)
    match section:
        "construction": _build_construction()
        "expedition": _build_expedition()
        "processing": _build_processing()
        "repair": _build_repair()
        "science": _build_science()

func _picture(parent: Node, id: String, rect: Rect2) -> TextureRect:
    var image := TextureRect.new()
    image.texture = load(ART + id + "-v1.png")
    image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    image.position = rect.position
    image.size = rect.size
    parent.add_child(image)
    return image

func _button(parent: Node, text: String, rect: Rect2, callback: Callable, active := false) -> Button:
    var button := UI.button(parent, text, rect, callback, active)
    button.add_theme_font_size_override("font_size", 18)
    button.size = rect.size
    return button

func _symbol(parent: Node, id: String, rect: Rect2, color := UI.CYAN) -> Control:
    var icon := Icon.new()
    icon.kind = id
    icon.tint = color
    icon.position = rect.position
    icon.size = rect.size
    parent.add_child(icon)
    return icon

func _tell(text: String) -> void:
    narration_requested.emit(text)

func _build_construction() -> void:
    for i in range(MODULES.size()):
        var card := _button(self, "", Rect2(i * 224, 44, 212, 236), _choose_module.bind(i))
        card.clip_contents = true
        _picture(card, IMAGES[i], Rect2(10, 10, 192, 158))
        var title := UI.label(card, tr("structures." + MODULES[i]), Rect2(12, 178, 188, 50), 19, UI.WHITE, true)
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        _module_buttons.append(card)
    UI.panel(self, Rect2(0, 300, 884, 140), Color("#071b32"), 18)
    var preview := UI.panel(self, Rect2(16, 316, 112, 112), Color("#17344f"), 14)
    _symbol(preview, "base", Rect2(30, 30, 52, 52), Color("#65859a"))
    var image := _picture(preview, IMAGES[0], Rect2(6, 6, 100, 100))
    image.visible = false
    _plot_images.append(image)
    _heading = UI.label(self, "", Rect2(152, 312, 448, 40), 23, UI.GOLD, true)
    _feedback = UI.label(self, "", Rect2(152, 360, 448, 66), 20, UI.WHITE)
    var place := _button(self, tr("visual.build.place"), Rect2(624, 348, 240, 54), _place_module.bind(0), true)
    place.tooltip_text = tr("visual.build.single_hint")
    _plots.append(place)
    _choose_module(0, false)

func _choose_module(index: int, narrate := true) -> void:
    _selected_module = index
    for i in range(_module_buttons.size()):
        _module_buttons[i].add_theme_stylebox_override("normal", UI.style(Color("#16344d"), UI.GOLD if i == index else Color("#496c83"), 3 if i == index else 1))
    _plots[0].disabled = _placed_module == index
    _plots[0].text = tr("visual.build.place" if _placed_module < 0 else "visual.build.replace")
    _heading.text = tr("structures." + MODULES[index])
    _feedback.text = tr("visual.build." + IMAGES[index])
    if narrate: _tell(_heading.text + ". " + _feedback.text)

func _place_module(index: int) -> void:
    if index != 0: return
    _placed_module = _selected_module
    _plot_images[index].texture = load(ART + IMAGES[_selected_module] + "-v1.png")
    _plot_images[index].visible = true
    _plots[index].text = tr("visual.build.ready")
    _plots[index].disabled = true
    _plots[index].tooltip_text = tr("structures." + MODULES[_selected_module])
    _feedback.text = tr("visual.build.placed")
    _tell(_feedback.text)

func _build_expedition() -> void:
    _picture(self, "ice_map", Rect2(0, 44, 626, 396))
    _route = Line2D.new()
    _route.width = 4
    _route.default_color = UI.GOLD
    add_child(_route)
    var positions := [Vector2(326, 218), Vector2(503, 147), Vector2(505, 355)]
    for i in range(positions.size()):
        var pin := _button(self, "?", Rect2(positions[i] - Vector2(26, 26), Vector2(52, 52)), _choose_zone.bind(i))
        pin.tooltip_text = tr("visual.map.zone") + " " + str(i + 1)
        _zone_buttons.append(pin)
    UI.panel(self, Rect2(644, 44, 240, 396), Color("#071b32"), 18)
    _heading = UI.label(self, tr("visual.map.title"), Rect2(662, 62, 204, 64), 24, UI.GOLD, true)
    _feedback = UI.label(self, tr("visual.map.choose"), Rect2(662, 146, 204, 156), 21, UI.WHITE)
    _scan_button = _button(self, tr("visual.map.scan"), Rect2(662, 318, 204, 52), _scan_zone, true)
    _scan_button.disabled = true
    UI.label(self, tr("visual.map.demo"), Rect2(662, 386, 204, 44), 14, UI.CYAN)

func _choose_zone(index: int) -> void:
    _zone = index
    for i in range(_zone_buttons.size()): UI.paint(_zone_buttons[i], i == index)
    _heading.text = tr("visual.map.zone." + str(index))
    _feedback.text = tr("visual.map.result." + str(index)) if _scanned.has(index) else tr("visual.map.ready")
    _scan_button.disabled = _scanned.has(index)
    _route.points = PackedVector2Array([Vector2(94, 310), Vector2(235, 280), _zone_buttons[index].position + Vector2(26, 26)])

func _scan_zone() -> void:
    if _zone < 0: return
    _scanned[_zone] = true
    _zone_buttons[_zone].text = ""
    var found := _symbol(_zone_buttons[_zone], "ice" if _zone == 1 else "check", Rect2(10, 10, 32, 32), UI.INK)
    found.disc = false
    _feedback.text = tr("visual.map.result." + str(_zone))
    _scan_button.disabled = true
    _tell(_feedback.text)

func _build_processing() -> void:
    _picture(self, "processor", Rect2(0, 44, 530, 320))
    var symbols := ["ice", "agua", "oxigeno"]
    for i in range(3):
        _flow_icons.append(_symbol(self, symbols[i], Rect2(52 + i * 172, 384, 48, 48), Color("#52738a")))
        UI.label(self, tr("visual.flow." + symbols[i]), Rect2(18 + i * 172, 434, 116, 22), 16, UI.WHITE).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        if i < 2: UI.label(self, "→", Rect2(128 + i * 172, 386, 44, 40), 30, UI.GOLD)
    UI.panel(self, Rect2(558, 44, 326, 396), Color("#071b32"), 18)
    UI.label(self, tr("visual.process.title"), Rect2(578, 58, 286, 44), 23, UI.GOLD, true)
    for i in range(3):
        var button := _button(self, str(i + 1) + "  " + tr("visual.process.step." + str(i)), Rect2(578, 120 + i * 64, 286, 52), _process_action.bind(i))
        _process_buttons.append(button)
    _feedback = UI.label(self, tr("visual.process.start"), Rect2(578, 322, 286, 72), 20, UI.WHITE)
    _button(self, tr("visual.try_again"), Rect2(578, 398, 286, 42), _reset_processing)
    _refresh_processing()

func _refresh_processing() -> void:
    for i in range(3):
        _process_buttons[i].disabled = i != _process_step
        _process_buttons[i].text = ("✓  " if i < _process_step else str(i + 1) + "  ") + tr("visual.process.step." + str(i))
        UI.paint(_process_buttons[i], i == _process_step)
        _flow_icons[i].tint = UI.CYAN if i < _process_step else Color("#52738a")
        _flow_icons[i].queue_redraw()

func _process_action(index: int) -> void:
    if index != _process_step: return
    _process_step += 1
    _feedback.text = tr("visual.process.result." + str(index))
    _refresh_processing()
    if _process_step < 3: _process_buttons[_process_step].grab_focus()
    _tell(_feedback.text)

func _reset_processing() -> void:
    _process_step = 0
    _feedback.text = tr("visual.process.start")
    _refresh_processing()
    _process_buttons[0].grab_focus()

func _build_repair() -> void:
    _picture(self, "repair", Rect2(0, 44, 584, 396))
    for i in range(3):
        var point: Vector2 = [Vector2(300, 159), Vector2(392, 224), Vector2(278, 293)][i]
        var button := _button(self, str(i + 1), Rect2(point - Vector2(28, 28), Vector2(56, 56)), _patch.bind(i), true)
        button.tooltip_text = tr("visual.repair.patch") + " " + str(i + 1)
        _patch_buttons.append(button)
    UI.panel(self, Rect2(606, 44, 278, 396), Color("#071b32"), 18)
    UI.label(self, tr("visual.repair.title"), Rect2(626, 64, 238, 64), 24, UI.GOLD, true)
    _feedback = UI.label(self, tr("visual.repair.tap"), Rect2(626, 148, 238, 98), 21, UI.WHITE)
    _shield_value = UI.label(self, "35 %", Rect2(626, 264, 238, 34), 25, UI.CYAN, true)
    _shield_bar = ProgressBar.new()
    _shield_bar.position = Vector2(626, 310)
    _shield_bar.show_percentage = false
    _shield_bar.add_theme_font_size_override("font_size", 1)
    _shield_bar.add_theme_stylebox_override("background", UI.style(Color("#34445d")))
    _shield_bar.add_theme_stylebox_override("fill", UI.style(UI.CYAN))
    add_child(_shield_bar)
    _shield_bar.size = Vector2(238, 18)
    _shield_bar.value = 35
    _button(self, tr("visual.try_again"), Rect2(626, 374, 238, 50), _reset_repair)

func _patch(index: int) -> void:
    if _patched.has(index): return
    _patched[index] = true
    var button := _patch_buttons[index]
    button.text = "✓"
    button.add_theme_stylebox_override("normal", UI.style(UI.CYAN, UI.WHITE, 2, 14))
    var value := 35.0 + _patched.size() / 3.0 * 65.0
    if _shield_tween and _shield_tween.is_running(): _shield_tween.kill()
    _shield_tween = create_tween()
    _shield_tween.tween_property(_shield_bar, "value", value, 0.3)
    _shield_value.text = "%d %%" % roundi(value)
    _feedback.text = tr("visual.repair.done") if _patched.size() == 3 else tr("visual.repair.progress").format({"count":_patched.size()})
    if _patched.size() == 3: _tell(_feedback.text)

func _reset_repair() -> void:
    if _shield_tween and _shield_tween.is_running(): _shield_tween.kill()
    _patched.clear()
    for i in range(_patch_buttons.size()):
        _patch_buttons[i].text = str(i + 1)
        UI.paint(_patch_buttons[i], true)
    _shield_bar.value = 35
    _shield_value.text = "35 %"
    _feedback.text = tr("visual.repair.tap")

func _build_science() -> void:
    UI.panel(self, Rect2(0, 44, 558, 396), Color("#304151"), 18)
    for i in range(SCIENCE.size()):
        var point := Vector2(12 + (i % 2) * 274, 58 + (i / 2) * 188)
        var card := _button(self, "", Rect2(point, Vector2(260, 174)), _choose_card.bind(i))
        var card_image := _picture(card, SCIENCE[i].image, Rect2(8, 16, 122, 146))
        if SCIENCE[i].id == "ice":
            var detail := AtlasTexture.new()
            detail.atlas = card_image.texture
            var dimensions := detail.atlas.get_size()
            detail.region = Rect2(dimensions.x * 0.61, dimensions.y * 0.09, dimensions.x * 0.36, dimensions.y * 0.42)
            card_image.texture = detail
        UI.label(card, tr("science." + SCIENCE[i].id + ".title"), Rect2(142, 42, 108, 74), 19, UI.WHITE, true)
        UI.label(card, tr("visual.science.open"), Rect2(142, 128, 108, 30), 15, UI.CYAN)
        var pin := _symbol(card, "pin", Rect2(113, 2, 28, 28), Color("#8fa6ba"))
        pin.name = "Pin"
        _pin_cards.append(card)
    UI.panel(self, Rect2(582, 44, 302, 396), Color("#071b32"), 18)
    _card_title = UI.label(self, "", Rect2(600, 58, 266, 56), 24, UI.GOLD, true)
    _card_fact = UI.label(self, "", Rect2(600, 134, 266, 164), 21, UI.WHITE)
    _counter = UI.label(self, "", Rect2(600, 304, 266, 28), 17, UI.CYAN, true)
    _pin_button = _button(self, tr("visual.science.pin"), Rect2(600, 342, 266, 48), _pin_card, true)
    _source_button = _button(self, tr("visual.science.source"), Rect2(600, 400, 266, 40), _open_source)
    _choose_card(0, false)

func _choose_card(index: int, narrate := true) -> void:
    _selected_card = index
    for i in range(_pin_cards.size()):
        _pin_cards[i].add_theme_stylebox_override("normal", UI.style(Color("#152b43"), UI.GOLD if i == index else Color("#688193"), 3 if i == index else 1))
    _card_title.text = tr("science." + SCIENCE[index].id + ".title")
    _card_fact.text = tr("science." + SCIENCE[index].id + ".fact")
    _refresh_pins()
    if narrate: _tell(_card_title.text + ". " + _card_fact.text)

func _pin_card() -> void:
    if _pins.has(_selected_card): _pins.erase(_selected_card)
    else: _pins[_selected_card] = true
    _refresh_pins()

func _refresh_pins() -> void:
    _counter.text = tr("visual.science.count").format({"count":_pins.size(), "total": SCIENCE.size()})
    _pin_button.text = tr("visual.science.unpin" if _pins.has(_selected_card) else "visual.science.pin")
    for i in range(_pin_cards.size()):
        var pin := _pin_cards[i].get_node("Pin")
        pin.tint = UI.GOLD if _pins.has(i) else Color("#8fa6ba")
        pin.queue_redraw()

func set_pinned_cards(pins: Dictionary) -> void:
    _pins = pins
    if is_node_ready(): _refresh_pins()

func _open_source() -> void:
    OS.shell_open(SCIENCE[_selected_card].url)

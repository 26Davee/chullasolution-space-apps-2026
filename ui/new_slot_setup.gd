extends Control
## Screen shown when selecting an empty save slot: asks difficulty/age group and astronaut name.
signal confirmed(profile: Dictionary)
signal cancelled()

const UI = preload("res://ui/ui_kit.gd")
const Profile = preload("res://ui/player_profile.gd")

var slot_id: int = 1
var language: String = "en"
var _age_group: String = ""
var age_buttons: Dictionary = {}
var name_field: LineEdit
var start_button: Button
var back_button: Button
var astronaut_preview: SubViewportContainer
var _hint_label: Label
var _card_labels: Dictionary = {}

func _ready() -> void:
	size = Vector2(1280, 720)
	var backdrop := preload("res://ui/world_backdrop.gd").new()
	add_child(backdrop)
	var shade := ColorRect.new()
	shade.size = Vector2(1280, 720)
	shade.color = Color(0.01, 0.03, 0.08, 0.62)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var panel := UI.panel(self, Rect2(88, 48, 1104, 624), Color(0.025, 0.075, 0.145, 0.97), 24)
	UI.label(panel, tr("live.setup_title").format({"slot": slot_id}), Rect2(38, 28, 760, 44), 32, UI.WHITE, true)
	UI.label(panel, tr("live.setup_subtitle"), Rect2(38, 76, 860, 30), 17, Color("#b8cfe2"))

	UI.label(panel, tr("live.setup_mode"), Rect2(38, 126, 680, 32), 20, UI.CYAN, true)
	_build_age_card(panel, "7_9", Rect2(38, 168, 336, 178))
	_build_age_card(panel, "10_12", Rect2(394, 168, 336, 178))

	UI.label(panel, tr("live.setup_name"), Rect2(38, 370, 680, 32), 20, UI.CYAN, true)
	name_field = LineEdit.new()
	name_field.position = Vector2(38, 412)
	name_field.size = Vector2(440, 52)
	name_field.max_length = 18
	name_field.placeholder_text = tr("v2.name_placeholder")
	name_field.add_theme_stylebox_override("normal", UI.style(Color("#16354f"), Color("#7b9fb9"), 1))
	name_field.add_theme_stylebox_override("focus", UI.style(Color("#16354f"), UI.CYAN, 3))
	panel.add_child(name_field)
	name_field.text_submitted.connect(func(_v: String):
		if not _age_group.is_empty():
			_submit()
	)
	UI.label(panel, tr("v2.name_hint"), Rect2(496, 416, 240, 46), 16, Color("#c2d8e9"))

	UI.panel(panel, Rect2(772, 126, 294, 344), Color(0.04, 0.1, 0.19, 0.92), 18)
	var astro_title := UI.label(panel, tr("profile.astronaut"), Rect2(786, 140, 266, 34), 20, UI.GOLD, true)
	astro_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var preview := preload("res://ui/astronaut_preview.gd").new()
	preview.name = "AstronautPreview"
	preview.position = Vector2(786, 180)
	preview.size = Vector2(266, 274)
	panel.add_child(preview)
	astronaut_preview = preview

	back_button = UI.button(panel, tr("live.setup_back"), Rect2(38, 534, 240, 56), func(): cancelled.emit())
	_hint_label = UI.label(panel, tr("live.setup_need_mode"), Rect2(298, 542, 432, 42), 16, Color("#bcd3e4"))
	start_button = UI.button(panel, tr("live.setup_start"), Rect2(754, 534, 312, 56), _submit, true)
	_refresh_selection()
	age_buttons["7_9"].grab_focus()


func _build_age_card(parent: Node, group: String, rect: Rect2) -> void:
	var btn := UI.button(parent, "", rect, func():
		_age_group = group
		_refresh_selection()
		name_field.grab_focus()
	, false)
	btn.name = "SetupAge_" + group
	btn.toggle_mode = true
	age_buttons[group] = btn
	var title_lbl := UI.label(btn, tr("profile.age." + group), Rect2(20, 16, 296, 40), 26, UI.WHITE, true)
	var body_lbl := UI.label(btn, tr("profile.age." + group + ".body"), Rect2(20, 62, 296, 74), 17, UI.WHITE)
	var tag_lbl := UI.label(btn, tr("v2.choose"), Rect2(20, 140, 296, 26), 15, UI.CYAN, true)
	_card_labels[group] = [title_lbl, body_lbl, tag_lbl]


func _refresh_selection() -> void:
	for group in age_buttons:
		var selected: bool = _age_group == group
		var btn: Button = age_buttons[group]
		btn.set_pressed_no_signal(selected)
		UI.paint(btn, selected)
		var color := UI.INK if selected else UI.WHITE
		var labels: Array = _card_labels[group]
		labels[0].set("theme_override_colors/font_color", color)
		labels[1].set("theme_override_colors/font_color", color)
		labels[2].set("theme_override_colors/font_color", UI.INK if selected else UI.CYAN)
		labels[2].text = tr("v2.selected" if selected else "v2.choose")
	var ready_ok := not _age_group.is_empty()
	start_button.disabled = not ready_ok
	_hint_label.visible = not ready_ok


func _submit() -> void:
	if _age_group.is_empty():
		return
	var prof := Profile.new()
	prof.choose_age(_age_group)
	prof.nickname = name_field.text.strip_edges()
	var exported: Dictionary = prof.export_profile(language, true, false)
	confirmed.emit(exported)

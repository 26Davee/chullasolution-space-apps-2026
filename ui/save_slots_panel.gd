extends Control
## Unified main screen with 3 large expedition slots, Tutorial, Options, and language switcher.
signal slot_selected(slot_id: int, is_new_game: bool)
signal slot_deleted(slot_id: int)
signal tutorial_requested()
signal options_requested()
signal language_changed(locale: String)
signal closed()

const UI = preload("res://ui/ui_kit.gd")
const Clock = preload("res://ui/mission_clock.gd")

var save_manager: Node
var is_home_screen: bool = true
var resume_available: bool = false
var play_button: Button
var tutorial_button: Button
var options_button: Button
var _cards_box: VBoxContainer
var _confirm_overlay: Control
var _pending_delete_slot: int = 0
var _title_label: Label
var _subtitle_label: Label
var _side_badge: Label
var _side_blurb: Label
var _lang_buttons: Dictionary = {}

func _ready() -> void:
	size = Vector2(1280, 720)
	if is_home_screen:
		var backdrop := preload("res://ui/world_backdrop.gd").new()
		add_child(backdrop)
		var shade := ColorRect.new()
		shade.size = Vector2(1280, 720)
		shade.color = Color(0.01, 0.04, 0.09, 0.42)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shade)
	else:
		var shade := ColorRect.new()
		shade.size = Vector2(1280, 720)
		shade.color = Color(0.01, 0.03, 0.07, 0.88)
		add_child(shade)

	UI.label(self, "KILLAWASI", Rect2(44, 24, 420, 60), 48, UI.WHITE, true)
	_subtitle_label = UI.label(self, "", Rect2(46, 82, 740, 32), 20, UI.CYAN, true)

	for i in range(2):
		var locale: String = ["en", "es"][i]
		var lbtn := UI.button(self, locale.to_upper(), Rect2(1078 + i * 74, 30, 64, 42), func():
			language_changed.emit(locale)
		)
		lbtn.toggle_mode = true
		lbtn.add_theme_font_size_override("font_size", 18)
		_lang_buttons[locale] = lbtn

	var slots_frame := UI.panel(self, Rect2(44, 126, 868, 558), Color(0.025, 0.07, 0.14, 0.96), 22)
	_title_label = UI.label(slots_frame, "", Rect2(28, 16, 680, 36), 26, UI.WHITE, true)
	if not is_home_screen:
		var close_btn := UI.button(slots_frame, tr("live.close"), Rect2(704, 14, 136, 40), func():
			closed.emit()
			queue_free()
		)
		close_btn.add_theme_font_size_override("font_size", 17)

	_cards_box = VBoxContainer.new()
	_cards_box.position = Vector2(28, 62)
	_cards_box.size = Vector2(812, 480)
	_cards_box.add_theme_constant_override("separation", 14)
	slots_frame.add_child(_cards_box)

	var side_panel := UI.panel(self, Rect2(934, 126, 302, 558), Color(0.025, 0.075, 0.145, 0.97), 22)
	var timmy := TextureRect.new()
	timmy.texture = load("res://assets/ui/timmy.png")
	timmy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	timmy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	timmy.position = Vector2(56, 22)
	timmy.size = Vector2(190, 228)
	timmy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side_panel.add_child(timmy)

	_side_badge = UI.label(side_panel, "", Rect2(22, 258, 258, 28), 16, UI.CYAN, true)
	_side_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_side_blurb = UI.label(side_panel, "", Rect2(22, 290, 258, 72), 18, Color("#d7e6f3"))
	_side_blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	tutorial_button = UI.button(side_panel, "", Rect2(24, 386, 254, 66), func(): tutorial_requested.emit(), true)
	tutorial_button.name = "TutorialButton"
	options_button = UI.button(side_panel, "", Rect2(24, 468, 254, 62), func(): options_requested.emit())
	options_button.name = "OptionsButton"

	refresh()


func refresh() -> void:
	if not is_instance_valid(_cards_box):
		return
	var cur_loc := "es" if TranslationServer.get_locale().to_lower().begins_with("es") else "en"
	for loc in _lang_buttons:
		var lbtn: Button = _lang_buttons[loc]
		lbtn.set_pressed_no_signal(loc == cur_loc)
		UI.paint(lbtn, loc == cur_loc)

	_subtitle_label.text = tr("guide.menu_blurb")
	_title_label.text = tr("live.slots_title")
	_side_badge.text = tr("guide.menu_tag")
	_side_blurb.text = tr("home.badge")
	tutorial_button.text = tr("live.main_tutorial")
	options_button.text = tr("live.main_options")

	for child in _cards_box.get_children():
		child.queue_free()
	play_button = null
	var any_occupied := false
	var first_action_btn: Button = null
	var slots: Array = save_manager.listar_slots() if save_manager != null else []
	for info in slots:
		var card := _build_card(info)
		_cards_box.add_child(card)
		var btn: Button = card.get_meta("primary_btn", null)
		if bool(info.get("occupied", false)):
			any_occupied = true
		if first_action_btn == null:
			first_action_btn = btn
		if bool(info.get("active", false)) and btn != null:
			play_button = btn
	if play_button == null:
		play_button = first_action_btn
	var cur_exp = save_manager.obtener_datos_completos().get("expedicion", {}) if save_manager != null else {}
	var has_active_exp := cur_exp is Dictionary and not (cur_exp as Dictionary).is_empty()
	resume_available = has_active_exp or (any_occupied and save_manager != null and bool(save_manager.leer_slot_resumen(save_manager.active_slot).get("occupied", false)))


func _build_card(info: Dictionary) -> Control:
	var slot_id := int(info.get("slot", 1))
	var occupied := bool(info.get("occupied", false))
	var is_active := bool(info.get("active", false))

	var card := Panel.new()
	card.custom_minimum_size = Vector2(812, 150)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.055, 0.115, 0.21, 0.96) if is_active else Color(0.035, 0.08, 0.155, 0.92)
	sb.border_color = UI.GOLD if is_active else (UI.CYAN if occupied else Color(0.24, 0.34, 0.48, 0.65))
	sb.set_border_width_all(2 if is_active else 1)
	sb.set_corner_radius_all(18)
	card.add_theme_stylebox_override("panel", sb)

	var slot_tag := UI.label(card, tr("live.slot_label").format({"slot": slot_id}), Rect2(24, 16, 160, 28), 16, UI.CYAN if occupied else Color("#9bb6cc"), true)
	slot_tag.name = "SlotTag"
	if is_active:
		var badge := UI.label(card, tr("live.slot_active"), Rect2(148, 16, 120, 28), 15, UI.GOLD, true)
		badge.name = "ActiveTag"

	if occupied:
		var nick := str(info.get("nickname", "")).strip_edges()
		if nick.is_empty():
			nick = tr("v2.default_name")
		var mode_key := "live.mode_engineer" if str(info.get("mode", "cadete")) == "ingeniero" else "live.mode_cadet"
		var mode_text := tr(mode_key)
		UI.label(card, "%s  ·  %s" % [nick, mode_text], Rect2(24, 48, 490, 38), 26, UI.WHITE, true)

		var t := float(info.get("tiempo_juego", 0.0))
		var clock_str := Clock.format_calendar(Clock.snapshot({"tiempo_juego": t}))
		var done := int(info.get("missions_done", 0))
		var stars := int(info.get("stars_total", 0))
		var meta_parts := [
			clock_str,
			tr("live.slot_missions").format({"done": done}),
			"%d ★" % stars,
		]
		var saved_iso := str(info.get("saved_iso", "")).strip_edges()
		if not saved_iso.is_empty():
			meta_parts.append(tr("live.slot_saved").format({"date": saved_iso.substr(0, 16)}))
		UI.label(card, "   •   ".join(meta_parts), Rect2(24, 96, 496, 36), 16, Color("#b8cfe2"))

		var cont_btn := UI.button(card, tr("live.slot_continue"), Rect2(526, 42, 152, 66), func():
			slot_selected.emit(slot_id, false)
		, true)
		cont_btn.name = "ContinueSlot%d" % slot_id
		var del_btn := UI.button(card, tr("live.slot_delete"), Rect2(688, 42, 102, 66), func():
			_open_delete_confirm(slot_id, nick)
		)
		del_btn.name = "DeleteSlot%d" % slot_id
		card.set_meta("primary_btn", cont_btn)
	else:
		UI.label(card, tr("live.slot_empty"), Rect2(24, 58, 470, 44), 22, Color("#9bb6cc"))
		var new_btn := UI.button(card, tr("live.slot_new"), Rect2(526, 42, 264, 66), func():
			slot_selected.emit(slot_id, true)
		, true)
		new_btn.name = "NewSlot%d" % slot_id
		card.set_meta("primary_btn", new_btn)

	return card


func _open_delete_confirm(slot_id: int, nick: String) -> void:
	if is_instance_valid(_confirm_overlay):
		_confirm_overlay.queue_free()
	_pending_delete_slot = slot_id
	_confirm_overlay = ColorRect.new()
	_confirm_overlay.size = Vector2(1280, 720)
	_confirm_overlay.color = Color(0.0, 0.01, 0.04, 0.82)
	add_child(_confirm_overlay)

	var box := UI.panel(_confirm_overlay, Rect2(330, 230, 620, 250), Color(0.03, 0.075, 0.15, 0.99), 20)
	var msg := tr("live.slot_delete_confirm").format({"slot": slot_id, "name": nick})
	UI.label(box, msg, Rect2(28, 34, 564, 110), 20, UI.WHITE, true)
	UI.button(box, tr("live.slot_delete_ok"), Rect2(28, 166, 270, 52), func():
		var target := _pending_delete_slot
		if is_instance_valid(_confirm_overlay):
			_confirm_overlay.queue_free()
		slot_deleted.emit(target)
	, true)
	UI.button(box, tr("live.cancel"), Rect2(322, 166, 270, 52), func():
		if is_instance_valid(_confirm_overlay):
			_confirm_overlay.queue_free()
	)

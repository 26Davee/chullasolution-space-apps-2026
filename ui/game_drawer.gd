extends Panel
## Cajón lateral derecho unificado para acciones y consultas sin tapar la base 3D.
signal close_requested()
signal navigate_requested(target: String, payload: Dictionary)

const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")
const Catalog = preload("res://ui/progression_catalog.gd")

const PAUSING_KINDS := [
	"missions", "upgrades", "science", "messages", "timmy", "coach",
	"resource", "settings", "settings:language", "settings:audio",
	"settings:controls", "settings:exit",
]

var kind := ""
var _header_icon: Icon
var _title_label: Label
var _scroll: ScrollContainer
var _content: VBoxContainer
var _footer: HBoxContainer
var _selected_branch := ""
var _selected_upgrade := ""
var _selected_science := 0
var _voice_choice: OptionButton
var _audio_status: Label
var _process_bar: ProgressBar


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	add_theme_stylebox_override("panel", UI.style(Color("#0c1c31f5"), Color(0.48, 0.77, 0.84, 0.42), 1, 18))
	_build_frame()


func _build_frame() -> void:
	var header := HBoxContainer.new()
	header.position = Vector2(18, 16)
	header.size = Vector2(312, 34)
	header.add_theme_constant_override("separation", 10)
	header.name = "Header"
	add_child(header)

	_header_icon = Icon.new()
	_header_icon.disc = false
	_header_icon.tint = UI.CYAN
	_header_icon.custom_minimum_size = Vector2(22, 22)
	_header_icon.size = Vector2(22, 22)
	header.add_child(_header_icon)

	_title_label = Label.new()
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title_label.clip_text = true
	_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", UI.WHITE)
	header.add_child(_title_label)

	var close_btn := Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(32, 32)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.add_theme_font_size_override("font_size", 18)
	UI.paint(close_btn, false)
	close_btn.add_theme_stylebox_override("normal", UI.style(Color("#152a42"), Color("#536e87"), 1, 10))
	close_btn.pressed.connect(close_requested.emit)
	header.add_child(close_btn)

	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(18, 58)
	_scroll.size = Vector2(312, 400)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	add_child(_scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	_scroll.add_child(_content)

	_footer = HBoxContainer.new()
	_footer.position = Vector2(18, 470)
	_footer.size = Vector2(312, 42)
	_footer.add_theme_constant_override("separation", 10)
	add_child(_footer)


func blocks_world() -> bool:
	return visible and (kind in PAUSING_KINDS)


func close_drawer() -> void:
	visible = false
	kind = ""
	_voice_choice = null
	_audio_status = null
	_process_bar = null


func open_section(section_kind: String, data: Dictionary) -> void:
	kind = section_kind
	_voice_choice = null
	_audio_status = null
	_process_bar = null
	for child in _content.get_children():
		child.queue_free()
	for child in _footer.get_children():
		child.queue_free()

	var width := 376.0 if section_kind in ["missions", "upgrades", "science", "construction"] else 336.0
	var inner_w := width - 36.0
	get_node("Header").size.x = inner_w
	_content.custom_minimum_size.x = inner_w - 10.0

	_header_icon.kind = str(data.get("icon", _default_icon_for(section_kind)))
	_header_icon.tint = data.get("tint", UI.CYAN)
	_header_icon.queue_redraw()
	_title_label.text = str(data.get("title", ""))

	match section_kind:
		"more":
			_populate_more(data, inner_w)
		"construction":
			_populate_construction(data, inner_w)
		"expedition":
			_populate_expedition(data, inner_w)
		"processing":
			_populate_processing(data, inner_w)
		"missions":
			_populate_missions(data, inner_w)
		"upgrades":
			_populate_upgrades(data, inner_w)
		"science":
			_populate_science(data, inner_w)
		"messages":
			_populate_messages(data, inner_w)
		"timmy", "coach":
			_populate_timmy(data, inner_w)
		"resource":
			_populate_resource(data, inner_w)
		"settings":
			_populate_settings(data, inner_w)
		"settings:language":
			_populate_language(data, inner_w)
		"settings:audio":
			_populate_audio(data, inner_w)
		"settings:controls":
			_populate_controls(data, inner_w)
		"settings:exit":
			_populate_exit(data, inner_w)

	_layout_panel(width, section_kind)
	visible = true


func update_processing_progress(pct: float) -> void:
	if kind == "processing" and is_instance_valid(_process_bar):
		_process_bar.value = clampf(pct, 0.0, 100.0)


func _layout_panel(width: float, section_kind: String) -> void:
	var has_footer := _footer.get_child_count() > 0
	var footer_h := 56.0 if has_footer else 16.0
	var max_h := 550.0
	var content_h := _content.get_combined_minimum_size().y + 8.0
	if section_kind in ["missions", "upgrades", "science", "construction", "messages"]:
		content_h = maxf(content_h, 390.0)
	var total_h := clampf(60.0 + content_h + footer_h, 190.0, max_h)
	var scroll_h := total_h - 60.0 - footer_h
	_scroll.size = Vector2(width - 36.0, scroll_h)
	_footer.visible = has_footer
	_footer.position = Vector2(18, total_h - 54.0)
	_footer.size = Vector2(width - 36.0, 40)
	position = Vector2(1280.0 - width - 16.0, 70.0)
	size = Vector2(width, total_h)


func _populate_more(data: Dictionary, _w: float) -> void:
	_add_section_heading(tr("live.more_actions"))
	var actions_row := HBoxContainer.new()
	actions_row.add_theme_constant_override("separation", 8)
	_content.add_child(actions_row)
	actions_row.add_child(_pill_button(tr("live.processing"), "agua", Color("#68b9ff"), func(): navigate_requested.emit("open_section", {"id": "processing"})))
	actions_row.add_child(_pill_button(tr("live.rest"), "robot_battery", Color("#b4a4ff"), func(): navigate_requested.emit("open_action", {"id": "rest"})))

	_add_section_heading(tr("live.more_consult"))
	var unread := int(data.get("unread", 0))
	var notices_sub := tr("live.more_notices_new").format({"n": unread}) if unread > 0 else tr("live.more_notices_none")
	for row in [
		["upgrades", "upgrades", Color("#b4a4ff"), tr("live.upgrades"), tr("live.more_upgrades_sub")],
		["science", "science", Color("#7fe7bf"), tr("live.science"), tr("live.more_science_sub")],
		["messages", "messages", Color("#59e0dc"), tr("live.messages"), notices_sub],
		["timmy", "target", Color("#ffc64f"), tr("live.timmy"), tr("live.more_timmy_sub")],
	]:
		var target_id: String = row[0]
		_add_row_card(row[1], row[2], row[3], row[4], func(): navigate_requested.emit("open_section", {"id": target_id}))


func _populate_construction(data: Dictionary, w: float) -> void:
	_add_note(tr("live.build_pick"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_content.add_child(grid)
	var card_w := floorf((w - 20.0) * 0.5)
	var modules: Array = data.get("modules", [])
	for mod in modules:
		var id := str(mod.id)
		var stock := int(mod.stock)
		var installed := int(mod.get("installed", 0))
		var limit := int(mod.get("limit", 1))
		var locked := bool(mod.locked)
		var need_upgrade := bool(mod.get("need_upgrade", false))
		var cost := int(mod.cost)
		var btn := Button.new()
		btn.name = "Module_" + id
		btn.custom_minimum_size = Vector2(card_w, 138)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		UI.paint(btn, false)
		btn.add_theme_stylebox_override("normal", UI.style(Color("#132740"), Color("#536e87") if not locked and stock > 0 else Color("#334861"), 1, 12))
		btn.pressed.connect(func(): navigate_requested.emit("build_module", {"id": id}))
		if stock == 0 or locked:
			btn.modulate = Color(0.76, 0.82, 0.88)
		grid.add_child(btn)

		if bool(mod.get("has_picture", true)):
			var pic := TextureRect.new()
			pic.texture = mod.get("texture")
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if id == "tanque_agua" else TextureRect.STRETCH_KEEP_ASPECT_COVERED
			pic.position = Vector2(8, 8)
			pic.size = Vector2(card_w - 16, 56)
			pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(pic)

		var title := UI.label(btn, str(mod.name), Rect2(10, 68, card_w - 20, 22), 14, UI.WHITE, true)
		title.autowrap_mode = TextServer.AUTOWRAP_OFF
		title.clip_text = true
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

		var avail_txt := tr("live.build_one_avail" if stock == 1 else "live.build_many_avail").format({"n": stock})
		var line2 := tr("live.build_limit_reached").format({"placed": installed, "limit": limit}) if locked else ("%s · %d/%d" % [avail_txt, installed, limit])
		var l2 := UI.label(btn, line2, Rect2(10, 90, card_w - 20, 18), 12, Color("#d3e1ee"))
		l2.autowrap_mode = TextServer.AUTOWRAP_OFF
		l2.clip_text = true
		l2.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

		var line3 := tr("live.build_need_upgrade") if need_upgrade else (tr("live.build_from_missions") if (stock == 0 and not locked and id in ["tanque_agua", "jardin"]) else tr("live.build_energy_cost").format({"n": cost}))
		var l3 := UI.label(btn, line3, Rect2(10, 110, card_w - 20, 18), 12, UI.CYAN if not locked else Color("#a4b7c9"))
		l3.autowrap_mode = TextServer.AUTOWRAP_OFF
		l3.clip_text = true
		l3.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func _populate_expedition(data: Dictionary, _w: float) -> void:
	_add_preview("res://assets/ui/activities/ice_map-v1.png", 112)
	var zones: Array = data.get("zones", [])
	var selected := str(data.get("selected", "crater"))
	var phase := str(data.get("phase", "idle"))
	for z in zones:
		var zid := str(z.id)
		var sub := "%s · %s" % [tr("live.ice_selected_sub"), tr("guide.zone_stock").format({"n": int(z.stock)})]
		_add_row_card("target", UI.CYAN if zid == selected else Color("#8ba4be"), str(z.name), sub, func():
			navigate_requested.emit("select_ice_zone", {"id": zid})
		, zid == selected)

	var mid_row := HBoxContainer.new()
	mid_row.add_theme_constant_override("separation", 8)
	_content.add_child(mid_row)
	var scan_btn := _pill_button(tr("live.ice_scan_btn"), "target", UI.CYAN, func(): navigate_requested.emit("scan_ice", {}))
	scan_btn.disabled = not bool(data.get("can_scan", false))
	mid_row.add_child(scan_btn)
	mid_row.add_child(_pill_button(tr("live.return_dome"), "escudo", UI.CYAN, func(): navigate_requested.emit("return_dome", {})))

	if phase in ["idle", "blocked"]:
		var label := tr("guide.retry") if phase == "blocked" else tr("live.ice_start_btn")
		_footer.add_child(_cta_button(label, true, func(): navigate_requested.emit("start_ice", {})))
	else:
		_footer.add_child(_cta_button(tr("guide.stop_trip"), false, func(): navigate_requested.emit("cancel_ice", {})))


func _populate_processing(data: Dictionary, _w: float) -> void:
	_add_preview("res://assets/ui/activities/processor-v1.png", 118)
	if bool(data.get("running", false)):
		_add_stat_row("agua", Color("#68b9ff"), tr("live.process_conversion"), tr("live.process_formula"))
		_process_bar = ProgressBar.new()
		_process_bar.show_percentage = false
		_process_bar.custom_minimum_size = Vector2(0, 8)
		_process_bar.value = float(data.get("progress", 0.0))
		_process_bar.add_theme_font_size_override("font_size", 1)
		_process_bar.add_theme_stylebox_override("background", UI.style(Color("#25374e"), Color.TRANSPARENT, 0, 4))
		_process_bar.add_theme_stylebox_override("fill", UI.style(UI.CYAN, Color.TRANSPARENT, 0, 4))
		_content.add_child(_process_bar)
		_add_note(tr("live.process_running_desc"))
	else:
		_add_stat_row("ice", Color("#68b9ff"), tr("live.ice"), tr("live.process_avail_blocks").format({"n": int(data.get("ice", 0))}))
		_add_stat_row("agua", Color("#68b9ff"), tr("live.process_capacity_label"), tr("live.process_capacity_val").format({"n": int(data.get("capacity", 3))}))
		_add_note(tr("live.process_near_hint"))
		_footer.add_child(_cta_button(tr("live.process_start_btn"), true, func(): navigate_requested.emit("run_processing", {})))


func _populate_missions(data: Dictionary, _w: float) -> void:
	var items: Array = data.get("items", [])
	var current_id := str(data.get("current_id", ""))
	var completed: Array = data.get("completed", [])
	var mode := str(data.get("mode", "cadete"))
	var found_next := false
	for item in items:
		var id := str(item.id)
		var title := Catalog.text("misiones." + id + ".titulo", str(item.get("mision", id)))
		var is_current := (id == current_id)
		var is_done := completed.has(id)
		var tag := tr("live.missions_done") if is_done else (tr("live.missions_active") if is_current else (tr("live.missions_next") if not found_next else tr("live.missions_pending")))
		if not is_done and not is_current and not found_next:
			found_next = true
		var box := PanelContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_stylebox_override("panel", UI.style(Color("#17324b") if is_current else Color("#132740"), UI.GOLD if is_current else Color("#3c5670"), 2 if is_current else 1, 12))
		_content.add_child(box)
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 5)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		margin.add_child(inner)
		box.add_child(margin)

		var top_row := HBoxContainer.new()
		top_row.add_theme_constant_override("separation", 8)
		inner.add_child(top_row)
		var lbl := Label.new()
		lbl.text = title
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 15 if is_current else 14)
		lbl.add_theme_color_override("font_color", UI.WHITE)
		top_row.add_child(lbl)

		var badge := Label.new()
		badge.text = tag
		badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		badge.add_theme_font_size_override("font_size", 12)
		badge.add_theme_color_override("font_color", UI.GOLD if is_current else (Color("#7fe7bf") if is_done else Color("#9db4ca")))
		top_row.add_child(badge)

		var desc := Label.new()
		var obj := Catalog.text("misiones." + id + ".objetivo", "\n".join(item.get("objetivo", [])))
		desc.text = obj
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 12)
		desc.add_theme_color_override("font_color", Color("#c7d6e6"))
		if not is_current:
			desc.max_lines_visible = 2
			desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		inner.add_child(desc)

		if is_current:
			var done := int(data.get("objective_done", 0))
			var total := maxi(1, int(data.get("objective_total", 1)))
			var bar := ProgressBar.new()
			bar.show_percentage = false
			bar.custom_minimum_size = Vector2(0, 6)
			bar.max_value = total
			bar.value = done
			bar.add_theme_font_size_override("font_size", 1)
			bar.add_theme_stylebox_override("background", UI.style(Color("#25374e"), Color.TRANSPARENT, 0, 3))
			bar.add_theme_stylebox_override("fill", UI.style(UI.CYAN, Color.TRANSPARENT, 0, 3))
			inner.add_child(bar)
			var stars := int(item.get("puntos", {}).get(mode, 1))
			var foot := Label.new()
			foot.text = "%d/%d · +%d ★" % [done, total, stars]
			foot.add_theme_font_size_override("font_size", 12)
			foot.add_theme_color_override("font_color", UI.CYAN)
			inner.add_child(foot)

	_footer.add_child(_cta_button(tr("live.back_to_map"), false, close_requested.emit))


func _populate_upgrades(data: Dictionary, _w: float) -> void:
	var items: Array = data.get("items", [])
	var unlocked: Array = data.get("unlocked", [])
	var stars := int(data.get("stars", 0))
	var branches: Array[String] = []
	for item in items:
		var b := str(item.get("branch", ""))
		if not b in branches:
			branches.append(b)
	if _selected_branch.is_empty() or not (_selected_branch in branches):
		_selected_branch = branches[0] if not branches.is_empty() else ""

	var tabs := GridContainer.new()
	tabs.columns = 2
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_theme_constant_override("h_separation", 6)
	tabs.add_theme_constant_override("v_separation", 6)
	_content.add_child(tabs)
	for b in branches:
		var branch_id := b
		var btn := _pill_button(Catalog.text("branches." + b, b), "", UI.GOLD if b == _selected_branch else UI.WHITE, func():
			_selected_branch = branch_id
			_selected_upgrade = ""
			navigate_requested.emit("refresh_upgrades", {})
		, b == _selected_branch)
		btn.add_theme_font_size_override("font_size", 12)
		tabs.add_child(btn)

	_add_stat_row("star", UI.GOLD, tr("live.upgrades_stars"), "%d ★" % stars)

	var branch_items: Array = []
	for item in items:
		if str(item.get("branch", "")) == _selected_branch:
			branch_items.append(item)

	if _selected_upgrade.is_empty() and not branch_items.is_empty():
		_selected_upgrade = str(branch_items[0].id)
		for item in branch_items:
			if not unlocked.has(str(item.id)):
				_selected_upgrade = str(item.id)
				break

	var selected_item: Dictionary = {}
	for item in branch_items:
		var id := str(item.id)
		var is_owned := unlocked.has(id)
		var req = item.get("requisito")
		var req_ok := (req == null or unlocked.has(str(req)))
		var cost := int(item.get("costo", item.get("costo_estrellas", 0)))
		var state_txt := tr("live.upgrades_installed") if is_owned else ("%d ★" % cost if req_ok else tr("live.build_locked"))
		var name_txt := Catalog.text("upgrades." + id + ".nombre", str(item.get("nombre", id)))
		var effect_txt := Catalog.text("upgrades." + id + ".efecto", "")
		if id == _selected_upgrade:
			selected_item = item
		_add_row_card("check" if is_owned else ("upgrades" if req_ok else "lock"), Color("#7fe7bf") if is_owned else (UI.GOLD if req_ok else Color("#8ba4be")), "%s · %s" % [name_txt, state_txt], effect_txt, func():
			_selected_upgrade = id
			navigate_requested.emit("refresh_upgrades", {})
		, id == _selected_upgrade)

	if not selected_item.is_empty():
		var sel_id := str(selected_item.id)
		var can_buy := not unlocked.has(sel_id) and (selected_item.get("requisito") == null or unlocked.has(str(selected_item.get("requisito")))) and stars >= int(selected_item.get("costo", selected_item.get("costo_estrellas", 0)))
		var buy_btn := _cta_button(tr("live.upgrades_unlock"), true, func(): navigate_requested.emit("buy_upgrade", {"id": sel_id}))
		buy_btn.disabled = not can_buy
		_footer.add_child(buy_btn)


func _populate_science(data: Dictionary, _w: float) -> void:
	var cards: Array = data.get("cards", [])
	if cards.is_empty():
		_add_note(tr("live.empty_science"))
		return
	_selected_science = clampi(_selected_science, 0, cards.size() - 1)
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation", 6)
	tabs.add_theme_constant_override("v_separation", 6)
	_content.add_child(tabs)
	for i in cards.size():
		var idx := i
		var btn := _pill_button(str(i + 1), "", UI.GOLD if i == _selected_science else UI.WHITE, func():
			_selected_science = idx
			navigate_requested.emit("refresh_science", {})
		, i == _selected_science)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		btn.custom_minimum_size = Vector2(36, 30)
		tabs.add_child(btn)

	var card: Dictionary = cards[_selected_science]
	var art_id := str(card.get("art", "solar"))
	_add_preview("res://assets/ui/activities/" + art_id + "-v1.png", 126)
	var heading := Label.new()
	heading.text = str(card.get("titulo", ""))
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", UI.GOLD)
	_content.add_child(heading)

	_add_note(str(card.get("dato", "")))
	var src := Label.new()
	src.text = tr("live.source").format({"source": str(card.get("fuente", ""))})
	src.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	src.add_theme_font_size_override("font_size", 12)
	src.add_theme_color_override("font_color", UI.CYAN)
	_content.add_child(src)

	_footer.add_child(_cta_button(tr("live.science_listen"), true, func(): navigate_requested.emit("speak", {"text": str(card.get("titulo", "")) + ". " + str(card.get("dato", ""))})))


func _populate_messages(data: Dictionary, _w: float) -> void:
	var items: Array = data.get("items", [])
	if items.is_empty():
		_add_note(tr("live.no_messages"))
		return
	for item in items:
		var id := str(item.id)
		var text := str(item.text)
		var unread := bool(item.unread)
		_add_row_card("warning" if item.get("kind", "") == "storm" else "messages", Color("#ff927a") if item.get("kind", "") == "storm" else UI.CYAN, text, "", func():
			navigate_requested.emit("read_message", {"id": id, "text": text})
		, unread)
	for item in items:
		if item.get("kind","") == "resource":
			_footer.add_child(_cta_button(tr("lesson.solve"),true,func(): navigate_requested.emit("guide_alert",{"id":str(item.id),"resource":str(item.get("resource","agua"))})))
			break
	_footer.add_child(_cta_button(tr("live.repeat"), false, func():
		if not items.is_empty():
			navigate_requested.emit("read_message", {"id": str(items[0].id), "text": str(items[0].text)})
	))


func _populate_timmy(data: Dictionary, _w: float) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_content.add_child(row)

	var portrait := TextureRect.new()
	portrait.texture = load("res://assets/ui/timmy.png")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(76, 108)
	row.add_child(portrait)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 6)
	row.add_child(text_col)

	var q := Label.new()
	q.text = str(data.get("subtitle", tr("live.next")))
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q.add_theme_font_size_override("font_size", 15)
	q.add_theme_color_override("font_color", UI.GOLD)
	text_col.add_child(q)

	var body := Label.new()
	body.text = str(data.get("body", ""))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 13)
	body.add_theme_color_override("font_color", UI.WHITE)
	text_col.add_child(body)

	_add_row_card("target", UI.CYAN, tr("live.help"), tr("live.settings_controls_sub"), func(): navigate_requested.emit("open_section", {"id": "settings:controls"}))

	var speak_text := str(data.get("body", ""))
	_footer.add_child(_cta_button(tr("live.timmy_sub"), false, func(): navigate_requested.emit("speak", {"text": speak_text})))
	var confirm_label := str(data.get("confirm_label", tr("live.understood")))
	_footer.add_child(_cta_button(confirm_label, true, func(): navigate_requested.emit("confirm_timmy", data)))


func _populate_resource(data: Dictionary, _w: float) -> void:
	var tex_path := str(data.get("texture_path", "res://assets/ui/activities/solar-v1.png"))
	_add_preview(tex_path, 118)
	var pct := int(data.get("percent", 0))
	var color: Color = data.get("color", UI.GOLD)
	_add_stat_row(str(data.get("icon", "energia")), color, tr("live.res_current"), "%d%%" % pct)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 7)
	bar.value = pct
	bar.add_theme_font_size_override("font_size", 1)
	bar.add_theme_stylebox_override("background", UI.style(Color("#25374e"), Color.TRANSPARENT, 0, 4))
	bar.add_theme_stylebox_override("fill", UI.style(color, Color.TRANSPARENT, 0, 4))
	_content.add_child(bar)
	_add_note(str(data.get("help", "")))
	var cta_text := str(data.get("cta_label", tr("live.res_view_upgrades")))
	var cta_target := str(data.get("cta_target", "upgrades"))
	_footer.add_child(_cta_button(cta_text, false, func(): navigate_requested.emit("open_section", {"id": cta_target})))


func _populate_settings(_data: Dictionary, _w: float) -> void:
	var lang_name := "Español" if TranslationServer.get_locale().begins_with("es") else "English"
	for row in [
		["settings:language", "menu", UI.CYAN, tr("live.settings_lang"), lang_name],
		["settings:audio", "audio", UI.CYAN, tr("live.settings_audio"), tr("live.settings_audio_sub")],
		["settings:controls", "target", UI.CYAN, tr("live.help"), tr("live.settings_controls_sub")],
		["settings:exit", "warning", Color("#ff927a"), tr("live.settings_exit"), tr("live.settings_exit_sub")],
	]:
		var target_id: String = row[0]
		_add_row_card(row[1], row[2], row[3], row[4], func(): navigate_requested.emit("open_section", {"id": target_id}))


func _populate_language(_data: Dictionary, _w: float) -> void:
	_add_note(tr("live.lang_pick_hint"))
	var is_es := TranslationServer.get_locale().begins_with("es")
	_add_row_card("check" if is_es else "menu", UI.CYAN, tr("v2.language_es"), tr("live.lang_current") if is_es else tr("live.lang_switch_es"), func(): navigate_requested.emit("set_language", {"lang": "es"}), is_es)
	_add_row_card("check" if not is_es else "menu", UI.CYAN, tr("v2.language_en"), tr("live.lang_current") if not is_es else tr("live.lang_switch_en"), func(): navigate_requested.emit("set_language", {"lang": "en"}), not is_es)
	_footer.add_child(_cta_button(tr("live.back_settings"), false, func(): navigate_requested.emit("open_section", {"id": "settings"})))


func _populate_audio(data: Dictionary, _w: float) -> void:
	var muted := bool(data.get("muted", false))
	var lang := str(data.get("lang", "es"))
	var voices: Array = data.get("voices", [])
	var selected_voice := str(data.get("selected_voice", ""))

	_add_row_card("audio", UI.CYAN, tr("live.audio_narration"), tr("live.audio_off" if muted else "live.audio_on"), func():
		navigate_requested.emit("toggle_mute", {})
	, not muted)

	_add_section_heading(tr("live.voice"))
	_voice_choice = OptionButton.new()
	_voice_choice.custom_minimum_size = Vector2(0, 36)
	_voice_choice.fit_to_longest_item = false
	_voice_choice.clip_text = true
	_voice_choice.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_voice_choice.add_theme_font_size_override("font_size", 14)
	UI.paint(_voice_choice)
	_voice_choice.add_item("Sabina" if lang == "es" else "Zira")
	_voice_choice.set_item_metadata(0, "")
	for v in voices:
		_voice_choice.add_item(str(v.name))
		_voice_choice.set_item_metadata(_voice_choice.item_count - 1, str(v.id))
		if selected_voice == str(v.id):
			_voice_choice.select(_voice_choice.item_count - 1)
	_voice_choice.item_selected.connect(func(index: int):
		navigate_requested.emit("select_voice", {"id": str(_voice_choice.get_item_metadata(index))})
	)
	_content.add_child(_voice_choice)

	_audio_status = Label.new()
	_audio_status.text = tr("v2.audio_muted") if muted else (tr("live.voice_missing") if voices.is_empty() else tr("v2.audio_ready"))
	_audio_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_audio_status.add_theme_font_size_override("font_size", 12)
	_audio_status.add_theme_color_override("font_color", Color("#c7d6e6"))
	_content.add_child(_audio_status)

	_add_slider_row(tr("live.volume"), "%d%%" % int(data.get("volume", 85)), 0.0, 100.0, 5.0, float(data.get("volume", 85)), func(val: float):
		navigate_requested.emit("set_volume", {"value": int(val)})
	)
	_add_slider_row(tr("live.speed"), "%.2fx" % float(data.get("rate", 0.95)), 0.7, 1.3, 0.05, float(data.get("rate", 0.95)), func(val: float):
		navigate_requested.emit("set_rate", {"value": val})
	)

	_footer.add_child(_cta_button(tr("live.audio_test_btn"), false, func(): navigate_requested.emit("test_voice", {})))
	_footer.add_child(_cta_button(tr("live.audio_back"), false, func(): navigate_requested.emit("open_section", {"id": "settings"})))


func _populate_controls(_data: Dictionary, w: float) -> void:
	var controls = preload("res://ui/controls_view.gd").new()
	controls.custom_minimum_size = Vector2(w-10,430)
	controls.size = controls.custom_minimum_size
	_content.add_child(controls)
	_footer.add_child(_cta_button(tr("live.understood"),true,close_requested.emit))


func _populate_exit(_data: Dictionary, _w: float) -> void:
	_add_note(tr("live.settings_exit_desc"))
	_footer.add_child(_cta_button(tr("live.cancel"), false, close_requested.emit))
	var exit_btn := _cta_button(tr("live.save_and_exit"), false, func(): navigate_requested.emit("return_home", {}))
	exit_btn.add_theme_stylebox_override("normal", UI.style(Color("#f4a68b"), Color.TRANSPARENT, 0, 10))
	exit_btn.add_theme_stylebox_override("hover", UI.style(Color("#ffbba3"), UI.WHITE, 1, 10))
	for s in ["font_color", "font_hover_color", "font_pressed_color"]:
		exit_btn.add_theme_color_override(s, UI.INK)
	_footer.add_child(exit_btn)


func _add_section_heading(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color("#9eb5cc"))
	_content.add_child(lbl)


func _add_note(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color("#d3e1ee"))
	_content.add_child(lbl)


func _add_preview(path: String, height: float) -> void:
	var pic := TextureRect.new()
	pic.texture = load(path)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.custom_minimum_size = Vector2(0, height)
	_content.add_child(pic)


func _add_stat_row(icon_kind: String, tint: Color, left_txt: String, right_txt: String) -> void:
	var box := UI.panel(_content, Rect2(0, 0, 0, 38), Color("#132740"), 10)
	box.custom_minimum_size = Vector2(0, 38)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_child(row)
	box.add_child(m)

	var icon := Icon.new()
	icon.kind = icon_kind
	icon.disc = false
	icon.tint = tint
	icon.custom_minimum_size = Vector2(16, 16)
	row.add_child(icon)

	var l := Label.new()
	l.text = left_txt
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color("#d3e1ee"))
	row.add_child(l)

	var r := Label.new()
	r.text = right_txt
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_theme_font_size_override("font_size", 13)
	r.add_theme_color_override("font_color", UI.CYAN)
	row.add_child(r)


func _add_slider_row(title: String, value_text: String, min_v: float, max_v: float, step_v: float, current: float, on_change: Callable) -> void:
	var box := UI.panel(_content, Rect2(0, 0, 0, 56), Color("#132740"), 10)
	box.custom_minimum_size = Vector2(0, 56)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 10)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 6)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_child(col)
	box.add_child(m)

	var top := HBoxContainer.new()
	col.add_child(top)
	var l := Label.new()
	l.text = title
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", UI.WHITE)
	top.add_child(l)
	var val_lbl := Label.new()
	val_lbl.text = value_text
	val_lbl.add_theme_font_size_override("font_size", 13)
	val_lbl.add_theme_color_override("font_color", UI.CYAN)
	top.add_child(val_lbl)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v
	slider.value = current
	slider.value_changed.connect(func(v: float):
		val_lbl.text = ("%d%%" % int(v)) if max_v >= 10 else ("%.2fx" % v)
		on_change.call(v)
	)
	col.add_child(slider)


func _add_row_card(icon_kind: String, tint: Color, title: String, subtitle: String, cb: Callable, highlight := false) -> void:
	var holder := MarginContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.custom_minimum_size = Vector2(0, 56 if not subtitle.is_empty() else 44)
	_content.add_child(holder)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UI.style(Color("#17324b") if highlight else Color("#132740"), UI.GOLD if highlight else Color("#405a74"), 2 if highlight else 1, 12))
	holder.add_child(panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)

	var icon := Icon.new()
	icon.kind = icon_kind
	icon.disc = false
	icon.tint = tint
	icon.custom_minimum_size = Vector2(18, 18)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 2)
	hbox.add_child(col)

	var t := Label.new()
	t.text = title
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_theme_font_size_override("font_size", 14)
	t.add_theme_color_override("font_color", UI.WHITE)
	col.add_child(t)

	if not subtitle.is_empty():
		var s := Label.new()
		s.text = subtitle
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s.add_theme_font_size_override("font_size", 12)
		s.add_theme_color_override("font_color", Color("#b6c9db"))
		col.add_child(s)

	if cb.is_valid():
		var chev := Label.new()
		chev.text = "›"
		chev.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chev.add_theme_font_size_override("font_size", 18)
		chev.add_theme_color_override("font_color", Color("#8ea9c4"))
		hbox.add_child(chev)

		var hit := Button.new()
		hit.tooltip_text = title
		hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		hit.add_theme_stylebox_override("normal", UI.style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 12))
		hit.add_theme_stylebox_override("hover", UI.style(Color(0.35, 0.88, 0.86, 0.08), UI.CYAN, 1, 12))
		hit.add_theme_stylebox_override("pressed", UI.style(Color(0.35, 0.88, 0.86, 0.16), UI.GOLD, 2, 12))
		hit.add_theme_stylebox_override("focus", UI.style(Color.TRANSPARENT, UI.CYAN, 2, 12))
		hit.pressed.connect(cb)
		holder.add_child(hit)


func _pill_button(text: String, icon_kind: String, tint: Color, cb: Callable, active := false) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 36)
	btn.clip_text = true
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UI.paint(btn, active)
	btn.add_theme_font_size_override("font_size", 13)
	var style := UI.style(Color("#1c3a56") if active else Color("#132740"), UI.GOLD if active else Color("#405a74"), 2 if active else 1, 10)
	if not icon_kind.is_empty():
		style.content_margin_left = 20.0
		style.content_margin_right = 10.0
		btn.tooltip_text = text
	btn.add_theme_stylebox_override("normal", style)
	btn.pressed.connect(cb)
	if not icon_kind.is_empty() and not active:
		btn.add_theme_color_override("font_color", UI.WHITE)
		var dot := ColorRect.new()
		dot.color = tint
		dot.position = Vector2(8, 15)
		dot.size = Vector2(6, 6)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(dot)
	return btn


func _cta_button(text: String, primary: bool, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 40)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UI.paint(btn, primary)
	btn.add_theme_font_size_override("font_size", 14)
	if primary:
		btn.add_theme_stylebox_override("normal", UI.style(UI.GOLD, Color.TRANSPARENT, 0, 10))
	else:
		btn.add_theme_stylebox_override("normal", UI.style(Color("#152a42"), Color("#536e87"), 1, 10))
	btn.pressed.connect(cb)
	return btn


func _default_icon_for(section_kind: String) -> String:
	match section_kind:
		"more": return "menu"
		"construction": return "construction"
		"expedition": return "ice"
		"processing": return "agua"
		"missions": return "missions"
		"upgrades": return "upgrades"
		"science": return "science"
		"messages": return "messages"
		"timmy", "coach": return "timmy"
		"settings": return "settings"
		"settings:language": return "menu"
		"settings:audio": return "audio"
		"settings:controls": return "target"
		"settings:exit": return "warning"
		_: return "base"

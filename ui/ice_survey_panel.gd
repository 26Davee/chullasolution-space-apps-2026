extends Control
signal scan_requested(id: String)
signal trip_requested(id: String)
signal return_requested()
signal cancel_requested()
signal retry_requested()
signal completed()
signal step_performed(action: String)
signal narration_requested(text: String)
const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")
const IDS := ["crater","ridge","basin"]
const NAMES := ["zone_crater","zone_ridge","zone_basin"]
var training := true
var selected := ""
var surveyed: Dictionary = {}
var stock: Dictionary = {"crater":18,"ridge":24,"basin":30}
var phase := "idle"
var _zone_buttons: Array[Button] = []
var _zone := -1
var _scanned: Dictionary = {}
var _scan_button: Button
var _collect_button: Button
var _heading: Label
var _feedback: Label
var _route: Line2D
var _radar: Control
var _zone_icons: Array[Control] = []
var _scanning := false
func _ready() -> void:
	var compact := size.y < 400
	var map_width := size.x*0.56
	var art = TextureRect.new()
	art.texture = load("res://assets/ui/activities/ice_map-v1.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.size = Vector2(map_width,size.y-40)
	art.position = Vector2(0,40)
	art.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(art)
	_route = Line2D.new()
	_route.width = 4
	_route.default_color = UI.GOLD
	add_child(_route)
	_radar = preload("res://ui/scan_radar.gd").new()
	_radar.size = Vector2(map_width,size.y)
	add_child(_radar)
	_radar.completed.connect(_finish_scan)
	UI.label(self,tr("flow.ice_order"),Rect2(0,0,size.x,30),17,UI.CYAN,true)
	var points := [Vector2(0.64,0.42),Vector2(0.20,0.18),Vector2(0.74,0.78)]
	for i in IDS.size():
		var point: Vector2 = Vector2(points[i].x*map_width,40+points[i].y*(size.y-100))
		var button = UI.button(self,"?",Rect2(point-Vector2(26,26),Vector2(52,52)),_choose_zone.bind(i))
		_zone_buttons.append(button)
		var ice = Icon.new()
		ice.kind = "ice"
		ice.disc = false
		ice.position = Vector2(12,12)
		ice.size = Vector2(28,28)
		button.add_child(ice)
		_zone_icons.append(ice)
		UI.panel(self,Rect2(point+Vector2(-70,32),Vector2(140,40)),Color("#071b32f4"),10)
		UI.label(self,tr("guide."+NAMES[i]),Rect2(point+Vector2(-66,36),Vector2(132,34)),14,UI.WHITE,true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var side := map_width+24
	var width := size.x-side
	UI.panel(self,Rect2(side,40,width,size.y-40),Color("#102b46"),18)
	_heading = UI.label(self,"",Rect2(side+18,50,width-36,44 if compact else 54),21 if compact else 26,UI.GOLD,true)
	_feedback = UI.label(self,"",Rect2(side+18,104 if compact else 122,width-36,58 if compact else 110),16 if compact else 21,UI.WHITE)
	_scan_button = UI.button(self,tr("visual.map.scan"),Rect2(side+18,170 if compact else 250,width-36,42 if compact else 54),_scan_zone)
	_collect_button = UI.button(self,tr("flow.collect"),Rect2(side+18,220 if compact else 318,width-36,42 if compact else 54),_collect,true)
	if not training:
		_utility(tr("nav.to_dome"),Rect2(side+18,274 if compact else 390,(width-48)/2,38 if compact else 44),return_requested.emit,tr("live.return_dome"))
		_utility(tr("nav.stop_trip"),Rect2(side+30+(width-48)/2,274 if compact else 390,(width-48)/2,38 if compact else 44),cancel_requested.emit,tr("guide.stop_trip"))
	_refresh()
func set_state(data: Dictionary) -> void:
	surveyed = data.get("surveyed",{}).duplicate()
	stock = data.get("stock",stock).duplicate()
	phase = str(data.get("phase","idle"))
	if phase != "idle" and str(data.get("selected","")).is_empty() == false:
		selected = str(data.selected)
		_zone = IDS.find(selected)
	if is_node_ready(): _refresh()
func _choose_zone(index: int) -> void:
	if phase != "idle" or _scanning: return
	_zone = index
	selected = IDS[index]
	_route.points = PackedVector2Array([Vector2(size.x*0.07,size.y*0.66),Vector2(size.x*0.20,size.y*0.58),_zone_buttons[index].position+Vector2(26,26)])
	step_performed.emit("zone_selected")
	_refresh()
func _refresh() -> void:
	for i in IDS.size():
		UI.paint(_zone_buttons[i],IDS[i] == selected)
		_zone_buttons[i].text = "" if surveyed.has(IDS[i]) else "?"
		_zone_icons[i].visible = surveyed.has(IDS[i])
		_zone_icons[i].kind = "ice" if int(stock.get(IDS[i],0)) > 0 else "check"
		_zone_icons[i].tint = UI.INK if IDS[i] == selected else UI.CYAN
		_zone_icons[i].queue_redraw()
		_zone_buttons[i].disabled = phase != "idle" or _scanning
	_heading.text = tr("flow.choose_zone") if selected.is_empty() else tr("guide."+NAMES[IDS.find(selected)])
	_feedback.text = tr("flow.scan_hint") if selected.is_empty() or not surveyed.has(selected) else tr("guide.zone_stock").format({"n":stock.get(selected,0)})
	if phase != "idle": _feedback.text = tr("guide."+phase)
	if _scanning: _feedback.text = tr("nav.scanning")
	_scan_button.disabled = selected.is_empty() or phase != "idle" or _scanning or surveyed.has(selected)
	_collect_button.disabled = _scanning or selected.is_empty() or not surveyed.has(selected) or int(stock.get(selected,0)) <= 0 or phase not in ["idle","blocked"]
	UI.paint(_scan_button,not _scan_button.disabled and not surveyed.has(selected))
	UI.paint(_collect_button,not _collect_button.disabled)
	_collect_button.text = tr("guide.retry") if phase == "blocked" else tr("flow.collect")
func _scan_zone() -> void:
	if selected.is_empty() or phase != "idle" or _scanning or surveyed.has(selected): return
	_scanning = true
	_refresh()
	_radar.start(_zone_buttons[_zone].position+Vector2(26,26))
func _finish_scan() -> void:
	_scanning = false
	if training:
		surveyed[selected] = true
		_scanned[IDS.find(selected)] = true
	else: scan_requested.emit(selected)
	step_performed.emit("zone_scanned")
	_refresh()
	narration_requested.emit(_feedback.text)
func _collect() -> void:
	if _collect_button.disabled: return
	if phase == "blocked": retry_requested.emit(); return
	step_performed.emit("collect_requested")
	if training:
		_feedback.text = tr("flow.practice_trip")
		completed.emit()
		narration_requested.emit(_feedback.text)
	else: trip_requested.emit(selected)

func _utility(title: String, rect: Rect2, callback: Callable, hint: String) -> void:
	var button = Button.new()
	button.text = title
	button.tooltip_text = hint
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size",14)
	UI.paint(button)
	for state in ["normal","hover","pressed","focus","disabled"]:
		var box = button.get_theme_stylebox(state).duplicate()
		box.content_margin_left = 6
		box.content_margin_right = 6
		button.add_theme_stylebox_override(state,box)
	button.pressed.connect(callback)
	add_child(button)
	button.position = rect.position
	button.size = rect.size

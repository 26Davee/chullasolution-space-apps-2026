extends Control
signal guide_requested(task: String, module: String)
signal section_requested(section: String)
signal narration_requested(text: String)
const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")
var game: Node
var _page := "attention"
var _selected := ""
var _scroll: ScrollContainer
var _detail: Control
var _tabs: Dictionary = {}
func _ready() -> void:
	for i in 3:
		var id: String = ["attention","discoveries","history"][i]
		_tabs[id] = UI.button(self,tr("notice."+id),Rect2(i*260,0,248,42),func(): _page = id; _selected = ""; _render())
		_tabs[id].add_theme_font_size_override("font_size",17)
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(0,62)
	_scroll.size = Vector2(336,size.y-62)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	add_child(_scroll)
	_detail = Control.new()
	_detail.position = Vector2(362,62)
	_detail.size = Vector2(size.x-362,size.y-62)
	add_child(_detail)
	_render()
func _entries() -> Array:
	var result: Array = []
	for item in game.session.messages:
		var alert: bool = str(item.kind) in ["resource","storm"]
		var discovery: bool = str(item.kind) in ["mission","upgrade"]
		if _page == "attention" and alert and not bool(item.get("resolved",false)): result.append(item)
		elif _page == "discoveries" and discovery: result.append(item)
		elif _page == "history" and (not alert or bool(item.get("resolved",false))): result.append(item)
	if _page == "attention":
		result.sort_custom(func(a,b): return _severity(a) > _severity(b))
	return result
func _severity(item: Dictionary) -> float:
	if item.kind == "storm": return 90
	return 100-float(game._gs().get(str(item.data.get("resource","agua"))))
func _title(item: Dictionary) -> String:
	if item.kind == "resource": return tr("notice.resource").format({"resource":tr("hud."+str(item.data.resource)+".nombre")})
	if item.kind == "storm": return tr("notice.storm")
	if item.kind == "mission": return game.CatalogScript.text("misiones."+str(item.data.id)+".titulo",str(item.data.id))
	if item.kind == "upgrade": return game.CatalogScript.text("upgrades."+str(item.data.id)+".nombre",str(item.data.id))
	return tr("live.messages")
func _render() -> void:
	for id in _tabs: UI.paint(_tabs[id],id == _page)
	for node in _scroll.get_children(): _scroll.remove_child(node); node.queue_free()
	for node in _detail.get_children(): _detail.remove_child(node); node.queue_free()
	var entries := _entries()
	if entries.is_empty():
		UI.label(_detail,tr("notice.empty" if _page == "attention" else "notice.empty_"+_page),Rect2(28,112,_detail.size.x-56,180),27,UI.CYAN,true)
		return
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation",12)
	_scroll.add_child(col)
	if not entries.any(func(item): return str(item.id) == _selected): _selected = str(entries[0].id)
	for item in entries:
		var button = UI.button(col,"",Rect2(0,0,316,92),func():
			_selected = str(item.id)
			game.session.mark_read(_selected)
			game._refresh_mail_badge()
			_render()
		)
		button.custom_minimum_size = Vector2(316,92)
		UI.paint(button,str(item.id) == _selected)
		var color := UI.INK if str(item.id) == _selected else UI.WHITE
		UI.label(button,_title(item),Rect2(14,10,286,50),18,color,true)
		UI.label(button,tr("notice.resolved" if item.get("resolved",false) else ("notice.active" if item.kind in ["resource","storm"] else "notice.information")),Rect2(14,66,286,20),12,color)
		if str(item.id) == _selected: _show_detail(item)
func _show_detail(item: Dictionary) -> void:
	if not bool(item.get("read",false)):
		game.session.mark_read(str(item.id))
		game._refresh_mail_badge()
	var width := _detail.size.x
	UI.panel(_detail,Rect2(Vector2.ZERO,_detail.size),Color("#193750"),20)
	var icon := Icon.new()
	icon.kind = str(item.data.get("resource","messages")).replace("energia_robot","robot_battery") if item.kind == "resource" else ("science" if item.kind in ["mission","upgrade"] else "messages")
	icon.tint = UI.CYAN
	icon.position = Vector2(24,20)
	icon.size = Vector2(64,64)
	_detail.add_child(icon)
	UI.label(_detail,_title(item),Rect2(110,22,width-138,74),27,UI.GOLD,true)
	var text: String = game.message_text(item)
	UI.label(_detail,text,Rect2(28,126,width-56,196),23,UI.WHITE)
	UI.label(_detail,tr("notice.resolved" if item.get("resolved",false) else ("notice.active" if item.kind in ["resource","storm"] else "notice.information")),Rect2(28,330,width-56,28),16,UI.CYAN,true)
	if item.kind in ["resource","storm"] and not item.get("resolved",false):
		var task: String = {"agua":"water","oxigeno":"oxygen","energia":"energy","escudo":"repair","energia_robot":"recharge"}.get(str(item.data.get("resource","escudo")),"repair")
		if item.kind == "storm": task = "storm"
		UI.button(_detail,tr("notice.solve"),Rect2(28,_detail.size.y-116,width-56,54),func():
			game.session.mark_read(str(item.id))
			guide_requested.emit(task,"")
		,true)
	elif item.kind in ["mission","upgrade"]:
		UI.button(_detail,tr("live.view_card"),Rect2(28,_detail.size.y-116,width-56,54),func(): section_requested.emit("science"),true)
	UI.button(_detail,tr("notice.listen"),Rect2(28,_detail.size.y-50,width-56,38),func(): narration_requested.emit(text))

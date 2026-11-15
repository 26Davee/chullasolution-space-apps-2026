extends Control
signal acknowledged(view_science: bool)
const UI = preload("res://ui/ui_kit.gd")
var mission_title := ""
var science_title := ""
var stars := 0
var card_module := "panel_solar"
var supplies: Dictionary = {}
var training := false
var picture_builder: Callable
var module_title: Callable
var continue_button: Button
func _ready() -> void:
	UI.label(self,mission_title,Rect2(0,0,size.x,46),26,UI.GOLD,true)
	UI.label(self,tr("live.reward_detail").format({"stars":stars}),Rect2(0,60,size.x,32),21,UI.WHITE)
	var card = UI.panel(self,Rect2(0,122,420,222),Color("#193750"),18)
	UI.label(card,tr("guide.letter"),Rect2(18,10,384,28),17,UI.GOLD,true)
	_picture(card,card_module,Rect2(16,52,166,128))
	UI.label(card,science_title,Rect2(198,52,204,112),21,UI.WHITE,true)
	UI.label(card,tr("guide.letter_saved"),Rect2(18,186,384,28),14,UI.CYAN)
	UI.label(self,tr("live.supplies"),Rect2(448,122,size.x-448,30),20,UI.CYAN,true)
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(448,164)
	scroll.size = Vector2(size.x-448,180)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	scroll.add_child(column)
	for id in supplies:
		var row = UI.panel(column,Rect2(0,0,size.x-468,160),Color("#193750"),16)
		row.custom_minimum_size = Vector2(size.x-468,160)
		_picture(row,str(id),Rect2(12,12,146,136))
		var title: String = module_title.call(str(id)) if module_title.is_valid() else tr("structures."+str(id))
		UI.label(row,"%s ×%d" % [title,int(supplies[id])],Rect2(176,38,size.x-656,90),21,UI.WHITE,true)
	if supplies.is_empty(): UI.label(self,tr("guide.no_supplies"),Rect2(448,174,size.x-448,116),21,UI.WHITE)
	if training: UI.label(self,tr("flow.practice"),Rect2(0,358,size.x,32),15,UI.CYAN,true)
	UI.button(self,tr("live.view_card"),Rect2(0,size.y-54,420,54),acknowledged.emit.bind(true),true)
	continue_button = UI.button(self,tr("live.continue"),Rect2(448,size.y-54,size.x-448,54),acknowledged.emit.bind(false))
func _picture(parent: Node, id: String, rect: Rect2) -> void:
	if picture_builder.is_valid(): picture_builder.call(parent,id,rect); return
	var image = TextureRect.new()
	image.texture = load("res://assets/ui/activities/"+{"panel_solar":"solar","procesador_hielo":"processor","generador_oxigeno":"oxygen","jardin":"garden","tanque_agua":"processor"}.get(id,"solar")+"-v1.png")
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.mouse_filter = MOUSE_FILTER_IGNORE
	image.position = rect.position
	image.size = rect.size
	parent.add_child(image)

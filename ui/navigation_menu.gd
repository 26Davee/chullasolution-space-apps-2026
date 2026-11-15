extends Control
signal action_requested(action: String)
const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")
var page := "more"
var buttons: Dictionary = {}
func _ready() -> void:
	if page == "more":
		UI.label(self,tr("nav.actions"),Rect2(0,0,size.x,24),17,UI.CYAN,true)
		_tile("processing","agua",tr("live.processing"),Rect2(0,32,(size.x-10)/2,52))
		_tile("rest","robot_battery",tr("live.rest"),Rect2((size.x+10)/2,32,(size.x-10)/2,52))
		UI.label(self,tr("nav.consult"),Rect2(0,100,size.x,24),17,UI.CYAN,true)
		for i in 4:
			var id: String = ["upgrades","science","messages","timmy"][i]
			_tile(id,["upgrades","science","messages","timmy"][i],tr("live."+id),Rect2(0,132+i*62,size.x,54))
	else:
		for i in 4:
			var id: String = ["language","audio","controls","exit"][i]
			_tile(id,["language","audio","camera","home"][i],tr("nav."+id),Rect2(0,i*66,size.x,56))
func _tile(id: String, symbol: String, title: String, rect: Rect2) -> void:
	var button = UI.button(self,"",rect,action_requested.emit.bind(id))
	button.name = "Navigation_"+id
	var icon = Icon.new()
	icon.kind = symbol
	icon.disc = false
	icon.tint = UI.CYAN
	icon.position = Vector2(12,(rect.size.y-24)/2)
	icon.size = Vector2(24,24)
	button.add_child(icon)
	var caption = UI.label(button,title,Rect2(46,4,rect.size.x-54,rect.size.y-8),15,UI.WHITE,true)
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	buttons[id] = button

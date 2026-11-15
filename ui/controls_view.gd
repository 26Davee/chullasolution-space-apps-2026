extends Control
const UI = preload("res://ui/ui_kit.gd")
const ACTIONS := ["move","orbit","zoom","follow","rotate","cancel"]
var tiles: Array[Control] = []
func _ready() -> void:
    var wide := size.x > 600
    var width := (size.x-16)/2 if wide else size.x
    var height := 92.0 if wide else 62.0
    for i in ACTIONS.size():
        var action: String = ACTIONS[i]
        var point := Vector2((i%2)*(width+16),int(i/2)*104) if wide else Vector2(0,i*64)
        var card := UI.panel(self,Rect2(point,Vector2(width,height)),Color("#16354d"),12)
        card.name = "Control_"+action
        var glyph = preload("res://ui/control_glyph.gd").new()
        glyph.action = action
        glyph.size = Vector2(70,height)
        card.add_child(glyph)
        UI.label(card,tr("controls."+action),Rect2(78,7,width-88,26),20 if wide else 16,UI.WHITE,true)
        UI.label(card,tr("controls."+action+".hint"),Rect2(78,35 if wide else 29,width-88,height-32),17 if wide else 13,UI.CYAN)
        tiles.append(card)
    UI.label(self,tr("controls.notice"),Rect2(0,322 if wide else 390,size.x,36),18 if wide else 14,UI.CYAN)

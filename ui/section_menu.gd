extends Control
signal section_requested(id: String)
const UI = preload("res://ui/ui_kit.gd")
const Icon = preload("res://ui/ui_icon.gd")
const IDS := ["construction", "expedition", "processing", "repair", "missions", "upgrades", "science"]
const SYMBOLS := ["base", "ice", "agua", "repair", "check", "energia", "science"]
const COLORS := [Color("#ffc64f"), Color("#68b9ff"), Color("#54d7d6"), Color("#ff927a"), Color("#a8e8c0"), Color("#bc9fff"), Color("#ffbbd1")]
var target := ""
var buttons: Dictionary = {}

func _ready() -> void:
    UI.label(self, tr("menu.choose"), Rect2(0, 0, 384, 28), 16, UI.CYAN)
    for i in range(IDS.size()):
        var id: String = IDS[i]
        var button := UI.button(self, "", Rect2(0, 38 + i * 60, 384, 52), section_requested.emit.bind(id))
        var active := target == "section:" + id
        UI.paint(button, active)
        var icon := Icon.new()
        icon.kind = SYMBOLS[i]
        icon.tint = UI.INK if active else COLORS[i]
        icon.disc = false
        icon.position = Vector2(14, 10)
        icon.size = Vector2(32, 32)
        button.add_child(icon)
        UI.label(button, tr("actions." + id), Rect2(62, 8, 300, 38), 22, UI.INK if active else UI.WHITE, true)
        button.tooltip_text = tr("actions." + id)
        buttons[id] = button

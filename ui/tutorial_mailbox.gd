extends Node
## Practice data is isolated from GameState and SaveManager.
const CatalogScript = preload("res://ui/progression_catalog.gd")
var session: Node
var agua := 10.0
var energia := 70.0
var messages: Array = []
func _init() -> void:
	session = self
	messages = [
		{"id":"practice:water","kind":"resource","data":{"resource":"agua"},"read":false,"resolved":false},
		{"id":"practice:storm","kind":"storm","data":{},"read":false,"resolved":false},
		{"id":"practice:letter","kind":"letter","data":{"title":TranslationServer.translate("tutorial.letter_title")},"read":false,"resolved":false}
	]
func _gs() -> Node: return self
func mark_read(id: String) -> void:
	for item in messages:
		if str(item.id) == id: item.read = true
func _refresh_mail_badge() -> void: pass
func message_text(item: Dictionary) -> String:
	if item.kind == "storm": return TranslationServer.translate("tutorial.storm_body")
	return TranslationServer.translate("tutorial.letter_body" if item.kind == "letter" else "tutorial.alert_body")

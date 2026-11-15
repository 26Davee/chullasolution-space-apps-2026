extends RefCounted
static func get_hint(game: Node) -> Dictionary:
	if game.guide != null and game.guide.active():
		return {"text":game.guide._speech,"task":game.guide.state.task,"module":game.guide.state.get("module","")}
	var gs = game._gs()
	if gs.oxigeno < 20: return _hint("oxygen","oxygen")
	if gs.agua <= 10: return water(game)
	if gs.energia < 15: return _hint("energy","energy")
	if gs.escudo < 25: return _hint("repair","repair")
	if gs.energia_robot < 15: return _hint("recharge","recharge")
	if gs.alerta_nube or gs.nube_activa: return _hint("storm","storm")
	var m: Dictionary = gs.obtener_mision_activa_localizada()
	var id: String = m.get("id","")
	match id:
		"mision_01": return _hint("build_panel","build","panel_solar") if gs.paneles_instalados < 1 else _hint("sun","energy")
		"mision_02","mision_10": return _hint("ice_"+game.ice.phase,"ice")
		"mision_03","mision_11": return water(game)
		"mision_04": return _hint("build_oxygen","build","generador_oxigeno") if not gs.generador_instalado else _hint("oxygen","oxygen")
		"mision_05": return _hint("recharge","recharge")
		"mision_06": return _hint("build_panel","build","panel_solar") if gs.paneles_instalados < 2 else _hint("sunset","energy")
		"mision_07": return _hint("night","water")
		"mision_08": return _hint("storm","storm")
		"mision_09","mision_12","mision_14": return _hint("repair","repair")
		"mision_13": return _hint("process","process")
		"mision_15": return _hint("build_garden","build","jardin")
	return _hint("stable","water")
static func water(game: Node) -> Dictionary:
	var gs = game._gs()
	if not gs.procesador_instalado: return _hint("build_processor","water","procesador_hielo")
	if gs.hielo <= 0: return _hint("water_ice","water")
	return _hint("water_process","water")
static func _hint(key: String, task: String, module := "") -> Dictionary:
	return {"text":TranslationServer.translate("hint."+key),"task":task,"module":module}

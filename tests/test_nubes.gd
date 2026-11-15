extends SceneTree

var fallos := 0

func check(nombre: String, ok: bool) -> void:
	print(("PASS  " if ok else "FALLA ") + nombre)
	if not ok:
		fallos += 1

func _init() -> void:
	_prueba_calendario("cadete")
	_prueba_calendario("ingeniero")
	_prueba_radar()
	_prueba_reparar()
	_prueba_vida_minima()
	print("---- ", "TODO BIEN" if fallos == 0 else str(fallos) + " FALLOS")
	quit(fallos)

# Golpes esperados: golpe base x intensidad, redondeado.
func _fuerzas_esperadas(modo: String) -> Array:
	var bal = JSON.parse_string(FileAccess.get_file_as_string("res://data/Balance/%s.json" % modo))
	var res := []
	var cal = null
	if FileAccess.file_exists("res://data/nasa/tormentas_juego.json"):
		cal = JSON.parse_string(FileAccess.get_file_as_string("res://data/nasa/tormentas_juego.json"))
	if cal == null:
		# Sin calendario de NASA: nubes fijas de intensidad 1
		for i in 3:
			res.append(int(bal.nube.golpe))
		return res
	for ev in cal.eventos:
		res.append(int(roundf(float(bal.nube.golpe) * float(ev.intensidad))))
	return res

func _prueba_calendario(modo: String) -> void:
	var golpes_esp := _fuerzas_esperadas(modo)
	var s := Simulacion.new(modo)
	var avisos := []
	var golpes := []
	s.advertencia_nube_iniciada.connect(func(_t): avisos.append(int(s.estado.tiempo_juego)))
	s.nube_impacto.connect(func(f, _v): golpes.append([int(s.estado.tiempo_juego), int(f)]))
	for i in 700:
		s.tick(1.0)
	check(modo + " avisos 160/400/640", avisos == [160, 400, 640])
	check(modo + " golpes en 180/420/660",
		golpes.size() == 3 and golpes[0][0] == 180 and golpes[1][0] == 420 and golpes[2][0] == 660)
	var fuerzas := []
	for g in golpes:
		fuerzas.append(g[1])
	check(modo + " fuerzas " + str(golpes_esp), fuerzas == golpes_esp)
	check(modo + " escudo final 0", s.estado.escudo == 0.0)
	check(modo + " vida >= 10", s.estado.vida >= 10.0)
	print("   ", modo, " avisos=", avisos, " golpes=", golpes, " vida=", s.estado.vida)

func _prueba_radar() -> void:
	var s := Simulacion.new("cadete")
	s.aplicar_mejora("escudo_alerta_temprana")
	var avisos := []
	s.advertencia_nube_iniciada.connect(func(_t): avisos.append(int(s.estado.tiempo_juego)))
	for i in 700:
		s.tick(1.0)
	check("radar avisos 140/380/620", avisos == [140, 380, 620])

func _prueba_reparar() -> void:
	var s := Simulacion.new("cadete")
	for i in 181:
		s.tick(1.0)
	check("escudo 70 tras 1ª nube", s.estado.escudo == 70.0)
	var e0: float = s.estado.energia
	check("reparar ok", s.reparar_escudo() == "ok")
	check("energía cobrada (-20)", absf((e0 - s.estado.energia) - 20.0) < 0.01)
	for i in 4:
		s.tick(1.0)
	check("a los 4 s aún 70", s.estado.escudo == 70.0)
	s.tick(1.0)
	check("a los 5 s escudo 100", s.estado.escudo == 100.0)
	var t := Simulacion.new("cadete")
	t.estado.energia = 10.0
	t.estado.escudo = 50.0   # escudo dañado, si no responde "escudo_lleno"
	check("sin energía rechaza", t.reparar_escudo() == "sin_energia")

func _prueba_vida_minima() -> void:
	var s := Simulacion.new("cadete")
	s.estado.escudo = 0.0
	s.estado.vida = 12.0
	s.golpe_de_nube()
	check("vida nunca < 10", s.estado.vida >= 10.0)

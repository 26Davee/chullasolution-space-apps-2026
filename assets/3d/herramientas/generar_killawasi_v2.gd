extends SceneTree
## Genera las escenas de arte de Killawasi (versión 2) con el kit redondeado.
## Uso, desde la carpeta del proyecto y con Godot 4.7.2 Standard:
##   godot --headless --path . --script res://assets/3d/herramientas/generar_killawasi_v2.gd
## Añade nombres de pieza tras "--" para generar solo algunas (por ejemplo: -- capsula domo).

const K := preload("res://assets/3d/herramientas/killawasi_kit.gd")
const OUT := "res://assets/3d/"


func _initialize() -> void:
	_run.call_deferred()


func _piezas() -> Dictionary:
	var base = load("res://assets/3d/herramientas/piezas_base.gd")
	var d := {
		"capsula": ["lunar_lander", base.capsula, false],
		"domo": ["domo_lunar", base.domo, false],
		"panel": ["panel_solar", base.panel_solar, true],
		"procesador": ["procesador_hielo", base.procesador, true],
		"tanque": ["tanque_agua", base.tanque, true],
	}
	for extra in ["piezas_modulos", "piezas_personajes", "piezas_herramientas", "piezas_entorno"]:
		var path := "res://assets/3d/herramientas/%s.gd" % extra
		if ResourceLoader.exists(path):
			d.merge(load(path).piezas())
	return d


func _run() -> void:
	var piezas := _piezas()
	var pedidas := OS.get_cmdline_user_args()
	var total := 0
	for id in piezas:
		if not pedidas.is_empty() and not id in pedidas:
			continue
		var def: Array = piezas[id]
		var raiz: Node3D = (def[1] as Callable).call()
		if def[2]:
			# los módulos se modelan mirando a +Z y se entregan con el frente hacia −Z
			for child in raiz.get_children():
				if child is Node3D:
					child.transform = Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO) * child.transform
		K.own(raiz)
		var escena := PackedScene.new()
		var err := escena.pack(raiz)
		if err == OK:
			err = ResourceSaver.save(escena, OUT + String(def[0]) + ".tscn")
		print("%s -> %s.tscn  %s  (%d mallas, %d triangulos)" % [id, def[0], "OK" if err == OK else "ERROR %d" % err, _contar(raiz)[0], _contar(raiz)[1]])
		raiz.free()
		total += 1
	print("Piezas generadas: %d" % total)
	quit(0)


func _contar(raiz: Node) -> Array:
	var mallas := 0
	var tris := 0
	for item in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := item as MeshInstance3D
		if mi.mesh == null:
			continue
		mallas += 1
		for s in mi.mesh.get_surface_count():
			var arrays := mi.mesh.surface_get_arrays(s)
			if arrays[Mesh.ARRAY_INDEX] != null:
				tris += (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
			else:
				tris += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return [mallas, tris]

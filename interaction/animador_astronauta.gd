## Animación procedural para un astronauta armado por piezas (sin AnimationPlayer).
##
## Colócalo en la raíz de astronauta.tscn. No necesita saber quién lo mueve:
## mide cuánto se desplaza la raíz en cada frame de física y con eso:
##   - Al caminar: balancea piernas y brazos (opuestos), dobla rodillas y codos,
##     hace rebotar y girar la cadera y contragira el torso.
##   - Quieto: vuelve a la pose original y "respira" suavemente.
##
## Detecta las articulaciones por nombre (español o inglés) y las imprime en consola.
## También añade al astronauta al grupo "astronauta" para que ClickToMove lo encuentre.
class_name AnimadorAstronauta
extends Node3D

@export_group("General")
## Raíz del astronauta. Vacío = este mismo nodo (lo normal si el script va en la raíz).
@export var raiz: Node3D
@export var grupo: StringName = &"astronauta"
@export var imprimir_articulaciones: bool = true
## Si el modelo mira hacia +Z (el mismo ajuste que en ClickToMove).
@export var modelo_mira_hacia_z_positivo: bool = true

@export_group("Paso")
## Velocidad (m/s) a la que el balanceo llega a su amplitud completa. Igual que ClickToMove.velocidad.
@export var velocidad_referencia: float = 3.0
## Pasos completos (izquierda + derecha) por segundo a velocidad de referencia.
@export var ciclos_por_segundo: float = 1.4
@export var umbral_movimiento: float = 0.05
## Rapidez con la que entra/sale la animación de caminar.
@export var suavizado: float = 8.0

@export_group("Amplitudes caminar (grados / metros)")
@export var amp_piernas: float = 28.0
@export var amp_rodillas: float = 35.0
@export var amp_pies: float = 12.0
@export var amp_brazos: float = 25.0
@export var amp_antebrazos: float = 15.0
@export var amp_giro_cadera: float = 6.0
@export var amp_giro_torso: float = 5.0
@export var inclinacion_torso: float = 4.0
@export var rebote_cadera: float = 0.04

@export_group("Respiración (quieto)")
@export var resp_ciclos_por_segundo: float = 0.25
@export var resp_torso: float = 2.0
@export var resp_cabeza: float = 1.0
@export var resp_brazos: float = 3.0
@export var resp_rebote: float = 0.008

@export_group("Ejes y sentido")
## Eje local sobre el que se balancean piernas y brazos (adelante/atrás).
@export var eje_balanceo: Vector3 = Vector3.RIGHT
## Eje local de giro de cadera/torso.
@export var eje_giro: Vector3 = Vector3.UP
## Eje local para abrir los brazos hacia los lados al respirar.
@export var eje_apertura: Vector3 = Vector3.FORWARD
## Actívalos si piernas o brazos se mueven al revés.
@export var invertir_piernas: bool = false
@export var invertir_brazos: bool = false

const LADOS := ["pierna", "rodilla", "pie", "brazo", "antebrazo"]

## clave ("pierna_izq", "cadera", ...) -> { nodo, rot, pos }
var articulaciones: Dictionary = {}

var _raiz: Node3D
var _pos_anterior: Vector3
var _vel: float = 0.0
var _mov: float = 0.0      # 0 = quieto, 1 = caminando a velocidad de referencia
var _fase: float = 0.0
var _t_resp: float = 0.0


func _ready() -> void:
	_raiz = raiz if raiz else self
	if grupo != &"" and not _raiz.is_in_group(grupo):
		_raiz.add_to_group(grupo)
	_detectar_articulaciones()
	_pos_anterior = _raiz.global_position


func _physics_process(delta: float) -> void:
	if delta <= 0.0 or articulaciones.is_empty():
		return

	# Velocidad horizontal de la raíz
	var pos := _raiz.global_position
	var d := pos - _pos_anterior
	d.y = 0.0
	_pos_anterior = pos
	var k := clampf(suavizado * delta, 0.0, 1.0)
	_vel = lerpf(_vel, d.length() / delta, k)

	var objetivo := clampf(_vel / velocidad_referencia, 0.0, 1.0) if _vel > umbral_movimiento else 0.0
	_mov = lerpf(_mov, objetivo, k)

	var ritmo := clampf(_vel / velocidad_referencia, 0.6, 1.6)
	_fase = fmod(_fase + delta * ciclos_por_segundo * TAU * ritmo, TAU)
	_t_resp = fmod(_t_resp + delta * resp_ciclos_por_segundo * TAU, TAU)

	_aplicar_pose()


# ===========================================================================
# Pose
# ===========================================================================

func _aplicar_pose() -> void:
	var m := _mov
	var quieto := 1.0 - m
	var s := sin(_fase)
	var c := cos(_fase)
	var resp := sin(_t_resp)
	var sp := -1.0 if invertir_piernas else 1.0
	var sb := -1.0 if invertir_brazos else 1.0

	# Piernas: opuestas entre sí
	_poner("pierna_izq", eje_balanceo * deg_to_rad(amp_piernas) * s * m * sp)
	_poner("pierna_der", eje_balanceo * deg_to_rad(amp_piernas) * -s * m * sp)

	# Rodillas: se doblan hacia atrás mientras la pierna avanza
	_poner("rodilla_izq", eje_balanceo * -deg_to_rad(amp_rodillas) * maxf(0.0, c) * m * sp)
	_poner("rodilla_der", eje_balanceo * -deg_to_rad(amp_rodillas) * maxf(0.0, -c) * m * sp)

	# Pies: compensan para quedar más planos
	_poner("pie_izq", eje_balanceo * -deg_to_rad(amp_pies) * s * m * sp)
	_poner("pie_der", eje_balanceo * deg_to_rad(amp_pies) * s * m * sp)

	# Brazos: opuestos a la pierna del mismo lado + apertura al respirar
	var apertura := eje_apertura * deg_to_rad(resp_brazos) * (0.5 + 0.5 * resp) * quieto
	_poner("brazo_izq", eje_balanceo * deg_to_rad(amp_brazos) * -s * m * sb + apertura)
	_poner("brazo_der", eje_balanceo * deg_to_rad(amp_brazos) * s * m * sb - apertura)

	# Antebrazos: ligeramente doblados al caminar, más al ir hacia delante
	_poner("antebrazo_izq", eje_balanceo * deg_to_rad(amp_antebrazos) * (0.6 + 0.4 * maxf(0.0, -s)) * m * sb)
	_poner("antebrazo_der", eje_balanceo * deg_to_rad(amp_antebrazos) * (0.6 + 0.4 * maxf(0.0, s)) * m * sb)

	# Cadera: giro + rebote (punto más alto cuando las piernas se cruzan)
	_poner("cadera",
		eje_giro * deg_to_rad(amp_giro_cadera) * s * m,
		Vector3.UP * (rebote_cadera * absf(c) * m + resp_rebote * resp * quieto))

	# Torso: contragiro, inclinación al caminar y respiración
	_poner("torso",
		eje_giro * -deg_to_rad(amp_giro_torso) * s * m
		+ eje_balanceo * (deg_to_rad(inclinacion_torso) * m + deg_to_rad(resp_torso) * resp * quieto))

	# Cabeza: compensa el giro del torso para mirar al frente
	_poner("cabeza",
		eje_giro * deg_to_rad(amp_giro_torso) * 0.5 * s * m
		+ eje_balanceo * -deg_to_rad(resp_cabeza) * resp * quieto)


func _poner(clave: String, rot: Vector3, pos := Vector3.ZERO) -> void:
	var a: Dictionary = articulaciones.get(clave, {})
	if a.is_empty():
		return
	var nodo: Node3D = a.nodo
	nodo.rotation = a.rot + rot
	nodo.position = a.pos + pos


# ===========================================================================
# Detección de articulaciones
# ===========================================================================

func _detectar_articulaciones() -> void:
	articulaciones.clear()
	var candidatos: Dictionary = {}   # clave -> { nodo, prof }
	_recorrer(_raiz, 0, "", candidatos)

	for clave in candidatos:
		var n: Node3D = candidatos[clave].nodo
		articulaciones[clave] = { "nodo": n, "rot": n.rotation, "pos": n.position }

	if imprimir_articulaciones:
		_imprimir()


func _recorrer(padre: Node, prof: int, lado_heredado: String, candidatos: Dictionary) -> void:
	for hijo in padre.get_children():
		if hijo == self or not (hijo is Node3D):
			continue
		var nombre := _normalizar(String(hijo.name))
		var lado := _lado(nombre)
		if lado == "":
			lado = lado_heredado

		var parte := _parte(nombre)
		if parte != "":
			var clave := parte
			if parte in LADOS:
				var l := lado if lado != "" else _lado_por_posicion(hijo)
				if l != "":
					clave = parte + "_" + l
				else:
					clave = ""   # sin lado no se puede animar
			if clave != "" and (not candidatos.has(clave) or prof < candidatos[clave].prof):
				# Si "PiernaIzquierda" contiene "Muslo", se queda la más cercana a la raíz
				candidatos[clave] = { "nodo": hijo, "prof": prof }

		_recorrer(hijo, prof + 1, lado, candidatos)


func _normalizar(s: String) -> String:
	s = s.to_lower()
	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ñ", "n"]]:
		s = s.replace(par[0], par[1])
	return s


func _contiene(nombre: String, palabras: Array) -> bool:
	for p in palabras:
		if nombre.contains(p):
			return true
	return false


func _parte(n: String) -> String:
	if _contiene(n, ["armature", "armadura", "collision", "colision"]):
		return ""
	if _contiene(n, ["antebrazo", "forearm", "codo", "elbow", "lowerarm"]):
		return "antebrazo"
	if _contiene(n, ["mano", "hand", "dedo", "finger", "guante", "glove"]):
		return ""
	if _contiene(n, ["brazo", "hombro", "shoulder", "upperarm", "arm"]):
		return "brazo"
	if _contiene(n, ["rodilla", "espinilla", "pantorrilla", "canilla", "shin", "calf", "knee", "lowerleg"]):
		return "rodilla"
	if _contiene(n, ["muslo", "pierna", "thigh", "upperleg", "leg"]):
		return "pierna"
	if _contiene(n, ["pie", "foot", "bota", "boot", "zapato"]):
		return "pie"
	if _contiene(n, ["cadera", "pelvis", "hip"]):
		return "cadera"
	if _contiene(n, ["torso", "pecho", "chest", "spine", "columna", "tronco"]):
		return "torso"
	if _contiene(n, ["cabeza", "head", "casco", "helmet", "cuello", "neck"]):
		return "cabeza"
	return ""


func _lado(n: String) -> String:
	if _contiene(n, ["izquierd", "izq", "left"]):
		return "izq"
	if _contiene(n, ["derech", "right"]):
		return "der"
	for suf in ["_l", ".l", "-l", " l"]:
		if n.ends_with(suf):
			return "izq"
	for suf in ["_r", ".r", "-r", " r"]:
		if n.ends_with(suf):
			return "der"
	if n.begins_with("l_") or n.begins_with("l."):
		return "izq"
	if n.begins_with("r_") or n.begins_with("r."):
		return "der"
	return ""


## Si el nombre no indica lado ("Muslo"), se deduce por la posición X respecto a la raíz.
func _lado_por_posicion(n: Node3D) -> String:
	var x := (_raiz.global_transform.affine_inverse() * n.global_position).x
	if absf(x) < 0.001:
		return ""
	# Mirando a +Z, la izquierda del personaje está en +X; mirando a -Z, en -X.
	var es_izq := x > 0.0 if modelo_mira_hacia_z_positivo else x < 0.0
	return "izq" if es_izq else "der"


func _imprimir() -> void:
	print("[AnimadorAstronauta] Articulaciones detectadas en '%s':" % _raiz.name)
	if articulaciones.is_empty():
		push_warning("[AnimadorAstronauta] No se detectó ninguna articulación. Revisa los nombres de los nodos.")
		return
	var claves := articulaciones.keys()
	claves.sort()
	for clave in claves:
		var n: Node3D = articulaciones[clave].nodo
		print("   %-14s -> %s" % [clave, _raiz.get_path_to(n)])
	var faltan: Array[String] = []
	for esperada in ["cadera", "torso", "cabeza", "pierna_izq", "pierna_der", "brazo_izq", "brazo_der"]:
		if not articulaciones.has(esperada):
			faltan.append(esperada)
	if not faltan.is_empty():
		print("   (no encontradas: %s)" % ", ".join(faltan))

extends Node3D
## Escena de revisión del arte de Killawasi (F6).
## N día/noche · D escudo del domo (100, 70, 30, 0) · A nivel del tanque · P gota del procesador
## L puerta y escalerilla · 1–5 expresiones del robot y poses de la vicuña · C cambia de cámara · T nube de tormenta · F12 guarda una captura.

const VISTAS := [
	{"objetivo": Vector3(4.2, 3.4, 1.5), "giro": 6.0, "altura": 7.0, "distancia": 41.0, "fov": 42.0},
	{"objetivo": Vector3(3.0, 1.2, 2.5), "giro": 0.0, "altura": 42.0, "distancia": 46.0, "fov": 34.0},
	{"objetivo": Vector3(-4.6, 1.1, 9.6), "giro": 18.0, "altura": 12.0, "distancia": 9.0, "fov": 36.0},
	{"objetivo": Vector3(14.5, 1.5, 1.5), "giro": -8.0, "altura": 20.0, "distancia": 17.0, "fov": 36.0},
	{"objetivo": Vector3(-13.0, 1.2, -3.0), "giro": 12.0, "altura": 20.0, "distancia": 17.0, "fov": 36.0},
]
const ESCUDOS := [100.0, 70.0, 30.0, 0.0]

@onready var camara: Camera3D = $Camara
@onready var mundo: Node3D = $Mundo
var vista := 0
var escudo := 0
var agua := 1
var acceso_abierto := true


func _ready() -> void:
	_encuadrar()
	$Vicuna/Poses.play("respirar")


func _encuadrar() -> void:
	var v: Dictionary = VISTAS[vista]
	var giro := deg_to_rad(float(v["giro"]))
	var altura := deg_to_rad(float(v["altura"]))
	var objetivo: Vector3 = v["objetivo"]
	camara.fov = v["fov"]
	camara.position = objetivo + Vector3(sin(giro) * cos(altura), sin(altura), cos(giro) * cos(altura)) * float(v["distancia"])
	camara.look_at(objetivo)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_N:
			var ambiente := mundo.get_node("Ambiente")
			ambiente.set_noche(not ambiente.noche)
			mundo.get_node("PanelSolar/Indicador").visible = not ambiente.noche
		KEY_D:
			escudo = (escudo + 1) % ESCUDOS.size()
			mundo.get_node("Domo").set_escudo(ESCUDOS[escudo])
		KEY_A:
			agua = (agua + 1) % 3
			var nivel := mundo.get_node("TanqueAgua/NivelAgua") as Node3D
			nivel.visible = agua > 0
			nivel.scale.y = [1.0, 1.0, 1.85][agua]
		KEY_P:
			mundo.get_node("ProcesadorHielo/AnimationPlayer").play("procesar")
		KEY_L:
			acceso_abierto = not acceso_abierto
			mundo.get_node("Capsula/Acceso").play("abrir" if acceso_abierto else "cerrar")
		KEY_T:
			$Tormenta.visible = not $Tormenta.visible
		KEY_C:
			vista = (vista + 1) % VISTAS.size()
			_encuadrar()
		KEY_F12:
			get_viewport().get_texture().get_image().save_png("user://killawasi_captura.png")
			print("Captura guardada en ", ProjectSettings.globalize_path("user://killawasi_captura.png"))
	var index := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5].find(event.keycode)
	if index >= 0:
		$Robot.cambiar_expresion($Robot.EXPRESIONES[index])
		$Vicuna/Poses.play(["respirar", "hablar", "senal", "aviso", "celebrar"][index])

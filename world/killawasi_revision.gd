extends Node3D

const ART := "res://assets/3d/"
const SAMPLES := [
	"procesador_hielo", "tanque_agua", "reciclador_agua", "panel_solar",
	"generador_oxigeno", "bateria_lunar", "jardin_lunar",
	"rover_lunar", "crater_hielo",
]
@onready var key: DirectionalLight3D = $Luz
@onready var environment: Environment = $Ambiente.environment
@onready var character: Node3D = $Astronauta
@onready var guide: Node3D = $Vicuna
var night := false
var shield_step := 0
var water_step := 1
var access_open := false
const CELL_COLOR := Color("#7C7890")


func _ready() -> void:
	environment = environment.duplicate()
	$Ambiente.environment = environment
	$Domo/Escudo.material_override = $Domo/Escudo.material_override.duplicate()
	_layout_cells()
	var access := $Capsula/Acceso as AnimationPlayer
	access.play("cerrar")
	access.seek(access.get_animation("cerrar").length, true)
	access.stop(true)
	for index in range(SAMPLES.size()):
		var module := _object(SAMPLES[index])
		module.name = SAMPLES[index]
		module.position = Vector3(-8.0 + (index % 3) * 7.2, 0, -5.0 - floorf(index / 3.0) * 6.8)
	$Camara.look_at(Vector3(-1.8, 0.7, -5.6))


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_N:
		night = not night
		key.light_energy = 0.18 if night else 0.68
		environment.ambient_light_color = Color("#789CDE") if night else Color("#BFCBE9")
		environment.ambient_light_energy = 0.32 if night else 0.60
		$Tormenta.visible = night
		$panel_solar/Indicador.visible = not night
	if event.keycode == KEY_L:
		access_open = not access_open
		$Capsula/Acceso.play("abrir" if access_open else "cerrar")
	if event.keycode == KEY_A:
		water_step = (water_step + 1) % 3
		$tanque_agua/NivelAgua.visible = water_step > 0
		$tanque_agua/NivelAgua.scale.y = [1.0, 1.0, 1.85][water_step]
	if event.keycode == KEY_P:
		$procesador_hielo/AnimationPlayer.play("procesar")
	if event.keycode == KEY_D:
		shield_step = (shield_step + 1) % 4
		var shield := $Domo/Escudo as MeshInstance3D
		var shield_material := shield.material_override as StandardMaterial3D
		var tint := shield_material.albedo_color
		tint.a = [0.13, 0.09, 0.04, 0.0][shield_step]
		shield_material.albedo_color = tint
		$Domo.visible = shield_step < 3
	var index := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5].find(event.keycode)
	if index >= 0:
		character.get_node("Poses").play(["reposo", "caminar", "cavar", "cargar_hielo", "tocar_domo"][index])
		guide.get_node("Poses").play(["respirar", "hablar", "senal", "aviso", "celebrar"][index])


func _object(file: String) -> Node3D:
	var piece := (load(ART + file + ".tscn") as PackedScene).instantiate() as Node3D
	add_child(piece)
	return piece

func _layout_cells() -> void:
	var surface := BoxMesh.new()
	surface.size = Vector3(5.6, 0.03, 4.2)
	var material := StandardMaterial3D.new()
	material.albedo_color = CELL_COLOR.lerp(Color("#B9B4BF"), 0.16)
	surface.material = material
	for index in range(6):
		var slot := MeshInstance3D.new()
		slot.name = "Casilla%d" % (index + 1)
		slot.mesh = surface
		slot.position = Vector3(-8.0 + (index % 3) * 7.2, 0.006, -5.0 - floorf(index / 3.0) * 6.8)
		add_child(slot)
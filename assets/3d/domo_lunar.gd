extends Node3D
## Domo de Killawasi. `escudo` va de 0 a 100 y cambia el aspecto en cuatro niveles:
## 100 (nítido), 70 (más tenue), 30 (parpadeo suave) y 0 (solo el contorno apagado).

@export_range(0.0, 100.0) var escudo := 100.0: set = set_escudo

var _material: ShaderMaterial
var _borde: StandardMaterial3D


func _ready() -> void:
	_material = ($Escudo as MeshInstance3D).material_override.duplicate()
	$Escudo.material_override = _material
	_borde = ($Borde as MeshInstance3D).material_override.duplicate()
	$Borde.material_override = _borde
	_aplicar()


func set_escudo(valor: float) -> void:
	escudo = clampf(valor, 0.0, 100.0)
	if is_node_ready():
		_aplicar()


func _aplicar() -> void:
	var presencia := 1.0
	var pulso := 0.0
	var brillo := 2.0
	if escudo <= 0.0:
		presencia = 0.0
		brillo = 0.0
	elif escudo <= 30.0:
		presencia = 0.45
		pulso = 1.0
		brillo = 1.0
	elif escudo <= 70.0:
		presencia = 0.65
		brillo = 1.5
	_material.set_shader_parameter("presencia", presencia)
	_material.set_shader_parameter("pulso", pulso)
	_borde.emission_energy_multiplier = brillo
	_borde.albedo_color = Color("#5BE6F2") if escudo > 0.0 else Color("#3E5A70")

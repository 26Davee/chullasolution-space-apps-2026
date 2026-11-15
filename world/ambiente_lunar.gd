extends Node3D
## Luz y cielo de Killawasi (puesto 3). Instancia `world/ambiente_lunar.tscn` y llama a
## `set_noche(true)` o `set_noche(false)` cuando cambie el ciclo solar. La transición dura
## `transicion` segundos.

@export var noche := false: set = set_noche
@export var transicion := 2.5

const DIA := {"sol": 1.05, "relleno": 0.22, "ambiente": 0.5, "color": Color("#9D9BC6"), "cielo": 1.0}
const NOCHE := {"sol": 0.08, "relleno": 0.18, "ambiente": 0.3, "color": Color("#5D6FC0"), "cielo": 0.55}

var _tween: Tween


func _ready() -> void:
	# Menu/tutorial viewports must not change the live world’s environment resources.
	$Ambiente.environment = $Ambiente.environment.duplicate(true)
	$Cielo/Boveda.material_override = $Cielo/Boveda.material_override.duplicate(true)
	_aplicar(0.0)


func set_noche(valor: bool) -> void:
	if noche == valor and is_node_ready(): return
	noche = valor
	if is_node_ready():
		_aplicar(transicion)


func _aplicar(duracion: float) -> void:
	var meta: Dictionary = NOCHE if noche else DIA
	var env: Environment = ($Ambiente as WorldEnvironment).environment
	var boveda := ($Cielo/Boveda as MeshInstance3D).material_override as ShaderMaterial
	if _tween != null:
		_tween.kill()
	$Cielo/DistantSun.visible = not noche
	if duracion <= 0.0:
		$Sol.light_energy = meta["sol"]
		$Relleno.light_energy = meta["relleno"]
		env.ambient_light_energy = meta["ambiente"]
		env.ambient_light_color = meta["color"]
		boveda.set_shader_parameter("oscuro", meta["cielo"])
		return
	_tween = create_tween().set_parallel(true)
	_tween.tween_property($Sol, "light_energy", meta["sol"], duracion)
	_tween.tween_property($Relleno, "light_energy", meta["relleno"], duracion)
	_tween.tween_property(env, "ambient_light_energy", meta["ambiente"], duracion)
	_tween.tween_property(env, "ambient_light_color", meta["color"], duracion)
	_tween.tween_property(boveda, "shader_parameter/oscuro", meta["cielo"], duracion)

func set_solar_time(seconds: float) -> void:
	var phase := fposmod(seconds,480.0)/480.0
	noche = phase >= 0.5
	# A continuous solar altitude drives both the visible sun and illumination.
	var altitude := sin(phase*TAU)
	var daylight := smoothstep(-0.10,0.18,altitude)
	if _tween != null: _tween.kill()
	$Sol.light_energy = lerpf(float(NOCHE.sol),float(DIA.sol),daylight)
	$Relleno.light_energy = lerpf(float(NOCHE.relleno),float(DIA.relleno),daylight)
	var env: Environment = ($Ambiente as WorldEnvironment).environment
	env.ambient_light_energy = lerpf(float(NOCHE.ambiente),float(DIA.ambiente),daylight)
	env.ambient_light_color = NOCHE.color.lerp(DIA.color,daylight)
	var sky := ($Cielo/Boveda as MeshInstance3D).material_override as ShaderMaterial
	sky.set_shader_parameter("oscuro",lerpf(float(NOCHE.cielo),float(DIA.cielo),daylight))
	$Cielo/DistantSun.visible = altitude >= -0.03
	$Cielo/DistantSun.position = Vector3(-110*cos(phase*TAU),300*altitude,-275)
	$Sol.rotation_degrees = Vector3(-maxf(2,90*altitude),-38,0)

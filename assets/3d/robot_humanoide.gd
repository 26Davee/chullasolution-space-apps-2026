extends Node3D
## Control visual del protagonista. El juego elige la expresión según la acción.

const EXPRESIONES: Array[StringName] = [&"reposo", &"escaneo", &"trabajo", &"alerta", &"exito"]

@onready var pantalla: ShaderMaterial = $Cadera/Torso/Cabeza/CaraDigital.material_override

var expresion: StringName = &"reposo"
var transicion: Tween


## Devuelve false si el nombre no está admitido. Funciona antes de add_child().
func cambiar_expresion(nueva: StringName) -> bool:
	var indice := EXPRESIONES.find(nueva)
	if indice == -1:
		return false
	if nueva == expresion:
		return true
	expresion = nueva
	if not is_node_ready():
		return true
	if transicion:
		transicion.kill()
	transicion = create_tween()
	transicion.tween_method(_animar_apertura, float(pantalla.get_shader_parameter("apertura")), 0.1, 0.075)
	transicion.tween_callback(pantalla.set_shader_parameter.bind("expresion", indice))
	transicion.tween_method(_animar_apertura, 0.1, 1.0, 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return true


func _ready() -> void:
	pantalla.set_shader_parameter("expresion", EXPRESIONES.find(expresion))


func _animar_apertura(valor: float) -> void:
	pantalla.set_shader_parameter("apertura", valor)

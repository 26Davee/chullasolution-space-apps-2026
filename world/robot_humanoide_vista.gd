extends Node3D

@onready var frente: Node3D = $Frente
@onready var espalda: Node3D = $Espalda
@onready var camara: Camera3D = $Camara

@onready var encuadre_completo := camara.transform
@onready var distancia_completa := camara.size
var detalle := false


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var tecla: Key = event.keycode
	if tecla >= KEY_1 and tecla <= KEY_5:
		var cara: StringName = frente.EXPRESIONES[tecla - KEY_1]
		frente.cambiar_expresion(cara)
		espalda.cambiar_expresion(cara)
	elif tecla == KEY_TAB:
		detalle = not detalle
		if detalle:
			camara.position = Vector3(0.88, 2.04, -4.0)
			camara.look_at(Vector3(0.88, 1.68, 0))
			camara.size = 0.89
		else:
			camara.transform = encuadre_completo
			camara.size = distancia_completa

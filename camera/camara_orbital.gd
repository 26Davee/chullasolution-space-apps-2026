# camera/camara_orbital.gd
# Cámara orbital semiisométrica (~45°) para Godot 4.
# - Arrastrar con el ratón: gira alrededor de la base (yaw) e inclina (pitch).
# - Rueda: acerca / aleja.
# - Límites de zoom, ángulo y altura mínima: no atraviesa el suelo ni pierde la base.
# - Suavizado con lerp independiente de los FPS.
#
# Uso: añade un Camera3D a la escena, asígnale este script y en el Inspector
# arrastra el nodo de la base a "objetivo" (o deja vacío y usa "centro").
class_name CamaraOrbital
extends Camera3D

@export_group("Objetivo")
@export var objetivo: Node3D                    ## Nodo que se orbita (centro de la base)
@export var centro: Vector3 = Vector3.ZERO      ## Se usa si "objetivo" está vacío

@export_group("Zoom")
@export var distancia: float = 20.0
@export var distancia_min: float = 8.0          ## Lo más cerca posible
@export var distancia_max: float = 40.0         ## Lo más lejos posible
@export var velocidad_zoom: float = 0.1         ## Fracción de distancia por clic de rueda

@export_group("Ángulos (grados)")
@export var yaw_inicial: float = 45.0           ## 45° = vista isométrica clásica
@export_range(0.0, 89.0) var pitch_inicial: float = 45.0
@export_range(0.0, 89.0) var pitch_min: float = 25.0   ## Nunca demasiado rasante
@export_range(0.0, 89.0) var pitch_max: float = 75.0   ## Nunca totalmente cenital
@export var permitir_inclinar: bool = true

@export_group("Suelo")
@export var altura_suelo: float = 0.0
@export var altura_min: float = 1.5             ## Altura mínima de la cámara sobre el suelo

@export_group("Control")
@export var boton_arrastre: MouseButton = MOUSE_BUTTON_LEFT
@export var sensibilidad: float = 0.3           ## Grados por píxel arrastrado
@export var suavizado: float = 10.0             ## Mayor = sigue más rápido al valor deseado
@export var activo: bool = true

# Valores deseados (los que cambia el input) y actuales (interpolados)
var _yaw_deseado: float
var _pitch_deseado: float
var _dist_deseada: float
var _yaw: float
var _pitch: float
var _dist: float
var _arrastrando := false


func _ready() -> void:
	reiniciar()
	_yaw = _yaw_deseado
	_pitch = _pitch_deseado
	_dist = _dist_deseada
	_aplicar()


# ---------- API pública ----------

## Vuelve a la vista inicial (con suavizado).
func reiniciar() -> void:
	_yaw_deseado = deg_to_rad(yaw_inicial)
	_pitch_deseado = deg_to_rad(pitch_inicial)
	_dist_deseada = distancia
	_limitar()


## Gira por código (en grados).
func girar(delta_yaw_grados: float, delta_pitch_grados: float = 0.0) -> void:
	_yaw_deseado += deg_to_rad(delta_yaw_grados)
	_pitch_deseado += deg_to_rad(delta_pitch_grados)
	_limitar()


## factor > 1 aleja, < 1 acerca.
func hacer_zoom(factor: float) -> void:
	_dist_deseada *= factor
	_limitar()


func punto_objetivo() -> Vector3:
	return objetivo.global_position if is_instance_valid(objetivo) else centro


# ---------- Entrada ----------

func _unhandled_input(event: InputEvent) -> void:
	if not activo:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == boton_arrastre:
			_arrastrando = mb.pressed
		elif mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			# factor viene de trackpads (puede ser 0 en ratones normales)
			var paso := 1.0 + velocidad_zoom * (mb.factor if mb.factor > 0.0 else 1.0)
			hacer_zoom(1.0 / paso if mb.button_index == MOUSE_BUTTON_WHEEL_UP else paso)

	elif event is InputEventMouseMotion and _arrastrando:
		var mm := event as InputEventMouseMotion
		var dy := mm.relative.y * sensibilidad if permitir_inclinar else 0.0
		girar(-mm.relative.x * sensibilidad, dy)

	elif event is InputEventMagnifyGesture:  # pellizco en trackpad
		hacer_zoom(1.0 / (event as InputEventMagnifyGesture).factor)


# ---------- Bucle ----------

func _process(delta: float) -> void:
	# Factor de lerp independiente de FPS: 1 - e^(-k·dt)
	var t := 1.0 - exp(-suavizado * minf(delta, 0.1))
	_yaw = lerp_angle(_yaw, _yaw_deseado, t)      # gira por el camino más corto
	_pitch = lerpf(_pitch, _pitch_deseado, t)
	_dist = lerpf(_dist, _dist_deseada, t)
	_aplicar()


# ---------- Internos ----------

func _limitar() -> void:
	_dist_deseada = clampf(_dist_deseada, distancia_min, distancia_max)

	# Pitch mínimo necesario para respetar altura_min con la distancia deseada
	var p_min := deg_to_rad(pitch_min)
	var p_max := deg_to_rad(pitch_max)
	var sobre_suelo := punto_objetivo().y - altura_suelo
	var necesario := (altura_min - sobre_suelo) / _dist_deseada
	if necesario > 0.0:
		p_min = maxf(p_min, asin(minf(1.0, necesario)))
	_pitch_deseado = clampf(_pitch_deseado, minf(p_min, p_max), p_max)

	_yaw_deseado = wrapf(_yaw_deseado, -PI, PI)


func _aplicar() -> void:
	var c := punto_objetivo()
	var pos := c + Vector3(
		_dist * cos(_pitch) * sin(_yaw),
		_dist * sin(_pitch),
		_dist * cos(_pitch) * cos(_yaw)
	)
	# Seguro final: nunca por debajo del suelo
	pos.y = maxf(pos.y, altura_suelo + altura_min)
	global_position = pos
	look_at(c, Vector3.UP)

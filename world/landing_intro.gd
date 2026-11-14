extends Node3D
## Standalone welcome shot. The caller may connect completed before adding this scene.

signal completed

const TOUCHDOWN := 5.9
const DURATION := 7.4
const GEAR_START := 2.25
const GEAR_END := 4.65
const DUST_START := 3.6
const DEPLOYED_ANGLE := 0.51
const SKY_DEPTH := 300.0
const EARTH_DIRECTION := Vector3(-0.73, 0.045, -0.68)
const SUN_DIRECTION := Vector3(-0.25, 0.042, -0.97)

@onready var camera: Camera3D = $Camera3D
@onready var lander: Node3D = $Lander
@onready var legs: Array[Node3D] = [$Lander/Leg0, $Lander/Leg1, $Lander/Leg2, $Lander/Leg3]
@onready var earth: MeshInstance3D = $Sky/Earth
@onready var sun: MeshInstance3D = $Sky/DistantSun
@onready var plume: Node3D = $Lander/BrakingPlume
@onready var dust: CPUParticles3D = $LunarDust

var elapsed := 0.0
var finished := false


func _ready() -> void:
	camera.make_current()
	_pose(0.0)


func _process(delta: float) -> void:
	elapsed = minf(elapsed + delta, DURATION)
	if elapsed >= DURATION:
		_finish()
	else:
		_pose(elapsed)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ESCAPE, KEY_SPACE] or event.physical_keycode in [KEY_ESCAPE, KEY_SPACE]:
			get_viewport().set_input_as_handled()
			_finish()


func _finish() -> void:
	if finished:
		return
	finished = true
	set_process(false)
	set_process_input(false)
	_pose(DURATION)
	completed.emit()


func _pose(time: float) -> void:
	var descent := minf(time / TOUCHDOWN, 1.0)
	# A short acceleration blends into a long brake with zero speed at contact.
	var remaining := pow(1.0 - descent, 2.0) * (1.0 + 1.65 * descent)
	var approach := 1.0 - smoothstep(0.0, 0.88, descent)
	lander.position = Vector3(-2.15 * remaining, 10.7 * remaining, -0.7 * remaining)
	lander.rotation = Vector3(-0.085 * approach, -0.28 + 0.33 * approach, 0.13 * approach)

	var gear := smoothstep(GEAR_START, GEAR_END, time)
	for leg in legs:
		var swing := lerpf(-1.83, DEPLOYED_ANGLE, gear)
		var arm: Node3D = leg.get_node("Arm")
		arm.rotation.z = swing
		var foot: Node3D = arm.get_node("Foot")
		foot.rotation.z = -swing
		var brace: MeshInstance3D = leg.get_node("Brace")
		var brace_end := arm.transform * Vector3(0.0, -1.16, 0.0)
		_align_link(brace, Vector3(-0.07, 0.51, 0.0), brace_end)

	plume.visible = time < TOUCHDOWN
	var throttle := 0.83 + 0.31 * sin(descent * PI)
	var clearance := (lander.position.y + plume.position.y) / 2.20
	plume.scale.y = minf(throttle + 0.08 * sin(time * 41.0), clearance)

	var dolly := smoothstep(0.15, DURATION, time)
	camera.position = Vector3(18.5 - 2.0 * dolly, 13.5 - 1.8 * dolly, 28.0 - 2.7 * dolly)
	camera.look_at(to_global(Vector3(0.0, 6.2 - 3.3 * dolly, 0.0)))
	# Render at a common depth while preserving angular size and eliminating parallax.
	earth.position = camera.position + EARTH_DIRECTION.normalized() * SKY_DEPTH
	sun.position = camera.position + SUN_DIRECTION.normalized() * SKY_DEPTH
	sun.look_at(camera.global_position, global_basis.y.normalized())
	dust.emitting = time >= DUST_START and time < TOUCHDOWN
	dust.visible = time >= DUST_START and time < DURATION


func _align_link(link: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var direction := end - start
	link.transform = Transform3D(
		Basis(Vector3.FORWARD, atan2(direction.x, direction.y)).scaled_local(Vector3(1.0, direction.length(), 1.0)),
		(start + end) * 0.5
	)

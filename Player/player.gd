extends CharacterBody3D

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

@export var MOUSE_SENSITIVITY : float = 0.005
var speed: float
const WALK_SPEED : float = 1.5
const SPRINT_SPEED : float = 5.0
const JUMP_VELOCITY : float = 3.5
const IN_AIR_CONTROL : float = 1.0

const BASE_FOV : float = 75.0
const FOV_CHANGE : float = 1.5

const BOB_FREQUENCY : float = 3.4
const BOB_AMPLITUDE : float = 0.05
var t_bob: float = 0.0

const HEAD_TILT_WEIGHT: float = 4.0
const HEAD_Z_MAX_ROTATION: float = deg_to_rad(30.0)
var _prev_head_rotation_y: float = 0.0


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		handleCameraMovement(event)

func handleCameraMovement(event):
	head.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
	camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	handleMovement(delta)
	handleCamerabob(delta)
	handleCameraTilt(delta)
	camera.fov = setFov(delta)
	move_and_slide()

func handleMovement(delta):
	handleSprint()
	
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveForward", "moveBackward")
	var direction = (head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 15.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 15.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * IN_AIR_CONTROL)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * IN_AIR_CONTROL)
		
func handleSprint():
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
		
func setFov(delta) -> float:
	var velocityClamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var targetFov = BASE_FOV + FOV_CHANGE * velocityClamped
	return lerp(camera.fov, targetFov, delta * 8.0)
	
var bob_strength := 0.0
var target_strength := 0.0

func handleCamerabob(delta):
	t_bob += delta * float(is_on_floor())

	var idle := getCamerabobPosition(t_bob, 0.015, 2.5, 0.01, 1.5, 0.03, 0.5)
	var walk := getCamerabobPosition(t_bob, 0.04, 9.5, 0.01, 6.0, 0.04, 6.0)
	var run  := getCamerabobPosition(t_bob, 0.16, 15.0, 0.01, 9.0, 0.1, 12.0)

	var target: Vector3
	if velocity.is_zero_approx():
		target = idle
	elif speed > WALK_SPEED + 0.5:
		target = run
	else:
		target = walk

	camera.transform.origin = camera.transform.origin.lerp(target, delta * 15.0)

func getCamerabobPosition(time, pitchAmp: float, pitchFreq: float, \
							yawAmp: float, yawFreq: float, \
							rollAmp: float, rollFreq: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * pitchFreq) * pitchAmp
	pos.x = sin(time * rollFreq) * rollAmp
	pos.z = sin(time * yawFreq) * yawAmp
	return pos
	
func handleCameraTilt(delta: float) -> void:
	var rotation_delta: float = angle_difference(_prev_head_rotation_y, head.rotation.y)

	var tilt_target: float = 0.0
	if abs(rotation_delta) > 0.0001:
		var tilt_strength: float = clampf(abs(rotation_delta) * HEAD_TILT_WEIGHT, 0.0, 1.0)
		tilt_target = sign(rotation_delta) * HEAD_Z_MAX_ROTATION * tilt_strength

	head.rotation.z = lerpf(head.rotation.z, tilt_target, delta * HEAD_TILT_WEIGHT)
	_prev_head_rotation_y = head.rotation.y

extends CharacterBody3D


const SPEED = 1.5
#const JUMP_VELOCITY = 4.5
const SPRINT_MULTIPLIER = 1

@export var mouseSensitivity := 0.3
var rotation_x := 0.0
var rotation_y := 0.0
var isSprinting: bool = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	#if Input.is_action_just_pressed("jump") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
		
	if Input.is_action_just_pressed("sprint"):
		isSprinting = true

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("moveLeft", "moveRight", "moveForward", "moveBackward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if input_dir.y >= 0 and isSprinting == true:
		isSprinting = false
		
	var currentSpeed = SPEED * (SPRINT_MULTIPLIER if isSprinting else 1)
	
	if direction:
		velocity.x = direction.x * currentSpeed
		velocity.z = direction.z * currentSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, currentSpeed)
		velocity.z = move_toward(velocity.z, 0, currentSpeed)

	move_and_slide()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotation_y -= event.relative.x * mouseSensitivity
		rotation_x -= event.relative.y * mouseSensitivity
		
		rotation_x = clamp(rotation_x, -70, 70)
		
		rotation_degrees.y = rotation_y
		rotation_degrees.x = rotation_x

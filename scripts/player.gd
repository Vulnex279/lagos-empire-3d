class_name EmpirePlayer
extends CharacterBody3D

var move_input = Vector2.ZERO
var running = false
var enabled = true
var yaw = 0.0
var pitch = -0.30
var body: EmpireActor
var pivot: Node3D
var arm: SpringArm3D
var camera: Camera3D
var stride = 0.0

func _ready() -> void:
	var collision = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.9
	collision.shape = capsule
	collision.position.y = 0.95
	add_child(collision)
	body = EmpireActor.new()
	add_child(body)
	pivot = Node3D.new()
	pivot.position.y = 1.6
	add_child(pivot)
	arm = SpringArm3D.new()
	arm.spring_length = 5.0
	arm.margin = 0.25
	arm.add_excluded_object(get_rid())
	pivot.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 66
	camera.far = 240
	arm.add_child(camera)
	camera.current = true
	floor_snap_length = 0.3

func look(delta: Vector2) -> void:
	yaw -= delta.x*0.004
	pitch = clampf(pitch-delta.y*0.003,-0.85,0.15)

func _physics_process(delta: float) -> void:
	pivot.rotation = Vector3(pitch,yaw,0)
	if not enabled:
		return
	var input = move_input
	if input.length() < 0.1:
		input = Input.get_vector("left","right","forward","back")
	var direction = Basis(Vector3.UP,yaw)*Vector3(input.x,0,input.y)
	var speed = 7.2 if running or Input.is_action_pressed("run") else 4.0
	velocity.x = move_toward(velocity.x,direction.x*speed,delta*28)
	velocity.z = move_toward(velocity.z,direction.z*speed,delta*28)
	if not is_on_floor():
		velocity.y -= 24*delta
	else:
		velocity.y = -0.1
	move_and_slide()
	if direction.length() > 0.1:
		body.rotation.y = lerp_angle(body.rotation.y,atan2(-direction.x,-direction.z),delta*12)
	body.locomotion(Vector2(velocity.x,velocity.z).length())

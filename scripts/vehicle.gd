class_name EmpireVehicle
extends CharacterBody3D

var kind = "sedan"
var fleet = false
var driving = false
var controls = Vector2.ZERO
var speed = 0.0
var brake = false
var camera: Camera3D
var pivot: Node3D
var wheels: Array[Node3D] = []
var steering_pivots: Array[Node3D] = []
var visual: Node3D
var headlamps: Array[SpotLight3D] = []
var steering_angle = 0.0
var condition = 100.0
var fuel = 100.0
var impact_cooldown = 0.0

func _ready() -> void:
	var file = {"sedan":"sedan","suv":"suv-luxury","sports":"race"}[kind]
	var path = "vehicles/"+("taxi" if fleet else file)+".glb"
	if not fleet and kind in ["suv","sports"]: path = "original/"+("oba-grand" if kind == "suv" else "adura-gt")+".glb"
	visual = Art.model(self,path,Vector3.ZERO,1.9,PI)
	_bind_wheels(visual)
	for x in [-0.65,0.65]:
		var lamp = SpotLight3D.new()
		lamp.position = Vector3(x,0.8,-2.1)
		lamp.spot_range = 22
		lamp.spot_angle = 32
		lamp.light_color = Color("fff1d2")
		lamp.light_energy = 1.5
		lamp.shadow_enabled = false
		add_child(lamp)
		headlamps.append(lamp)
	var c = CollisionShape3D.new()
	var s = BoxShape3D.new()
	s.size = Vector3(2.1,1.2 if kind == "sports" else 1.75,4.7)
	c.shape = s
	c.position.y = 0.7 if kind == "sports" else 0.9
	add_child(c)
	pivot = Node3D.new()
	add_child(pivot)
	pivot.position.y = 2.0
	var arm = SpringArm3D.new()
	arm.spring_length = 7.2
	arm.rotation.x = -0.22
	arm.add_excluded_object(get_rid())
	pivot.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 72
	camera.far = 240
	arm.add_child(camera)
	floor_snap_length = 0.4

func _physics_process(delta: float) -> void:
	impact_cooldown = maxf(0,impact_cooldown-delta)
	if driving:
		var axis = controls
		if axis.length() < 0.1:
			axis = Input.get_vector("left","right","forward","back")
		var throttle = -axis.y if fuel > 0 and condition > 0 else 0.0
		var limit: float = Catalog.VEHICLES[kind].speed*(0.45+condition/180)
		if brake or Input.is_action_pressed("brake"):
			speed = move_toward(speed,0,delta*24)
		elif throttle != 0:
			speed = move_toward(speed,throttle*(limit if throttle > 0 else 8),delta*9)
		else:
			speed = move_toward(speed,0,delta*3)
		steering_angle = lerpf(steering_angle,-axis.x*0.45,delta*8)
		rotation.y -= axis.x*clampf(speed/8,-1,1)*delta*1.55
		fuel = maxf(0,fuel-absf(speed)*delta*0.009)
	else:
		speed = move_toward(speed,0,delta*12)
	var forward = -global_basis.z
	velocity.x = forward.x*speed
	velocity.z = forward.z*speed
	velocity.y = -0.1 if is_on_floor() else velocity.y-24*delta
	var previous = speed
	move_and_slide()
	if is_on_wall() and absf(previous) > 4:
		speed *= 0.5
		if impact_cooldown <= 0:
			condition = maxf(0,condition-absf(previous)*0.4)
			impact_cooldown = 1.0
	for wheel in wheels:
		wheel.rotate_x(speed*delta*2.3)

	for steering in steering_pivots:
		steering.rotation.y = steering_angle
	var hour = float(Economy.state.clock)/Economy.DAY_SECONDS*24
	for lamp in headlamps: lamp.visible = driving and (hour < 6 or hour > 18)

func _bind_wheels(node: Node3D) -> void:
	for child in node.get_children():
		if not child is Node3D: continue
		if str(child.name).begins_with("wheel-"):
			var steering = Node3D.new()
			node.add_child(steering)
			steering.transform = child.transform
			child.reparent(steering,false)
			child.transform = Transform3D.IDENTITY
			wheels.append(child)
			if "front" in str(child.name): steering_pivots.append(steering)
		else: _bind_wheels(child)

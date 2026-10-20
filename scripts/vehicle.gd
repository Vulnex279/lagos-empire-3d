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
var wheels: Array[MeshInstance3D] = []
var condition = 100.0
var fuel = 100.0
var impact_cooldown = 0.0

func _ready() -> void:
	var suv = kind == "suv"
	var color: Color = Color("e3ba52") if fleet else Catalog.VEHICLES[kind].color
	Geo.box(self,Vector3(0,0.85,0),Vector3(1.9,0.65,4.2),color)
	Geo.box(self,Vector3(0,1.4,0.25),Vector3(1.65,0.7 if suv else 0.6,2.3),color)
	Geo.box(self,Vector3(0,1.43,-0.92),Vector3(1.52,0.46,0.04),Color("294954"))
	Geo.box(self,Vector3(0,1.43,1.42),Vector3(1.52,0.46,0.04),Color("294954"))
	for x in [-0.835,0.835]:
		Geo.box(self,Vector3(x,1.43,0.2),Vector3(0.03,0.45,1.9),Color("294954"))
	for x in [-0.65,0.65]:
		Geo.box(self,Vector3(x,0.9,-2.12),Vector3(0.45,0.2,0.05),Color("fff3bb"))
		Geo.box(self,Vector3(x,0.9,2.12),Vector3(0.4,0.18,0.05),Color("b85044"))
	for x in [-0.98,0.98]:
		for z in [-1.3,1.3]:
			var wheel = Geo.cylinder(self,Vector3(x,0.48,z),0.44,0.22,Color("202b30"))
			wheel.rotation.z = PI/2
			wheels.append(wheel)
	var c = CollisionShape3D.new()
	var s = BoxShape3D.new()
	s.size = Vector3(1.95,1.6,4.3)
	c.shape = s
	c.position.y = 0.95
	add_child(c)
	pivot = Node3D.new()
	add_child(pivot)
	pivot.position.y = 2.0
	var arm = SpringArm3D.new()
	arm.spring_length = 8.0
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
		wheel.rotate_y(speed*delta*1.8)

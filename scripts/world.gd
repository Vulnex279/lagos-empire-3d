class_name LagosWorld
extends Node3D

var sun: DirectionalLight3D
var environment: WorldEnvironment
var interior_exits = {"home": Vector3(350,0,5), "mansion": Vector3(400,0,8), "apartment":Vector3(450,0,6)}
var npcs: Array[Node3D] = []
var elapsed = 0.0

func _ready() -> void:
	build()

func build() -> void:
	environment = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("5089a8")
	sky_mat.sky_horizon_color = Color("d2d8c3")
	sky_mat.ground_horizon_color = Color("d2d8c3")
	sky.sky_material = sky_mat
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("b8cbd2")
	e.ambient_light_energy = 0.35
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = e
	add_child(environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-35,0)
	sun.light_color = Color("fff3dd")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 75
	add_child(sun)
	Geo.box(self, Vector3(0,-0.35,0), Vector3(270,0.7,270), Color("827a68"), true)
	for axis in [-60,0,60]:
		Geo.box(self, Vector3(axis,0.01,0), Vector3(18,0.06,258), Color("9c9d95"))
		Geo.box(self, Vector3(0,0.012,axis), Vector3(258,0.06,18), Color("9c9d95"))
		Geo.box(self, Vector3(axis,0.06,0), Vector3(14,0.04,258), Color("3e4c50"))
		Geo.box(self, Vector3(0,0.065,axis), Vector3(258,0.04,14), Color("3e4c50"))
		for mark in range(-122,125,8):
			if abs(mark) < 10 or abs(abs(mark)-60) < 10:
				continue
			Geo.box(self, Vector3(axis,0.095,mark), Vector3(0.17,0.02,3), Color("eddfb3"))
			Geo.box(self, Vector3(mark,0.098,axis), Vector3(3,0.02,0.17), Color("eddfb3"))
	for id in Catalog.LOCATIONS:
		_build_location(id)
	# Continuous small shopfronts make the high street readable at walking height.
	var shop_names = ["Provisions & grains","Phone repairs","Tailoring studio","Fresh bread"]
	for z in [-73,-13,13,73]:
		for i in 4:
			var x = [-42,-12,12,42][i]
			var facing = -1 if z < 0 else 1
			var yaw = 0.0 if facing < 0 else PI
			villa(Vector3(x,0,z),yaw,1,3)
			var sign = Geo.label(self,shop_names[i],Vector3(x,2.7,z-facing*0.25),18)
			sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			sign.rotation.y = yaw
			Art.model(self,"nature/plant_bushDetailed.glb",Vector3(x-2,0,z-facing*1.2),1.2)
	for x in [83,105]:
		Art.model(self,"original/palm-court-villa.glb",Vector3(x,0,-111),0.75)
		Art.collider(self,Vector3(x,2.25,-115),Vector3(12,4.5,7.5))
	for z in [20,100]:
		villa(Vector3(-108,0,z),PI,1,5)
	var rng = RandomNumberGenerator.new()
	rng.seed = 279
	for x in [-107,-83,-38,25,42,83,108]:
		for z in [-110,-42,42,108]:
			var p = Vector3(x,0,z)
			var close = false
			for loc in Catalog.LOCATIONS.values():
				if p.distance_to(loc.pos + Vector3(0,0,-8 if loc.pos.z < 0 else 8)) < 24:
					close = true
			if close:
				continue
			var h = rng.randf_range(6,16)
			_building(p,Vector3(13,h,12),Color.from_hsv(rng.randf_range(0.04,0.14),0.23,rng.randf_range(0.65,0.92)))
	for x in range(-112,115,28):
		for z in [-11,11,-71,71]:
			if abs(x) < 12 or abs(abs(x)-60) < 12:
				continue
			palm(Vector3(x,0,z))
	for x in [-10,10]:
		for z in [-105,-45,35,100]:
			Art.model(self,"original/streetlight.glb",Vector3(x,0,z))
	for z in [-100,-40,30,90]:
		Art.model(self,"original/power-pole.glb",Vector3(-12,0,z))
	for x in [79,83,87]:
		Art.model(self,"original/fuel-pump.glb",Vector3(x,0,-22))
	# Imported parked vehicles, including two inspectable dealership display cars.
	for p in [Vector3(-5,0,38),Vector3(65,0,-34),Vector3(38,0,5)]:
		Art.model(self,"vehicles/taxi.glb",p,1.9,PI/2)
		Art.collider(self,p+Vector3(0,0.8,0),Vector3(4.3,1.6,1.9))
	Art.model(self,"original/oba-grand.glb",Vector3(34,0,-23),1.9,0.7)
	Art.model(self,"original/adura-gt.glb",Vector3(42,0,-23),1.9,-0.7)
	for i in 4:
		var p = Vector3(33+i*3,0,22)
		Art.model(self,"original/market-stall.glb",p,1.0)
		Art.collider(self,p+Vector3(0,0.5,0),Vector3(1.8,1,1.8))
	for i in 10:
		var p = Vector3(-10 if i%2 else 10,0,-100+i*21)
		var npc = Geo.person(self,p,Color.from_hsv(float(i)/10,0.45,0.8))
		npc.set_meta("origin",p)
		npcs.append(npc)
	# Lagoon edge and low skyline, inaccessible scenery beyond the playable district.
	Geo.box(self,Vector3(0,-0.15,157),Vector3(500,0.15,45),Color("438a93"))
	for i in 15:
		Geo.box(self,Vector3(-145+i*21,12,193),Vector3(13,18+i%4*7,15),Color("718c91"))
	for p in [Vector3(0,1.5,131),Vector3(0,1.5,-131)]:
		Geo.box(self,p,Vector3(264,3,1),Color("879d90"),true)
	for p in [Vector3(131,1.5,0),Vector3(-131,1.5,0)]:
		Geo.box(self,p,Vector3(1,3,264),Color("879d90"),true)
	_build_interior("home",Vector3(350,0,0),Vector3(10,4,12))
	_build_interior("mansion",Vector3(400,0,0),Vector3(18,5,20))
	_build_interior("apartment",Vector3(450,0,0),Vector3(12,4,14))
	Geo.batch_static(self)
	Art.batch_static(self)

func _building(p: Vector3, size: Vector3, _color: Color) -> void:
	var file = "Building_Small_1" if size.y < 10 else "Building_Medium_2_001"
	var scale_value = 0.75 if size.y < 10 else 0.85
	Art.model(self,"city/"+file+".gltf",p+Vector3(0,0,5),scale_value)
	Art.collider(self,p+Vector3(0,7,-1),Vector3(12,14,10))

func _build_location(id: String) -> void:
	var d = Catalog.LOCATIONS[id]
	var p: Vector3 = d.pos
	var facing = -1.0 if p.z < 0 else 1.0
	if id == "mansion":
		Art.model(self,"original/palm-court-villa.glb",p+Vector3(0,0,-4))
		Art.collider(self,p+Vector3(0,3,-9),Vector3(16,6,10))
	elif id in ["home","apartment","garage"]:
		villa(p+Vector3(0,0,2*facing),PI if facing > 0 else 0.0,2 if id in ["mansion","apartment"] else 1,8 if id == "mansion" else 5)
	else:
		var file = "Building_Large_2" if id in ["bank","invest"] else "Building_Small_1"
		Art.model(self,"city/"+file+".gltf",p+Vector3(0,0,2*facing),0.8,PI if facing > 0 else 0)
		Art.collider(self,p+Vector3(0,7,7*facing),Vector3(11,14,10))
	Geo.label(self,d.name,p+Vector3(0,3.4,0.7*facing),26)
	var marker = Geo.cylinder(self,p+Vector3(0,0.12,0),1.1,0.08,Color("69d8bb"))
	marker.name = "Point_" + id
	if id == "mansion":
		Art.model(self,"original/residence-gate.glb",p+Vector3(0,0,3),1.0)
		Geo.box(self,p+Vector3(0,0.03,0),Vector3(7,0.05,14),Color("787a70"))
		for x in [-10,10]:
			Art.model(self,"suburban/fence.glb",p+Vector3(x,0,1),3.0)
			palm(p+Vector3(x,0,5))
	if id in ["work","market","bank","dealer"]:
		var actor = Geo.person(self,p+Vector3(2,0,0),d.color.darkened(0.2))
		actor.rotation.y = 0 if facing < 0 else PI
		actor.play_state("Talk")
		actor.set_meta("owner",id)
		npcs.append(actor)

func villa(p: Vector3, yaw: float, floors: int, half_width: int) -> void:
	# Quaternius facade modules provide bevelled window frames, masonry, PBR
	# texture maps, cornices and actual doors. Collision is a separate box.
	var house = Node3D.new()
	add_child(house)
	house.position = p
	house.rotation.y = yaw
	for level in floors:
		for x in range(-half_width+1,half_width,2):
			for z in [0,-10]:
				var piece = "Trim_Window" if level > 0 or x != 0 else "Trim_FirstFloor_Wall"
				Art.model(house,"city/"+piece+".gltf",Vector3(x,level*3, z),1,0 if z == 0 else PI)
		for z in range(-9,0,2):
			for side in [-1,1]:
				Art.model(house,"city/Trim_Window.gltf",Vector3(side*half_width,level*3,z),1,side*PI/2)
	for x in range(-half_width+2,half_width,4):
		for z in [-2,-6,-10]:
			Art.model(house,"city/Roof_4x4.gltf",Vector3(x,floors*3,z))
	Art.model(house,"city/DoorFrame_Metal_Single.gltf",Vector3(0,0,0.15))
	Art.model(house,"city/Door_2.gltf",Vector3(0,0,0.2))
	Art.model(house,"city/Entrance_Concrete_2x2.gltf",Vector3(0,0,0.35))
	Art.collider(house,Vector3(0,floors*1.5,-5),Vector3(half_width*2,floors*3,10))
	for x in [-half_width+0.5,half_width-0.5]:
		Art.model(house,"city/Trim_Column_Center.gltf",Vector3(x,0,0.15))
		Art.model(house,"city/Prop_Planter_Single.gltf",Vector3(x,0,1.5))

func palm(p: Vector3) -> void:
	Art.model(self,"nature/tree_palmDetailedTall.glb",p,2.1)

func _build_interior(id: String, center: Vector3, size: Vector3) -> void:
	Geo.box(self,center+Vector3(0,-0.2,0),Vector3(size.x,0.4,size.z),Color("c4ad88"),true)
	Geo.box(self,center+Vector3(0,size.y+0.15,0),Vector3(size.x,0.3,size.z),Color("dfd6bd"),true)
	for sign_value in [-1,1]:
		Geo.box(self,center+Vector3(sign_value*size.x/2,size.y/2,0),Vector3(0.3,size.y,size.z),Color("e3d6b9"),true)
		Geo.box(self,center+Vector3(0,size.y/2,sign_value*size.z/2),Vector3(size.x,size.y,0.3),Color("e3d6b9"),true)
	Art.model(self,"furniture/bedSingle.glb" if id == "home" else "furniture/bedDouble.glb",center+Vector3(-size.x/2+2,0,-3),1.7)
	Art.collider(self,center+Vector3(-size.x/2+2,0.5,-3),Vector3(2,1,3))
	Art.model(self,"furniture/cabinetTelevision.glb",center+Vector3(2,0,-4),2)
	Art.model(self,"furniture/televisionModern.glb",center+Vector3(2,1.1,-4),1.5)
	Art.model(self,"furniture/rugRectangle.glb",center+Vector3(0,0.01,1),2.3)
	Art.model(self,"furniture/lampRoundFloor.glb",center+Vector3(-size.x/2+1,0,3),1.6)
	Art.model(self,"furniture/pottedPlant.glb",center+Vector3(size.x/2-1,0,3),1.5)
	Art.model(self,"furniture/ceilingFan.glb",center+Vector3(0,size.y-0.2,0),1.5)
	if id != "home":
		Art.model(self,"furniture/loungeDesignSofa.glb",center+Vector3(1,0,2),2.2,PI)
		Art.model(self,"furniture/tableCoffeeGlass.glb",center+Vector3(1,0,0),1.6)
		for i in 3:
			Art.model(self,"furniture/"+["kitchenFridge","kitchenSink","kitchenStove"][i]+".glb",center+Vector3(size.x/2-1.2,0,-4+i*1.5),1.5,-PI/2)
		Art.model(self,"furniture/bookcaseOpen.glb",center+Vector3(-size.x/2+0.6,0,0),2,PI/2)
	Geo.label(self,"Palm Court" if id == "mansion" else "Home • a place to begin",center+Vector3(0,3,-size.z/2+0.3),32)
	Geo.cylinder(self,interior_exits[id]+Vector3(0,0.04,0),0.8,0.06,Color("60baa2"))
	Geo.box(self,center+Vector3(0,1.4,size.z/2-0.18),Vector3(2,2.8,0.08),Color("816447"))
	var lamp = OmniLight3D.new()
	lamp.position = center+Vector3(0,3,0)
	lamp.omni_range = 16
	lamp.light_color = Color("ffe4b4")
	lamp.light_energy = 0.8
	add_child(lamp)

func set_time(hour: float) -> void:
	sun.rotation_degrees.x = -sin((hour-6)/24*TAU)*65
	sun.light_energy = clampf(sin((hour-6)/24*TAU)*0.85,0.03,0.85)
	environment.environment.ambient_light_energy = 0.2 if hour < 6 or hour > 19 else 0.35
	var daylight = clampf(sin((hour-6)/24*TAU)*2.0,0.0,1.0)
	var sky_mat: ProceduralSkyMaterial = environment.environment.sky.sky_material
	sky_mat.sky_top_color = Color("0b192b").lerp(Color("5089a8"),daylight)
	sky_mat.sky_horizon_color = Color("23333e").lerp(Color("d2d8c3"),daylight)
	sky_mat.ground_horizon_color = sky_mat.sky_horizon_color

func _process(delta: float) -> void:
	elapsed += delta
	var camera = get_viewport().get_camera_3d()
	for i in npcs.size():
		var actor: EmpireActor = npcs[i]
		var near = camera != null and actor.global_position.distance_to(camera.global_position) < (38 if Economy.state.settings.graphics == "Low" else 65)
		actor.set_active(near)
		if not near or not actor.has_meta("origin"): continue
		# Authored sidewalk routes are clear of buildings and never cross roads.
		# Schedules pause pedestrians at night. No per-frame path search.
		var hour = float(Economy.state.clock)/Economy.DAY_SECONDS*24
		var walking = hour > 6 and hour < 21
		var origin: Vector3 = actor.get_meta("origin")
		if walking:
			actor.position.z = origin.z + sin(elapsed*0.2+i)*5
			actor.rotation.y = PI if cos(elapsed*0.2+i) > 0 else 0
		actor.locomotion(absf(cos(elapsed*0.2+i)) if walking else 0)

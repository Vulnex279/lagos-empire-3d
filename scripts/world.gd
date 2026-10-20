class_name LagosWorld
extends Node3D

var sun: DirectionalLight3D
var environment: WorldEnvironment
var interior_exits = {"home": Vector3(350,0,5), "mansion": Vector3(400,0,8)}
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
	sun.light_color = Color("ffdfab")
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 75
	add_child(sun)
	Geo.box(self, Vector3(0,-0.35,0), Vector3(270,0.7,270), Color("a89572"), true)
	for axis in [-60,0,60]:
		Geo.box(self, Vector3(axis,0.01,0), Vector3(18,0.06,258), Color("c6bca7"))
		Geo.box(self, Vector3(0,0.012,axis), Vector3(258,0.06,18), Color("c6bca7"))
		Geo.box(self, Vector3(axis,0.06,0), Vector3(14,0.04,258), Color("3e4c50"))
		Geo.box(self, Vector3(0,0.065,axis), Vector3(258,0.04,14), Color("3e4c50"))
		for mark in range(-122,125,8):
			if abs(mark) < 10 or abs(abs(mark)-60) < 10:
				continue
			Geo.box(self, Vector3(axis,0.095,mark), Vector3(0.17,0.02,3), Color("eddfb3"))
			Geo.box(self, Vector3(mark,0.098,axis), Vector3(3,0.02,0.17), Color("eddfb3"))
	for id in Catalog.LOCATIONS:
		_build_location(id)
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
			Geo.cylinder(self,Vector3(x,3,z),0.09,6,Color("3b5557"))
			Geo.box(self,Vector3(x,6,z),Vector3(1.2,0.15,0.6),Color("fff0ba"))
	# Original yellow commuter minibuses and roadside stalls.
	for p in [Vector3(-5,0,38),Vector3(65,0,-34),Vector3(38,0,5)]:
		Geo.box(self,p+Vector3(0,0.9,0),Vector3(2.2,1.5,4.8),Color("e6ad33"),true)
		Geo.box(self,p+Vector3(0,1.7,0),Vector3(2.05,0.7,4.1),Color("d7b554"))
		Geo.box(self,p+Vector3(0,1.7,-2.07),Vector3(1.8,0.55,0.04),Color("294954"))
		Geo.box(self,p+Vector3(0,0.9,-2.42),Vector3(2.2,0.15,0.05),Color("252f2e"))
		for dx in [-1.12,1.12]:
			for dz in [-1.5,1.5]:
				var w = Geo.cylinder(self,p+Vector3(dx,0.45,dz),0.45,0.16,Color("202c31"))
				w.rotation.z = PI/2
	for i in 5:
		var p = Vector3(33+i*3,0,22)
		Geo.box(self,p+Vector3(0,0.8,0),Vector3(2.4,1.3,1.5),Color("946f45"),true)
		Geo.box(self,p+Vector3(0,2.5,0),Vector3(2.8,0.18,2.2),Color("c85f45") if i%2 else Color("d3b957"))
		for j in 3:
			Geo.cylinder(self,p+Vector3(-0.7+j*0.6,1.6,0),0.25,0.35,Color("8da05b"))
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
	Geo.batch_static(self)

func _building(p: Vector3, size: Vector3, color: Color) -> void:
	Geo.box(self,p+Vector3(0,size.y/2,0),size,color,true)
	Geo.box(self,p+Vector3(0,size.y+0.15,0),Vector3(size.x+0.6,0.3,size.z+0.6),Color("6b7773"))
	Geo.box(self,p+Vector3(0,0.4,0),Vector3(size.x+0.12,0.8,size.z+0.12),color.darkened(0.22))
	for y in range(2,int(size.y),3):
		for x in [-4,0,4]:
			for facing in [-1,1]:
				Geo.box(self,p+Vector3(x,y,(size.z/2+0.03)*facing),Vector3(1.85,1.7,0.1),color.lightened(0.18))
				Geo.box(self,p+Vector3(x,y,(size.z/2+0.1)*facing),Vector3(1.55,1.4,0.05),Color("385e68"))
				Geo.box(self,p+Vector3(x,y,(size.z/2+0.15)*facing),Vector3(0.09,1.4,0.05),Color("aab5ae"))
	if size.y > 7:
		Geo.box(self,p+Vector3(size.x/2-2,size.y+0.7,2),Vector3(2,1.3,2),Color("4c666b"))

func _build_location(id: String) -> void:
	var d = Catalog.LOCATIONS[id]
	var p: Vector3 = d.pos
	var h = 5.0
	var facing = -1.0 if p.z < 0 else 1.0
	if id in ["bank","invest","mansion"]:
		h = 10.0
	_building(p+Vector3(0,0,8*facing),Vector3(15,h,12),d.color)
	Geo.box(self,p+Vector3(0,1.5,1.96*facing),Vector3(2.5,3,0.08),Color("244d50"))
	Geo.box(self,p+Vector3(0,3.7,0.8*facing),Vector3(13,0.3,3),d.color.darkened(0.22))
	Geo.label(self,d.name,p+Vector3(0,4.6,0.7*facing),30)
	var marker = Geo.cylinder(self,p+Vector3(0,0.12,0),1.1,0.08,Color("69d8bb"))
	marker.name = "Point_" + id
	if id == "mansion":
		for x in [-6,6]:
			Geo.cylinder(self,p+Vector3(x,2.5,0),0.3,5,Color("f1e8d2"))
	if id in ["work","market","bank","dealer"]:
		Geo.person(self,p+Vector3(2,0,0),d.color.darkened(0.2))

func palm(p: Vector3) -> void:
	Geo.cylinder(self,p+Vector3(0,2.6,0),0.19,5.2,Color("91714b"))
	for i in 5:
		var leaf = Geo.box(self,p+Vector3(0,5.3,0),Vector3(0.65,0.16,5),Color("4b7960"))
		leaf.rotation.y = i*TAU/5
		leaf.rotation.x = 0.2

func _build_interior(id: String, center: Vector3, size: Vector3) -> void:
	Geo.box(self,center+Vector3(0,-0.2,0),Vector3(size.x,0.4,size.z),Color("c4ad88"),true)
	Geo.box(self,center+Vector3(0,size.y+0.15,0),Vector3(size.x,0.3,size.z),Color("dfd6bd"),true)
	for sign_value in [-1,1]:
		Geo.box(self,center+Vector3(sign_value*size.x/2,size.y/2,0),Vector3(0.3,size.y,size.z),Color("e3d6b9"),true)
		Geo.box(self,center+Vector3(0,size.y/2,sign_value*size.z/2),Vector3(size.x,size.y,0.3),Color("e3d6b9"),true)
	Geo.box(self,center+Vector3(-size.x/2+2,0.45,-2),Vector3(2.6,0.9,3.8),Color("5b7d7d"),true)
	Geo.box(self,center+Vector3(-size.x/2+2,0.97,-3),Vector3(2,0.15,1),Color("fff0d3"))
	Geo.box(self,center+Vector3(2,0.65,-3),Vector3(2.5,1.3,1.3),Color("805d42"),true)
	Geo.box(self,center+Vector3(2,1.6,-3),Vector3(1.5,0.85,0.08),Color("263f48"))
	Geo.box(self,center+Vector3(0,0.025,1),Vector3(size.x*0.6,0.04,3.5),Color("a6654d"))
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
	for i in npcs.size():
		var origin: Vector3 = npcs[i].get_meta("origin")
		npcs[i].position.z = origin.z + sin(elapsed*0.2+i)*5
		npcs[i].rotation.y = 0 if cos(elapsed*0.2+i) > 0 else PI

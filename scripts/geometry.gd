class_name Geo
extends RefCounted

static var materials: Dictionary = {}

static func mat(color: Color) -> StandardMaterial3D:
	var key = color.to_html()
	if not materials.has(key):
		var m = StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.85
		materials[key] = m
	return materials[key]

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var shape = BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = mat(color)
	mesh.position = pos
	parent.add_child(mesh)
	if solid:
		var body = StaticBody3D.new()
		var collision = CollisionShape3D.new()
		var bounds = BoxShape3D.new()
		bounds.size = size
		collision.shape = bounds
		body.add_child(collision)
		mesh.add_child(body)
	return mesh

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var m = MeshInstance3D.new()
	var c = CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = 8
	m.mesh = c
	m.material_override = mat(color)
	m.position = pos
	parent.add_child(m)
	return m

static func label(parent: Node3D, text: String, pos: Vector3, size: int = 40) -> Label3D:
	var l = Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.018
	l.position = pos
	l.modulate = Color("fff3d5")
	l.outline_modulate = Color("183438")
	l.outline_size = 9
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = false
	l.visibility_range_begin = 4
	l.visibility_range_end = 100
	parent.add_child(l)
	return l

static func person(parent: Node3D, pos: Vector3, shirt: Color) -> Node3D:
	var p = EmpireActor.new()
	parent.add_child(p)
	p.position = pos
	return p

static func batch_static(parent: Node3D) -> void:
	# Normalize primitive geometry into spatially grouped MultiMeshes. Keep every
	# physics body independent; only replace visual instances to reduce draw calls.
	var groups: Dictionary = {}
	for child in parent.get_children():
		if not child is MeshInstance3D: continue
		var mesh: MeshInstance3D = child
		var unit: Mesh
		var scale_vector = Vector3.ONE
		var type_name = ""
		if mesh.mesh is BoxMesh:
			unit = BoxMesh.new()
			unit.size = Vector3.ONE
			scale_vector = mesh.mesh.size
			type_name = "box"
		elif mesh.mesh is CylinderMesh:
			unit = CylinderMesh.new()
			unit.top_radius = 1
			unit.bottom_radius = 1
			unit.height = 1
			unit.radial_segments = 8
			scale_vector = Vector3(mesh.mesh.top_radius,mesh.mesh.height,mesh.mesh.top_radius)
			type_name = "cylinder"
		else: continue
		var key = "%s_%s_%d_%d" % [type_name,mesh.material_override.albedo_color.to_html(),floori(mesh.position.x/60),floori(mesh.position.z/60)]
		if not groups.has(key):
			groups[key] = {"mesh":unit,"material":mesh.material_override,"transforms":[]}
		groups[key].transforms.append(mesh.transform*Transform3D(Basis.from_scale(scale_vector),Vector3.ZERO))
		for body in mesh.get_children():
			if body is StaticBody3D: body.reparent(parent,true)
		parent.remove_child(mesh)
		mesh.queue_free()
	for group in groups.values():
		var multi = MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = group.mesh
		multi.instance_count = group.transforms.size()
		for i in group.transforms.size(): multi.set_instance_transform(i,group.transforms[i])
		var instance = MultiMeshInstance3D.new()
		instance.multimesh = multi
		instance.material_override = group.material
		parent.add_child(instance)

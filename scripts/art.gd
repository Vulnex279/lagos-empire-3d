class_name Art
extends RefCounted
## Imported meshes are shared; simple collision never replaces the visual asset.
static var models: Dictionary = {}

static func model(parent: Node3D, path: String, pos: Vector3 = Vector3.ZERO, scale_value: float = 1.0, yaw: float = 0.0) -> Node3D:
	if not models.has(path): models[path] = load("res://assets/imported/"+path)
	var node: Node3D = models[path].instantiate()
	parent.add_child(node)
	node.position = pos
	node.scale = Vector3.ONE*scale_value
	node.rotation.y = yaw
	visibility(node)
	return node

static func visibility(node: Node) -> void:
	if node is GeometryInstance3D:
		node.visibility_range_end = 155
		node.visibility_range_end_margin = 12
	for child in node.get_children(): visibility(child)

static func collider(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var body = StaticBody3D.new()
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
	body.position = pos

static func batch_static(root: Node3D) -> void:
	var groups: Dictionary = {}
	_collect(root,root,groups)
	for data in groups.values():
		var multi = MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = data.mesh
		multi.instance_count = data.transforms.size()
		for i in data.transforms.size(): multi.set_instance_transform(i,data.transforms[i])
		var instance = MultiMeshInstance3D.new()
		instance.multimesh = multi
		instance.position = data.origin
		instance.visibility_range_end = 145
		root.add_child(instance)

static func _collect(node: Node, root: Node3D, groups: Dictionary) -> void:
	if node is EmpireActor: return
	for child in node.get_children(): _collect(child,root,groups)
	if not node is MeshInstance3D or not node.mesh is ArrayMesh: return
	var mesh_node: MeshInstance3D = node
	var cell = Vector3(floor(mesh_node.global_position.x/40)*40,0,floor(mesh_node.global_position.z/40)*40)
	var key = str(mesh_node.mesh.get_rid())+str(cell)
	if not groups.has(key): groups[key] = {"mesh":mesh_node.mesh,"origin":cell,"transforms":[]}
	var t = mesh_node.global_transform
	t.origin -= cell
	groups[key].transforms.append(t)
	mesh_node.visible = false
	# The shared imported mesh remains referenced by MultiMesh; no duplicate GPU mesh.

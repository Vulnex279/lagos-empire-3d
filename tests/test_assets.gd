extends SceneTree
var failed = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ",label)
	else: failed += 1;push_error("FAIL: "+label)
func material_textures(node: Node) -> bool:
	var good = true
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var m = node.mesh.surface_get_material(i)
			if m is StandardMaterial3D and m.resource_name == "colormap":
				good = good and m.albedo_texture != null
	for c in node.get_children(): good = material_textures(c) and good
	return good
func run() -> void:
	var actor = EmpireActor.new()
	root.add_child(actor)
	check(actor.skeleton.get_bone_count() >= 60,"Imported humanoid has a full skeletal rig")
	for clip in ["Idle","Walk","Run","Driving","Talk","Enter","Exit"]:
		check(actor.animator.has_animation(clip),"Animation available: "+clip)
	actor.locomotion(4)
	actor.animator.advance(0.4)
	var before = actor.skeleton.get_bone_pose_rotation(10)
	actor.animator.advance(0.3)
	check(before != actor.skeleton.get_bone_pose_rotation(10),"Walking animation changes skeletal pose")
	for file in ["vehicles/suv-luxury.glb","vehicles/race.glb","vehicles/sedan.glb","nature/tree_palmDetailedTall.glb","suburban/fence.glb"]:
		var model = load("res://assets/imported/"+file).instantiate()
		check(material_textures(model),"Palette textures present: "+file)
		model.free()
	actor.queue_free()
	await process_frame
	print("ASSET RESULTS: failures=",failed)
	quit(1 if failed else 0)

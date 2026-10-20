extends SceneTree
var game: Node
var camera: Camera3D

func _initialize() -> void: call_deferred("run")

func capture(title: String, eye: Vector3, target: Vector3) -> void:
	game.ui.toast_time = 0
	game.update_hud()
	camera.global_position = eye
	camera.look_at(target)
	camera.make_current()
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/upgrade-"+title+".png")
	print("SCREENSHOT ",title," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," triangles=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))

func run() -> void:
	var e = root.get_node("Economy")
	e.volatile = true
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.start_game(false)
	e.state.clock = 200
	game.world.set_time(10)
	game.ui.toast_time = 0
	game.player.position = Vector3(-10,0.2,-17)
	game.player.body.rotation.y = 0
	for i in 15: await physics_frame
	game._set_paused(true)
	game.ui.touch.visible = true
	game.ui.touch.active = true
	game.ui.touch.queue_redraw()
	camera = Camera3D.new()
	camera.fov = 62
	camera.far = 180
	game.add_child(camera)
	await capture("character",Vector3(-8,1.6,-20),Vector3(-10,1,-17))
	await capture("city",Vector3(-3,8,18),Vector3(-24,3,-25))
	e.state.cash = 8000000
	e.purchase("vehicles","suv")
	game._spawn_owned("suv",Vector3(1,0.02,-22))
	await capture("suv",Vector3(5,2.5,-28),Vector3(1,0.9,-22))
	game.owned_car.queue_free()
	game.owned_car = null
	await process_frame
	e.purchase("vehicles","sports")
	game._spawn_owned("sports",Vector3(1,0.02,-22))
	await capture("sports",Vector3(5,2.2,-28),Vector3(1,0.7,-22))
	await capture("mansion",Vector3(92,6,-66),Vector3(83,2.5,-88))
	e.purchase("properties","mansion")
	game.transition_home("mansion",true)
	game._set_paused(true)
	await capture("interior",Vector3(406,3,7),Vector3(400,1,-2))
	e.purchase("businesses","mart")
	e.advance_day()
	game.open_phone("Businesses")
	await capture("economy",Vector3(406,3,7),Vector3(400,1,-2))
	game.stop_audio()
	await create_timer(0.25).timeout
	game.queue_free()
	await process_frame
	Geo.materials.clear()
	Art.models.clear()
	quit()

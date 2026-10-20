extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
	print("Captured ",name)
	print("Render sample ",name,": draw calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))

func run() -> void:
	var economy = root.get_node("Economy")
	economy.volatile = true
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await capture("menu")
	game.start_game(false)
	game.ui.toast_time = 0
	await capture("exploration")
	game.player.position = Vector3(-10,0.2,-25)
	game.player.yaw = 0.7
	await capture("street")
	game.open_phone("Map")
	await capture("map")
	game.close_panel()
	economy.state.cash = 5000000
	economy.purchase("vehicles","suv")
	game._spawn_owned("suv",Vector3(2,0.2,28))
	game.enter_car(game.owned_car)
	game.ui.toast_time = 0
	await capture("driving")
	game.owned_car.speed = 0
	game.exit_car()
	game.transition_home("home",true)
	game.ui.toast_time = 0
	await capture("interior")
	game.queue_free()
	await process_frame
	Geo.materials.clear()
	quit()

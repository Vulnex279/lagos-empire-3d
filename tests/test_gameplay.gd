extends SceneTree

var failures = 0
var checks = 0
var game: Node
var e: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition: print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)

func frames(count: int) -> void:
	for i in count: await physics_frame

func run() -> void:
	e = root.get_node("Economy")
	e.save_path = "user://gameplay-test.json"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(2)
	check(not game.playing and game.ui.modal != null,"Main menu launches")
	game.start_game(false)
	await frames(15)
	check(game.playing and not game.paused,"New game enters 3D world")
	check(game.player.is_on_floor(),"Player grounded on collision surface")
	var before: Vector3 = game.player.position
	Input.action_press("forward")
	await frames(45)
	Input.action_release("forward")
	check(game.player.position.distance_to(before) > 2,"Walking moves character")
	game.player.look(Vector2(100,-30))
	check(game.player.yaw != 0,"Camera responds to look input")
	game.ui.touch.active = true
	var finger = InputEventScreenTouch.new()
	finger.index = 3
	finger.position = game.ui.touch.stick_center()+Vector2(0,-50)
	finger.pressed = true
	game.ui.touch._input(finger)
	check(game.ui.touch.movement.y < -0.5,"Touch joystick produces movement")
	finger.pressed = false
	game.ui.touch._input(finger)
	check(game.ui.touch.movement == Vector2.ZERO,"Joystick release clears movement")
	for app in ["Wallet","Jobs","Trade","Businesses","Properties","Vehicles","Investments","Map","Progress","Guide"]:
		game.open_phone(app)
		await frames(1)
		check(game.paused and game.ui.modal != null,"Phone screen renders: "+app)
	game.close_panel()
	game.transition_home("home",true)
	await frames(10)
	check(game.interior == "home" and game.player.position.x > 300,"Rented room interior enterable")
	game.transition_home("home",false)
	await frames(5)
	check(game.interior.is_empty() and game.player.position.x < 150,"Interior exit returns to neighbourhood")
	e.state.cash = 4000000
	check(e.purchase("properties","mansion"),"Gameplay mansion purchase")
	game.transition_home("mansion",true)
	await frames(5)
	check(game.interior == "mansion" and game.player.position.x > 380,"Mansion enterable")
	game.transition_home("mansion",false)
	game.player.position = Catalog.LOCATIONS.work.pos
	e.accept_job(3,game.player.position)
	game.player.position = game.fleet.position+Vector3(2.5,0,0)
	game.enter_car(game.fleet)
	await frames(3)
	check(game.active_car == game.fleet and not game.player.visible,"Vehicle entry transfers control")
	var car_before: Vector3 = game.fleet.position
	Input.action_press("forward")
	await frames(60)
	Input.action_release("forward")
	check(game.fleet.position.distance_to(car_before) > 2,"Vehicle acceleration moves car")
	check(game.fleet.fuel < 100,"Driving consumes fuel")
	Input.action_press("brake")
	await frames(40)
	Input.action_release("brake")
	check(absf(game.fleet.speed) < 1,"Braking stops vehicle")
	game.exit_car()
	await frames(3)
	check(game.active_car == null and game.player.visible,"Vehicle exit restores walking")
	game.player.position = Catalog.LOCATIONS.dealer.pos
	check(e.purchase("vehicles","sedan"),"Car purchase in gameplay state")
	game.retrieve_car("sedan")
	await frames(3)
	check(is_instance_valid(game.owned_car),"Garage retrieves owned car")
	game._store_car()
	check(not is_instance_valid(game.owned_car),"Garage stores car")
	check(e.purchase("vehicles","suv"),"Luxury SUV purchase")
	game.retrieve_car("suv")
	await frames(3)
	check(game.owned_car.kind == "suv","Second vehicle can be retrieved")
	game.player.position = game.owned_car.position+Vector3(2.5,0,0)
	game.enter_car(game.owned_car)
	check(game.active_car.kind == "suv","Luxury SUV is enterable")
	game.show_pause()
	var clock_before = e.state.clock
	await frames(10)
	check(e.state.clock == clock_before,"Menus pause simulation clock")
	game.capture_state()
	check(e.save_game() and e.load_game() and e.state.vehicles.has("suv") and e.state.properties.has("mansion"),"World ownership persists")
	game.queue_free()
	await frames(3)
	Geo.materials.clear()
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(e.save_path+suffix): DirAccess.remove_absolute(e.save_path+suffix)
	print("GAMEPLAY RESULTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

extends Node3D

var world: LagosWorld
var player: EmpirePlayer
var ui: EmpireUI
var fleet: EmpireVehicle
var owned_car: EmpireVehicle
var active_car: EmpireVehicle
var menu_camera: Camera3D
var playing = false
var paused = true
var current_app = "Wallet"
var current_location = ""
var autosave = 0.0
var hud_timer = 0.0
var interior = ""
var furniture: Node3D
var ambient: AudioStreamPlayer
var engine: AudioStreamPlayer
var click: AudioStreamPlayer
var nav_target = ""
var passenger: Node3D

func _ready() -> void:
	_setup_inputs()
	world = preload("res://scenes/neighbourhood.tscn").instantiate()
	add_child(world)
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector3(-25,0.2,9)
	add_child(player)
	fleet = _make_car("sedan",Vector3(-13,0.3,-24),true)
	menu_camera = Camera3D.new()
	add_child(menu_camera)
	menu_camera.position = Vector3(42,30,49)
	menu_camera.look_at(Vector3(-4,0,-12))
	menu_camera.far = 300
	ui = EmpireUI.new()
	add_child(ui)
	ui.touch.interact.connect(interact)
	ui.touch.look_motion.connect(func(d: Vector2):
		if not is_instance_valid(active_car):
			player.look(d))
	ui.phone_button.pressed.connect(func(): open_phone("Wallet"))
	ui.pause_button.pressed.connect(show_pause)
	Economy.notice.connect(_notice)
	_setup_audio()
	_load_preferences()
	show_menu()
	if "--smoke" in OS.get_cmdline_user_args():
		start_game(false)

func _setup_inputs() -> void:
	var mapping = {"forward":[KEY_W,KEY_UP],"back":[KEY_S,KEY_DOWN],"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"run":[KEY_SHIFT],"brake":[KEY_SPACE],"interact":[KEY_E],"phone":[KEY_TAB],"pause":[KEY_ESCAPE]}
	for action in mapping:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for code in mapping[action]:
			var event = InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action,event)

func _setup_audio() -> void:
	ambient = AudioStreamPlayer.new()
	engine = AudioStreamPlayer.new()
	click = AudioStreamPlayer.new()
	for p in [ambient,engine,click]:
		add_child(p)
	if ResourceLoader.exists("res://assets/city.wav"):
		ambient.stream = load("res://assets/city.wav")
		ambient.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		ambient.stream.loop_end = 22050*8
		ambient.volume_db = -24
		ambient.play()
		engine.stream = load("res://assets/engine.wav")
		engine.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		engine.stream.loop_end = 22050*2
		engine.volume_db = -16
		click.stream = load("res://assets/click.wav")
		click.volume_db = -12

func _notice(message: String) -> void:
	ui.toast(message)
	if click.stream and Economy.state.settings.audio:
		click.play()

func _make_car(kind: String, position_value: Vector3, company: bool = false) -> EmpireVehicle:
	var car: EmpireVehicle = preload("res://scenes/vehicle.tscn").instantiate()
	car.kind = kind
	car.fleet = company
	car.position = position_value
	add_child(car)
	return car

func _set_paused(value: bool) -> void:
	paused = value
	player.enabled = not value and not is_instance_valid(active_car)
	player.set_physics_process(not value)
	world.set_process(not value)
	for car in [fleet,owned_car]:
		if is_instance_valid(car):
			car.set_physics_process(not value)
	ui.touch.active = not value and playing
	ui.touch.reset()
	if value:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		engine.stop()

func show_menu() -> void:
	playing = false
	_set_paused(true)
	ui.hud.hide()
	menu_camera.current = true
	var panel = ui.show_panel("LAGOS EMPIRE 3D", "FROM ZERO TO BILLIONS  •  An original offline city life game",func(): pass)
	ui.text(panel,"Small beginnings.\nExtraordinary ambitions.",42,Color("f4dfb3"))
	ui.text(panel,"A room. ₦25,000. A city full of opportunity.\nExplore Ayo district, deliver your first parcel, own a car and build your empire.",22)
	var row = ui.row(panel)
	ui.button(row,"NEW GAME",_confirm_new)
	ui.button(row,"CONTINUE",func(): start_game(true)).disabled = not Economy.has_save()
	var row2 = ui.row(panel)
	ui.button(row2,"SETTINGS",show_settings)
	ui.button(row2,"CREDITS",show_credits)
	ui.button(row2,"EXIT",func(): get_tree().quit())
	ui.text(panel,"Offline • Landscape • Original procedural world\nWASD / arrows to move, right mouse to look, E to interact, Tab for phone.\nOn mobile: left joystick, right-side camera drag, USE and RUN buttons.",17,Color("a4bfb6"))

func _confirm_new() -> void:
	if not Economy.has_save():
		start_game(false)
		return
	var p = ui.show_panel("START A NEW STORY?","This replaces your current progress. Your previous save remains as the recovery backup until the next save.",show_menu)
	ui.button(p,"START NEW GAME",func(): start_game(false))
	ui.button(p,"KEEP MY SAVE",show_menu)

func start_game(continued: bool) -> void:
	var ok = Economy.load_game() if continued else Economy.new_game()
	if not ok:
		ui.toast(Economy.last_error)
		return
	if is_instance_valid(active_car):
		active_car.driving = false
	active_car = null
	if is_instance_valid(owned_car):
		remove_child(owned_car)
		owned_car.queue_free()
	owned_car = null
	fleet.position = Vector3(-13,0.3,-24)
	fleet.fuel = 100
	fleet.condition = 100
	var s: Dictionary = Economy.state
	player.position = Vector3(s.position[0],s.position[1]+0.1,s.position[2])
	player.velocity = Vector3.ZERO
	player.yaw = s.yaw
	player.show()
	player.collision_layer = 1
	player.collision_mask = 1
	interior = s.interior
	if not interior.is_empty():
		if not s.properties.has(interior):
			interior = ""
			player.position = Vector3(-25,0.2,9)
		else:
			_draw_furniture()
	if not s.selected_vehicle.is_empty() and s.vehicles.has(s.selected_vehicle):
		_spawn_owned(s.selected_vehicle,Vector3(15,0.3,-23))
	playing = true
	ui.hud.show()
	_load_preferences()
	close_panel()
	player.camera.current = true
	if not continued:
		ui.toast("Welcome! Walk to Oja Dispatch. The gold marker shows the way.")

func close_panel() -> void:
	ui.clear_modal()
	if playing:
		_set_paused(false)
	else:
		show_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if playing:
			if paused: close_panel()
			else: show_pause()
	elif playing and event.is_action_pressed("phone"):
		if paused: close_panel()
		else: open_phone("Wallet")
	elif playing and not paused:
		if event.is_action_pressed("interact"):
			interact()
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not is_instance_valid(active_car):
			player.look(event.relative)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and playing:
		if paused: close_panel()
		else: show_pause()
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if playing:
			capture_state()
			Economy.save_game()
		if what == NOTIFICATION_APPLICATION_PAUSED and playing:
			show_pause()

func position_now() -> Vector3:
	return active_car.global_position if is_instance_valid(active_car) else player.global_position

func capture_state() -> void:
	var pos = position_now()
	Economy.state.position = [pos.x,pos.y,pos.z]
	Economy.state.yaw = player.yaw
	Economy.state.interior = interior
	if is_instance_valid(owned_car) and Economy.state.vehicles.has(owned_car.kind):
		Economy.state.vehicles[owned_car.kind].fuel = owned_car.fuel
		Economy.state.vehicles[owned_car.kind].condition = owned_car.condition

func _process(delta: float) -> void:
	if not playing or paused:
		return
	player.move_input = ui.touch.movement
	player.running = ui.touch.running
	if is_instance_valid(active_car):
		active_car.controls = ui.touch.movement
		active_car.brake = ui.touch.braking
		if engine.stream and Economy.state.settings.audio:
			if not engine.playing: engine.play()
			engine.pitch_scale = 0.7+absf(active_car.speed)/18
	else:
		engine.stop()
	capture_state()
	Economy.tick(delta)
	world.set_time(float(Economy.state.clock)/Economy.DAY_SECONDS*24)
	autosave += delta
	if autosave > 20:
		autosave = 0
		if not Economy.save_game(): ui.toast(Economy.last_error)
	if player.position.y < -10:
		player.position = Vector3(-25,1,9)
		player.velocity = Vector3.ZERO
	hud_timer += delta
	if hud_timer > 0.12:
		hud_timer = 0
		update_hud()

func nearest_location() -> String:
	if not interior.is_empty():
		return "exit" if position_now().distance_to(world.interior_exits[interior]) < 5 else ""
	var closest = ""
	var distance = 5.5
	for id in Catalog.LOCATIONS:
		var d = position_now().distance_to(Catalog.LOCATIONS[id].pos)
		if d < distance:
			distance = d
			closest = id
	return closest

func nearest_car() -> EmpireVehicle:
	for car in [owned_car,fleet]:
		if is_instance_valid(car) and player.global_position.distance_to(car.global_position) < 4.5:
			return car
	return null

func job_at_target() -> bool:
	if Economy.state.mission.is_empty(): return false
	var job: Dictionary = Catalog.JOBS[int(Economy.state.mission.template)]
	return position_now().distance_to(Catalog.LOCATIONS[job.target].pos) < 6

func objective_location() -> String:
	if not Economy.state.mission.is_empty():
		return Catalog.JOBS[int(Economy.state.mission.template)].target
	if not nav_target.is_empty(): return nav_target
	if Economy.state.tutorial < 2: return "work"
	if Economy.state.tutorial == 2: return "dealer"
	return "mart" if not Economy.state.businesses.has("mart") else "mansion"

func update_hud() -> void:
	var s: Dictionary = Economy.state
	_update_passenger()
	ui.wallet.text = Catalog.naira(s.cash)
	var mins = int(float(s.clock)/Economy.DAY_SECONDS*1440)
	ui.clock_label.text = "DAY %d  •  %02d:%02d  •  REP %d" % [s.day,mins/60,mins%60,s.reputation]
	var dest = objective_location()
	if not s.mission.is_empty():
		ui.objective.text = "● "+Catalog.JOBS[int(s.mission.template)].name+"\n%d sec  •  %s" % [s.mission.remaining,Catalog.LOCATIONS[dest].name]
	elif s.tutorial < 2:
		ui.objective.text = "YOUR FIRST MILE\nVisit Oja Dispatch and complete a delivery."
	elif s.tutorial == 2:
		ui.objective.text = "BUILD YOUR INDEPENDENCE\nEarn ₦45,000 and buy a Kora Compact."
	else:
		ui.objective.text = "BUILD YOUR EMPIRE\nNet worth "+Catalog.naira(Economy.net_worth())
	current_location = nearest_location()
	if is_instance_valid(active_car):
		ui.prompt.text = "%d km/h  •  Fuel %d%%  •  Condition %d%%  •  Stop + E to %s" % [absf(active_car.speed)*3.6,active_car.fuel,active_car.condition,"deliver" if job_at_target() else "exit"]
	elif job_at_target():
		ui.prompt.text = "E / USE  •  Complete delivery"
	elif is_instance_valid(nearest_car()):
		ui.prompt.text = "E / USE  •  Enter "+("company car" if nearest_car().fleet else Catalog.VEHICLES[nearest_car().kind].name)
	elif current_location == "exit":
		ui.prompt.text = "E / USE  •  Home: exit, rest or furnish"
	elif not current_location.is_empty():
		ui.prompt.text = "E / USE  •  "+Catalog.LOCATIONS[current_location].name
	else:
		ui.prompt.text = "Explore the city  •  Drag right side / hold right mouse to look"
	var camera = get_viewport().get_camera_3d()
	var target: Vector3 = Catalog.LOCATIONS[dest].pos+Vector3(0,5.6,0)
	ui.waypoint.visible = interior.is_empty() and not camera.is_position_behind(target)
	if ui.waypoint.visible:
		var point = camera.unproject_position(target)
		var bounds = get_viewport().get_visible_rect().size
		ui.waypoint.position = Vector2(clampf(point.x-80,40,bounds.x-220),clampf(point.y,150,bounds.y-250))
		ui.waypoint.text = "◆  %d m\n%s" % [position_now().distance_to(target),Catalog.LOCATIONS[dest].name]

func interact() -> void:
	if not playing or paused: return
	if job_at_target():
		if is_instance_valid(active_car) and absf(active_car.speed) > 1:
			ui.toast("Stop your car to complete this job.")
			return
		Economy.complete_job(position_now(),is_instance_valid(active_car))
		return
	if is_instance_valid(active_car):
		exit_car()
		return
	var car = nearest_car()
	if is_instance_valid(car):
		enter_car(car)
		return
	var location = nearest_location()
	if not location.is_empty():
		open_location(location)
	else:
		ui.toast("Move closer to a shop entrance, vehicle or destination marker.")

func enter_car(car: EmpireVehicle) -> void:
	if car.fleet and (Economy.state.mission.is_empty() or Catalog.JOBS[int(Economy.state.mission.template)].type != "driving"):
		ui.toast("The company car is available for passenger jobs from Oja Dispatch.")
		return
	active_car = car
	car.driving = true
	player.enabled = false
	player.hide()
	player.collision_layer = 0
	player.collision_mask = 0
	car.camera.current = true
	car.camera.fov = 62
	create_tween().tween_property(car.camera,"fov",72.0,0.35)
	ui.touch.driving = true
	ui.touch.reset()
	ui.toast("Forward accelerates. Pull back to brake and reverse. Stop before exiting.")

func exit_car() -> void:
	if absf(active_car.speed) > 1:
		ui.toast("Stop the vehicle before exiting.")
		return
	# Probe both doors and rear so an exit cannot place the player inside a wall.
	var exit_position: Vector3
	var found = false
	for offset in [Vector3(2,1.3,0),Vector3(-2,1.3,0),Vector3(0,1.3,3.5)]:
		var target = active_car.global_transform*offset
		var query = PhysicsShapeQueryParameters3D.new()
		var shape = CapsuleShape3D.new()
		shape.radius = 0.4
		shape.height = 1.8
		query.shape = shape
		query.transform = Transform3D(Basis.IDENTITY,target)
		query.exclude = [active_car.get_rid(),player.get_rid()]
		if get_world_3d().direct_space_state.intersect_shape(query).is_empty():
			exit_position = target-Vector3(0,0.9,0)
			found = true
			break
	if not found:
		ui.toast("Both doors are blocked. Move to an open space.")
		return
	active_car.driving = false
	active_car = null
	player.position = exit_position
	player.velocity = Vector3.ZERO
	player.show()
	player.enabled = true
	player.collision_layer = 1
	player.collision_mask = 1
	player.camera.current = true
	ui.touch.driving = false
	ui.touch.reset()
	capture_state()
	Economy.save_game()

func _spawn_owned(id: String, point: Vector3) -> void:
	if is_instance_valid(owned_car):
		remove_child(owned_car)
		owned_car.queue_free()
	owned_car = _make_car(id,point)
	owned_car.fuel = Economy.state.vehicles[id].fuel
	owned_car.condition = Economy.state.vehicles[id].condition
	owned_car.set_physics_process(not paused)

func retrieve_car(id: String) -> void:
	if is_instance_valid(active_car):
		ui.toast("Exit your current vehicle first.")
		return
	var near = nearest_location()
	if near != "dealer" and not (near == "garage" and Economy.state.properties.has("mansion")):
		ui.toast("Retrieve vehicles at Eko Motors or your mansion garage.")
		return
	capture_state()
	Economy.state.selected_vehicle = id
	if Economy.save_game():
		_spawn_owned(id,Catalog.LOCATIONS[near].pos+Vector3(-9,0.3,-1))
		ui.toast("Vehicle retrieved. Walk over and press USE to enter.")
	else:
		ui.toast(Economy.last_error)

func open_location(id: String) -> void:
	match id:
		"work": open_phone("Jobs")
		"dealer","garage": open_phone("Vehicles")
		"bank": open_phone("Wallet")
		"invest": open_phone("Investments")
		"market","cafe": open_phone("Trade")
		"mart","logistics": open_phone("Businesses")
		"home","mansion","exit": show_home(id)
		_: open_phone("Map")

func show_home(id: String) -> void:
	_set_paused(true)
	var property_id = interior if id == "exit" else id
	var p = ui.show_panel(Catalog.PROPERTIES[property_id].name,"Home is where your next chapter begins.",close_panel)
	if id == "exit":
		ui.button(p,"GO OUTSIDE",func(): transition_home(property_id,false))
		ui.button(p,"REST UNTIL NEXT DAY • rent and expenses apply",func():
			Economy.tick(Economy.DAY_SECONDS)
			open_phone("Wallet"))
		ui.button(p,"FURNISH • "+Catalog.naira(Economy.upgrade_price("properties",property_id)),func():
			Economy.upgrade("properties",property_id)
			_draw_furniture()
			show_home("exit"))
	elif Economy.state.properties.has(property_id):
		ui.button(p,"ENTER YOUR HOME",func(): transition_home(property_id,true))
	else:
		ui.text(p,"Own a spacious residence and private garage. Price: ₦2,500,000.")
		ui.button(p,"BUY PALM COURT",func():
			Economy.purchase("properties","mansion")
			show_home("mansion"))

func transition_home(id: String, enter: bool) -> void:
	interior = id if enter else ""
	var outward = -3.0 if Catalog.LOCATIONS[id].pos.z > 0 else 3.0
	player.position = world.interior_exits[id]+Vector3(0,0.2,-2) if enter else Catalog.LOCATIONS[id].pos+Vector3(0,0.2,outward)
	player.velocity = Vector3.ZERO
	player.yaw = 0 if enter else PI
	if enter: _draw_furniture()
	capture_state()
	Economy.save_game()
	close_panel()

func _draw_furniture() -> void:
	if is_instance_valid(furniture):
		remove_child(furniture)
		furniture.queue_free()
	furniture = Node3D.new()
	add_child(furniture)
	if interior.is_empty(): return
	var center = Vector3(350,0,0) if interior == "home" else Vector3(400,0,0)
	for i in int(Economy.state.properties[interior]):
		Geo.box(furniture,center+Vector3(2,0.5,i*1.8),Vector3(1.5,1,1.2),Color("4b8e84"),true)
		Geo.cylinder(furniture,center+Vector3(3.8,0.5,i*1.8),0.3,1,Color("b98755"))

func show_pause() -> void:
	if not playing: return
	_set_paused(true)
	capture_state()
	var p = ui.show_panel("TAKE A BREATHER","The city clock pauses while menus are open.",close_panel)
	ui.button(p,"RESUME",close_panel)
	ui.button(p,"SAVE GAME",func(): ui.toast("Game saved." if Economy.save_game() else Economy.last_error))
	ui.button(p,"SETTINGS",show_settings)
	ui.button(p,"CONTROLS & GUIDE",show_guide)
	ui.button(p,"SAVE & MAIN MENU",func():
		if Economy.save_game(): show_menu()
		else: ui.toast(Economy.last_error))

func show_settings() -> void:
	_set_paused(true)
	var p = ui.show_panel("SETTINGS","Compatibility renderer • choose a preset for your device.",close_panel)
	ui.text(p,"Graphics: "+Economy.state.settings.graphics,25)
	var r = ui.row(p)
	for preset in ["Low","Medium","High"]:
		ui.button(r,preset,func():
			Economy.state.settings.graphics = preset
			apply_settings()
			_save_preferences()
			if playing: Economy.save_game()
			show_settings())
	ui.button(p,"SOUND: "+("ON" if Economy.state.settings.audio else "OFF"),func():
		Economy.state.settings.audio = not Economy.state.settings.audio
		apply_settings()
		_save_preferences()
		if playing: Economy.save_game()
		show_settings())
	ui.text(p,"Low: no sun shadows, shorter view distance.\nMedium: balanced shadows and distance.\nHigh: longer shadow and view distance.\nActual Samsung performance requires device testing.",19)

func apply_settings() -> void:
	var preset: String = Economy.state.settings.graphics
	world.sun.shadow_enabled = preset != "Low"
	world.sun.directional_shadow_max_distance = 95 if preset == "High" else 60
	var distance = 300 if preset == "High" else (150 if preset == "Low" else 220)
	player.camera.far = distance
	for car in [fleet,owned_car]:
		if is_instance_valid(car): car.camera.far = distance
	AudioServer.set_bus_mute(0,not Economy.state.settings.audio)

func show_credits() -> void:
	var p = ui.show_panel("CREDITS","An original city, an original story.",close_panel)
	ui.text(p,"LAGOS EMPIRE 3D: FROM ZERO TO BILLIONS\nBuilt with Godot 4.6.3 (MIT licence).\nAll world geometry, fictional brands, UI, gameplay and synthesized audio were created for this project.\nNo third-party models, music or proprietary game content.\nGodot's bundled fonts and dependencies retain their upstream licences.\nSee LICENSE and ASSET_LICENSES.md in the source project.",23)
	ui.button(p,"GODOT ENGINE LICENCE",func(): show_legal("GODOT_LICENSE.txt"))
	ui.button(p,"THIRD-PARTY COPYRIGHT NOTICES",func(): show_legal("GODOT_COPYRIGHT.txt"))

func show_legal(file: String) -> void:
	var p = ui.show_panel("LICENCES & ATTRIBUTION","Godot Engine and bundled dependencies",show_credits)
	ui.text(p,FileAccess.get_file_as_string("res://assets/legal/"+file),16)

func show_guide() -> void:
	var p = ui.show_panel("YOUR CITY GUIDE","Ayo district, Lagos • fictional neighbourhood",close_panel)
	ui.text(p,"Walk: WASD / arrows or left joystick. Run: Shift or RUN toggle.\nLook: hold right mouse and move, or drag on the right half of the screen.\nInteract / enter / exit: E or USE. Phone: Tab. Pause: Escape.\nDrive: forward accelerates; back brakes then reverses. Left/right steer. Space or BRAKE stops.\nCollect work at Oja Dispatch. Yellow company car serves passenger jobs.\nFollow the gold marker; stop at your destination and press USE to finish.\nBuy crates at Ayo Market and sell them at Suya Junction.\nWithdraw bank funds before purchases. Daily rent, costs and interest apply.\nA day lasts eight playing minutes. Rest advances one day.\nEmergency grants and free walking deliveries provide a recovery path.\nThe mansion includes a private garage. Eko Motors also stores your vehicles.",20)

func action(parent: Node, title: String, callback: Callable) -> void:
	ui.button(parent,title,func():
		callback.call()
		open_phone(current_app))

func open_phone(app: String) -> void:
	if not playing: return
	capture_state()
	_set_paused(true)
	current_app = app
	var p = ui.show_panel("EKO PHONE  /  "+app.to_upper(),Catalog.naira(Economy.state.cash)+" wallet  •  "+Catalog.naira(Economy.net_worth())+" net worth",close_panel)
	var tabs = GridContainer.new()
	tabs.columns = 5
	p.add_child(tabs)
	for tab in ["Wallet","Jobs","Trade","Businesses","Properties","Vehicles","Investments","Map","Progress","Guide"]:
		ui.button(tabs,tab,func(): open_phone(tab))
	var s: Dictionary = Economy.state
	match app:
		"Wallet":
			ui.text(p,"CASH  %s     BANK  %s\nDEBT  %s     NET WORTH  %s" % [Catalog.naira(s.cash),Catalog.naira(s.bank),Catalog.naira(s.debt),Catalog.naira(Economy.net_worth())],24)
			ui.text(p,"Lifetime income %s  •  Cash outflows %s\n%s" % [Catalog.naira(s.income),Catalog.naira(s.expenses),s.event],18)
			var r = ui.row(p)
			action(r,"Deposit ₦5,000",func(): Economy.transfer(5000,true))
			action(r,"Withdraw ₦5,000",func(): Economy.transfer(5000,false))
			action(r,"Withdraw all",func(): Economy.transfer(int(s.bank),false))
			action(r,"Deposit all",func(): Economy.transfer(int(s.cash),true))
			var r2 = ui.row(p)
			action(r2,"Borrow ₦25,000 • 2% daily",func(): Economy.borrow(25000))
			action(r2,"Repay up to ₦25,000",func(): Economy.repay(mini(25000,int(s.cash))))
			action(r2,"Repay all affordable",func(): Economy.repay(int(s.cash)))
			action(p,"Community recovery grant • eligibility checked",func(): Economy.recover())
			ui.text(p,"Daily rent: ₦1,200 until you own the mansion. Weekly bank yield: 0.5%. Unpaid bills become debt.",17)
			for line in s.ledger.slice(0,8): ui.text(p,str(line),16)
		"Jobs":
			if not s.mission.is_empty():
				ui.text(p,"ACTIVE: "+Catalog.JOBS[int(s.mission.template)].name+" • %d sec remaining" % s.mission.remaining,23)
				action(p,"Cancel active job",func(): Economy.cancel_job())
			ui.text(p,"Visit Oja Dispatch to collect work. Passenger jobs include use of the yellow company car.",18)
			for i in Catalog.JOBS.size():
				var job: Dictionary = Catalog.JOBS[i]
				action(p,"%s   •   %s   •   %d sec" % [job.name,Catalog.naira(job.pay),job.seconds],func(): _accept_job(i))
		"Trade":
			ui.text(p,"Cargo: %d / 20 crates\nBuy wholesale at Ayo Market: ₦700/crate.\nSell to Suya Junction: %s/crate today." % [s.goods,Catalog.naira(int(1100*s.demand))],23)
			var r = ui.row(p)
			action(r,"Buy 5 crates",func(): Economy.trade(true,5,nearest_location()))
			action(r,"Sell 5 crates",func(): Economy.trade(false,5,nearest_location()))
			action(r,"Sell all crates",func(): Economy.trade(false,int(s.goods),nearest_location()))
			ui.text(p,"Travel between the market and café to earn a margin. Daily demand changes your selling price.",18)
		"Businesses":
			for id in Catalog.BUSINESSES:
				var b: Dictionary = Catalog.BUSINESSES[id]
				var level = int(s.businesses.get(id,0))
				ui.text(p,b.name+"  •  "+("Level %d" % level if level else "Not owned"),25,Color("edc580"))
				if level:
					var scale = pow(2.1,level-1)
					ui.text(p,"Today's gross %s / day • operating costs %s / day" % [Catalog.naira(int(b.revenue*scale*s.demand)),Catalog.naira(int(b.cost*scale))],18)
					var r = ui.row(p)
					action(r,"Upgrade • "+Catalog.naira(Economy.upgrade_price("businesses",id)),func(): Economy.upgrade("businesses",id))
					action(r,"Sell • "+Catalog.naira(Economy.asset_value("businesses",id)),func(): Economy.sell_asset("businesses",id))
				else:
					ui.text(p,"Base gross %s/day • costs %s/day" % [Catalog.naira(b.revenue),Catalog.naira(b.cost)],18)
					action(p,"Buy • "+Catalog.naira(b.price),func(): Economy.purchase("businesses",id))
		"Properties":
			for id in Catalog.PROPERTIES:
				ui.text(p,Catalog.PROPERTIES[id].name,25,Color("edc580"))
				if s.properties.has(id):
					ui.text(p,"Furnishing level %d / 3" % s.properties[id],18)
					action(p,"Upgrade furnishings • "+Catalog.naira(Economy.upgrade_price("properties",id)),func():
						Economy.upgrade("properties",id)
						if not interior.is_empty(): _draw_furniture())
					if id != "home":
						action(p,"Sell residence • "+Catalog.naira(Economy.asset_value("properties",id)),func():
							if interior == id:
								ui.toast("Leave the residence before selling it.")
							else: Economy.sell_asset("properties",id))
				else:
					action(p,"Buy residence • "+Catalog.naira(Catalog.PROPERTIES[id].price),func(): Economy.purchase("properties",id))
			ui.text(p,"Enter through the marked front doors. Furnishings appear inside. Mansion ownership replaces room rent.",18)
		"Vehicles":
			ui.text(p,"Retrieve and store at Eko Motors or your mansion garage. Fuel and repairs are serviced at Eko Motors.",18)
			for id in Catalog.VEHICLES:
				var v: Dictionary = Catalog.VEHICLES[id]
				ui.text(p,v.name,25,Color("edc580"))
				if s.vehicles.has(id):
					ui.text(p,"Fuel %d%% • condition %d%%" % [s.vehicles[id].fuel,s.vehicles[id].condition],18)
					var r = ui.row(p)
					action(r,"Retrieve",func(): retrieve_car(id))
					action(r,"Refuel",func(): _service_car(id,true))
					action(r,"Repair",func(): _service_car(id,false))
					action(r,"Sell • "+Catalog.naira(Economy.asset_value("vehicles",id)),func(): _sell_car(id))
				else:
					action(p,"Buy • "+Catalog.naira(v.price),func():
						if nearest_location() != "dealer": ui.toast("Visit Eko Motors to buy a vehicle.")
						elif Economy.purchase("vehicles",id): retrieve_car(id))
			action(p,"Store active vehicle in garage",_store_car)
		"Investments":
			ui.text(p,"Fictional market • daily price changes • 1% fee per order\nPrices reflect bounded volatility and mean reversion. Investments can lose value.",18)
			for id in Catalog.STOCKS:
				ui.text(p,"%s (%s)  •  %s  •  %d shares" % [Catalog.STOCKS[id].name,id,Catalog.naira(s.prices[id]),s.shares.get(id,0)],23)
				var r = ui.row(p)
				action(r,"Buy 1",func(): Economy.stock(id,1,true))
				action(r,"Buy 10",func(): Economy.stock(id,10,true))
				action(r,"Sell 1",func(): Economy.stock(id,1,false))
				action(r,"Sell 10",func(): Economy.stock(id,10,false))
		"Map":
			var map = DistrictMap.new()
			map.player_position = position_now()
			map.destination = objective_location()
			map.custom_minimum_size = Vector2(600,380)
			p.add_child(map)
			for id in Catalog.LOCATIONS:
				ui.button(p,"Navigate to "+Catalog.LOCATIONS[id].name,func():
					nav_target = id
					close_panel())
		"Progress":
			ui.text(p,"REPUTATION %d  •  JOBS COMPLETED %d\nNET WORTH %s" % [s.reputation,s.completed,Catalog.naira(Economy.net_worth())],25)
			ui.text(p,"Intro quest: "+("COMPLETE • you own your first car" if s.tutorial >= 3 else "Collect work → complete delivery → earn ₦45,000 → buy a Kora Compact."),20)
			for target in [100000,1000000,10000000,100000000,1000000000]:
				ui.text(p,("ACHIEVED  " if s.achievements.has(str(target)) else "GOAL  ")+Catalog.naira(target)+" net worth • 1% cash reward",20)
		"Guide":
			show_guide()

func _service_car(id: String, refuel: bool) -> void:
	if nearest_location() != "dealer":
		ui.toast("Vehicle service is available at Eko Motors.")
		return
	if Economy.service(id,refuel) and is_instance_valid(owned_car) and owned_car.kind == id:
		owned_car.fuel = Economy.state.vehicles[id].fuel
		owned_car.condition = Economy.state.vehicles[id].condition

func _sell_car(id: String) -> void:
	if is_instance_valid(active_car):
		ui.toast("Exit the car before selling a vehicle.")
		return
	if Economy.sell_asset("vehicles",id) and is_instance_valid(owned_car) and owned_car.kind == id:
		remove_child(owned_car)
		owned_car.queue_free()
		owned_car = null

func _store_car() -> void:
	if is_instance_valid(active_car):
		ui.toast("Exit your vehicle before storing it.")
		return
	var near = nearest_location()
	if near != "dealer" and not (near == "garage" and Economy.state.properties.has("mansion")):
		ui.toast("Visit Eko Motors or your mansion garage.")
		return
	capture_state()
	Economy.state.selected_vehicle = ""
	if Economy.save_game() and is_instance_valid(owned_car):
		remove_child(owned_car)
		owned_car.queue_free()
		owned_car = null
		ui.toast("Vehicle stored. Retrieve it here whenever you need it.")

func _accept_job(index: int) -> void:
	if Economy.accept_job(index,position_now()) and Catalog.JOBS[index].type == "driving":
		fleet.fuel = 100
		fleet.condition = 100
		if active_car != fleet:
			fleet.position = Vector3(-13,0.3,-24)
			fleet.speed = 0
			fleet.velocity = Vector3.ZERO

func _update_passenger() -> void:
	var needed = is_instance_valid(active_car) and not Economy.state.mission.is_empty() and Catalog.JOBS[int(Economy.state.mission.template)].type == "driving"
	if needed and not is_instance_valid(passenger):
		passenger = Geo.person(active_car,Vector3(0.4,0.3,0.1),Color("c46c5c"))
		passenger.scale = Vector3(0.7,0.7,0.7)
	elif not needed and is_instance_valid(passenger):
		passenger.get_parent().remove_child(passenger)
		passenger.queue_free()
		passenger = null

func _load_preferences() -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var graphics = config.get_value("settings","graphics","Medium")
		if graphics in ["Low","Medium","High"]: Economy.state.settings.graphics = graphics
		Economy.state.settings.audio = bool(config.get_value("settings","audio",true))
	apply_settings()

func _save_preferences() -> void:
	var config = ConfigFile.new()
	config.set_value("settings","graphics",Economy.state.settings.graphics)
	config.set_value("settings","audio",Economy.state.settings.audio)
	if config.save("user://settings.cfg") != OK: ui.toast("Could not save settings.")

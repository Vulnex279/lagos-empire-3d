class_name TouchControls
extends Control

signal interact
signal phone
signal look_motion(delta: Vector2)
var movement = Vector2.ZERO
var running = false
var braking = false
var active = false
var driving = false
var stick_id = -1
var look_id = -1
var brake_id = -1
var knob = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func reset() -> void:
	movement = Vector2.ZERO
	knob = Vector2.ZERO
	stick_id = -1
	look_id = -1
	brake_id = -1
	braking = false
	queue_redraw()

func stick_center() -> Vector2:
	return Vector2(130,size.y-125)

func _input(event: InputEvent) -> void:
	if not active:
		return
	var action_center = Vector2(size.x-100,size.y-135)
	var run_center = Vector2(size.x-235,size.y-105)
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(stick_center()) < 110 and stick_id == -1:
				stick_id = event.index
				_update_stick(event.position)
			elif event.position.distance_to(action_center) < 52:
				interact.emit()
			elif event.position.distance_to(run_center) < 44:
				if driving:
					brake_id = event.index
					braking = true
				else:
					running = not running
			elif event.position.x > size.x*0.4 and event.position.y > 160 and look_id == -1:
				look_id = event.index
		else:
			if event.index == stick_id:
				stick_id = -1
				movement = Vector2.ZERO
				knob = Vector2.ZERO
			if event.index == look_id:
				look_id = -1
			if event.index == brake_id:
				brake_id = -1
				braking = false
		queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == stick_id:
			_update_stick(event.position)
		elif event.index == look_id:
			look_motion.emit(event.relative)

func _update_stick(p: Vector2) -> void:
	knob = (p-stick_center()).limit_length(65)
	movement = knob/65
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	var font = ThemeDB.fallback_font
	draw_circle(stick_center(),83,Color(0.06,0.16,0.18,0.54))
	draw_arc(stick_center(),83,0,TAU,48,Color(0.72,0.87,0.81,0.5),2,true)
	draw_circle(stick_center()+knob,32,Color(0.62,0.88,0.77,0.65))
	var center = Vector2(size.x-100,size.y-135)
	draw_circle(center,52,Color("ddb16a"))
	draw_string(font,center+Vector2(-35,5),"USE / E",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("183538"))
	center = Vector2(size.x-235,size.y-105)
	draw_circle(center,44,Color("416f70") if running or braking else Color(0.07,0.19,0.22,0.75))
	draw_string(font,center+Vector2(-29,5),"BRAKE" if driving else "RUN",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("f5e9ce"))

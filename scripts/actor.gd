class_name EmpireActor
extends Node3D
## One imported skinned actor and an explicit animation state machine.
const MODEL = preload("res://assets/imported/characters/ayo.glb")
var visual: Node3D
var animator: AnimationPlayer
var skeleton: Skeleton3D
var animation_state = ""
var active = true

func _ready() -> void:
	visual = MODEL.instantiate()
	visual.rotation.y = PI
	add_child(visual)
	_find_rig(visual)
	assert(animator != null and skeleton != null,"Imported humanoid must contain a skeleton and animation player")
	for name in ["Idle","Walk","Run","Talk","Driving"]:
		if animator.has_animation(name): animator.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	play_state("Idle")

func _find_rig(node: Node) -> void:
	if node is AnimationPlayer: animator = node
	if node is Skeleton3D: skeleton = node
	if node is GeometryInstance3D:
		node.visibility_range_end = 90
	for child in node.get_children(): _find_rig(child)

func play_state(next: String) -> void:
	if next == animation_state or not is_instance_valid(animator): return
	if animator.has_animation(next):
		animation_state = next
		animator.play(next,0.18)

func locomotion(speed: float) -> void:
	play_state("Run" if speed > 5.8 else ("Walk" if speed > 0.3 else "Idle"))
	if is_instance_valid(animator):
		animator.speed_scale = clampf(speed/(7.2 if speed > 5.8 else 3.5),0.8,1.45) if speed > 0.3 else 1.0

func set_active(value: bool) -> void:
	active = value
	visible = value
	if is_instance_valid(animator): animator.active = value

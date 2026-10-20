class_name EmpireUI
extends CanvasLayer

var root: Control
var hud: Control
var modal: Control
var content: VBoxContainer
var touch: TouchControls
var wallet: Label
var objective: Label
var prompt: Label
var clock_label: Label
var toast_label: Label
var waypoint: Label
var toast_time = 0.0
var phone_button: Button
var pause_button: Button

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme = Theme.new()
	theme.default_font_size = 20
	var style = StyleBoxFlat.new()
	style.bg_color = Color("264e53")
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	theme.set_stylebox("normal","Button",style)
	var hover = style.duplicate()
	hover.bg_color = Color("39706d")
	theme.set_stylebox("hover","Button",hover)
	var pressed = style.duplicate()
	pressed.bg_color = Color("8c713f")
	theme.set_stylebox("pressed","Button",pressed)
	theme.set_color("font_color","Button",Color("f8eed7"))
	theme.set_color("font_color","Label",Color("f8eed7"))
	root.theme = theme
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var top = PanelContainer.new()
	top.position = Vector2(24,20)
	top.size = Vector2(330,106)
	top.add_theme_stylebox_override("panel",panel_style(Color(0.05,0.15,0.18,0.91)))
	hud.add_child(top)
	var column = VBoxContainer.new()
	top.add_child(column)
	wallet = text(column,"₦25,000",30,Color("edc580"))
	clock_label = text(column,"DAY 1   •   08:00",17)
	objective = Label.new()
	objective.position = Vector2(378,26)
	objective.size = Vector2(510,100)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.add_theme_font_size_override("font_size",21)
	objective.add_theme_color_override("font_shadow_color",Color("132e32"))
	objective.add_theme_constant_override("shadow_offset_x",2)
	objective.add_theme_constant_override("shadow_offset_y",2)
	hud.add_child(objective)
	phone_button = Button.new()
	phone_button.text = "PHONE  /  TAB"
	phone_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	phone_button.position = Vector2(-242,24)
	phone_button.size = Vector2(200,54)
	hud.add_child(phone_button)
	pause_button = Button.new()
	pause_button.text = "PAUSE"
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_button.position = Vector2(-154,88)
	pause_button.size = Vector2(112,45)
	hud.add_child(pause_button)
	prompt = Label.new()
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.position = Vector2(-350,-60)
	prompt.size = Vector2(700,40)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_shadow_color",Color("102d34"))
	prompt.add_theme_constant_override("shadow_offset_y",2)
	hud.add_child(prompt)
	waypoint = Label.new()
	waypoint.add_theme_color_override("font_color",Color("ffe29b"))
	waypoint.add_theme_color_override("font_shadow_color",Color("183438"))
	waypoint.add_theme_constant_override("shadow_offset_y",2)
	waypoint.add_theme_font_size_override("font_size",20)
	hud.add_child(waypoint)
	touch = TouchControls.new()
	hud.add_child(touch)
	toast_label = Label.new()
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	toast_label.position = Vector2(-420,100)
	toast_label.size = Vector2(840,70)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.add_theme_color_override("font_color",Color("ffe2a3"))
	toast_label.add_theme_color_override("font_shadow_color",Color("102d34"))
	toast_label.add_theme_constant_override("shadow_offset_y",2)
	root.add_child(toast_label)

func panel_style(color: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 18
	s.corner_radius_top_right = 18
	s.corner_radius_bottom_left = 18
	s.corner_radius_bottom_right = 18
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 18
	s.content_margin_bottom = 18
	return s

func text(parent: Node, value: String, size: int = 20, color: Color = Color("e4ebdf")) -> Label:
	var l = Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func button(parent: Node, title: String, action: Callable) -> Button:
	var b = Button.new()
	b.text = title
	b.custom_minimum_size.y = 50
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func row(parent: Node) -> HBoxContainer:
	var r = HBoxContainer.new()
	r.add_theme_constant_override("separation",12)
	parent.add_child(r)
	return r

func clear_modal() -> void:
	if is_instance_valid(modal):
		root.remove_child(modal)
		modal.queue_free()
	modal = null

func show_panel(title: String, subtitle: String, close_action: Callable) -> VBoxContainer:
	clear_modal()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	var dim = ColorRect.new()
	dim.color = Color(0.02,0.08,0.10,0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(dim)
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 120
	panel.offset_right = -120
	panel.offset_top = 40
	panel.offset_bottom = -40
	panel.add_theme_stylebox_override("panel",panel_style(Color(0.055,0.15,0.18,0.98)))
	modal.add_child(panel)
	var base = VBoxContainer.new()
	base.add_theme_constant_override("separation",12)
	panel.add_child(base)
	var header = row(base)
	var heading = text(header,title,30,Color("edc580"))
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button(header,"CLOSE  ×",close_action).size_flags_horizontal = Control.SIZE_SHRINK_END
	text(base,subtitle,17,Color("a8c2bb"))
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	base.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",12)
	scroll.add_child(content)
	# Notifications remain readable over every modal.
	root.move_child(toast_label,-1)
	modal.modulate.a = 0
	create_tween().tween_property(modal,"modulate:a",1.0,0.15)
	return content

func toast(message: String) -> void:
	toast_label.text = message
	toast_time = 5.5
	toast_label.show()

func _process(delta: float) -> void:
	toast_time = maxf(0,toast_time-delta)
	toast_label.visible = toast_time > 0

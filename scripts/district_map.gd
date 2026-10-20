class_name DistrictMap
extends Control

var player_position = Vector3.ZERO
var destination = "work"

func point(p: Vector3) -> Vector2:
	return Vector2(size.x/2+p.x*1.28,size.y/2+p.z*1.28)

func _draw() -> void:
	draw_style_box(_background(),Rect2(Vector2.ZERO,size))
	for axis in [-60,0,60]:
		draw_line(point(Vector3(axis,0,-130)),point(Vector3(axis,0,130)),Color("4b6868"),16)
		draw_line(point(Vector3(-130,0,axis)),point(Vector3(130,0,axis)),Color("4b6868"),16)
	for id in Catalog.LOCATIONS:
		var d: Dictionary = Catalog.LOCATIONS[id]
		var pos = point(d.pos)
		draw_circle(pos,7,Color("edc580") if id == destination else Color("69b7a3"))
		draw_string(ThemeDB.fallback_font,pos+Vector2(10,4),id.capitalize(),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("e7e9d4"))
	var player_point = point(player_position)
	if player_position.x < 150:
		draw_circle(player_point,8,Color("ffffff"))
		draw_arc(player_point,12,0,TAU,24,Color("71e7bf"),2)
		draw_string(ThemeDB.fallback_font,player_point+Vector2(14,-10),"YOU",HORIZONTAL_ALIGNMENT_LEFT,-1,15)
	draw_string(ThemeDB.fallback_font,Vector2(16,26),"AYO DISTRICT  /  N ↑",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("edc580"))

func _background() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("153c43")
	return style

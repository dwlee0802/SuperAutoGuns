@tool
extends Control
class_name RadialMenu

## The number of segments the circle is divided into.
@export var option_count: int = 4
@export var snap: bool = false
@export var press_only_inside: bool = false

@export var ring: bool = true
@export var thickness: float = 20.0

@export var bg_color: Color = Color.DARK_GRAY
@export var cursor_color: Color = Color.WHITE
@export_range(0.01, 2)  var cursor_size_multiplier: float = 1

## Offset of starting angle. Up is zero and goes clockwise.
@export var starting_point_angle: float = 0

@export var polygon_pt_count: int = 32

signal pressed(index)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _process(_delta: float) -> void:
	queue_redraw()
	

func _draw() -> void:
	var radius = get_radius()
	var cursor_angle = get_cursor_angle()
	var mouse_angle = get_mouse_angle()
	var center: Vector2 = get_center()
	
	if ring:
		draw_ring_arc(center, radius, radius-thickness, 0.0, TAU, bg_color)
		draw_ring_arc(center, radius, radius-thickness, mouse_angle - cursor_angle / 2, mouse_angle + cursor_angle / 2, cursor_color)
	else:
		draw_circle_arc(center, radius, 0.0, TAU, bg_color)
		draw_circle_arc(center, radius, 0.0, cursor_angle, cursor_color)
	
	place_children()
	

func _input(event):
	if visible:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if !press_only_inside:
					#print(get_option(get_mouse_angle()))
					pressed.emit(get_option(get_mouse_angle()))
				else:
					if is_mouse_inside():
						#print(get_option(get_mouse_angle()))
						pressed.emit(get_option(get_mouse_angle()))
	
	
# fit circle to smaller of width & height
func get_radius():
	return min(size.x, size.y) / 2
	

func get_cursor_angle():
	return TAU / option_count * cursor_size_multiplier

	
func get_mouse_angle():
	var angle: float = get_center().angle_to_point(get_local_mouse_position()) + PI/2
	if snap:
		return snappedf(angle, TAU / option_count)
		
	return angle
	

func is_mouse_inside() -> bool:
	var dist_from_center = abs(get_center().distance_to(get_local_mouse_position()))
	if dist_from_center < get_radius():
		if ring:
			if dist_from_center < get_radius() - thickness:
				return false
		
		return true
	
	return false
		
	
func get_option(angle: float) -> int:
	if angle < 0:
		angle = angle + TAU
		
	return int(snappedf(angle, TAU / option_count) / (TAU / option_count))

	
func get_center():
	return size/2

func get_center_position():
	return global_position + get_center()

# set self's position to pos
func set_center_position(pos):
	global_position = pos - size/2
	
	
func draw_circle_arc(center: Vector2, radius: float, angle_from: float,\
		angle_to: float, color: Color) -> void:
	var points_arc := PackedVector2Array()
	points_arc.push_back(center)
	var colors := PackedColorArray([color])
	var a: float = angle_from - (PI / 2.0)
	var b: float = (angle_to - angle_from) / float(polygon_pt_count)
	for i in range(polygon_pt_count + 1):
		var angle_point: float = a + float(i) * b
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	draw_polygon(points_arc, colors)


func draw_ring_arc(center: Vector2, radius1: float, radius2: float,\
		angle_from: float, angle_to: float, color: Color) -> void:
	var points_arc := PackedVector2Array()
	var colors := PackedColorArray([color])
	var a: float = angle_from - (PI / 2.0)
	var b: float = (angle_to - angle_from) / float(polygon_pt_count)
	for i in range(polygon_pt_count + 1):
		var angle_point: float = a + float(i) * b
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius1)
	for i in range(polygon_pt_count, -1, -1):
		var angle_point: float = a + float(i) * b
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius2)
	draw_polygon(points_arc, colors)


func place_children():
	var children = []
	for child in get_children():
		if child.visible:
			children.append(child)
			
	var dist_from_center = get_radius() - thickness / 2
	
	for i in range(option_count):
		var current_angle = i * TAU / option_count
		children[i].position = get_center() + Vector2.UP.rotated(current_angle) * dist_from_center - children[i].size/2

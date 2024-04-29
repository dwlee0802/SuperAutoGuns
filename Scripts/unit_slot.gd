extends Control
class_name UnitSlot

var coords = null

var canBeDropped: bool = true

signal dropped


func SetCanBeDropped(value):
	canBeDropped = value
	
	if canBeDropped:
		get_node("TextureRect").self_modulate = Color(0.46,0.46,0.46,1)
	else:
		get_node("TextureRect").self_modulate = Color(0.3,0.3,0.3,1)
	
	
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is UnitCard and canBeDropped:
		return true
		
	return false


# make unit card into self's child
func _drop_data(_at_position, data):
	data.get_parent().remove_child(data)
	add_child(data)
	data.reparent(self)
	data.position = Vector2.ZERO
	data.unit.coords = coords
	data.UpdateDebugLabel()
	dropped.emit()


func _gui_input(event):
	if event is InputEventMouse:
		if UnitCard.selected != null and Input.is_action_just_pressed("right_click"):
			# check if merging is available: same type
			_drop_data(Vector2.ZERO, UnitCard.selected)

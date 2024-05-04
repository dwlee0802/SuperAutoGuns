extends HFlowContainer
class_name ReserveContainer

signal dropped

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is UnitCard:
		return true
		
	return false


# make unit card into self's child
func _drop_data(_at_position, data):
	data.reparent(self)
	
	# new unit dropped into reserve
	dropped.emit()
	
	
func _gui_input(event):
	if event is InputEventMouse:
		if UnitCard.selected != null and Input.is_action_just_pressed("right_click"):
			# check if merging is available: same type
			_drop_data(Vector2.ZERO, UnitCard.selected)

extends HBoxContainer
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

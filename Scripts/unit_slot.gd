extends Control
class_name UnitSlot

signal dropped


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is UnitCard:
		return true
		
	return false


# make unit card into self's child
func _drop_data(_at_position, data):
	data.get_parent().remove_child(data)
	add_child(data)
	data.reparent(self)
	data.position = Vector2.ZERO
	dropped.emit()

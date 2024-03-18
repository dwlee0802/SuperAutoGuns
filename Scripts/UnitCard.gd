extends Control
class_name UnitCard

var unit: Unit


func SetUnit(_unit: Unit):
	unit = _unit
	$Name.text = unit.data.name


func _get_drag_data(_at_position: Vector2) -> Variant:
	set_drag_preview(make_drag_preview())
	return self
	

func make_drag_preview() -> TextureRect:
	var newT = TextureRect.new()
	newT.size = Vector2(64,64)
	return newT

extends Control
class_name UnitCard

var unit: Unit

@onready var attackLine: Line2D = $AttackLine


func SetUnit(_unit: Unit):
	unit = _unit
	$Name.text = unit.data.name
	UpdateHealthLabel()
	unit.received_hit.connect(UpdateHealthLabel)
	unit.unit_dead.connect(queue_free)


func _get_drag_data(_at_position: Vector2) -> Variant:
	set_drag_preview(make_drag_preview())
	return self
	

func make_drag_preview() -> TextureRect:
	var newT = TextureRect.new()
	newT.size = Vector2(64,64)
	return newT


func UpdateHealthLabel():
	$HealthPointsLabel.text = "HP: " + str(unit.currentHealthPoints)


func SetAttackLine(pos):
	attackLine.set_point_position(1, pos)

extends Control
class_name UnitCard

var unit: Unit

@onready var attackLine: Line2D = $AttackLine

var damagePopupScene = load("res://Scenes/damage_popup.tscn")


func SetUnit(_unit: Unit):
	unit = _unit
	$Name.text = unit.data.name
	UpdateHealthLabel()
	UpdateMovementLabel()
	UpdateAttackLabel()
	unit.received_hit.connect(MakeDamagePopup)
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


func MakeDamagePopup(amount):
	if amount == 0:
		return
		
	var newPopup = damagePopupScene.instantiate()
	newPopup.global_position = global_position
	newPopup.get_node("Label").text = str(amount)
	newPopup.get_node("AnimationPlayer").play("damage_popup_animation")
	get_tree().root.add_child(newPopup)
	
	
func UpdateMovementLabel():
	var label = $MovementLabel
	label.text = "Movement: " + str(unit.movementCyclesLeft + 1)
	if unit.movementCyclesLeft == unit.data.movementCost:
		label.visible = false
	else:
		label.visible = true
	

func UpdateAttackLabel():
	var label = $AttackLabel
	label.text = "Attack in: " + str(unit.attackCyclesLeft + 1)
	if unit.attackCyclesLeft == unit.data.attackCost:
		label.visible = false
	else:
		label.visible = true
	
		
func SetAttackLine(pos):
	attackLine.set_point_position(1, pos - global_position)
	attackLine.get_node("AnimationPlayer").play("attack_animation")

extends Control
class_name UnitCard

var unit: Unit

@onready var attackLine: Line2D = $AttackLine

var damagePopupScene = load("res://Scenes/damage_popup.tscn")


func SetUnit(_unit: Unit):
	unit = _unit
	
	# update info ui for this unit
	$TextureRect/Name.text = unit.data.name
	UpdateHealthLabel(0)
	UpdateMovementLabel()
	UpdateAttackLabel()
	
	# connect signals
	unit.received_hit.connect(UpdateHealthLabel)
	unit.received_hit.connect(MakeDamagePopup)
	unit.unit_dead.connect(queue_free)
	
	if unit.attackCyclesLeft < 0:
		$AttackAnimaitonPlayer.play("attack_animation")
		$AttackAnimaitonPlayer.animation_finished.connect(OnAttackAnimationFinished)


func _get_drag_data(_at_position: Vector2) -> Variant:
	set_drag_preview(make_drag_preview())
	return self
	

func make_drag_preview() -> TextureRect:
	var newT = TextureRect.new()
	return newT


func UpdateHealthLabel(_num):
	$TextureRect/HealthPointsLabel.text = "HP: " + str(unit.currentHealthPoints)


func MakeDamagePopup(amount):
	print("caller name: " + name)
	print("caller parent name: " + get_parent().name)
	if amount == 0:
		return
		
	var newPopup = damagePopupScene.instantiate()
	newPopup.global_position = global_position + Vector2(32, 32) + Vector2(randi_range(-10, 10), randi_range(-10, 10))
	newPopup.get_node("Label").text = str(amount)
	newPopup.get_node("AnimationPlayer").play("damage_popup_animation")
	get_tree().current_scene.add_child(newPopup)
	
	
func UpdateMovementLabel():
	var label = $TextureRect/MovementLabel
	label.text = "Movement: " + str(unit.movementCyclesLeft + 1)
	if unit.movementCyclesLeft == unit.data.movementCost or unit.movementCyclesLeft == -1:
		label.visible = false
	else:
		label.visible = true
	

func UpdateAttackLabel():
	var label = $TextureRect/AttackLabel
	label.text = "Attack in: " + str(unit.attackCyclesLeft + 1)
	if unit.attackCyclesLeft == unit.data.attackCost or unit.attackCyclesLeft == -1:
		label.visible = false
	else:
		label.visible = true
	
		
func UpdateAttackLine():
	var target = null
	if unit.isPlayer:
		target = GameManager.enemyEditor.GetUnitCardAt(unit.attackTargetCoord.x, unit.attackTargetCoord.y)
	else:
		target = GameManager.playerEditor.GetUnitCardAt(unit.attackTargetCoord.x, unit.attackTargetCoord.y)
	
	if target == null:
		return
		
	$AttackLine.set_point_position(1, target.global_position - global_position + Vector2(32,32))
	$AttackLine.get_node("AnimationPlayer").play("attack_animation")


func OnAttackAnimationFinished(animName):
	if animName == "attack_animation":
		unit.Attack()
		UpdateAttackLine()
		
		
func UnitDied():
	queue_free()

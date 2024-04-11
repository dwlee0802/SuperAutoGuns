extends Control
class_name UnitCard

var unit: Unit

@onready var attackLine: Line2D = $AttackLine

var damagePopupScene = load("res://Scenes/damage_popup.tscn")

@onready var attackAnimationPlayer: AnimationPlayer = $AttackAnimaitonPlayer

static var selected: UnitCard

static var dragging: bool = false

@onready var selectionIndicator = $TextureRect/SelectionIndicator


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
		if unit.attackTargetCoord == null:
			return
			
		attackAnimationPlayer.animation_finished.connect(OnAttackAnimationFinished)
		if unit.isPlayer:
			attackAnimationPlayer.play("attack_animation_left")
		else:
			attackAnimationPlayer.play("attack_animation_right")
			

func _get_drag_data(_at_position: Vector2) -> Variant:
	set_drag_preview(make_drag_preview())
	UnitCard.dragging = true
	return self


func make_drag_preview() -> TextureRect:
	var newT = TextureRect.new()
	return newT


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is UnitCard:
		return true
		
	return false


# swap positions
func _drop_data(_at_position, data):
	# do nothing if self
	if data == self:
		return
		
	var otherParent = data.get_parent()
	data.reparent(get_parent())
	reparent(otherParent)
	data.position = Vector2.ZERO
	position = Vector2.ZERO
	
	# export unit matrix or reserve
	if get_parent() is UnitSlot:
		get_parent().dropped.emit()
	if get_parent() is ReserveContainer:
		get_parent().dropped.emit()
	
	UnitCard.selected = null
	UnitCard.dragging = false
	
	
func UpdateHealthLabel(_num):
	$TextureRect/HealthPointsLabel.text = "HP: " + str(unit.currentHealthPoints) + "/" + str(unit.data.maxHealthPoints)


func MakeDamagePopup(amount):
	if amount == 0:
		return
		
	var newPopup = damagePopupScene.instantiate()
	newPopup.global_position = global_position + Vector2(32, 32) + Vector2(randi_range(-10, 10), randi_range(-10, 10))
	newPopup.get_node("Label").text = str(amount)
	newPopup.get_node("AnimationPlayer").play("damage_popup_animation")
	$HitAnimaitonPlayer.play("hit_animation")
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
	if animName == "attack_animation_left" or animName == "attack_animation_right":
		unit.Attack()
		UpdateAttackLine()
		
		
func UnitDied():
	queue_free()

#
#func _input(_event):
	#if UnitCard.selected == self:
		#selectionIndicator.visible = true
	#else:
		#selectionIndicator.visible = false

		#
#func _gui_input(event):
	#if event is InputEventMouse:
		#if event.button_mask == MOUSE_BUTTON_LEFT and Input.is_action_just_pressed("left_click"):
			#if UnitCard.selected == null:
				#UnitCard.selected = self
			#else:
				## already selected exists. swap positions
				#if !UnitCard.dragging:
					#_drop_data(Vector2.ZERO, UnitCard.selected)

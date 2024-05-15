extends Control
class_name UnitCard

var unit: Unit

static var attackLineScene = load("res://Scenes/attack_line_effect.tscn")

var damagePopupScene = load("res://Scenes/damage_popup.tscn")

@onready var attackAnimationPlayer: AnimationPlayer = $AttackAnimaitonPlayer

static var selected: UnitCard

@onready var selectionIndicator = $TextureRect/SelectionIndicator

static var deathEffect

@onready var radialUI: RadialProgress = $RadialUI/RadialUI

@onready var radialLabel: Label = $RadialUI/RadialUI/Label

signal clicked

signal was_right_clicked(clicked_thing)

signal merged 


static func _static_init():
	deathEffect = load("res://Scenes/death_effect.tscn")
	
	
func SetUnit(_unit: Unit):
	unit = _unit
	
	$TextureRect/Sprite.self_modulate = unit.data.color
	
	# update info ui for this unit
	
	if unit.isPlayer:
		$TextureRect/Sprite/Name.text = "(P)" + unit.data.name + str(unit.stackCount)
		$TextureRect.self_modulate = GameManager.playerColor
	else:
		$TextureRect/Sprite/Name.text = "(E)" + unit.data.name + str(unit.stackCount)
		$TextureRect.self_modulate = GameManager.enemyColor
		
	UpdateHealthLabel(0)
	UpdateMovementLabel()
	UpdateAttackLabel()
	UpdateCombatStatsLabel()
	
	# UI signals
	unit.stat_changed.connect(UpdateCombatStatsLabel)
	
	$HitAnimaitonPlayer.animation_finished.connect(UpdateHealthLabel)
	
	unit.received_hit.connect(HitAnimation)
	
	unit.unit_died.connect(UnitDied)
	
	UpdateRadialUI(true)
	
	# determine if attacking this cycle
	if unit.attackCyclesLeft < 0:
		if unit.attackTargetCoord == null:
			return
			
		attackAnimationPlayer.animation_finished.connect(OnAttackAnimationFinished)
		if unit.isPlayer:
			attackAnimationPlayer.play("attack_animation_left")
		else:
			attackAnimationPlayer.play("attack_animation_right")
			
	UpdateDebugLabel()
	
	
func _get_drag_data(_at_position: Vector2) -> Variant:
	set_drag_preview(make_drag_preview())
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
	
	var temp = unit.coords
	unit.coords = data.unit.coords
	data.unit.coords = temp
	
	# export unit matrix or reserve
	if get_parent() is UnitSlot:
		get_parent().dropped.emit()
	if get_parent() is ReserveContainer:
		get_parent().dropped.emit()
	
	# swapping inside reserve container
	if !(get_parent() is ReserveContainer and data.get_parent() is ReserveContainer):
		data.position = Vector2.ZERO
		position = Vector2.ZERO
	
	UpdateDebugLabel()
	data.UpdateDebugLabel()
	
	
func UpdateHealthLabel(_num = 0):
	$TextureRect/Sprite/HealthPointsLabel.text = "HP: " + str(unit.currentHealthPoints) + "/" + str(unit.data.maxHealthPoints * unit.stackCount)
	UpdateHealthIndicator()
	

func UpdateHealthIndicator():
	var currentHealthRatio: float = float(unit.currentHealthPoints) / (unit.data.maxHealthPoints * unit.stackCount)
	$TextureRect/Sprite/HealthIndicator.anchor_bottom = 1 - currentHealthRatio
	

# plays when unit received damage
# make damage pop up
# play unit animation
func HitAnimation(amount):
	var newPopup = damagePopupScene.instantiate()
	newPopup.global_position = global_position + Vector2(32, 32) + Vector2(randi_range(-10, 10), randi_range(-10, 10))
	newPopup.get_node("Label").text = str(amount)
	newPopup.get_node("AnimationPlayer").play("damage_popup_animation")
	get_tree().current_scene.add_child(newPopup)
	
	var hitAnimPlayer: AnimationPlayer = $HitAnimaitonPlayer
	hitAnimPlayer.play("hit_animation")

	
func UpdateMovementLabel():
	var label = $TextureRect/MovementLabel
	label.text = "Movement: " + str(unit.movementCyclesLeft + 1)
	if unit.movementCyclesLeft == unit.data.movementCost:
		label.visible = false
	else:
		#label.visible = true
		if unit.movementCyclesLeft < 0:
			label.text = "Ready"
			label.text += "(" + str(unit.movementCyclesLeft + 1) + ")"
			
	
func UpdateAttackLabel():
	var label = $TextureRect/AttackLabel
	label.text = "Attack in: " + str(unit.attackCyclesLeft + 1)
	if unit.attackCyclesLeft == unit.data.attackCost or unit.attackCyclesLeft == -1:
		label.visible = false
	#else:
		#label.visible = true
	

func _process(_delta):
	UpdateRadialUI()
	
	
func UpdateRadialUI(first: bool = false):
	if radialUI == null:
		return
		
	radialUI.visible = true
	
	# how much is finished in the process
	var ratio : float = 0
	
	if unit.movementCyclesLeft < unit.data.movementCost:
		radialUI.bar_color = Color.SKY_BLUE
		ratio = 1 - (unit.movementCyclesLeft + 1) / float(unit.data.movementCost)
		if first:
			ratio = 1 - (unit.movementCyclesLeft + 2) / float(unit.data.movementCost)
		ratio += BattleSpeedUI.currentCycleRatio * (1.0 / unit.data.movementCost)
		radialUI.visible = true
		
		# update label
		if unit.movementCyclesLeft + 1 <= 0:
			radialLabel.text = "0"
		else:
			radialLabel.text = str(unit.movementCyclesLeft + 1)
	
	elif unit.attackCyclesLeft < unit.data.attackCost:
		radialUI.bar_color = Color.RED
		ratio = 1 - (unit.attackCyclesLeft + 1) / float(unit.data.attackCost)
		if first:
			ratio = 1 - (unit.attackCyclesLeft + 2) / float(unit.data.attackCost)
		ratio += BattleSpeedUI.currentCycleRatio * (1.0 / unit.data.attackCost)
		radialUI.visible = true
		
		# update label
		if unit.attackCyclesLeft + 1 <= 0:
			radialLabel.text = "0"
		else:
			radialLabel.text = str(unit.attackCyclesLeft + 1)
	else:
		radialUI.visible = false
	
	if ratio < 0:
		ratio = 0
	if ratio > 1:
		ratio = 1
		
	radialUI.progress = 100 * ratio
		
	
func UpdateCombatStatsLabel():
	var label = $TextureRect/Sprite/CombatStats/AttackLabel
	var text = "ATK: {atk}"
	var atk = unit.GetAttackDamage()
	
	label.text = text.format({"atk": atk})
	
	
func UpdateAttackLine(isFlanking: bool = false):
	var attackLineColor = Color.RED
	if isFlanking:
		attackLineColor = Color.DARK_GOLDENROD
		
	var target = GameManager.userInterface.FindUnitCard(unit.attackTarget)
	
	if target == null:
		return
		
	var newLineEffect = UnitCard.attackLineScene.instantiate()
	newLineEffect.SetValues(
		global_position + Vector2(32,32), 
		target.global_position + Vector2(32,32),
		attackLineColor
		)
	
	get_tree().root.add_child(newLineEffect)


# calls target unit's hit received animations
func OnAttackAnimationFinished(animName):
	if animName == "attack_animation_left" or animName == "attack_animation_right":
		# reset attack cycle cost
		unit.attackCyclesLeft = unit.data.attackCost
		
		if unit != null:
			var newTarget = unit.attackTarget
			
			if newTarget is Unit:
				unit.attackTargetCoord = newTarget.coords
				
				# call received hit animation
				newTarget.ReceiveHit(unit)
				
				UpdateAttackLine(unit.coords.y != newTarget.coords.y)
				
				if unit.isPlayer:
					GameManager.playerAttackingUnitsCount -= 1
				else:
					GameManager.enemyAttackingUnitsCount -= 1
					
					
func UnitDied():
	var neweffect: GPUParticles2D = deathEffect.instantiate()
	neweffect.global_position = global_position
	get_tree().root.add_child(neweffect)
	neweffect.emitting = true
	
	queue_free()


# when left clicked on this, update selected unit card
# when right clicked onto this, emit signal right clicked
func _gui_input(event):
	if event is InputEventMouse:
		if event.button_mask == MOUSE_BUTTON_LEFT and Input.is_action_just_pressed("left_click"):
			if UnitCard.selected == self:
				# unselect
				$TextureRect/SelectionIndicator.visible = false
				UnitCard.selected = null
			else:
				if UnitCard.selected != null:
					UnitCard.selected.get_node("TextureRect/SelectionIndicator").visible = false
				UnitCard.selected = self
				$TextureRect/SelectionIndicator.visible = true
			
			clicked.emit()
		
		if UnitCard.selected != null and Input.is_action_just_pressed("right_click"):
			was_right_clicked.emit(self)
			
			# check if merging is available: same type
			if UnitCard.selected.unit.data != unit.data:
				# swap positions immediately
				_drop_data(Vector2.ZERO, UnitCard.selected)
			else:
				pass
				## show context menu
				#if UnitCard.selected != self:
					#controlButtons.visible = true


func _unhandled_key_input(event):
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			if UnitCard.selected != null:
				UnitCard.selected.get_node("TextureRect/SelectionIndicator").visible = false
				
			UnitCard.selected = null


func _merge_button_pressed():
	if UnitCard.selected != null:
		unit.Merge(UnitCard.selected.unit)
	
		# destroy other card
		UnitCard.selected.get_parent().remove_child(UnitCard.selected)
		UnitCard.selected.queue_free()
		UnitCard.selected = null
		
		# export unit matrix or reserve
		if get_parent() is UnitSlot:
			get_parent().dropped.emit()
		if get_parent() is ReserveContainer:
			get_parent().dropped.emit()
		
		merged.emit()
		UpdateHealthLabel(0)
		UpdateCombatStatsLabel()
		

func _swap_button_pressed():
	if UnitCard.selected != null:
		_drop_data(Vector2.ZERO, UnitCard.selected)


func UpdateDebugLabel():
	# debug label
	$DebugLabel.text = str(unit.coords)

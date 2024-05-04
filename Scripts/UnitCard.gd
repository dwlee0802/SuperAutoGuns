extends Control
class_name UnitCard

var unit: Unit

@onready var attackLine: Line2D = $AttackLine

var damagePopupScene = load("res://Scenes/damage_popup.tscn")

@onready var attackAnimationPlayer: AnimationPlayer = $AttackAnimaitonPlayer

static var selected: UnitCard

@onready var selectionIndicator = $TextureRect/SelectionIndicator

static var deathEffect

signal clicked

signal was_right_clicked(clicked_thing)

signal merged 


static func _static_init():
	deathEffect = load("res://Scenes/death_effect.tscn")
	

func SetUnit(_unit: Unit):
	unit = _unit
	
	$TextureRect.self_modulate = unit.data.color
	
	# update info ui for this unit
	
	if unit.isPlayer:
		$TextureRect/Name.text = "(P)" + unit.data.name + str(unit.stackCount)
	else:
		$TextureRect/Name.text = "(E)" + unit.data.name + str(unit.stackCount)
		
	UpdateHealthLabel(0)
	UpdateMovementLabel()
	UpdateAttackLabel()
	UpdateCombatStatsLabel()
	
	# UI signals
	unit.stat_changed.connect(UpdateCombatStatsLabel)
	
	$HitAnimaitonPlayer.animation_finished.connect(UpdateHealthLabel)
	
	unit.received_hit.connect(HitAnimation)
	
	unit.unit_died.connect(UnitDied)
	
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
	$TextureRect/HealthPointsLabel.text = "HP: " + str(unit.currentHealthPoints) + "/" + str(unit.data.maxHealthPoints * unit.stackCount)
	UpdateHealthIndicator()
	

func UpdateHealthIndicator():
	var currentHealthRatio: float = float(unit.currentHealthPoints) / (unit.data.maxHealthPoints * unit.stackCount)
	$HealthIndicator.anchor_bottom = 1 - currentHealthRatio
	

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
	

func UpdateCombatStatsLabel():
	var label = $TextureRect/CombatStats
	var text = "A: {atk} D: {dfs}"
	var atk = unit.GetAttackDamage()
	var dfs = unit.GetDefense()
	
	label.text = text.format({"atk": atk, "dfs": dfs})
	
	
func UpdateAttackLine(isFlanking: bool = false):
	var target = null
	#if unit.isPlayer:
		#target = GameManager.enemyEditor.GetUnitCardAt(unit.attackTargetCoord.x, unit.attackTargetCoord.y)
	#else:
		#target = GameManager.playerEditor.GetUnitCardAt(unit.attackTargetCoord.x, unit.attackTargetCoord.y)
	
	if target == null:
		return
		
	$AttackLine.set_point_position(1, target.global_position - global_position + Vector2(32,32))
	$AttackLine.get_node("AnimationPlayer").play("attack_animation")
	
	if isFlanking:
		$AttackLine.default_color = Color.DARK_GOLDENROD


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
			#
			#if unit.isPlayer:
				#GameManager.playerEditor.ImportUnitMatrix()
			#else:
				#GameManager.enemyEditor.ImportUnitMatrix()
				
		if get_parent() is ReserveContainer:
			get_parent().dropped.emit()
			#
			#if unit.isPlayer:
				#GameManager.playerEditor.ImportReserve()
			#else:
				#GameManager.enemyEditor.ImportReserve()
		
		merged.emit()
		

func _swap_button_pressed():
	if UnitCard.selected != null:
		_drop_data(Vector2.ZERO, UnitCard.selected)


func UpdateDebugLabel():
	# debug label
	$DebugLabel.text = str(unit.coords)

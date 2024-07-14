extends Control
class_name UnitCard

static var selected: UnitCard
static var rightClicked: UnitCard

var unit: Unit

@onready var healthBar: TextureProgressBar = $HealthBar
@onready var moraleBar: TextureProgressBar = $MoraleBar

static var attackLineScene = load("res://Scenes/attack_line_effect.tscn")

var damagePopupScene = load("res://Scenes/damage_popup.tscn")

@onready var attackAnimationPlayer: AnimationPlayer = $Sprite/AttackAnimaitonPlayer
@onready var hitAnimationPlayer: AnimationPlayer = $Sprite/HitTextureRect/HitAnimaitonPlayer

@onready var selectionIndicator = $SelectionIndicator

static var deathEffect

@onready var radialUI: RadialProgress = $RadialUI/RadialUI

@onready var radialLabel: Label = $RadialUI/RadialUI/Label

@onready var starContainer: FlowContainer = $Stars

static var goldStarImage = load("res://Art/gold_star.png")
static var greyStarImage = load("res://Art/grey_star.png")

signal clicked

signal was_right_clicked(clicked_thing)

signal merged 


static func _static_init():
	deathEffect = load("res://Scenes/death_effect.tscn")
	
	
func SetUnit(_unit: Unit):
	unit = _unit
	healthBar = $HealthBar
	moraleBar = $MoraleBar
	
	if unit.data.unitTexture != null:
		$Sprite.texture = unit.data.unitTexture
		$Sprite.expand_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		$Sprite.self_modulate = unit.data.color
	
	UpdateHealthLabel(0)
	UpdateMoraleBar()
	
	if unit.isPlayer:
		SetSideIndicatorColor(GameManager.playerColor)
	else:
		SetSideIndicatorColor(GameManager.enemyColor)
	
	starContainer = $Stars
	UpdateStars()
	
	tooltip_text = tr(unit.data.description)
	
	if unit is WaitOrder:
		#$TextureRect/Sprite/CombatStats.visible = false
		radialLabel.text = str(unit.waitCycles)
		
	# UI signals
	unit.stat_changed.connect(UpdateStatLabels)
	
	$Sprite/HitTextureRect/HitAnimaitonPlayer.animation_finished.connect(UpdateHealthLabel)
	$Sprite/HitTextureRect/HitAnimaitonPlayer.animation_finished.connect(UpdateMoraleBar)
	
	unit.received_hit.connect(HitAnimation)
	unit.received_hit.connect(UpdateHealthLabel)
	unit.received_hit.connect(UpdateMoraleBar)
	
	unit.healed.connect(HealAnimation)
	unit.healed.connect(UpdateHealthLabel)
	
	unit.unit_died.connect(UnitDied)
	
	UpdateRadialUI(true)
	
	if unit is WaitOrder:
		if unit.waitCycles <= 0:
			unit.currentHealthPoints = -1
			
	# determine if attacking this cycle
	if unit.IsAttackReady():
		if unit.attackTargetCoord == null:
			return
			
		if unit is MachineGunUnit:
			unit.firstAttackAfterMoving = false
			
		attackAnimationPlayer.animation_finished.connect(OnAttackAnimationFinished)
		if unit.isPlayer:
			attackAnimationPlayer.play("attack_animation_left")
		else:
			attackAnimationPlayer.play("attack_animation_right")
			
	UpdateDebugLabel()
	UpdateStatLabels()
	

func SetSpriteHFlipped(value: bool):
	$Sprite.flip_h = value
		
		
func SetSideIndicatorColor(color: Color) -> void:
	$Sprite.self_modulate = color
	
		
func _get_drag_data(_at_position: Vector2) -> Variant:
	set_drag_preview(make_drag_preview())
	return self


func make_drag_preview() -> TextureRect:
	var newT = TextureRect.new()
	newT.size = size
	newT.texture = unit.data.unitTexture
	newT.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	newT.material = material
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
		unit.coords = null
	
	# swapping inside reserve container
	if !(get_parent() is ReserveContainer and data.get_parent() is ReserveContainer):
		data.global_position = global_position
		position = Vector2.ZERO
	
	UpdateDebugLabel()
	data.UpdateDebugLabel()
	UpdateStatLabels()
	
	
func UpdateHealthLabel(_num = 0):
	$Stats/Health/Label.text = str(unit.currentHealthPoints)
	
	healthBar.max_value = unit.GetMaxHealth()
	healthBar.value = unit.currentHealthPoints


func UpdateMoraleBar(_num = 0):
	moraleBar.max_value = 100
	moraleBar.value = unit.currentMoralePoints
	
	
# plays when unit received damage
# make damage pop up
# play unit animation
func HitAnimation(amount):
	MakePopup(amount, Color.RED, Color.WHITE)
	hitAnimationPlayer.play("hit_animation")
	

func HealAnimation(amount):
	MakePopup(amount, Color.GREEN, Color.WHITE)
	
	
# makes a popup that displays content
func MakePopup(content, color = Color.WHITE, outline_color = Color.GRAY):
	var newPopup = damagePopupScene.instantiate()
	newPopup.global_position = global_position + Vector2(32, 32) + Vector2(randi_range(-10, 10), randi_range(-10, 10))
	var label: Label = newPopup.get_node("Label")
	label.text = str(content)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", outline_color)
	label.add_theme_color_override("outline_size", 10)
	newPopup.get_node("AnimationPlayer").play("damage_popup_animation")
	get_tree().current_scene.add_child(newPopup)
	
	
# workaround for radial ui blinking
var tempWorkaround = true
func _process(_delta):
	UpdateRadialUI(tempWorkaround)
	tempWorkaround = false
	
	
func UpdateRadialUI(first: bool = false):
	if radialUI == null:
		return
		
	#radialUI.visible = true
	
	# how much is finished in the process
	var ratio : float = 0
	
	if unit is WaitOrder and unit.waitCycles <= unit.stackCount:
		radialUI.bar_color = Color.ORANGE
		
		# update label
		if unit.waitCycles < 0:
			radialLabel.text = "0"
		else:
			radialLabel.text = str(unit.waitCycles)
		
		ratio = (unit.stackCount - unit.waitCycles) / float(unit.stackCount)
		if first:
			ratio = (unit.stackCount - unit.waitCycles - 1) / float(unit.stackCount)
		ratio += BattleSpeedUI.currentCycleRatio * (1.0 / unit.stackCount)
		
		print("wait count: " + str(unit.waitCycles))
		print("stack: " + str(unit.stackCount))
		print("ratio: " + str(ratio))
	
	# unit is currently moving
	elif unit.IsMoving():
		radialUI.bar_color = Color.SKY_BLUE
		ratio = 1 - unit.GetCyclesTilMovement() / float(unit.GetMovementCost())
		# workaround for blinking on first frame
		if first:
			ratio = 1 - (unit.GetCyclesTilMovement() + 1) / float(unit.GetMovementCost())
		ratio += BattleSpeedUI.currentCycleRatio * (1.0 / unit.GetMovementCost())
		radialUI.visible = true
		
		# update label to show number of cycles left til action
		if unit.movementProgress - unit.GetMovementCost() > 0:
			radialLabel.text = "0"
		else:
			radialLabel.text = str(unit.GetMovementCost() - unit.movementProgress + 1)
	
	# unit is currently attacking
	elif unit.attackProgress > 0:
		radialUI.bar_color = Color.RED
		ratio = 1 - (unit.GetCyclesTilAttack() + 1) / float(unit.GetAttackCost())
		if first:
			ratio = 1 - (unit.GetCyclesTilAttack() + 2) / float(unit.GetAttackCost())
		ratio += BattleSpeedUI.currentCycleRatio * (1.0 / unit.GetAttackCost())
		radialUI.visible = true
		
		# update label
		if unit.GetCyclesTilAttack() < 0:
			radialLabel.text = "0"
		else:
			radialLabel.text = str(unit.GetCyclesTilAttack() + 1)
			
	# unit is doing nothing
	else:
		radialUI.visible = false
		
	if ratio < 0:
		ratio = 0
	if ratio > 1:
		ratio = 1
	
	if unit is WaitOrder:
		radialUI.visible = true
		
	radialUI.progress = 100 * ratio
	

func UpdateStatLabels():
	var healthLabel: Label = $Stats/MoveSpeed/Label
	var damageLabel: Label = $Stats/AttackDamage/Label
	var moveLabel: Label = $Stats/MoveSpeed/Label
	healthLabel.text = str(unit.currentHealthPoints)
	damageLabel.text = str(unit.data.attackDamageMin) + "-" + str(unit.data.attackDamageMax) + "/" + str(unit.GetAttackCost())
	moveLabel.text = str(unit.GetMovementCost())
	
	
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
		unit.attackProgress = 0
		
		if unit != null:
			var newTarget = unit.attackTarget
			
			# row attack
			if unit.data.rowAttack:
				var targets = GameManager.GetUnitMatrixRow(!unit.isPlayer, newTarget.coords.y)
				
				for target in targets:
					target.ReceiveHit(unit)
					UpdateAttackLine(unit.coords.y != newTarget.coords.y)
				
				if unit.isPlayer:
					GameManager.playerAttackingUnitsCount -= 1
				else:
					GameManager.enemyAttackingUnitsCount -= 1
			else:
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
	if GameManager.isPlayerTurn != unit.isPlayer:
		return
		
	if event is InputEventMouse:
		if event.button_mask == MOUSE_BUTTON_LEFT and Input.is_action_just_pressed("left_click"):
			if UnitCard.selected == self:
				UnitCard.UnselectCard()
			else:
				if UnitCard.selected != null:
					UnitCard.selected.get_node("SelectionIndicator").visible = false
				UnitCard.selected = self
				$SelectionIndicator.visible = true
			
			clicked.emit()
		
		if Input.is_action_just_pressed("right_click"):
			# check if merging is available: same type
			if UnitCard.selected != null and UnitCard.selected.unit.data != unit.data:
				# swap positions immediately
				_drop_data(Vector2.ZERO, UnitCard.selected)
			else:
				## show correct context menu
				UnitCard.rightClicked = self
				was_right_clicked.emit(self)
		

static func UnselectCard():
	if UnitCard.selected != null:
		UnitCard.selected.get_node("SelectionIndicator").visible = false
		UnitCard.selected = null
	
	
func _unhandled_key_input(event):
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			if UnitCard.selected != null:
				UnitCard.selected.get_node("SelectionIndicator").visible = false
				
			UnitCard.selected = null


func _merge_button_pressed():
	if UnitCard.selected != null:
		unit.Merge(UnitCard.selected.unit)
		UpdateStars()
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
		UpdateStatLabels()
		

func UpdateStars(count: int = unit.stackCount):
	var goldCount = (count - 1) / 2
	var remainder = (count + 1) % 2
	
	for star: TextureRect in starContainer.get_children():
		if goldCount > 0:
			star.visible = true
			star.texture = UnitCard.goldStarImage
			goldCount -= 1
		elif remainder == 1:
			star.visible = true
			star.texture = UnitCard.greyStarImage
			star.get_node("PointLight2D").energy = 1
			remainder = 0
		else:
			star.visible = false
				
	
func _swap_button_pressed():
	if UnitCard.selected != null:
		_drop_data(Vector2.ZERO, UnitCard.selected)


func UpdateDebugLabel():
	# debug label
	var output = "null"
	
	if unit == null:
		return
	if unit.coords == null:
		$DebugLabel.text = "NULL"
		return
		
	var ter = GameManager.GetTerrainData(unit)
	if ter != null:
		output = ter.name + "(" + str(unit.coords) + ")"
	
	$DebugLabel.text = output

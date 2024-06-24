extends Control
class_name CaptureStatusUI

@onready var leftContainer: HBoxContainer = $LeftCaptured
@onready var rightContainer: HBoxContainer = $RightCaptured

@onready var contestedContainer: HBoxContainer = $Contested

var sectorIconScene = load("res://Scenes/sector_icon.tscn")


func _ready():
	SetTotalSectorCount(10)
	SetColors(Color.SKY_BLUE, Color.DARK_RED)
	ReloadUI(5)
	SetPlayerAttack(false)


func SetColors(leftColor: Color, rightColor: Color):
	for child in leftContainer.get_children():
		child.self_modulate = leftColor
		
	for child in rightContainer.get_children():
		child.self_modulate = rightColor
		
	contestedContainer.get_node("PlayerAttackArrow").self_modulate = leftColor
	contestedContainer.get_node("PlayerDefendArrow").self_modulate = leftColor
	contestedContainer.get_node("EnemyAttackArrow").self_modulate = rightColor
	contestedContainer.get_node("EnemyDefendArrow").self_modulate = rightColor
	
	
func SetTotalSectorCount(count: int):
	if count % 2 == 1:
		push_warning("Total sector count shouldn't be an odd number.")
	
	# remove preexisting stuff
	for i in leftContainer.get_children():
		leftContainer.remove_child(i)
		i.queue_free()
	for i in rightContainer.get_children():
		rightContainer.remove_child(i)
		i.queue_free()
	
	# assume count is always even
	# add normal squares except contested squares
	for i in range(count):
		var newIcon = sectorIconScene.instantiate()
		leftContainer.add_child(newIcon)
		var newIcon2 = sectorIconScene.instantiate()
		rightContainer.add_child(newIcon2)
	
	# capital indicator
	leftContainer.get_child(0).get_node("Label").visible = true
	rightContainer.get_child(-1).get_node("Label").visible = true
	

func SetPlayerAttack(playerAttacking: bool):
	contestedContainer.get_node("PlayerAttackArrow").visible = playerAttacking == true
	contestedContainer.get_node("PlayerDefendArrow").visible = playerAttacking == false
	contestedContainer.get_node("EnemyAttackArrow").visible = playerAttacking == false
	contestedContainer.get_node("EnemyDefendArrow").visible = playerAttacking == true
		

# assumes that total sector count is correct
func ReloadUI(playerCapturedSectors: int):
	for i in range(leftContainer.get_child_count()):
		leftContainer.get_child(i).visible = i < playerCapturedSectors - 1
	
	for i in range(rightContainer.get_child_count()):
		rightContainer.get_child(i).visible = i > playerCapturedSectors
	
	contestedContainer.visible = !(playerCapturedSectors == 0 or playerCapturedSectors >= rightContainer.get_child_count())
	
	leftContainer.visible = leftContainer.get_child_count() > 0
	rightContainer.visible = rightContainer.get_child_count() > 0

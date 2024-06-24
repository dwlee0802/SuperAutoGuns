extends Control
class_name CaptureStatusUI

@onready var leftContainer: HBoxContainer = $LeftCaptured
@onready var rightContainer: HBoxContainer = $RightCaptured

@onready var contestedContainer: HBoxContainer = $Contested

var sectorIconScene = load("res://Scenes/sector_icon.tscn")


func _ready():
	SetTotalSectorCount(10)
	ReloadUI(5)


func SetColors(leftColor: Color, rightColor: Color):
	pass
	
	
func SetTotalSectorCount(count: int):
	if count % 2 == 1:
		push_warning("Total sector count shouldn't be an odd number.")
	
	# remove preexisting stuff
	for i in range(leftContainer.get_child_count()):
		leftContainer.get_child(i).queue_free()
	for i in range(rightContainer.get_child_count()):
		rightContainer.get_child(i).queue_free()
	
	# assume count is always even
	# add normal squares except contested squares
	for i in range(count/2 - 1):
		var newIcon = sectorIconScene.instantiate()
		leftContainer.add_child(newIcon)
		rightContainer.add_child(newIcon)
	
	# capital indicator
	leftContainer.get_child(0).get_node("Label").visible = true
	rightContainer.get_child(-1).get_node("Label").visible = true
	
	
func ReloadUI(playerCapturedSectors: int):
	var notCotestedPlayerCount: int = playerCapturedSectors - 1
	
	for i in range(leftContainer.get_child_count()):
		if i < playerCapturedSectors:
			container.get_child(i).self_modulate = Color.ROYAL_BLUE
		else:
			container.get_child(i).self_modulate = Color.DARK_RED

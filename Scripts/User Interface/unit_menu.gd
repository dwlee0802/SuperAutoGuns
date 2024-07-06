@tool
extends RadialMenu
class_name UnitMenu

@onready var healButton = $HealButton
@onready var sellButton = $SellButton
@onready var reserveButton = $ReserveButton
#@onready var splitButton = $SplitButton
@onready var swapButton = $SwapButton
@onready var mergeButton = $MergeButton

var targetUnit: UnitCard

var selfMode: bool = false


func get_option(angle: float) -> int:
	var output = super.get_option(angle)
	if !selfMode:
		output += 3
	
	print("radial menu option index: " + str(output))
	
	return output
	

func ShowOtherUnitButtons():
	selfMode = false
	option_count = 2
	swapButton.visible = true
	mergeButton.visible = true
	healButton.visible = false
	sellButton.visible = false
	reserveButton.visible = false
	place_children()


func ShowSelfButtons():
	selfMode = true
	option_count = 3
	swapButton.visible = false
	mergeButton.visible = false
	healButton.visible = true
	sellButton.visible = true
	reserveButton.visible = true
	place_children()

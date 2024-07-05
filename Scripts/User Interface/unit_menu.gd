@tool
extends RadialMenu
class_name UnitMenu

@onready var healButton = $HealButton
@onready var sellButton = $SellButton
@onready var reserveButton = $ReserveButton
#@onready var splitButton = $SplitButton
@onready var swapButton = $SwapButton
@onready var mergeButton = $MergeButton


func ShowOtherUnitButtons():
	option_count = 2
	swapButton.visible = true
	mergeButton.visible = true

func ShowSelfButtons():
	option_count = 3
	healButton.visible = true
	sellButton.visible = true
	reserveButton.visible = true

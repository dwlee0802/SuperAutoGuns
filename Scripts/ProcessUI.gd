extends Control
class_name CaptureStatusUI

@onready var container: HBoxContainer = $HBoxContainer

var sectorIconScene = load("res://Scenes/sector_icon.tscn")


func _ready():
	SetTotalSectorCount(10)
	ReloadUI(5)


func SetTotalSectorCount(count: int):
	for i in range(max(count, container.get_child_count())):
		if i < container.get_child_count():
			if i >= count:
				container.get_child(i).queue_free()
		else:
			var newIcon = sectorIconScene.instantiate()
			container.add_child(newIcon)
	
	container.get_child(0).get_node("Label").visible = true
	container.get_child(-1).get_node("Label").visible = true
	
	
func ReloadUI(playerCapturedSectors: int):
	for i in range(container.get_child_count()):
		if i < playerCapturedSectors:
			container.get_child(i).self_modulate = Color.ROYAL_BLUE
		else:
			container.get_child(i).self_modulate = Color.DARK_RED

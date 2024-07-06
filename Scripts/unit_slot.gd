extends Control
class_name UnitSlot

var coords = null

var canBeDropped: bool = true

var canWaitOrder: bool = false
			
signal dropped

var waitcount: int = 0

@onready var debugLabel: Label = $WaitCountLabel


func SetCanBeDropped(value):
	canBeDropped = value
	
	#if canBeDropped:
		#get_node("TextureRect").self_modulate = Color(0.46,0.46,0.46,1)
	#else:
		#get_node("TextureRect").self_modulate = Color(0.3,0.3,0.3,1)
	
	
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is UnitCard and canBeDropped and !data.unit.IsDead():
		return true
		
	return false


# make unit card into self's child
func _drop_data(_at_position, data):
	data.get_parent().remove_child(data)
	add_child(data)
	data.reparent(self)
	data.position = Vector2.ZERO
	
	data.unit.coords = GameManager.EditorCoordsToMatrixCoords(coords)
	
	data.UpdateDebugLabel()
	dropped.emit()


func _gui_input(event):
	if event is InputEventMouse:
		if UnitCard.selected != null and Input.is_action_just_pressed("right_click"):
			# check if merging is available: same type
			if _can_drop_data(Vector2.ZERO, UnitCard.selected):
				_drop_data(Vector2.ZERO, UnitCard.selected)
		
		if UnitCard.selected != null and Input.is_action_just_pressed("left_click"):
			# remove selected unit
			UnitCard.UnselectCard()
		
		# possible to make units wait here if attacker turn and slot is in middle col
		if UnitCard.selected == null and Input.is_action_just_pressed("left_click") and canWaitOrder:
			print("add wait order here")
			waitcount += 1
			debugLabel.text = "wait " + str(waitcount) + " cycles"
		if UnitCard.selected == null and Input.is_action_just_pressed("right_click") and canWaitOrder:
			print("remove wait order here")
			waitcount -= 1
			if waitcount < 0:
				waitcount = 0
			debugLabel.text = "wait " + str(waitcount) + " cycles"
			
		if waitcount > 0 and canWaitOrder:
			debugLabel.visible = true
		else:
			debugLabel.visible = false
			

# returns the unit card here and null if none
func GetUnitHere():
	for child in get_children():
		if child is UnitCard:
			return child
	
	return null


func SetCanWaitOrder(value):
	canWaitOrder = value
	debugLabel.visible = value		
	
	if waitcount > 0 and canWaitOrder:
		debugLabel.visible = true
	else:
		debugLabel.visible = false
		
		
func SetTerrain(data: TerrainData):
	$TerrainLabel.self_modulate = data.color
	#$TextureRect.self_modulate = data.color
	$TerrainLabel.text = data.name
	#$TextureRect.texture = data.slotTexture
	tooltip_text = tr(data.description)

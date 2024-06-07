extends Control
class_name UnitSlot

var coords = null

var canBeDropped: bool = true

signal dropped

static var waitOrderData

var waitcount: int = 0


static func _static_init():
	waitOrderData = load("res://Data/Units/Generic/wait_order.tres")
	

func SetCanBeDropped(value):
	canBeDropped = value
	
	#if canBeDropped:
		#get_node("TextureRect").self_modulate = Color(0.46,0.46,0.46,1)
	#else:
		#get_node("TextureRect").self_modulate = Color(0.3,0.3,0.3,1)
	
	
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is UnitCard and canBeDropped:
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
		
		if UnitCard.selected == null and Input.is_action_just_pressed("left_click") and canBeDropped:
			print("add wait order here")
			waitcount += 1
			$Label.text = str(waitcount)
		if UnitCard.selected == null and Input.is_action_just_pressed("right_click") and canBeDropped:
			print("remove wait order here")
			waitcount -= 1
			$Label.text = str(waitcount)


# returns the unit card here and null if none
func GetUnitHere():
	for child in get_children():
		if child is UnitCard:
			return child
	
	return null

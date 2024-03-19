extends TextureButton
class_name ReinforcementOptionButton

var unitData: UnitData

@export var isPlayer: bool


func SetData(data: UnitData):
	unitData = data
	$Label.text = unitData.name


# add to reserve
# update UI
func _pressed():
	# add unit to reserve
	GameManager.AddReserveUnit(unitData, isPlayer)
		

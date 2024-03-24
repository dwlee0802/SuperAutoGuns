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
	# check if theres enough funds
	if GameManager.playerFunds < unitData.purchaseCost:
		print("not enough funds!")
		return
	
	# add unit to reserve
	GameManager.AddReserveUnit(unitData, isPlayer)
	GameManager.ChangeFunds(unitData.purchaseCost, isPlayer)
	queue_free()

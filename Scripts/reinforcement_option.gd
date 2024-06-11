extends TextureButton
class_name ReinforcementOptionButton

var unitData: UnitData

@export var isPlayer: bool


func SetData(data: UnitData):
	unitData = data
	$Label.text = tr(unitData.name)
	$Label.text += "\n Cost: " + str(unitData.purchaseCost)
	self_modulate = unitData.color
	tooltip_text = data.description


# add to reserve
# update UI
func _pressed():
	print("rein op")
	PurchseUnit()


func PurchseUnit():
	# check if theres enough funds
	if isPlayer:
		if GameManager.playerFunds < unitData.purchaseCost:
			print("player has not enough funds!\n")
			return false
	else:
		if GameManager.enemyFunds < unitData.purchaseCost:
			print("enemy has not enough funds!\n")
			return false
		
	# add unit to reserve
	GameManager.AddReserveUnit(unitData, isPlayer)
	GameManager.ChangeFunds(-unitData.purchaseCost, isPlayer)
	pressed.emit()
	queue_free()
	return true
	

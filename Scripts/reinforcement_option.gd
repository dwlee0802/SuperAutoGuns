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
	PurchseUnit()


func PurchseUnit():
	# check if theres enough funds
	if isPlayer:
		if GameManager.playerFunds < unitData.purchaseCost:
			print("player has not enough funds!")
			return false
	else:
		if GameManager.enemyFunds < unitData.purchaseCost:
			print("enemy has not enough funds!")
			return false
		
	# add unit to reserve
	GameManager.AddReserveUnit(unitData, isPlayer)
	GameManager.ChangeFunds(-unitData.purchaseCost, isPlayer)
	queue_free()
	return true
	

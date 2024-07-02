extends TextureButton
class_name ReinforcementOptionButton

var unitData: UnitData

@export var isPlayer: bool


func SetData(data: UnitData):
	unitData = data
	$Label.text = tr(unitData.name)
	$Label.text += "\n " + tr("COST") + ": " + str(unitData.purchaseCost)
	self_modulate = unitData.color
	tooltip_text = data.description


# add to reserve
# update UI
func _pressed():
	PurchseUnit()


func PurchseUnit():
	# check if theres enough funds
	if GameManager.CheckFunds(unitData.purchaseCost):
		# add unit to reserve
		GameManager.AddReserveUnit(unitData, isPlayer)
		GameManager.ChangeFunds(-unitData.purchaseCost, isPlayer)
		pressed.emit()
		queue_free()
		return true
	
	return false

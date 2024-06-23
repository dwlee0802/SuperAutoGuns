extends Unit
class_name MachineGunUnit

var firstAttackAfterMoving: bool = true


func GetAttackCost():
	if firstAttackAfterMoving:
		return data.attackCost + data.setUpTime
	else:
		return data.attackCost


func Duplicate():
	var clone = MachineGunUnit.new(isPlayer, data, coords, stackCount)
	clone.currentHealthPoints = currentHealthPoints
	clone.boughtThisTurn = boughtThisTurn
	
	return clone

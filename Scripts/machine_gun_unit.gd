extends Unit
class_name MachineGunUnit

var firstAttackAfterMoving: bool = true


func GetAttackSpeed():
	if firstAttackAfterMoving:
		return data.attackCost + data.setUpTime
	else:
		return data.attackCost

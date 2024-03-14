extends Node
class_name Unit

var data: UnitData

var currentHealthPoints: int

var movementCyclesLeft: int

var attackCyclesLeft: int


func _init(_data):
	if _data == null:
		queue_free()
		return
		
	data = _data
	ResetStats()
	

func ResetStats():
	movementCyclesLeft = data.movementCost
	attackCyclesLeft = data.attackCost
	currentHealthPoints = data.maxHealthPoints


func ReceiveHit(amount):
	currentHealthPoints -= amount
	if currentHealthPoints <= 0:
		queue_free()

extends Node
class_name Unit

var data: UnitData

var currentHealthPoints: int

var movementCyclesLeft: int = 0

var attackCyclesLeft: int = 0

signal received_hit(amount)

signal unit_dead

var isDead: bool = false


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
	print("received hit of " + str(amount))
	currentHealthPoints -= amount
	received_hit.emit(amount)
	if currentHealthPoints <= 0:
		unit_dead.emit()
		isDead = true

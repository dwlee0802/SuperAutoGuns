class_name Unit

var isPlayer: bool

var data: UnitData

var currentHealthPoints: int

var movementCyclesLeft: int = 0

var attackCyclesLeft: int = 0

# holds the col and row index of attack target in enemy's matrix
var attackTargetCoord: Vector2

signal received_hit(amount)

signal unit_dead

var isDead: bool = false

var isMoving: bool = false


func _init(_player, _data):
	if _data == null:
		print("ERROR! No data in Unit.")
		return
		
	data = _data
	isPlayer = _player
	ResetStats()
	

func ResetStats():
	movementCyclesLeft = data.movementCost
	attackCyclesLeft = data.attackCost
	currentHealthPoints = data.maxHealthPoints


func ReceiveHit(amount):
	print(data.name + " received hit of " + str(amount))
	currentHealthPoints -= amount
	received_hit.emit(amount)
	
	if currentHealthPoints <= 0:
		unit_dead.emit()
		isDead = true
		# remove data
		GameManager.RemoveUnit(self)
		
		
func Attack():
	var target
	if isPlayer:
		target = GameManager.enemyUnitMatrix[attackTargetCoord.x][attackTargetCoord.y]
	else:
		target = GameManager.playerUnitMatrix[attackTargetCoord.x][attackTargetCoord.y]
	
	if target != null:
		target.ReceiveHit(data.attackDamage)
		
	attackCyclesLeft = data.attackCost

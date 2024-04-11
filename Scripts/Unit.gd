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

var stackCount: int = 1


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
	var consoleOutput: String
	if isPlayer:
		consoleOutput = "(Player)"
	else:
		consoleOutput = "(Enemy)"
		
	print(consoleOutput + str(self) + " received hit of " + str(amount))
	
	currentHealthPoints -= amount
	received_hit.emit(amount)
	
	if currentHealthPoints <= 0:
		unit_dead.emit()
		isDead = true
		# remove data
		GameManager.RemoveUnit(self)
		

func Heal(amount = 0):
	if amount == 0:
		return
		
	var consoleOutput: String
	if isPlayer:
		consoleOutput = "(Player)"
	else:
		consoleOutput = "(Enemy)"
		
	print(consoleOutput + str(self) + " healed for " + str(amount))
	
	currentHealthPoints += amount
	
	if currentHealthPoints > data.maxHealthPoints:
		currentHealthPoints = data.maxHealthPoints
		
		
func RatioHeal(ratio: float = 0):
	if ratio == 0:
		return
		
	var consoleOutput: String
	if isPlayer:
		consoleOutput = "(Player)"
	else:
		consoleOutput = "(Enemy)"
	
	var amount = int(data.maxHealthPoints * ratio)
	
	currentHealthPoints += amount
	
	if currentHealthPoints > data.maxHealthPoints:
		currentHealthPoints = data.maxHealthPoints
		
	print(consoleOutput + str(self) + " healed " + str(ratio) + " of max health(" + str(amount) + ")")
	
	
func Attack():
	var target
	if isPlayer:
		target = GameManager.enemyUnitMatrix[attackTargetCoord.x][attackTargetCoord.y]
	else:
		target = GameManager.playerUnitMatrix[attackTargetCoord.x][attackTargetCoord.y]
	
	if target != null:
		target.ReceiveHit(data.attackDamage)
	else:
		print("target null")
		
	attackCyclesLeft = data.attackCost


func _to_string():
	var output = data.name
	output += "(" + str(currentHealthPoints) + "/" + str(data.maxHealthPoints) + ")"
	return output


func Duplicate():
	var clone = Unit.new(isPlayer, data)
	clone.currentHealthPoints = currentHealthPoints
	
	return clone

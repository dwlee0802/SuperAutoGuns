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


func _init(_player, _data, _stack: int = 1):
	if _data == null:
		print("ERROR! No data in Unit.")
		return
		
	data = _data
	isPlayer = _player
	stackCount = _stack
	ResetStats()
	

func ResetStats():
	movementCyclesLeft = data.movementCost
	attackCyclesLeft = data.attackCost
	currentHealthPoints = data.maxHealthPoints


func ReceiveHit(amount, isFlank: bool = false):
	var consoleOutput: String
	if isPlayer:
		consoleOutput = "(Player)"
	else:
		consoleOutput = "(Enemy)"
	
	if isFlank:
		amount -= data.defense + data.flankingDefenseModifier
	else:
		amount -= data.defense
		
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
	
	if currentHealthPoints > data.maxHealthPoints * stackCount:
		currentHealthPoints = data.maxHealthPoints * stackCount
		
		
func RatioHeal(ratio: float = 0):
	if ratio == 0:
		return
		
	var consoleOutput: String
	if isPlayer:
		consoleOutput = "(Player)"
	else:
		consoleOutput = "(Enemy)"
	
	var amount = int(data.maxHealthPoints * stackCount * ratio)
	
	currentHealthPoints += amount
	
	if currentHealthPoints > data.maxHealthPoints * stackCount:
		currentHealthPoints = data.maxHealthPoints * stackCount
		
	#print(consoleOutput + str(self) + " healed " + str(int(ratio * 100)) + "% of max health(" + str(amount) + ")")
	
	
func Attack(isFlank: bool = false):
	var target
	if isPlayer:
		target = GameManager.enemyUnitMatrix[attackTargetCoord.x][attackTargetCoord.y]
	else:
		target = GameManager.playerUnitMatrix[attackTargetCoord.x][attackTargetCoord.y]
	
	if target != null:
		if isFlank:
			target.ReceiveHit(data.attackDamage + data.flankingAttackModifier)
		else:
			target.ReceiveHit(data.attackDamage)
	else:
		print("target null")
		
	attackCyclesLeft = data.attackCost


# merge with otherUnit
#
func Merge(otherUnit: Unit):
	stackCount += otherUnit.stackCount
	Heal(otherUnit.currentHealthPoints)
	print("\n" + str(otherUnit) + " and " + str(self) + " merged. New stack size: " + str(stackCount) + "\n")
	
	# remove other unit
	# otherunit's parent is unit slot
	## otherunit's parent is reserve
	#if GameManager.RemoveUnit(otherUnit):
		#return
	#else:
		#if GameManager.RemoveUnitFromReserve(otherUnit):
			#return
		#else:
			#print("ERROR! Merged unit but couldn't remove it from memory.")


func _to_string():
	var output = data.name + str(stackCount)
	output += "(" + str(currentHealthPoints) + "/" + str(data.maxHealthPoints * stackCount) + ")"
	return output


func Duplicate():
	var clone = Unit.new(isPlayer, data, stackCount)
	clone.currentHealthPoints = currentHealthPoints
	
	return clone

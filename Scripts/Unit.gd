class_name Unit

var coords = null

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

var statAdditionModifier = []


func _init(_player, _data, _coord, _stack: int = 1):
	if _data == null:
		print("ERROR! No data in Unit.")
		return
		
	data = _data
	isPlayer = _player
	stackCount = _stack
	coords = _coord
	
	ResetStats()
	ResetStatModifiers()
	

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
		amount -= GetDefense() + data.flankingDefenseModifier
	else:
		amount -= GetDefense()
		
	print(consoleOutput + str(self) + " received hit of " + str(amount))
	
	if currentHealthPoints >= amount:
		currentHealthPoints -= amount
		received_hit.emit(amount)
	else:
		received_hit.emit(currentHealthPoints)
		amount = currentHealthPoints
		currentHealthPoints = 0
		
	GameManager.AddEffectiveDamage(isPlayer, amount)
		
		
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
		
	var _consoleOutput: String
	if isPlayer:
		_consoleOutput = "(Player)"
	else:
		_consoleOutput = "(Enemy)"
	
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
			target.ReceiveHit(GetAttackDamage() + data.flankingAttackModifier)
		else:
			target.ReceiveHit(GetAttackDamage())
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
	var clone = Unit.new(isPlayer, data, coords, stackCount)
	clone.currentHealthPoints = currentHealthPoints
	
	return clone
	
	
func ChangeStats(what: Enums.StatType, amount):
	if what < Enums.statTypeCount:
		statAdditionModifier[what] += amount


func ResetStatModifiers():
	statAdditionModifier = []
	statAdditionModifier.resize(Enums.statTypeCount)
	statAdditionModifier.fill(0)


func GetAttackDamage():
	return data.attackDamage * stackCount + statAdditionModifier[Enums.StatType.AttackDamage]
	
	
func GetDefense():
	return data.defense + statAdditionModifier[Enums.StatType.Defense]

class_name Unit

var coords = null
var initialCoords = null

var isPlayer: bool

var data: UnitData

var currentHealthPoints: int

var currentMoralePoints: int = 100

var lastReceivedDamage: int = 0

var movementProgress: int = 0

var attackProgress: int = 0

# holds the col and row index of attack target in enemy's matrix
var attackTargetCoord: Vector2

var attackTarget

var isDead: bool = false

var isMoving: bool = false

var stackCount: int = 1

# star increases by 1 per 3 stacks
# stats are increased by stars
var starCount: int = 0

var statAdditionModifier = []

var boughtThisTurn: bool = true

# signals
signal received_hit(amount)
signal healed(amount)

signal unit_died

signal attacked

signal was_attacked

signal suppressed

signal stat_changed



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
	movementProgress = 0
	attackProgress = 0
	currentHealthPoints = GetMaxHealth()


func ResetStatModifiers():
	statAdditionModifier = []
	statAdditionModifier.resize(Enums.statTypeCount)
	statAdditionModifier.fill(0)


func ReceiveHit(attacker: Unit):
	var isFlank = attacker.coords.y != coords.y
	var amount = attacker.GetAttackDamage(isFlank)
	
	var consoleOutput: String
	if isPlayer:
		consoleOutput = "(Player)"
	else:
		consoleOutput = "(Enemy)"
	
	var effectiveDefense = max(GetDefense(isFlank) - attacker.GetPenetration(), 0)
	
	amount -= effectiveDefense
	
	if amount < 0:
		amount = 0
		
	print(consoleOutput + str(self) + " received hit of " + str(amount))
	
	if currentHealthPoints >= amount:
		currentHealthPoints -= amount
	else:
		amount = currentHealthPoints
		currentHealthPoints = 0
		
	# suppression
	if !GameManager.disableMorale:
		currentMoralePoints -= attacker.GetSuppressionAmount()
		if currentMoralePoints <= 0:
			currentMoralePoints = 0
			suppressed.emit()
		
	# this calls UnitCard's hit animation
	received_hit.emit(amount)
	
	lastReceivedDamage += amount
		

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
	
	healed.emit(amount)
	
		
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
		
	#print(str(self) + " healed " + str(int(ratio * 100)) + "% of max health(" + str(amount) + ")")
	
	healed.emit(amount)
	
	
func Attack(differentRow: bool = false):
	#var target
	#if isPlayer:
		#target = GameManager.enemyUnitMatrix[attackTargetCoord.x][attackTargetCoord.y]
	#else:
		#target = GameManager.playerUnitMatrix[attackTargetCoord.x][attackTargetCoord.y]
	#
	if attackTarget != null:
		if data.rowAttack:
			var targets = GameManager.GetUnitMatrixRow(!isPlayer, attackTarget.coords.y)
			print("here?")
			print(targets.size())
			for unit in targets:
				if differentRow:
					attackTarget.ReceiveHit(GetAttackDamage() + data.flankingAttackModifier)
				else:
					attackTarget.ReceiveHit(GetAttackDamage())
		else:
			print("is it here???")
			# is flank
			if differentRow:
				attackTarget.ReceiveHit(GetAttackDamage() + data.flankingAttackModifier)
			else:
				attackTarget.ReceiveHit(GetAttackDamage())
		
		attacked.emit()
	else:
		print("target null")
		
	attackProgress = 0


# merge with otherUnit
#
func Merge(otherUnit: Unit):
	stackCount += otherUnit.stackCount
	Heal(otherUnit.currentHealthPoints)
	print("\n" + str(otherUnit) + " and " + str(self) + " merged. New stack size: " + str(stackCount) + "\n")
	
	# 1 0 0
	# 2 0 1
	# 3 1 0
	# 4 1.5 1
	# 5 2 0
	# 6 2.5 1
	# 7 3
	starCount = (stackCount - 1) / 2
	
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
	return output


func Duplicate():
	var clone = Unit.new(isPlayer, data, coords, stackCount)
	clone.currentHealthPoints = currentHealthPoints
	clone.boughtThisTurn = boughtThisTurn
	
	return clone
	
	
func ChangeStats(what: Enums.StatType, amount):
	if what < Enums.statTypeCount:
		statAdditionModifier[what] += amount
	
	stat_changed.emit()


func GetAttackDamage(isFlank: bool = false):
	if isFlank:
		return (GetRandomDamageAmount() + statAdditionModifier[Enums.StatType.AttackDamage] + data.flankingAttackModifier) * (starCount + 1)
	else:
		return (GetRandomDamageAmount() + statAdditionModifier[Enums.StatType.AttackDamage]) * (starCount + 1)


func GetRandomDamageAmount():
	return randi_range(data.attackDamageMin, data.attackDamageMax)


func GetSuppressionAmount():
	return randi_range(data.suppressionMin, data.suppressionMax)


func GetMaxHealth():
	return data.maxHealthPoints * stackCount
	
	
func GetDefense(isFlank: bool = false):
	if isFlank:
		return (data.defense + statAdditionModifier[Enums.StatType.Defense] + data.flankingDefenseModifier) * (starCount + 1)
	else:
		return (data.defense + statAdditionModifier[Enums.StatType.Defense]) * (starCount + 1)


func GetAttackCost():
	return data.attackCost
	

# shoult take into account the terrain modifiers
func GetMovementCost():
	return max(data.movementCost + GameManager.GetTerrainMovementModifier(self), 1)


func GetAttackRange():
	if coords == null:
		return data.attackRange
	else:
		var terrainData = GameManager.GetTerrainData(self)
		return data.attackRange + terrainData.attackRange


func GetPenetration():
	return data.penetration * (starCount + 1)
	
	
# connects the right signal based on AbilityData to UseAbility
func ConnectTargetSignals():
	# start by removing connections from all signals
	if attackTarget == null:
		return
	
	DisconnectAbilityRelatedSignalConnections(attackTarget)
	
	if data.ability == null:
		return
		
	match data.ability.activiationCondition:
		Enums.AbilityCondition.Static:
			print("static ability.")
		Enums.AbilityCondition.OnTargetDeath:
			print("on target death")
			if !attackTarget.unit_died.is_connected(UseAbility):
				attackTarget.unit_died.connect(UseAbility)
		Enums.AbilityCondition.OnTargetAttack:
			print("on target attack")
			if !attackTarget.attacked.is_connected(UseAbility):
				attackTarget.attacked.disconnect(UseAbility)
		Enums.AbilityCondition.OnSelfAttack:
			print("on self attack")
			if !attacked.is_connected(UseAbility):
				attacked.disconnect(UseAbility)
		Enums.AbilityCondition.OnHit:
			print("on self hit")
			if !was_attacked.is_connected(UseAbility):
				was_attacked.disconnect(UseAbility)
			
	
	
func UseAbility():
	print("use ability " + data.ability.abilityName)
	var abilityFunction = Callable(AbilityManager, data.ability.callableName)
	if isPlayer:
		abilityFunction.call(GameManager.playerUnitMatrix, coords, data.ability.dir_parameter, data.ability.int_parameter, data.ability.statType)


func SetAttackTarget(newTarget):
	# remove connections to old target
	if attackTarget != null:
		DisconnectAbilityRelatedSignalConnections(attackTarget)
	
	attackTarget = newTarget
	ConnectTargetSignals()
	

# connects signals if connecting is true, and vice versa
func DisconnectAbilityRelatedSignalConnections(target: Unit):
	if target == null:
		return
	
	if target.attacked.is_connected(UseAbility):
		target.attacked.disconnect(UseAbility)
		
	if target.unit_died.is_connected(UseAbility):
		target.unit_died.disconnect(UseAbility)
		
	if target.was_attacked.is_connected(UseAbility):
		target.was_attacked.disconnect(UseAbility)


func IsFullHealth() -> bool:
	return currentHealthPoints == data.maxHealthPoints * stackCount


func IsMoving() -> bool:
	return movementProgress > 0


func GetCyclesTilMovement():
	return GetMovementCost() - movementProgress + 1
	

func GetCyclesTilAttack():
	return GetAttackCost() - attackProgress
	

func IsAttackReady():
	return attackProgress > GetAttackCost()
	
	
func IsDead() -> bool:
	return currentHealthPoints <= 0
	
	
func SaveCoords():
	initialCoords = coords


func GetDPC() -> float:
	return data.attackDamage / float(data.attackCost)

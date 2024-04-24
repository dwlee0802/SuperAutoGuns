class_name Unit

var coords = null

var isPlayer: bool

var data: UnitData

var currentHealthPoints: int

var lastReceivedDamage: int = 0

var movementCyclesLeft: int = 0

var attackCyclesLeft: int = 0

# holds the col and row index of attack target in enemy's matrix
var attackTargetCoord: Vector2

var attackTarget

var isDead: bool = false

var isMoving: bool = false

var stackCount: int = 1

var statAdditionModifier = []

# signals
signal received_hit(amount)

signal unit_dead

signal attacked

signal was_attacked

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
	
	if amount < 0:
		amount = 0
		
	print(consoleOutput + str(self) + " received hit of " + str(amount))
	
	if currentHealthPoints >= amount:
		currentHealthPoints -= amount
		#received_hit.emit()
	else:
		#received_hit.emit()
		amount = currentHealthPoints
		currentHealthPoints = 0
	
	lastReceivedDamage += amount
	
	GameManager.AddEffectiveDamage(isPlayer, amount)
		
	if currentHealthPoints <= 0:
		unit_dead.emit()
		isDead = true
		# remove data
		#GameManager.RemoveUnit(self)
		

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
	
	
func Attack(differentRow: bool = false):
	#var target
	#if isPlayer:
		#target = GameManager.enemyUnitMatrix[attackTargetCoord.x][attackTargetCoord.y]
	#else:
		#target = GameManager.playerUnitMatrix[attackTargetCoord.x][attackTargetCoord.y]
	#
	if attackTarget != null:
		# is flank
		if differentRow:
			attackTarget.ReceiveHit(GetAttackDamage() + data.flankingAttackModifier)
		else:
			attackTarget.ReceiveHit(GetAttackDamage())
		
		attacked.emit()
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
	
	stat_changed.emit()


func ResetStatModifiers():
	statAdditionModifier = []
	statAdditionModifier.resize(Enums.statTypeCount)
	statAdditionModifier.fill(0)


func GetAttackDamage(isFlank: bool = false):
	if isFlank:
		return GetAttackDamage() + data.flankingAttackModifier
	else:
		return data.attackDamage * stackCount + statAdditionModifier[Enums.StatType.AttackDamage]

	
func GetDefense():
	return data.defense + statAdditionModifier[Enums.StatType.Defense]
	

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
			if !attackTarget.unit_dead.is_connected(UseAbility):
				attackTarget.unit_dead.connect(UseAbility)
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
		
	if target.unit_dead.is_connected(UseAbility):
		target.unit_dead.disconnect(UseAbility)
		
	if target.was_attacked.is_connected(UseAbility):
		target.was_attacked.disconnect(UseAbility)
		

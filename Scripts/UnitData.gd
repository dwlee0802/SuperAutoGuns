extends Resource
class_name UnitData

@export_group("Unit Info")
@export var name: String = "Null"

@export_multiline var description: String = ""

# if true does not get added to data manager
@export var disabled: bool = false

@export var type: Enums.UnitType

@export var purchaseCost: int = 3

@export var color = Color.WHITE

@export var ability: AbilityData

@export var onHitAbility: AbilityData = null


@export_group("Combat Stats")
@export var maxHealthPoints: int = 10

@export var movementCost: int = 4

@export var attackCost: int = 4

@export var attackRange: int = 1

@export var attackFromBack: bool = false
@export var rowAttack: bool = false

@export var attackDamage: int = 3
@export var flankingAttackModifier: float = 0

@export var defense: int = 0
@export var flankingDefenseModifier: float = 0

@export var penetration: int = 0

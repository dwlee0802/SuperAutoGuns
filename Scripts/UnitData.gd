extends Resource
class_name UnitData

@export var name: String = "Null"

@export var type: Enums.UnitType

@export var purchaseCost: int = 3


@export_group("Combat Stats")
@export var maxHealthPoints: int = 1

@export var movementCost: int = 1

@export var attackCost: int = 1

@export var attackDamage: int = 1

@export var attackRange: int = 1

@export var flankingAttackModifier: float = 0
@export var flankingDefenseModifier: float = 0



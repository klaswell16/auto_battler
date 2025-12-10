extends Resource
class_name EnemyLevel

@export var display_name: String = "Round 1"
@export var enemies: Array[ChampionData] = []   # which units appear for the round
@export var stat_multiplier: float = 1.0        # how hard the round is

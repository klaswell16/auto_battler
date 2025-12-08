extends Container
class_name ChampionSlot

@export var slot_index: int = 0
@export var side: String = "player" # would put enemy here as well

var champion: Node = null

func _ready():
	custom_minimum_size = Vector2(128, 128)
	$Highlight.visible = false

func place_champion(champ_scene: PackedScene, data) -> void:
	if champion:
		champion.queue_free()

	var c: Node2D = champ_scene.instantiate()
	$Anchor.add_child(c)

	if c.has_method("apply_data"):
		c.apply_data(data)  # can be ChampionData or Dictionary

	champion = c


func clear_slot() -> void:
	if champion:
		champion.queue_free()
		champion = null

func has_living_champion() -> bool:
	return champion != null \
		and champion is Champion \
		and not champion.is_dead()

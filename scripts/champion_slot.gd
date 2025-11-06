extends Container
class_name ChampionSlot

@export var slot_index: int = 0
@export var side: String = "player" # or "enemy"

var champion: Node = null

func _ready():
	custom_minimum_size = Vector2(128, 128)
	$Highlight.visible = false

func place_champion(champ_scene: PackedScene, data: Dictionary) -> void:
	if champion:
		champion.queue_free()
	var c: Node2D = champ_scene.instantiate()
	$Anchor.add_child(c)
	# Minimal stat hookup (matches Champion.gd below)
	if c.has_method("apply_data"):
		c.apply_data(data)
	champion = c

func clear_slot() -> void:
	if champion:
		champion.queue_free()
		champion = null

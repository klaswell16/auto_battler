extends Node


var gold: int = 10

# Each entry is just a ChampionData reference the player owns
var owned_units: Array[ChampionData] = []

# Tracks how many copies you have of each champion, for upgrades
var copy_counts: Dictionary = {}  # key: Resource path (String), value: int
var star_levels: Dictionary = {}  # key: Resource path (String), value: int

func add_unit(data: ChampionData) -> void:
	if data == null:
		return

	owned_units.append(data)

	var key := data.resource_path
	if key == "":
		key = str(data)  # fallback

	var count: int = int(copy_counts.get(key, 0)) + 1
	copy_counts[key] = count

	var star: int = int(star_levels.get(key, 1))

	# Simple rule: 3 copies = +1 star (TFT-style)
	if count >= 3:
		copy_counts[key] = 0
		star_levels[key] = star + 1
		print("Upgraded ", data.display_name, " to ", star + 1, "-star!")

extends Node

var gold: int = 10
var round: int = 1

# Simple reward tuning
var win_gold: int = 5      # base gold for winning a round
var loss_gold: int = 2     # base gold for losing a round
var round_bonus: int = 1   # extra gold per round (scaling)

# Player’s roster and upgrade tracking
var owned_units: Array[ChampionData] = []
var copy_counts: Dictionary = {}   # key: resource path -> copies
var star_levels: Dictionary = {}   # key: resource path -> star level

func reset_run() -> void:
	gold = 10
	round = 1
	owned_units.clear()
	copy_counts.clear()
	star_levels.clear()

func add_unit(data: ChampionData) -> void:
	if data == null:
		return

	owned_units.append(data)

	var key := data.resource_path
	if key == "":
		key = str(data)

	var count: int = int(copy_counts.get(key, 0)) + 1
	copy_counts[key] = count

	var star: int = int(star_levels.get(key, 1))
	if count >= 3:
		copy_counts[key] = 0
		star_levels[key] = star + 1
		print("Upgraded ", data.display_name, " to ", star + 1, "-star!")

func apply_battle_result(player_won: bool) -> void:
	var base: int = win_gold if player_won else loss_gold
	var bonus: int = round_bonus * round

	var reward: int = base + bonus
	gold += reward

	print("Round ", round, " ended. Player_won=", player_won,
		" reward=", reward, " gold now=", gold)

	round += 1

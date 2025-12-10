extends Node

const MAX_ROUNDS := 10

var gold: int = 10
var round: int = 1

var win_gold: int = 5
var loss_gold: int = 2
var round_bonus: int = 1

var owned_units: Array[ChampionData] = []
var copy_counts: Dictionary = {}
var star_levels: Dictionary = {}

var game_won: bool = false
var game_lost: bool = false
var game_over: bool = false

func reset_run() -> void:
	gold = 10
	round = 1
	game_won = false
	game_lost = false
	game_over = false
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
	if game_over:
		return

	var base: int = win_gold if player_won else loss_gold
	var bonus: int = round_bonus * round
	var reward: int = base + bonus
	gold += reward

	print("apply_battle_result: round before =", round, " player_won =", player_won)

	if round >= MAX_ROUNDS:
		if player_won:
			game_won = true
			game_over = true
		else:
			game_lost = true
			game_over = true
		# round stays at MAX_ROUNDS
		return

	round += 1

	print("apply_battle_result: round after  =", round, " game_won =", game_won, " game_lost =", game_lost)

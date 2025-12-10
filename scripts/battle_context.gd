extends Node

const MAX_ROUNDS := 10
const MAX_STAR := 3    
const BENCH_MAX := 8 

class UnitInstance:
	var data: ChampionData
	var star: int = 1

var gold: int = 10
var round: int = 1

var win_gold: int = 5
var loss_gold: int = 2
var round_bonus: int = 1

var owned_units: Array[UnitInstance] = []  

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
	

func _try_merge(data: ChampionData, start_star: int) -> void:
	var star := start_star

	while star < MAX_STAR:
		var indices: Array[int] = []

		# Find all instances of this unit at this star level
		for i in owned_units.size():
			var u: UnitInstance = owned_units[i]
			if u.data == data and u.star == star:
				indices.append(i)

		if indices.size() < 3:
			return  # not enough to merge at this star level

		# We have at least 3 → consume exactly 3 to make 1 upgraded
		indices.sort()

		# Remove 3 from highest index down so indices don't shift
		for j in range(2, -1, -1):
			owned_units.remove_at(indices[j])

		# Create upgraded instance
		var upgraded := UnitInstance.new()
		upgraded.data = data
		upgraded.star = star + 1
		owned_units.append(upgraded)

		print("Upgraded ", data.display_name, " to ", upgraded.star, "-star!")

		# Now see if we can merge at the next star level (e.g. 2★ → 3★)
		star += 1
		
func is_bench_full() -> bool:
	return owned_units.size() >= BENCH_MAX


func add_unit(data: ChampionData) -> void:
	if data == null:
		return

	# Start with a new 1★ instance
	var inst := UnitInstance.new()
	inst.data = data
	inst.star = 1
	owned_units.append(inst)

	# Try to merge 1★ → 2★, 2★ → 3★, etc.
	_try_merge(data, 1)

		
func _squash_unit_instances(data: ChampionData) -> void:
	# Keep exactly ONE instance of this unit 
	var indices: Array[int] = []

	for i in owned_units.size():
		if owned_units[i] == data:
			indices.append(i)

	if indices.size() <= 1:
		return  

	indices.sort()  # ascending

	# Keep the first; remove all others (from end so indices don't shift)
	for j in range(indices.size() - 1, 0, -1):
		owned_units.remove_at(indices[j])



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

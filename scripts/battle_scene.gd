extends Control

@onready var player_row: HBoxContainer = $Board/PlayerRow
@onready var enemy_row: HBoxContainer = $Board/EnemyRow

@onready var gold_label: Label = $TopBar/Money/GoldLabel      
@onready var round_label: Label = $TopBar/RoundLabel 

var champion_scene: PackedScene = preload("res://scenes/champion.tscn")

var player_team: Array = []

@export var enemy_levels: Array[EnemyLevel] = []  
@export var enemy_team: Array[ChampionData]

var player_slots: Array = []
var enemy_slots: Array = []

func _ready() -> void:
	player_team = BattleContext.owned_units.duplicate()

	enemy_team = _get_current_enemy_team()
	var enemy_mult: float = _get_current_enemy_stat_multiplier()

	_spawn_row(player_row, player_team, 1.0, true)
	_spawn_row(enemy_row, enemy_team, enemy_mult, false)

	_cache_slots()
	_update_meta_ui()
	_start_battle()


func _start_battle() -> void:
	call_deferred("_run_battle")

func _run_battle() -> void:
	await get_tree().create_timer(0.4).timeout
	await _battle_loop_speed_based()

func _spawn_row(row: HBoxContainer, team: Array, stat_mult: float, is_player: bool) -> void:
	var count: int = min(team.size(), row.get_child_count())
	for i in count:
		var slot = row.get_child(i)
		if not slot.has_method("place_champion"):
			continue

		if is_player:
			var inst = team[i]              # UnitInstance
			var data: ChampionData = inst.data
			var star_level: int = inst.star
			slot.place_champion(champion_scene, data, stat_mult, star_level)
		else:
			var data_enemy: ChampionData = team[i]
			slot.place_champion(champion_scene, data_enemy, stat_mult, 1)



func _cache_slots() -> void:
	player_slots.clear()
	enemy_slots.clear()

	for child in player_row.get_children():
		if child.has_method("place_champion"):
			player_slots.append(child)

	for child in enemy_row.get_children():
		if child.has_method("place_champion"):
			enemy_slots.append(child)

	print("Cached slots -> player:", player_slots.size(), " enemy:", enemy_slots.size())

func _battle_loop_speed_based() -> void:
	while true:
		if _is_team_defeated(player_slots):
			_on_battle_end("enemy")
			return
		if _is_team_defeated(enemy_slots):
			_on_battle_end("player")
			return

		var actors: Array = _get_actors_in_speed_order()
		if actors.is_empty():
			print("No actors left, battle is a draw?")
			return

		for actor in actors:
			var champ: Champion = actor["champ"]
			var team: String = actor["team"]

			if champ == null or champ.is_dead():
				continue

			var defenders: Array = enemy_slots if team == "player" else player_slots

			var target: Champion = _get_closest_living_champion(champ, defenders)

			if target == null:
				if team == "player":
					_on_battle_end("player")
				else:
					_on_battle_end("enemy")
				return

			await champ.attack(target)

			await get_tree().create_timer(0.4).timeout

			if _is_team_defeated(defenders):
				if team == "player":
					_on_battle_end("player")
				else:
					_on_battle_end("enemy")
				return

func _get_actors_in_speed_order() -> Array:
	var actors: Array = []

	for slot in player_slots:
		if slot.champion != null \
		and slot.champion is Champion \
		and not slot.champion.is_dead():
			actors.append({
				"champ": slot.champion,
				"team": "player"
			})

	for slot in enemy_slots:
		if slot.champion != null \
		and slot.champion is Champion \
		and not slot.champion.is_dead():
			actors.append({
				"champ": slot.champion,
				"team": "enemy"
			})

	actors.sort_custom(Callable(self, "_compare_actor_speed"))
	return actors

func _compare_actor_speed(a: Dictionary, b: Dictionary) -> bool:
	var ca: Champion = a["champ"]
	var cb: Champion = b["champ"]

	if ca.speed == cb.speed:
		if a["team"] == b["team"]:
			return true
		return a["team"] == "player"

	return ca.speed > cb.speed

func _is_team_defeated(slots: Array) -> bool:
	for slot in slots:
		if slot.champion != null \
		and slot.champion is Champion \
		and not slot.champion.is_dead():
			return false
	return true

func _get_closest_living_champion(attacker: Champion, slots: Array) -> Champion:
	var best_target: Champion = null
	var best_dist_sq: float = INF

	for slot in slots:
		if slot.champion != null \
		and slot.champion is Champion \
		and not slot.champion.is_dead():

			var c: Champion = slot.champion
			var dist_sq := attacker.global_position.distance_squared_to(c.global_position)

			if dist_sq < best_dist_sq:
				best_dist_sq = dist_sq
				best_target = c

	return best_target
	
func _update_meta_ui() -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % BattleContext.gold
	if round_label:
		round_label.text = "Round: %d" % BattleContext.round

func _get_current_enemy_team() -> Array[ChampionData]:
	if enemy_levels.is_empty():
		return []

	var idx :int = clamp(BattleContext.round, 1, enemy_levels.size()) - 1
	var level: EnemyLevel = enemy_levels[idx]

	return level.enemies

func _get_current_enemy_stat_multiplier() -> float:
	if enemy_levels.is_empty():
		return 1.0
	var idx :int = clamp(BattleContext.round, 1, enemy_levels.size()) - 1
	return enemy_levels[idx].stat_multiplier




func _on_battle_end(winner: String) -> void:
	print("Battle over! Winner: ", winner)

	var player_won: bool = (winner == "player")
	BattleContext.apply_battle_result(player_won)

	_update_meta_ui()

	await get_tree().create_timer(1.0).timeout

	if BattleContext.game_won:
		get_tree().change_scene_to_file("res://scenes/victory_screen.tscn")
	elif BattleContext.game_lost:
		get_tree().change_scene_to_file("res://scenes/defeat_screen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Shop.tscn")

extends Control

@onready var player_row: HBoxContainer = $Board/PlayerRow
@onready var enemy_row: HBoxContainer = $Board/EnemyRow

var champion_scene: PackedScene = preload("res://scenes/Champion.tscn")

var player_team := [
	{"name":"Shieldbearer","hp":40,"pwr":8,"armor":3},
	{"name":"Archer","hp":25,"pwr":12,"armor":1},
	{"name":"Priest","hp":30,"pwr":4,"armor":1}
]

var enemy_team := [
	{"name":"Bandit","hp":28,"pwr":10,"armor":1},
	{"name":"Wizard","hp":22,"pwr":14,"armor":0},
	{"name":"Brute","hp":50,"pwr":6,"armor":4}
]

func _ready() -> void:
	_spawn_row(player_row, player_team)
	_spawn_row(enemy_row, enemy_team)

func _spawn_row(row: HBoxContainer, team: Array) -> void:
	var count : int = min(team.size(), row.get_child_count())
	for i in count:
		var slot = row.get_child(i)
		if slot.has_method("place_champion"):
			slot.place_champion(champion_scene, team[i])

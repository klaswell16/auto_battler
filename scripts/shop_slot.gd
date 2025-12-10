extends VBoxContainer
class_name ShopSlot

@onready var portrait_rect: TextureRect = $Portrait
@onready var name_label: Label = $NameLabel
@onready var cost_label: Label = $CostLabel
@onready var buy_button: Button = $BuyButton

var data: ChampionData
var cost: int = 0

signal buy_pressed(slot: ShopSlot, data: ChampionData, cost: int)


func _ready() -> void:
	if buy_button:
		buy_button.pressed.connect(_on_buy_button_pressed)

func set_offer(d: ChampionData) -> void:
	data = d
	if data == null:
		return

	cost = data.cost
	if portrait_rect and data.portrait_texture:
		portrait_rect.texture = data.portrait_texture

	if name_label:
		name_label.text = data.display_name

	if cost_label:
		cost_label.text = str(cost)

func _on_buy_button_pressed() -> void:
	if data == null:
		return
	# emit this slot along with the data
	emit_signal("buy_pressed", self, data, cost)

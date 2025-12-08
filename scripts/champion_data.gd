extends Resource
class_name ChampionData

@export var display_name: String = "Unit"
@export var max_hp: int = 30
@export var power: int = 8
@export var armor: int = 2
@export var speed: int = 10

@export var body_texture: Texture2D        # main in-battle sprite
@export var portrait_texture: Texture2D    # for your PortraitButton

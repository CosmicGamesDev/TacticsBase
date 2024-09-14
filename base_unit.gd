extends Sprite2D
class_name BaseUnit


@export var map : TileMap
@export var path_map : TileMap
@export var walkable : TileMap
@export var attack_map : TileMap

@onready var attack_icon = $AttackIcon
@onready var animation_player = $AnimationPlayer


var attack_range = 1
var move_range = 4

var is_moving = false
var mode = State.MOVE

enum State { MOVE, ATTACK }

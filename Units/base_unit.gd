extends Sprite2D
class_name BaseUnit

@onready var attack_icon = $AttackIcon
@onready var animation_player = $AnimationPlayer


var attack_range = 1
var move_range = 4

var is_moving = false
var mode = State.MOVE

var has_attacked = false
var has_moved = false

enum State { MOVE, ATTACK }

func reset_unit_turn():
	has_attacked = false
	has_moved = false



func _on_animation_player_animation_finished(anim_name):
	pass # Replace with function body.

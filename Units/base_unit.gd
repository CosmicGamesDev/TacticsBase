extends Sprite2D
class_name BaseUnit

@onready var attack_icon = $AttackIcon
@onready var animation_player = $AnimationPlayer
@onready var hp_icon_scene = preload("res://hp_icon.tscn")
@onready var enemy_hp_icon = preload("res://enemy_hp_icon.tscn")
@onready var hp_location = $HpLocation


var attack_damage = 1
var attack_range = 1
var move_range = 4
var base_hp = 3

var is_moving = false
var mode = State.MOVE

var has_attacked = false
var has_moved = false

enum State { MOVE, ATTACK }

func _ready():
	create_hp_icons()

func reset_unit_turn():
	has_attacked = false
	has_moved = false

func take_damage(damage):
	base_hp -= damage
	delete_hp_icons()
	if base_hp > 0:
		create_hp_icons()
	else:
		unit_died()

func unit_died():
	SignalBus.on_unit_died(self)
	queue_free()

func delete_hp_icons():
	var hp_icons = hp_location.get_children()
	for icon in hp_icons:
		icon.queue_free()

func create_hp_icons():
	for hp in range(base_hp):
		var hp_icon = null
		if is_in_group("enemy_unit"):
			hp_icon = enemy_hp_icon.instantiate()
		else:
			hp_icon = hp_icon_scene.instantiate()
		hp_location.add_child(hp_icon)
		hp_icon.position = hp_location.position + Vector2.RIGHT * hp * 5


func _on_animation_player_animation_finished(anim_name):
	pass # Replace with function body.

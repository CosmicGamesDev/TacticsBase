extends Node2D

@onready var attack_map = %AttackMap
@onready var path = %Path
@onready var objects = %Objects
@onready var effects = %Effects
@onready var units = %Units
@onready var a_star_grid = AStarGrid2D.new()
@onready var walkable = %Walkable
@onready var map = %Map

var path_points := PackedVector2Array()
var closest_enemy = null
var current_unit : BaseUnit
var player_units = []
var enemy_units = []
var current_unit_index = 0
var cell_size = Vector2i(8,8)

const DIRECTIONS = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

func _ready():
	player_units = get_tree().get_nodes_in_group("player_unit")
	enemy_units = get_tree().get_nodes_in_group("enemy_unit")
	current_unit = enemy_units[current_unit_index]
	a_star_grid.region = map.get_used_rect()
	a_star_grid.cell_size = cell_size
	a_star_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	a_star_grid.update()

func start():
	current_unit = enemy_units[0]
	enemy_move()

func move_to_location():
	walkable.clear()
	get_closest_enemy()
	if path_points[path_points.size()-1].x < current_unit.global_position.x:
		current_unit.flip_h = true
	else:
		current_unit.flip_h = false
	for point in path_points:
		current_unit.animation_player.play("walking")
		move_tween(point, current_unit)
		await get_tree().create_timer(.2).timeout
		if path_points.find(point) == path_points.size() - 1:
			path_points = PackedVector2Array()
			current_unit.mode = BaseUnit.State.ATTACK
			current_unit.animation_player.play("Idle")
			current_unit.has_moved = true
			enemy_attack()

func get_closest_enemy():
	if current_unit.mode == BaseUnit.State.MOVE:
		var distance_to_enemy = 1000
		for enemy in player_units:
			if closest_enemy == null || current_unit.global_position.distance_squared_to(enemy.global_position) < distance_to_enemy:
				distance_to_enemy = current_unit.global_position.distance_squared_to(enemy.global_position)
				closest_enemy = enemy
		var closest_tile = null
		var walkable_tiles = _flood_fill(current_unit.global_position/Vector2(8,8), current_unit.move_range)
		for unit in player_units:
			var index = walkable_tiles.find(unit.global_position as Vector2i/ Vector2i(8,8))
			if index != -1:
				walkable_tiles.pop_at(index)
		for unit in enemy_units:
			var index = walkable_tiles.find(unit.global_position as Vector2i/ Vector2i(8,8))
			if index != -1 && current_unit.global_position != unit.global_position:
				walkable_tiles.pop_at(index)
		for tile in walkable_tiles:
			if closest_tile == null || (closest_enemy.global_position/ Vector2(8,8)).distance_squared_to(tile) < \
			(closest_enemy.global_position/ Vector2(8,8)).distance_squared_to(closest_tile):
				closest_tile = tile
		if walkable_tiles.has(closest_tile):
			path_points = a_star_grid.get_point_path(current_unit.global_position/Vector2(8,8),closest_tile)


func move_tween(pos, unit):
	var tween = create_tween()
	await tween.tween_property(unit, "global_position", pos, 0.2)

func enemy_move():
	current_unit.mode = BaseUnit.State.MOVE
	move_to_location()


func enemy_attack():
	var attack_tiles = _flood_fill(current_unit.global_position/Vector2(8,8), current_unit.attack_range)
	var index = attack_tiles.find(current_unit.global_position as Vector2i/ Vector2i(8,8))
	current_unit.mode = BaseUnit.State.ATTACK
	attack_tiles.pop_at(index)
	if attack_tiles.has(closest_enemy.global_position as Vector2i/ Vector2i(8,8)):
		current_unit.animation_player.play("attack")
		closest_enemy.take_damage(current_unit.attack_damage)
		await current_unit.animation_player.animation_finished
		current_unit.animation_player.play("Idle")
	player_units = get_tree().get_nodes_in_group("player_unit")
	if player_units == []:
		print("Lose")
	else:
		$"../GameManager".start()

func _flood_fill(cell: Vector2i, max_distance: int) -> Array:
	var array := []
	var stack := [cell]
	var walkable_points = map.get_used_cells(1)
	while not stack.is_empty():
		var current = stack.pop_back()

		if current in array:
			continue

		var difference: Vector2i = (current - cell).abs()
		var distance := int(difference.x + difference.y)
		if distance > max_distance:
			continue

		array.append(current)
		for direction in DIRECTIONS:
			var coordinates: Vector2i = current + direction
			if coordinates in array:
				continue
			if !walkable_points.has(coordinates):
				continue
			stack.append(coordinates)
	return array

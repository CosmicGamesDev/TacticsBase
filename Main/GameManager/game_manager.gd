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

@export var current_unit : BaseUnit


const DIRECTIONS = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

func _ready():
	a_star_grid.region = map.get_used_rect()
	a_star_grid.cell_size = Vector2(8,8)
	a_star_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	a_star_grid.update()
	#map.set_cell(0,global_position/8,0,Vector2(0,0))
	move_mode()

func _input(event):
	if event.is_action_pressed('click') and current_unit.mode == BaseUnit.State.MOVE:
		var mouse_location = get_global_mouse_position()/Vector2(8,8) as Vector2i
		if walkable.get_used_cells(0).has(mouse_location):
			path_points = a_star_grid.get_point_path(current_unit.global_position/Vector2(8,8),mouse_location)
			move_to_location()
	if event.is_action_pressed('click') and current_unit.mode == BaseUnit.State.ATTACK:
		var mouse_location = get_global_mouse_position()/Vector2(8,8) as Vector2i
		if attack_map.get_used_cells(0).has(mouse_location):
			unit_attack()

func _process(delta):
	draw_path()
	draw_attack_icon()

func move_tween(pos, unit):
	var tween = create_tween()
	tween.tween_property(unit, "global_position", pos, 0.2)

func move_to_location():
	walkable.clear()
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
			attack_mode()

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
			#if is_occupied(coordinates):
				#continue
			if coordinates in array:
				continue
			if !walkable_points.has(coordinates):
				continue
			stack.append(coordinates)
	return array

func attack_mode():
	current_unit.attack_icon.show()
	var attack_tiles = _flood_fill(current_unit.global_position/8, current_unit.attack_range)
	for tile in attack_tiles:
		attack_map.set_cell(0,tile,0,Vector2(0,0))
	current_unit.mode = BaseUnit.State.ATTACK

func move_mode():
	var walkable_tiles = _flood_fill(current_unit.global_position/8, current_unit.move_range)
	for tile in walkable_tiles:
		walkable.set_cell(0,tile,0,Vector2(0,0))
	current_unit.mode = BaseUnit.State.MOVE

func draw_path():
	path.clear()
	var mouse_location = get_global_mouse_position() as Vector2i/Vector2i(8,8)
	if walkable.get_used_cells(0).has(mouse_location):
		var path_points = a_star_grid.get_point_path(current_unit.global_position/Vector2(8,8),mouse_location)
		for point in path_points:
			path.set_cell(0,point/8,0,Vector2i(0,0),0)

func draw_attack_icon():
	var mouse_location = get_global_mouse_position() as Vector2i/Vector2i(8,8)
	if attack_map.get_used_cells(0).has(mouse_location):
		current_unit.attack_icon.global_position = Vector2i( 
			roundi(mouse_location.x) * 8,
			roundi(mouse_location.y) * 8)

func unit_attack():
	attack_map.clear()
	current_unit.attack_icon.hide()
	print('attack')
	move_mode()

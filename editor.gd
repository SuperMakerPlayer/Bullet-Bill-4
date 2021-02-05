extends Node2D

const PLAYER_SCENE = "res://level_loader.tscn"
const ROOM_SCENE = "res://room.tscn"
const TYPE_WIDTHS = [
	16,
	32,
	48,
	64
]

var mode := 1

onready var rooms_node = $Rooms
onready var previews_node = $Previews
onready var delete_area = $DeleteArea

var current_room = 0
var current_room_node : Node2D

var flipped := false
var terrain_type := 0

var preview_disabled := false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Input.set_custom_mouse_cursor(load("res://misc/cursor_normal.png"))

	for preview in previews_node.get_children():
		preview.texture = load(CurrentLevelData.theme_textures[CurrentLevelData.level.theme])

	swap_rooms(current_room)

func swap_rooms(index):
	unload_room(index)
	
	current_room_node = load(ROOM_SCENE).instance()
	current_room_node.room_index = index
	
	load_room(current_room_node, index)

func unload_room(index):
	var room_node = rooms_node.get_node_or_null("Room_" + str(index))
	if is_instance_valid(room_node):
		room_node.queue_free()

func load_room(room, index):
	room.name = "Room_" + str(index)
	room.load_room()
	rooms_node.add_child(room)

func place_obstacle(obj_position : Vector2, type : int, is_flipped : bool):
	CurrentLevelData.level.rooms[current_room].obstacles.append([obj_position, type, is_flipped])
	current_room_node.load_room()
	
func delete_obstacle(index):
	CurrentLevelData.level.rooms[current_room].obstacles.remove(index)
	current_room_node.load_room()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed and !preview_disabled:
			var obstacle_pos = Vector2(
				round(get_global_mouse_position().x / 16),
				round(get_global_mouse_position().y / 16)
			)
			obstacle_pos = correct_mouse_pos(obstacle_pos)
			place_obstacle(obstacle_pos, terrain_type, flipped)
			
	elif event.is_action_pressed("switch_modes"):
		remove_child(current_room_node)
		get_tree().change_scene_to(load(PLAYER_SCENE))
		
	elif event.is_action_pressed("flip"):
		flipped = !flipped

	elif event.is_action_pressed("type_0"):
		terrain_type = 0

	elif event.is_action_pressed("type_1"):
		terrain_type = 1

	elif event.is_action_pressed("type_2"):
		terrain_type = 2

	elif event.is_action_pressed("type_3"):
		terrain_type = 3
	
	elif event.is_action_pressed("change_theme"):
		CurrentLevelData.level.theme = wrapi(CurrentLevelData.level.theme + 1, 0, CurrentLevelData.theme_textures.size())
		current_room_node.load_room()
		
		for preview in previews_node.get_children():
			preview.texture = load(CurrentLevelData.theme_textures[CurrentLevelData.level.theme])

func correct_mouse_pos(mouse_pos : Vector2):
	if mouse_pos.x < 0:
		mouse_pos.x = 0
	
	if (mouse_pos.x * 16) + TYPE_WIDTHS[terrain_type] > 416:
		mouse_pos.x = (416 - TYPE_WIDTHS[terrain_type]) / 16
	
	return mouse_pos

func _process(delta):
	var preview_node
	for preview in previews_node.get_children():
		if preview.name == "Type" + str(terrain_type):
			preview.visible = true
			preview_node = preview
		else:
			preview.visible = false
	
	var obstacle_pos = Vector2(
		round(get_global_mouse_position().x / 16),
		round(get_global_mouse_position().y / 16)
	)
	obstacle_pos = correct_mouse_pos(obstacle_pos)
	
	preview_disabled = false
	var obj_index = 0
	for obstacle in CurrentLevelData.level.rooms[current_room].obstacles:
		if (
			(obstacle[2] == flipped or 
				(((obstacle_pos.y + 1) > obstacle[0].y and flipped) or (obstacle_pos.y - 1) < obstacle[0].y and !flipped))
		):			
			for index in range(terrain_type + 1):
				if (obstacle_pos.x + index == obstacle[0].x):
					preview_disabled = true
					
			for index in range(obstacle[1] + 1):
				if (obstacle_pos.x - index == obstacle[0].x):
					preview_disabled = true
		obj_index += 1
	
	if preview_disabled:
		preview_node.modulate = Color(1, 0.25, 0.25, 0.5)
	else:
		preview_node.modulate = Color(1, 1, 1, 0.5)
	preview_node.scale.y = 1 if !flipped else -1
	preview_node.position = obstacle_pos * 16
	
	if flipped:
		preview_node.position.y += 16
	
	delete_area.position = get_global_mouse_position()
	if Input.is_action_just_pressed("delete_obstacle"):
		for obstacle in delete_area.get_overlapping_bodies():
			delete_obstacle(obstacle.get_parent().index)

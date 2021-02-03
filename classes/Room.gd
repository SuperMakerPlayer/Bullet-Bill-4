extends Node2D

const BOUNDS = Vector2(26, 15)
var obstacles := []
var obstacle_data := []

func _initdie():
	obstacle_data = [
		[Vector2(3, 12), 1, false],
		[Vector2(3, 6), 1, true],
		
		[Vector2(9, 8), 3, false],
		[Vector2(9, 2), 3, true],
		
		[Vector2(18, 10), 1, false],
		[Vector2(18, 4), 1, true]
	]

func obstacle_data_to_nodes():
	obstacles.clear()

	for data in obstacle_data:
		var new_obstacle = Obstacle.new()
		new_obstacle.type = data[1]
		new_obstacle.position = data[0]
		new_obstacle.flipped = data[2]
		
		obstacles.append(new_obstacle)

func load_room():
	obstacle_data_to_nodes()
	create_obstacles()
	
func create_obstacles():
	var index = 0
	
	for obstacle in obstacles:
		obstacle.height = obstacle.determine_height(BOUNDS.y)
		
		var obstacle_node = obstacle.return_node()
		obstacle_node.position = obstacle.position * 16
		obstacle_node.set_height(obstacle.height)
		if obstacle.flipped:
			obstacle_node.flip()
		obstacle_node.name = "Obstacle_" + str(index)
		add_child(obstacle_node)
		index += 1

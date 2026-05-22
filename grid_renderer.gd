class_name GridRenderer extends Node2D

const CELL_SIZE: int = 64
const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 12
const GRID_COLOR: Color = Color(0.1, 0.5, 0.2, 0.3) # Verde terminal holográfico

func _ready() -> void:
	# Força a execução do método _draw() no momento em que o nó entra na árvore
	queue_redraw()

func _draw() -> void:
	# Eixo X
	for x in range(GRID_WIDTH + 1):
		var start = Vector2(x * CELL_SIZE, 0)
		var end = Vector2(x * CELL_SIZE, GRID_HEIGHT * CELL_SIZE)
		draw_line(start, end, GRID_COLOR, 1.5)
		
	# Eixo Y
	for y in range(GRID_HEIGHT + 1):
		var start = Vector2(0, y * CELL_SIZE)
		var end = Vector2(GRID_WIDTH * CELL_SIZE, y * CELL_SIZE)
		draw_line(start, end, GRID_COLOR, 1.5)

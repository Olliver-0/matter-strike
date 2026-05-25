class_name GridRenderer extends Node2D

const CELL_SIZE: int = 64
const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 12
const GRID_COLOR: Color = Color(0.1, 0.5, 0.2, 0.3) # Verde terminal holográfico
const TEXT_COLOR: Color = Color(0.1, 0.8, 0.2, 0.8) # Opacidade aumentada para leitura

func _ready() -> void:
	# Eleva a camada de renderização deste nó. 
	# Assim, o texto do grid será desenhado POR CIMA do chão vermelho e dos personagens.
	z_index = 10 
	queue_redraw()

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 16 # Fonte ligeiramente maior para facilitar a visualização

	# ==========================================
	# 1. DESENHO DO EIXO X (Linhas Verticais e Números)
	# ==========================================
	for x in range(GRID_WIDTH + 1):
		var start = Vector2(x * CELL_SIZE, 0)
		var end = Vector2(x * CELL_SIZE, GRID_HEIGHT * CELL_SIZE)
		draw_line(start, end, GRID_COLOR, 1.5)
		
		# Plota o número logo acima do chão vermelho (Y ajustado de +20 para -8)
		if x < GRID_WIDTH:
			var text_pos_x = Vector2((x * CELL_SIZE) + 24, (GRID_HEIGHT * CELL_SIZE) - 8)
			draw_string(font, text_pos_x, str(x), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TEXT_COLOR)
		
	# ==========================================
	# 2. DESENHO DO EIXO Y (Linhas Horizontais e Números)
	# ==========================================
	for y in range(GRID_HEIGHT + 1):
		var start = Vector2(0, y * CELL_SIZE)
		var end = Vector2(GRID_WIDTH * CELL_SIZE, y * CELL_SIZE)
		draw_line(start, end, GRID_COLOR, 1.5)
		
		if y < GRID_HEIGHT:
			# TRADUTOR CARTESIANO VISUAL: O topo(0) vira 11, o chão(11) vira 0
			var cartesian_y = (GRID_HEIGHT - 1) - y 
			
			var text_pos_y = Vector2(8, (y * CELL_SIZE) + 36)
			draw_string(font, text_pos_y, str(cartesian_y), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TEXT_COLOR)

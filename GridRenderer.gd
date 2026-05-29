## DESCRIÇÃO: Responsável por desenhar as linhas verdes holográficas 
## e os números cartesianos por cima do mapa em tempo de execução.
class_name GridRenderer extends Node2D

# ==========================================
# 1. CONSTANTES E REFERÊNCIAS VISUAIS
# ==========================================

const GRID_COLOR: Color = Color(0.1, 0.5, 0.2, 0.3) 
const TEXT_COLOR: Color = Color(0.1, 0.8, 0.2, 0.8) 


# ==========================================
# 2. CICLO DE VIDA E INICIALIZAÇÃO
# ==========================================

func _ready() -> void:
	# Eleva a camada de renderização para desenhar POR CIMA do cenário
	z_index = 10 
	queue_redraw()


# ==========================================
# 3. MOTOR DE RENDERIZAÇÃO (Desenho Nativo)
# ==========================================

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 16 

	# --- 1. DESENHO DO EIXO X (Linhas Verticais e Números) ---
	for x in range(GameState.GRID_WIDTH + 1):
		# Tipagem forte adicionada aqui (: Vector2)
		var start: Vector2 = Vector2(x * GameState.CELL_SIZE, 0)
		var end: Vector2 = Vector2(x * GameState.CELL_SIZE, GameState.GRID_HEIGHT * GameState.CELL_SIZE)
		draw_line(start, end, GRID_COLOR, 1.5)
		
		if x < GameState.GRID_WIDTH:
			var text_pos_x: Vector2 = Vector2((x * GameState.CELL_SIZE) + 24, (GameState.GRID_HEIGHT * GameState.CELL_SIZE) - 8)
			draw_string(font, text_pos_x, str(x), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TEXT_COLOR)
		
	# --- 2. DESENHO DO EIXO Y (Linhas Horizontais e Números Invertidos) ---
	for y in range(GameState.GRID_HEIGHT + 1):
		var start: Vector2 = Vector2(0, y * GameState.CELL_SIZE)
		var end: Vector2 = Vector2(GameState.GRID_WIDTH * GameState.CELL_SIZE, y * GameState.CELL_SIZE)
		draw_line(start, end, GRID_COLOR, 1.5)
		
		if y < GameState.GRID_HEIGHT:
			var cartesian_y: int = (GameState.GRID_HEIGHT - 1) - y 
			var text_pos_y: Vector2 = Vector2(8, (y * GameState.CELL_SIZE) + 36)
			draw_string(font, text_pos_y, str(cartesian_y), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TEXT_COLOR)
			

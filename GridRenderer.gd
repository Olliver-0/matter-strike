## DESCRIÇÃO: Responsável por desenhar as linhas verdes holográficas,
## os números cartesianos, o indicador da célula selecionada / ponto de pouso
## e a parábola prevista do disparo por cima do mapa em tempo de execução.
class_name GridRenderer extends Node2D

# ==========================================
# 1. CONSTANTES E REFERÊNCIAS VISUAIS
# ==========================================

const GRID_COLOR: Color = Color(0.1, 0.5, 0.2, 0.3) 
const TEXT_COLOR: Color = Color(0.1, 0.8, 0.2, 0.8) 

const LANDING_VALID_COLOR: Color = Color(0.25, 0.95, 0.55, 0.92)
const LANDING_INVALID_COLOR: Color = Color(0.95, 0.32, 0.24, 0.85)


# ==========================================
# 2. ESTADO DE PRÉ-VISUALIZAÇÃO TÁTICA
# ==========================================

var _has_selection: bool = false
var _selected_cell: Vector2i = Vector2i(-1, -1)
var _can_land: bool = false
var _landing_cell: Vector2i = Vector2i(-1, -1)
var _landing_foot_pos: Vector2 = Vector2.ZERO
var _trajectory_points: PackedVector2Array = PackedVector2Array()
var _accent_color: Color = Color(1.0, 0.5, 0.0, 1.0)


# ==========================================
# 3. CICLO DE VIDA E API PÚBLICA
# ==========================================

func _ready() -> void:
	# Eleva a camada de renderização para desenhar POR CIMA do cenário
	z_index = 10 
	queue_redraw()


func set_tactical_preview(
	selected_cell: Vector2i,
	can_land: bool,
	landing_cell: Vector2i,
	landing_foot_pos: Vector2,
	trajectory_points: PackedVector2Array,
	accent_color: Color
) -> void:
	_has_selection = true
	_selected_cell = selected_cell
	_can_land = can_land
	_landing_cell = landing_cell
	_landing_foot_pos = landing_foot_pos
	_trajectory_points = trajectory_points
	_accent_color = accent_color
	queue_redraw()


func clear_preview() -> void:
	if not _has_selection and _trajectory_points.is_empty():
		return
	_has_selection = false
	_selected_cell = Vector2i(-1, -1)
	_can_land = false
	_landing_cell = Vector2i(-1, -1)
	_landing_foot_pos = Vector2.ZERO
	_trajectory_points = PackedVector2Array()
	queue_redraw()


# ==========================================
# 4. MOTOR DE RENDERIZAÇÃO (Desenho Nativo)
# ==========================================

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 16 

	# --- 1. DESENHO DO EIXO X (Linhas Verticais e Números) ---
	for x in range(GameState.GRID_WIDTH + 1):
		var start: Vector2 = Vector2(x * GameState.CELL_SIZE, 0)
		var end: Vector2 = Vector2(x * GameState.CELL_SIZE, GameState.GRID_HEIGHT * GameState.CELL_SIZE)
		draw_line(start, end, GRID_COLOR, 1.5)
		
		if x < GameState.GRID_WIDTH:
			var text_pos_x: Vector2 = Vector2((x * GameState.CELL_SIZE) + 24, 24)
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

	# --- 3. PRÉ-VISUALIZAÇÃO DA CÉLULA SELECIONADA E POUSO ---
	if _has_selection:
		_draw_selection_and_landing(font)

	# --- 4. PRÉ-VISUALIZAÇÃO DA PARÁBOLA DE DISPARO ---
	if _trajectory_points.size() >= 2:
		_draw_trajectory_parabola()


func _cell_to_rect(cell: Vector2i) -> Rect2:
	var inv_y: int = (GameState.GRID_HEIGHT - 1) - cell.y
	var cs: float = float(GameState.CELL_SIZE)
	return Rect2(cell.x * cs, inv_y * cs, cs, cs)


func _draw_corner_brackets(rect: Rect2, color: Color, length: float = 14.0, width: float = 3.0) -> void:
	var tl: Vector2 = rect.position
	var tr: Vector2 = Vector2(rect.end.x, rect.position.y)
	var bl: Vector2 = Vector2(rect.position.x, rect.end.y)
	var br: Vector2 = rect.end
	
	# Top-Left
	draw_line(tl, tl + Vector2(length, 0), color, width)
	draw_line(tl, tl + Vector2(0, length), color, width)
	# Top-Right
	draw_line(tr, tr + Vector2(-length, 0), color, width)
	draw_line(tr, tr + Vector2(0, length), color, width)
	# Bottom-Left
	draw_line(bl, bl + Vector2(length, 0), color, width)
	draw_line(bl, bl + Vector2(0, -length), color, width)
	# Bottom-Right
	draw_line(br, br + Vector2(-length, 0), color, width)
	draw_line(br, br + Vector2(0, -length), color, width)


func _draw_selection_and_landing(font: Font) -> void:
	var in_bounds: bool = (
		_selected_cell.x >= 0 and _selected_cell.x < GameState.GRID_WIDTH
		and _selected_cell.y >= 0 and _selected_cell.y < GameState.GRID_HEIGHT
	)
	if not in_bounds:
		return
		
	var sel_rect: Rect2 = _cell_to_rect(_selected_cell)
	var sel_center: Vector2 = sel_rect.get_center()
	var frame_color: Color = _accent_color if _can_land else LANDING_INVALID_COLOR
	
	# Preenchimento translúcido e moldura do quadrado digitado
	var fill_col := Color(frame_color.r, frame_color.g, frame_color.b, 0.18)
	draw_rect(sel_rect, fill_col, true)
	draw_rect(sel_rect, Color(frame_color.r, frame_color.g, frame_color.b, 0.55), false, 1.5)
	_draw_corner_brackets(sel_rect, Color(frame_color.r, frame_color.g, frame_color.b, 0.95), 14.0, 3.0)
	
	# Pequena mira central no quadrado alvo
	var cross_col := Color(1.0, 0.96, 0.85, 0.85)
	draw_line(sel_center + Vector2(-7, 0), sel_center + Vector2(7, 0), cross_col, 1.5)
	draw_line(sel_center + Vector2(0, -7), sel_center + Vector2(0, 7), cross_col, 1.5)
	draw_arc(sel_center, 4.5, 0.0, TAU, 16, cross_col, 1.2)
	
	# Rótulo discreto com as coordenadas no canto superior do quadrado
	var coord_tag: String = "[%02d,%02d]" % [_selected_cell.x, _selected_cell.y]
	draw_string(font, sel_rect.position + Vector2(5, 14), coord_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.05, 0.03, 0.01, 0.9))
	draw_string(font, sel_rect.position + Vector2(4, 13), coord_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.95, 0.82, 0.95))
	
	if _can_land:
		var land_rect: Rect2 = _cell_to_rect(_landing_cell)
		# Se o jogador digitou uma célula acima da plataforma, mostra linha vertical até o piso de pouso
		if _landing_cell != _selected_cell:
			draw_dashed_line(
				Vector2(sel_center.x, sel_rect.end.y),
				Vector2(sel_center.x, _landing_foot_pos.y - 8.0),
				Color(LANDING_VALID_COLOR.r, LANDING_VALID_COLOR.g, LANDING_VALID_COLOR.b, 0.65),
				2.0,
				6.0
			)
			draw_rect(land_rect, Color(LANDING_VALID_COLOR.r, LANDING_VALID_COLOR.g, LANDING_VALID_COLOR.b, 0.14), true)
			_draw_corner_brackets(land_rect, LANDING_VALID_COLOR, 11.0, 2.5)
		
		# Marcador físico na superfície exata da plataforma onde os pés pousam
		var pad_half_w: float = 20.0
		var pad_y: float = _landing_foot_pos.y
		var pad_x: float = _landing_foot_pos.x
		draw_line(Vector2(pad_x - pad_half_w, pad_y), Vector2(pad_x + pad_half_w, pad_y), Color(0.05, 0.08, 0.04, 0.9), 5.0)
		draw_line(Vector2(pad_x - pad_half_w, pad_y), Vector2(pad_x + pad_half_w, pad_y), LANDING_VALID_COLOR, 2.6)
		
		# Seta pequena apontando para o ponto de pouso
		var tip := Vector2(pad_x, pad_y - 3.0)
		var chevron := PackedVector2Array([
			tip + Vector2(-6.0, -7.0),
			tip + Vector2(6.0, -7.0),
			tip
		])
		draw_colored_polygon(chevron, LANDING_VALID_COLOR)
	else:
		# Indica visualmente que não há piso válido para teletransporte neste quadrado
		draw_string(font, sel_rect.position + Vector2(5, sel_rect.size.y - 5), "SEM PISO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.08, 0.02, 0.02, 0.9))
		draw_string(font, sel_rect.position + Vector2(4, sel_rect.size.y - 6), "SEM PISO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.52, 0.44, 0.95))


func _draw_trajectory_parabola() -> void:
	var total: int = _trajectory_points.size()
	
	# Linha suave translúcida conectando o arco inteiro
	var line_col := Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.34)
	draw_polyline(_trajectory_points, line_col, 2.2, true)
	
	# Pequeno anel indicando o ponto exato de saída do disparo (cano)
	draw_arc(_trajectory_points[0], 5.5, 0.0, TAU, 16, Color(0.08, 0.05, 0.02, 0.85), 3.0)
	draw_arc(_trajectory_points[0], 5.5, 0.0, TAU, 16, Color(1.0, 0.96, 0.86, 0.95), 1.6)
	
	# Pontos luminosos espaçados ao longo da parábola (com contorno escuro para destaque)
	for i in range(1, total):
		var progress: float = float(i) / float(max(1, total - 1))
		var alpha: float = lerpf(0.95, 0.35, progress)
		var radius: float = lerpf(3.4, 2.0, progress)
		var pt: Vector2 = _trajectory_points[i]
		
		draw_circle(pt, radius + 1.2, Color(0.06, 0.04, 0.02, alpha * 0.75))
		draw_circle(pt, radius, Color(_accent_color.r, _accent_color.g, _accent_color.b, alpha))
		if i % 2 == 0:
			draw_circle(pt, radius * 0.45, Color(1.0, 0.98, 0.9, alpha * 0.85))

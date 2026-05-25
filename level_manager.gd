extends Node

# Captura os atores, a interface, a calculadora e o chão!
@onready var engineer1 = $Engineer1
@onready var engineer2 = $Engineer2
@onready var terminal_ui = $TerminalUI
@onready var hud = $HUD
@onready var calculator = $BallisticsCalculator
@onready var ground: ColorRect = $Ground 

var is_shooting: bool = false 

func _ready() -> void:
	# Ligações originais
	terminal_ui.move_command_issued.connect(_on_terminal_command_issued)
	terminal_ui.end_turn_requested.connect(_on_end_turn_requested)
	GameState.turn_changed.connect(_on_turn_changed)
	terminal_ui.fire_command_issued.connect(_on_terminal_fire_issued)
	calculator.turn_resolved.connect(_on_projectile_resolved)
	engineer1.health_changed.connect(hud.update_health)
	engineer2.health_changed.connect(hud.update_health)
	
	# ==========================================
	# LIGAÇÕES DA PRÉ-VISUALIZAÇÃO DE CUSTO (Tópico 3)
	# ==========================================
	terminal_ui.preview_move_requested.connect(_on_preview_move)
	hud.preview_shot_requested.connect(_on_preview_shot)
	
	_create_floor_collision()
	
	# Força a interface a mostrar o custo do tiro logo que o jogo abre
	_on_preview_shot(hud.mass_slider.value)


func _create_floor_collision() -> void:
	var static_body = StaticBody2D.new()
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	
	rect_shape.size = ground.size
	collision_shape.shape = rect_shape
	collision_shape.position = ground.size / 2.0 
	
	static_body.add_child(collision_shape)
	ground.add_child(static_body)


# ==========================================
# CÁLCULOS DE PRÉ-VISUALIZAÇÃO (PREVIEW)
# ==========================================

func _on_preview_move(x_str: String, y_str: String) -> void:
	# Se a caixa estiver vazia ou com letras inválidas, o custo é zero
	if x_str.is_empty() or y_str.is_empty() or not x_str.is_valid_int() or not y_str.is_valid_int():
		terminal_ui.set_move_cost(0)
		return
		
	var target_x = int(x_str)
	var target_y = int(y_str)
	var active_engineer = engineer1 if GameState.current_turn == 1 else engineer2
	
	var delta_x: int = int(abs(target_x - active_engineer.logical_position.x))
	var delta_y: int = int(abs(target_y - active_engineer.logical_position.y))
	var cost: int = (delta_x * 1) + (delta_y * 2) 
	
	terminal_ui.set_move_cost(cost)

func _on_preview_shot(mass_value: float) -> void:
	var cost = int(calculator.calculate_energy_cost(mass_value))
	terminal_ui.set_fire_cost(cost)


# ==========================================
# COMANDOS DE AÇÃO
# ==========================================

func _on_terminal_command_issued(target_x: int, target_y: int) -> void:
	if is_shooting: return 
	
	var nova_coordenada = Vector2(target_x, target_y)
	if GameState.current_turn == 1: engineer1.attempt_move(nova_coordenada)
	elif GameState.current_turn == 2: engineer2.attempt_move(nova_coordenada)

func _on_terminal_fire_issued(target_x: int, target_y: int) -> void:
	if is_shooting: return 
	
	var current_player_id = GameState.current_turn
	var active_engineer = engineer1 if current_player_id == 1 else engineer2
	
	var input_type: String = hud.last_edited
	var final_value: float = hud.mass_slider.value if input_type == "MASS" else hud.volume_slider.value
	
	var mass_to_shoot = final_value
	if input_type == "VOLUME":
		mass_to_shoot = final_value * MaterialsTable.get_current_properties()["density"]
		
	var energy_cost: int = int(calculator.calculate_energy_cost(mass_to_shoot))
	
	if GameState.consume_energy(current_player_id, energy_cost):
		is_shooting = true 
		print(">>> INICIANDO CÁLCULO BALÍSTICO... Custo: ", energy_cost, " UE")
		var cell_size = 64
		var grid_height = 12
		var inverted_target_y = (grid_height - 1) - target_y
		var target_pos = Vector2((target_x * cell_size) + (cell_size / 2.0), (inverted_target_y * cell_size) + (cell_size / 2.0))
		calculator.dispatch_shot(active_engineer, target_pos, input_type, final_value)
	else:
		print(">>> ERRO: Energia insuficiente para propulsão desta massa.")

func _on_projectile_resolved() -> void:
	is_shooting = false 
	GameState.end_turn()

func _on_end_turn_requested() -> void:
	if is_shooting: return 
	GameState.end_turn()

func _on_turn_changed(new_turn: int) -> void:
	print("--- TURNO PASSADO! Agora é a vez do Jogador: ", new_turn, " ---")
	# Recalcula a distância do novo jogador para o que já estava digitado no X/Y
	_on_preview_move(terminal_ui.input_x.text, terminal_ui.input_y.text)

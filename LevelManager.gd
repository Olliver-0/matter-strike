## DESCRIÇÃO: Orquestrador principal da partida. 
## Coordena o fluxo de turnos, gerencia a comunicação entre os nós de jogo (Mundo) 
## e os nós de interface (UI), além de aplicar as regras de consumo de energia para ações.
extends Node

# ==========================================
# 1. TRAVAS E VARIÁVEIS DE ESTADO
# ==========================================

var is_shooting: bool = false 
var is_game_over: bool = false # <--- NOVO: Trava principal de fim de jogo

# ==========================================
# 2. REFERÊNCIAS DA ÁRVORE DE CENA
# ==========================================

@onready var engineer1: StaticBody2D = $World/Engineer1
@onready var engineer2: StaticBody2D = $World/Engineer2
@onready var ground: ColorRect = $World/Ground 

@onready var terminal_ui: Control = $UI/TerminalUI
@onready var hud: CanvasLayer = $UI/HUD

@onready var calculator: Node2D = $Systems/BallisticsCalculator


# ==========================================
# 3. CICLO DE VIDA (Inicialização)
# ==========================================

func _ready() -> void:
	terminal_ui.move_command_issued.connect(_on_terminal_command_issued)
	terminal_ui.end_turn_requested.connect(_on_end_turn_requested)
	terminal_ui.fire_command_issued.connect(_on_terminal_fire_issued)
	
	terminal_ui.preview_move_requested.connect(_on_preview_move)
	terminal_ui.preview_shot_requested.connect(_on_preview_shot)
	
	GameState.turn_changed.connect(_on_turn_changed)
	calculator.turn_resolved.connect(_on_projectile_resolved)
	
	engineer1.health_changed.connect(hud.update_health)
	engineer2.health_changed.connect(hud.update_health)
	
	# --- NOVO: O Orquestrador agora escuta se alguém morrer ---
	engineer1.died.connect(_on_engineer_died)
	engineer2.died.connect(_on_engineer_died)
	
	_on_preview_shot(terminal_ui.mass_slider.value)


# ==========================================
# 4. MÉTODOS PRIVADOS / INTERNOS
# ==========================================

func _get_logical_floor(target_x: int, target_y: int) -> int:
	if target_x < 0 or target_x >= GameState.GRID_WIDTH:
		return -1
	if target_x == 0 or target_x == 1:
		return -1 
		
	if (target_x >= 10 and target_x <= 13) and target_y >= 9: return 9
	if (target_x >= 10 and target_x <= 15) and target_y >= 8: return 8
	if (target_x >= 5 and target_x <= 9) and target_y >= 7: return 7
	if (target_x >= 7 and target_x <= 8) and target_y >= 6: return 6
	if (target_x >= 9 and target_x <= 17) and target_y >= 6: return 6
		
	return 4

# ==========================================
# 5. RESPOSTAS A SINAIS: PRÉ-VISUALIZAÇÃO (PREVIEW)
# ==========================================

func _on_preview_move(x_str: String, y_str: String) -> void:
	if is_game_over: return # Previne atualizar UI se o jogo acabou
	
	if x_str.is_empty() or y_str.is_empty() or not x_str.is_valid_int() or not y_str.is_valid_int():
		terminal_ui.set_move_cost(0)
		return
		
	var target_x := int(x_str)
	var target_y := int(y_str)
	var active_engineer = engineer1 if GameState.current_turn == 1 else engineer2
	
	var delta_x: int = int(abs(target_x - active_engineer.logical_position.x))
	var delta_y: int = int(abs(target_y - active_engineer.logical_position.y))
	var cost: int = (delta_x * 1) + (delta_y * 2) 
	
	terminal_ui.set_move_cost(cost)

func _on_preview_shot(mass_value: float) -> void:
	if is_game_over: return
	var cost := int(calculator.calculate_energy_cost(mass_value))
	terminal_ui.set_fire_cost(cost)

# ==========================================
# 6. RESPOSTAS A SINAIS: COMANDOS DE AÇÃO
# ==========================================

func _on_terminal_command_issued(target_x: int, target_y: int) -> void:
	if is_shooting or is_game_over: return 
	
	var active_engineer = engineer1 if GameState.current_turn == 1 else engineer2
	var floor_y = _get_logical_floor(target_x, target_y)
	
	if floor_y == -1 or target_y < floor_y:
		print(">>> ERRO CRÍTICO: Rota inválida. Destino leva ao vazio ou ao interior maciço.")
		return
		
	var new_coordinate := Vector2(target_x, floor_y)
	active_engineer.attempt_move(new_coordinate)


func _on_terminal_fire_issued(target_x: int, target_y: int) -> void:
	if is_shooting or is_game_over: return 
		
	var current_player_id := GameState.current_turn
	var active_engineer = engineer1 if current_player_id == 1 else engineer2
	
	var input_type: String = terminal_ui.get_current_input_type()
	var final_value: float = terminal_ui.get_current_input_value()
	var mass_to_shoot := final_value
	
	if input_type == "VOLUME":
		mass_to_shoot = final_value * MaterialsTable.get_current_properties()["density"]
		
	var energy_cost := int(calculator.calculate_energy_cost(mass_to_shoot))
	
	if GameState.consume_energy(current_player_id, energy_cost):
		is_shooting = true 
		var inverted_target_y: int = (GameState.GRID_HEIGHT - 1) - target_y
		var target_pos := Vector2(
			(target_x * GameState.CELL_SIZE) + (GameState.CELL_SIZE / 2.0), 
			(inverted_target_y * GameState.CELL_SIZE) + (GameState.CELL_SIZE / 2.0)
		)
		await active_engineer.play_cast_sequence(target_pos.x)
		calculator.dispatch_shot(active_engineer, target_pos, input_type, final_value)
	else:
		push_warning(">>> ERRO: Energia insuficiente para propulsão desta massa.")

# ==========================================
# 7. ROTINAS DE ESTADO E GAME OVER
# ==========================================

func _on_projectile_resolved() -> void:
	# NOVO: Impede que o turno passe se alguém morreu no meio do impacto!
	if is_game_over:
		return 
		
	is_shooting = false 
	GameState.end_turn()

func _on_end_turn_requested() -> void:
	if is_shooting or is_game_over: return 
	GameState.end_turn()

func _on_turn_changed(new_turn: int) -> void:
	print("--- TURNO PASSADO! Agora é a vez do Jogador: ", new_turn, " ---")
	_on_preview_move(terminal_ui.input_x.text, terminal_ui.input_y.text)


## NOVO: Função chamada instantaneamente quando um personagem zera a vida
func _on_engineer_died(dead_player_id: int) -> void:
	is_game_over = true
	print(">>> LEVEL MANAGER DETECTOU MORTE: O jogo acabou!")
	
	# Se o 1 morreu, o 2 ganha.
	var winner_id: int = 2 if dead_player_id == 1 else 1
	
	# Busca a tela de GameOver na árvore e dispara a vitória
	if has_node("GameOverUI"):
		$GameOverUI.show_victory(winner_id)
	elif has_node("UI/GameOverUI"):
		$UI/GameOverUI.show_victory(winner_id)
	else:
		push_error(">>> ERRO: Nó GameOverUI não encontrado. Coloque a cena no mapa!")

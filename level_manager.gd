extends Node

# Captura os atores, a interface e a SUA calculadora
@onready var engineer1 = $Engineer1
@onready var engineer2 = $Engineer2
@onready var terminal_ui = $TerminalUI
@onready var hud = $HUD
@onready var calculator = $BallisticsCalculator # O SEU SISTEMA AQUI!

func _ready() -> void:
	terminal_ui.move_command_issued.connect(_on_terminal_command_issued)
	terminal_ui.end_turn_requested.connect(_on_end_turn_requested)
	GameState.turn_changed.connect(_on_turn_changed)
	
	# NOVAS CONEXÕES DO TIRO:
	terminal_ui.fire_command_issued.connect(_on_terminal_fire_issued)
	calculator.turn_resolved.connect(_on_projectile_resolved)

# --- SISTEMA DE MOVIMENTO (Do seu colega) ---
func _on_terminal_command_issued(target_x: int, target_y: int) -> void:
	var nova_coordenada = Vector2(target_x, target_y)
	if GameState.current_turn == 1: engineer1.attempt_move(nova_coordenada)
	elif GameState.current_turn == 2: engineer2.attempt_move(nova_coordenada)

# --- SISTEMA DE TIRO (Integração com a sua Calculadora) ---
func _on_terminal_fire_issued(target_x: int, target_y: int) -> void:
	var active_engineer = engineer1 if GameState.current_turn == 1 else engineer2
	
	# APAGUEM a linha que dizia 'var start_pos = ...'
	
	var cell_size = 64
	var target_pos = Vector2((target_x * cell_size) + (cell_size / 2.0), (target_y * cell_size) + (cell_size / 2.0))
	
	var input_type: String = hud.last_edited
	var final_value: float = 0.0
	
	if input_type == "MASS":
		final_value = hud.mass_slider.value
	else:
		final_value = hud.volume_slider.value
		
	print(">>> INICIANDO CÁLCULO BALÍSTICO...")
	
	# ENVIA O PERSONAGEM INTEIRO ('active_engineer') EM VEZ DA POSIÇÃO!
	calculator.dispatch_shot(active_engineer, target_pos, input_type, final_value)

# Quando a sua bala emite o sinal de que bateu ou sumiu
func _on_projectile_resolved() -> void:
	print("Impacto concluído! O turno foi passado automaticamente pela Física.")
	GameState.end_turn()

# --- SISTEMA DE TURNOS (Do seu colega) ---
func _on_end_turn_requested() -> void:
	GameState.end_turn()

func _on_turn_changed(new_turn: int) -> void:
	print("--- TURNO PASSADO! Agora é a vez do Jogador: ", new_turn, " ---")

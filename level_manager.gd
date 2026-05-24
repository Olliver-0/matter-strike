extends Node

# Captura os dois atores e o painel
@onready var engineer1 = $Engineer1
@onready var engineer2 = $Engineer2
@onready var terminal_ui = $TerminalUI

func _ready() -> void:
	# Escuta as ordens do terminal
	terminal_ui.move_command_issued.connect(_on_terminal_command_issued)
	terminal_ui.end_turn_requested.connect(_on_end_turn_requested)
	
	# Escuta o estado do jogo (Opcional: imprime no ecrã de quem é a vez)
	GameState.turn_changed.connect(_on_turn_changed)

func _on_terminal_command_issued(target_x: int, target_y: int) -> void:
	var nova_coordenada = Vector2(target_x, target_y)
	
	# LÓGICA DE TURNO: Pergunta ao GameState de quem é a vez [cite: 52]
	if GameState.current_turn == 1:
		print("Léo (Jogador 1) a iniciar manobra.")
		engineer1.attempt_move(nova_coordenada)
	elif GameState.current_turn == 2:
		print("Sophie (Jogador 2) a iniciar manobra.")
		engineer2.attempt_move(nova_coordenada)

func _on_end_turn_requested() -> void:
	# Manda o Singleton global virar o turno e recarregar energia [cite: 229, 232]
	GameState.end_turn()

func _on_turn_changed(new_turn: int) -> void:
	print("--- TURNO PASSADO! Agora é a vez do Jogador: ", new_turn, " ---")

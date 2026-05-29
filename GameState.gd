## DESCRIÇÃO: Autoload (Singleton) que gerencia o estado global da partida.
## Controla o fluxo de turnos, a economia de Unidades de Energia (UE) dos jogadores
## e mantém as constantes universais (como as proporções matemáticas do grid).
extends Node

# ==========================================
# 1. SINAIS (Comunicação Externa)
# ==========================================

## Emitido quando a rodada muda, informando qual é o ID do novo jogador ativo.
signal turn_changed(active_player_id: int)

## Emitido sempre que a energia de qualquer jogador é gasta ou recuperada.
signal energy_updated(player_id: int, new_energy_amount: int)


# ==========================================
# 2. CONSTANTES GLOBAIS
# ==========================================

## Limite máximo de energia que um jogador pode acumular na sua bateria.
const MAX_ENERGY: int = 100

# --- Geometria do Plano Cartesiano ---
const CELL_SIZE: int = 64
const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 12


# ==========================================
# 3. VARIÁVEIS DE ESTADO
# ==========================================

## Define de quem é a vez atual (1 para Léo, 2 para Sophie).
var current_turn: int = 1

## Dicionário que armazena a quantidade de energia atual de cada jogador.
var players_energy: Dictionary = {
	1: MAX_ENERGY,
	2: MAX_ENERGY
}


# ==========================================
# 4. MÉTODOS PÚBLICOS (API do Estado)
# ==========================================

## Tenta subtrair um valor da energia do jogador alvo.
## Retorna 'true' se o jogador tinha energia suficiente e a transação foi aprovada.
func consume_energy(player_id: int, amount: int) -> bool:
	if players_energy[player_id] >= amount:
		players_energy[player_id] -= amount
		energy_updated.emit(player_id, players_energy[player_id])
		return true
	return false


## Alterna o jogador ativo e aplica a regra de economia tática (recarga parcial de energia).
func end_turn() -> void:
	# Troca o turno (se é 1, vira 2; se é 2, vira 1)
	current_turn = 2 if current_turn == 1 else 1
	
	# Dá uma "mesada" fixa de +50 UE no início do turno, valorizando o gerenciamento
	add_energy(current_turn, 50) 
	
	turn_changed.emit(current_turn)


## Adiciona energia ao jogador de forma segura, travando no limite máximo permitido.
func add_energy(player_id: int, amount: int) -> void:
	var nova_energia: int = players_energy[player_id] + amount
	players_energy[player_id] = clampi(nova_energia, 0, MAX_ENERGY)
	energy_updated.emit(player_id, players_energy[player_id])


## Purga os dados da partida atual, restaurando os turnos e a energia para o estado inicial.
func reset_state() -> void:
	current_turn = 1
	players_energy = {
		1: MAX_ENERGY,
		2: MAX_ENERGY
	}
	

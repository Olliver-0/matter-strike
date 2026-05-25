extends Node
# GameState.gd (Autoload global)

signal turn_changed(active_player_id: int)
signal energy_updated(player_id: int, new_energy_amount: int)

const MAX_ENERGY: int = 100 #

var current_turn: int = 1
var players_energy: Dictionary = {
	1: MAX_ENERGY,
	2: MAX_ENERGY
}

func consume_energy(player_id: int, amount: int) -> bool:
	if players_energy[player_id] >= amount:
		players_energy[player_id] -= amount
		energy_updated.emit(player_id, players_energy[player_id])
		return true
	return false

func end_turn() -> void:
	current_turn = 2 if current_turn == 1 else 1
	
	# ==========================================
	# REBALANCEAMENTO DA ECONOMIA DE ENERGIA (Tópico 4)
	# Em vez de restaurar 100% da energia, damos uma "mesada" de 50 UE por turno.
	# A função 'add_energy' já tem uma trava (clampi) para não passar do MAX_ENERGY.
	# ==========================================
	add_energy(current_turn, 50) 
	
	turn_changed.emit(current_turn)
	# (Apagámos a linha que forçava a emissão do MAX_ENERGY)

func add_energy(player_id: int, amount: int) -> void:
	players_energy[player_id] = clampi(players_energy[player_id] + amount, 0, MAX_ENERGY)
	energy_updated.emit(player_id, players_energy[player_id])

func reset_state() -> void:
	current_turn = 1
	players_energy = {
		1: MAX_ENERGY,
		2: MAX_ENERGY
	}

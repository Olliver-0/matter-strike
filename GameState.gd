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
	players_energy[current_turn] = MAX_ENERGY # Recarrega no início da rodada
	turn_changed.emit(current_turn)
	energy_updated.emit(current_turn, MAX_ENERGY)

func add_energy(player_id: int, amount: int) -> void:
	players_energy[player_id] = clampi(players_energy[player_id] + amount, 0, MAX_ENERGY)
	energy_updated.emit(player_id, players_energy[player_id])

func reset_state() -> void:
	current_turn = 1
	players_energy = {
		1: MAX_ENERGY,
		2: MAX_ENERGY
	}

## DESCRIÇÃO: Controla a interface passiva de sobreposição (Heads-Up Display).
## Gerencia barras independentes de Vida e Energia para cada personagem.
class_name HUD extends CanvasLayer

# ==========================================
# 1. REFERÊNCIAS DA INTERFACE (UI Nodes)
# ==========================================

@onready var turn_feedback: Label = $TurnFeedback

# --- UI do Léo ---
@onready var leo_hp_bar: ProgressBar = $LeoUI/HPBar
@onready var leo_energy_bar: ProgressBar = $LeoUI/EnergyBar

# --- UI da Sophie ---
@onready var sophie_hp_bar: ProgressBar = $SophieUI/HPBar
@onready var sophie_energy_bar: ProgressBar = $SophieUI/EnergyBar


# ==========================================
# 2. CICLO DE VIDA E INICIALIZAÇÃO
# ==========================================

func _ready() -> void:
	# 1. Conecta aos sinais globais do GameState
	GameState.energy_updated.connect(_on_energy_updated)
	GameState.turn_changed.connect(_on_turn_changed)
	
	# 2. Inicialização das Barras de Vida (HP)
	leo_hp_bar.max_value = 100.0
	leo_hp_bar.value = 100.0
	sophie_hp_bar.max_value = 100.0
	sophie_hp_bar.value = 100.0
	
	# 3. Inicialização das Barras de Energia
	# Supondo que a energia máxima base no GDD seja 10 (Ajuste se for outro valor)
	leo_energy_bar.max_value = 100.0 
	sophie_energy_bar.max_value = 100.0
	
	# Puxa o estado atual direto da memória global
	leo_energy_bar.value = GameState.players_energy[1]
	sophie_energy_bar.value = GameState.players_energy[2]
	
	_on_turn_changed(GameState.current_turn)


# ==========================================
# 3. MÉTODOS PÚBLICOS (API / Injeção de Dano)
# ==========================================

## Atualiza a barra de HP do jogador especificado ao receber dano.
func update_health(player_id: int, new_health: float) -> void:
	if player_id == 1:
		leo_hp_bar.value = new_health
	elif player_id == 2:
		sophie_hp_bar.value = new_health


# ==========================================
# 4. MÉTODOS PRIVADOS (Reações ao GameState)
# ==========================================

## Redireciona o novo valor de energia para a barra do personagem correto.
func _on_energy_updated(player_id: int, new_energy_amount: int) -> void:
	if player_id == 1:
		leo_energy_bar.value = new_energy_amount
	elif player_id == 2:
		sophie_energy_bar.value = new_energy_amount

## Destaca o nome de quem está jogando no momento no topo da tela.
func _on_turn_changed(active_player_id: int) -> void:
	if active_player_id == 1:
		turn_feedback.text = "SISTEMA ATIVO: LÉO"
		turn_feedback.modulate = Color(1.0, 0.5, 0.0) # Laranja
	else:
		turn_feedback.text = "SISTEMA ATIVO: SOPHIE"
		turn_feedback.modulate = Color(0.04, 0.74, 0.81) # Ciano

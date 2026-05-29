## DESCRIÇÃO: Controla a interface principal de sobreposição (Heads-Up Display).
## Gerencia a exibição de vida, energia, turnos e permite a manipulação de massa
## e volume respeitando a física (d=m/V) configurada no banco de materiais.
class_name HUD extends CanvasLayer

# ==========================================
# 1. SINAIS (Comunicação Externa)
# ==========================================

## Emitido sempre que o jogador ajusta as barras de massa/volume, enviando a nova massa.
signal preview_shot_requested(mass_value: float)

# ==========================================
# 2. REFERÊNCIAS DA INTERFACE (UI Nodes)
# ==========================================

# --- Controles de Matéria ---
@onready var mass_slider: HSlider = $MassSlider
@onready var volume_slider: HSlider = $VolumeSlider
@onready var material_dropdown: OptionButton = $MaterialDropdown

# --- Textos e Rótulos ---
@onready var mass_label: Label = $MassLabel
@onready var volume_label: Label = $VolumeLabel
@onready var turn_feedback: Label = $TurnFeedback

# --- Barras de Status ---
@onready var leo_hp_bar: ProgressBar = $LeoHPBar
@onready var sophie_hp_bar: ProgressBar = $SophieHPBar
@onready var energy_bar: ProgressBar = $EnergyBar

# ==========================================
# 3. VARIÁVEIS DE ESTADO
# ==========================================

## Armazena qual foi a última barra ajustada pelo jogador ("MASS" ou "VOLUME").
var last_edited: String = "MASS" 

# ==========================================
# 4. CICLO DE VIDA E INICIALIZAÇÃO
# ==========================================

func _ready() -> void:
	# 1. Preenche o Dropdown com os materiais do banco de dados global
	material_dropdown.clear()
	for mat_name in MaterialsTable.MATERIALS.keys():
		material_dropdown.add_item(mat_name)
		
	# 2. Conecta os botões e barras da UI aos métodos locais
	material_dropdown.item_selected.connect(_on_material_selected)
	mass_slider.value_changed.connect(_on_mass_changed)
	volume_slider.value_changed.connect(_on_volume_changed)
	
	# 3. Força a primeira atualização para configurar os limites matemáticos
	_update_limits_and_bars()
	
	# 4. Conecta aos sinais globais do GameState
	GameState.energy_updated.connect(_on_energy_updated)
	GameState.turn_changed.connect(_on_turn_changed)
	
	# 5. Inicialização visual padrão das barras de vida
	leo_hp_bar.max_value = 100.0
	leo_hp_bar.value = 100.0
	sophie_hp_bar.max_value = 100.0
	sophie_hp_bar.value = 100.0
	
	_on_turn_changed(GameState.current_turn)


# ==========================================
# 5. MÉTODOS PÚBLICOS (API / Getters)
# ==========================================

## Retorna se o jogador focou na Massa ou no Volume por último.
func get_current_input_type() -> String:
	return last_edited

## Retorna o valor numérico exato da barra que o jogador editou por último.
func get_current_input_value() -> float:
	if last_edited == "MASS":
		return mass_slider.value
	else:
		return volume_slider.value

## Atualiza a barra de HP do jogador especificado ao receber dano.
func update_health(player_id: int, new_health: float) -> void:
	if player_id == 1:
		leo_hp_bar.value = new_health
	elif player_id == 2:
		sophie_hp_bar.value = new_health


# ==========================================
# 6. MÉTODOS PRIVADOS DE UI E ESTADO GLOBAIS
# ==========================================

## Ajusta dinamicamente a barra de energia se o jogador alvo for o do turno atual.
func _on_energy_updated(player_id: int, new_energy_amount: int) -> void:
	if player_id == GameState.current_turn:
		energy_bar.value = new_energy_amount

## Atualiza feedback de texto, cor do rótulo e troca o valor da barra de energia.
func _on_turn_changed(active_player_id: int) -> void:
	energy_bar.value = GameState.players_energy[active_player_id]
	
	if active_player_id == 1:
		turn_feedback.text = "SISTEMA ATIVO: LÉO (Laranja)"
		turn_feedback.modulate = Color(1.0, 0.5, 0.0) 
	else:
		turn_feedback.text = "SISTEMA ATIVO: SOPHIE (Ciano)"
		turn_feedback.modulate = Color(0.04, 0.74, 0.81) 


# ==========================================
# 7. MÉTODOS DE CÁLCULO FÍSICO (MATÉRIA)
# ==========================================

## Troca a densidade global baseando-se na seleção do Dropdown e reajusta as barras.
func _on_material_selected(index: int) -> void:
	var selected_mat: String = material_dropdown.get_item_text(index)
	MaterialsTable.current_material = selected_mat
	_update_limits_and_bars()

## Recalcula o mínimo e o máximo permitido para as barras respeitando a nova densidade.
func _update_limits_and_bars() -> void:
	var density: float = MaterialsTable.get_current_properties()["density"]
	
	volume_slider.min_value = 10.0
	volume_slider.max_value = 100.0
	
	mass_slider.min_value = volume_slider.min_value * density
	mass_slider.max_value = volume_slider.max_value * density
	
	if last_edited == "MASS":
		_on_mass_changed(mass_slider.value)
	else:
		_on_volume_changed(volume_slider.value)

## Transmuta a alteração de massa em volume usando d=m/V de forma silenciosa (sem loop).
func _on_mass_changed(value: float) -> void:
	last_edited = "MASS"
	var density: float = MaterialsTable.get_current_properties()["density"]
	var calculated_volume: float = value / density
	
	volume_slider.set_value_no_signal(calculated_volume)
	_update_texts(value, calculated_volume)

## Transmuta a alteração de volume em massa usando d=m/V de forma silenciosa.
func _on_volume_changed(value: float) -> void:
	last_edited = "VOLUME"
	var density: float = MaterialsTable.get_current_properties()["density"]
	var calculated_mass: float = value * density
	
	mass_slider.set_value_no_signal(calculated_mass)
	_update_texts(calculated_mass, value)

## Formata os números textuais na tela e emite o sinal para calcular o custo de energia.
func _update_texts(m_val: float, v_val: float) -> void:
	mass_label.text = "Massa: " + str(snapped(m_val, 0.1)) + " kg"
	volume_label.text = "Volume: " + str(snapped(v_val, 0.1)) + " m³"
	
	preview_shot_requested.emit(m_val)

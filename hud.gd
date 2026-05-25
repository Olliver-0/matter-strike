extends CanvasLayer

@onready var mass_slider: HSlider = $MassSlider
@onready var volume_slider: HSlider = $VolumeSlider
@onready var material_dropdown: OptionButton = $MaterialDropdown

@onready var mass_label: Label = $MassLabel
@onready var volume_label: Label = $VolumeLabel

# --- NOVAS REFERÊNCIAS (Essenciais para evitar erros de variável inexistente) ---
@onready var leo_hp_bar: ProgressBar = $LeoHPBar
@onready var sophie_hp_bar: ProgressBar = $SophieHPBar
@onready var energy_bar: ProgressBar = $EnergyBar
@onready var turn_feedback: Label = $TurnFeedback

# Guardamos o que o jogador tocou por último para avisar a Calculadora
var last_edited: String = "MASS" 

func _ready() -> void:
	# 1. Preenche o Dropdown com os materiais do banco de dados
	material_dropdown.clear()
	for mat_name in MaterialsTable.MATERIALS.keys():
		material_dropdown.add_item(mat_name)
		
	# 2. Conecta os botões e barras às funções
	material_dropdown.item_selected.connect(_on_material_selected)
	mass_slider.value_changed.connect(_on_mass_changed)
	volume_slider.value_changed.connect(_on_volume_changed)
	
	# 3. Força a primeira atualização para configurar os limites
	_update_limits_and_bars()
	
	# --- ASSINATURA DE SINAIS GLOBAIS E INICIALIZAÇÃO VISUAL ---
	GameState.energy_updated.connect(_on_energy_updated)
	GameState.turn_changed.connect(_on_turn_changed)
	
	leo_hp_bar.max_value = 100
	leo_hp_bar.value = 100
	sophie_hp_bar.max_value = 100
	sophie_hp_bar.value = 100
	_on_turn_changed(GameState.current_turn)

func _on_material_selected(index: int) -> void:
	var selected_mat = material_dropdown.get_item_text(index)
	MaterialsTable.current_material = selected_mat
	_update_limits_and_bars()

func _update_limits_and_bars() -> void:
	var density = MaterialsTable.get_current_properties()["density"]
	
	volume_slider.min_value = 10.0
	volume_slider.max_value = 100.0
	
	mass_slider.min_value = volume_slider.min_value * density
	mass_slider.max_value = volume_slider.max_value * density
	
	if last_edited == "MASS":
		_on_mass_changed(mass_slider.value)
	else:
		_on_volume_changed(volume_slider.value)

func _on_mass_changed(value: float) -> void:
	last_edited = "MASS"
	var density = MaterialsTable.get_current_properties()["density"]
	var calculated_volume = value / density
	
	volume_slider.set_value_no_signal(calculated_volume)
	_update_texts(value, calculated_volume)

func _on_volume_changed(value: float) -> void:
	last_edited = "VOLUME"
	var density = MaterialsTable.get_current_properties()["density"]
	var calculated_mass = value * density
	
	mass_slider.set_value_no_signal(calculated_mass)
	_update_texts(calculated_mass, value)

func _update_texts(m_val: float, v_val: float) -> void:
	mass_label.text = "Massa: " + str(snapped(m_val, 0.1)) + " kg"
	volume_label.text = "Volume: " + str(snapped(v_val, 0.1)) + " m³"

# ==========================================
# NOVAS FUNÇÕES DE CALLBACK (Listeners)
# ==========================================

func update_health(player_id: int, new_health: float) -> void:
	if player_id == 1:
		leo_hp_bar.value = new_health
	elif player_id == 2:
		sophie_hp_bar.value = new_health

func _on_energy_updated(player_id: int, new_energy_amount: int) -> void:
	if player_id == GameState.current_turn:
		energy_bar.value = new_energy_amount

func _on_turn_changed(active_player_id: int) -> void:
	energy_bar.value = GameState.players_energy[active_player_id]
	
	if active_player_id == 1:
		turn_feedback.text = "SISTEMA ATIVO: LÉO (Laranja)"
		turn_feedback.modulate = Color(1.0, 0.5, 0.0) # Cor tema do Léo
	else:
		turn_feedback.text = "SISTEMA ATIVO: SOPHIE (Ciano)"
		turn_feedback.modulate = Color(0.04, 0.74, 0.81) # Cor tema da Sophie

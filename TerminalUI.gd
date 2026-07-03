## DESCRIÇÃO: Controla a interface do terminal de comandos do jogador.
## Capta a inserção de coordenadas cartesianas (X, Y), botões de ação, exibe 
## o custo de energia em tempo real (Preview) e manipula a física (Matéria).
class_name TerminalUI extends Control

# ==========================================
# 1. SINAIS (Comunicação Externa)
# ==========================================

signal move_command_issued(target_x: int, target_y: int)
signal fire_command_issued(target_x: int, target_y: int)
signal end_turn_requested()
signal preview_move_requested(target_x_str: String, target_y_str: String)

## Emitido sempre que o jogador ajusta as barras de massa/volume.
signal preview_shot_requested(mass_value: float)


# ==========================================
# 2. REFERÊNCIAS DA INTERFACE (UI Nodes)
# ==========================================

# --- Caixas de Entrada (Inputs) ---
@onready var input_x: LineEdit = $InputX
@onready var input_y: LineEdit = $InputY

# --- Botões de Ação ---
@onready var btn_move: Button = $BtnMove
@onready var btn_fire: Button = $BtnFire
@onready var btn_end_turn: Button = $BtnEndTurn
@onready var btn_restart: Button = $BtnRestart

# --- Textos de Feedback (Custos) ---
@onready var lbl_move_cost: Label = $LblMoveCost
@onready var lbl_fire_cost: Label = $LblFireCost

# --- Controles de Matéria (Migrados do HUD) ---
@onready var mass_slider: HSlider = $MassSlider
@onready var volume_slider: HSlider = $VolumeSlider
@onready var material_dropdown: OptionButton = $MaterialDropdown
@onready var mass_label: Label = $MassLabel
@onready var volume_label: Label = $VolumeLabel


# ==========================================
# 3. VARIÁVEIS DE ESTADO
# ==========================================

## Armazena qual foi a última barra ajustada pelo jogador ("MASS" ou "VOLUME").
var last_edited: String = "MASS" 


# ==========================================
# 4. CICLO DE VIDA E INICIALIZAÇÃO
# ==========================================

func _ready() -> void:
	# Liga os botões às suas respetivas funções de validação interna
	btn_move.pressed.connect(_on_btn_move_pressed)
	btn_fire.pressed.connect(_on_btn_fire_pressed)
	btn_end_turn.pressed.connect(_on_btn_end_turn_pressed)
	btn_restart.pressed.connect(_on_btn_restart_pressed)
	
	# Liga o evento de digitação ao sistema de Preview
	input_x.text_changed.connect(_on_text_changed)
	input_y.text_changed.connect(_on_text_changed)
	
	# Preenche o Dropdown com os materiais do banco de dados global
	if material_dropdown:
		material_dropdown.clear()
		for mat_name in MaterialsTable.MATERIALS.keys():
			material_dropdown.add_item(mat_name)
			
	# Conecta as barras físicas aos métodos locais
	if material_dropdown: material_dropdown.item_selected.connect(_on_material_selected)
	if mass_slider: mass_slider.value_changed.connect(_on_mass_changed)
	if volume_slider: volume_slider.value_changed.connect(_on_volume_changed)
	
	# Força a primeira atualização para configurar os limites matemáticos
	_update_limits_and_bars()


# ==========================================
# 5. MÉTODOS PÚBLICOS (API / Setters & Getters)
# ==========================================

func set_move_cost(cost: int) -> void:
	if lbl_move_cost:
		lbl_move_cost.text = "Custo: " + str(cost) + " UE"

func set_fire_cost(cost: int) -> void:
	if lbl_fire_cost:
		lbl_fire_cost.text = "Custo: " + str(cost) + " UE"

## Retorna se o jogador focou na Massa ou no Volume por último.
func get_current_input_type() -> String:
	return last_edited

## Retorna o valor numérico exato da barra que o jogador editou por último.
func get_current_input_value() -> float:
	if last_edited == "MASS" and mass_slider:
		return mass_slider.value
	elif volume_slider:
		return volume_slider.value
	return 0.0


# ==========================================
# 6. CALLBACKS DE COORDENADAS E AÇÃO
# ==========================================

func _on_text_changed(_new_text: String) -> void:
	preview_move_requested.emit(input_x.text, input_y.text)

func _on_btn_move_pressed() -> void:
	if input_x.text.is_empty() or input_y.text.is_empty():
		return
	move_command_issued.emit(int(input_x.text), int(input_y.text))
	_clear_inputs()

func _on_btn_fire_pressed() -> void:
	if input_x.text.is_empty() or input_y.text.is_empty():
		return
	fire_command_issued.emit(int(input_x.text), int(input_y.text))
	_clear_inputs()

func _on_btn_end_turn_pressed() -> void:
	end_turn_requested.emit()

func _on_btn_restart_pressed() -> void:
	GameState.reset_state()
	get_tree().reload_current_scene()

func _clear_inputs() -> void:
	input_x.text = ""
	input_y.text = ""
	preview_move_requested.emit("", "")


# ==========================================
# 7. MÉTODOS DE CÁLCULO FÍSICO (MATÉRIA)
# ==========================================

func _on_material_selected(index: int) -> void:
	var selected_mat: String = material_dropdown.get_item_text(index)
	MaterialsTable.current_material = selected_mat
	_update_limits_and_bars()

func _update_limits_and_bars() -> void:
	if not volume_slider or not mass_slider: return
	
	var density: float = MaterialsTable.get_current_properties()["density"]
	
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
	var density: float = MaterialsTable.get_current_properties()["density"]
	var calculated_volume: float = value / density
	
	if volume_slider: volume_slider.set_value_no_signal(calculated_volume)
	_update_texts(value, calculated_volume)

func _on_volume_changed(value: float) -> void:
	last_edited = "VOLUME"
	var density: float = MaterialsTable.get_current_properties()["density"]
	var calculated_mass: float = value * density
	
	if mass_slider: mass_slider.set_value_no_signal(calculated_mass)
	_update_texts(calculated_mass, value)

func _update_texts(m_val: float, v_val: float) -> void:
	if mass_label: mass_label.text = "Massa: " + str(snapped(m_val, 0.1)) + " kg"
	if volume_label: volume_label.text = "Volume: " + str(snapped(v_val, 0.1)) + " m³"
	
	preview_shot_requested.emit(m_val)

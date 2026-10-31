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
@onready var coord_display: Label = $CoordinateDisplay
@onready var numpad: GridContainer = $Numpad

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
@onready var btn_mat_cork: Button = get_node_or_null("BtnMatCork")
@onready var btn_mat_stone: Button = get_node_or_null("BtnMatStone")
@onready var btn_mat_iron: Button = get_node_or_null("BtnMatIron")
@onready var btn_mat_lead: Button = get_node_or_null("BtnMatLead")
@onready var mass_label: Label = $MassLabel
@onready var volume_label: Label = $VolumeLabel
@onready var shot_log: RichTextLabel = get_node_or_null("ShotLog")


# ==========================================
# 3. VARIÁVEIS DE ESTADO
# ==========================================

## Armazena qual foi a última barra ajustada pelo jogador ("MASS" ou "VOLUME").
var last_edited: String = "MASS" 

## Armazena as coordenadas digitadas (ex: "0509" -> X=05, Y=09)
var current_coord_input: String = ""

## Histórico de disparos realizados na partida.
var shot_history: Array[Dictionary] = []


# ==========================================
# 4. CICLO DE VIDA E INICIALIZAÇÃO
# ==========================================

func _ready() -> void:
	# Liga os botões às suas respetivas funções de validação interna
	btn_move.pressed.connect(_on_btn_move_pressed)
	btn_fire.pressed.connect(_on_btn_fire_pressed)
	btn_end_turn.pressed.connect(_on_btn_end_turn_pressed)
	btn_restart.pressed.connect(_on_btn_restart_pressed)
	
	# Liga os botões do numpad
	if numpad:
		for i in range(10):
			var btn = numpad.get_node_or_null("Btn" + str(i))
			if btn:
				btn.pressed.connect(_on_numpad_pressed.bind(str(i)))
		var btn_clear = numpad.get_node_or_null("BtnClear")
		if btn_clear:
			btn_clear.pressed.connect(_on_btn_clear_pressed)
			
	_update_coord_display()
	
	# Conecta os botões individuais de materiais
	var mat_buttons = {
		"CORTIÇA": btn_mat_cork,
		"PEDRA": btn_mat_stone,
		"FERRO": btn_mat_iron,
		"CHUMBO": btn_mat_lead
	}
	for mat_name in mat_buttons.keys():
		var btn: Button = mat_buttons[mat_name]
		if btn:
			btn.pressed.connect(_on_material_button_pressed.bind(mat_name))
			if mat_name == MaterialsTable.current_material:
				btn.button_pressed = true
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

## Retorna as coordenadas X e Y atuais digitadas (ou strings vazias caso incompletas).
func get_target_coords() -> Array[String]:
	if current_coord_input.length() == 4:
		return [current_coord_input.substr(0, 2), current_coord_input.substr(2, 2)]
	return ["", ""]

## Registra um novo disparo no painel de histórico (mais recente no topo).
func add_shot_log(shooter_id: int, material_name: String, input_type: String, final_mass: float, final_volume: float, target_x: int, target_y: int) -> void:
	var shooter_name: String = "Léo" if shooter_id == 1 else "Sophie"
	var mat_label: String = material_name.capitalize()
	var m_str: String = str(snapped(final_mass, 0.1))
	var v_str: String = str(snapped(final_volume, 0.1))
	
	var param_str: String = ""
	if input_type == "VOLUME":
		param_str = "Volume: %s (Massa: %s)" % [v_str, m_str]
	else:
		param_str = "Massa: %s (Vol: %s)" % [m_str, v_str]
		
	var entry: Dictionary = {
		"index": shot_history.size() + 1,
		"shooter": shooter_name,
		"shooter_id": shooter_id,
		"material": mat_label,
		"param_str": param_str,
		"coords": "[%d, %d]" % [target_x, target_y],
		"result": ""
	}
	shot_history.push_front(entry)
	_render_shot_log()

## Atualiza o resultado (impacto/dano ou erro) do disparo mais recente no log.
func update_last_shot_result(hit: bool, target_id: int, damage: float) -> void:
	if shot_history.is_empty():
		return
	if hit:
		var target_name: String = "Léo" if target_id == 1 else "Sophie"
		shot_history[0]["result"] = "[color=#e89a48]  ↳ Impacto em %s: -%s HP (+30 UE)[/color]" % [target_name, str(snapped(damage, 0.1))]
	else:
		shot_history[0]["result"] = "[color=#8c765c]  ↳ Sem impacto (fora dos limites)[/color]"
	_render_shot_log()

func _render_shot_log() -> void:
	if not shot_log:
		return
	if shot_history.is_empty():
		shot_log.text = "[color=#8c765c]Aguardando registros balísticos...[/color]"
		return
	var lines: PackedStringArray = []
	for item in shot_history:
		var name_color: String = "#f0a050" if item["shooter_id"] == 1 else "#78c8d0"
		var line: String = "[b][color=#ead2ac]DISPARO #%d:[/color][/b] [color=%s]%s[/color] -> %s, %s,\nCoord: %s" % [
			item["index"],
			name_color,
			item["shooter"],
			item["material"],
			item["param_str"],
			item["coords"]
		]
		if not item["result"].is_empty():
			line += "\n" + item["result"]
		lines.append(line)
	shot_log.text = "\n".join(lines)


# ==========================================
# 6. CALLBACKS DE COORDENADAS E AÇÃO
# ==========================================

func _on_numpad_pressed(digit: String) -> void:
	if current_coord_input.length() < 4:
		current_coord_input += digit
		_update_coord_display()

func _on_btn_clear_pressed() -> void:
	_clear_inputs()

func _update_coord_display() -> void:
	var disp = "["
	var x_str = "__"
	var y_str = "__"
	
	if current_coord_input.length() >= 1:
		x_str = current_coord_input.substr(0, 1) + "_"
	if current_coord_input.length() >= 2:
		x_str = current_coord_input.substr(0, 2)
	if current_coord_input.length() >= 3:
		y_str = current_coord_input.substr(2, 1) + "_"
	if current_coord_input.length() >= 4:
		y_str = current_coord_input.substr(2, 2)
		
	disp += x_str + ", " + y_str + "]"
	if coord_display:
		coord_display.text = disp
		
	# trigger preview
	if current_coord_input.length() == 4:
		preview_move_requested.emit(current_coord_input.substr(0, 2), current_coord_input.substr(2, 2))
	elif current_coord_input.length() == 0:
		preview_move_requested.emit("", "")

func _on_btn_move_pressed() -> void:
	if current_coord_input.length() < 4:
		return
	move_command_issued.emit(int(current_coord_input.substr(0, 2)), int(current_coord_input.substr(2, 2)))
	_clear_inputs()

func _on_btn_fire_pressed() -> void:
	if current_coord_input.length() < 4:
		return
	fire_command_issued.emit(int(current_coord_input.substr(0, 2)), int(current_coord_input.substr(2, 2)))
	_clear_inputs()

func _on_btn_end_turn_pressed() -> void:
	end_turn_requested.emit()

func _on_btn_restart_pressed() -> void:
	GameState.reset_state()
	get_tree().reload_current_scene()

func _clear_inputs() -> void:
	current_coord_input = ""
	_update_coord_display()


# ==========================================
# 7. MÉTODOS DE CÁLCULO FÍSICO (MATÉRIA)
# ==========================================

func _on_material_button_pressed(mat_name: String) -> void:
	MaterialsTable.current_material = mat_name
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

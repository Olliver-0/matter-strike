extends Control

signal move_command_issued(target_x: int, target_y: int)
signal fire_command_issued(target_x: int, target_y: int)
signal end_turn_requested()

# NOVO SINAL: Grita sempre que o jogador digita qualquer coisa nas caixas X ou Y
signal preview_move_requested(target_x_str: String, target_y_str: String)

@onready var input_x: LineEdit = $InputX
@onready var input_y: LineEdit = $InputY
@onready var btn_move: Button = $BtnMove
@onready var btn_end_turn: Button = $BtnEndTurn
@onready var btn_fire: Button = $BtnFire
@onready var btn_restart: Button = $BtnRestart

# NOVAS REFERÊNCIAS DOS TEXTOS
@onready var lbl_move_cost: Label = $LblMoveCost
@onready var lbl_fire_cost: Label = $LblFireCost

func _ready() -> void:
	btn_move.pressed.connect(_on_btn_move_pressed)
	btn_fire.pressed.connect(_on_btn_fire_pressed)
	btn_end_turn.pressed.connect(func(): end_turn_requested.emit())
	btn_restart.pressed.connect(_on_btn_restart_pressed)
	
	# Ouve quando o jogador digita e aciona a pré-visualização
	input_x.text_changed.connect(_on_text_changed)
	input_y.text_changed.connect(_on_text_changed)

func _on_text_changed(_new_text: String) -> void:
	preview_move_requested.emit(input_x.text, input_y.text)

func _on_btn_restart_pressed() -> void:
	GameState.reset_state()
	get_tree().reload_current_scene()

func _on_btn_move_pressed() -> void:
	if input_x.text.is_empty() or input_y.text.is_empty(): return
	move_command_issued.emit(int(input_x.text), int(input_y.text))
	_clear_inputs()

func _on_btn_fire_pressed() -> void:
	if input_x.text.is_empty() or input_y.text.is_empty(): return
	fire_command_issued.emit(int(input_x.text), int(input_y.text))
	_clear_inputs()

func _clear_inputs() -> void:
	input_x.text = ""
	input_y.text = ""
	preview_move_requested.emit("", "") # Zera o custo na tela ao limpar

# Funções públicas para o LevelManager injetar o custo calculado
func set_move_cost(cost: int) -> void:
	lbl_move_cost.text = "Custo: " + str(cost) + " UE"

func set_fire_cost(cost: int) -> void:
	lbl_fire_cost.text = "Custo: " + str(cost) + " UE"

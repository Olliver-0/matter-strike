extends Control

signal move_command_issued(target_x: int, target_y: int)
signal fire_command_issued(target_x: int, target_y: int)
signal end_turn_requested() # Novo sinal criado!

@onready var input_x: LineEdit = $InputX
@onready var input_y: LineEdit = $InputY
@onready var btn_move: Button = $BtnMove
@onready var btn_end_turn: Button = $BtnEndTurn # Referência ao novo botão
@onready var btn_fire: Button = $BtnFire

func _ready() -> void:
	btn_move.pressed.connect(_on_btn_move_pressed)
	btn_fire.pressed.connect(_on_btn_fire_pressed)
	# Conecta o clique do novo botão diretamente à emissão do sinal
	btn_end_turn.pressed.connect(func(): end_turn_requested.emit())

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

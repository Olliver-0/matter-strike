extends Control

signal move_command_issued(target_x: int, target_y: int)
signal end_turn_requested() # Novo sinal criado!

@onready var input_x: LineEdit = $InputX
@onready var input_y: LineEdit = $InputY
@onready var btn_move: Button = $BtnMove
@onready var btn_end_turn: Button = $BtnEndTurn # Referência ao novo botão

func _ready() -> void:
	btn_move.pressed.connect(_on_btn_move_pressed)
	# Conecta o clique do novo botão diretamente à emissão do sinal
	btn_end_turn.pressed.connect(func(): end_turn_requested.emit())

func _on_btn_move_pressed() -> void:
	if input_x.text.is_empty() or input_y.text.is_empty():
		print("Erro: Introduza os dois eixos!")
		return
		
	var x_val: int = int(input_x.text)
	var y_val: int = int(input_y.text)
	
	move_command_issued.emit(x_val, y_val)
	
	input_x.text = ""
	input_y.text = ""

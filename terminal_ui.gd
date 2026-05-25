extends Control

signal move_command_issued(target_x: int, target_y: int)
signal fire_command_issued(target_x: int, target_y: int)
signal end_turn_requested()

@onready var input_x: LineEdit = $InputX
@onready var input_y: LineEdit = $InputY
@onready var btn_move: Button = $BtnMove
@onready var btn_end_turn: Button = $BtnEndTurn
@onready var btn_fire: Button = $BtnFire
@onready var btn_restart: Button = $BtnRestart # NOVA REFERÊNCIA

func _ready() -> void:
	btn_move.pressed.connect(_on_btn_move_pressed)
	btn_fire.pressed.connect(_on_btn_fire_pressed)
	btn_end_turn.pressed.connect(func(): end_turn_requested.emit())
	
	btn_restart.pressed.connect(_on_btn_restart_pressed)

func _on_btn_restart_pressed() -> void:
	# Purga o estado global e recarrega a malha de objetos da cena
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

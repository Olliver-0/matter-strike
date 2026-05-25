extends Node

# Captura os atores, a interface, a calculadora e agora o chão!
@onready var engineer1 = $Engineer1
@onready var engineer2 = $Engineer2
@onready var terminal_ui = $TerminalUI
@onready var hud = $HUD
@onready var calculator = $BallisticsCalculator
@onready var ground: ColorRect = $Ground 

# ==========================================
# TRAVA DE ESTADO (State Lock)
# ==========================================
var is_shooting: bool = false # Impede que os jogadores cliquem em botões enquanto a bala voa

func _ready() -> void:
	terminal_ui.move_command_issued.connect(_on_terminal_command_issued)
	terminal_ui.end_turn_requested.connect(_on_end_turn_requested)
	GameState.turn_changed.connect(_on_turn_changed)
	
	terminal_ui.fire_command_issued.connect(_on_terminal_fire_issued)
	calculator.turn_resolved.connect(_on_projectile_resolved)
	
	engineer1.health_changed.connect(hud.update_health)
	engineer2.health_changed.connect(hud.update_health)
	
	# Transforma o ColorRect num "chão físico" na hora que o jogo inicia
	_create_floor_collision()

# Injeta a Física no Desenho Visual
func _create_floor_collision() -> void:
	var static_body = StaticBody2D.new()
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	
	# Copia exatamente a largura e altura do chão vermelho
	rect_shape.size = ground.size
	collision_shape.shape = rect_shape
	# Centraliza a hitbox perfeitamente em cima da cor
	collision_shape.position = ground.size / 2.0 
	
	static_body.add_child(collision_shape)
	ground.add_child(static_body)

# ==========================================
# INTEGRAÇÃO COM OS COMANDOS DOS JOGADORES
# ==========================================

func _on_terminal_command_issued(target_x: int, target_y: int) -> void:
	if is_shooting: return # Ignora movimento se a bala estiver voando
	
	var nova_coordenada = Vector2(target_x, target_y)
	if GameState.current_turn == 1: engineer1.attempt_move(nova_coordenada)
	elif GameState.current_turn == 2: engineer2.attempt_move(nova_coordenada)

func _on_terminal_fire_issued(target_x: int, target_y: int) -> void:
	if is_shooting: return # Ignora clique duplo no botão de atirar
	
	var current_player_id = GameState.current_turn
	var active_engineer = engineer1 if current_player_id == 1 else engineer2
	
	var input_type: String = hud.last_edited
	var final_value: float = hud.mass_slider.value if input_type == "MASS" else hud.volume_slider.value
	
	var mass_to_shoot = final_value
	if input_type == "VOLUME":
		mass_to_shoot = final_value * MaterialsTable.get_current_properties()["density"]
		
	var energy_cost: int = int(calculator.calculate_energy_cost(mass_to_shoot))
	
	if GameState.consume_energy(current_player_id, energy_cost):
		is_shooting = true # ATIVA A TRAVA DE SEGURANÇA
		print(">>> INICIANDO CÁLCULO BALÍSTICO... Custo: ", energy_cost, " UE")
		var cell_size = 64
		var target_pos = Vector2((target_x * cell_size) + (cell_size / 2.0), (target_y * cell_size) + (cell_size / 2.0))
		calculator.dispatch_shot(active_engineer, target_pos, input_type, final_value)
	else:
		print(">>> ERRO: Energia insuficiente para propulsão desta massa.")

func _on_projectile_resolved() -> void:
	is_shooting = false # DESTRAVA A SEGURANÇA (A bala explodiu no chão ou acertou alguém)
	print("Impacto concluído! O turno foi passado automaticamente pela Física.")
	GameState.end_turn()

func _on_end_turn_requested() -> void:
	if is_shooting: return # Impede passar o turno na mão enquanto a bala está caindo!
	GameState.end_turn()

func _on_turn_changed(new_turn: int) -> void:
	print("--- TURNO PASSADO! Agora é a vez do Jogador: ", new_turn, " ---")

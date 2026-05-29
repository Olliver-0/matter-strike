## DESCRIÇÃO: Orquestrador principal da partida. 
## Coordena o fluxo de turnos, gerencia a comunicação entre os nós de jogo (Mundo) 
## e os nós de interface (UI), além de aplicar as regras de consumo de energia para ações.
extends Node

# ==========================================
# 1. TRAVAS E VARIÁVEIS DE ESTADO
# ==========================================

## Impede que os jogadores realizem novas ações (mover/atirar) enquanto um projétil 
## está executando sua simulação física e trajetória pelo cenário.
var is_shooting: bool = false 

# ==========================================
# 2. REFERÊNCIAS DA ÁRVORE DE CENA
# ==========================================

# --- GRUPO: MUNDO DE JOGO (Nós dentro da "pasta" World) ---
@onready var engineer1: StaticBody2D = $World/Engineer1
@onready var engineer2: StaticBody2D = $World/Engineer2
@onready var ground: ColorRect = $World/Ground 

# --- GRUPO: INTERFACE DE USUÁRIO (Nós dentro da "pasta" UI) ---
@onready var terminal_ui: Control = $UI/TerminalUI
@onready var hud: CanvasLayer = $UI/HUD

# --- GRUPO: SISTEMAS CORE (Nós dentro da "pasta" Systems) ---
@onready var calculator: Node2D = $Systems/BallisticsCalculator


# ==========================================
# 3. CICLO DE VIDA (Inicialização)
# ==========================================

func _ready() -> void:
	# Conexões de Sinais vindos do Terminal (Inputs do jogador)
	terminal_ui.move_command_issued.connect(_on_terminal_command_issued)
	terminal_ui.end_turn_requested.connect(_on_end_turn_requested)
	terminal_ui.fire_command_issued.connect(_on_terminal_fire_issued)
	
	# Conexões de Sinais de Pré-Visualização de Custos (Atualização dinâmica do HUD)
	terminal_ui.preview_move_requested.connect(_on_preview_move)
	hud.preview_shot_requested.connect(_on_preview_shot)
	
	# Conexões de Sinais dos Sistemas Globais e Físicos
	GameState.turn_changed.connect(_on_turn_changed)
	calculator.turn_resolved.connect(_on_projectile_resolved)
	
	# Conecta a vida dos personagens ao HUD para atualizar as barras de HP
	engineer1.health_changed.connect(hud.update_health)
	engineer2.health_changed.connect(hud.update_health)
	
	# Inicializa a colisão do chão baseando-se no tamanho do ColorRect visual
	_create_floor_collision()
	
	# Força a interface a computar o custo inicial do tiro com base no Slider do HUD
	_on_preview_shot(hud.mass_slider.value)


# ==========================================
# 4. MÉTODOS PRIVADOS / INTERNOS
# ==========================================

## Gera dinamicamente um corpo físico estático (hitbox) acoplado ao ColorRect do chão 
## para garantir que os projéteis colidam na base visual do mapa.
func _create_floor_collision() -> void:
	var static_body := StaticBody2D.new()
	var collision_shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	
	# Clona as dimensões exatas definidas no ColorRect do editor
	rect_shape.size = ground.size
	collision_shape.shape = rect_shape
	
	# Centraliza a forma geométrica perfeitamente sobre o retângulo
	collision_shape.position = ground.size / 2.0 
	
	# Monta a hierarquia física dentro do nó Ground
	static_body.add_child(collision_shape)
	ground.add_child(static_body)


# ==========================================
# 5. RESPOSTAS A SINAIS: PRÉ-VISUALIZAÇÃO (PREVIEW)
# ==========================================

## Monitora o que o jogador está digitando no terminal em tempo real e calcula 
## o custo estimado em Unidades de Energia (UE) para locomoção.
func _on_preview_move(x_str: String, y_str: String) -> void:
	# Se os campos estiverem vazios ou conterem caracteres inválidos, zera a exibição de custo
	if x_str.is_empty() or y_str.is_empty() or not x_str.is_valid_int() or not y_str.is_valid_int():
		terminal_ui.set_move_cost(0)
		return
		
	var target_x := int(x_str)
	var target_y := int(y_str)
	
	# Determina qual engenheiro está operando no turno atual
	var active_engineer = engineer1 if GameState.current_turn == 1 else engineer2
	
	# Calcula a distância absoluta (Delta) entre a posição atual e o destino
	var delta_x: int = int(abs(target_x - active_engineer.logical_position.x))
	var delta_y: int = int(abs(target_y - active_engineer.logical_position.y))
	
	# Regra do GDD: 1 UE por bloco em X, 2 UE por bloco em Y
	var cost: int = (delta_x * 1) + (delta_y * 2) 
	
	# Injeta o valor calculado de volta no Label do terminal
	terminal_ui.set_move_cost(cost)


## Monitora o arrasto das barras de Massa/Volume no HUD e exibe no terminal 
## o custo energético que o disparo consumirá se for efetuado com esse peso.
func _on_preview_shot(mass_value: float) -> void:
	var cost := int(calculator.calculate_energy_cost(mass_value))
	terminal_ui.set_fire_cost(cost)


# ==========================================
# 6. RESPOSTAS A SINAIS: COMANDOS DE AÇÃO
# ==========================================

## Acionado quando o jogador clica para se mover. Valida o estado de trava do jogo 
## e repassa as novas coordenadas para o script interno do personagem ativo.
func _on_terminal_command_issued(target_x: int, target_y: int) -> void:
	if is_shooting: return 
	
	var new_coordinate := Vector2(target_x, target_y)
	if GameState.current_turn == 1: engineer1.attempt_move(new_coordinate)
	elif GameState.current_turn == 2: engineer2.attempt_move(new_coordinate)


## Acionado quando o comando de disparo é dado no terminal. Calcula a massa final, 
## cobra as Unidades de Energia do jogador e ativa a trava balística.
func _on_terminal_fire_issued(target_x: int, target_y: int) -> void:
	if is_shooting: return 
	
	var current_player_id := GameState.current_turn
	var active_engineer = engineer1 if current_player_id == 1 else engineer2
	
	# Usando o Encapsulamento Seguro do HUD!
	var input_type: String = hud.get_current_input_type()
	var final_value: float = hud.get_current_input_value()
	
	var mass_to_shoot := final_value
	if input_type == "VOLUME":
		mass_to_shoot = final_value * MaterialsTable.get_current_properties()["density"]
		
	var energy_cost := int(calculator.calculate_energy_cost(mass_to_shoot))
	
	if GameState.consume_energy(current_player_id, energy_cost):
		is_shooting = true 
		print(">>> INICIANDO CÁLCULO BALÍSTICO... Custo: ", energy_cost, " UE")
		
		# Removidos os Magic Numbers (var cell_size = 64 e var grid_height = 12)
		# Usando as variáveis globais agora!
		var inverted_target_y: int = (GameState.GRID_HEIGHT - 1) - target_y
		var target_pos := Vector2((target_x * GameState.CELL_SIZE) + (GameState.CELL_SIZE / 2.0), (inverted_target_y * GameState.CELL_SIZE) + (GameState.CELL_SIZE / 2.0))
		
		calculator.dispatch_shot(active_engineer, target_pos, input_type, final_value)
	else:
		print(">>> ERRO: Energia insuficiente para propulsão desta massa.")


## Chamado quando o projétil morre por colisão ou por fim de tempo de vida. 
## Libera as travas e força a passagem automática do turno do jogo.
func _on_projectile_resolved() -> void:
	is_shooting = false # Destrava a segurança para a próxima jogada
	GameState.end_turn()


## Força a passagem de turno manual caso o jogador decida abrir mão de suas ações restantes.
func _on_end_turn_requested() -> void:
	if is_shooting: return 
	GameState.end_turn()


## Escuta o evento global de virada de turno para atualizar as distâncias e custos exibidos
## na interface, readequando os números ao novo jogador ativo.
func _on_turn_changed(new_turn: int) -> void:
	print("--- TURNO PASSADO! Agora é a vez do Jogador: ", new_turn, " ---")
	# Recalcula a distância e atualiza os custos baseando-se nas caixas de texto que já estavam digitadas
	_on_preview_move(terminal_ui.input_x.text, terminal_ui.input_y.text)

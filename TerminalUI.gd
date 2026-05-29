## DESCRIÇÃO: Controla a interface do terminal de comandos do jogador.
## Capta a inserção de coordenadas cartesianas (X, Y), botões de ação e exibe 
## o custo de energia em tempo real (Preview) para o planeamento tático.
class_name TerminalUI extends Control

# ==========================================
# 1. SINAIS (Comunicação Externa)
# ==========================================

## Emitido quando o jogador ordena o movimento para uma nova célula.
signal move_command_issued(target_x: int, target_y: int)

## Emitido quando o jogador ordena o disparo de matéria nas coordenadas inseridas.
signal fire_command_issued(target_x: int, target_y: int)

## Emitido quando o jogador decide passar a vez voluntariamente.
signal end_turn_requested()

## Emitido a cada digitação para que o LevelManager calcule o custo de locomoção.
signal preview_move_requested(target_x_str: String, target_y_str: String)


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


# ==========================================
# 3. CICLO DE VIDA E INICIALIZAÇÃO
# ==========================================

func _ready() -> void:
	# Liga os botões às suas respetivas funções de validação interna
	btn_move.pressed.connect(_on_btn_move_pressed)
	btn_fire.pressed.connect(_on_btn_fire_pressed)
	btn_end_turn.pressed.connect(_on_btn_end_turn_pressed)
	btn_restart.pressed.connect(_on_btn_restart_pressed)
	
	# Liga o evento de digitação ao sistema de Preview (Custo em Tempo Real)
	input_x.text_changed.connect(_on_text_changed)
	input_y.text_changed.connect(_on_text_changed)


# ==========================================
# 4. MÉTODOS PÚBLICOS (API / Setters)
# ==========================================

## Atualiza o rótulo da interface com o custo energético estimado para o movimento.
func set_move_cost(cost: int) -> void:
	if lbl_move_cost:
		lbl_move_cost.text = "Custo: " + str(cost) + " UE"

## Atualiza o rótulo da interface com o custo energético estimado para o disparo.
func set_fire_cost(cost: int) -> void:
	if lbl_fire_cost:
		lbl_fire_cost.text = "Custo: " + str(cost) + " UE"


# ==========================================
# 5. MÉTODOS PRIVADOS (Callbacks da Interface)
# ==========================================

## Emite o sinal de Preview com o texto atual das caixas à medida que o jogador digita.
func _on_text_changed(_new_text: String) -> void:
	preview_move_requested.emit(input_x.text, input_y.text)

## Valida as caixas de texto e repassa a ordem de translação (movimento) ao orquestrador.
func _on_btn_move_pressed() -> void:
	if input_x.text.is_empty() or input_y.text.is_empty():
		return
		
	move_command_issued.emit(int(input_x.text), int(input_y.text))
	_clear_inputs()

## Valida as caixas de texto e emite a ordem de disparo balístico.
func _on_btn_fire_pressed() -> void:
	if input_x.text.is_empty() or input_y.text.is_empty():
		return
		
	fire_command_issued.emit(int(input_x.text), int(input_y.text))
	_clear_inputs()

## Informa ao orquestrador que o jogador abdicou de efetuar mais ações.
func _on_btn_end_turn_pressed() -> void:
	end_turn_requested.emit()

## Purga a memória de estados globais (GameState) e reinicia a árvore da partida a zeros.
func _on_btn_restart_pressed() -> void:
	GameState.reset_state()
	get_tree().reload_current_scene()

## Zera as caixas de texto visualmente e força o Preview a emitir "Strings vazias" 
## para que o LevelManager resete o texto de custo para 0 UE.
func _clear_inputs() -> void:
	input_x.text = ""
	input_y.text = ""
	preview_move_requested.emit("", "")

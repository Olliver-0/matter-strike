## DESCRIÇÃO: Representa os avatares manipuláveis no mapa (Léo ou Sophie).
## Lida com a interpolação visual e tradução do grid lógico (X, Y) para o espaço cartesiano.
class_name Engineer extends StaticBody2D

# ==========================================
# 1. SINAIS (Comunicação Externa)
# ==========================================

signal movement_resolved(final_coords: Vector2)
signal health_changed(player_id: int, new_health: float)

# ==========================================
# 2. EXPORTS E VARIÁVEIS DE ESTADO
# ==========================================

@export var player_id: int = 1
@export var theme_color: Color = Color(1.0, 0.5, 0.0) # Laranja para Léo, Ciano para Sophie
@export var logical_position: Vector2 = Vector2.ZERO

@onready var visual_body: ColorRect = $VisualBody
@onready var glow: PointLight2D = $EnergyGlow

var health: float = 100.0

# ==========================================
# 3. CICLO DE VIDA E INICIALIZAÇÃO
# ==========================================

func _ready() -> void:
	_setup_visuals()
	_sync_transform_to_logic()


## Configura as cores e proporções do personagem para caber perfeitamente dentro da célula
func _setup_visuals() -> void:
	visual_body.color = theme_color
	# Usando o GameState.CELL_SIZE para abolir o Magic Number antigo
	visual_body.size = Vector2(GameState.CELL_SIZE * 0.7, GameState.CELL_SIZE * 0.7) 
	visual_body.position = -visual_body.size / 2.0 
	
	glow.color = theme_color
	glow.energy = 2.0


# ==========================================
# 4. SISTEMA DE LOCOMOÇÃO
# ==========================================

## Teleporta o visual do engenheiro para a sua coordenada lógica instantaneamente.
func _sync_transform_to_logic() -> void:
	var inverted_y: int = (GameState.GRID_HEIGHT - 1) - int(logical_position.y)
	var cartesian_pos: Vector2 = Vector2(logical_position.x, inverted_y)
	global_position = (cartesian_pos * GameState.CELL_SIZE) + Vector2(GameState.CELL_SIZE / 2.0, GameState.CELL_SIZE / 2.0)


## Valida o custo de energia, atualiza a posição lógica e executa o Tween (animação) 
## para deslizar o personagem suavemente pelo grid holográfico.
func attempt_move(target_grid_pos: Vector2) -> void:
	var delta_x: int = int(abs(target_grid_pos.x - logical_position.x))
	var delta_y: int = int(abs(target_grid_pos.y - logical_position.y))
	
	var cost: int = (delta_x * 1) + (delta_y * 2) 
	
	# ==========================================
	# CORREÇÃO DE INDENTAÇÃO APLICADA AQUI
	# ==========================================
	if GameState.consume_energy(player_id, cost):
		logical_position = target_grid_pos
		
		# O Tradutor Cartesiano agora está perfeitamente alinhado "dentro" do if
		var inverted_y: int = (GameState.GRID_HEIGHT - 1) - int(logical_position.y)
		var cartesian_pos: Vector2 = Vector2(logical_position.x, inverted_y)
		var target_global_pos: Vector2 = (cartesian_pos * GameState.CELL_SIZE) + Vector2(GameState.CELL_SIZE / 2.0, GameState.CELL_SIZE / 2.0)
		
		# Animação gráfica (deslizar)
		var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "global_position", target_global_pos, 0.5)
		tween.finished.connect(func(): movement_resolved.emit(logical_position))
	else:
		push_warning("Energia insuficiente para translação de coordenadas.")


# ==========================================
# 5. SISTEMA DE COMBATE (CONTRATO BALÍSTICO)
# ==========================================

## Função acionada exclusivamente pela colisão do Projectile.gd (A Bala)
func take_damage(amount: float) -> void:
	health -= amount
	health_changed.emit(player_id, health) 
	
	print("Engenheiro ", player_id, " foi atingido! Sofreu ", amount, " de dano.")
	print("Vida atual: ", health)
	
	if health <= 0.0:
		print("Engenheiro ", player_id, " FOI ELIMINADO!")
		queue_free()

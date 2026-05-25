class_name Engineer extends StaticBody2D

signal movement_resolved(final_coords: Vector2)
signal health_changed(player_id: int, new_health: float)

@export var player_id: int = 1
@export var theme_color: Color = Color(1.0, 0.5, 0.0) # Padrão: Léo (Laranja)[cite: 2]
@export var logical_position: Vector2 = Vector2.ZERO

@onready var visual_body: ColorRect = $VisualBody
@onready var glow: PointLight2D = $EnergyGlow

const CELL_SIZE: int = 64
const GRID_HEIGHT: int = 12

func _ready() -> void:
	_setup_visuals()
	_sync_transform_to_logic()

func _setup_visuals() -> void:
	visual_body.color = theme_color
	# Proporção ajustada para caber dentro da célula do grid
	visual_body.size = Vector2(CELL_SIZE * 0.7, CELL_SIZE * 0.7) 
	visual_body.position = -visual_body.size / 2.0 
	
	glow.color = theme_color
	glow.energy = 2.0

func _sync_transform_to_logic() -> void:
	# Tradutor Cartesiano Físico
	var inverted_y = (GRID_HEIGHT - 1) - int(logical_position.y)
	var cartesian_pos = Vector2(logical_position.x, inverted_y)
	
	global_position = (cartesian_pos * CELL_SIZE) + Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)

func attempt_move(target_grid_pos: Vector2) -> void:
	var delta_x: int = int(abs(target_grid_pos.x - logical_position.x))
	var delta_y: int = int(abs(target_grid_pos.y - logical_position.y))
	
	var cost: int = (delta_x * 1) + (delta_y * 2) #[cite: 2]
	
	# Valida com o serviço global se há energia para a transação
	if GameState.consume_energy(player_id, cost):
		logical_position = target_grid_pos
		var inverted_y = (GRID_HEIGHT - 1) - int(logical_position.y)
		var cartesian_pos = Vector2(logical_position.x, inverted_y)
		var target_global_pos = (cartesian_pos * CELL_SIZE) + Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)
		
		# Animação gráfica desacoplada da física (fire-and-forget)
		var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "global_position", target_global_pos, 0.5)
		tween.finished.connect(func(): movement_resolved.emit(logical_position))
	else:
		push_warning("Energia insuficiente para translação de coordenadas.")
		
var health: float = 100.0

func take_damage(amount: float) -> void:
	health -= amount
	health_changed.emit(player_id, health) # ADICIONE ESTA LINHA
	
	print("Engenheiro ", player_id, " foi atingido! Sofreu ", amount, " de dano.")
	print("Vida atual: ", health)
	
	if health <= 0.0:
		print("Engenheiro ", player_id, " FOI ELIMINADO!")
		queue_free()

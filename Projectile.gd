extends Area2D

# 1. BLOCO DE DECLARAÇÃO (Os slots de memória do projétil)
var velocity: Vector2 = Vector2.ZERO
var mass: float = 1.0
var volume: float = 1.0
var custom_gravity: float = 980.0
var wind_force: float = 0.0

# 2. FUNÇÃO DE INICIALIZAÇÃO (Injeção de dados específicos do disparo)
func initialize(start_position: Vector2, initial_velocity: Vector2, p_mass: float, p_volume: float, p_wind: float, p_gravity: float) -> void:
	global_position = start_position
	velocity = initial_velocity
	mass = p_mass
	volume = p_volume
	wind_force = p_wind
	custom_gravity = p_gravity

# 3. PROCESSO FÍSICO (A matemática da parábola acontecendo a cada frame)
func _physics_process(delta: float) -> void:
	# Cálculo da aceleração do vento no eixo X baseado na fórmula do GDD (DesvioX = V * Fvento / m)
	var wind_acceleration = (volume * wind_force) / mass
	velocity.x += wind_acceleration * delta
	
	# Aplicação da aceleração da gravidade no eixo Y
	velocity.y += custom_gravity * delta
	
	# Movimentação real do objeto no espaço cartesiano da Godot
	global_position += velocity * delta

# 4. DETECÇÃO DE COLISÃO (O que acontece quando bate em algo)
func _on_body_entered(_body: Node) -> void:
	# Remove o projétil do jogo para não ficar voando infinitamente pelo cenário vazio
	queue_free()

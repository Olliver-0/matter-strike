extends Area2D

# ==========================================
# 1. SINAIS (Comunicação Externa)
# ==========================================

# Emite um aviso no momento exato em que o projétil colide com qualquer superfície ou inimigo.
signal projectile_impacted

# ==========================================
# 2. VARIÁVEIS DE ESTADO FÍSICO
# ==========================================

var velocity: Vector2 = Vector2.ZERO
var mass: float = 1.0
var volume: float = 1.0
var custom_gravity: float = 980.0
var wind_force: float = 0.0
var lifespan: float = 10.0
var shooter_node: Node = null

func _ready() -> void:
	# Liga o "radar" nativo de colisões do Godot à sua função matemática!
	body_entered.connect(_on_body_entered)

# ==========================================
# 3. INICIALIZAÇÃO E ESCALA VISUAL
# ==========================================

# Injeta os dados balísticos e ambientais para que o projétil inicie a sua trajetória de voo.
func initialize(start_position: Vector2, initial_velocity: Vector2, p_mass: float, p_volume: float, p_wind: float, p_gravity: float, p_shooter: Node) -> void:
	global_position = start_position
	velocity = initial_velocity
	mass = p_mass
	volume = p_volume
	wind_force = p_wind
	custom_gravity = p_gravity
	shooter_node = p_shooter
	
	# --- ESCALA VISUAL DINÂMICA ---
	# Volume de Referência representa a escala 1.0 original da imagem e da hitbox.
	var reference_volume: float = 50.0 
	
	# Fator de escala: Volume 100 dobra o tamanho, Volume 25 reduz para metade.
	var size_multiplier: float = volume / reference_volume
	
	# Aplica a alteração nos eixos X e Y do nó inteiro (Sprite e Colisão redimensionam juntos).
	scale = Vector2(size_multiplier, size_multiplier)

# ==========================================
# 4. MOTOR FÍSICO (Simulação Determinística)
# ==========================================

func _physics_process(delta: float) -> void:
	# Aceleração do vento no eixo X (Fórmula do GDD: DesvioX = Volume * Força do Vento / Massa)
	var wind_acceleration = (volume * wind_force) / mass
	velocity.x += wind_acceleration * delta
	
	# Aceleração da gravidade no eixo Y
	velocity.y += custom_gravity * delta
	
	# Movimentação do objeto no espaço cartesiano (Translação)
	global_position += velocity * delta
	
	# --- SISTEMA ANTI SOFT-LOCK ---
	lifespan -= delta # Desconta a fração de segundo do relógio
	
	if lifespan <= 0.0:
		print(">>> O projétil se perdeu no espaço. Forçando fim de turno!")
		projectile_impacted.emit() # Passa a vez
		queue_free() # Destrói a bala

# ==========================================
# 5. DETECÇÃO DE COLISÃO E CÁLCULO DE DANO
# ==========================================

func _on_body_entered(body: Node) -> void:
	if body == shooter_node:
		return
		
	var impact_speed: float = velocity.length()
	var kinetic_energy: float = (0.5 * mass * pow(impact_speed, 2)) / 1000.0
	
	if body.has_method("take_damage"):
		body.take_damage(kinetic_energy)
		
		# Adiciona o ganho de energia para o atirador
		var shooter_id = shooter_node.player_id
		GameState.add_energy(shooter_id, 30)
		print(">>> TIRO PERFEITO! Recuperando 30 UE para o Jogador ", shooter_id)
		
	projectile_impacted.emit()
	queue_free()
	

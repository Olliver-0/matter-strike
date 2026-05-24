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
	# SE O CORPO FOR O ATIRADOR, IGNORA-O COMPLETAMENTE E CONTINUA A VOAR!
	if body == shooter_node:
		return
	# 1. Calcula a velocidade escalar total (módulo do vetor) no momento exato do impacto.
	var impact_speed: float = velocity.length()
	
	# 2. Fórmula da Energia Cinética (Ec = 0.5 * m * v^2).
	# Dividimos por um valor arbitrário (ex: 1000) para manter os números de dano equilibrados na UI.
	var kinetic_energy: float = (0.5 * mass * pow(impact_speed, 2)) / 1000.0
	
	print(">>> IMPACTO REGISTRADO! Dano Calculado: ", kinetic_energy)
	
	# --- CONTRATO COM A INTERFACE / PERSONAGENS ---
	# Se o objeto atingido (body) possuir o método de receber dano, aplicamos a energia nele.
	# O colega que programar os inimigos DEVE usar exatamente a função 'take_damage(amount: float)'.
	if body.has_method("take_damage"):
		body.take_damage(kinetic_energy)
	
	# Avisa a Calculadora Balística que o ciclo físico do tiro acabou (para passar a vez).
	projectile_impacted.emit()
	
	# Remove o projétil da memória no final do frame atual, limpando o ecrã.
	queue_free()
	

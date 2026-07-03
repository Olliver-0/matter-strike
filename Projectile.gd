## DESCRIÇÃO: Representa a matéria programável (bala) disparada pelo jogador.
## Processa a sua própria simulação física (gravidade, vento, inércia) usando 
## a matemática balística ditada pela densidade, e aplica a energia cinética no alvo.
class_name Projectile extends Area2D

# ==========================================
# 1. SINAIS (Comunicação Externa)
# ==========================================

## Emitido no exato momento em que o projétil colide com algo ou se perde no espaço.
signal projectile_impacted

# ==========================================
# 2. VARIÁVEIS DE ESTADO FÍSICO E UI NODES
# ==========================================

@onready var visual_sprite: Sprite2D = $Sprite2D
@onready var fire_sfx: AudioStreamPlayer2D = $FireSfx

var velocity: Vector2 = Vector2.ZERO
var mass: float = 1.0
var volume: float = 1.0
var custom_gravity: float = 980.0
var wind_force: float = 0.0
var lifespan: float = 10.0
var shooter_node: Node2D = null

# Cache de texturas carregadas na memória
var _projectile_textures: Dictionary = {}

# ==========================================
# 3. CICLO DE VIDA E INICIALIZAÇÃO
# ==========================================

func _ready() -> void:
	# Conecta o radar físico da Godot à nossa função matemática de impacto.
	body_entered.connect(_on_body_entered)
	if fire_sfx:
		fire_sfx.play()
	
	# --- CARREGAMENTO DE ASSETS ---
	# ATENÇÃO: Altere os caminhos abaixo para os nomes reais das suas imagens!
	var leo_texture_path: String = "res://assets/ball_orange_idle.png"
	var sophie_texture_path: String = "res://assets/ball_cyan_idle.png"
	
	if ResourceLoader.exists(leo_texture_path):
		_projectile_textures[1] = load(leo_texture_path)
	if ResourceLoader.exists(sophie_texture_path):
		_projectile_textures[2] = load(sophie_texture_path)


## Injeta os dados balísticos e aplica a textura baseada no ID do atirador.
func initialize(start_position: Vector2, initial_velocity: Vector2, p_mass: float, p_volume: float, p_wind: float, p_gravity: float, p_shooter: Node2D) -> void:
	global_position = start_position
	velocity = initial_velocity
	mass = p_mass
	volume = p_volume
	wind_force = p_wind
	custom_gravity = p_gravity
	shooter_node = p_shooter
	
	# --- APLICAÇÃO VISUAL (SPRITE) ---
	if shooter_node and "player_id" in shooter_node:
		var s_id: int = shooter_node.player_id
		
		# Aplica a textura se ela existir no dicionário
		if _projectile_textures.has(s_id):
			visual_sprite.texture = _projectile_textures[s_id]
		else:
			# Fallback: Se a imagem não for encontrada, pinta a cor padrão do Godot
			visual_sprite.modulate = Color(1.0, 0.5, 0.0) if s_id == 1 else Color(0.04, 0.74, 0.81)
	
	# --- ESCALA VISUAL DINÂMICA ---
	var reference_volume: float = 50.0 
	var size_multiplier: float = volume / reference_volume
	scale = Vector2(size_multiplier, size_multiplier)


# ==========================================
# 4. MOTOR FÍSICO (Simulação Determinística)
# ==========================================

func _physics_process(delta: float) -> void:
	var wind_acceleration: float = (volume * wind_force) / mass
	velocity.x += wind_acceleration * delta
	velocity.y += custom_gravity * delta
	global_position += velocity * delta
	
	# --- GRELHA DE SAÍDA DE TELA ---
	# Se a bala cair do mapa (Y > 1000) ou voar para fora das laterais (X < -200 ou X > 1500)
	if global_position.y > 1000.0 or global_position.x < -200.0 or global_position.x > 1500.0:
		print(">>> O projétil saiu dos limites do mapa. Turno encerrado!")
		projectile_impacted.emit()
		queue_free()
		return
	
	# --- SISTEMA DE EMERGÊNCIA (Failsafe) ---
	lifespan -= delta 
	if lifespan <= 0.0:
		print(">>> Tempo limite do projétil esgotado!")
		projectile_impacted.emit()
		queue_free()

# ==========================================
# 5. DETEÇÃO DE COLISÃO E CÁLCULO DE DANO
# ==========================================

func _on_body_entered(body: Node) -> void:
	# 1. Filtro de Fogo Amigo (Ignora quem atirou)
	if body == shooter_node:
		return 
		
	# 2. FILTRO DE ATRAVESSAMENTO (A Mágica)
	# Se o objeto tocado NÃO for um personagem, ignora a colisão e continua voando.
	if not body.has_method("take_damage"):
		return
		
	# --- DAQUI PARA BAIXO, TEMOS CERTEZA DE QUE BATEU EM UM INIMIGO ---
	
	# 3. Cálculo de Dano balanceado
	var impact_speed: float = velocity.length()
	var kinetic_energy: float = (0.5 * mass * pow(impact_speed, 2)) / 50000.0
	kinetic_energy = clamp(kinetic_energy, 5.0, 40.0)
	
	# 4. Aplica o dano no inimigo
	body.take_damage(kinetic_energy)
	
	# 5. Dá a recompensa de Energia para o atirador
	if shooter_node and "player_id" in shooter_node:
		var shooter_id: int = shooter_node.player_id
		GameState.add_energy(shooter_id, 30)
		print(">>> TIRO PERFEITO! Recuperando 30 UE para o Jogador ", shooter_id)
			
	# 6. Avisa o LevelManager e destrói a bala
	projectile_impacted.emit()
	queue_free()

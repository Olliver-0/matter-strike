## DESCRIÇÃO: Representa a matéria programável (bala) disparada pelo jogador.
## Processa a sua própria simulação física (gravidade, vento, inércia) usando 
## a matemática balística ditada pela densidade, e aplica a energia cinética no alvo.
class_name Projectile extends Area2D

# ==========================================
# 1. SINAIS (Comunicação Externa)
# ==========================================

## Emitido no exato momento em que o projétil colide com algo ou se perde no espaço.
## O Gerenciador de Turnos escuta isto para saber quando passar a vez do jogador.
signal projectile_impacted

# ==========================================
# 2. VARIÁVEIS DE ESTADO FÍSICO
# ==========================================

var velocity: Vector2 = Vector2.ZERO
var mass: float = 1.0
var volume: float = 1.0
var custom_gravity: float = 980.0
var wind_force: float = 0.0

## Tempo máximo de voo antes de ser destruído automaticamente (Sistema Anti Soft-Lock).
var lifespan: float = 10.0

## Referência ao personagem que atirou para evitar "Fogo Amigo" no frame de spawn.
var shooter_node: Node2D = null


# ==========================================
# 3. CICLO DE VIDA E INICIALIZAÇÃO
# ==========================================

func _ready() -> void:
	# Conecta o radar físico da Godot à nossa função matemática de impacto.
	body_entered.connect(_on_body_entered)


## Injeta os dados balísticos e ambientais calculados para que o projétil nasça 
## com o tamanho correto e inicie a sua trajetória perfeitamente.
func initialize(start_position: Vector2, initial_velocity: Vector2, p_mass: float, p_volume: float, p_wind: float, p_gravity: float, p_shooter: Node2D) -> void:
	global_position = start_position
	velocity = initial_velocity
	mass = p_mass
	volume = p_volume
	wind_force = p_wind
	custom_gravity = p_gravity
	shooter_node = p_shooter
	
	# --- ESCALA VISUAL DINÂMICA ---
	# Volume de Referência representa a escala 1.0 original da imagem e da hitbox
	var reference_volume: float = 50.0 
	
	# Fator de escala: Volume 100 dobra o tamanho, Volume 25 reduz para metade
	var size_multiplier: float = volume / reference_volume
	
	# Aplica a alteração geométrica nos eixos X e Y
	scale = Vector2(size_multiplier, size_multiplier)


# ==========================================
# 4. MOTOR FÍSICO (Simulação Determinística)
# ==========================================

func _physics_process(delta: float) -> void:
	# Aceleração do vento no eixo X (Fórmula do GDD: DesvioX = Volume * Força do Vento / Massa)
	var wind_acceleration: float = (volume * wind_force) / mass
	velocity.x += wind_acceleration * delta
	
	# Aceleração da gravidade no eixo Y
	velocity.y += custom_gravity * delta
	
	# Movimentação real da bala (Translação Cartesiana)
	global_position += velocity * delta
	
	# --- SISTEMA ANTI SOFT-LOCK ---
	lifespan -= delta 
	
	if lifespan <= 0.0:
		print(">>> O projétil perdeu-se no espaço. Forçando fim de turno!")
		projectile_impacted.emit()
		queue_free()


# ==========================================
# 5. DETEÇÃO DE COLISÃO E CÁLCULO DE DANO
# ==========================================

## Função chamada automaticamente quando a hitbox da bala sobrepõe um corpo físico (Chão/Inimigo).
func _on_body_entered(body: Node) -> void:
	# Filtro de Imunidade: O atirador não pode levar um tiro da própria bala assim que ela nasce.
	if body == shooter_node:
		return 
		
	# 1. Velocidade Escalar Total (Módulo do vetor no exato instante do impacto)
	var impact_speed: float = velocity.length()
	
	# 2. Fórmula da Energia Cinética: Ec = (0.5 * m * v²) / 1000 (Modificador de Balanceamento)
	var kinetic_energy: float = (0.5 * mass * pow(impact_speed, 2)) / 1000.0
	
	# 3. CONTRATO DE DANO: Valida se o objeto atingido é destrutível (Personagens)
	if body.has_method("take_damage"):
		body.take_damage(kinetic_energy)
		
		# Recompensa o jogador atirador por ter acertado um alvo válido (+30 UE)
		if shooter_node and "player_id" in shooter_node:
			var shooter_id: int = shooter_node.player_id
			GameState.add_energy(shooter_id, 30)
			print(">>> TIRO PERFEITO! Recuperando 30 UE para o Jogador ", shooter_id)
			
	# Avisa a Calculadora de que o ciclo balístico acabou (bateu em alvo ou bateu no chão)
	projectile_impacted.emit()
	
	# Remove a bala do cenário
	queue_free()

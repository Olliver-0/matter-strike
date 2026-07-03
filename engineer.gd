## DESCRIÇÃO: Representa os avatares manipuláveis no mapa (Léo ou Sophie).
## Lida com a interpolação visual e tradução do grid lógico (X, Y) para o espaço cartesiano.
class_name Engineer extends StaticBody2D

# ==========================================
# 1. SINAIS (Comunicação Externa)
# ==========================================

signal movement_resolved(final_coords: Vector2)
signal health_changed(player_id: int, new_health: float)

## NOVO: Emitido no momento exato em que a vida zera, para o LevelManager declarar Game Over.
signal died(player_id: int)


# ==========================================
# 2. EXPORTS E VARIÁVEIS DE ESTADO
# ==========================================

@export var player_id: int = 1
@export var theme_color: Color = Color(1.0, 0.5, 0.0) # Laranja para Léo, Ciano para Sophie
@export var logical_position: Vector2 = Vector2.ZERO

@onready var visual_body: Sprite2D = $VisualBody
@onready var glow: PointLight2D = $EnergyGlow
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sfx_player: AudioStreamPlayer2D = $SfxPlayer

## Som tocado no momento exato em que a vida chega a zero.
@export var death_sound: AudioStream

## Som tocado sempre que o engenheiro sofre um impacto de projétil.
@export var damage_sound: AudioStream

## Som tocado ao ser sugado pelo portal.
@export var portal_in_sound: AudioStream

## Som tocado ao materializar-se na nova coordenada.
@export var portal_out_sound: AudioStream

var health: float = 100.0

# Dicionário dinâmico que armazenará as texturas em cache
var _pose_textures: Dictionary = {}


# ==========================================
# 3. CICLO DE VIDA E INICIALIZAÇÃO
# ==========================================

func _ready() -> void:
	_load_character_assets()
	_setup_visuals()
	_sync_transform_to_logic()
	
	# Define o estado inicial da máquina de estados dependendo de quem é o jogador
	set_state("idle", player_id == 1)


## Carrega as texturas corretas para a memória baseando-se no ID do jogador.
func _load_character_assets() -> void:
	var char_prefix: String = "leo" if player_id == 1 else "sophie"
	
	# ATENÇÃO: Altere esta string para o caminho real onde você salvou as suas imagens!
	var base_path: String = "res://assets/"
	
	_pose_textures = {
		"idle_right": load(base_path + char_prefix + "_idle_r.png"),
		"idle_left": load(base_path + char_prefix + "_idle_l.png"),
		"cast_right": load(base_path + char_prefix + "_cast_r.png"),
		"cast_left": load(base_path + char_prefix + "_cast_l.png"),
		"defeat": load(base_path + char_prefix + "_defeat.png"),
		"portal_in": load(base_path + char_prefix + "_portal_in.png"),
		"portal_out": load(base_path + char_prefix + "_portal_out.png"),
	}


## Configura efeitos luminosos baseados na cor tema.
func _setup_visuals() -> void:
	glow.color = theme_color
	glow.energy = 2.0


# ==========================================
# 4. GESTÃO DE ESTADOS E ANIMAÇÃO
# ==========================================

## Substitui a textura e invoca o AnimationPlayer para o movimento matemático
func set_state(base_state: String, facing_right: bool) -> void:
	var direction_suffix: String = "_right" if facing_right else "_left"
	var state_name: String = base_state + direction_suffix
	
	# Fallback: Se não houver variação de lado (ex: "defeat" é o mesmo pra ambos os lados)
	if not _pose_textures.has(state_name):
		state_name = base_state
		
	# Injeção da imagem baseada no dicionário carregado no início da partida
	if _pose_textures.has(state_name) and _pose_textures[state_name] != null:
		visual_body.texture = _pose_textures[state_name]
	else:
		push_warning("Falta de asset para a pose: ", state_name)
	
	# Chama a execução da matemática elástica no AnimationPlayer
	if anim_player and anim_player.has_animation(state_name):
		anim_player.play(state_name)


# ==========================================
# 5. SISTEMA DE LOCOMOÇÃO
# ==========================================

## Teleporta o visual do engenheiro para a sua coordenada lógica instantaneamente.
func _sync_transform_to_logic() -> void:
	var inverted_y: int = (GameState.GRID_HEIGHT - 1) - int(logical_position.y)
	var cartesian_pos: Vector2 = Vector2(logical_position.x, inverted_y)
	global_position = (cartesian_pos * GameState.CELL_SIZE) + Vector2(GameState.CELL_SIZE / 2.0, GameState.CELL_SIZE / 2.0)


## Valida o custo de energia, calcula a conversão cartesiana e aciona a sequência assíncrona de portal.
func attempt_move(target_grid_pos: Vector2) -> void:
	var delta_x: int = int(abs(target_grid_pos.x - logical_position.x))
	var delta_y: int = int(abs(target_grid_pos.y - logical_position.y))
	
	var cost: int = (delta_x * 1) + (delta_y * 2) 
	
	if GameState.consume_energy(player_id, cost):
		var inverted_y: int = (GameState.GRID_HEIGHT - 1) - int(target_grid_pos.y)
		var cartesian_pos: Vector2 = Vector2(target_grid_pos.x, inverted_y)
		var target_global_pos: Vector2 = (cartesian_pos * GameState.CELL_SIZE) + Vector2(GameState.CELL_SIZE / 2.0, GameState.CELL_SIZE / 2.0)
		
		# Delega a translação física para a corrotina visual
		_play_portal_sequence(target_grid_pos, target_global_pos)
	else:
		push_warning("Energia insuficiente para translação de coordenadas.")


## Executa a transição assíncrona de escala e textura para simular o teletransporte paramétrico.
func _play_portal_sequence(new_logical_pos: Vector2, target_pixel_pos: Vector2) -> void:
	# 1. Blindagem de Escala
	var base_scale: Vector2 = visual_body.scale
	
	# --- FASE 1: IMPLOSÃO VISUAL (Entrada) ---
	if portal_in_sound and sfx_player:
		sfx_player.stream = portal_in_sound
		sfx_player.play()
		
	set_state("portal_in", player_id == 1)
	var tween_in: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween_in.tween_property(visual_body, "scale", Vector2(0.01, 0.01), 0.3)
	
	await tween_in.finished
	
	if not is_inside_tree(): return

	# --- FASE 2: REDEFINIÇÃO CARTESIANA (O Teletransporte) ---
	logical_position = new_logical_pos
	global_position = target_pixel_pos
	
	# --- FASE 3: EXPANSÃO VISUAL (Saída) ---
	if portal_out_sound and sfx_player:
		sfx_player.stream = portal_out_sound
		sfx_player.play()
		
	set_state("portal_out", player_id == 1)
	var tween_out: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_out.tween_property(visual_body, "scale", base_scale, 0.3)
	
	await tween_out.finished
	
	if not is_inside_tree(): return
	
	# --- FASE 4: REESTABILIZAÇÃO ---
	set_state("idle", player_id == 1)
	
	# Notifica o LevelManager que a operação matemática e visual foi concluída
	movement_resolved.emit(logical_position)


# ==========================================
# 6. SISTEMA DE COMBATE (CONTRATO BALÍSTICO)
# ==========================================

## Função acionada exclusivamente pela colisão do Projectile.gd (A Bala)
func take_damage(amount: float) -> void:
	health -= amount
	health_changed.emit(player_id, health) 
	
	# Toca o som de impacto
	if damage_sound and sfx_player:
		sfx_player.stream = damage_sound
		sfx_player.play()
	
	print("Engenheiro ", player_id, " foi atingido! Sofreu ", amount, " de dano.")
	print("Vida atual: ", health)
	
	# --- LÓGICA DE GAME OVER ---
	if health <= 0.0:
		died.emit(player_id) # NOVO: Avisa imediatamente o orquestrador que este jogador morreu
		print("Engenheiro ", player_id, " FOI ELIMINADO!")
		
		# Toca o som de morte
		if death_sound and sfx_player:
			sfx_player.stream = death_sound
			sfx_player.play()
		
		# 1. Troca para a textura de morte
		set_state("defeat", player_id == 1) 
		
		# 2. Desliga a colisão para a bala não bater duas vezes no cadáver
		$CollisionShape2D.set_deferred("disabled", true)
		
		# 3. Pausa 1.5 segundos para o jogador ver a derrota antes do nó sumir
		await get_tree().create_timer(1.5).timeout
		queue_free()
		

# ==========================================
# 7. SEQUÊNCIA DE DISPARO (CAST)
# ==========================================

## Orienta a sprite para o alvo, executa a animação de cast e aplica um recuo físico.
func play_cast_sequence(target_pixel_x: float) -> void:
	# 1. Avalia o $\Delta x$ para definir o vetor de direção
	var facing_right: bool = target_pixel_x > global_position.x
	set_state("cast", facing_right)
	
	# 2. Animação Procedimental de Recuo (Inércia da ignição pneumática)
	var recoil_tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var recoil_vector := Vector2(-12.0, 0.0) if facing_right else Vector2(12.0, 0.0)
	
	# Transpõe o corpo visual no eixo oposto ao tiro e o estabiliza
	recoil_tween.tween_property(visual_body, "position", recoil_vector, 0.1)
	recoil_tween.tween_property(visual_body, "position", Vector2.ZERO, 0.3)
	
	# 3. Tempo de Wind-up: Pausa a corrotina até o braço estar estendido
	await get_tree().create_timer(0.15).timeout
	
	if not is_inside_tree(): return
	
	# 4. Configura o "Recovery": O braço volta à posição estática (Idle)
	get_tree().create_timer(0.4).timeout.connect(func():
		if is_inside_tree() and health > 0.0:
			set_state("idle", facing_right)
	)

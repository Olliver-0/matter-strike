extends Node2D

# 1. LINK COM O MOLDE DO PROJÉTIL
# Esta variável vai nos permitir arrastar a cena do projétil diretamente pelo editor
@export var projectile_scene: PackedScene

# 2. REFERÊNCIA AO PONTO DE DISPARO
@onready var muzzle_marker: Marker2D = $MuzzleMarker

# Variáveis físicas básicas para o teste da parábola
var current_gravity: float = 980.0
var current_wind: float = 100.0 # Inicialmente sem vento para facilitar seu primeiro teste

func _unhandled_input(event: InputEvent) -> void:
	# GATILHO DE TESTE: Sempre que você clicar com o botão esquerdo do mouse na tela
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Captura a coordenada exata de onde você clicou na tela
		var clicked_coordinate = get_global_mouse_position()
		
		# Executa o disparo simulando o terminal do jogo
		# Usaremos valores base de massa e volume (10.0) para o teste inicial
		fire_shot(clicked_coordinate, 10.0, 10.0)

func fire_shot(target_coordinate: Vector2, input_mass: float, input_volume: float) -> void:
	if not projectile_scene:
		push_error("ERRO: Você esqueceu de arrastar a cena do Projétil para o Inspector da Calculadora!")
		return
		
	var spawn_position = muzzle_marker.global_position
	
	# Calcula o vetor de velocidade inicial baseado na distância e direção do clique
	var calculated_velocity = _calculate_launch_velocity(spawn_position, target_coordinate, input_mass, input_volume)
	
	# Instancia (clona) o projétil no jogo
	var projectile_instance = projectile_scene.instantiate() as Area2D
	get_tree().current_scene.add_child(projectile_instance)
	
	# Injeta os valores iniciais e a gravidade para o projétil começar a voar sozinho
	projectile_instance.initialize(
		spawn_position,
		calculated_velocity,
		input_mass,
		input_volume,
		current_wind,
		current_gravity
	)

func _calculate_launch_velocity(start: Vector2, target_input: Vector2, m: float, _v: float) -> Vector2:	# Encontra a direção apontando do Muzzle para o clique do mouse
	var direction: Vector2 = (target_input - start).normalized()
	
	# Calcula a distância em pixels entre o Muzzle e o clique
	var distance: float = start.distance_to(target_input)
	
	# Multiplicador de força para o tiro não ficar lento demais na tela
	var force_multiplier: float = 3.0
	var raw_force: float = distance * force_multiplier
	
	# Modificador físico simples: quanto maior a massa, menos velocidade inicial o tiro ganha [cite: 85]
	var velocity_modifier: float = 1.0 / (1.0 + (m * 0.01))
	var final_force: float = raw_force * velocity_modifier
	
	return direction * final_force

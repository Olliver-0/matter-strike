extends Node2D

# ==========================================
# 1. SINAIS E REFERÊNCIAS (Configuração do Editor)
# ==========================================

# CONTRATO COM A INTERFACE: O Gerenciador de Turnos deve se conectar a este sinal 
# para saber o momento exato em que a animação da bala acabou e a vez pode ser passada.
signal turn_resolved

# Arraste a cena "Projectile.tscn" para este campo no painel Inspector (à direita)
@export var projectile_scene: PackedScene

# Marcador temporário de onde o tiro sai durante os testes isolados
@onready var muzzle_marker: Marker2D = $MuzzleMarker

# Variáveis do ambiente da partida atual (Devem ser alteradas a cada turno/fase)
var current_gravity: float = 980.0
var current_wind: float = -350.0

# ==========================================
# 3. API PÚBLICA (CONTRATO COM A INTERFACE)
# ==========================================

# CONTRATO COM A INTERFACE: Chamar esta função quando o botão "ATIRAR" for pressionado.
# start_position: a posição global da arma/luva do personagem.
# target_coordinate: a coordenada (X, Y) digitada no terminal.
# input_type: "MASS" ou "VOLUME" (dependendo de qual barra o jogador ajustou).
# input_value: o número final da barra.
func dispatch_shot(shooter: Node2D, target_coordinate: Vector2, input_type: String, input_value: float) -> void:
	var material_data = MaterialsTable.get_current_properties()
	var current_density: float = material_data["density"]
	
	var final_mass: float = 0.0
	var final_volume: float = 0.0
	
	# Limites físicos do canhão (impede o jogador de criar balas infinitamente grandes/pequenas)
	var min_volume: float = 10.0
	var max_volume: float = 100.0
	
	# Resolve a regra de transmutação (Conservação baseada na Densidade do Material)
	if input_type == "MASS":
		var theoretical_volume: float = input_value / current_density
		final_volume = clampf(theoretical_volume, min_volume, max_volume)
		final_mass = final_volume * current_density 
		
	elif input_type == "VOLUME":
		final_volume = clampf(input_value, min_volume, max_volume)
		final_mass = final_volume * current_density
		
	# Log de validação no console
	print("--- NOVO DISPARO ---")
	print("Input Original: ", input_type, " = ", input_value)
	print("Material Atual: ", MaterialsTable.current_material)
	print("Massa Final: ", final_mass, " | Volume Final: ", final_volume)
	
	# Repassa os dados validados para o sistema de física criar o objeto
	fire_shot(shooter, target_coordinate, final_mass, final_volume)


# CONTRATO COM A INTERFACE: Chamar esta função continuamente enquanto o jogador arrasta
# a barra de Massa para prever quanto o tiro vai custar da barra de Energia (UE) dele.
func calculate_energy_cost(preview_mass: float) -> float:
	var cost_multiplier: float = 0.1 
	return preview_mass * cost_multiplier


# ==========================================
# 4. LÓGICA INTERNA E MATEMÁTICA FÍSICA
# ==========================================

# Cria a bala no mapa, injeta a física e atira.
func fire_shot(shooter: Node2D, target_coordinate: Vector2, input_mass: float, input_volume: float) -> void:
	if not projectile_scene: return
	
	# Descobre a posição de saída extraindo-a do atirador que foi recebido
	var start_position = shooter.global_position
	
	var calculated_velocity = _calculate_launch_velocity(start_position, target_coordinate, input_mass, input_volume)
	
	var projectile_instance = projectile_scene.instantiate() as Area2D
	get_tree().current_scene.add_child(projectile_instance)
	projectile_instance.body_entered.connect(projectile_instance._on_body_entered)
	projectile_instance.projectile_impacted.connect(_on_projectile_impacted)
	
	# Inicializa passando o 'shooter' no final
	projectile_instance.initialize(
		start_position, calculated_velocity, input_mass,
		input_volume, current_wind, current_gravity,
		shooter # <--- ENTREGA O DONO PARA A BALA AQUI
	)

# Transforma coordenadas puras em um vetor de velocidade física (com punição por inércia/peso)
func _calculate_launch_velocity(start: Vector2, target_input: Vector2, m: float, _v: float) -> Vector2:	
	var direction: Vector2 = (target_input - start).normalized()
	var distance: float = start.distance_to(target_input)
	
	var force_multiplier: float = 3.0
	var raw_force: float = distance * force_multiplier
	
	# Modificador de Inércia: materiais mais pesados saem do canhão com menos velocidade inicial
	var velocity_modifier: float = 1.0 / (1.0 + (m * 0.01))
	var final_force: float = raw_force * velocity_modifier
	
	return direction * final_force

# Escuta o aviso de impacto da bala e repassa a informação adiante para o jogo
func _on_projectile_impacted() -> void:
	print("Calculadora informa: O tiro foi finalizado fisicamente no cenário.")
	turn_resolved.emit()
	

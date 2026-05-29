## DESCRIÇÃO: Motor matemático e físico (O Cérebro) do Matter Strike.
## Transforma os inputs abstratos do jogador (Coordenadas, Massa, Volume)
## em vetores físicos tangíveis, além de instanciar a matéria no cenário.
class_name BallisticsCalculator extends Node2D

# ==========================================
# 1. SINAIS (Comunicação Externa)
# ==========================================

## Emitido quando o ciclo balístico do projétil termina (bateu ou sumiu).
## O LevelManager escuta isto para saber quando passar o turno com segurança.
signal turn_resolved


# ==========================================
# 2. CONSTANTES E REFERÊNCIAS
# ==========================================

## O modelo base (cena) do projétil que será clonado no momento do disparo.
@export var projectile_scene: PackedScene

## Marcador visual de onde o tiro sai. (Útil para testes isolados da calculadora).
@onready var muzzle_marker: Marker2D = $MuzzleMarker

## Desvio de altura aplicado para que a bala não nasça a bater no chão.
const MUZZLE_OFFSET_Y: float = -80.0


# ==========================================
# 3. VARIÁVEIS DE ESTADO AMBIENTAL
# ==========================================

## Gravidade atual do setor da Estação Arquimedes. (Pode ser alterada por turno).
var current_gravity: float = 980.0

## Força e direção do vento atual atuando no Eixo X. (Negativo = Esquerda, Positivo = Direita).
var current_wind: float = -350.0


# ==========================================
# 4. MÉTODOS PÚBLICOS (API do Motor)
# ==========================================

## Recebe os dados brutos da interface do jogador, aplica os limites físicos do canhão,
## calcula a conversão de densidade e repassa a ordem validada para o gerador de tiro.
func dispatch_shot(shooter: Node2D, target_coordinate: Vector2, input_type: String, input_value: float) -> void:
	var material_data: Dictionary = MaterialsTable.get_current_properties()
	var current_density: float = material_data["density"]
	
	var final_mass: float = 0.0
	var final_volume: float = 0.0
	
	# Limites físicos do canhão (Impede balas infinitamente gigantes ou poeira atómica)
	var min_volume: float = 10.0
	var max_volume: float = 100.0
	
	# Resolve a regra de transmutação com base na Conservação de Densidade
	if input_type == "MASS":
		var theoretical_volume: float = input_value / current_density
		final_volume = clampf(theoretical_volume, min_volume, max_volume)
		final_mass = final_volume * current_density 
		
	elif input_type == "VOLUME":
		final_volume = clampf(input_value, min_volume, max_volume)
		final_mass = final_volume * current_density
		
	# Log de validação no console para depuração matemática
	print("--- NOVO DISPARO ---")
	print("Input Original: ", input_type, " = ", input_value)
	print("Material Atual: ", MaterialsTable.current_material)
	print("Massa Final: ", final_mass, " | Volume Final: ", final_volume)
	
	# Repassa os dados validados para a forja interna de matéria
	_fire_shot(shooter, target_coordinate, final_mass, final_volume)


## Calcula continuamente o custo energético de um disparo baseado na massa da matéria.
## Usado pela UI para atualizar as exibições de custo em tempo real.
func calculate_energy_cost(preview_mass: float) -> float:
	# Multiplicador equilibrado para que o Chumbo máximo (1134 kg) custe ~90 UE
	var cost_multiplier: float = 0.08 
	return preview_mass * cost_multiplier


# ==========================================
# 5. MÉTODOS PRIVADOS (Lógica Interna)
# ==========================================

## Instancia o projétil no mapa, calcula o vetor de lançamento compensando 
## inércia e gravidade, e injeta as variáveis no novo objeto.
func _fire_shot(shooter: Node2D, target_coordinate: Vector2, input_mass: float, input_volume: float) -> void:
	if not projectile_scene:
		push_error("BallisticsCalculator: Cena do projétil não configurada no Inspector!")
		return
	
	# Descobre a posição de saída usando a constante global de desvio (Cano da Arma)
	var start_position: Vector2 = shooter.global_position + Vector2(0, MUZZLE_OFFSET_Y)
	
	var calculated_velocity: Vector2 = _calculate_launch_velocity(start_position, target_coordinate, input_mass)
	
	# Aqui o motor instancia a bala utilizando a tipagem estrita "Projectile"
	var projectile_instance := projectile_scene.instantiate() as Projectile
	get_tree().current_scene.add_child(projectile_instance)
	
	# Ouve o projétil para saber quando a física terminou de processá-lo
	projectile_instance.projectile_impacted.connect(_on_projectile_impacted)
	
	# Inicializa o objeto físico passando todos os atributos ambientais
	projectile_instance.initialize(
		start_position, 
		calculated_velocity, 
		input_mass,
		input_volume, 
		current_wind, 
		current_gravity,
		shooter
	)


## Transforma coordenadas puras num vetor de velocidade inicial.
## Aplica modificadores de inércia para materiais mais pesados saírem do canhão mais devagar.
func _calculate_launch_velocity(start: Vector2, target_input: Vector2, m: float) -> Vector2:	
	var direction: Vector2 = (target_input - start).normalized()
	var distance: float = start.distance_to(target_input)
	
	# Modificador de força base (Força pura baseada na distância exigida)
	var force_multiplier: float = 3.0
	var raw_force: float = distance * force_multiplier
	
	# Modificador de Inércia: Materiais de alta massa perdem propulsão inicial
	var velocity_modifier: float = 1.0 / (1.0 + (m * 0.01))
	var final_force: float = raw_force * velocity_modifier
	
	return direction * final_force


## Escuta o aviso de impacto da bala e repassa a informação adiante para o LevelManager.
func _on_projectile_impacted() -> void:
	print("Calculadora informa: O tiro foi finalizado fisicamente no cenário.")
	turn_resolved.emit()
	

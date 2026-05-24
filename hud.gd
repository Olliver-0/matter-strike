extends CanvasLayer

@onready var mass_slider: HSlider = $MassSlider
@onready var volume_slider: HSlider = $VolumeSlider
@onready var material_dropdown: OptionButton = $MaterialDropdown

@onready var mass_label: Label = $MassLabel
@onready var volume_label: Label = $VolumeLabel

# Guardamos o que o jogador tocou por último para avisar a Calculadora
var last_edited: String = "MASS" 

func _ready() -> void:
	# 1. Preenche o Dropdown com os materiais do banco de dados
	material_dropdown.clear()
	for mat_name in MaterialsTable.MATERIALS.keys():
		material_dropdown.add_item(mat_name)
		
	# 2. Conecta os botões e barras às funções
	material_dropdown.item_selected.connect(_on_material_selected)
	mass_slider.value_changed.connect(_on_mass_changed)
	volume_slider.value_changed.connect(_on_volume_changed)
	
	# 3. Força a primeira atualização para configurar os limites
	_update_limits_and_bars()

func _on_material_selected(index: int) -> void:
	# Quando o jogador escolhe outro material, atualizamos o Singleton global
	var selected_mat = material_dropdown.get_item_text(index)
	MaterialsTable.current_material = selected_mat
	
	# E recalcula as barras para a nova densidade
	_update_limits_and_bars()

func _update_limits_and_bars() -> void:
	var density = MaterialsTable.get_current_properties()["density"]
	
	# REGRA DO CANHÃO: O volume mínimo é 10 e o máximo é 100
	volume_slider.min_value = 10.0
	volume_slider.max_value = 100.0
	
	# A Massa permitida adapta-se à densidade do material escolhido
	mass_slider.min_value = volume_slider.min_value * density
	mass_slider.max_value = volume_slider.max_value * density
	
	# Atualiza a barra que o jogador não está mexendo para não estragar a jogada dele
	if last_edited == "MASS":
		_on_mass_changed(mass_slider.value)
	else:
		_on_volume_changed(volume_slider.value)

func _on_mass_changed(value: float) -> void:
	last_edited = "MASS"
	var density = MaterialsTable.get_current_properties()["density"]
	var calculated_volume = value / density
	
	# ATUALIZA O VOLUME SILENCIOSAMENTE (Não dispara o sinal _on_volume_changed)
	volume_slider.set_value_no_signal(calculated_volume)
	
	_update_texts(value, calculated_volume)

func _on_volume_changed(value: float) -> void:
	last_edited = "VOLUME"
	var density = MaterialsTable.get_current_properties()["density"]
	var calculated_mass = value * density
	
	# ATUALIZA A MASSA SILENCIOSAMENTE (Não dispara o sinal _on_mass_changed)
	mass_slider.set_value_no_signal(calculated_mass)
	
	_update_texts(calculated_mass, value)

func _update_texts(m_val: float, v_val: float) -> void:
	# O snapped() arredonda para 1 casa decimal para o ecrã não ficar cheio de números quebrados
	mass_label.text = "Massa: " + str(snapped(m_val, 0.1)) + " kg"
	volume_label.text = "Volume: " + str(snapped(v_val, 0.1)) + " m³"

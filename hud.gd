extends CanvasLayer

@onready var mass_slider = $MassSlider
@onready var volume_label = $VolumeLabel

func _ready():
	# Configura o slider
	mass_slider.min_value = 1
	mass_slider.max_value = 100
	mass_slider.value = 10
	
	# Conecta o sinal de mudança do slider
	mass_slider.value_changed.connect(_on_mass_changed)
	
	# Calcula o volume inicial
	_update_volume(mass_slider.value)

func _on_mass_changed(value):
	_update_volume(value)

func _update_volume(mass):
	# Regra simples: Densidade fixa (ex: 2.0)
	var density = 2.0 
	var volume = mass / density
	volume_label.text = "Volume: " + str(volume) + " m³"

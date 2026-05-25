extends Node

const MATERIALS = {
	"CORTIÇA":  {"density": 0.24, "hud_color": Color(0.65, 0.50, 0.39)},
	"PEDRA": {"density": 2.70, "hud_color": Color(0.50, 0.50, 0.50)},
	"FERRO":  {"density": 7.87, "hud_color": Color(0.75, 0.75, 0.75)},
	"CHUMBO":  {"density": 11.34, "hud_color": Color(0.30, 0.35, 0.40)}
}

var current_material: String = "CORTIÇA"

func get_current_properties() -> Dictionary:
	return MATERIALS[current_material]

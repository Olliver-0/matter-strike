extends Node

const MATERIALS = {
	"CORK":  {"density": 0.24, "hud_color": Color(0.65, 0.50, 0.39)},
	"STONE": {"density": 2.70, "hud_color": Color(0.50, 0.50, 0.50)},
	"IRON":  {"density": 7.87, "hud_color": Color(0.75, 0.75, 0.75)},
	"LEAD":  {"density": 11.34, "hud_color": Color(0.30, 0.35, 0.40)}
}

var current_material: String = "IRON"

func get_current_properties() -> Dictionary:
	return MATERIALS[current_material]

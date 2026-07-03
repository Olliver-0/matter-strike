class_name GameOverUI extends CanvasLayer

@onready var banner: TextureRect = $Banner
@onready var btn_restart: Button = $BtnRestart

var victory_textures: Dictionary = {}

func _ready() -> void:
	hide()
	btn_restart.pressed.connect(_on_btn_restart_pressed)
	
	# Ajustado para os nomes exatos das imagens que você fez
	var leo_tex_path: String = "res://assets/leo"
	var sophie_tex_path: String = "res://assets/sophie_wins.png"
	
	if ResourceLoader.exists(leo_tex_path): victory_textures[1] = load(leo_tex_path)
	if ResourceLoader.exists(sophie_tex_path): victory_textures[2] = load(sophie_tex_path)

func show_victory(winner_id: int) -> void:
	if victory_textures.has(winner_id):
		banner.texture = victory_textures[winner_id]
	show()

func _on_btn_restart_pressed() -> void:
	GameState.reset_state()
	get_tree().reload_current_scene()

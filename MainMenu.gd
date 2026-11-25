## DESCRIÇÃO: Controla o Menu Principal de Matter Strike.
## Gerencia a navegação para a partida, o modal interativo de Tutorial e a saída do jogo.
class_name MainMenu extends Control

const GAME_SCENE_PATH: String = "res://LevelManager.tscn"

@onready var btn_start: Button = $MenuButtons/BtnStart
@onready var btn_tutorial: Button = $MenuButtons/BtnTutorial
@onready var btn_quit: Button = $MenuButtons/BtnQuit

@onready var tutorial_overlay: ColorRect = $TutorialOverlay
@onready var tutorial_title: Label = $TutorialOverlay/TutorialPanel/TutorialTitle
@onready var tutorial_body: RichTextLabel = $TutorialOverlay/TutorialPanel/TutorialBody
@onready var lbl_page: Label = $TutorialOverlay/TutorialPanel/FooterButtons/LblPage
@onready var btn_prev: Button = $TutorialOverlay/TutorialPanel/FooterButtons/BtnPrev
@onready var btn_next: Button = $TutorialOverlay/TutorialPanel/FooterButtons/BtnNext
@onready var btn_close_tutorial: Button = $TutorialOverlay/TutorialPanel/FooterButtons/BtnCloseTutorial

var _current_page: int = 0

var _tutorial_pages: Array[Dictionary] = [
	{
		"title": "1. OBJETIVO E TURNOS",
		"body": "[b][color=#f0b058]Bem-vindo à Estação Arquimedes![/color][/b]

[b]Matter Strike[/b] é um duelo balístico por turnos entre dois engenheiros:
• [color=#f0a050][b]Léo (Laranja)[/b][/color] vs. [color=#68d0dc][b]Sophie (Ciano)[/b][/color]

[b][color=#ead2ac]Como funcionam os turnos:[/color][/b]
• O [b]triângulo acima de cada personagem[/b] indica de quem é a vez — o triângulo [b]maior[/b] marca o jogador ativo.
• Cada jogador inicia com [b]100 HP[/b] e [b]100 UE[/b] (Unidades de Energia).
• No início de cada turno, o jogador ativo recupera [b]+50 UE[/b].
• Acertar um disparo no oponente concede um bônus de [b]+30 UE[/b]!
• Vença reduzindo a vida do adversário a zero."
	},
	{
		"title": "2. COORDENADAS E MOVIMENTAÇÃO",
		"body": "[b][color=#f0b058]Plano Cartesiano [X, Y][/color][/b]

A arena é dividida em uma grade numerada com colunas [b]X[/b] (horizontal) e linhas [b]Y[/b] (vertical).

[b][color=#ead2ac]Usando o Terminal Numérico:[/color][/b]
• Digite [b]4 dígitos[/b] no teclado numérico da tela ou no teclado físico ([b]0–9[/b]) para informar [b][XX, YY][/b].
  Exemplo: digitar [b]0806[/b] define a coordenada [b][08, 06][/b].
• Use [b]Backspace[/b] para apagar o último dígito, [b]C[/b] / [b]Delete[/b] para limpar tudo e [b]Enter[/b] para atirar.

[b][color=#ead2ac]Ações do Painel Central:[/color][/b]
• [b]MOVER / CALCULAR:[/b] Teletransporta seu engenheiro para a plataforma da coordenada informada (custo: [b]1 UE[/b] por unidade em X + [b]2 UE[/b] por unidade em Y).
• [b]PASSAR TURNO:[/b] Encerra sua vez sem disparar para poupar energia."
	},
	{
		"title": "3. MATÉRIA, DENSIDADE E DISPARO",
		"body": "[b][color=#f0b058]Física da Transmutação[/color][/b]

Antes de atirar, configure o projétil no painel de [b]MATERIAIS[/b] e nos sliders de [b]MASSA[/b] e [b]VOLUME[/b]:
• [b]Cortiça[/b] (d = 0.24) — muito leve, barata em energia e com grande alcance, porém causa menos dano.
• [b]Pedra[/b] (d = 2.70) — equilíbrio entre custo, alcance e impacto.
• [b]Ferro[/b] (d = 7.87) — alta massa e dano cinético elevado.
• [b]Chumbo[/b] (d = 11.34) — altíssima massa e inércia, exige muita energia.

[b][color=#ead2ac]Regra Física (Massa = Densidade × Volume):[/color][/b]
• Ajustar a [b]Massa[/b] recalcula o [b]Volume[/b] automaticamente (e vice-versa).
• O [b]Registro de Disparos Recentes[/b] à esquerda guarda o histórico de tiros para você calibrar sua mira.
• Digite a coordenada alvo [b][XX, YY][/b] e clique em [color=#a8d898][b]CONFIRMAR DISPARO[/b][/color]!"
	}
]


func _ready() -> void:
	tutorial_overlay.visible = false
	MusicManager.play_menu()
	
	btn_start.pressed.connect(_on_btn_start_pressed)
	btn_tutorial.pressed.connect(_on_btn_tutorial_pressed)
	btn_quit.pressed.connect(_on_btn_quit_pressed)
	
	btn_prev.pressed.connect(_on_btn_prev_pressed)
	btn_next.pressed.connect(_on_btn_next_pressed)
	btn_close_tutorial.pressed.connect(_on_btn_close_tutorial_pressed)
	
	btn_start.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if tutorial_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_tutorial()
		get_viewport().set_input_as_handled()


func _on_btn_start_pressed() -> void:
	GameState.reset_state()
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_btn_tutorial_pressed() -> void:
	_current_page = 0
	_render_tutorial_page()
	tutorial_overlay.visible = true
	btn_next.grab_focus()


func _on_btn_quit_pressed() -> void:
	get_tree().quit()


func _on_btn_prev_pressed() -> void:
	if _current_page > 0:
		_current_page -= 1
		_render_tutorial_page()


func _on_btn_next_pressed() -> void:
	if _current_page < _tutorial_pages.size() - 1:
		_current_page += 1
		_render_tutorial_page()
	else:
		_on_btn_start_pressed()


func _on_btn_close_tutorial_pressed() -> void:
	_close_tutorial()


func _close_tutorial() -> void:
	tutorial_overlay.visible = false
	btn_tutorial.grab_focus()


func _render_tutorial_page() -> void:
	var page: Dictionary = _tutorial_pages[_current_page]
	tutorial_title.text = "TUTORIAL — " + page["title"]
	tutorial_body.text = page["body"]
	tutorial_body.scroll_to_line(0)
	lbl_page.text = "Página %d / %d" % [_current_page + 1, _tutorial_pages.size()]
	btn_prev.disabled = (_current_page == 0)
	if _current_page == _tutorial_pages.size() - 1:
		btn_next.text = "JOGAR AGORA ▶"
	else:
		btn_next.text = "PRÓXIMO ▶"

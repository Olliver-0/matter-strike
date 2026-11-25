## DESCRIÇÃO: Autoload responsável pela trilha sonora global do jogo (Menu e Combate).
## Gerencia loop contínuo sem cortes e crossfade suave entre as faixas.
extends Node

const TRACKS: Dictionary = {
	"menu": "res://sounds/music_menu.wav",
	"combat": "res://sounds/music_combat.wav"
}

const DEFAULT_VOLUME_DB: float = -8.0
const MUTED_VOLUME_DB: float = -80.0
const CROSSFADE_DURATION: float = 0.65

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active_player: AudioStreamPlayer
var _current_track: String = ""
var _is_muted: bool = false
var _fade_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_player_a = AudioStreamPlayer.new()
	_player_a.name = "MusicPlayerA"
	_player_a.volume_db = MUTED_VOLUME_DB
	add_child(_player_a)
	
	_player_b = AudioStreamPlayer.new()
	_player_b.name = "MusicPlayerB"
	_player_b.volume_db = MUTED_VOLUME_DB
	add_child(_player_b)
	
	_active_player = _player_a


func _exit_tree() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null
	if _player_a:
		_player_a.stop()
		_player_a.stream = null
	if _player_b:
		_player_b.stop()
		_player_b.stream = null


func play_menu() -> void:
	play_track("menu")


func play_combat() -> void:
	play_track("combat")


func play_track(track_name: String) -> void:
	if not TRACKS.has(track_name):
		push_warning("MusicManager: Faixa desconhecida -> ", track_name)
		return
	if _current_track == track_name and _active_player and _active_player.playing:
		return
		
	var path: String = TRACKS[track_name]
	if not ResourceLoader.exists(path):
		push_warning("MusicManager: Arquivo de áudio não encontrado -> ", path)
		return
		
	var stream: AudioStream = load(path)
	if stream == null:
		return
		
	_configure_loop(stream)
	
	var old_player: AudioStreamPlayer = _active_player
	var next_player: AudioStreamPlayer = _player_b if _active_player == _player_a else _player_a
	
	next_player.stream = stream
	next_player.volume_db = MUTED_VOLUME_DB
	next_player.play()
	
	_active_player = next_player
	_current_track = track_name
	
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
		
	var target_db: float = MUTED_VOLUME_DB if _is_muted else DEFAULT_VOLUME_DB
	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(next_player, "volume_db", target_db, CROSSFADE_DURATION)
	if old_player.playing:
		_fade_tween.tween_property(old_player, "volume_db", MUTED_VOLUME_DB, CROSSFADE_DURATION)
		_fade_tween.chain().tween_callback(old_player.stop)


func stop_music() -> void:
	_current_track = ""
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_player_a.stop()
	_player_b.stop()


func set_muted(muted: bool) -> void:
	_is_muted = muted
	if _active_player and _active_player.playing:
		_active_player.volume_db = MUTED_VOLUME_DB if _is_muted else DEFAULT_VOLUME_DB


func toggle_mute() -> void:
	set_muted(not _is_muted)


func _configure_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		if wav.loop_end <= 0:
			wav.loop_end = int(round(wav.get_length() * wav.mix_rate))
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true

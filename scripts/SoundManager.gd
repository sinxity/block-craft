extends Node

# Procedural sound manager — no audio files needed

var _player: AudioStreamPlayer

func _ready():
	_player = AudioStreamPlayer.new()
	add_child(_player)

func play_chop():
	if not GameState.sound_enabled: return
	_play_tone(120.0, 0.08, 0.6)

func play_place():
	if not GameState.sound_enabled: return
	_play_tone(440.0, 0.06, 0.3)

func play_level_done():
	if not GameState.sound_enabled: return
	_play_melody([523, 659, 784, 1047], 0.13)

func play_fail():
	if not GameState.sound_enabled: return
	_play_tone(180.0, 0.12, 0.8)

func play_star():
	if not GameState.sound_enabled: return
	_play_tone(1046.0, 0.10, 0.5)

func play_achievement():
	if not GameState.sound_enabled: return
	_play_melody([880, 1108, 1318], 0.12)

func play_daily_done():
	if not GameState.sound_enabled: return
	_play_melody([659, 784, 1046], 0.14)

func _play_tone(freq: float, duration: float, volume: float = 0.5):
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = duration + 0.05
	_player.stream = stream
	_player.volume_db = linear_to_db(volume)
	_player.play()
	var pb = _player.get_stream_playback()
	var frames = int(stream.mix_rate * duration)
	for i in range(frames):
		var t = float(i) / stream.mix_rate
		var env = 1.0 - (t / duration)  # fade out
		var s = sin(TAU * freq * t) * env * 0.8
		pb.push_frame(Vector2(s, s))

func _play_melody(freqs: Array, note_dur: float):
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = note_dur * freqs.size() + 0.1
	_player.stream = stream
	_player.volume_db = linear_to_db(0.4)
	_player.play()
	var pb = _player.get_stream_playback()
	for freq in freqs:
		var frames = int(stream.mix_rate * note_dur)
		for i in range(frames):
			var t = float(i) / stream.mix_rate
			var env = 1.0 - (t / note_dur)
			var s = sin(TAU * freq * t) * env * 0.7
			pb.push_frame(Vector2(s, s))

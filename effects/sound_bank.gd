class_name SoundBank
extends Node
## Original PCM chimes, synthesized once per scene. No downloaded sound assets.

var _streams := {}
var _voices: Array[AudioStreamPlayer] = []
var _voice := 0


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	for i in 4:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)
	for kind: String in ["jump", "land", "plant", "star", "shatter", "death", "undo", "clear", "ui"]:
		_streams[kind] = _synthesize(kind)


func play(kind: String) -> void:
	if _voices.is_empty() or bool(Game.settings.muted) or float(Game.settings.volume) <= 0.0:
		return
	var voice := _voices[_voice]
	_voice = (_voice + 1) % _voices.size()
	voice.stream = _streams.get(kind, _streams.ui)
	voice.volume_db = linear_to_db(float(Game.settings.volume)) - 12.0
	voice.play()


static func _synthesize(kind: String) -> AudioStreamWAV:
	var pitches := {"jump": 440.0, "land": 100.0, "plant": 523.25, "star": 880.0,
		"shatter": 1600.0, "death": 160.0, "undo": 350.0, "clear": 659.25, "ui": 660.0}
	var duration := 0.42 if kind in ["clear", "plant", "star"] else 0.16
	var rate := 22050
	var samples := int(duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	var frequency: float = pitches.get(kind, 440.0)
	for i in samples:
		var time := float(i) / rate
		var envelope := minf(time / 0.008, 1.0) * pow(1.0 - time / duration, 2.0)
		var bend := 1.0 + time * (2.0 if kind == "jump" else -0.4)
		var wave := sin(TAU * frequency * bend * time) * 0.6 + sin(TAU * frequency * 2.0 * time) * 0.18
		if kind == "shatter":
			wave = sin(float(i * i) * 0.31) * 0.45
		if kind in ["plant", "star", "clear"]:
			wave += sin(TAU * frequency * 1.5 * time) * 0.2
		var sample := int(clampf(wave * envelope, -1.0, 1.0) * 28000.0)
		bytes[i * 2] = sample & 255
		bytes[i * 2 + 1] = (sample >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream

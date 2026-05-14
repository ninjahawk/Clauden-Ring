extends Node

# Procedural audio — no external files needed.
# All sounds synthesized via AudioStreamGenerator.

const SAMPLE_RATE := 44100.0

func _ready() -> void:
	pass

func play_hit_player() -> void:
	_play(_gen_hit_player(), -6.0)

func play_hit_enemy() -> void:
	_play(_gen_hit_enemy(), -8.0)

func play_dodge() -> void:
	_play(_gen_dodge(), -10.0)

func play_attack() -> void:
	_play(_gen_attack(), -10.0)

func play_death() -> void:
	_play(_gen_death(), -4.0)

func play_projectile_fire() -> void:
	_play(_gen_projectile_fire(), -8.0)

func play_projectile_impact() -> void:
	_play(_gen_projectile_impact(), -8.0)

func _play(stream: AudioStreamWAV, volume_db: float) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.volume_db = volume_db
	player.play()
	player.finished.connect(player.queue_free)

# --- Waveform generators ---

func _gen_hit_player() -> AudioStreamWAV:
	# Low thud + noise burst
	var dur := 0.18
	var samples := _make_buffer(dur)
	for i in samples.size():
		var t: float = i / SAMPLE_RATE
		var env: float = exp(-t * 18.0)
		var thud: float = sin(TAU * 60.0 * t) * env
		var noise: float = (randf() * 2.0 - 1.0) * env * 0.4
		samples[i] = clampf(thud + noise, -1.0, 1.0)
	return _to_wav(samples)

func _gen_hit_enemy() -> AudioStreamWAV:
	# Sharp click
	var dur := 0.1
	var samples := _make_buffer(dur)
	for i in samples.size():
		var t: float = i / SAMPLE_RATE
		var env: float = exp(-t * 40.0)
		var click: float = sin(TAU * 400.0 * t * (1.0 - t * 3.0)) * env
		samples[i] = clampf(click, -1.0, 1.0)
	return _to_wav(samples)

func _gen_dodge() -> AudioStreamWAV:
	# Quick whoosh
	var dur := 0.15
	var samples := _make_buffer(dur)
	for i in samples.size():
		var t: float = i / SAMPLE_RATE
		var env: float = exp(-t * 12.0) * (1.0 - exp(-t * 60.0))
		var freq: float = 300.0 + 800.0 * (1.0 - t / dur)
		var whoosh: float = sin(TAU * freq * t) * env * 0.5
		var noise: float = (randf() * 2.0 - 1.0) * env * 0.5
		samples[i] = clampf(whoosh + noise, -1.0, 1.0)
	return _to_wav(samples)

func _gen_attack() -> AudioStreamWAV:
	# Sword swing whoosh
	var dur := 0.2
	var samples := _make_buffer(dur)
	for i in samples.size():
		var t: float = i / SAMPLE_RATE
		var env: float = exp(-t * 10.0) * (1.0 - exp(-t * 80.0))
		var freq: float = 180.0 + 400.0 * t / dur
		var swing: float = sin(TAU * freq * t) * env * 0.4
		var noise: float = (randf() * 2.0 - 1.0) * env * 0.6
		samples[i] = clampf(swing + noise, -1.0, 1.0)
	return _to_wav(samples)

func _gen_death() -> AudioStreamWAV:
	# Low descending tone with noise
	var dur := 0.5
	var samples := _make_buffer(dur)
	for i in samples.size():
		var t: float = i / SAMPLE_RATE
		var env: float = exp(-t * 4.0)
		var freq: float = 120.0 - 80.0 * (t / dur)
		var tone: float = sin(TAU * freq * t) * env * 0.7
		var noise: float = (randf() * 2.0 - 1.0) * env * 0.3
		samples[i] = clampf(tone + noise, -1.0, 1.0)
	return _to_wav(samples)

func _gen_projectile_fire() -> AudioStreamWAV:
	# Sci-fi "pew" rising tone
	var dur := 0.12
	var samples := _make_buffer(dur)
	for i in samples.size():
		var t: float = i / SAMPLE_RATE
		var env: float = exp(-t * 20.0)
		var freq: float = 200.0 + 1200.0 * (t / dur)
		var pew: float = sin(TAU * freq * t) * env
		samples[i] = clampf(pew, -1.0, 1.0)
	return _to_wav(samples)

func _gen_projectile_impact() -> AudioStreamWAV:
	# Short crack
	var dur := 0.1
	var samples := _make_buffer(dur)
	for i in samples.size():
		var t: float = i / SAMPLE_RATE
		var env: float = exp(-t * 30.0)
		var crack: float = (randf() * 2.0 - 1.0) * env
		samples[i] = clampf(crack, -1.0, 1.0)
	return _to_wav(samples)

# --- Helpers ---

func _make_buffer(duration: float) -> PackedFloat32Array:
	var count := int(SAMPLE_RATE * duration)
	var buf := PackedFloat32Array()
	buf.resize(count)
	return buf

func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = false
	wav.mix_rate = int(SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var s := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		bytes[i * 2] = s & 0xFF
		bytes[i * 2 + 1] = (s >> 8) & 0xFF
	wav.data = bytes
	return wav

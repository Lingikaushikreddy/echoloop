class_name EchoTimeline
extends Control
## Each planted self has a visible state and a bar for its replay progress.

var echoes: Array = []
var ages: Dictionary = {}
var recording_frames := 0


func _draw() -> void:
	var font := ThemeDB.fallback_font
	for i in echoes.size():
		var echo := echoes[i] as Echo
		if not is_instance_valid(echo):
			continue
		var age := int(ages.get(echo, 0))
		var frames := echo.recording.frame_count()
		var state := "walk"
		var color := DemoTheme.CYAN
		if echo.is_shattered:
			state = "broken"
			color = Color("eaa18d")
		elif echo.ghost:
			state = "ghost"
		elif age >= frames:
			state = "wait"
		var x := float(i * 65)
		draw_string(font, Vector2(x, 8), "%d  %s" % [i + 1, state], HORIZONTAL_ALIGNMENT_LEFT, 62, 8, color)
		draw_rect(Rect2(x, 12, 52, 2), Color("43616c"))
		var progress := minf(float(age) / maxi(frames, 1), 1.0)
		draw_rect(Rect2(x, 12, 52 * progress, 2), color)
	var seconds := float(recording_frames) / Engine.physics_ticks_per_second
	var text := "Trail %.1fs / 60" % seconds if recording_frames < EchoRecording.MAX_FRAMES else "Trail full — R keeps 60s"
	draw_string(font, Vector2(331, 8), text, HORIZONTAL_ALIGNMENT_RIGHT, 130, 8, DemoTheme.MUTED)
	draw_rect(Rect2(331, 12, 130, 2), Color("43616c"))
	draw_rect(Rect2(331, 12, 130 * float(recording_frames) / EchoRecording.MAX_FRAMES, 2), DemoTheme.CYAN)

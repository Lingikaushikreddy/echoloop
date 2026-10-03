class_name Level
extends Node2D
## One room. Builds itself from `map`, then runs the loop: every attempt starts at
## tick 0 with each committed echo replaying beside the player.

signal completed(echoes_used: int)

const ECHO_SCENE := preload("res://actors/echo.tscn")
const SWITCH_SCENE := preload("res://props/switch.tscn")
const DOOR_SCENE := preload("res://props/door.tscn")
const EXIT_SCENE := preload("res://props/exit_flag.tscn")
const DEATH_TICKS := 24  ## about 0.4 s
const KILL_MARGIN := 36.0

@export var title := ""
@export var hint := ""
@export_range(0, 4) var max_echoes := 0
@export_range(0, 4) var par_echoes := 0
## Letters of doors that stay open once triggered, for example "b".
@export var latch_doors := ""
@export_multiline var map := ""
@export var saw_travel := Vector2(0, -72)
@export_range(60, 600) var saw_period := 240
@export var saw_phase := 0
@export var lift_travel := Vector2(0, -90)
@export_range(30, 300) var lift_duration := 120

var level_map: LevelMap
var spawn_point := Vector2.ZERO
var is_complete := false
var effects: WorldEffects
var overlay: GameOverlay

var _death_ticks_left := -1
var _restart_queued := false

@onready var terrain: TileMapLayer = $Terrain
@onready var props: Node2D = $Props
@onready var echoes_root: Node2D = $Echoes
@onready var player: Player = $Player
@onready var loop: LoopController = $LoopController
@onready var camera: Camera2D = $Camera
@onready var hud: Hud = $Hud


func _ready() -> void:
	level_map = LevelMap.parse(map)
	if not level_map.is_valid():
		push_error("%s: %s" % [scene_file_path, ", ".join(level_map.errors)])
		return
	_build_terrain()
	_build_props()
	var scenery := ClocklandsScenery.new()
	scenery.configure(Vector2(level_map.size) * LevelMap.TILE, true)
	add_child(scenery)
	effects = WorldEffects.attach(self, player)
	overlay = GameOverlay.attach(self)
	hud.pause_requested.connect(overlay.pause_game)
	spawn_point = LevelMap.cell_floor(level_map.spawn)
	player.kill_y = level_map.size.y * LevelMap.TILE + KILL_MARGIN
	player.died.connect(_on_player_died)
	loop.ticked.connect(_on_ticked)
	loop.echoes_changed.connect(hud.set_echoes)
	loop.setup(max_echoes)
	_setup_camera()
	hud.set_title(title)
	hud.set_hint(hint)
	_restart()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"commit"):
		commit_attempt()
	elif event.is_action_pressed(&"retry"):
		retry()
	elif event.is_action_pressed(&"undo"):
		undo_echo()
	elif event.is_action_pressed(&"next_room") and is_complete:
		Game.goto_next_level()
	else:
		return
	get_viewport().set_input_as_handled()


## Keeps this attempt as an echo and starts the next loop. Returns false if refused.
func commit_attempt() -> bool:
	if is_complete or _restart_queued or not player.active:
		return false
	if not loop.commit(player.recorder.recording):
		if not loop.can_commit():
			hud.show_message("Echo limit: Undo (Backspace) or Retry (T)")
		return false
	_queue_restart()
	effects.burst(player.position, Color("80edf0"), "plant")
	return true


## Restarts this attempt without recording it.
func retry() -> void:
	if is_complete:
		return
	_queue_restart()


## Forgets the newest echo and restarts. Returns false if there was none.
func undo_echo() -> bool:
	if is_complete or not loop.undo():
		return false
	_queue_restart()
	effects.burst(player.position, Color("80edf0"), "undo")
	return true


func _queue_restart() -> void:
	if _restart_queued:
		return
	_restart_queued = true
	# Freeze input and recording now, so a committed recording gets no extra frames.
	player.active = false
	# Deferred: restarts can be triggered from physics callbacks (a door crushing the
	# player), and the scene must not be rebuilt in the middle of a physics step.
	_restart.call_deferred()


func _restart() -> void:
	_restart_queued = false
	_death_ticks_left = -1
	for node in get_tree().get_nodes_in_group(&"resettable"):
		if is_ancestor_of(node):
			node.reset_to_start()
	for old in echoes_root.get_children():
		echoes_root.remove_child(old)
		old.queue_free()
	player.respawn(spawn_point)
	for i in loop.recordings.size():
		var echo: Echo = ECHO_SCENE.instantiate()
		echo.setup(loop.recordings[i], i, player)
		echoes_root.add_child(echo)
		echo.shattered.connect(func(body: Echo) -> void:
			effects.burst(body.position, Color("80edf0"), "shatter")
			hud.show_message("Paradox: an echo shattered. Retry brings it back."))
	player.recorder.start()
	loop.reset()
	hud.set_time(0)


func _on_ticked(tick: int) -> void:
	for prop in props.get_children():
		if prop is ClockworkHazard or prop is ClockworkLift:
			prop.apply_tick(tick)
	for echo: Echo in echoes_root.get_children():
		echo.apply_tick(tick)
	var ages := {}
	for echo in echoes_root.get_children():
		ages[echo] = tick
	hud.set_replays(echoes_root.get_children(), ages, player.recorder.recording.frame_count())
	camera.position = player.position
	hud.set_time(tick)
	if _death_ticks_left > 0:
		_death_ticks_left -= 1
		if _death_ticks_left == 0:
			_queue_restart()


func _on_player_died(_cause: StringName) -> void:
	if is_complete:
		return
	_death_ticks_left = DEATH_TICKS


func _on_exit_reached() -> void:
	if is_complete or not player.active:
		return
	is_complete = true
	player.active = false
	effects.burst(player.position, Color("f4cf75"), "clear")
	hud.show_message("Room clear!  Press Enter for the next room.", true)
	Game.note_trial(scene_file_path, loop.recordings.size())
	var key := scene_file_path.get_file().get_basename()
	overlay.show_results(loop.recordings.size(), int(Game.trial_best.get(key, loop.recordings.size())), par_echoes)
	completed.emit(loop.recordings.size())


func _build_terrain() -> void:
	terrain.tile_set = TerrainTileset.build()
	for cell in level_map.solids:
		terrain.set_cell(cell, TerrainTileset.SOURCE_ID, TerrainTileset.tile_for(level_map, cell))


func _build_props() -> void:
	var switch_nodes := {}
	for letter: String in level_map.switches:
		var plate: Switch = SWITCH_SCENE.instantiate()
		plate.position = LevelMap.cell_floor(level_map.switches[letter])
		props.add_child(plate)
		switch_nodes[letter] = plate
	for letter: String in level_map.doors:
		var cells: Array = level_map.doors[letter]
		for cell: Vector2i in cells:
			var door: Door = DOOR_SCENE.instantiate()
			door.mode = Door.Mode.LATCH if latch_doors.contains(letter) else Door.Mode.HOLD
			door.is_top = cells.has(cell + Vector2i.DOWN)
			door.position = LevelMap.cell_center(cell)
			props.add_child(door)
			(switch_nodes[letter] as Switch).pressed_changed.connect(door.on_switch_changed)
	for cell in level_map.spikes:
		var hazard := ClockworkHazard.new()
		hazard.setup(LevelMap.cell_floor(cell), Vector2.ZERO, 0, 0)
		props.add_child(hazard)
	for cell in level_map.saws:
		var hazard := ClockworkHazard.new()
		hazard.setup(LevelMap.cell_center(cell), saw_travel, saw_period, saw_phase)
		props.add_child(hazard)
	for letter: String in level_map.lifts:
		var lift := ClockworkLift.new()
		lift.setup(LevelMap.cell_floor(level_map.lifts[letter]), lift_travel, lift_duration)
		props.add_child(lift)
		(switch_nodes[letter] as Switch).pressed_changed.connect(lift.on_switch_changed)
	var exit: ExitFlag = EXIT_SCENE.instantiate()
	exit.position = LevelMap.cell_floor(level_map.exit)
	exit.reached.connect(_on_exit_reached)
	props.add_child(exit)


func _setup_camera() -> void:
	var world := Vector2(level_map.size) * LevelMap.TILE
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world.x)
	camera.limit_bottom = int(world.y)
	camera.position = world / 2.0

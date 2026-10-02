class_name OpenWorld
extends Node2D
## The Clocklands: one continuous map, not a stack of rooms.
##
## In a room, Commit rewinds time and the echo replays from the start. Out here,
## R plants the trail you just walked and you stay put. The echo replays that
## trail in the world and freezes at the end, holding a switch or waiting as a
## step, while you keep walking. Stars stay collected. Death and Retry (T) send
## you to the last trailhead (@) and leave every planted echo where it is.

signal completed(echoes_used: int)

const ECHO_SCENE := preload("res://actors/echo.tscn")
const SWITCH_SCENE := preload("res://props/switch.tscn")
const DOOR_SCENE := preload("res://props/door.tscn")
const EXIT_SCENE := preload("res://props/exit_flag.tscn")
const STAR_SCENE := preload("res://props/star.tscn")
const DEATH_TICKS := 24
const KILL_MARGIN := 36.0

## x0/x1 are tile columns. The spawn column decides the opening region.
const REGIONS: Array[Dictionary] = [
	{
		"x0": 0, "x1": 20,
		"title": "The Gate",
		"blurb": "The near star is a jump. Plant an echo on the switch, wait on the shelf, then take the far star.",
	},
	{
		"x0": 21, "x1": 55,
		"title": "The Meadow",
		"blurb": "The island overhead is scenery. A cyan marker sets your trailhead. The summit is east.",
	},
	{
		"x0": 56, "x1": 80,
		"title": "The Summit",
		"blurb": "Plant an echo at the cliff and jump over it as it walks back. Climb it once it stops.",
	},
]

@export_range(0, 4) var max_echoes := 4
@export_multiline var map := ""

var level_map: LevelMap
var anchor_point := Vector2.ZERO
var is_complete := false
var found_stars: Array[Vector2i] = []

var _death_ticks_left := -1
var _trail_cell := Vector2i(-999, -999)
var _ages := {}
var _seen_regions := {}

@onready var terrain: TileMapLayer = $Terrain
@onready var props: Node2D = $Props
@onready var echoes_root: Node2D = $Echoes
@onready var player: Player = $Player
@onready var loop: LoopController = $LoopController
@onready var camera: Camera2D = $Camera
@onready var hud: Hud = $Hud


func star_count() -> int:
	return found_stars.size()


func star_total() -> int:
	return 0 if level_map == null else level_map.stars.size()


func _ready() -> void:
	level_map = LevelMap.parse(map)
	if not level_map.is_valid():
		push_error("Clocklands: %s" % ", ".join(level_map.errors))
		return
	_build_sky()
	_build_terrain()
	_build_props()
	anchor_point = LevelMap.cell_floor(level_map.spawn)
	_trail_cell = level_map.spawn
	player.kill_y = level_map.size.y * LevelMap.TILE + KILL_MARGIN
	player.died.connect(_on_player_died)
	loop.ticked.connect(_on_ticked)
	loop.echoes_changed.connect(hud.set_echoes)
	loop.setup(max_echoes)
	_setup_camera()
	player.respawn(anchor_point)
	player.recorder.start()
	hud.set_hint("R plants an echo and you keep walking. T returns to the trailhead. Backspace forgets one.")
	hud.set_stars(0, star_total())
	_seen_regions[_region_at(level_map.spawn.x).title] = true
	_update_region()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"commit"):
		plant_echo()
	elif event.is_action_pressed(&"retry"):
		return_to_trailhead()
	elif event.is_action_pressed(&"undo"):
		undo_echo()
	elif event.is_action_pressed(&"next_room") and is_complete and get_tree().current_scene == self:
		get_tree().reload_current_scene()
	else:
		return
	get_viewport().set_input_as_handled()


## Keeps the current trail as an echo and starts a fresh trail from here.
## You do not move. Returns false if nothing was recorded yet or the limit is full.
func plant_echo() -> bool:
	if is_complete or not player.active:
		return false
	if not loop.commit(player.recorder.recording):
		if not loop.can_commit():
			hud.show_message("Echo limit: Undo (Backspace) or Retry (T)")
		return false
	var echo: Echo = ECHO_SCENE.instantiate()
	echo.setup(loop.recordings[-1], loop.recordings.size() - 1, player)
	echoes_root.add_child(echo)
	_ages[echo] = 0
	player.recorder.start()
	hud.show_message("Echo planted. It will walk that trail and wait.")
	return true


## Forgets the newest echo. You stay where you are. Returns false if there was none.
func undo_echo() -> bool:
	if is_complete or not player.active or not loop.undo():
		return false
	var last := echoes_root.get_child(-1)
	_ages.erase(last)
	echoes_root.remove_child(last)
	last.queue_free()
	hud.show_message("The newest echo fades.")
	return true


## Back to the last trailhead. Planted echoes and collected stars stay.
func return_to_trailhead() -> void:
	if is_complete:
		return
	_death_ticks_left = -1
	player.respawn(anchor_point)
	player.recorder.start()
	_trail_cell = LevelMap.cell_at_feet(anchor_point)


func collect_star(star: Star) -> void:
	if found_stars.has(star.cell):
		return
	found_stars.append(star.cell)
	star.queue_free()
	hud.set_stars(star_count(), star_total())
	if star_count() == star_total():
		hud.show_message("Every star is yours. The summit will open.")


func _region_at(column: int) -> Dictionary:
	for region: Dictionary in REGIONS:
		if column >= int(region.x0) and column <= int(region.x1):
			return region
	return REGIONS[0]


func _update_region() -> void:
	var region := _region_at(LevelMap.cell_at_feet(player.position).x)
	hud.set_title(region.title)
	var title: String = region.title
	if _seen_regions.has(title):
		return
	_seen_regions[title] = true
	hud.show_message(region.blurb)


func _update_trailhead() -> void:
	var cell := LevelMap.cell_at_feet(player.position)
	if cell == _trail_cell:
		return
	if cell != level_map.spawn and not level_map.anchors.has(cell):
		return
	_trail_cell = cell
	anchor_point = LevelMap.cell_floor(cell)
	# The next echo should replay from here, not from the other side of the map.
	player.recorder.start()
	hud.show_message("Trailhead set")


func _on_ticked(_tick: int) -> void:
	for node in echoes_root.get_children():
		var echo := node as Echo
		if echo == null:
			continue
		var age := int(_ages.get(echo, 0))
		echo.apply_tick(age)
		_ages[echo] = age + 1
	camera.position = player.position
	if _death_ticks_left > 0:
		_death_ticks_left -= 1
		if _death_ticks_left == 0:
			return_to_trailhead()
		return
	if player.active:
		_update_region()
		_update_trailhead()


func _on_player_died(_cause: StringName) -> void:
	if is_complete:
		return
	_death_ticks_left = DEATH_TICKS
	hud.show_message("Back to the trailhead.")


func _on_exit_reached() -> void:
	if is_complete or not player.active:
		return
	if star_count() < star_total():
		hud.show_message("The summit stays shut until every star is found.")
		return
	is_complete = true
	player.active = false
	hud.show_message("The Clocklands remember you. Press Enter to walk them again.", true)
	completed.emit(loop.recordings.size())


func _build_sky() -> void:
	var sky := Node2D.new()
	sky.name = "Sky"
	sky.z_index = -10
	add_child(sky)
	move_child(sky, 0)
	var clouds: Array[Dictionary] = [
		{"at": Vector2(120, 46), "w": 78.0},
		{"at": Vector2(340, 34), "w": 96.0},
		{"at": Vector2(640, 50), "w": 70.0},
		{"at": Vector2(980, 40), "w": 110.0},
	]
	for spec: Dictionary in clouds:
		var cloud := Polygon2D.new()
		var w := float(spec.w)
		var poly := PackedVector2Array()
		poly.append(Vector2(-w, 8))
		poly.append(Vector2(-w * 0.55, -6))
		poly.append(Vector2(-w * 0.15, -2))
		poly.append(Vector2(w * 0.2, -9))
		poly.append(Vector2(w * 0.6, -1))
		poly.append(Vector2(w, 8))
		cloud.polygon = poly
		cloud.color = Color(0.9, 0.95, 0.98, 0.45)
		cloud.position = spec.at
		sky.add_child(cloud)


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
			door.mode = Door.Mode.HOLD
			door.is_top = cells.has(cell + Vector2i.DOWN)
			door.position = LevelMap.cell_center(cell)
			props.add_child(door)
			(switch_nodes[letter] as Switch).pressed_changed.connect(door.on_switch_changed)
	for cell in level_map.stars:
		var star: Star = STAR_SCENE.instantiate()
		star.cell = cell
		star.position = LevelMap.cell_floor(cell)
		star.collected.connect(collect_star)
		props.add_child(star)
	for cell in level_map.anchors:
		_mark_trailhead(cell)
	var exit: ExitFlag = EXIT_SCENE.instantiate()
	exit.position = LevelMap.cell_floor(level_map.exit)
	exit.reached.connect(_on_exit_reached)
	props.add_child(exit)


func _mark_trailhead(cell: Vector2i) -> void:
	var mark := Polygon2D.new()
	mark.color = Color(0.45, 0.95, 1, 0.9)
	mark.polygon = PackedVector2Array([
		Vector2(0, -16), Vector2(5, -9), Vector2(0, -2), Vector2(-5, -9)])
	mark.position = LevelMap.cell_floor(cell)
	props.add_child(mark)


func _setup_camera() -> void:
	var world := Vector2(level_map.size) * LevelMap.TILE
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world.x)
	camera.limit_bottom = int(world.y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.position = anchor_point

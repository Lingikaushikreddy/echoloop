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
		"blurb": "The island is a second climb, if you can spare two echoes. The summit is east.",
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
var effects: WorldEffects
var found_stars: Array[Vector2i] = []

var _death_ticks_left := -1
var _trail_cell := Vector2i(-999, -999)
var _ages := {}
var _trails := {}
var _seen_regions := {}
var _mentioned_island := false
var _met_yourself := false

var trails: Node2D

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


## Stars the summit asks for. The island star is not one of them.
func required_found() -> int:
	var found := 0
	for cell in level_map.stars:
		if found_stars.has(cell):
			found += 1
	return found


func secret_found() -> bool:
	for cell in level_map.secrets:
		if found_stars.has(cell):
			return true
	return false


func _ready() -> void:
	level_map = LevelMap.parse(map)
	if not level_map.is_valid():
		push_error("Clocklands: %s" % ", ".join(level_map.errors))
		return
	_build_sky()
	_build_terrain()
	_build_props()
	effects = WorldEffects.attach(self, player)
	trails = Node2D.new()
	trails.name = "Trails"
	trails.z_index = 2
	add_child(trails)
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
	hud.set_hint("R leaves you on the trail. The line shows where they will walk.")
	_refresh_stars()
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
	echo.shattered.connect(func(body: Echo) -> void:
		effects.burst(body.position, Color("80edf0"), "shatter")
		hud.show_message("Paradox: your echo shattered. Undo frees its slot."))
	_ages[echo] = 0
	_trails[echo] = _draw_trail(loop.recordings[-1])
	player.recorder.start()
	hud.show_message("You leave yourself here. Follow the line.")
	effects.burst(player.position, Color("80edf0"), "plant")
	_refresh_stars()
	return true


## Forgets the newest echo. You stay where you are. Returns false if there was none.
func undo_echo() -> bool:
	if is_complete or not player.active or not loop.undo():
		return false
	var last := echoes_root.get_child(-1)
	_ages.erase(last)
	var line: Line2D = _trails.get(last)
	_trails.erase(last)
	if line != null:
		line.queue_free()
	echoes_root.remove_child(last)
	last.queue_free()
	effects.burst(player.position, Color("80edf0"), "undo")
	hud.show_message("The newest echo fades.")
	_refresh_stars()
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
	var kept_secret := level_map.secrets.has(star.cell)
	found_stars.append(star.cell)
	effects.burst(star.position, Color("f4cf75"), "star")
	star.queue_free()
	_refresh_stars()
	if kept_secret:
		hud.show_message("The island kept this one. The summit never asked.")
	elif required_found() == star_total():
		if secret_found():
			hud.show_message("Every star is yours, island included. The summit will open.")
		else:
			hud.show_message("The road's stars are yours. The summit will open. Look up on the way.")


func _refresh_stars() -> void:
	hud.set_stars(required_found(), star_total(), _compass())


func _compass() -> String:
	var pool: Array[Vector2i] = []
	for cell in level_map.stars:
		if not found_stars.has(cell):
			pool.append(cell)
	if pool.is_empty():
		for cell in level_map.secrets:
			if not found_stars.has(cell):
				pool.append(cell)
	if pool.is_empty():
		return "kept"
	var nearest := pool[0]
	var nearest_d := player.position.distance_to(LevelMap.cell_floor(nearest))
	for cell in pool:
		var distance := player.position.distance_to(LevelMap.cell_floor(cell))
		if distance < nearest_d:
			nearest = cell
			nearest_d = distance
	var there := LevelMap.cell_floor(nearest)
	var dx := there.x - player.position.x
	var dy := there.y - player.position.y
	if dy < -40.0 and absf(dx) < 140.0:
		return "above"
	if dx < -24.0:
		return "west"
	if dx > 24.0:
		return "east"
	return "here"


func _draw_trail(recording: EchoRecording) -> Line2D:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(0.55, 0.95, 1, 0.7)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var count := recording.frame_count()
	var i := 0
	while i < count:
		line.add_point(recording.position_at(i) + Vector2(0, -6))
		i += 3
	var last := recording.position_at(count - 1) + Vector2(0, -6)
	if line.get_point_count() == 0 or line.get_point_position(line.get_point_count() - 1).distance_to(last) > 1.0:
		line.add_point(last)
	trails.add_child(line)
	return line


func _maybe_mention_island() -> void:
	if _mentioned_island or level_map.secrets.is_empty():
		return
	var cell := LevelMap.cell_at_feet(player.position)
	var secret: Vector2i = level_map.secrets[0]
	if cell.y == level_map.spawn.y and absi(cell.x - secret.x) <= 4:
		_mentioned_island = true
		hud.show_message("Two of you can climb the island. The road does not need them.")


func _maybe_greet() -> void:
	if _met_yourself:
		return
	for node in echoes_root.get_children():
		var echo := node as Echo
		if echo == null or echo.ghost or echo.is_shattered:
			continue
		if int(_ages.get(echo, 0)) < echo.recording.frame_count():
			continue
		if echo.position.distance_to(player.position) > 42.0:
			continue
		_met_yourself = true
		hud.show_message("You, waiting. They will not move again.")
		return


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
		_maybe_mention_island()
		_maybe_greet()
		_refresh_stars()


func _on_player_died(_cause: StringName) -> void:
	if is_complete:
		return
	_death_ticks_left = DEATH_TICKS
	hud.show_message("Back to the trailhead.")


func _on_exit_reached() -> void:
	if is_complete or not player.active:
		return
	if required_found() < star_total():
		hud.show_message("The summit stays shut until every star is found.")
		return
	is_complete = true
	player.active = false
	effects.burst(player.position, Color("f4cf75"), "clear")
	var echoes_used := loop.recordings.size()
	Game.note_clocklands(echoes_used, secret_found())
	var ending := "Echoes %d, best %d. " % [echoes_used, Game.best_echoes]
	if secret_found():
		ending += "You left someone on the island."
	elif Game.found_island:
		ending += "You have been to the island. This walk stayed on the road."
	else:
		ending += "The island is still waiting."
	ending += " Enter walks it again."
	hud.show_message(ending, true)
	completed.emit(echoes_used)


func _build_sky() -> void:
	var scenery := ClocklandsScenery.new()
	scenery.name = "Sky"
	scenery.configure(Vector2(level_map.size) * LevelMap.TILE, false)
	add_child(scenery)


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
		_add_star(cell, false)
	for cell in level_map.secrets:
		_add_star(cell, true)
	for cell in level_map.anchors:
		_mark_trailhead(cell)
	var exit: ExitFlag = EXIT_SCENE.instantiate()
	exit.position = LevelMap.cell_floor(level_map.exit)
	exit.reached.connect(_on_exit_reached)
	props.add_child(exit)


func _add_star(cell: Vector2i, secret: bool) -> void:
	var star: Star = STAR_SCENE.instantiate()
	star.cell = cell
	star.secret = secret
	star.position = LevelMap.cell_floor(cell)
	star.collected.connect(collect_star)
	props.add_child(star)


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

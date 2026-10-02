class_name LevelMap
extends RefCounted
## Parses a level drawn as text, one character per 18×18 tile.
##
##   .  empty            #  solid ground
##   S  player spawn     E  exit flag          (exactly one of each)
##   a-d  pressure switch (at most one per letter)
##   A-D  door tile, opened by the switch with the same letter
##   *  star             @  trailhead          (any number, open world only)
##
## Every row must be the same width. Problems are collected in `errors` instead
## of crashing, so a broken level says what is wrong.

const TILE := 18

var size := Vector2i.ZERO
var solids: Array[Vector2i] = []
var spawn := Vector2i(-1, -1)
var exit := Vector2i(-1, -1)
var switches := {}  ## letter -> Vector2i
var doors := {}  ## letter -> Array of Vector2i
var stars: Array[Vector2i] = []
var anchors: Array[Vector2i] = []
var errors := PackedStringArray()


static func parse(text: String) -> LevelMap:
	var result := LevelMap.new()
	var rows: Array[String] = []
	for line in text.split("\n"):
		var row := line.strip_edges()
		if not row.is_empty():
			rows.append(row)
	if rows.is_empty():
		result.errors.append("map is empty")
		return result

	result.size = Vector2i(rows[0].length(), rows.size())
	var spawns: Array[Vector2i] = []
	var exits: Array[Vector2i] = []
	for y in rows.size():
		var row := rows[y]
		if row.length() != result.size.x:
			result.errors.append("row %d is %d wide, expected %d" % [y, row.length(), result.size.x])
			continue
		for x in row.length():
			var cell := Vector2i(x, y)
			var ch := row[x]
			match ch:
				".":
					pass
				"#":
					result.solids.append(cell)
				"S":
					spawns.append(cell)
				"E":
					exits.append(cell)
				"*":
					result.stars.append(cell)
				"@":
					result.anchors.append(cell)
				_:
					if ch >= "a" and ch <= "d":
						if result.switches.has(ch):
							result.errors.append("switch %s appears more than once" % ch)
						result.switches[ch] = cell
					elif ch >= "A" and ch <= "D":
						var letter := ch.to_lower()
						if not result.doors.has(letter):
							result.doors[letter] = []
						result.doors[letter].append(cell)
					else:
						result.errors.append("unknown tile '%s' at %d,%d" % [ch, x, y])

	if spawns.size() == 1:
		result.spawn = spawns[0]
	else:
		result.errors.append("expected exactly one S, found %d" % spawns.size())
	if exits.size() == 1:
		result.exit = exits[0]
	else:
		result.errors.append("expected exactly one E, found %d" % exits.size())
	for letter: String in result.doors:
		if not result.switches.has(letter):
			result.errors.append("door %s has no switch %s" % [letter.to_upper(), letter])
	return result


func is_valid() -> bool:
	return errors.is_empty()


func is_solid(cell: Vector2i) -> bool:
	return solids.has(cell)


## World position of the bottom-centre of a cell: where feet stand.
static func cell_floor(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)


## Inverse of `cell_floor`: the cell whose floor the feet are standing on.
## Feet sit on the bottom edge of that cell, so the y test uses a 1 px bias.
static func cell_at_feet(feet: Vector2) -> Vector2i:
	return Vector2i(floori(feet.x / float(TILE)), floori((feet.y - 1.0) / float(TILE)))

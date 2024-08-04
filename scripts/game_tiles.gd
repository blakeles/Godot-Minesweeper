extends TileMap

const TILES : Dictionary = { # Holds name of the tile and associated position of tile in TileAtlas
	"Tile1": Vector2i(0,0),
	"Tile2": Vector2i(1,0),
	"Tile3": Vector2i(2,0),
	"Tile4": Vector2i(3,0),
	"Tile5": Vector2i(4,0),
	"Tile6": Vector2i(0,1),
	"Tile7": Vector2i(1,1),
	"Tile8": Vector2i(2,1),
	"TileBlank": Vector2i(3,1),
	"TileExploded": Vector2i(4,1),
	"TileFlag": Vector2i(0,2),
	"TileMine": Vector2i(1,2),
	"TileUnpressed": Vector2i(2,2),
}
const DIFFICULTIES : Dictionary = { # Holds the values that should be changed depending on the difficulty set
	"easy": {"x": 6, "y": 6, "mines": 5, "pos": Vector2i(48,300), "scale": Vector2i(5,5)},
	"medium": {"x": 8, "y": 8, "mines": 10, "pos": Vector2i(32,300), "scale": Vector2i(4,4)},
	"hard": {"x": 10, "y": 10, "mines": 25, "pos": Vector2i(8,300), "scale": Vector2(3.5,3.5)}
}

var rows : int = 8 # Rows of tiles
var columns : int = 8 # Columns of tiles
var total_mines : int = 10 # Number of mine tiles

var mine_tiles : Array[Vector2i] = [] # Holds coordinates of which tiles are mines
var tiles_clicked : Array[Vector2i] = [] # Holds coordinates of tiles that have already been clicked
var in_play : bool = false # If the game is in play
var game_bounds : Rect2i # The bounds of the game (0,0 to rows,columns)

var flag : bool = false # If the flag is on
var flagged_tiles : Array[Vector2i] = [] # All flagged tiles

signal start_time
signal game_lost
signal game_won

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			# Handle tile click event if it is in bounds of board
			var click_position : Vector2i = local_to_map(to_local(get_viewport().get_mouse_position()))
			if in_bounds(click_position) && in_play: on_tile_click(click_position)

'''
set_bounds
- Sets the bounds of the game to (0,0 to rows,columns)
'''	
func set_game_bounds():
	game_bounds = Rect2i(0,0,rows,columns)

'''
in_bounds
- Checks whether the point given is within the bounds of the game
'''
func in_bounds(coord : Vector2i):
	return game_bounds.has_point(coord)

'''
set_tile
- Sets the tile given to the appropriate type
'''
func set_tile(tile_coord : Vector2i, tile_type : String): 
	erase_cell(0, tile_coord)
	set_cell(0, tile_coord, 0, TILES["Tile"+tile_type], 0)

'''
create_tiles
- First deletes any tiles on the layer and resets the game's variables
- Sets the tiles of the game within the bounds
'''
func create_tiles():
	tiles_clicked = []
	flagged_tiles = []
	in_play = true
	clear_layer(0)
	create_mine_tiles()
	for row in rows:
		for column in columns:
			var tile_coord = Vector2i(row,column)
			set_tile(tile_coord, "Unpressed")

'''
create_mine_tiles
- Randomly chooses tiles to be mines
'''
func create_mine_tiles():
	mine_tiles = [] 
	while mine_tiles.size() < total_mines:
		var mine_tile = Vector2i(randi_range(0,rows-1), randi_range(0,columns-1))
		if mine_tile not in mine_tiles: mine_tiles.append(mine_tile)
	mine_tiles.sort()

'''
on_tile_click
- Performs the necessary action when the tile is clicked
- Called recursively
'''
func on_tile_click(tile_coord : Vector2i):
	if tile_coord not in tiles_clicked: # Can't click a tile if it has already been clicked
		if !flag: # Handle non-flag clicks
			if tile_coord in flagged_tiles: flagged_tiles.remove_at(flagged_tiles.find(tile_coord))
			if tile_coord not in mine_tiles:
				tiles_clicked.append(tile_coord)
				var nearby_mines : int = get_mine_count(tile_coord)
				if nearby_mines == 0:
					set_tile(tile_coord, "Blank")
					check_adjacent_tiles(tile_coord)
				else:
					set_tile(tile_coord, str(nearby_mines))
			else:
				set_tile(tile_coord, "Exploded")
				handle_game_over(tile_coord)
		else: # Handle flag clicks
			if tile_coord not in flagged_tiles:
				if flagged_tiles.size() < total_mines:
					flagged_tiles.append(tile_coord)
					set_tile(tile_coord, "Flag")
			else:
				flagged_tiles.remove_at(flagged_tiles.find(tile_coord,0))
				set_tile(tile_coord, "Unpressed")
			check_flag(tile_coord)

'''
get_mine_count
- Gets the count of mines in the 8 surrounds tiles
'''
func get_mine_count(tile_coord : Vector2i):
	var mine_count : int = 0
	for x in range(tile_coord.x-1,tile_coord.x+2):
		for y in range(tile_coord.y-1,tile_coord.y+2):
			if Vector2i(x,y) in mine_tiles:
				mine_count += 1
	return mine_count
		
'''
check_adjacent_tiles
- Clicks the tiles north, east, south and west of the original click
- Only called if the tile that was originally clicked had no surrounding mines
'''
func check_adjacent_tiles(tile_coord : Vector2i):
	var tiles_to_check : Array[Vector2i] = [Vector2i(tile_coord.x,tile_coord.y+1), Vector2i(tile_coord.x+1,tile_coord.y), Vector2i(tile_coord.x,tile_coord.y-1), Vector2i(tile_coord.x-1,tile_coord.y)]
	for tile in tiles_to_check:
		if in_bounds(tile):
			on_tile_click(tile)

'''
check_flag
- Checks if mine tiles have been flagged
'''
func check_flag(flag_coord : Vector2i):
	if flagged_tiles.size() != total_mines: return false
	flagged_tiles.sort()
	for i in total_mines:
		if flagged_tiles[i] != mine_tiles[i]:
			return false
	handle_game_win() # If no mismatch is found, game is won

'''
handle_game_win
- Ends the game and tells menu to save the score

handle_game_over
- Ends the game and shows placement of all mines
'''
func handle_game_win():
	in_play = false
	game_won.emit()
func handle_game_over(final_tile : Vector2i):
	in_play = false
	for mine in mine_tiles:
		if mine != final_tile:
			set_tile(mine, "Mine")
			game_lost.emit()

'''
set_difficulty
- Sets the variables which the game rely on depending on the given difficulty
- Starts a new game
'''
func set_difficulty(settings : Dictionary):
	# SET UP GAME
	rows = settings["x"]
	columns = settings["y"]
	total_mines = settings["mines"]
	global_position = settings["pos"]
	scale = settings["scale"]
	# START GAME
	randomize()
	set_game_bounds()
	create_tiles()
	start_time.emit()

func _on_flag_toggled(toggled_on):
	flag = toggled_on
func _on_main_easy():
	set_difficulty(DIFFICULTIES["easy"])
func _on_main_medium():
	set_difficulty(DIFFICULTIES["medium"])
func _on_main_hard():
	set_difficulty(DIFFICULTIES["hard"])

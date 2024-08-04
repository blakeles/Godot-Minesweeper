extends Node2D

signal easy
signal medium
signal hard

var easy_text : String = "00:00"
var medium_text : String = "00:00"
var hard_text : String = "00:00"

func _ready():
	set_scores()
	
'''
set_scores
- Display the quickest time each difficulty has been completed in
'''
func set_scores():
	if FileAccess.file_exists("user://easysweeper.save"): 
		easy_text = FileAccess.open("user://easysweeper.save", FileAccess.READ).get_as_text()
	if FileAccess.file_exists("user://mediumsweeper.save"): 
		medium_text = FileAccess.open("user://mediumsweeper.save", FileAccess.READ).get_as_text()
	if FileAccess.file_exists("user://hardsweeper.save"): 
		hard_text = FileAccess.open("user://hardsweeper.save", FileAccess.READ).get_as_text()
	$'GUI/MENU GUI/VSplitContainer/HIGHSCORE'.text = easy_text + "          " + medium_text + "          " + hard_text


'''
set_new
- Start menu

set_game
- Show game
'''
func set_new():
	set_scores()
	$'GUI/IN GAME GUI'.visible = false
	$'GUI/MENU GUI'.visible = true
func set_game():
	$'GUI/MENU GUI'.visible = false
	$'GUI/IN GAME GUI'.visible = true

func _on_tile_map_game_lost():
	set_new()
func _on_tile_map_game_won():
	set_new()	
func _on_easy_pressed():
	easy.emit()
	set_game()
func _on_medium_pressed():
	medium.emit()
	set_game()
func _on_hard_pressed():
	hard.emit()
	set_game()

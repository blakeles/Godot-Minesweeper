extends Label

var run : bool = false
var minutes : int = 0
var seconds : float = 0
var time_text : String = "00:00"
var difficulty : String = "Medium"

func _physics_process(delta):
	if run:
		seconds = seconds + delta
		update_time()
	
'''
start_timer
- Restarts the timer

stop_timer
- Stops the timer from running
'''
func start_timer():
	minutes = 0
	seconds = 0
	run = true
func stop_timer():
	run = false
	
'''
save_time
- Saves the time to the correct difficulty's save file

check_time
- Checks if the time is faster than the fastest recording time for this diffculty

update_time
- Sets the text of the label to the current time
'''
func save_time():
	var file = FileAccess.open("user://"+difficulty+"sweeper.save", FileAccess.WRITE)
	file.store_string(time_text)
func check_time():
	if FileAccess.file_exists("user://"+difficulty+"sweeper.save"):
		var file = FileAccess.open("user://"+difficulty+"sweeper.save", FileAccess.READ)
		var target = int(file.get_as_text().lstrip(":"))
		var this_time = int(time_text.lstrip(":"))
		if target > this_time && target != 0: save_time()
	else:
		save_time()
func update_time():
	if int(seconds) >= 60:
		minutes += 1
		seconds = 0
		
	var minute_text = str(minutes)
	var second_text = str(int(seconds))
	if minutes < 10: minute_text = "0" + minute_text
	if seconds < 10: second_text = "0" + second_text
	
	time_text = minute_text+":"+second_text
	text = str(time_text)

func _on_tile_map_start_time():
	start_timer()
func _on_tile_map_game_won():
	stop_timer()
	check_time()
func _on_tile_map_game_lost():
	stop_timer()
func _on_main_medium():
	difficulty = "medium"
func _on_main_hard():
	difficulty = "hard"
func _on_main_easy():
	difficulty = "easy"

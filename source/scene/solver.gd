extends Node2D

# Could have set these manually but I feel it was good practice to pull the information
# from the nodes and project settings
onready var tile_length = $grid_tiles.get_cell_size()[0]
onready var window_height = $sudoku_grid_image.texture.get_size()[1]
var window_width = ProjectSettings.get_setting("display/window/size/width")
var selecting = false
var selecting_position_index
var sudoku_grid
var original_grid
var solved = false

func _ready():
	# This is needed to be called on run as it initialises the grid variable
	clear_grid()

func _input(event):
   # Mouse in viewport coordinates
	if event is InputEventMouseButton:
		# If the user presses down the left mouse button
		if event.button_index == BUTTON_LEFT and event.pressed:
			# only allow the user to select a tile if they're not already selecting a tile
			# the problem hasn't been solved, and the y coordinate fits inside the sudoku grid
			# as the window is larger than just the grid due to the buttons at the bottom
			if not selecting and event.position[1] < window_height and not solved:
				# The coordinates the user clicks at need to be converted to integers and fit the index of the grid
				selecting_position_index = [round_position(event.position[0]), round_position(event.position[1])]
				# Sets the cell to be the border so the user can see which tile they're now selecting
				$grid_tiles.set_cell(selecting_position_index[0], selecting_position_index[1], 9)
				selecting = true
				change_text("Select number", Color(255, 255, 255))
	elif event is InputEventKey and event.pressed:
		if selecting and not solved:
			if event.scancode == KEY_ESCAPE:
				# Pressing escape should exit out of selecting the tile they were looking at
				# Using an index of -1 for setting a cell removes any tile from that position
				$grid_tiles.set_cell(selecting_position_index[0], selecting_position_index[1], -1)
				# Since pressing escape is also a method of removing any number from that position that
				# was there previously, the array needs to be updated to have a 0 to represent a blank
				# tile
				sudoku_grid[selecting_position_index[1]][selecting_position_index[0]] = 0
				selecting = false
				change_text("", Color(255, 0, 0))
			else:
				check_number(event)
		elif event.scancode == KEY_R:
			reset()
		elif event.scancode == KEY_ENTER:
			check_if_can_be_solved()

func reset():
	# Resets variables and grid, as if the user was to just open the program again
	clear_grid()
	selecting = false
	solved = false
	change_text("Board reset", Color(255, 255, 255))

func start_solve():
	# Firsts checks the input the user gives
	# Waist of resources trying to solve if the original input can't be solve
	# Also ran into issues when not having this
	if check_input():
		# Copies the user input grid to later check if solved
		copy_original_grid()
		solve()
		# If the original grid the user puts in is the same as the one returned from solving
		# then the sudoku could not be solved
		if str(sudoku_grid) == str(original_grid):
			solved = false
			change_text("No Solutions", Color(255, 0, 0))
		else:
			solved = true
			display_solution()
			change_text("Solved", Color(0, 255, 0))
	else:
		solved = false
		change_text("No Solutions", Color(255, 0, 0))	

func round_position(value):
	# Rounding the number needs to be done by always rounding down
	# so first the remainder of the divison is calculated which is then
	var remainder = int(value) % int(tile_length)
	# taken off and divided again to return a whole number while rounding down	
	return ((value - remainder) / tile_length)

func check_number(event):
	if event.scancode == KEY_1:
		change_number(1)
	elif event.scancode == KEY_2:
		change_number(2)
	elif event.scancode == KEY_3:
		change_number(3)
	elif event.scancode == KEY_4:
		change_number(4)
	elif event.scancode == KEY_5:
		change_number(5)
	elif event.scancode == KEY_6:
		change_number(6)
	elif event.scancode == KEY_7:
		change_number(7)
	elif event.scancode == KEY_8:
		change_number(8)
	elif event.scancode == KEY_9:
		change_number(9)

func change_number(number):
	# Changes the number to be the number of the key pressed
	# Changes both the tile map and the grid position
	$grid_tiles.set_cell(selecting_position_index[0], selecting_position_index[1], number - 1)
	sudoku_grid[selecting_position_index[1]][selecting_position_index[0]] = number
	selecting = false
	change_text("", Color(0, 0, 0))

func check_input():
	# If it detects any tiles that aren't valid in the sudoku then it will return false
	# no point in searching the rest of the array as once one position is invalid
	# the whole sudoku will be invalid
	for row in range(sudoku_grid.size()):
		for col in range(sudoku_grid.size()):
			if sudoku_grid[row][col] != 0:
				if not check_valid(sudoku_grid[row][col], [row, col]):
					return false
	return true

func clear_grid():
	sudoku_grid = [
		[  0, 0, 0, 0, 0, 0, 0, 0, 0],
		[  0, 0, 0, 0, 0, 0, 0, 0, 0],
		[  0, 0, 0, 0, 0, 0, 0, 0, 0],
		[  0, 0, 0, 0, 0, 0, 0, 0, 0],
		[  0, 0, 0, 0, 0, 0, 0, 0, 0],
		[  0, 0, 0, 0, 0, 0, 0, 0, 0],
		[  0, 0, 0, 0, 0, 0, 0, 0, 0],
		[  0, 0, 0, 0, 0, 0, 0, 0, 0],
		[  0, 0, 0, 0, 0, 0, 0, 0, 0],
	]
	# This is not needed on the first load of the program
	# But is needed more for when the user presses the reset button
	for y in range (0, sudoku_grid.size()):
		for x in range(0, sudoku_grid.size()):
			var number = sudoku_grid[y][x]
			$grid_tiles.set_cell(x, y, number - 1)

func display_solution():
	# Compares what is already being displayed compared to what is stored in the array
	# Any that are found to not be displayed are changed to red, to represent
	# the numbers that have been filled in
	for y in range (sudoku_grid.size()):
		for x in range(sudoku_grid.size()):
			if $grid_tiles.get_cell(x, y) == -1:
				var number = sudoku_grid[y][x]
				# Finds the tileID from the name so it can then be set
				var tile_id = $grid_tiles.tile_set.find_tile_by_name(("red_" + str(number)))
				$grid_tiles.set_cell(x, y, tile_id)

func copy_original_grid():
	original_grid = str(sudoku_grid)

func check_repeating_number_row(attempted_number, index):
	# Will check for any of the same number in a column
	for col in range(sudoku_grid.size()):
		if sudoku_grid[index[0]][col] == attempted_number and col != index[1]:
			return true
	return false

func check_repeating_number_col(attempted_number, index):
	# Will check for any repeating number in a row
	for row in range(sudoku_grid.size()):
		if sudoku_grid[row][index[1]] == attempted_number and row != index[0]:
			return true
	return false

func check_repeating_number_in_box(attempted_number, index):
	# Will check for any repeating number in a box
	var box_row = int(index[0] / 3)
	var box_col = int(index[1] / 3)
	for row in range(box_row * 3, box_row * 3 + 3):
		for col in range(box_col * 3, box_col * 3 + 3):
			if ([row, col]) != (index) and sudoku_grid[row][col] == attempted_number:
				return true
	return false

func check_valid(attempted_number, index):
	if not check_repeating_number_row(attempted_number, index):
		if not check_repeating_number_col(attempted_number, index):
			if not check_repeating_number_in_box(attempted_number, index):
				return true
	return false

func find_empty():
	# Finds an empty slot in the array to start trying numbers
	for row in range(sudoku_grid.size()):
		for col in range(sudoku_grid.size()):
			if sudoku_grid[row][col] == 0:
				return [row, col]
	return false

func solve():
	var row
	var col
	var find = self.find_empty()
	if not find:
		return true
	else:
		row = find[0]
		col = find[1]
	for possible_values in range(9):
		possible_values += 1
		if check_valid(possible_values, [row, col]):
			sudoku_grid[row][col] = possible_values
			if solve():
				return true
			sudoku_grid[row][col] = 0
	return false

func check_if_can_be_solved():
	if not selecting and not solved:
		start_solve()
	elif not solved and selecting:
		change_text("Unselect to solve", Color(255, 255, 255))

func _on_solve_button_pressed():
	check_if_can_be_solved()
	$solve_button.set_focus_mode(0)

func _on_reset_button_pressed():
	reset()
	# Unfocus the button so that it doesn't get triggered by the user pressing enter
	# this is more useful for the reset as a user may press the button to resset
	# but then press enter thinking they wish to solve but since the reset button is selected
	# pressing enter would reset the grid not solve it, so this is needed to prevent this
	$reset_button.set_focus_mode(0)

func change_text(label_text, color_variable):
	# The ability to change what text appears in the middle at the bottom and it's colour
	$Label.set_text(label_text)
	$Label.set("custom_colors/font_color", color_variable)

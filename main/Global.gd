extends Node

var statsfilename = "user://stats.save"
var highscoresfilename = "user://highscores.save"
var species = {
	'Shrew': load("res://characters/Shrew.tscn"),
	'Bird': load("res://characters/Bird.tscn"),
	'Frog': load("res://characters/Frog.tscn"),
	'Turt': load("res://characters/Turt.tscn"),
	'Wasp': load("res://characters/Wasp.tscn"),
	'Mant': load("res://characters/Mant.tscn"),
	'Slug': load("res://characters/Slug.tscn"),
	'Spid': load("res://characters/Spid.tscn"),
}
var stats = {}
var highscores = []
var screens = {
	'stats': "res://screens/stats/Stats.tscn",
	'select': "res://screens/character_select/CharacterSelect.tscn",
	'play': "res://screens/arena/Map.tscn",
}
var player_colors = [
	Color("ff004d"),
	Color("83769c"),
	Color("00e436"),
	Color("ffa300"),
]


func _init():
	stats = load_stats()
	highscores = load_highscores()


func make_stats():
	return {
		'score': 0,
		'ate': 0,
		'fed': 0,
		'wins': 0,
		'losses': 0,
		'time': 0,
		'distance': 0
	}


func add_player_stats(player):
	var stat = stats[player.get_species()]
	for key in stat.keys():
		var val = player.get(key)
		if val != null:
			stat[key] += val
	save_stats()


func save_stats():
	var save_file = File.new()
	save_file.open(statsfilename, File.WRITE)
	save_file.store_string(to_json(stats))
	save_file.close()


func load_stats():
	var file_stats = {}
	var save_file = File.new()
	if save_file.file_exists(statsfilename):
		save_file.open(statsfilename, File.READ)
		var data = parse_json(save_file.get_as_text())
		if data:
			file_stats = data
		save_file.close()
	for name in species.keys():
		if not file_stats.has(name):
			file_stats[name] = make_stats()
	return file_stats


func check_highscore(score):
	for highscore in highscores:
		if score > highscore['score']:
			return true
	return false


func add_highscore(name, aminal, score):
	for i in range(highscores.size()):
		var highscore = highscores[i]
		if score > highscore['score']:
			highscores.insert(i, {
				'name': name,
				'species': aminal,
				'score': score,
			})
	highscores = highscores.slice(0, 9)
	save_highscores()


func save_highscores():
	var save_file = File.new()
	save_file.open(highscoresfilename, File.WRITE)
	save_file.store_string(to_json(highscores))
	save_file.close()


func load_highscores():
	var loaded_scores = []
	var save_file = File.new()
	if save_file.file_exists(highscoresfilename):
		save_file.open(highscoresfilename, File.READ)
		var data = parse_json(save_file.get_as_text())
		if data:
			loaded_scores = data
		save_file.close()
	if loaded_scores.size() < 1:
		# initialize with example values
		var names = species.keys()
		for i in range(10):
			loaded_scores.append({
				'name': 'ABC',
				'species': names[i % names.size()],
				'score': (11-i)*1000
			})
	
	return loaded_scores

func center(points):
	var sum = Vector2()
	for point in points:
		sum += point
	return sum / points.size()

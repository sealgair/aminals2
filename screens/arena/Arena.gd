extends Node2D

var start_data = []
var players = []
export (int) var score_limit = 10
var score = 0

var PlayerPath = preload("res://brain/PlayerPath.gd")
var slime_scene = preload("res://characters/Slime.tscn")
var web_scene = preload("res://characters/Web.tscn")
var map_scene = preload("res://maps/Basic.tscn")

func _ready():
	set_map(map_scene.instance())
	
	randomize()
	$Score.text = String(score_limit)
	var spawn_points = $Map.get_spawn_points()
	for player_data in start_data:
		var sp = spawn_points[randi() % spawn_points.size()]
		spawn_points.erase(sp)
		player_data['spawn_point'] = sp
		add_player(player_data)


func set_map(new_map):
	var old_map = $Map
	var pos = old_map.get_position_in_parent()
	remove_child(old_map)
	old_map.queue_free()
	new_map.set_name("Map")
	add_child(new_map)
	move_child(new_map, pos)


func add_player(player_data):
	var player = Global.species[player_data['species']].instance()
	player.order = player_data['order']
	player.palette = player_data['palette']
	player.init(player_data['spawn_point'] * player.size, PlayerPath.new(player, $Map/Background/TileMap))
	# don't need to use setterif it's before it's added as child
	player.computer = player_data['computer']
	add_child(player)
	player.connect("respawn", self, "spawn")
	player.connect("made_hit", self, "hit")
	player.connect("make_slime", self, "make_slime")
	player.connect("make_web", self, "make_web")
	players.append(player)
	return player


func clean():
	for web in get_tree().get_nodes_in_group("webs"):
		web.queue_free()
	for slime in get_tree().get_nodes_in_group("slime"):
		slime.queue_free()

func hit():
	score = 0
	for player in players:
		score += player.ate
	
	if score >= score_limit:
		$VictoryTimer.start()
	else:
		$Score.text = String(score_limit - score)

func average(values):
	var sum = 0
	for value in values:
		sum += value
	return sum / values.size()


func spawnpoint_distance(spawnpoint):
	var distances = []
	for player in players:
		distances.append((player.position - spawnpoint).length())
	return average(distances)


func spawnpoint_sorter(a, b):
	return spawnpoint_distance(a) > spawnpoint_distance(b)


func spawn(player, spawn_point=null):
	var webs = get_webs()
	if spawn_point == null:
		var furthest = null
		# find spawn point furthest from other players
		for sp in $Map.get_spawn_points():
			sp *= $Map.get_cell_size()
			var webbed = false
			for web in webs:
				if web.intersection_center(Rect2(sp, $Map.get_cell_size())):
					webbed = true
					break
			if not webbed:
				var dist = spawnpoint_distance(sp)
				if furthest == null or furthest < dist:
					furthest = dist
					spawn_point = sp
	player.revive(spawn_point)


func make_slime(position, palette=0):
	if $Map != null:
		var tile_pos = position / $Map.get_cell_size()
		var tile_id = $Map.get_cellv(tile_pos)
		if tile_id != TileMap.INVALID_CELL:
			var instance = slime_scene.instance()
			instance.transform.origin = position
			instance.set_palette(palette)
			add_child(instance)


func get_webs():
	var webs = []
	for child in get_children():
		if child.get_groups().has("webs"):
			webs.append(child)
	return webs


func make_web(start, end, player, decay=null):
	var web = web_scene.instance()
	web.spinner = player
	add_child(web)
	web.set_start(start)
	web.set_end(end)
	web.start_decay(decay)


func make_score(player):
	# kills per second
	var kps = player.ate / player.time
	kps *= 1200
	# kill to death
	var ktd = max(0, player.ate - player.fed)
	ktd *= 200
	# percent of total
	var tot = 0
	for p in players:
		tot += p.ate
	var kpc = player.ate / tot
	kpc *= 1000
	return ceil(kps + ktd + kpc) + player.ate * 100


func end():
	for player in players:
		player.score = make_score(player)
	ScreenManager.load_screen("victory", {'players': players})


func _on_VictoryTimer_timeout():
	end()

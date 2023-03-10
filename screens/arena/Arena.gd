extends Node2D

var start_data = [
	{'order': 1, 'species': "", 'palette': 0, 'computer': true},
	{'order': 2, 'species': "", 'palette': 0, 'computer': true},
	{'order': 3, 'species': "", 'palette': 0, 'computer': true},
	{'order': 4, 'species': "", 'palette': 0, 'computer': true},
]
var players = []
export (int) var score_limit = 30
export (int) var max_computers = 4
export (bool) var countdown = true
var score = 0

var slime_scene = preload("res://characters/Slime.tscn")
var web_scene = preload("res://characters/Web.tscn")
var map_scene = null

const MapChoice = preload("res://screens/map_picker/MapChoice.tscn")

func _ready():
	if countdown:
		get_tree().paused = true
	else:
		$Countdown.visible = false
	if map_scene == null:
		var map_name = Global.rand_choice(MapChoice.instance().map_choices)
		map_scene = load("res://maps/{name}.tscn".format({'name': map_name}))
	set_map(map_scene.instance())
	
	randomize()
	$Map/HUD/Score.text = String(score_limit)
	var spawn_points = $Map.get_spawn_points()
	var species_choices = {
		'Shrew': 3,
		'Slug': 1,
		'Turt': 2,
		'Wasp': 1,
		'Bird': 3,
		'Frog': 2,
		'Mant': 1,
		'Spid': 1,
		'Fungus': 0.5,
	}
	
	var existing_palettes = {}
	for player_data in start_data:
		if not player_data.computer:
			var palettes = existing_palettes.get(player_data.species, [])
			palettes.append(player_data.palette)
			existing_palettes[player_data.species] = palettes
		
	var computers = 0
	for player_data in start_data:
		if player_data.computer and computers < max_computers:
			computers += 1
			var overrides = {
#				1: 'Fungus',
#				2: 'Wasp',
#				3: 'Frog',
#				4: 'Bird',
			}
			if computers in overrides:
				player_data.species = overrides[computers]
			else:
				player_data.species = Global.weighted_rand_choice(species_choices)
			var palette = randi() % 4
			var species_palettes = existing_palettes.get(player_data.species, [])
			while palette in species_palettes:
				palette = wrapi(palette+1, 0, 4)
			player_data.palette = palette
			species_palettes.append(palette)
			existing_palettes[player_data.species] = species_palettes
		
		if player_data.species:
			var sp = spawn_points[randi() % spawn_points.size()]
			spawn_points.erase(sp)
			player_data.spawn_point = sp
			add_player(player_data)
	
	# populate enemies lists after all players are created
	#  (otherwise they'll be missing some)
	for player in players:
		player.make_enemies(players)
		

func _process(delta):
	var count = floor($CountdownTimer.time_left)
	
	if count > 0:
		$Countdown.text = "%d..." % count
	else:
		$Countdown.text = "START!"
	
func set_map(new_map):
	var old_map = $Map
	var pos = old_map.get_position_in_parent()
	remove_child(old_map)
	old_map.queue_free()
	new_map.set_name("Map")
	new_map.pause_mode = Node.PAUSE_MODE_STOP
	add_child(new_map)
	move_child(new_map, pos)

func add_player(player_data):
	var player = Global.species[player_data['species']].instance()
	player.order = player_data['order']
	player.palette = player_data['palette']
	player.computer = player_data['computer']
	player.init(player_data['spawn_point'] * player.size, $Map/Background/TileMap)
	$Map.add_child(player)
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
		$Map/HUD/Score.text = String(score_limit - score)

func spawnpoint_distance(spawnpoint):
	var distances = []
	for player in players:
		distances.append((player.position - spawnpoint).length())
	return Global.average(distances)

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
				if web.intersection_center(sp, 12):
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
		tile_pos.x = round(tile_pos.x-0.1)
		tile_pos.y = ceil(tile_pos.y)
		var tile_id = $Map.get_cellv(tile_pos)
		if tile_id != TileMap.INVALID_CELL:
			var instance = slime_scene.instance()
			instance.transform.origin = tile_pos * $Map.get_cell_size()
			instance.set_palette(palette)
			$Map.add_child(instance)

func get_webs():
	var webs = []
	for child in get_children():
		if child.get_groups().has("webs"):
			webs.append(child)
	return webs

func make_web(start, end, player, decay=null):
	var web = web_scene.instance()
	web.spinner = player
	$Map.add_child(web)
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
	SceneSwitcher.change_scene("victory", {'players': players}, ["circle"], Vector2(0,1))

func _on_VictoryTimer_timeout():
	end()

func _on_CountdownTimer_timeout():
	$Countdown.visible = false
	get_tree().paused = false

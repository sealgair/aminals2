extends Node2D

export (int) var player_order = 1
var palette = 0
var species = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	$Label.text = String(player_order)
	$Background.color = Global.player_colors[player_order-1]
	$AminalSprite.visible = false
	$Sky.visible = false
	$Label.visible = true

func shift_palette(amount):
	palette = wrapi(palette+amount, 0, 4)
	$AminalSprite.material.set_shader_param("palette", palette)

func set_species(new_species):
	var instance = Global.species[new_species].instance()
	set_aminal(instance)

func set_aminal(instance):
	if instance:
		species = instance.get_species()
		$AminalSprite.set_aminal(instance)
		$AminalSprite.visible = true
		$Sky.visible = true
		$Label.visible = false
	else:
		species = ""
		$AminalSprite.visible = false
		$Sky.visible = false
		$Label.visible = true

func make_player():
	return {
		'order': player_order,
		'species': species,
		'palette': palette
	}
	

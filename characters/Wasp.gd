extends "Player.gd"


func init(start_pos, the_tilemap):
	gravity = Vector2()
	run_speed = 80
	attack_offset = Vector2(16,8)
	attack_wait = 1.5
	attack_anim = "peck"
	PlayerPath = load("res://brain/WaspPath.gd")
	.init(start_pos, the_tilemap)

func get_species():
	return "Wasp"

func pronouns():
	return ['she', 'her', 'her', 'hers']

func hit(other):
	if other.poisoned_by == self:
		.hit(other)
	else:
		other.poison(self)

func move(dir):
	.move(dir)
	to_velocity.y = dir.y * run_speed

func can_be_target(enemy, filter_ops={}):
	return .can_be_target(enemy) and enemy.poisoned_by != self

func move_toward_point(point):
	var dir = point - position
	 # wrap around map
	if abs(dir.x) > 16*8:
		dir.x *= -1
	if abs(dir.y) > 16*8:
		dir.y *= -1
	input.press_axis(dir)

func do_process(delta):
	.do_process(delta)
	$AnimatedSprite/Wings.visible = not dead
	$AnimatedSprite/Wings.flip_h = $AnimatedSprite.flip_h

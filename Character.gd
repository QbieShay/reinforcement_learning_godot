extends KinematicBody2D

var move_dir = Vector2()
var SPEED = 70
var timer
var prediction

func _ready():
	timer = get_tree().create_timer( 1 )
	timer.connect("timeout",self, "on_timer_tick" )
	
func _physics_process(delta):
	move_and_collide(move_dir * SPEED * delta)

func _input(event):
	var x = 0
	var y = 0
#	if event.is_action("ui_down") and event.is_pressed():
#		y += 1
#	if event.is_action("ui_up") and event.is_pressed():
#		y -= 1
#	if event.is_action("ui_right") and event.is_pressed():
#		x += 1
#	if event.is_action("ui_left") and event.is_pressed():
#		x -= 1
	x = Input.get_joy_axis( 0,0)
	y = Input.get_joy_axis( 0,1)
	move_dir = Vector2( x, y)
	if event.is_action_pressed("ui_accept"):
		print($TFBrain.get_prediction([1,1,1,1,1,1,1,1,1,1], $Camera2D/NNOUT))
	

func on_timer_tick():
	timer = get_tree().create_timer( 1 )
	timer.connect("timeout",self, "on_timer_tick" )
	$Camera2D/Label.text = "progress:"+ str(get_parent().calculate_progress(transform.origin)) + " intersecting" + str(get_parent().last_intersecting)
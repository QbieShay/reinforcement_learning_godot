extends KinematicBody2D

var move_dir = Vector2()
var SPEED = 100
var ACC_DEC = 10
var ROTATION_SPEED = 30
var SIGHT_RANGE = 100
var timer
var prediction 
var fwd = Vector2(1,0)
var progress
var delta_progress = 0

func _ready():
	timer = get_tree().create_timer( 1 )
	timer.connect("timeout",self, "on_timer_tick" )
	
func _physics_process(delta):
	
	progress = get_parent().calculate_progress(global_transform.origin, SIGHT_RANGE)
	if typeof(progress) == TYPE_REAL:
		return
	var dir_rays_distances = []
	dir_rays_distances.resize(5)
	var start_vec = fwd.rotated(-PI/2)
	
	for i in range(5):
		var res = get_world_2d().direct_space_state.intersect_ray(global_transform.origin, start_vec.rotated(i*PI/4).normalized()*SIGHT_RANGE)
		if res.size() == 0:
			dir_rays_distances[int(i)] = 1
		else:
			dir_rays_distances[int(i)] = (global_transform.origin - res.position).length()/SIGHT_RANGE
	var values = []
	values.resize(5)
	start_vec = (fwd).rotated(-PI/6)
	
	for i in range(5):
		var p = get_parent().calculate_progress(global_position + start_vec.normalized()*SPEED*delta, SIGHT_RANGE)
		start_vec = start_vec.rotated(PI/12)
		if typeof(p) == TYPE_REAL:
			values[i] = 0
		else:
			values[i] = (p["covered_distance"] - progress["covered_distance"])
			#print(str(values[i]))
	#print("covered distance is" +str(progress["covered_distance"]))
	#print("dir_rays_distances are:"+str(dir_rays_distances))
	prediction = $TFBrain.train_char([1,
		dir_rays_distances[0],
		dir_rays_distances[1],
		dir_rays_distances[2],
		dir_rays_distances[3],
		dir_rays_distances[4],
		(fwd).dot(progress["local_normal"]),
		((fwd)).rotated(PI/2).dot(progress["local_normal"].rotated(PI/2)),
		1,
		1],
		values)
	if(prediction == null):
		print("fucc")
		return
	#print ("predicted: "+ prediction+ "\nexpected: "+str(values))
	prediction = prediction.substr(1,prediction.length()-2)
	prediction = prediction.split_floats( " " )
	if is_nan(prediction[0]):
		print("got nan") 
	start_vec  = (fwd).rotated(-PI/6)
	var bigger_val = 0
	var count = 0

	for i in range(prediction.size()):
		count = i
		if prediction[i]>bigger_val:
			bigger_val = prediction[i]
	move_dir = (fwd).rotated(-PI/12 + PI/12 * count).normalized()
	move_and_collide(move_dir * SPEED * delta)
	fwd = move_dir

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
		pass
	

func on_timer_tick():
	timer = get_tree().create_timer( 1 )
	timer.connect("timeout",self, "on_timer_tick" )
	$Camera2D/Label.text = "progress:"+ str(get_parent().calculate_progress(transform.origin)["covered_distance"]) + " intersecting" + str(get_parent().last_intersecting)
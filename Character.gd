extends KinematicBody2D

var move_dir = Vector2()
var SPEED = 70
var ACC_DEC = 10
var ROTATION_SPEED = 30
var SIGHT_RANGE = 100
var timer
var prediction 
var fwd = Vector2(1,0)
var progress
var delta_progress = 0
var value_points =[]
var zeros = 0

func _ready():
	timer = get_tree().create_timer( 1 )
	timer.connect("timeout",self, "on_timer_tick" )
	fwd = -global_transform.y
	
func _physics_process(delta):
	progress = get_parent().calculate_progress(global_transform.origin)
	if ( typeof(progress) != TYPE_REAL and progress["covered_distance"] <0.01):
		zeros+= 1
		$Camera2D/Label.text = "progress:"+ str(progress["covered_distance"])\
			+ " intersecting" + str(get_parent().last_intersecting) + "progress zeros" + str(zeros)
	var vals = calculate_values(progress["covered_distance"])
	var dir_rays_distances = calculate_collision_rays()
#	print(str(dir_rays_distances))
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
		vals)
	$Camera2D/Label.text = "predicted: "+ prediction+ "\nexpected: "+str(vals)
	var chosen_idx = calculate_best_dir(prediction)
	var c = $MoveRays.get_child(chosen_idx)
	var move_dir = c.global_transform.basis_xform( c.cast_to ).normalized()
	fwd = move_dir.normalized()
	#$PerceptionRays.rotate( move_dir.angle()*delta )
	#$MoveRays.rotate( move_dir.angle()*delta )
	move_and_collide((move_dir).normalized()*SPEED*delta)

func calculate_collision_rays():
	var d = []
	d.resize(5)
	for i in range(5):
		var c = $PerceptionRays.get_child(i)
		if c.is_colliding():
			d[i] = global_position.distance_to(c.get_collision_point())/c.cast_to.y
		else:
			d[i] = 1
	return d

func calculate_best_dir(prediction):
	if(prediction == null):
		print("fucc")
		return
	var orig_pred = prediction
	prediction = prediction.substr(1,prediction.length()-2)
	prediction = prediction.split_floats( " ", false )
	if is_nan(prediction[0]):
		print("got nan") 
	var bigger_val = 0
	var count = 0

	for i in range(prediction.size()):
		if prediction[i]>bigger_val:
			count = i
			bigger_val = prediction[i]
	return count

func calculate_values(cur_progress):
	var values = []
	values.resize(5)
	value_points.resize(5)
	for i in range(5):
		var c = $MoveRays.get_child(i)
		if c.is_colliding():
			values[i] = (get_parent().calculate_progress(c.get_collision_point())["covered_distance"])-cur_progress
			values[i]/=SPEED
			value_points[i] = c.get_collision_point()
		else:
			values[i] = get_parent().calculate_progress(c.global_transform.basis_xform( c.cast_to ) + global_position)["covered_distance"]-cur_progress
			values[i]/=SPEED
			value_points[i] = c.global_transform.basis_xform( c.cast_to ) + global_position
	return values


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
	#timer = get_tree().create_timer( 1 )
	#timer.connect("timeout",self, "on_timer_tick" )
	pass

func _physics_process_nah(delta):
	
	
	progress = get_parent().calculate_progress(global_transform.origin, SIGHT_RANGE)
	if typeof(progress) == TYPE_REAL:
		return
	var dir_rays_distances = []
	dir_rays_distances.resize(5)
	var start_vec = fwd.rotated(-PI/2)
	
	for i in range(5):
		var res = get_world_2d().direct_space_state.intersect_ray(global_transform.origin, start_vec.rotated(i*PI/4).normalized()*SIGHT_RANGE)
		if res.size() == 0:
			dir_rays_distances[int(i)] = SIGHT_RANGE#1
		else:
			dir_rays_distances[int(i)] = (global_transform.origin - res.position).length()#/SIGHT_RANGE
	#print(str(dir_rays_distances))
	var values = []
	value_points.resize(5)
	values.resize(5)
	start_vec = (fwd).rotated(-PI/6)
	
	
	for i in range(5):
		var ray = get_world_2d().direct_space_state.intersect_ray(global_position, start_vec.rotated(PI/12*i).normalized()*SPEED*delta)
		var p
		if ray.size()==0:
			p = get_parent().calculate_progress(global_position + start_vec.normalized()*SPEED*delta, SIGHT_RANGE)
			value_points[i] = global_position + start_vec.normalized()*SPEED*delta
		else:
			p = get_parent().calculate_progress(ray.position, SIGHT_RANGE)
			value_points[i] = ray.position
		if typeof(p) == TYPE_REAL:
			values[i] = -1
		else:
			values[i] = (p["covered_distance"] - progress["covered_distance"])/(SPEED)
		
		#print((fwd).dot(progress["local_normal"]))
	#print("covered distance is" +str(progress["covered_distance"]))
	#print("dir_rays_distances are:"+str(dir_rays_distances))
	prediction = $TFBrain.train_char([1,
		1,#dir_rays_distances[0],
		1,#dir_rays_distances[1],
		1,#dir_rays_distances[2],
		1,#dir_rays_distances[3],
		1,#dir_rays_distances[4],
		(fwd).dot(progress["local_normal"]),
		((fwd)).rotated(PI/2).dot(progress["local_normal"].rotated(PI/2)),
		1,
		1],
		values)
	if(prediction == null):
		print("fucc")
		return
	$Camera2D/Label.text = "predicted: "+ prediction+ "\nexpected: "+str(values)
	$Camera2D/Label.text = "  points "+str(value_points)
	prediction = prediction.substr(1,prediction.length()-2)
	prediction = prediction.split_floats( " " )
	if is_nan(prediction[0]):
		print("got nan") 
	start_vec  = (fwd).rotated(-PI/6)
	var bigger_val = 0
	var count = 0

	for i in range(prediction.size()):
		if prediction[i]>bigger_val:
			count = i
			bigger_val = prediction[i]
	move_dir = (fwd).rotated(-PI/12 + PI/12 * count).normalized()
	move_and_collide(move_dir * SPEED * delta)
	fwd = move_dir
	
	#$Camera2D/Label.text = "progress:"+ str(get_parent().calculate_progress(transform.origin)["covered_distance"]) + " intersecting" + str(get_parent().last_intersecting)

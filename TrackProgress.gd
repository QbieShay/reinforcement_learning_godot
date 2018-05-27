extends Node2D

var point_type = preload("res://DistancePoint.tscn")
var track_points = []
var shape_cast
var query

func _ready():
	var tmp_point
	shape_cast = CircleShape2D.new()
	shape_cast.radius = 300
	var c = 0
	for p in $MidLine.curve.get_baked_points():
		tmp_point = point_type.instance()
		tmp_point.position = $MidLine.transform.xform(p)
		tmp_point.index = c
		c+=1
		track_points.append(tmp_point)
		$DistancePoints.add_child(tmp_point)
	track_points[0].distance_covered = 0
	for i in range(1,track_points.size()):
		track_points[i].distance_covered = (
			track_points[i-1].distance_covered + 
			track_points[i-1].position.distance_to(track_points[i].position) )
	#missing unity, rip
	query = Physics2DShapeQueryParameters.new()
	query.set_shape(shape_cast)
	query.transform = Transform2D()
	query.exclude = [ $"StaticBody2D" , $"StaticBody2D2" , $"Character" ]
	

func calculate_normal_proj(p1,p2,from):
	var a = p1.y - p2.y
	var b = p1.x - p2.x
	var c = p2.x*p1.y - p2.y*p1.x
	#calculate both lines equations
	var m2 = b/a
	var q2 =  from.y - m2* from.x # y = mx+q -> q = y-mx
	var m1 = -a/b
	var q1 = -c/b
	#calculate where the two lines intersect
	var p = Vector2( (q2-q1)/(m1-m2) , (m1*q2 - m2*q1)/(m1-m2) )
	#calculate if the point of intersection is inside of the segment
	var v = p2 - p1
	if (v.dot(p-p1)< 0 and (p-p1).length() > 3) or (v.dot(p-p1) > 0 and (p2-p1).length() - (p - p1).length() > -3):
	#if(v.dot(p-p1) > 0 && (p2-p1).length() - (p - p1).length()  ):
		return p 
	else: 
		return null

var last_intersecting = 0

func sort_points(a,b):
	if(a.collider.distance_covered < b.collider.distance_covered):
		return true
	else:
		return false


func calculate_progress(from):
	if(!query):
		return 0.0
	query.transform.origin = from
	var overlapping_points = get_world_2d().direct_space_state.intersect_shape( query )
	if overlapping_points.size() < 2:
		return 0.0
	var distance = INF
	var cur_covered = 0
	
	last_intersecting = overlapping_points.size()
	overlapping_points.sort_custom( self, "sort_points")
	for i in range( overlapping_points.size() -1 ):
		var p = overlapping_points[i]
		var p_proj = calculate_normal_proj(overlapping_points[i].collider.global_transform.origin, overlapping_points[i+1].collider.global_transform.origin, from)
		if p_proj != null:
			if from.distance_to(p_proj) < distance:
				distance = from.distance_to(p_proj)
				var actual_cur_p = p.collider.global_transform.origin
				var next_p = overlapping_points[i+1].collider.global_transform.origin
				cur_covered = ((p_proj - actual_cur_p).length()/(next_p - actual_cur_p).length())\
					*(overlapping_points[i+1].collider.distance_covered - overlapping_points[i].collider.distance_covered)
				print("progress for point "+str(i)+ "is "+str(cur_covered))
				cur_covered+= overlapping_points[i].collider.distance_covered
	#TODO LEEEEEEEEEERP
	return cur_covered

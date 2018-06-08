extends Node2D

var point_type = preload("res://DistancePoint.tscn")
var track_points = []
var shape_cast
var query

func _ready():
	var tmp_point
	shape_cast = CircleShape2D.new()
	shape_cast.radius = 200
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
	var tri_radius = (from - p1).length()
	var height = tri_radius*sin( (from -p1).angle_to( p2-p1))
	var right_vec = (p2-p1).rotated(PI/2).normalized()
	var int_point = from + right_vec*height
	if( (int_point -p1).length() < (p2-p1).length() and (p2-p1).dot(int_point-p1)>0):
		return int_point
	else:
		if ((p2-p1).dot(int_point-p1) <= 0 and (int_point - p1).length()<4) or\
			((p2-p1).dot(int_point-p1) >= 1 and (int_point -p1).length() - (p2-p1).length() < 4):
			return int_point
		else:
			return null
	
var last_intersecting = 0

func sort_points(a,b):
	if(a.collider.distance_covered < b.collider.distance_covered):
		return true
	else:
		return false


func calculate_progress(from, sight_range = 124):
	#shape_cast.radius = sight_range
	if(!query):
		return {
			"covered_distance": 0,
			"local_normal": Vector2()
			}
	query.transform.origin = from
	var overlapping_points = get_world_2d().direct_space_state.intersect_shape( query )
	if overlapping_points.size() < 2:
		return {
			"covered_distance": 0,
			"local_normal": Vector2()
			}
	var distance = INF
	var cur_covered = 0
	var track_nor = Vector2()
	
	last_intersecting = overlapping_points.size()
	overlapping_points.sort_custom( self, "sort_points")
	for i in range( overlapping_points.size() -1 ):
		var p = overlapping_points[i]
		var p_proj = calculate_normal_proj(overlapping_points[i].collider.global_transform.origin, overlapping_points[i+1].collider.global_transform.origin, from)
		#if p.collider.distance_covered>cur_covered:
			#cur_covered = p.collider.distance_covered
#			track_nor = (overlapping_points[i+1].collider.global_transform.origin-overlapping_points[i].collider.global_transform.origin).normalized()
		if p_proj != null:
			if from.distance_to(p_proj) < distance:
				distance = from.distance_to(p_proj)
				var actual_cur_p = p.collider.global_transform.origin
				var next_p = overlapping_points[i+1].collider.global_transform.origin
				cur_covered = ((p_proj - actual_cur_p).length()/(next_p - actual_cur_p).length())\
					*(overlapping_points[i+1].collider.distance_covered - overlapping_points[i].collider.distance_covered)

				cur_covered+= overlapping_points[i].collider.distance_covered
				track_nor = (overlapping_points[i+1].collider.global_transform.origin-overlapping_points[i].collider.global_transform.origin).normalized()
	return {
		"covered_distance": cur_covered,
		"local_normal": track_nor
		}

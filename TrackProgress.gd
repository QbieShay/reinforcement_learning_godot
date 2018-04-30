extends Node2D

var point_type = preload("res://DistancePoint.tscn")
var track_points = []
var shape_cast
var query

func _ready():
	var tmp_point
	shape_cast = CircleShape2D.new()
	shape_cast.radius = 124
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
	

func calculate_progress(from):
	if(!query):
		return 0.0
	query.transform.origin = from
	var overlapping_points = get_world_2d().direct_space_state.intersect_shape( query )
	if overlapping_points.size() < 1:
		return 0.0
	var closer = overlapping_points[0].collider.global_transform.origin
	var distance = INF
	var closer_idx = 0
	for i in range( overlapping_points.size() ):
		var p = overlapping_points[i]
		if from.distance_to(p.collider.global_transform.origin) < distance:
			closer_idx = i
			closer = p.collider.global_transform.origin
			distance = from.distance_to(p.collider.global_transform.origin)	
	return overlapping_points[closer_idx].collider.distance_covered

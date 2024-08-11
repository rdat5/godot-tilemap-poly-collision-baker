@tool
extends TileMapLayer

@export var bake_shapes : bool = false : set = run_code

func run_code(_fake_bool = null) -> void:
	var baked_static_body : StaticBody2D = find_child("CollisionShapes")
	
	if not baked_static_body:
		baked_static_body = StaticBody2D.new()
		add_child(baked_static_body)
		baked_static_body.name = "CollisionShapes"
		baked_static_body.owner = get_tree().edited_scene_root
	
	var polygons : Array = []
	var used_cells : Array = get_used_cells()
	
	for cell_coords in used_cells:
		var cell_data : TileData = get_cell_tile_data(cell_coords)
		polygons.append(get_poly_coords(cell_coords, cell_data, tile_set.tile_size))
	
	var merged_polygons : Array = merge_polygons(polygons)
	
	for child in baked_static_body.get_children():
		child.free()
	
	for i in range(merged_polygons.size()):
		var shape : CollisionPolygon2D = CollisionPolygon2D.new()
		shape.polygon = merged_polygons[i]
		baked_static_body.add_child(shape)
		shape.name = "shape" + str(i)
		shape.owner = get_tree().edited_scene_root

func get_poly_coords(cell_coords, cell_data, tile_size) -> PackedVector2Array:
	var adjusted_coords : PackedVector2Array = []
	
	for vert in cell_data.get_collision_polygon_points(0, 0):
		var adjusted_x : float = (cell_coords.x * tile_size.x) + (vert.x + (tile_size.x / 2))
		var adjusted_y : float = (cell_coords.y * tile_size.y) + (vert.y + (tile_size.y / 2))
		adjusted_coords.append(Vector2(adjusted_x, adjusted_y))
	return adjusted_coords


func is_mergable(poly_a : PackedVector2Array, poly_b : PackedVector2Array) -> bool:
	var size : int = Geometry2D.merge_polygons(poly_a, poly_b).size()
	return size == 1


func merge_polygons(polygons : Array) -> Array:
	var polys : Array = polygons.duplicate()
	
	var finished_polygons : Array = []
	
	while polys.size() > 1:
		var current_poly : PackedVector2Array = polys.pop_front()
		var merged : bool = false
		
		for i in range(polys.size()):
			var other_poly : PackedVector2Array = polys[i]
			if is_mergable(current_poly, other_poly):
				var merged_poly : PackedVector2Array = Geometry2D.merge_polygons(current_poly, other_poly)[0]
				polys.pop_at(i)
				polys.push_front(merged_poly)
				merged = true
				break
		
		if not merged:
			finished_polygons.push_back(current_poly)
	
	finished_polygons.push_back(polys[0])
	
	return finished_polygons

extends Node

class_name AIAtlasLoader

static func get_atlas(filename: String, row: int, col: int, rows: int = 2, cols: int = 6) -> AtlasTexture:
	var path = "res://extracted_assets/AI/" + filename
	if not ResourceLoader.exists(path):
		return null
	var tex = load(path) as Texture2D
	if not tex:
		return null
		
	var w = tex.get_width()
	var h = tex.get_height()
	var cell_w = float(w) / float(cols)
	var cell_h = float(h) / float(rows)
	
	var atlas = AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(float(col) * cell_w, float(row) * cell_h, cell_w, cell_h)
	return atlas

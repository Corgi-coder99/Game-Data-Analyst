extends SceneTree
const Palette = preload("res://scripts/v2/palette.gd")
const GROUPS := [preload("res://tools/sprites/characters.gd"),preload("res://tools/sprites/furniture.gd"),preload("res://tools/sprites/icons.gd"),preload("res://tools/sprites/thumbs.gd")]
static func definitions() -> Dictionary:
	var all := {}
	for group in GROUPS:
		all.merge(group.definitions())
	return all
static func generate() -> bool:
	DirAccess.make_dir_recursive_absolute("res://assets/v2")
	var all := definitions()
	for id in all:
		var item: Dictionary = all[id]
		var size: Vector2i = item.size
		var img := Image.create(size.x * item.frames.size(),size.y,false,Image.FORMAT_RGBA8)
		img.fill(Color(0,0,0,0))
		for f in range(item.frames.size()):
			var rows: Array = item.frames[f]
			if rows.size() != size.y:
				printerr(id, ": wrong row count")
				return false
			for y in range(size.y):
				if rows[y].length() != size.x:
					printerr(id, ": wrong width at frame ",f," row ",y,": ",rows[y])
					return false
				for x in range(size.x):
					img.set_pixel(f*size.x+x,y,Palette.decode(rows[y].substr(x,1)))
		var path: String = "res://assets/v2/" + id + ".png"
		var bytes := img.save_png_to_buffer()
		if not FileAccess.file_exists(path) or FileAccess.get_file_as_bytes(path) != bytes:
			var file := FileAccess.open(path,FileAccess.WRITE)
			if file == null:
				return false
			file.store_buffer(bytes)
	print("Generated ",all.size()," sprite strips")
	return true
func _init() -> void:
	quit(0 if generate() else 1)


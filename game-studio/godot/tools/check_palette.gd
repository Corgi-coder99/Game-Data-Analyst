extends SceneTree
const Palette = preload("res://scripts/v2/palette.gd")
static func allowed_set() -> Dictionary:
	var allowed := {}
	for hex in Palette.colors():
		allowed[Color(hex).to_rgba32()] = true
	return allowed
static func validate_image(img: Image, path: String, report: bool = true) -> bool:
	var allowed := allowed_set()
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var pixel := img.get_pixel(x,y)
			if (pixel.a8 != 0 and pixel.a8 != 255) or (pixel.a8 == 255 and not allowed.has(pixel.to_rgba32())):
				if report:
					printerr("FAIL ",path," pixel (",x,",",y,") ",pixel)
				return false
	return true
static func validate() -> bool:
	var shared := ProjectSettings.globalize_path("res://../../shared/style-bible/palette-v3.json")
	if FileAccess.get_file_as_bytes(shared) != FileAccess.get_file_as_bytes("res://data/palette_v3.json"):
		printerr("FAIL palette v3 copy differs")
		return false
	var shared_v2 := ProjectSettings.globalize_path("res://../../shared/style-bible/palette-v2.json")
	if FileAccess.get_file_as_bytes(shared_v2) != FileAccess.get_file_as_bytes("res://data/palette_v2.json"):
		printerr("FAIL palette v2 copy differs")
		return false
	if Palette.colors().size() != 64:
		printerr("FAIL palette v3 must have 64 colors")
		return false
	var v2: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/palette_v2.json")).colors
	for i in range(v2.size()):
		if Palette.colors()[i] != v2[i]:
			printerr("FAIL palette v3 is not a superset of v2 at index ",i)
			return false
	var seen := {}
	for hex in Palette.colors():
		if seen.has(hex):
			printerr("FAIL duplicate palette color ",hex)
			return false
		seen[hex] = true
	var allowed := allowed_set()
	var count := 0
	for file in DirAccess.get_files_at("res://assets/v2"):
		if file.ends_with(".png"):
			count += 1
			var img := Image.load_from_file("res://assets/v2/" + file)
			if img == null or not validate_image(img,file):
				return false
	print("Palette PASS: ",count," PNG; ",allowed.size()," allowed colors (v3); binary alpha")
	return count > 0
func _init() -> void:
	quit(0 if validate() else 1)

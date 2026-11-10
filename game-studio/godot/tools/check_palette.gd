extends SceneTree
const Palette = preload("res://scripts/v2/palette.gd")
static func validate_image(img: Image, path: String, report: bool = true) -> bool:
	var allowed: Array = []
	for hex in Palette.colors():
		allowed.append(Color(hex).to_rgba32())
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var pixel := img.get_pixel(x,y)
			if (pixel.a8 != 0 and pixel.a8 != 255) or (pixel.a8 == 255 and not pixel.to_rgba32() in allowed):
				if report:
					printerr("FAIL ",path," pixel (",x,",",y,") ",pixel)
				return false
	return true
static func validate() -> bool:
	var shared := ProjectSettings.globalize_path("res://../../shared/style-bible/palette-v2.json")
	if FileAccess.get_file_as_bytes(shared) != FileAccess.get_file_as_bytes("res://data/palette_v2.json"):
		printerr("FAIL palette copy differs")
		return false
	if Palette.colors().size() != 32:
		return false
	var count := 0
	for file in DirAccess.get_files_at("res://assets/v2"):
		if file.ends_with(".png"):
			count += 1
			var img := Image.load_from_file("res://assets/v2/" + file)
			if img == null or not validate_image(img,file):
				return false
	print("Palette PASS: ",count," PNG; 32 allowed colors; binary alpha")
	return count > 0
func _init() -> void:
	quit(0 if validate() else 1)


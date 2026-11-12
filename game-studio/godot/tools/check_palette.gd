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
# Compare as text so Windows CRLF checkouts do not cause false failures.
static func _text(path: String) -> String:
	return FileAccess.get_file_as_string(path).replace("
", "
")

static func validate() -> bool:
	var shared := ProjectSettings.globalize_path("res://../../shared/style-bible/palette-v4.json")
	if _text(shared) != _text("res://data/palette_v4.json"):
		printerr("FAIL palette v4 copy differs")
		return false
	for version in ["v2", "v3"]:
		var shared_old := ProjectSettings.globalize_path("res://../../shared/style-bible/palette-%s.json" % version)
		if _text(shared_old) != _text("res://data/palette_%s.json" % version):
			printerr("FAIL palette ", version, " copy differs")
			return false
	if Palette.colors().size() != 112:
		printerr("FAIL palette v4 must have 112 colors")
		return false
	var v3: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/palette_v3.json")).colors
	for i in range(v3.size()):
		if Palette.colors()[i] != v3[i]:
			printerr("FAIL palette v4 is not a superset of v3 at index ",i)
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
	# T-039 rule: assets/v2/fonts holds palette-free font atlases (the text color comes from the theme),
	# so the palette check skips that folder and only requires pure white on transparent, binary alpha.
	var fonts := 0
	for file in DirAccess.get_files_at("res://assets/v2/fonts"):
		if not file.ends_with(".png"): continue
		fonts += 1
		var atlas := Image.load_from_file("res://assets/v2/fonts/" + file)
		if atlas == null: return false
		for y in range(atlas.get_height()):
			for x in range(atlas.get_width()):
				var p := atlas.get_pixel(x, y)
				if p.a8 != 0 and not (p.a8 == 255 and p.r8 == 255 and p.g8 == 255 and p.b8 == 255):
					printerr("FAIL font atlas ", file, " pixel (", x, ",", y, ") ", p)
					return false
	print("Font atlases PASS: ", fonts, " PNG; white on transparent, binary alpha")
	print("Palette PASS: ",count," PNG; ",allowed.size()," allowed colors (v4); binary alpha")
	return count > 0
func _init() -> void:
	quit(0 if validate() else 1)

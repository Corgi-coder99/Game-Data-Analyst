extends RefCounted
const Palette = preload("res://scripts/v2/palette.gd")
# Original hand-authored 16x24 silhouettes, lit at the upper left.
const BODY := [
"................",
".....000000.....",
"....0HHHHHH0....",
"....0HHhHHH0....",
"....0vvvvvu0....",
"....0v0vv0u0....",
".....vvvvuu0....",
".....0vvuu0.....",
"......0uu0......",
"....00SSSS00....",
"...0SSsSSSsS0...",
"...0SSsSSSsS0...",
"...0vSSSSSSu0...",
"...0vSSSSSSu0...",
"....0SSSSSS0....",
"....0SSSSSS0....",
".....022220.....",
".....022220.....",
".....022220.....",
".....02..20.....",
".....02..20.....",
"....000..000....",
"....000..000....",
"................"]
const PEOPLE := {
"player": ["9", "a", "i", "j"],
"khoi": ["0", "3", "6", "7"],
"mai": ["8", "a", "s", "t"],
"tu": ["5", "6", "e", "f"],
"hanh": ["0", "3", "h", "i"]}
# T-022: department staff. Colors are palette v3 indices (hair, hair shade, shirt, shirt shade, skin, skin shade, pants).
const ROSTER := {
"rin": [1, 3, 23, 46, 32, 31, 3],
"bao": [9, 10, 7, 6, 50, 49, 2],
"linh": [54, 38, 55, 43, 32, 31, 4],
"dat": [1, 3, 56, 17, 49, 9, 3],
"an": [27, 11, 51, 25, 50, 49, 2],
"vy": [9, 10, 53, 58, 32, 31, 3],
"sam": [1, 2, 52, 27, 49, 9, 4],
"ngoc": [1, 3, 54, 38, 32, 31, 2],
"ops": [10, 9, 5, 4, 50, 49, 17],
"lead": [2, 1, 18, 17, 32, 31, 3],
"intern": [27, 11, 47, 46, 50, 49, 3],
"kai": [1, 3, 53, 58, 50, 49, 2],
"mei": [9, 10, 54, 38, 32, 31, 3],
"pat": [10, 9, 55, 43, 49, 9, 17]}
static func letter(color_index: int) -> String:
	return Palette.ALPHABET.substr(color_index - 1, 1)
static func roster_definitions() -> Dictionary:
	var result := {}
	for person in ROSTER:
		var c: Array = ROSTER[person]
		var map := {"H": letter(c[0]), "h": letter(c[1]), "S": letter(c[2]), "s": letter(c[3]), "v": letter(c[4]), "u": letter(c[5]), "2": letter(c[6])}
		var frames: Array = []
		for frame in range(8):
			var rows: Array = []
			for line in BODY:
				rows.append(line)
			if frame == 1:
				rows[5] = "....0vuuuuu0...."
			if frame >= 2 and frame <= 5:
				var feet := ["....000..000....", "...000....000...", ".....00..00.....", ".....000000....."]
				rows[21] = feet[frame - 2]
				rows[22] = feet[frame - 2]
			if frame >= 6:
				rows[13] = "...0vSSjjjvu0..." if frame == 6 else "...0vSSjjvuu0..."
			var painted: Array = []
			for row in rows:
				var out := ""
				for i in range(row.length()):
					var ch: String = row.substr(i, 1)
					out += map.get(ch, ch)
				painted.append(out)
			frames.append(painted)
		result[person] = {"size": Vector2i(16, 24), "frames": frames}
	return result
static func definitions() -> Dictionary:
	var result := {}
	for person in PEOPLE:
		var frames: Array = []
		var colors: Array = PEOPLE[person]
		var count := 6 if person == "hanh" else 8
		for frame in range(count):
			var rows: Array = []
			for line in BODY:
				rows.append(line.replace("H", colors[0]).replace("h", colors[1]).replace("S", colors[2]).replace("s", colors[3]))
			if frame == 1:
				rows[5] = "....0vuuuuu0...."
			if person == "player":
				rows[10] = "...0iisrii ji0...".replace(" ", "")
			if person == "khoi":
				rows[5] = "....044vv440...." if frame == 1 else "....040vv040...." # Glasses and closed lids.
			if person == "mai":
				rows[3] = "....0tt" + rows[3].substr(7) # Hair clip.
			if person == "tu":
				rows[2] = "....05555550...." # Grey cap.
			if person == "hanh":
				rows[10] = "...0hhsvhhs h0...".replace(" ", "")
			if frame >= 2 and frame <= 5:
				var feet := ["....000..000....", "...000....000...", ".....00..00.....", ".....000000....."]
				rows[21] = feet[frame - 2]
				rows[22] = feet[frame - 2]
			if frame >= 6:
				rows[13] = "...0vSSjjjvu0...".replace("S", colors[2]) if frame == 6 else "...0vSSjjvuu0...".replace("S", colors[2])
			frames.append(rows)
		result[person] = {"size": Vector2i(16, 24), "frames": frames}
	result.merge(roster_definitions())
	return result



extends RefCounted
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
	return result



extends RefCounted
# T-028 cozy characters: 16x24, big round heads, blush, colored outline, small floor shadow.
# Same ids, sizes and frame counts as T-022 (8 frames: 0 idle, 1 blink, 2-5 walk, 6-7 type; hanh has 6).
const Kit = preload("res://tools/sprites/kit.gd")
# Template rows. Placeholders: O outline, H hair, h hair shade, L hair light, v skin, u skin shade, b blush,
# e eye, m mouth, S shirt, s shirt shade, l shirt light, P pants, p pants shade, F shoe, x shadow.
const BASE := [
"................",
"....OOOOOOOO....",
"...OLLHHHHHHO...",
"..OLLHHHHHHHHO..",
"..OLHHHHHHHHHO..",
"..OHHHvHHHvHhO..",
"..OHHvvvHvvvhO..",
"..OHvvvvvvvvhO..",
"..OvvevvvvevvO..",
"..OvvevvvvevvO..",
"..ObbvvmmvvbbO..",
"...OvvvvvvvvO...",
"....OOuvvuOO....",
"...OSSSvvSSSO...",
"..OSlSSSSSSSsO..",
"..OSlSSSSSSSsO..",
"..OvSSSSSSSSvO..",
"..OuSSSSSSSSuO..",
"...OPPPPPPPPO...",
"...OPPPPPPPPO...",
"...OPPPOOPPPO...",
"...OPPpOOpPPO...",
"...OFFFOOFFFO...",
"....xxxxxxxx...."]
# Style patches: row index -> replacement row.
const STYLES := {
	"short": {},
	"bob": {7: "..OHvvvvvvvvHO..", 8: "..OHvevvvvevHO..", 9: "..OHvevvvvevHO..", 10: "..OHbvvmmvvbHO.."},
	"long": {7: "..OHvvvvvvvvHO..", 8: "..OHvevvvvevHO..", 9: "..OHvevvvvevHO..", 10: "..OHbvvmmvvbHO..", 11: "...OHvvvvvvHO...", 12: "....OHuvvuHO....", 13: "...OHSSvvSSHO..."},
	"bun": {0: ".....OHHHO......", 1: "....OOHHHOOO...."},
	"glasses": {8: "..OvGeGvvGeGvO..", 9: "..OvGGGvvGGGvO.."},
	"cap": {1: "....OOOOOOOO....", 2: "...OCCCCCCCCO...", 3: "..OCCCCCCCCCCO..", 4: "..OCCCCCCCCCCCO.", 5: "..OHHHvvvvvHhO.."},
	"clip": {3: "..OLLHHHHHHHkO.."},
	"mentor": {7: "..OHvvvvvvvvHO..", 8: "..OHGeGvvGeGHO..", 9: "..OHGGGvvGGGHO..", 10: "..OHbvvmmvvbHO..", 11: "...OHvvvvvvHO...", 13: "...OSSSvvSSSO...", 14: "..OSlSSSSSSSsO..", 15: "..OSlSSSSSSSsO..", 16: "..OvSSSSSSSSvO.."},
	"tie": {13: "...OSSSvtSSSO...", 14: "..OSlSSStSSSsO..", 15: "..OSlSSStSSSsO.."}}
# Name -> look. Colors are palette v4 indices.
const LOOKS := {
	"player": {"hair": [108, 66, 109], "skin": [106, 104, 85], "shirt": [84, 79, 94], "pants": [83, 111], "style": "short"},
	"khoi": {"hair": [65, 66, 99], "skin": [32, 50, 105], "shirt": [91, 78, 90], "pants": [111, 83], "style": "glasses"},
	"mai": {"hair": [87, 88, 85], "skin": [106, 104, 85], "shirt": [93, 81, 82], "pants": [84, 79], "style": "clip"},
	"tu": {"hair": [108, 66, 109], "skin": [50, 107, 105], "shirt": [97, 98, 89], "pants": [108, 66], "style": "cap", "cap": 100},
	"hanh": {"hair": [100, 99, 101], "skin": [106, 104, 85], "shirt": [88, 66, 87], "pants": [66, 65], "style": "bun"},
	"rin": {"hair": [108, 66, 109], "skin": [32, 50, 105], "shirt": [91, 78, 90], "pants": [84, 79], "style": "bob"},
	"bao": {"hair": [65, 66, 99], "skin": [50, 107, 105], "shirt": [102, 101, 72], "pants": [111, 83], "style": "tie"},
	"linh": {"hair": [87, 88, 85], "skin": [106, 104, 85], "shirt": [85, 87, 86], "pants": [84, 79], "style": "long"},
	"dat": {"hair": [65, 66, 99], "skin": [31, 107, 105], "shirt": [20, 19, 21], "pants": [108, 66], "style": "short"},
	"an": {"hair": [110, 97, 89], "skin": [32, 50, 105], "shirt": [75, 74, 76], "pants": [84, 79], "style": "bob"},
	"vy": {"hair": [108, 66, 109], "skin": [106, 104, 85], "shirt": [70, 98, 71], "pants": [111, 83], "style": "bun"},
	"sam": {"hair": [65, 66, 99], "skin": [31, 107, 105], "shirt": [112, 25, 26], "pants": [108, 66], "style": "short"},
	"ngoc": {"hair": [65, 66, 99], "skin": [32, 50, 105], "shirt": [85, 87, 86], "pants": [66, 65], "style": "long"},
	"ops": {"hair": [108, 66, 109], "skin": [50, 107, 105], "shirt": [6, 5, 7], "pants": [111, 83], "style": "glasses"},
	"lead": {"hair": [99, 66, 100], "skin": [106, 104, 85], "shirt": [80, 79, 81], "pants": [83, 111], "style": "tie"},
	"drlinh": {"hair": [66, 65, 100], "skin": [106, 104, 85], "shirt": [64, 61, 41], "pants": [84, 79], "style": "mentor"},
	"intern": {"hair": [110, 97, 89], "skin": [32, 50, 105], "shirt": [89, 97, 110], "pants": [84, 79], "style": "short"},
	"kai": {"hair": [65, 66, 99], "skin": [31, 107, 105], "shirt": [87, 88, 85], "pants": [83, 111], "style": "short"},
	"mei": {"hair": [108, 66, 109], "skin": [106, 104, 85], "shirt": [93, 81, 82], "pants": [108, 66], "style": "long"},
	"pat": {"hair": [99, 66, 100], "skin": [50, 107, 105], "shirt": [90, 91, 78], "pants": [84, 79], "style": "bob"}}
const WALK_LEGS := [
	["..OPPPPOOPPPPO..", "..OPPPO..OPPPO..", "..OFFFO..OFFFO..", "...OOO....OOO..."],
	["...OPPPOOPPPO...", "....OPPOOPPO....", "....OFFOOFFO....", ".....OOOOOO....."],
	["...OPPPPPPPPO...", "....OPPPPPPO....", ".....OFFFFO.....", "......OOOO......"],
	["..OPPPPOOPPPPO..", "...OPPO..OPPO...", "...OFFO..OFFO...", "....OO....OO...."]]
static func build_rows(look: Dictionary, frame: int) -> Array:
	var rows: Array = BASE.duplicate()
	var style: String = look.style
	for row in STYLES[style]:
		rows[row] = STYLES[style][row]
	if frame == 1:
		rows[8] = rows[8].replace("e", "v")
	if frame >= 2 and frame <= 5:
		var legs: Array = WALK_LEGS[frame - 2]
		for i in range(4):
			rows[19 + i] = legs[i]
	if frame >= 6:
		# Typing: hands move in toward the keyboard.
		rows[16] = "..OSSSvvSSSSSO.." if frame == 6 else "..OSSSSSSvvSSO.."
		rows[17] = "...OSSSSSSSSO..."
	var hair: Array = look.hair
	var skin: Array = look.skin
	var shirt: Array = look.shirt
	var pants: Array = look.pants
	var legend := {"O": 65, "H": hair[0], "h": hair[1], "L": hair[2], "v": skin[0], "u": skin[1], "b": skin[2], "e": 65,
		"m": 105, "S": shirt[0], "s": shirt[1], "l": shirt[2], "P": pants[0], "p": pants[1], "F": 102, "x": 66,
		"G": 65, "C": look.get("cap", 100), "k": 85, "t": 87}
	if look.style == "cap":
		legend["C"] = look.cap
	if look.style == "tie":
		legend["t"] = 87
	return Kit.art(rows, legend)

const CAT_SIT := [
"................",
"....o....o......",
"...oOo..oOo.....",
"...oOOooOOo.....",
"...oOOOOOOo.....",
"...oOeOOeOo.....",
"...oOOnnOOo.oo..",
"....oOOOOo.oOo..",
"...oOOWWOOo.oOo.",
"..oOOdWWdOOooOo.",
"..oOOOOOOOOOoOo.",
"...ooooooooooo.."]
const CAT_WALK := [
"................",
"..........o.o...",
".........oOoOo..",
".........oOOOOo.",
"..oo.....oOeOOnn",
".oOOoooooOOOOoo.",
"oOdOOdOOOOOOOo..",
"oOOdOOdOOOOOOo..",
".ooOOOOOOOOOOo.."]
const CAT_LEGS := [
["..oOo..oOo.oOo..", "..oOo..oOo.oOo..", "..ooo..ooo.ooo.."],
["...oOo.oOo.oOo..", "...oOo.oOo.oOo..", "...ooo.ooo.ooo.."],
[".oOo...oOo..oOo.", ".oOo...oOo..oOo.", ".ooo...ooo..ooo."],
["..oOo...oOo.oOo.", "..oOo...oOo.oOo.", "..ooo...ooo.ooo."]]
static func cat_frames() -> Array:
	var legend := {"o": 65, "O": 70, "d": 98, "W": 102, "n": 85, "e": 65}
	var frames: Array = []
	frames.append(Kit.art(CAT_SIT, legend))
	var blink: Array = []
	for row in CAT_SIT:
		blink.append(row.replace("e", "d"))
	frames.append(Kit.art(blink, legend))
	for leg in CAT_LEGS:
		var rows: Array = CAT_WALK.duplicate()
		rows.append_array(leg)
		frames.append(Kit.art(rows, legend))
	return frames

static var _cache: Dictionary = {}
static func definitions() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	for person in LOOKS:
		var frames: Array = []
		for frame in range(6 if person == "hanh" else 8):
			frames.append(build_rows(LOOKS[person], frame))
		_cache[person] = {"size": Vector2i(16, 24), "frames": frames}
	_cache["cat"] = {"size": Vector2i(16, 12), "frames": cat_frames()}
	return _cache

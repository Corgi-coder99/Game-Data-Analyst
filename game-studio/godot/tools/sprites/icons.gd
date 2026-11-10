extends RefCounted
const ICONS := {
"arrow_up":["...n....","..nnn...",".nnnnn..","...n....","...n....","...n....","........","........"],
"arrow_down":["...p....","...p....","...p....",".ppppp..","..ppp...","...p....","........","........"],
"arrow_flat":["........","........","......6.",".6666666","......6.","........","........","........"],
"check":["........","......n.",".....nn.",".n..nn..",".nnnn...","..nn....","........","........"],
"cross":["........",".pp..pp.","..pppp..","...pp...","..pppp..",".pp..pp.","........","........"],
"question":["..rrr...",".r...r..",".....r..","...rr...","...r....","........","...r....","........"],
"lock":["..444...",".4...4..",".4...4..","rrrrrrr.","rrr1rrr.","rrr1rrr.","rrrrrrr.","........"],
"shield":[".jjjjjj.",".jhhhhj.",".jhkkhj.",".jhkkhj.","..jhhj..","...jj...","........","........"],
"newspaper":["6666666.","6ddddd6.","6d33dd6.","6d33dd6.","6ddddd6.","6d333d6.","6666666.","........"],
"bubble":["ttttttt.","tssssst.","tsstsst.","tssssst.","ttttttt.","..tt....",".t......","........"],
"flag":["..6.....","..6rrrr.","..6rrrr.","..6rrr..","..6.....","..6.....",".666....","........"],
"dash":["........","........","........",".666666.",".666666.","........","........","........"],
"clock_old":["..5555..",".5....5.","5...6..5","5...6..5","5...666.","5......5",".5....5.","..5555.."],
"emote_happy":["..rrrr..",".rrrrrr.","rr0rr0rr","rrrrrrrr","r0rrrr0r","rr0000rr",".rrrrrr.","..rrrr.."],
"emote_sad":["..jjjj..",".jjjjjj.","jj0jj0jj","jjjjjjjj","jj0000jj","j0jjjj0j",".jjjjjj.","..jjjj.."],
"emote_angry":["..pppp..",".0pppp0.","pp0pp0pp","pppppppp","pp0000pp","p0pppp0p",".pppppp.","..pppp.."],
"emote_neutral":["..6666..",".666666.","66066066","66666666","66666666","66000066",".666666.","..6666.."],
"thumb":["....vv..","...vvv..","...vvu..",".vvvvvv.",".vvvvvu.",".vvvvvu.",".uuuuuu.","........"]}
static func definitions() -> Dictionary:
	var out := {}
	for id in ICONS:
		out[id] = {"size":Vector2i(8,8),"frames":[ICONS[id]]}
	return out

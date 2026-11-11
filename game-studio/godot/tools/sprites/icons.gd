extends RefCounted
# T-028 cozy 8x8 icons (palette v4). Legend: o plum outline, G green, g dark green, R red, r wine, Y yellow, y gold,
# B sky blue, b deep blue, W cream, w light gray, P pink, p rose, L lavender, T teal, t dark teal, O orange, n mauve, k gray, S skin.
const Kit = preload("res://tools/sprites/kit.gd")
const LEGEND := {"o": 65, "G": 75, "g": 74, "R": 26, "r": 88, "Y": 89, "y": 96, "B": 94, "b": 84, "W": 102, "w": 101, "P": 85, "p": 87,
	"L": 93, "T": 91, "t": 78, "O": 97, "n": 99, "k": 100, "S": 106, "s": 104, "D": 83, "M": 80, "Q": 82}
const ICONS := {
"arrow_up":["...GG...","..GGGG..",".GGGGGG.","gggGGggg","...GG...","...Gg...","...gg...","........"],
"arrow_down":["...Rr...","...Rr...","...Rr...","rrrRRrrr",".RRRRRR.","..RRRR..","...RR...","........"],
"arrow_flat":["........","...k....","....k...","kkkkkkk.","....k...","...k....","........","........"],
"check":["........","......G.",".....GG.",".G..GG..",".GGGG...","..GG....","........","........"],
"cross":["........",".RR..RR.","..RRRR..","...RR...","..RRRR..",".RR..RR.","........","........"],
"question":["..BBBB..",".BbbbbB.","......bB","....BB..","...Bb...","........","...Bb...","........"],
"lock":["..kkk...",".k...k..",".k...k..","yyyyyyy.","yYYoYYy.","yYYoYYy.","yyyyyyy.","........"],
"shield":[".bbbbbb.","bBBBBBBb","bBWBBBBb","bBWBBBBb",".bBBBBb.","..bBBb..","...bb...","........"],
"newspaper":["wwwwwww.","wWWWWWw.","wWBBWWw.","wWBBWWw.","wWWWWWw.","wWkkkWw.","wwwwwww.","........"],
"bubble":["PPPPPPP.","PWWWWWP.","PWPWPWP.","PWWWWWP.","PPPPPPP.","..PP....",".P......","........"],
"flag":["..n.....","..nRRRR.","..nRRRr.","..nRRr..","..n.....","..n.....",".nnn....","........"],
"dash":["........","........","........",".kkkkkk.",".kkkkkk.","........","........","........"],
"clock_old":["..oooo..",".oWWWWo.","oWWnWWWo","oWWnWWWo","oWWnnnWo","oWWWWWWo",".oWWWWo.","..oooo.."],
"emote_happy":["..YYYY..",".YYYYYY.","YYoYYoYY","YPYYYYPY","YoYYYYoY","YYooooYY",".YYYYYY.","..yyyy.."],
"emote_sad":["..BBBB..",".BBBBBB.","BBoBBoBB","BPBBBBPB","BBooooBB","BoBBBBoB",".BBBBBB.","..bbbb.."],
"emote_angry":["..RRRR..",".oRRRRo.","RRoRRoRR","RRRRRRRR","RRooooRR","RoRRRRoR",".RRRRRR.","..rrrr.."],
"emote_neutral":["..LLLL..",".LLLLLL.","LLoLLoLL","LLLLLLLL","LLLLLLLL","LLooooLL",".LLLLLL.","..MMMM.."],
"thumb":["....SS..","...SSS..","...SSs..",".SSSSSS.",".SSSSSs.",".SSSSSs.",".ssssss.","........"],
"crest_chinh_thuc":["..RRRR..",".RYYYYR.",".RYRRYR.",".RYRRYR.","..RYYR..","...RR...","........","........"],
"crest_bao_chi":["kkkkkkkk","kooooook","kowwwwok","kkkkkkkk","kooooook","kooooook","kkkkkkkk","........"],
"crest_mang_xa_hoi":[".PPPPPP.","PPPPPPPP","PPWPPWPP","PPPPPPPP",".PPPPPP.","..PP....",".P......","........"],
"crest_noi_bo":["..kkkk..",".k....k.",".k....k.","yyyyyyyy","yyyooyyy","yyyooyyy","yyyyyyyy","........"],
"app_news":["..oooo..",".oBBGGo.","oBBGGBBo","oBGGGBBo","oBBGGGBo","oBBBGGBo",".oBBBBo.","..oooo.."],
"app_mail":["oooooooo","oWWWWWWo","oWpWWpWo","oWWpppWo","oWWWppWo","oWWWWWWo","oooooooo","........"],
"app_bi":["oooooooo","oDDDDDDo","oDDDDGDo","oDGDDGDo","oDGDGGDo","oDGGGGDo","oDDDDDDo","oooooooo"],
"app_code":["oooooooo","oDDDDDDo","oDGDDDDo","oDDGDDDo","oDGDDDDo","oDDDGGDo","oDDDDDDo","oooooooo"],
"app_help":["..oooo..",".oYYYYo.","oYYoooYo","oYYYYoYo","oYYYooYo","oYYYYYYo",".oYYoYo.","..oooo.."],
"app_files":["........",".yyy....","yYYYYYYy","yYYYYYYy","yYYYYYYy","yYYYYYYy","yyyyyyyy","........"],
"app_sheet":["oooooooo","oGGoGGGo","oooooooo","oWWoWWWo","oooooooo","oWWoWWWo","oooooooo","oooooooo"],
"app_handbook":[".oooooo.","oBBBBBBo","oBWWWWBo","oBWwWWBo","oBWWWRBo","oBWWWRBo","oBBBBBBo",".oooooo."],
"app_charts":["oooooooo","oWWWWWWo","oWWWWBWo","oWWBWBWo","oWBBWBWo","oWBBBBWo","oooooooo","........"]}
static func definitions() -> Dictionary:
	var out := {}
	for id in ICONS:
		out[id] = {"size": Vector2i(8, 8), "frames": [Kit.art(ICONS[id], LEGEND)]}
	return out

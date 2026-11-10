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
"thumb":["....vv..","...vvv..","...vvu..",".vvvvvv.",".vvvvvu.",".vvvvvu.",".uuuuuu.","........"],
"topic_lai_suat":["........","rr....r.","rr...r..","....r...","...r....","..r...rr",".r....rr","........"],
"topic_ty_gia":["...j....","jjjjjj..","...j....","........","....k...","..kkkkkk","....k...","........"],
"topic_nguyen_lieu":["........","bbbbbbbb","bccddccb","b9cddc9b","bccddccb","b9cddc9b","bbbbbbbb","........"],
"topic_suc_mua":["..7777..",".7....7.","mmmmmmmm","mnnnnnnm","mnn77nnm","mnnnnnnm","mmmmmmmm","........"],
"topic_chung_khoan":["........","......nn","......nn","...nn.nn","...nn.nn","nn.nn.nn","nn.nn.nn","66666666"],
"topic_tin_dung":["........","iiiiiiii","iiiiiiii","00000000","iiiiiiii","irriiiii","iiiiiiii","........"],
"topic_noi_bo":["........","66666666","67666676","66766766","66677666","66666666","66666666","........"],
"crest_chinh_thuc":["..rrrr..",".rqqqqr.",".rqrrqr.",".rqrrqr.","..rqqr..","...rr...","........","........"],
"crest_bao_chi":["77777777","70000007","70777707","77777777","70000007","70000007","77777777","........"],
"crest_mang_xa_hoi":[".tttttt.","tttttttt","tt7tt7tt","tttttttt",".tttttt.","..tt....",".t......","........"],
"crest_noi_bo":["..4444..",".4....4.",".4....4.","rrrrrrrr","rrr00rrr","rrr00rrr","rrrrrrrr","........"],
"app_news":["..jjjj..",".jkkjjj.","jkkjjkjj","jjjjkkkj","jjkkjjjj","jjjjjkkj",".jjjjjj.","..jjjj.."],
"app_mail":["........","77777777","76777767","77677677","77766777","777pp777","77777777","........"],
"app_bi":["44444444","40000004","40000n04","40n00n04","40n0nn04","40nnnn04","40000004","44444444"],
"app_code":["55555555","50000005","50n00005","500n0005","50n00005","50000nn5","50000005","55555555"],
"app_help":["..jjjj..",".jj77jj.","jjjjj7jj","jjjj7jjj","jjjj7jjj","jjjjjjjj",".jjj7jj.","..jjjj.."]}
static func definitions() -> Dictionary:
	var out := {}
	for id in ICONS:
		out[id] = {"size":Vector2i(8,8),"frames":[ICONS[id]]}
	return out

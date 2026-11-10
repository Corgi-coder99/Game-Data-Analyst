extends SceneTree
const Generator = preload("res://tools/gen_sprites.gd")
const Checker = preload("res://tools/check_palette.gd")
var checks := 0
var failures := 0
var seated_count := 0
var closed_count := 0
var desk_count := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL ",label)
func hashes() -> Dictionary:
	var result := {}
	for name in DirAccess.get_files_at("res://assets/v2"):
		if name.ends_with(".png"):
			result[name] = FileAccess.get_sha256("res://assets/v2/"+name)
	return result
func _init() -> void:
	call_deferred("run")
func inspect(node: Node) -> void:
	if node is CanvasItem:
		check(node.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST or node.texture_filter == CanvasItem.TEXTURE_FILTER_PARENT_NODE,"nearest inherited: "+str(node.name))
	if node is Node2D or node is Control:
		check(node.position == node.position.round(),"integer position: "+str(node.name))
	for child in node.get_children():
		inspect(child)
func run() -> void:
	check(Generator.generate(),"first generation")
	var first := hashes()
	check(Generator.generate(),"second generation")
	check(first == hashes(),"byte deterministic")
	check(Checker.validate(),"palette validation")
	var expected := {
	"player":[16,24,8],"khoi":[16,24,8],"mai":[16,24,8],"tu":[16,24,8],"hanh":[16,24,6],
	"desk":[48,24,2],"chair":[16,24,1],"plant":[16,24,2],"cabinet":[24,32,1],
	"window":[32,32,3],"door":[24,40,2],"floor":[16,16,1],"wall":[16,16,1],
	"baseboard":[16,16,1],"clock":[16,16,1],"cat":[16,12,6]}
	for staff in ["rin","bao","linh","dat","an","vy","sam","ngoc","ops","lead","intern","kai","mei","pat"]:
		expected[staff] = [16,24,8]
	for icon in ["arrow_up","arrow_down","arrow_flat","check","cross","question","lock","shield","newspaper","bubble","flag","dash","clock_old","emote_happy","emote_sad","emote_angry","emote_neutral","thumb","crest_chinh_thuc","crest_bao_chi","crest_mang_xa_hoi","crest_noi_bo","app_news","app_mail","app_bi","app_code","app_help"]:
		expected[icon] = [8,8,1]
	for topic in ["lai_suat","ty_gia","nguyen_lieu","suc_mua","chung_khoan","tin_dung","noi_bo"]:
		expected["topic_" + topic] = [32,32,1]
	check(first.size() == expected.size(),"complete sprite inventory")
	for id in expected:
		var image := Image.load_from_file("res://assets/v2/"+id+".png")
		var dimensions: Array = expected[id]
		check(image != null and image.get_size() == Vector2i(dimensions[0]*dimensions[2],dimensions[1]),"dimensions "+id)
	var bad := Image.create(1,1,false,Image.FORMAT_RGBA8)
	bad.set_pixel(0,0,Color(1,0,1,1))
	check(not Checker.validate_image(bad,"expected-invalid-color",false),"reject foreign color")
	bad.set_pixel(0,0,Color(0,0,0,0.5))
	check(not Checker.validate_image(bad,"expected-invalid-alpha",false),"reject partial alpha")
	var office = load("res://scenes/v2/office.tscn").instantiate()
	root.add_child(office)
	office.set_process(false)
	office.seated.connect(func(): seated_count += 1)
	office.dialog_closed.connect(func(): closed_count += 1)
	office.desk_clicked.connect(func(): desk_count += 1)
	inspect(office)
	office.play_arrival()
	var frame := 0
	while office.arrival_active and frame < 600:
		office.advance(1.0/60)
		check(office.player.position == office.player.position.round(),"integer animation")
		frame += 1
	check(frame < 600 and seated_count == 1,"arrival completes once")
	office.advance(1.0)
	check(seated_count == 1,"arrival no duplicate")
	for phase in ["sang","trua","chieu"]:
		check(office.set_phase(phase),"phase "+phase)
		check(office.phase == phase,"phase retained")
	check(not office.set_phase("invalid") and office.phase == "chieu","invalid phase rejected without mutation")
	office.set_clock(15,45)
	check(office.clock_hour == 15 and office.clock_minute == 45,"clock API")
	office.play_boss_appears("I need evidence.")
	check(office.boss.visible and office.dialog.visible,"boss appears")
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.pressed = true
	office._unhandled_input(enter)
	check(closed_count == 1 and not office.dialog.visible and not office.boss.visible,"confirm closes boss dialog")
	office.hide_dialog()
	check(closed_count == 1,"hide is idempotent")
	office._unhandled_input(enter)
	check(desk_count == 1,"Enter opens desk")
	office.desk_button.pressed.emit()
	check(desk_count == 2,"desk click")
	var text := "Long English line: data, evidence, certainty. ".repeat(8).substr(0,300)
	office.show_dialog("Khoi",text)
	await process_frame
	check(office.dialog_text.text == text,"long dialogue text retained")
	for control in [office.dialog,office.speaker_label,office.dialog_text]:
		check(Rect2(Vector2.ZERO,Vector2(640,360)).encloses(control.get_global_rect()),"dialog inside viewport")
	check(office.dialog_text.scroll_active,"long dialogue scrolls within bounds")
	office.hide_dialog()
	check(closed_count == 2,"public dialog closes")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png(OS.get_environment("TEMP")+"/T-019a-office.png")
	office.free()
	print("test_v2_assets: ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)



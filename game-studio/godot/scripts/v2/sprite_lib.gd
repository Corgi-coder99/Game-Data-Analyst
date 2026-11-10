extends RefCounted
const Generator = preload("res://tools/gen_sprites.gd")
var textures: Dictionary = {}
var definitions: Dictionary = Generator.definitions()
func frame(id: String, index: int = 0) -> AtlasTexture:
	assert(definitions.has(id))
	if not textures.has(id):
		textures[id] = ImageTexture.create_from_image(Image.load_from_file("res://assets/v2/" + id + ".png"))
	var atlas := AtlasTexture.new()
	atlas.atlas = textures[id]
	var size: Vector2i = definitions[id].size
	atlas.region = Rect2(Vector2i(posmod(index,definitions[id].frames.size()) * size.x,0),size)
	atlas.filter_clip = true
	return atlas
func sprite(id: String, index: int = 0) -> Sprite2D:
	var node := Sprite2D.new()
	node.texture = frame(id,index)
	node.centered = false
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return node

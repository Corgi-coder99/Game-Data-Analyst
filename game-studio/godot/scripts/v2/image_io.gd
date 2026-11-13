extends RefCounted
# Exported builds keep only the imported texture, not the source PNG: Image.load_from_file() on res:// fails there.
# In the editor and in tests the source file exists and is read exactly as before.
static func exists(path: String) -> bool:
	return FileAccess.file_exists(path) or ResourceLoader.exists(path)

static func load_image(path: String) -> Image:
	if FileAccess.file_exists(path): return Image.load_from_file(path)
	var texture := load(path) as Texture2D
	return texture.get_image() if texture != null else null

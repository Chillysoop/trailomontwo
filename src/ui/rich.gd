class_name Rich
extends RefCounted
## Text with inline icons and hoverable keywords.
##
## Markup understood by `bb()`:
##   {i:id}          icon only (hover explains it)
##   {ik:id}         icon followed by its name
##   {k:id}          underlined keyword (hover explains it)
##   {k:id|words}    underlined custom words that explain `id`
##   {c:species}     underlined creature name (hover shows its card)
## Everything else is plain BBCode.

const KEYWORD := Color("ffe3a3")
const CREATURE := Color("c9f0ff")
const ICON_PX := 12

static var _token := RegEx.create_from_string("\\{(i|ik|k|c):([a-z0-9_]+)(?:\\|([^}]*))?\\}")


static func icon_path(id: String) -> String:
	return "res://assets/icons/%s.png" % id


static func icon_tex(id: String) -> Texture2D:
	var path := icon_path(id)
	return load(path) if ResourceLoader.exists(path) else null


## Converts markup to BBCode.
static func bb(text: String, px := ICON_PX) -> String:
	var out := ""
	var at := 0
	for m in _token.search_all(text):
		out += text.substr(at, m.get_start() - at)
		at = m.get_end()
		var kind := m.get_string(1)
		var id := m.get_string(2)
		var words := m.get_string(3)
		match kind:
			"i":
				out += _img(id, px, "g:" + id)
			"ik":
				out += "%s %s" % [_img(id, px, "g:" + id), words if words != "" else Glossary.entry_name(id)]
			"k":
				out += "[url=g:%s][color=#%s][u]%s[/u][/color][/url]" % [id, KEYWORD.to_html(false), words if words != "" else Glossary.entry_name(id)]
			"c":
				var name: String = words if words != "" else Species.info(id)["name"]
				out += "[url=c:%s][color=#%s][u]%s[/u][/color][/url]" % [id, CREATURE.to_html(false), name]
	out += text.substr(at)
	return out


static func _img(id: String, px: int, meta: String) -> String:
	var icon_id := Glossary.icon(id) if Glossary.has(id) and Glossary.icon(id) != "" else id
	if not ResourceLoader.exists(icon_path(icon_id)):
		return "[url=%s][u]%s[/u][/url]" % [meta, Glossary.entry_name(id)]
	return "[url=%s][img=%dx%d]%s[/img][/url]" % [meta, px, px, icon_path(icon_id)]


## A RichTextLabel set up for game text. Keywords and icons in it show tips on hover.
static func label(text := "", size := 8, width := 0.0) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.meta_underlined = false
	l.selection_enabled = false
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	l.add_theme_font_size_override("normal_font_size", size)
	l.add_theme_font_size_override("bold_font_size", size + 1)
	l.add_theme_font_size_override("italics_font_size", size)
	l.add_theme_color_override("default_color", PreviewHud.INK)
	l.add_theme_constant_override("line_separation", 1)
	if width > 0.0:
		l.custom_minimum_size = Vector2(width, 0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.meta_hover_started.connect(func(meta): Tips.show_meta(str(meta), l))
	l.meta_hover_ended.connect(func(_meta): Tips.hide_from(l))
	l.mouse_exited.connect(func(): Tips.hide_from(l))
	set_text(l, text)
	return l


static func set_text(l: RichTextLabel, text: String) -> void:
	l.text = bb(text)


## Adds an outline so text stays readable over scenery.
static func outlined(l: RichTextLabel) -> RichTextLabel:
	l.add_theme_color_override("font_outline_color", Color("2b2030"))
	l.add_theme_constant_override("outline_size", 4)
	return l


## A small hoverable icon control.
static func icon_rect(id: String, px := ICON_PX) -> TextureRect:
	var r := TextureRect.new()
	r.texture = icon_tex(Glossary.icon(id) if Glossary.icon(id) != "" else id)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(px, px)
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	Tips.attach(r, "g:" + id)
	return r

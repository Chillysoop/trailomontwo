class_name Tips
extends CanvasLayer
## The hover tooltip. One shared panel that follows the mouse.
##
## Sources call `show_meta("g:food", self)` (a glossary entry), `show_meta("c:reedwake", self)`
## (a creature card) or `show_text(markup, self)`, and `hide_from(self)` when the mouse leaves.
## `attach(control, what)` wires a Control's mouse enter/exit to do that for you.

const WIDTH := 190.0
const OFFSET := Vector2(10, 12)
const SCREEN := Vector2(640, 360)

static var _inst: Tips

var _panel: PanelContainer
var _label: RichTextLabel
var _source: Object
var _title_icon: TextureRect


static func get_inst() -> Tips:
	if _inst == null or not is_instance_valid(_inst):
		_inst = Tips.new()
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null:
			tree.root.add_child.call_deferred(_inst)
	return _inst


static func show_meta(meta: String, source: Object) -> void:
	var text := content(meta)
	if text != "":
		show_text(text, source)


static func show_text(markup: String, source: Object) -> void:
	get_inst()._show(markup, source)


static func hide_from(source: Object) -> void:
	if _inst != null and is_instance_valid(_inst) and (_inst._source == source or source == null):
		_inst._hide()


static func is_showing() -> bool:
	return _inst != null and is_instance_valid(_inst) and _inst._panel.visible


## Shows a tip while the mouse is over `control`. `what` is a meta string ("g:id", "c:species")
## or a Callable returning markup (evaluated each time the tip opens).
static func attach(control: Control, what: Variant) -> void:
	if control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		control.mouse_filter = Control.MOUSE_FILTER_PASS
	control.mouse_entered.connect(func():
		if what is Callable:
			var t: String = (what as Callable).call()
			if t != "":
				show_text(t, control)
		else:
			show_meta(str(what), control))
	control.mouse_exited.connect(func(): hide_from(control))
	control.tree_exiting.connect(func(): hide_from(control))


## Markup for a meta string.
static func content(meta: String) -> String:
	var kind := meta.get_slice(":", 0)
	var id := meta.get_slice(":", 1)
	match kind:
		"g":
			if not Glossary.has(id):
				return ""
			var head := "{i:%s} " % id if Glossary.icon(id) != "" else ""
			return "%s[b]%s[/b]\n%s" % [head, Glossary.entry_name(id), Glossary.text(id)]
		"c":
			if not Species.DATA.has(id):
				return ""
			return CreatureCard.markup(id)
	return ""


func _init() -> void:
	layer = 100
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := PreviewHud.box(Color(0.10, 0.08, 0.12, 0.96))
	box.set_content_margin_all(4)
	_panel.add_theme_stylebox_override("panel", box)
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.meta_underlined = false
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("normal_font_size", 8)
	_label.add_theme_font_size_override("bold_font_size", 9)
	_label.add_theme_color_override("default_color", PreviewHud.INK)
	_label.add_theme_constant_override("line_separation", 1)
	_label.custom_minimum_size = Vector2(WIDTH, 0)
	_panel.add_child(_label)
	_panel.visible = false
	add_child(_panel)


func _show(markup: String, source: Object) -> void:
	_source = source
	var bbcode := Rich.bb(markup)
	if _label.text != bbcode:
		_label.text = bbcode
	_panel.visible = true
	_panel.reset_size.call_deferred()
	_place()


func _hide() -> void:
	_source = null
	_panel.visible = false


func _process(_delta: float) -> void:
	if not _panel.visible:
		return
	# Hide if whatever asked for the tip went away.
	if _source == null or not is_instance_valid(_source):
		_hide()
		return
	if _source is CanvasItem and not (_source as CanvasItem).is_visible_in_tree():
		_hide()
		return
	_place()


func _place() -> void:
	if not is_inside_tree():
		return
	var mouse := get_viewport().get_mouse_position()
	var size := _panel.size
	var pos := mouse + OFFSET
	if pos.x + size.x > SCREEN.x - 2:
		pos.x = mouse.x - OFFSET.x - size.x
	if pos.y + size.y > SCREEN.y - 2:
		pos.y = mouse.y - 4 - size.y
	_panel.position = pos.clamp(Vector2(2, 2), (SCREEN - size - Vector2(2, 2)).max(Vector2(2, 2))).round()

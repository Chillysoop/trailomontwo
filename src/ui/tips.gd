class_name Tips
extends CanvasLayer
## The hover tooltip. One shared panel that follows the mouse.
##
## Sources call `show_meta("g:food", self)` (a glossary entry), `show_meta("c:reedwake", self)`
## (a creature card) or `show_text(markup, self)`, and `hide_from(self)` when the mouse leaves.
## `attach(control, what)` wires a Control's mouse enter/exit to do that for you.
## Markup after a SIDE marker opens as its own small popup stacked beside the main one
## (keyword explanations, like Astronarch).

## Splits the main tip from its side popups.
const SIDE := "\u001e"
const SIDE_WIDTH := 132.0
const GAP := 3.0
const WIDTH := 236.0
const OFFSET := Vector2(10, 12)
const SCREEN := Vector2(640, 360)

static var _inst: Tips

var _panel: PanelContainer
var _label: RichTextLabel
var _source: Object
var _title_icon: TextureRect
var _side: VBoxContainer
var _side_boxes: Array[PanelContainer] = []
var _side_labels: Array[RichTextLabel] = []


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
	_panel = _make_panel(Color(0.10, 0.08, 0.12, 0.96))
	_label = _make_label(WIDTH)
	_panel.add_child(_label)
	add_child(_panel)
	_side = VBoxContainer.new()
	_side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_side.add_theme_constant_override("separation", 2)
	_side.visible = false
	add_child(_side)


static func _make_panel(bg: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := PreviewHud.box(bg)
	box.set_content_margin_all(4)
	p.add_theme_stylebox_override("panel", box)
	p.visible = false
	return p


static func _make_label(width: float) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.meta_underlined = false
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("normal_font_size", 8)
	l.add_theme_font_size_override("bold_font_size", 9)
	l.add_theme_color_override("default_color", PreviewHud.INK)
	l.add_theme_constant_override("line_separation", 1)
	l.custom_minimum_size = Vector2(width, 0)
	return l


func _show(markup: String, source: Object) -> void:
	_source = source
	var parts := markup.split(SIDE)
	var bbcode := Rich.bb(parts[0])
	if _label.text != bbcode:
		_label.text = bbcode
	_panel.visible = true
	_panel.reset_size.call_deferred()
	while _side_boxes.size() < parts.size() - 1:
		var p := _make_panel(Color(0.13, 0.10, 0.15, 0.96))
		var l := _make_label(SIDE_WIDTH)
		p.add_child(l)
		_side.add_child(p)
		_side_boxes.append(p)
		_side_labels.append(l)
	for i in _side_boxes.size():
		var on := i + 1 < parts.size()
		_side_boxes[i].visible = on
		if on:
			var side_bb := Rich.bb(parts[i + 1])
			if _side_labels[i].text != side_bb:
				_side_labels[i].text = side_bb
	_side.visible = parts.size() > 1
	_side.reset_size.call_deferred()
	_place()


func _hide() -> void:
	_source = null
	_panel.visible = false
	_side.visible = false


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
	var side_w := _side.size.x + GAP if _side.visible else 0.0
	var pos := mouse + OFFSET
	# Keep the main tip and its side popups on screen together where possible.
	if pos.x + size.x + side_w > SCREEN.x - 2:
		pos.x = mouse.x - OFFSET.x - size.x - side_w
	if pos.y + size.y > SCREEN.y - 2:
		pos.y = mouse.y - 4 - size.y
	_panel.position = pos.clamp(Vector2(2, 2), (SCREEN - size - Vector2(2, 2)).max(Vector2(2, 2))).round()
	if _side.visible:
		# Right edge of the main tip, or its left edge if there's no room on the right.
		var sx := _panel.position.x + size.x + GAP
		if sx + _side.size.x > SCREEN.x - 2:
			sx = _panel.position.x - GAP - _side.size.x
		var sy := minf(_panel.position.y, SCREEN.y - 2 - _side.size.y)
		_side.position = Vector2(sx, maxf(2.0, sy)).round()

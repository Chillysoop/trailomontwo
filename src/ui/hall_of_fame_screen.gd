class_name HallOfFameScreen
extends Control
## The Hall of Fame from the title screen: each finished crossing with its team.
##
##   HallOfFameScreen.open(parent)

signal closed

const SCREEN := Vector2(640, 360)
const PIC := 22.0


static func open(parent: Node) -> HallOfFameScreen:
	var s := HallOfFameScreen.new()
	parent.add_child(s)
	return s


func _ready() -> void:
	size = SCREEN
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.06, 0.82)
	dim.size = SCREEN
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(30, 14)
	panel.custom_minimum_size = Vector2(580, 332)
	var box := PreviewHud.box(Color(0.13, 0.10, 0.15, 0.97))
	box.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", box)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var title := Rich.label("{i:hall_of_fame} [b]Hall of Fame[/b]", 12, 300)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := Ui.button("Close (Esc)", 8)
	close.pressed.connect(_close)
	head.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(566, 296)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var all := HallOfFame.entries()
	if all.is_empty():
		list.add_child(Rich.label("[color=#%s]No crossings finished yet. Reach the far town and your team's names go up here.[/color]" % CreatureCard.MUTED, 9, 540))
	for e in all:
		list.add_child(_row(e))
	close.grab_focus.call_deferred()


func _row(e: Dictionary) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 1)
	var how := {"toll": " by the toll road", "rapids": " by the rapids", "fight": ""}.get(String(e.get("finale", "")), "")
	row.add_child(Rich.label("[b]Crossing %d[/b]%s   day %d   {i:score} %d [color=#ffe3a3]%s[/color]   [color=#%s]%s[/color]" % [
		int(e.get("crossing", 1)), how, int(e.get("day", 0)), int(e.get("score", 0)), String(e.get("rank", "")),
		CreatureCard.MUTED, String(e.get("date", ""))], 9, 560))
	var pics := HBoxContainer.new()
	pics.add_theme_constant_override("separation", 6)
	row.add_child(pics)
	for m in e.get("team", []):
		var id := String(m.get("id", ""))
		if not Species.DATA.has(id):
			continue
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		var pic := TextureRect.new()
		pic.texture = CompanionsScreen.portrait(id)
		pic.custom_minimum_size = Vector2(PIC, PIC)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		Glint.apply(pic, bool(m.get("glint", false)))
		cell.add_child(pic)
		cell.add_child(Rich.label("%s\n[color=#ffe3a3]Lv %d[/color]" % [String(m.get("name", "")), int(m.get("level", 1))], 7, 70))
		pics.add_child(cell)
	return row


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	closed.emit()
	queue_free()

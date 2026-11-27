class_name GuideScreen
extends Control
## A short "how to play" guide: a few pages shown when a new caravan sets out, and again from
## the Guide button on the top bar. It tells a new player the goal and what keeps them alive.

signal closed

const SCREEN := Vector2(640, 360)

var crossing: Expedition
var page := 0
var _title: RichTextLabel
var _body: RichTextLabel
var _count: Label
var _next: Button
var _back: Button


static func open(parent: Node, e: Expedition) -> GuideScreen:
	var s := GuideScreen.new()
	s.crossing = e
	parent.add_child(s)
	return s


## The guide's pages: [title, body] in Rich markup.
static func pages(e: Expedition) -> Array:
	var goal := e.map.name_of(e.map.goal) if e != null and e.map != null else "the goal"
	return [
		["{i:settlement} Your goal",
			"Lead your wagon and its Trailomon across the wilds to [b]%s[/b].\n\n" % goal
			+ "Pick a road at each stop and watch the caravan travel day by day. On the last road a [b]guardian[/b] blocks the way. Beat it to finish the crossing.\n\n"
			+ "Lose to the guardian and your caravan falls back to the last stop. Rest, rethink your team and try again, but every extra day costs supplies."],
		["{i:food} Food and water",
			"Every day on the road eats {i:food} food and {i:water} water. [b]If both run out, the crossing fails.[/b]\n\n"
			+ "Buy more in the {i:trade} [b]Trade[/b] tab at a stop before you set off. Your purse of {i:coins} coins is small, so spend it on supplies first and extras later.\n\n"
			+ "Resting heals your team but costs a day of food too."],
		["{i:risk} Roads and fights",
			"Roads with more {i:risk} risk mean more wild fights. Fights are dangerous, but they are where your team gets {i:xp} experience, dust and loot.\n\n"
			+ "Safe roads keep you fed; risky ones make you strong. Choose your path to get your team ready for the guardian without running dry."],
		["{i:xp} Growing your team",
			"Every level-up is a choice: one of two stat boosts, or a new move from one of two styles. Make them on the [b]Companions[/b] screen.\n\n"
			+ "You start with just your partner. After each wild win you get [b]one try to catch[/b] a worn-out foe; a {i:lure} lure improves the odds. Rare ones are harder to catch.\n\n"
			+ "Lean into a style and use {i:light_dust} dust on your best fighters.\n\n"
			+ "Before a battle, set your lineup (the front row is hit first) and fill the {i:item_slot} three item slots. Save your best items for the guardian."],
	]


func _ready() -> void:
	size = SCREEN
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.06, 0.7)
	dim.size = SCREEN
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.size = SCREEN
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	panel.add_theme_stylebox_override("panel", PreviewHud.box(Color(0.13, 0.10, 0.15, 0.97)))
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	var head := HBoxContainer.new()
	_title = Rich.label("", 13)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	_count = PreviewHud.label("", 8)
	head.add_child(_count)
	col.add_child(head)
	_body = Rich.label("", 9, 346)
	col.add_child(_body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var skip := Ui.button("Skip guide", 9)
	skip.pressed.connect(close_screen)
	row.add_child(skip)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap)
	_back = Ui.button("Back", 9)
	_back.pressed.connect(func(): _show(page - 1))
	row.add_child(_back)
	_next = Ui.button("Next", 9)
	_next.name = "GuideNext"
	_next.pressed.connect(func():
		if page >= pages(crossing).size() - 1:
			close_screen()
		else:
			_show(page + 1))
	row.add_child(_next)
	col.add_child(row)
	_show(0)


func _show(i: int) -> void:
	var all := pages(crossing)
	page = clampi(i, 0, all.size() - 1)
	Rich.set_text(_title, "[b]%s[/b]" % all[page][0])
	Rich.set_text(_body, all[page][1])
	_count.text = "%d / %d" % [page + 1, all.size()]
	_back.disabled = page == 0
	_next.text = "Let's go!" if page == all.size() - 1 else "Next"
	_next.grab_focus.call_deferred()


func close_screen() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_screen()

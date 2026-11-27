class_name Personalities
extends RefCounted
## Personality quirks: every Trailomon you catch has one, and it moves the crew's morale
## (Expedition.change_morale) when the right thing happens. Separate from temperament, which
## leans its stats. Each quirk names the moments it reacts to and by how much:
##   win, lose, rest, meal, landmark   (when those happen; win/lose only if it fought)
##   home_day   (a travel day on its own habitat's roads)
##   lead_day   (a travel day walking beside the wagon as the lead)
##   storm_day  (a travel day in rain or a storm)
##   thin_day   (a travel day on thin rations)

const KINDS := {
	"showoff": {"name": "Show-off", "text": "Struts after every win.", "on": {"win": 2}},
	"glutton": {"name": "Glutton", "text": "Lives for hot meals; sulks on thin rations.", "on": {"meal": 4, "thin_day": -1}},
	"homebody": {"name": "Homebody", "text": "Happiest on its own habitat's roads.", "on": {"home_day": 1}},
	"sunny": {"name": "Sunny", "text": "Cheers everyone up at camp.", "on": {"rest": 3}},
	"curious": {"name": "Curious", "text": "Loves a landmark.", "on": {"landmark": 4}},
	"loyal": {"name": "Loyal", "text": "Proud to walk beside the wagon.", "on": {"lead_day": 1}},
	"sore_loser": {"name": "Sore loser", "text": "Takes losses hard, wins harder.", "on": {"win": 1, "lose": -3}},
	"stormy": {"name": "Stormy", "text": "Hates getting wet.", "on": {"storm_day": -1, "rest": 1}},
}

## A trigger line for the journal, per moment ("%s" = names).
const LINES := {
	"win": "%s shows off after the win.",
	"lose": "%s sulks after the loss.",
	"rest": "%s keeps the camp laughing.",
	"meal": "%s licks the pot clean.",
	"landmark": "%s can't stop staring.",
}


static func roll(rng: RandomNumberGenerator) -> String:
	var keys := KINDS.keys()
	keys.sort()
	return String(keys[rng.randi_range(0, keys.size() - 1)])


static func amount(kind: String, moment: String) -> int:
	return int(KINDS.get(kind, {}).get("on", {}).get(moment, 0))


static func line(kind: String) -> String:
	if not KINDS.has(kind):
		return ""
	return "%s: %s" % [KINDS[kind]["name"], KINDS[kind]["text"]]

class_name Temperaments
extends RefCounted
## Every Trailomon you catch has a temperament: a small lean in its stats, one up and one down
## (Calm has none). "spd" is the time between attacks, so below 1.0 means faster.

const KINDS := {
	"bold": {"name": "Bold", "text": "Hits harder, guards less.", "atk": 1.08, "def": 0.94},
	"fierce": {"name": "Fierce", "text": "Hits much harder, a little frailer.", "atk": 1.1, "hp": 0.94},
	"hardy": {"name": "Hardy", "text": "Tougher, hits softer.", "hp": 1.08, "atk": 0.95},
	"sturdy": {"name": "Sturdy", "text": "Guards better, a little slower.", "def": 1.1, "spd": 1.05},
	"quick": {"name": "Quick", "text": "Attacks faster, guards less.", "spd": 0.93, "def": 0.94},
	"restless": {"name": "Restless", "text": "Attacks faster, a little frailer.", "spd": 0.94, "hp": 0.95},
	"gentle": {"name": "Gentle", "text": "Tougher and steadier, hits softer.", "hp": 1.05, "def": 1.04, "atk": 0.93},
	"calm": {"name": "Calm", "text": "Even-tempered: no lean either way."},
}


static func roll(rng: RandomNumberGenerator) -> String:
	var keys := KINDS.keys()
	keys.sort()
	return String(keys[rng.randi_range(0, keys.size() - 1)])


## The multiplier a temperament puts on a stat ("hp", "atk", "def", "spd").
static func factor(kind: String, stat: String) -> float:
	return float(KINDS.get(kind, {}).get(stat, 1.0))


## "Bold: Hits harder, guards less." for cards.
static func line(kind: String) -> String:
	if not KINDS.has(kind):
		return ""
	return "%s: %s" % [KINDS[kind]["name"], KINDS[kind]["text"]]

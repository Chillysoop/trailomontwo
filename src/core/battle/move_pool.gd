class_name MovePool
extends RefCounted
## Moves Trailomon learn by levelling up, grouped into two archetypes per species
## (the habitat's archetype pair from docs/habitats.md). Each ability level-up offers one
## move from each archetype, so players can specialise or mix the two.
##
## These moves are data-driven: Battle runs them from the keys below, and their tooltip
## text is written from the same keys, so numbers and text can't drift apart.
##
## Basic attacks and ultimates:
##   pct        damage as % of Attack          def_pct   extra damage as % of Defense
##   hits       how many times it hits         splash    % of Attack to enemies adjacent to the target
##   pierce     ignores Defense
##   target     ultimates only: target, adjacent (target + adjacent), row, all, weakest, none
##   bonus      {"vs": condition, "amount": %} more damage when the condition holds
##   poison     [% of Attack per second, secs]   slow / weaken  [%, secs]
##   stagger    % knocked off the target's attack bar
##   wash       strip Shield equal to % of Attack before hitting
##   self       {"shield_atk", "shield_def", "heal_atk": %, "dodge": true}
##   ally       {"heal_atk", "shield_atk": %} for the most hurt ally
##   team       {"heal_maxhp": %, "shield_def": %, "shield_flat", "haste": [%, secs], "cleanse": true}
##   taunt      seconds
## Passives ("kind"):
##   bonus_vs     {"vs", "amount"}          thorns   {"pct", "while_shielded"}
##   drain        {"pct"}                   armor_low {"amount"} Defense below half health
##   start_shield {"def_pct"}               every    {"n", and one of: "shield_def",
##                                                    "ally_heal_atk", "extra_pct",
##                                                    "poison_all": [%, secs], "team_haste": [%, secs]}
## Conditions: slowed, poisoned, weakened, hurt (below half health), healthy (above 75%),
## shielded (the attacker has Shield).

## species -> two archetypes: {"name", "line", "moves": [basic, passive, ultimate]}
const ARCHETYPES := {
	"brambleback": [
		{"name": "Thornwarden", "line": "Punishes attackers with thorns.", "moves": ["thorn_rake", "bramble_coat", "thicket_burst"]},
		{"name": "Barkguard", "line": "Grows bark and shields its friends.", "moves": ["bark_bash", "heartwood", "great_oak"]},
	],
	"coilhusk": [
		{"name": "Barkguard", "line": "Turns its shell into a fortress.", "moves": ["coil_crush", "resin_shell", "coil_fortress"]},
		{"name": "Thornwarden", "line": "Grows spines that bite back.", "moves": ["spine_jab", "spined_coil", "spine_burst"]},
	],
	"reedwake": [
		{"name": "Mender", "line": "Keeps the whole team on its feet.", "moves": ["soothing_ripple", "wellspring", "spring_rain"]},
		{"name": "Riptide", "line": "Drains foes and washes away their shields.", "moves": ["drain_lance", "riptide_pull", "whirlpool"]},
	],
	"mirelamp": [
		{"name": "Plaguebearer", "line": "Spreads poison across the whole pack.", "moves": ["spore_spit", "spore_cloud", "plague_bloom"]},
		{"name": "Rotter", "line": "Rots armor so the team hits harder.", "moves": ["rot_glow", "decay_light", "lantern_rot"]},
	],
	"rimehare": [
		{"name": "Frostbinder", "line": "Freezes foes in place.", "moves": ["ice_kick", "frostbite", "whiteout"]},
		{"name": "Gale", "line": "Speeds up the whole team.", "moves": ["quick_hop", "tailwind", "gale_sprint"]},
	],
	"scythelk": [
		{"name": "Breaker", "line": "Finishes off the wounded.", "moves": ["reaping_cut", "deep_cut", "executioner"]},
		{"name": "Bulwark", "line": "Knocks foes off their rhythm.", "moves": ["antler_check", "granite_hide", "rockslide"]},
	],
	"gillhorn": [
		{"name": "Plaguebearer", "line": "Gores and poisons.", "moves": ["bog_gore", "stagnant", "swamp_surge"]},
		{"name": "Rotter", "line": "Rots armor, then crushes it.", "moves": ["rot_horn", "fester", "mire_crush"]},
	],
	"lianetail": [
		{"name": "Canopy", "line": "Strikes the second row from the treetops.", "moves": ["high_vine", "treetop", "vine_rain"]},
		{"name": "Skirmisher", "line": "Darts in, hits hard and dodges away.", "moves": ["dart_strike", "first_strike", "flurry_dash"]},
	],
	"inkhoot": [
		{"name": "Riptide", "line": "Strips shields and drains life.", "moves": ["soaking_ink", "ink_drain", "maelstrom"]},
		{"name": "Mender", "line": "Patches up the team between strikes.", "moves": ["healing_ink", "ink_salve", "tidal_mend"]},
	],
}

## Species without their own archetypes learn from their habitat's pair.
const HABITAT_ARCHETYPES := {"Forest": "brambleback", "River": "reedwake", "Swamp": "mirelamp",
	"Mountain": "scythelk", "Snow": "rimehare", "Jungle": "lianetail"}

const MOVES := {
	# ----- Brambleback -----
	"thorn_rake": {"name": "Thorn Rake", "slot": "basic", "pct": 60, "def_pct": 30, "splash": 30},
	"bramble_coat": {"name": "Bramble Coat", "slot": "passive", "kind": "thorns", "pct": 60},
	"thicket_burst": {"name": "Thicket Burst", "slot": "ultimate", "target": "adjacent", "pct": 140, "self": {"shield_def": 120}, "taunt": 4.0},
	"bark_bash": {"name": "Bark Bash", "slot": "basic", "pct": 70, "self": {"shield_def": 35}},
	"heartwood": {"name": "Heartwood", "slot": "passive", "kind": "start_shield", "def_pct": 250},
	"great_oak": {"name": "Great Oak", "slot": "ultimate", "target": "none", "team": {"shield_def": 80, "shield_flat": 40}, "taunt": 5.0},
	# ----- Coilhusk -----
	"coil_crush": {"name": "Coil Crush", "slot": "basic", "pct": 80, "self": {"shield_atk": 40}},
	"resin_shell": {"name": "Resin Shell", "slot": "passive", "kind": "every", "n": 2, "shield_def": 70},
	"coil_fortress": {"name": "Coil Fortress", "slot": "ultimate", "target": "none", "self": {"shield_def": 300}, "taunt": 4.0},
	"spine_jab": {"name": "Spine Jab", "slot": "basic", "pct": 85, "splash": 25},
	"spined_coil": {"name": "Spined Coil", "slot": "passive", "kind": "thorns", "pct": 30},
	"spine_burst": {"name": "Spine Burst", "slot": "ultimate", "target": "adjacent", "pct": 150},
	# ----- Reedwake -----
	"soothing_ripple": {"name": "Soothing Ripple", "slot": "basic", "pct": 50, "ally": {"heal_atk": 85}},
	"wellspring": {"name": "Wellspring", "slot": "passive", "kind": "every", "n": 3, "ally_heal_atk": 90},
	"spring_rain": {"name": "Spring Rain", "slot": "ultimate", "target": "none", "team": {"heal_maxhp": 10, "cleanse": true}},
	"drain_lance": {"name": "Drain Lance", "slot": "basic", "pct": 120, "ally": {"heal_atk": 45}},
	"riptide_pull": {"name": "Riptide Pull", "slot": "passive", "kind": "drain", "pct": 50, "to_ally": true},
	"whirlpool": {"name": "Whirlpool", "slot": "ultimate", "target": "all", "pct": 90, "wash": 60},
	# ----- Mirelamp -----
	"spore_spit": {"name": "Spore Spit", "slot": "basic", "pct": 60, "poison": [20, 5.0]},
	"spore_cloud": {"name": "Spore Cloud", "slot": "passive", "kind": "every", "n": 3, "poison_all": [8, 3.0]},
	"plague_bloom": {"name": "Plague Bloom", "slot": "ultimate", "target": "all", "pct": 30, "poison": [22, 6.0]},
	"rot_glow": {"name": "Rot Glow", "slot": "basic", "pct": 75, "weaken": [25, 4.0]},
	"decay_light": {"name": "Decay Light", "slot": "passive", "kind": "bonus_vs", "vs": "weakened", "amount": 30},
	"lantern_rot": {"name": "Lantern Rot", "slot": "ultimate", "target": "all", "pct": 60, "weaken": [30, 5.0]},
	# ----- Rimehare -----
	"ice_kick": {"name": "Ice Kick", "slot": "basic", "pct": 75, "slow": [35, 3.0]},
	"frostbite": {"name": "Frostbite", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 30},
	"whiteout": {"name": "Whiteout", "slot": "ultimate", "target": "all", "pct": 70, "slow": [40, 4.0]},
	"quick_hop": {"name": "Quick Hop", "slot": "basic", "pct": 45, "hits": 2},
	"tailwind": {"name": "Tailwind", "slot": "passive", "kind": "every", "n": 3, "team_haste": [15, 3.0]},
	"gale_sprint": {"name": "Gale Sprint", "slot": "ultimate", "target": "none", "team": {"haste": [50, 4.0]}},
	# ----- Scythelk -----
	"reaping_cut": {"name": "Reaping Cut", "slot": "basic", "pct": 90, "bonus": {"vs": "hurt", "amount": 70}},
	"deep_cut": {"name": "Deep Cut", "slot": "passive", "kind": "bonus_vs", "vs": "hurt", "amount": 35},
	"executioner": {"name": "Executioner", "slot": "ultimate", "target": "weakest", "pct": 200, "pierce": true},
	"antler_check": {"name": "Antler Check", "slot": "basic", "pct": 80, "stagger": 35},
	"granite_hide": {"name": "Granite Hide", "slot": "passive", "kind": "armor_low", "amount": 30},
	"rockslide": {"name": "Rockslide", "slot": "ultimate", "target": "row", "pct": 125, "stagger": 50},
	# ----- Gillhorn -----
	"bog_gore": {"name": "Bog Gore", "slot": "basic", "pct": 80, "poison": [15, 4.0]},
	"stagnant": {"name": "Stagnant", "slot": "passive", "kind": "bonus_vs", "vs": "poisoned", "amount": 35},
	"swamp_surge": {"name": "Swamp Surge", "slot": "ultimate", "target": "adjacent", "pct": 110, "poison": [18, 4.0]},
	"rot_horn": {"name": "Rot Horn", "slot": "basic", "pct": 90, "weaken": [25, 3.0]},
	"fester": {"name": "Fester", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 70},
	"mire_crush": {"name": "Mire Crush", "slot": "ultimate", "target": "target", "pct": 210, "weaken": [30, 5.0]},
	# ----- Inkhoot -----
	"soaking_ink": {"name": "Soaking Ink", "slot": "basic", "pct": 80, "wash": 100},
	"ink_drain": {"name": "Ink Drain", "slot": "passive", "kind": "drain", "pct": 35},
	"maelstrom": {"name": "Maelstrom", "slot": "ultimate", "target": "all", "pct": 70, "wash": 80},
	"healing_ink": {"name": "Healing Ink", "slot": "basic", "pct": 60, "ally": {"heal_atk": 60}},
	"ink_salve": {"name": "Ink Salve", "slot": "passive", "kind": "every", "n": 3, "ally_heal_atk": 80},
	"tidal_mend": {"name": "Tidal Mend", "slot": "ultimate", "target": "none", "team": {"heal_maxhp": 12, "cleanse": true}},
	# ----- Jungle archetypes (Canopy / Skirmisher) -----
	"high_vine": {"name": "High Vine", "slot": "basic", "pct": 75, "reach": true},
	"treetop": {"name": "Treetop", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 50},
	"vine_rain": {"name": "Vine Rain", "slot": "ultimate", "target": "all", "pct": 90},
	"dart_strike": {"name": "Dart Strike", "slot": "basic", "pct": 85, "self": {"dodge": true}},
	"first_strike": {"name": "First Strike", "slot": "passive", "kind": "bonus_vs", "vs": "healthy", "amount": 25},
	"flurry_dash": {"name": "Flurry Dash", "slot": "ultimate", "target": "weakest", "pct": 210, "self": {"dodge": true}},
	# ----- Kits of the species added with varied crossings -----
	"moss_burrow": {"name": "Moss Burrow", "slot": "basic", "pct": 70, "self": {"shield_def": 40}},
	"mossy_hide": {"name": "Mossy Hide", "slot": "passive", "kind": "thorns", "pct": 30},
	"dig_in": {"name": "Dig In", "slot": "ultimate", "target": "none", "self": {"shield_def": 220}, "taunt": 3.0},
	"burl_maul": {"name": "Burl Maul", "slot": "basic", "pct": 100, "bonus": {"vs": "shielded", "amount": 25}},
	"burl_bark": {"name": "Burl Bark", "slot": "passive", "kind": "every", "n": 3, "shield_def": 90},
	"timber_crash": {"name": "Timber Crash", "slot": "ultimate", "target": "adjacent", "pct": 150, "self": {"shield_def": 60}},
	"pebble_toss": {"name": "Pebble Toss", "slot": "basic", "pct": 60, "ally": {"heal_atk": 50}},
	"otter_care": {"name": "Otter Care", "slot": "passive", "kind": "drain", "pct": 20, "to_ally": true},
	"brook_song": {"name": "Brook Song", "slot": "ultimate", "target": "none", "team": {"heal_maxhp": 12, "cleanse": true}},
	"glow_sting": {"name": "Glow Sting", "slot": "basic", "pct": 80, "wash": 50},
	"deep_glow": {"name": "Deep Glow", "slot": "passive", "kind": "drain", "pct": 30},
	"lantern_dive": {"name": "Lantern Dive", "slot": "ultimate", "target": "weakest", "pct": 200, "wash": 100},
	"spore_puff": {"name": "Spore Puff", "slot": "basic", "pct": 60, "poison": [15, 4]},
	"toxic_skin": {"name": "Toxic Skin", "slot": "passive", "kind": "bonus_vs", "vs": "poisoned", "amount": 20},
	"spore_storm": {"name": "Spore Storm", "slot": "ultimate", "target": "all", "poison": [20, 5]},
	"bog_bite": {"name": "Bog Bite", "slot": "basic", "pct": 95, "weaken": [15, 3]},
	"murk_jaws": {"name": "Murk Jaws", "slot": "passive", "kind": "bonus_vs", "vs": "weakened", "amount": 25},
	"death_roll": {"name": "Death Roll", "slot": "ultimate", "pct": 200, "poison": [30, 4], "weaken": [25, 4]},
	"slate_peck": {"name": "Slate Peck", "slot": "basic", "pct": 90, "bonus": {"vs": "hurt", "amount": 40}},
	"carrion_eye": {"name": "Carrion Eye", "slot": "passive", "kind": "bonus_vs", "vs": "hurt", "amount": 20},
	"rock_dive": {"name": "Rock Dive", "slot": "ultimate", "target": "weakest", "pct": 180, "pierce": true},
	"tusk_shove": {"name": "Tusk Shove", "slot": "basic", "pct": 80, "stagger": 25},
	"quarry_hide": {"name": "Quarry Hide", "slot": "passive", "kind": "armor_low", "amount": 25},
	"quarry_quake": {"name": "Quarry Quake", "slot": "ultimate", "target": "row", "pct": 120, "stagger": 40},
	"snow_nip": {"name": "Snow Nip", "slot": "basic", "pct": 75, "slow": [20, 2]},
	"pack_flurry": {"name": "Pack Flurry", "slot": "passive", "kind": "every", "n": 3, "team_haste": [20, 3]},
	"blizzard_howl": {"name": "Blizzard Howl", "slot": "ultimate", "target": "none", "team": {"haste": [30, 5]}},
	"frost_wing": {"name": "Frost Wing", "slot": "basic", "pct": 50, "hits": 2, "slow": [15, 2]},
	"cold_edge": {"name": "Cold Edge", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 25},
	"rime_dive": {"name": "Rime Dive", "slot": "ultimate", "target": "adjacent", "pct": 120, "slow": [40, 4]},
	"vine_flick": {"name": "Vine Flick", "slot": "basic", "pct": 80, "reach": true},
	"sticky_feet": {"name": "Sticky Feet", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 40},
	"canopy_drop": {"name": "Canopy Drop", "slot": "ultimate", "target": "weakest", "pct": 170},
	"leaf_pounce": {"name": "Leaf Pounce", "slot": "basic", "pct": 90, "self": {"dodge": true}},
	"dapple": {"name": "Dapple", "slot": "passive", "kind": "every", "n": 2, "extra_pct": 35},
	"canopy_strike": {"name": "Canopy Strike", "slot": "ultimate", "target": "weakest", "pct": 230},
	"ember_bough": {"name": "Ember Bough", "slot": "basic", "pct": 80, "def_pct": 40, "self": {"shield_def": 30}},
	"ember_bark": {"name": "Ember Bark", "slot": "passive", "kind": "thorns", "pct": 35},
	"heartfire": {"name": "Heartfire", "slot": "ultimate", "target": "none", "team": {"shield_def": 70, "shield_flat": 40}, "taunt": 4.0},
	"tide_lash": {"name": "Tide Lash", "slot": "basic", "pct": 85, "ally": {"heal_atk": 30}},
	"tidal_heart": {"name": "Tidal Heart", "slot": "passive", "kind": "drain", "pct": 12, "to_ally": true},
	"great_wave": {"name": "Great Wave", "slot": "ultimate", "target": "all", "pct": 80, "team": {"heal_maxhp": 5}},
	"aurora_horn": {"name": "Aurora Horn", "slot": "basic", "pct": 45, "hits": 2, "slow": [15, 2]},
	"aurora_mane": {"name": "Aurora Mane", "slot": "passive", "kind": "every", "n": 4, "team_haste": [20, 3]},
	"polar_light": {"name": "Polar Light", "slot": "ultimate", "target": "all", "pct": 80, "slow": [30, 3]},
	# ----- Batch 2 kits -----
	"acorn_pelt": {"name": "Acorn Pelt", "slot": "basic", "pct": 80, "self": {"shield_atk": 20}},
	"nutshell": {"name": "Nutshell", "slot": "passive", "kind": "thorns", "pct": 35, "while_shielded": true},
	"nut_barrage": {"name": "Nut Barrage", "slot": "ultimate", "target": "adjacent", "pct": 110, "self": {"shield_atk": 60}},
	"wisp_splash": {"name": "Wisp Splash", "slot": "basic", "pct": 55, "ally": {"heal_atk": 55}},
	"glimmer": {"name": "Glimmer", "slot": "passive", "kind": "every", "n": 3, "ally_heal_atk": 60},
	"spring_glow": {"name": "Spring Glow", "slot": "ultimate", "target": "none", "team": {"heal_maxhp": 10, "cleanse": true}},
	"dust_wing": {"name": "Dust Wing", "slot": "basic", "pct": 60, "poison": [12, 4], "reach": true},
	"murk_scales": {"name": "Murk Scales", "slot": "passive", "kind": "bonus_vs", "vs": "poisoned", "amount": 15},
	"moth_swarm": {"name": "Moth Swarm", "slot": "ultimate", "target": "row", "poison": [20, 4], "weaken": [15, 3]},
	"crag_butt": {"name": "Crag Butt", "slot": "basic", "pct": 90, "stagger": 20},
	"sure_footed": {"name": "Sure-footed", "slot": "passive", "kind": "armor_low", "amount": 15},
	"rockfall": {"name": "Rockfall", "slot": "ultimate", "pct": 190, "pierce": true},
	"sleet_nibble": {"name": "Sleet Nibble", "slot": "basic", "pct": 45, "hits": 2, "slow": [15, 2]},
	"cold_whiskers": {"name": "Cold Whiskers", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 20},
	"snow_scurry": {"name": "Snow Scurry", "slot": "ultimate", "target": "weakest", "pct": 160, "slow": [30, 3]},
	"keet_peck": {"name": "Keet Peck", "slot": "basic", "pct": 70, "reach": true},
	"chatter": {"name": "Chatter", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 35},
	"flock_call": {"name": "Flock Call", "slot": "ultimate", "target": "row", "pct": 100, "self": {"dodge": true}},
	"horn_flip": {"name": "Horn Flip", "slot": "basic", "pct": 75, "self": {"shield_def": 30}},
	"hard_shell": {"name": "Hard Shell", "slot": "passive", "kind": "start_shield", "def_pct": 200},
	"carapace": {"name": "Carapace", "slot": "ultimate", "target": "none", "self": {"shield_def": 180}, "team": {"shield_def": 30}, "taunt": 4.0},
	"kelp_snap": {"name": "Kelp Snap", "slot": "basic", "pct": 75, "self": {"heal_atk": 30}},
	"kelp_drink": {"name": "Kelp Drink", "slot": "passive", "kind": "drain", "pct": 25},
	"tide_shelter": {"name": "Tide Shelter", "slot": "ultimate", "target": "none", "team": {"heal_maxhp": 14, "cleanse": true}, "taunt": 4.0},
	"leech_bite": {"name": "Leech Bite", "slot": "basic", "pct": 85, "poison": [15, 3]},
	"gloom_feed": {"name": "Gloom Feed", "slot": "passive", "kind": "bonus_vs", "vs": "poisoned", "amount": 25},
	"bloodrot": {"name": "Bloodrot", "slot": "ultimate", "target": "weakest", "pct": 180, "poison": [30, 4], "weaken": [20, 4]},
	"basalt_slam": {"name": "Basalt Slam", "slot": "basic", "pct": 80, "stagger": 30},
	"cooled_rock": {"name": "Cooled Rock", "slot": "passive", "kind": "armor_low", "amount": 30},
	"magma_crack": {"name": "Magma Crack", "slot": "ultimate", "target": "row", "pct": 130, "pierce": true},
	"frost_maul": {"name": "Frost Maul", "slot": "basic", "pct": 95, "slow": [20, 3]},
	"ice_pride": {"name": "Ice Pride", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 25},
	"white_roar": {"name": "White Roar", "slot": "ultimate", "target": "all", "pct": 90, "slow": [30, 3]},
	"tongue_lash": {"name": "Tongue Lash", "slot": "basic", "pct": 85, "reach": true},
	"quick_tongue": {"name": "Quick Tongue", "slot": "passive", "kind": "every", "n": 2, "extra_pct": 30},
	"ambush_leap": {"name": "Ambush Leap", "slot": "ultimate", "target": "weakest", "pct": 220, "self": {"dodge": true}},
	"triple_bite": {"name": "Triple Bite", "slot": "basic", "pct": 45, "hits": 3, "poison": [15, 4], "weaken": [10, 3]},
	"many_heads": {"name": "Many Heads", "slot": "passive", "kind": "every", "n": 3, "poison_all": [12, 4]},
	"hydra_rot": {"name": "Hydra Rot", "slot": "ultimate", "target": "all", "pct": 85, "poison": [22, 5], "weaken": [20, 4]},
	"titan_horn": {"name": "Titan Horn", "slot": "basic", "pct": 85, "stagger": 25, "splash": 30},
	"titan_hide": {"name": "Titan Hide", "slot": "passive", "kind": "armor_low", "amount": 30},
	"earthsplitter": {"name": "Earthsplitter", "slot": "ultimate", "target": "row", "pct": 150, "pierce": true, "stagger": 40},
	"plume_strike": {"name": "Plume Strike", "slot": "basic", "pct": 80, "reach": true, "self": {"dodge": true}},
	"sun_plumes": {"name": "Sun Plumes", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 60},
	"sky_dive": {"name": "Sky Dive", "slot": "ultimate", "target": "all", "pct": 95},
	# ----- Guardians -----
	"brood_spit": {"name": "Brood Spit", "slot": "basic", "pct": 95, "poison": [18, 4], "splash": 40},
	"mother_brood": {"name": "Mother's Brood", "slot": "passive", "kind": "every", "n": 3, "poison_all": [15, 4]},
	"fen_flood": {"name": "Fen Flood", "slot": "ultimate", "target": "all", "pct": 95, "poison": [28, 5]},
	"gear_tusk": {"name": "Gear Tusk", "slot": "basic", "pct": 100, "stagger": 15, "splash": 25},
	"iron_hide": {"name": "Iron Hide", "slot": "passive", "kind": "armor_low", "amount": 20},
	"piston_stomp": {"name": "Piston Stomp", "slot": "ultimate", "target": "row", "pct": 110, "pierce": true, "stagger": 30},
	"rime_fang": {"name": "Rime Fang", "slot": "basic", "pct": 50, "hits": 2, "slow": [20, 2]},
	"frozen_heart": {"name": "Frozen Heart", "slot": "passive", "kind": "bonus_vs", "vs": "slowed", "amount": 20},
	"glacier_breath": {"name": "Glacier Breath", "slot": "ultimate", "target": "all", "pct": 75, "slow": [35, 3]},
}

const COND_TEXT := {"slowed": "{k:slow|slowed} enemies", "poisoned": "{k:poison|poisoned} enemies",
	"weakened": "{k:weaken|weakened} enemies", "hurt": "enemies below half health",
	"healthy": "enemies above 75% health", "shielded": "while you have {k:shield|Shield}"}
const COND_SHORT := {"slowed": "slowed foes", "poisoned": "poisoned foes", "weakened": "weakened foes",
	"hurt": "foes below half health", "healthy": "healthy foes", "shielded": "while shielded"}
const TARGET_TEXT := {"target": "your target", "adjacent": "your target and enemies {k:adjacent} to it",
	"row": "every enemy in your target's row", "all": "every enemy", "weakest": "the weakest enemy anywhere"}
const TARGET_SHORT := {"target": "target", "adjacent": "target + adjacent", "row": "target's row",
	"all": "all foes", "weakest": "weakest foe"}


static func has(id: String) -> bool:
	return MOVES.has(id)


## The archetype (0 or 1) a learnable move belongs to for a species, or -1.
## The species whose archetypes hold this move ("" if none).
## A species' two archetypes: its own, or its habitat's pair.
static func archetypes(species: String) -> Array:
	if ARCHETYPES.has(species):
		return ARCHETYPES[species]
	if not Species.DATA.has(species) or Species.is_boss(species):
		return []
	return ARCHETYPES.get(HABITAT_ARCHETYPES.get(Species.info(species)["type"], ""), [])


## Moves that can turn up as technique scrolls: every archetype move.
static func technique_ids() -> Array:
	var out: Array = []
	for species in ARCHETYPES:
		for arc in ARCHETYPES[species]:
			for mid in arc["moves"]:
				if not out.has(mid):
					out.append(mid)
	return out


static func owner_of(move_id: String) -> String:
	for species in ARCHETYPES:
		for arc in ARCHETYPES[species]:
			if arc["moves"].has(move_id):
				return species
	return ""


static func archetype_of(species: String, move_id: String) -> int:
	var arcs: Array = archetypes(species)
	for i in arcs.size():
		if arcs[i]["moves"].has(move_id):
			return i
	return -1


## Full tooltip text in Rich markup with {atk:N}-style number tokens.
static func desc(id: String) -> String:
	var m: Dictionary = MOVES[id]
	if m["slot"] == "passive":
		return _passive_text(m, false)
	return _active_text(m, false)


## One-line summary with number tokens.
static func short(id: String) -> String:
	var m: Dictionary = MOVES[id]
	if m["slot"] == "passive":
		return _passive_text(m, true)
	return _active_text(m, true)


static func _active_text(m: Dictionary, brief: bool) -> String:
	var parts: Array[String] = []
	var target: String = m.get("target", "target")
	if m.has("wash"):
		parts.append("strips {atk:%d} Shield" % m["wash"] if brief else "{k:wash|Wash away} up to {atk:%d} of {k:shield|Shield}" % m["wash"])
	if m.has("pct") and target != "none":
		var amount := "{atk:%d}" % m["pct"]
		if m.has("def_pct"):
			amount += " + {def:%d}" % m["def_pct"]
		var times := " twice" if int(m.get("hits", 1)) == 2 else ""
		if brief:
			parts.append(("hits %s%s" % [amount, times]) if target == "target" else "%s to %s" % [amount, TARGET_SHORT[target]])
		else:
			parts.append("deal %s%s to %s" % [amount, times, TARGET_TEXT[target]])
		if m.has("pierce"):
			parts.append("ignores Defense" if brief else "it {k:pierce}")
	if m.has("splash"):
		parts.append("{atk:%d} to adjacent" % m["splash"] if brief else "{atk:%d} to enemies {k:adjacent} to the target" % m["splash"])
	if m.has("bonus"):
		var b: Dictionary = m["bonus"]
		parts.append("+%d%% vs %s" % [b["amount"], COND_SHORT[b["vs"]]] if brief else "%d%% more against %s" % [b["amount"], COND_TEXT[b["vs"]]])
	if m.has("poison"):
		parts.append("poison {atk:%d}/s %ds" % [m["poison"][0], m["poison"][1]] if brief else "{k:poison} for {atk:%d} a second for %ds" % [m["poison"][0], m["poison"][1]])
	if m.has("slow"):
		parts.append("slow %d%% %ds" % [m["slow"][0], m["slow"][1]] if brief else "{k:slow} by %d%% for %ds" % [m["slow"][0], m["slow"][1]])
	if m.has("weaken"):
		parts.append("-%d%% Defense %ds" % [m["weaken"][0], m["weaken"][1]] if brief else "{k:weaken}: %d%% less Defense for %ds" % [m["weaken"][0], m["weaken"][1]])
	if m.has("stagger"):
		parts.append("attack bar -%d%%" % m["stagger"] if brief else "{k:stagger}: attack bar drops by %d%%" % m["stagger"])
	var s: Dictionary = m.get("self", {})
	if s.has("shield_atk"):
		parts.append("shield self {atk:%d}" % s["shield_atk"] if brief else "gain {k:shield|Shield} equal to {atk:%d}" % s["shield_atk"])
	if s.has("shield_def"):
		parts.append("shield self {def:%d}" % s["shield_def"] if brief else "gain {k:shield|Shield} equal to {def:%d}" % s["shield_def"])
	if s.has("heal_atk"):
		parts.append("heal self {atk:%d}" % s["heal_atk"] if brief else "heal yourself for {atk:%d}" % s["heal_atk"])
	var a: Dictionary = m.get("ally", {})
	if a.has("heal_atk"):
		parts.append("heal most hurt ally {atk:%d}" % a["heal_atk"] if brief else "heal the most hurt ally for {atk:%d}" % a["heal_atk"])
	var t: Dictionary = m.get("team", {})
	if t.has("heal_maxhp"):
		parts.append("heal all allies %d%% max HP" % t["heal_maxhp"] if brief else "heal every ally for %d%% of their Max HP" % t["heal_maxhp"])
	if t.has("cleanse"):
		parts.append("cleanse" if brief else "wash off their {k:poison} and {k:weaken}")
	if t.has("shield_def"):
		parts.append("shield all allies {def:%d}+%d" % [t["shield_def"], t.get("shield_flat", 0)] if brief else "give every ally {k:shield|Shield} equal to {def:%d} plus %d" % [t["shield_def"], t.get("shield_flat", 0)])
	if t.has("haste"):
		parts.append("all allies +%d%% speed %ds" % [t["haste"][0], t["haste"][1]] if brief else "every ally gains {k:haste}: attacks %d%% faster for %ds" % [t["haste"][0], t["haste"][1]])
	if m.has("taunt"):
		parts.append("taunt %ds" % m["taunt"] if brief else "{k:taunt} enemies for %ds" % m["taunt"])
	var text := ", ".join(parts)
	text = text.substr(0, 1).to_upper() + text.substr(1)
	return text if brief else text + "."


static func _passive_text(m: Dictionary, brief: bool) -> String:
	match m["kind"]:
		"bonus_vs":
			return ("+%d%% damage vs %s" % [m["amount"], COND_SHORT[m["vs"]]]) if brief else "Deal %d%% more damage to %s." % [m["amount"], COND_TEXT[m["vs"]]]
		"thorns":
			var cond := bool(m.get("while_shielded", false))
			if brief:
				return ("While shielded: " if cond else "Hit by a basic: ") + "hits back for {atk:%d}" % m["pct"]
			if cond:
				return "While you have {k:shield|Shield}, a basic attack that hits you deals {atk:%d} back to the attacker." % m["pct"]
			return "When a basic attack hits you, deal {atk:%d} back to the attacker." % m["pct"]
		"drain":
			if m.get("to_ally", false):
				return ("Heals most hurt ally %d%% of damage dealt" % m["pct"]) if brief else "Heal your most hurt ally for %d%% of the damage you deal." % m["pct"]
			return ("Heals self for %d%% of damage dealt" % m["pct"]) if brief else "Heal yourself for %d%% of the damage you deal." % m["pct"]
		"armor_low":
			return ("Below half health: +%d Defense" % m["amount"]) if brief else "Below half health, gain %d Defense." % m["amount"]
		"start_shield":
			return ("Starts each fight with {def:%d} Shield" % m["def_pct"]) if brief else "Start every fight with {k:shield|Shield} equal to {def:%d}." % m["def_pct"]
		"every":
			var n := int(m["n"])
			var what := ""
			if m.has("shield_def"):
				what = ("shield self {def:%d}" if brief else "gain {k:shield|Shield} equal to {def:%d}") % m["shield_def"]
			elif m.has("ally_heal_atk"):
				what = ("heal most hurt ally {atk:%d}" if brief else "heal the most hurt ally for {atk:%d}") % m["ally_heal_atk"]
			elif m.has("extra_pct"):
				what = ("extra hit for {atk:%d}" if brief else "hit the target again for {atk:%d}") % m["extra_pct"]
			elif m.has("poison_all"):
				what = ("poison all foes {atk:%d}/s %ds" if brief else "{k:poison} every enemy for {atk:%d} a second for %ds") % m["poison_all"]
			elif m.has("team_haste"):
				what = ("all allies +%d%% speed %ds" if brief else "every ally gains {k:haste}: %d%% faster for %ds") % m["team_haste"]
			var nth: String = {2: "2nd", 3: "3rd"}.get(n, "%dth" % n)
			return ("Every %s attack: %s" % [nth, what]) if brief else "Every %s basic attack, %s." % [nth, what]
	return ""

extends RefCounted
## Forest Trailomon.
##
## Roster data file, merged by Roster into Species.DATA, CombatData.KITS and MovePool.MOVES.
## SPECIES uses Species' keys (plus evolves_to / evolve_level for evolution lines), KITS uses
## CombatData's and MOVES uses MovePool's data-driven move keys.

const SPECIES := {
	"mossmole": {"rarity": "common", "name": "Mossmole", "type": "Forest", "size": "small", "hauling": 0, "evolves_to": "mossbrock",
		"capabilities": {"clear": 2, "forage": 2}},
	"burlbear": {"rarity": "rare", "name": "Burlbear", "type": "Forest", "size": "large", "hauling": 140,
		"capabilities": {"strength": 3, "guard": 2}},
	"emberoak": {"rarity": "legendary", "name": "Emberoak", "type": "Forest", "size": "large", "hauling": 180,
		"capabilities": {"strength": 3, "guard": 3, "light": 2}},
	"acornet": {"rarity": "common", "name": "Acornet", "type": "Forest", "size": "small", "hauling": 0, "evolves_to": "hazelhorn",
		"capabilities": {"forage": 3, "scout": 1}},
	"barkbeetle": {"rarity": "rare", "name": "Barkbeetle", "type": "Forest", "size": "medium", "hauling": 60,
		"capabilities": {"guard": 3, "strength": 1}},
	# ----- Milestone 1 -----
	"mossbrock": {"rarity": "common", "name": "Mossbrock", "type": "Forest", "size": "medium", "hauling": 60, "evolves_to": "sodursa",
		"capabilities": {"clear": 3, "strength": 1}},
	"sodursa": {"rarity": "rare", "name": "Sodursa", "type": "Forest", "size": "large", "hauling": 150,
		"capabilities": {"strength": 3, "clear": 2}},
	"hazelhorn": {"rarity": "common", "name": "Hazelhorn", "type": "Forest", "size": "small", "hauling": 0,
		"capabilities": {"forage": 3, "scout": 2}},
	"briarwolf": {"rarity": "rare", "name": "Briarwolf", "type": "Forest", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "guard": 2}},
	"fawnmoth": {"rarity": "common", "name": "Fawnmoth", "type": "Forest", "size": "small", "hauling": 0, "evolves_to": "stagmoth",
		"capabilities": {"scout": 2, "light": 1, "forage": 1}},
	"stagmoth": {"rarity": "common", "name": "Stagmoth", "type": "Forest", "size": "medium", "hauling": 0, "evolves_to": "lunastag",
		"capabilities": {"scout": 2, "light": 2}},
	"lunastag": {"rarity": "rare", "name": "Lunastag", "type": "Forest", "size": "large", "hauling": 80,
		"capabilities": {"light": 3, "scout": 2, "guard": 1}},
	"burrhog": {"rarity": "common", "name": "Burrhog", "type": "Forest", "size": "medium", "hauling": 70, "evolves_to": "thornboar",
		"capabilities": {"strength": 2, "guard": 2}},
	"thornboar": {"rarity": "rare", "name": "Thornboar", "type": "Forest", "size": "large", "hauling": 130,
		"capabilities": {"strength": 3, "guard": 2}},
	"peckscale": {"rarity": "common", "name": "Peckscale", "type": "Forest", "size": "small", "hauling": 0, "evolves_to": "drumscale",
		"capabilities": {"clear": 2, "scout": 2}},
	"drumscale": {"rarity": "common", "name": "Drumscale", "type": "Forest", "size": "medium", "hauling": 0,
		"capabilities": {"clear": 3, "scout": 2}},
	"snailback": {"rarity": "common", "name": "Snailback", "type": "Forest", "size": "medium", "hauling": 50, "evolves_to": "domeshell",
		"capabilities": {"steady": 3, "guard": 1}},
	"domeshell": {"rarity": "rare", "name": "Domeshell", "type": "Forest", "size": "large", "hauling": 120,
		"capabilities": {"steady": 3, "guard": 2, "strength": 1}},
	"grovemoose": {"rarity": "legendary", "name": "Grovemoose", "type": "Forest", "size": "large", "hauling": 190,
		"capabilities": {"strength": 3, "guard": 3, "clear": 2}},
	"briarlynx": {"rarity": "legendary", "name": "Briarlynx", "type": "Forest", "size": "medium", "hauling": 0,
		"capabilities": {"scout": 3, "guard": 2}},
}

const KITS := {
	"mossmole": {"role": "Guard", "hp": 400, "atk": 22, "def": 36, "spd": 2.1,
		"basic": "moss_burrow", "passive": "mossy_hide", "ultimate": "dig_in"},
	"burlbear": {"role": "Bruiser", "hp": 500, "atk": 33, "def": 32, "spd": 2.2,
		"basic": "burl_maul", "passive": "burl_bark", "ultimate": "timber_crash"},
	"emberoak": {"role": "Guard", "hp": 620, "atk": 32, "def": 52, "spd": 2.2,
		"basic": "ember_bough", "passive": "ember_bark", "ultimate": "heartfire"},
	"acornet": {"role": "Striker", "hp": 250, "atk": 27, "def": 14, "spd": 1.6,
		"basic": "acorn_pelt", "passive": "nutshell", "ultimate": "nut_barrage"},
	"barkbeetle": {"role": "Guard", "hp": 420, "atk": 24, "def": 44, "spd": 2.2,
		"basic": "horn_flip", "passive": "hard_shell", "ultimate": "carapace"},
	# ----- Milestone 1 -----
	"mossbrock": {"role": "Guard", "hp": 440, "atk": 25, "def": 40, "spd": 2.1,
		"basic": "sod_shove", "passive": "badger_hide", "ultimate": "deep_burrow"},
	"sodursa": {"role": "Guard", "hp": 520, "atk": 30, "def": 48, "spd": 2.2,
		"basic": "turf_maul", "passive": "sod_armor", "ultimate": "earthen_den"},
	"hazelhorn": {"role": "Striker", "hp": 290, "atk": 31, "def": 16, "spd": 1.6,
		"basic": "hazel_jab", "passive": "husk_spines", "ultimate": "nut_gore"},
	"briarwolf": {"role": "Striker", "hp": 360, "atk": 35, "def": 20, "spd": 1.7,
		"basic": "briar_bite", "passive": "quill_coat", "ultimate": "bramble_howl"},
	"fawnmoth": {"role": "Support", "hp": 270, "atk": 24, "def": 14, "spd": 1.7,
		"basic": "dust_fan", "passive": "soft_wings", "ultimate": "canopy_veil"},
	"stagmoth": {"role": "Support", "hp": 330, "atk": 27, "def": 20, "spd": 1.8,
		"basic": "antler_dust", "passive": "moth_bark", "ultimate": "grove_veil"},
	"lunastag": {"role": "Support", "hp": 430, "atk": 31, "def": 28, "spd": 1.9,
		"basic": "moonlit_antler", "passive": "luna_wings", "ultimate": "silver_grove"},
	"burrhog": {"role": "Guard", "hp": 400, "atk": 24, "def": 36, "spd": 2.2,
		"basic": "burr_charge", "passive": "burr_quills", "ultimate": "quill_ball"},
	"thornboar": {"role": "Guard", "hp": 520, "atk": 29, "def": 44, "spd": 2.2,
		"basic": "thorn_tusk", "passive": "spined_back", "ultimate": "briar_stampede"},
	"peckscale": {"role": "Striker", "hp": 250, "atk": 29, "def": 12, "spd": 1.5,
		"basic": "bark_peck", "passive": "drum_rhythm", "ultimate": "hollow_drum"},
	"drumscale": {"role": "Striker", "hp": 300, "atk": 33, "def": 16, "spd": 1.5,
		"basic": "drum_peck", "passive": "tree_drummer", "ultimate": "timber_roll"},
	"snailback": {"role": "Guard", "hp": 420, "atk": 21, "def": 42, "spd": 2.4,
		"basic": "shell_bump", "passive": "coiled_shell", "ultimate": "slow_fortress"},
	"domeshell": {"role": "Guard", "hp": 540, "atk": 25, "def": 52, "spd": 2.4,
		"basic": "dome_slam", "passive": "living_dome", "ultimate": "moss_bastion"},
	"grovemoose": {"role": "Guard", "hp": 600, "atk": 32, "def": 52, "spd": 2.2,
		"basic": "elder_antler", "passive": "old_growth", "ultimate": "forest_crown"},
	"briarlynx": {"role": "Striker", "hp": 410, "atk": 38, "def": 26, "spd": 1.5,
		"basic": "thorn_claw", "passive": "barbed_coat", "ultimate": "briar_storm"},
}

const MOVES := {
	# Mossmole
	"moss_burrow": {"name": "Moss Burrow", "slot": "basic", "pct": 70, "self": {"shield_def": 40}},
	"mossy_hide": {"name": "Mossy Hide", "slot": "passive", "kind": "thorns", "pct": 30},
	"dig_in": {"name": "Dig In", "slot": "ultimate", "target": "none", "self": {"shield_def": 220}, "taunt": 3.0},
	# Burlbear
	"burl_maul": {"name": "Burl Maul", "slot": "basic", "pct": 100, "bonus": {"vs": "shielded", "amount": 25}},
	"burl_bark": {"name": "Burl Bark", "slot": "passive", "kind": "every", "n": 3, "shield_def": 90},
	"timber_crash": {"name": "Timber Crash", "slot": "ultimate", "target": "adjacent", "pct": 150, "self": {"shield_def": 60}},
	# Emberoak
	"ember_bough": {"name": "Ember Bough", "slot": "basic", "pct": 80, "def_pct": 40, "self": {"shield_def": 30}},
	"ember_bark": {"name": "Ember Bark", "slot": "passive", "kind": "thorns", "pct": 35},
	"heartfire": {"name": "Heartfire", "slot": "ultimate", "target": "none", "team": {"shield_def": 70, "shield_flat": 40}, "taunt": 4.0},
	# Acornet
	"acorn_pelt": {"name": "Acorn Pelt", "slot": "basic", "pct": 80, "self": {"shield_atk": 20}},
	"nutshell": {"name": "Nutshell", "slot": "passive", "kind": "thorns", "pct": 35, "while_shielded": true},
	"nut_barrage": {"name": "Nut Barrage", "slot": "ultimate", "target": "adjacent", "pct": 110, "self": {"shield_atk": 60}},
	# Barkbeetle
	"horn_flip": {"name": "Horn Flip", "slot": "basic", "pct": 75, "self": {"shield_def": 30}},
	"hard_shell": {"name": "Hard Shell", "slot": "passive", "kind": "start_shield", "def_pct": 200},
	"carapace": {"name": "Carapace", "slot": "ultimate", "target": "none", "self": {"shield_def": 180}, "team": {"shield_def": 30}, "taunt": 4.0},
	# ----- Milestone 1 -----
	# Mossbrock
	"sod_shove": {"name": "Sod Shove", "slot": "basic", "pct": 75, "self": {"shield_def": 45}},
	"badger_hide": {"name": "Badger Hide", "slot": "passive", "kind": "thorns", "pct": 35},
	"deep_burrow": {"name": "Deep Burrow", "slot": "ultimate", "target": "none", "self": {"shield_def": 240}, "taunt": 3.5},
	# Sodursa
	"turf_maul": {"name": "Turf Maul", "slot": "basic", "pct": 90, "def_pct": 30, "self": {"shield_def": 40}},
	"sod_armor": {"name": "Sod Armor", "slot": "passive", "kind": "every", "n": 3, "shield_def": 100},
	"earthen_den": {"name": "Earthen Den", "slot": "ultimate", "target": "adjacent", "pct": 130, "team": {"shield_def": 40}, "taunt": 4.0},
	# Hazelhorn
	"hazel_jab": {"name": "Hazel Jab", "slot": "basic", "pct": 85, "self": {"shield_atk": 20}},
	"husk_spines": {"name": "Husk Spines", "slot": "passive", "kind": "thorns", "pct": 40, "while_shielded": true},
	"nut_gore": {"name": "Nut Gore", "slot": "ultimate", "target": "adjacent", "pct": 140, "self": {"shield_atk": 60}},
	# Briarwolf
	"briar_bite": {"name": "Briar Bite", "slot": "basic", "pct": 95, "splash": 25},
	"quill_coat": {"name": "Quill Coat", "slot": "passive", "kind": "thorns", "pct": 45},
	"bramble_howl": {"name": "Bramble Howl", "slot": "ultimate", "target": "row", "pct": 120, "self": {"shield_atk": 50}},
	# Fawnmoth
	"dust_fan": {"name": "Dust Fan", "slot": "basic", "pct": 65, "ally": {"shield_atk": 40}},
	"soft_wings": {"name": "Soft Wings", "slot": "passive", "kind": "every", "n": 3, "shield_def": 60},
	"canopy_veil": {"name": "Canopy Veil", "slot": "ultimate", "target": "none", "team": {"shield_def": 45}},
	# Stagmoth
	"antler_dust": {"name": "Antler Dust", "slot": "basic", "pct": 70, "ally": {"shield_atk": 55}},
	"moth_bark": {"name": "Moth Bark", "slot": "passive", "kind": "every", "n": 3, "shield_def": 80},
	"grove_veil": {"name": "Grove Veil", "slot": "ultimate", "target": "none", "team": {"shield_def": 55, "shield_flat": 30}},
	# Lunastag
	"moonlit_antler": {"name": "Moonlit Antler", "slot": "basic", "pct": 80, "ally": {"shield_atk": 70}},
	"luna_wings": {"name": "Luna Wings", "slot": "passive", "kind": "every", "n": 2, "shield_def": 70},
	"silver_grove": {"name": "Silver Grove", "slot": "ultimate", "target": "none", "team": {"shield_def": 80, "shield_flat": 40}},
	# Burrhog
	"burr_charge": {"name": "Burr Charge", "slot": "basic", "pct": 75, "self": {"shield_def": 30}},
	"burr_quills": {"name": "Burr Quills", "slot": "passive", "kind": "thorns", "pct": 40},
	"quill_ball": {"name": "Quill Ball", "slot": "ultimate", "target": "none", "self": {"shield_def": 180}, "taunt": 3.0},
	# Thornboar
	"thorn_tusk": {"name": "Thorn Tusk", "slot": "basic", "pct": 85, "splash": 20, "self": {"shield_def": 35}},
	"spined_back": {"name": "Spined Back", "slot": "passive", "kind": "thorns", "pct": 55},
	"briar_stampede": {"name": "Briar Stampede", "slot": "ultimate", "target": "row", "pct": 110, "self": {"shield_def": 80}, "taunt": 4.0},
	# Peckscale
	"bark_peck": {"name": "Bark Peck", "slot": "basic", "pct": 50, "hits": 2, "self": {"shield_atk": 15}},
	"drum_rhythm": {"name": "Drum Rhythm", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 40},
	"hollow_drum": {"name": "Hollow Drum", "slot": "ultimate", "target": "adjacent", "pct": 130, "self": {"shield_atk": 40}},
	# Drumscale
	"drum_peck": {"name": "Drum Peck", "slot": "basic", "pct": 50, "hits": 2, "self": {"shield_atk": 20}},
	"tree_drummer": {"name": "Tree Drummer", "slot": "passive", "kind": "every", "n": 3, "extra_pct": 50},
	"timber_roll": {"name": "Timber Roll", "slot": "ultimate", "target": "adjacent", "pct": 160, "self": {"shield_atk": 40}},
	# Snailback
	"shell_bump": {"name": "Shell Bump", "slot": "basic", "pct": 65, "def_pct": 30, "self": {"shield_def": 20}},
	"coiled_shell": {"name": "Coiled Shell", "slot": "passive", "kind": "start_shield", "def_pct": 220},
	"slow_fortress": {"name": "Slow Fortress", "slot": "ultimate", "target": "none", "self": {"shield_def": 200}, "taunt": 4.0},
	# Domeshell
	"dome_slam": {"name": "Dome Slam", "slot": "basic", "pct": 70, "def_pct": 40, "self": {"shield_def": 30}},
	"living_dome": {"name": "Living Dome", "slot": "passive", "kind": "start_shield", "def_pct": 260},
	"moss_bastion": {"name": "Moss Bastion", "slot": "ultimate", "target": "none", "self": {"shield_def": 220}, "team": {"shield_def": 40}, "taunt": 4.5},
	# Grovemoose
	"elder_antler": {"name": "Elder Antler", "slot": "basic", "pct": 85, "def_pct": 40, "splash": 30},
	"old_growth": {"name": "Old Growth", "slot": "passive", "kind": "every", "n": 3, "shield_def": 120},
	"forest_crown": {"name": "Forest Crown", "slot": "ultimate", "target": "none", "team": {"shield_def": 80, "shield_flat": 40}, "taunt": 4.0},
	# Briarlynx
	"thorn_claw": {"name": "Thorn Claw", "slot": "basic", "pct": 90, "self": {"shield_atk": 25}},
	"barbed_coat": {"name": "Barbed Coat", "slot": "passive", "kind": "thorns", "pct": 60, "while_shielded": true},
	"briar_storm": {"name": "Briar Storm", "slot": "ultimate", "target": "all", "pct": 85, "self": {"shield_atk": 80}},
}

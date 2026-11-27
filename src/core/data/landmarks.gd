class_name Landmarks
extends RefCounted
## Region landmarks (the lm_* props drawn in the scenery): a short arrival card the first time
## the caravan reaches a region, with the day count and a small reward for stopping to look.

## lm id -> [name, one line, reward fx]
const ALL := {
	"lm_the_mossdeeps": ["The Sunken Head", "A brass giant's head, ferns growing from its eyes.", {"light_dust": 1}],
	"lm_lanternwood": ["The Lantern Tree", "Teal lanterns sway in branches no one could have climbed.", {"health": 10}],
	"lm_the_green_tangle": ["The Strangled Crane", "Vines have pulled the old crane halfway to the ground.", {"coins": 6}],
	"lm_elderglade": ["The Elder Dial", "The sundial's shadow points west. So do you.", {"xp": 15}],
	"lm_the_rolling_downs": ["The Windpump", "It still pumps sweet water, clanking all night.", {"water": 20}],
	"lm_copper_barrows": ["The Copper Door", "A round green door in a hill. Best left closed.", {"light_dust": 1}],
	"lm_gorse_heights": ["The Bird Cairn", "Travellers add a stone for luck. You add yours.", {"health": 10}],
	"lm_windmere": ["The Great Turbine", "Three wooden blades turn slow as clouds.", {"xp": 15}],
	"lm_the_silverrun": ["The Falling Bridge", "A waterfall pours through an iron pier.", {"water": 20}],
	"lm_reedwater_vale": ["Reedwater Mill", "The miller waves and tosses you a sack of meal.", {"food": 15}],
	"lm_the_kettle_flats": ["The Boiling Kettle", "Steam rises from a boiler the size of a barn.", {"health": 10}],
	"lm_otterbend": ["The Otter Dam", "Brass sluices, a tiny lodge, and a lot of otters.", {"food": 10}],
	"lm_the_murkfens": ["The Drowned Engine", "Mushrooms crowd the boiler of a sunken locomotive.", {"food": 10}],
	"lm_gloamwallow": ["The Gloam Willow", "Violet fronds glow; fireflies swirl around the wagon.", {"light_dust": 1}],
	"lm_the_rotting_reach": ["The Bog Ship", "A ship stranded in a bog, a hundred miles from any sea.", {"coins": 6}],
	"lm_peatmoor": ["The Peat Crane", "Stacked peat bricks: dry fuel for cold nights.", {"health": 10}],
	"lm_the_cogspires": ["The Cog Spire", "Giant rusted cogs stacked to the clouds.", {"xp": 15}],
	"lm_frostcrag_range": ["The Frozen Pipes", "A waterfall frozen mid-fall over brass pipes.", {"water": 15}],
	"lm_the_anvil_teeth": ["The Anvil Forge", "A forge still glows in the rock. The smith fixes a strap.", {"wear": -10}],
	"lm_slate_wall": ["The Stone Door", "A door carved in a cliff, hinges as big as the wagon.", {"light_dust": 1}],
	"lm_the_white_reach": ["The Buried Airship", "Icicles hang from a frozen airship's gondola.", {"coins": 6}],
	"lm_frostfang_pass": ["The Fang Gate", "Two ice fangs over a brass gate. You pass between them.", {"xp": 15}],
	"lm_rimeholt": ["Rimeholt Towers", "Smoking chimneys on stilts. Someone shares hot soup.", {"food": 10}],
	"lm_the_hoarwood": ["The Hoar Tree", "Blue ice crystals hum in an ancient tree.", {"health": 10}],
	"lm_the_emerald_canopy": ["The Fountain Tree", "Water pours from a hollow trunk. Fill every barrel.", {"water": 20}],
	"lm_vinehold": ["The Vine Temple", "Brass gears turn somewhere deep inside the steps.", {"light_dust": 1}],
	"lm_the_sunken_gardens": ["The Glass Garden", "Giant flowers burst through a broken greenhouse dome.", {"food": 10}],
	"lm_parrotspire": ["The Parrot Mast", "Bright birds chatter from a rusted radio tower.", {"xp": 15}],
	"lm_the_ashen_hollow": ["The Ashen Tree", "Dark dust swirls inside a split black trunk.", {"dark_dust": 1}],
	"lm_duskmire_scar": ["The Scar Spire", "A violet crack in the rock breathes dark mist.", {"dark_dust": 1}],
	"lm_the_withering": ["The Fallen Colossus", "A brass giant lies in black thorns and violet crystal.", {"dark_dust": 1}],
	"lm_lumen_meadows": ["The Lumen Obelisk", "Golden light pours over a ring of glowing flowers.", {"light_dust": 2}],
	"lm_the_shining_steppe": ["The Floating Isle", "A crystal island hums above its brass pedestal.", {"light_dust": 2}],
	"lm_halo_glade": ["The Halo Tree", "A ring of light floats over a white tree.", {"health": 15}],
}


static func has(lm: String) -> bool:
	return ALL.has(lm)


static func name_of(lm: String) -> String:
	return String(ALL.get(lm, ["", "", {}])[0])


## The arrival card as an event: one choice, the reward.
static func card(lm: String, region_name: String, day: int) -> Dictionary:
	var e: Array = ALL[lm]
	var fx: Dictionary = (e[2] as Dictionary).duplicate()
	fx["text"] = "You stop to take it in."
	fx["morale"] = Camp.ON["landmark"]
	return {"id": "landmark", "kind": "find", "icon": "landmark", "title": String(e[0]), "landmark": lm,
		"text": "Day %d, %s. %s" % [day, region_name, String(e[1])],
		"choices": [{"label": "Take it in", "success": fx}]}

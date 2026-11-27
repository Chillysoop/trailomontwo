"""Icon set for the UI: one 16x16 sprite per id, saved to assets/icons/<id>.png.

  python3 tools/art/icons.py generate [id ...]   # Sprite Fusion, 3 credits each (skips existing files)
  python3 tools/art/icons.py placeholder         # plain stand-ins for any icon still missing

Reads SPRITE_FUSION_API_KEY from the environment. Never write the key anywhere.
"""
import json
import os
import sys
import urllib.request

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "icons")
STYLE = "naturepunk style, bold dark outline, readable silhouette"

# id -> subject. Every prompt shares STYLE so the set reads as one family.
ICONS = {
    # creature stats
    # The six stat icons must differ in both color and shape so they read at a glance:
    # red heart, orange sword, blue shield, green chevrons, purple impact, gold star.
    "hp": "a single plump solid bright red heart, simple shape, no frame",
    "atk": "a single bright orange sword pointing diagonally up, simple shape",
    "def": "a single solid steel blue kite shield with a white rim, simple shape",
    "spd": "two bright green arrow chevrons pointing right, simple shape",
    "dps": "a magenta purple starburst impact splash with three sharp spikes, simple shape",
    # Move-slot tags (also used for memory slots): white claw, green aura ring, gold star.
    "basic": "three bold white diagonal claw slash marks, simple shape, no background",
    "passive": "a soft green glowing ring aura with a leaf, on a small dark round badge",
    "ultimate": "a big bright gold five pointed star with a yellow glow, simple shape, no background",
    "might": "a clenched fist wrapped in a brass knuckle band with ivy",
    "spirit": "a glowing teal spirit flame inside a small brass lantern cage",
    "guard": "a round wooden shield with a brass rim and moss on it",
    "tempo": "a small brass winged boot with a leaf on the wing",
    "cooldown": "a brass hourglass with green sand",
    # habitats (types) and terrain
    "forest": "a dark green pine tree with a brass ring around its trunk",
    "river": "a blue water wave curling over a small river stone",
    "swamp": "a murky green swamp bubble with a cattail reed",
    "mountain": "a grey mountain peak with a snowy tip and a brass gear at its base",
    "jungle": "a big bright tropical monstera leaf with a hanging vine",
    "snow": "a pale blue snowflake crystal",
    "hills": "two rolling green grassy hills with a dirt path",
    # battle roles
    "role_guard": "a tall tower shield with a mossy oak leaf emblem",
    "role_bruiser": "a heavy stone hammer bound with copper wire",
    "role_healer": "a green healing herb sprig with a teal glow drop",
    "role_support": "a small brass hand bell with a ribbon",
    "role_striker": "a curved crossed claw slash with three sharp claw marks",
    # statuses
    "shield": "a pale blue glowing bubble shield",
    "poison": "a green poison droplet with a skull shaped bubble",
    "taunt": "an angry red exclamation mark on a yellow burst",
    "haste": "a yellow lightning bolt with speed lines",
    "weaken": "a round shield split by a big jagged crack with a red arrow pointing down beside it",
    "slow": "a blue snail shell with a frost crystal",
    "ko": "three yellow cartoon stars circling above, knocked out daze symbol",
    "tired": "a sleepy blue zzz letters over a small cloud",
    # dust (permanent boosts, coming later)
    "light_dust": "a small cloth pouch spilling glowing pale gold sparkling dust",
    "dark_dust": "a small cloth pouch spilling glowing deep violet dust with dark sparkles",
    # empty memory slot
    "memory": "a small empty glass jar with a faint teal glow inside and a cork stopper",
    "technique": "a rolled parchment scroll tied with a green ribbon and a small glowing rune",
    # battle items (consumables)
    "item_slot": "an empty small leather belt pouch with a brass buckle",
    "ironbark_salve": "a small round tin of salve with a bark textured lid and a blue shield glow",
    "ember_draught": "a small corked potion bottle with glowing orange ember liquid",
    "stoneskin_tea": "a small clay teacup with grey stone flakes and steam",
    "swiftwind_feather": "a single bright green feather with yellow speed streaks",
    "rally_horn": "a curved brass horn with a red cord, sound waves",
    "mending_moss": "a clump of bright green moss with a teal healing sparkle",
    "smoke_pouch": "a small grey pouch puffing a blue grey smoke cloud",
    "bitter_ash": "a small dark jar of black ash with a cracked lid and purple wisps",
    # trail resources
    "day": "a bright orange sun over a horizon line",
    "food": "a round loaf of bread with a sprig of wheat",
    "water": "a leather water skin canteen with a blue drop",
    "cargo": "a wooden crate bound with rope and brass corners",
    "haul": "a coil of thick rope with a brass hook",
    "wagon": "a wooden wagon wheel with metal rim and brass hub",
    "health": "a red medical cross on a small parchment patch",
    "repair_kit": "a crossed brass wrench and hammer",
    "risk": "a cracked bone skull warning sign",
    "value": "a stack of three gold coins",
    "weight": "an iron kettlebell weight",
    # ----- trail life (weather, pace, rations, encounters, jobs) -----
    "w_clear": "a small bright yellow sun with short rays in a clear sky, simple shape",
    "w_rain": "a grey rain cloud with three blue raindrops falling",
    "w_fog": "three soft pale grey horizontal fog bands with a faint tree silhouette",
    "w_ashfall": "dark grey ash flakes and violet dust motes falling from a black cloud",
    "w_shimmer": "golden light motes and a soft aurora ribbon in the sky",
    "biome_blight": "a withered black leaf cracked with glowing violet veins",
    "biome_glow": "a radiant white-gold crystal flower with light rays",
    "w_storm": "a dark purple storm cloud with a bright yellow lightning bolt",
    "w_heat": "a fiery orange sun with wavy red heat lines below it",
    "w_cold": "a pale blue cloud with white snowflakes falling",
    "pace_easy": "a small green leaf boot walking slowly with a tiny snail beside it",
    "pace_steady": "a sturdy brown leather boot with a brass buckle, stepping",
    "pace_hard": "a running brown boot with orange speed lines and sweat drops",
    "rations_full": "a wooden bowl heaped high with stew and a steaming bread roll",
    "rations_thin": "a nearly empty wooden bowl with a few crumbs and a spoon",
    "coins": "a single round brass coin stamped with a green leaf",
    "fever": "a sweating sick green face with a red thermometer",
    "xp": "a bright green upward arrow with a small gold star",
    "progress": "a wooden trail signpost with an arrow pointing right",
    "ev_travelers": "a small travelling cart with a canvas cover and a lantern, side view",
    "ev_wildlife": "a big brown animal paw print with a leaf",
    "ev_hazard": "a yellow triangle warning sign with a black exclamation mark",
    "ev_find": "a small open wooden treasure chest with a teal glow inside",
    "ev_shrine": "a mossy standing stone with a glowing teal rune",
    "settlement": "a small cottage with a mossy roof and a brass chimney",
    "grave": "a small grey stone tombstone with moss and a wildflower",
    "trade": "two hands shaking over a brass coin",
    "camp": "a small campfire with crossed logs and orange flames",
    "job_clear": "a small woodcutter axe with a brass head",
    "job_strength": "a wooden ox yoke with a thick rope",
    "job_float": "a small leaf raft floating on blue water",
    "job_light": "a glowing teal lantern bulb on a hook",
    "job_scout": "a brass spyglass telescope",
    "job_steady": "a brass anchor with a green vine",
    "job_cold": "a warm red knitted scarf with fur trim",
    "job_heal": "a green healing herb bundle tied with string",
    # catching
    "lure": "a small woven brass and reed bait charm with a glowing teal berry hanging from a string",
    "starter": "a small brass compass rose with a green leaf in its center",
    "map": "a folded parchment treasure map with a dotted trail and a red x",
    "job_forage": "a small woven basket full of red berries and mushrooms",
}


def _download(url, path):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=60) as resp, open(path, "wb") as f:
        f.write(resp.read())


def generate(ids):
    key = os.environ.get("SPRITE_FUSION_API_KEY")
    if not key:
        sys.exit("SPRITE_FUSION_API_KEY is not set")
    os.makedirs(OUT, exist_ok=True)
    for icon_id in ids:
        path = os.path.join(OUT, icon_id + ".png")
        if os.path.exists(path) and not os.path.exists(path + ".placeholder"):
            print("skip", icon_id)
            continue
        body = json.dumps({"operation": "generate", "prompt": "Game UI icon: %s, %s" % (ICONS[icon_id], STYLE),
                           "size": 16, "count": 1, "tags": ["trailomon-icons"]}).encode()
        req = urllib.request.Request("https://www.spritefusion.com/api/v1/generate", data=body, method="POST",
                                     headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"})
        url = None
        with urllib.request.urlopen(req, timeout=300) as resp:
            for raw in resp:
                line = raw.decode().strip()
                if not line.startswith("data:"):
                    continue
                ev = json.loads(line[5:])
                if ev.get("type") == "output":
                    url = ev["asset"]["assetUrl"]
                elif ev.get("type") == "completed":
                    print(icon_id, ev.get("status"), "credits left", ev.get("credits", {}).get("remaining"))
        print(icon_id, "asset", url, flush=True)
        if url is None:
            print("FAILED", icon_id)
            continue
        _download(url, path)
        if os.path.exists(path + ".placeholder"):
            os.remove(path + ".placeholder")


def placeholder():
    from PIL import Image, ImageDraw
    os.makedirs(OUT, exist_ok=True)
    for i, icon_id in enumerate(ICONS):
        path = os.path.join(OUT, icon_id + ".png")
        if os.path.exists(path):
            continue
        hue = [(210, 120, 90), (110, 180, 110), (110, 160, 220), (220, 190, 100), (190, 120, 200)][i % 5]
        im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.ellipse((1, 1, 14, 14), fill=hue + (255,), outline=(43, 32, 48, 255))
        d.text((4, 2), icon_id[0].upper(), fill=(43, 32, 48, 255))
        im.save(path)
        open(path + ".placeholder", "w").close()


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "generate":
        generate(sys.argv[2:] or list(ICONS))
    elif cmd == "placeholder":
        placeholder()
    else:
        print(__doc__)

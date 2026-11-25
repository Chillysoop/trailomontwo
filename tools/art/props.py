"""Trail-life props: one Sprite Fusion sprite per id, saved to assets/props/<id>.png.

  python3 tools/art/props.py generate [id ...]   # 5 credits each at 96px+, 3 at 80px or less (skips existing files)

Reads SPRITE_FUSION_API_KEY from the environment. Never write the key anywhere.
"""
import json
import os
import sys
import urllib.request

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "props")
STYLE = "naturepunk style, side view, pixel art game sprite, transparent background, nature reclaiming brass machinery"

# id -> (size, subject)
PROPS = {
    "trader_cart": (96, "a small two-wheeled covered trader cart piled with sacks and lanterns, facing left"),
    "traveler": (64, "a hooded traveller walking with a big backpack and a walking staff, facing left, full body"),
    "signpost": (64, "a weathered wooden trail signpost with two arrow boards and moss"),
    "grave_marker": (64, "a small wooden grave cross with a hanging lantern and wildflowers on a dirt mound"),
    "campfire": (64, "a small campfire with crossed logs, a cooking pot on a tripod, flames"),
    "abandoned_cart": (96, "a broken abandoned wagon with a missing wheel, overgrown with vines and flowers"),
    "hut": (128, "a cozy village cottage with a mossy thatched roof, round window and brass chimney pipe"),
    "trading_post": (128, "a wooden trading post market stall with a striped awning, crates and hanging lanterns"),
    "stilt_house": (128, "a swamp house on tall wooden stilts with a rope ladder and glowing lantern"),
    "tent_camp": (96, "a canvas camping tent with a lantern and a bedroll beside it"),
    "shrine_stone": (80, "an ancient standing stone with a glowing teal rune and moss"),
    "well": (80, "a stone village water well with a wooden roof and a bucket"),

    # ---- Terrain kits for the overworld (travel and battle scenery) ----
    "hills_oak": (128, "a lone windswept oak tree on a grassy knoll, leaning, brass wind chimes in its branches"),
    "hills_rocks": (96, "a cluster of mossy grey boulders with glinting copper veins and small yellow flowers"),
    "hills_heather": (96, "a low clump of purple heather and yellow gorse bushes, wide and short"),
    "hills_fence": (96, "a broken wooden pasture fence wrapped in climbing roses, short and wide"),
    "river_willow": (128, "a weeping willow tree with long hanging fronds and a small brass birdhouse"),
    "river_reeds": (96, "a dense clump of tall cattail reeds and river grass with blue flowers"),
    "river_rocks": (96, "smooth river stones with lily pads and a rusted brass pipe poking out of the water"),
    "river_jetty": (96, "a small wooden fishing jetty on posts with a coiled rope and a lantern"),
    "swamp_mangrove": (128, "a gnarled dead swamp tree with twisted roots above water and hanging grey moss"),
    "swamp_shrooms": (96, "a cluster of tall glowing teal and violet bog mushrooms on a rotting log"),
    "swamp_cattails": (96, "a clump of swamp cattails with pink lotus flowers and broad leaves, isolated plant, empty transparent background, short and wide"),
    "swamp_boiler": (96, "a half-sunken rusted brass boiler tank overgrown with moss and swamp vines"),
    "mtn_pine": (128, "a tall dark pine tree with snow on its branches and a brass ring bolted around the trunk"),
    "mtn_boulder": (96, "a big snowy granite boulder with blue ice crystals and lichen"),
    "mtn_shrub": (96, "frosted alpine shrubs and small white mountain flowers, short and wide"),
    "mtn_minecart": (96, "a rusted mine cart full of glowing blue ore on a short broken rail track"),

    # ---- Region landmarks: one per region name, seen far off the road ----
    "lm_the_mossdeeps": (128, "a giant moss-covered fallen brass robot head half sunk into a forest floor, ferns growing from its eyes"),
    "lm_lanternwood": (128, "a single colossal ancient tree with glowing teal lanterns hanging from its branches, isolated object, empty transparent background, no sky"),
    "lm_the_green_tangle": (128, "a rusted tall construction crane strangled by thick green vines and flowers"),
    "lm_elderglade": (128, "a ring of standing elder stones around a big brass sundial overgrown with ivy"),
    "lm_the_rolling_downs": (128, "a tall old brass windpump tower with a spinning fan on a grassy hill"),
    "lm_copper_barrows": (128, "a grassy burial mound with a round copper door and green patina, stones on top"),
    "lm_gorse_heights": (128, "a tall stacked stone cairn topped with a brass weathervane shaped like a bird"),
    "lm_windmere": (128, "a giant three-bladed wind turbine made of wood and brass overgrown with flowering vines"),
    "lm_the_silverrun": (128, "an old iron railway bridge pier overgrown with ivy, a waterfall pouring through it"),
    "lm_reedwater_vale": (128, "a big wooden water mill with a turning waterwheel and a mossy roof"),
    "lm_the_kettle_flats": (128, "a giant rusted brass kettle-shaped boiler lying on its side, steam rising, reeds around it"),
    "lm_otterbend": (128, "a log dam with brass sluice gates and a little lodge on top, water spilling over"),
    "lm_the_murkfens": (128, "a half-sunken overgrown steam locomotive in a swamp, mushrooms on its boiler"),
    "lm_gloamwallow": (128, "a giant glowing swamp willow with bioluminescent violet fronds and fireflies"),
    "lm_the_rotting_reach": (128, "a broken wooden ship hull stranded in a bog, masts tangled with moss"),
    "lm_peatmoor": (128, "an old wooden peat-cutting crane with brass gears beside a stack of peat bricks"),
    "lm_the_cogspires": (128, "a tall spire built of stacked giant rusted cogs on a rocky peak, snow on top"),
    "lm_frostcrag_range": (128, "a lone icy rock pinnacle with a frozen waterfall over huge brass pipes, isolated object, empty transparent background, no sky"),
    "lm_the_anvil_teeth": (128, "a huge anvil-shaped rock with a forge chimney glowing orange, snow around it"),
    "lm_slate_wall": (128, "a towering slate cliff wall with a giant carved stone door and brass hinges"),

    # ---- Dust biomes (late game): Dark-dust Blight and Light-dust Glow ----
    "blight_tree": (128, "a dead blackened tree with cracked bark leaking glowing violet dark dust, withered twisted branches"),
    "blight_crystal": (96, "a cluster of jagged black-violet crystals oozing dark mist from cracked brass pipes"),
    "blight_wreck": (96, "a corroded brass machine wreck dripping dark violet ooze, withered grey vines on it"),
    "blight_brambles": (96, "black thorny brambles with ashen leaves and small glowing violet buds, short and wide"),
    "glow_tree": (128, "a pale white-barked tree with glowing golden leaves and floating light motes, brass rings on the trunk"),
    "glow_crystal": (96, "a cluster of radiant white-gold crystals humming with light, set in polished brass"),
    "glow_pylon": (96, "a restored shining brass pylon wrapped in blooming white flowers, glowing gold core"),
    "glow_flowers": (96, "luminous white and gold flowers and glowing grass, short and wide"),
    "lm_the_ashen_hollow": (128, "a huge hollow black dead tree split open, a violet dark-dust vortex swirling inside, ash all around"),
    "lm_duskmire_scar": (128, "a tall jagged black rock spire split by a glowing violet crack venting dark mist, broken brass pipes, isolated object, empty transparent background, no sky"),
    "lm_the_withering": (128, "a giant toppled brass colossus statue covered in black thorns and violet crystals"),
    "lm_lumen_meadows": (128, "a tall white crystal obelisk radiating golden light over a ring of glowing flowers"),
    "lm_the_shining_steppe": (128, "a floating island of golden crystal hovering above a brass pedestal, light motes around it"),
    "lm_halo_glade": (128, "a giant white tree with a glowing golden halo ring of light floating above its crown"),
    "bld_ward_post": (128, "a small warden outpost: a wooden palisade gate with a tall brass lantern glowing gold on top, isolated object, empty transparent background, no sky"),
    "bld_sanctum": (128, "a small white stone sanctuary shrine with a golden glowing dome and flowering vines"),

    # ---- Snow and Jungle terrains ----
    "snow_fir": (128, "a snow-laden fir tree with icicles and a small brass lantern hanging from a branch"),
    "snow_drift": (96, "a snowdrift with a half-buried brass gear and frosted grass, short and wide"),
    "snow_sled": (96, "an abandoned wooden supply sled with brass runners, covered in snow"),
    "snow_ice": (96, "jagged blue ice chunks with frozen copper pipes, isolated object, empty transparent background"),
    "jungle_palm": (128, "a tall curved jungle palm tree with huge leaves and climbing vines around a brass pipe"),
    "jungle_ferns": (96, "giant tropical leaves, monstera and bright orange flowers, short and wide"),
    "jungle_idol": (96, "a moss-covered carved stone idol head with brass eyes and vines"),
    "jungle_vines": (96, "a hanging curtain of thick jungle vines with purple flowers on a rusted brass arch"),
    "lm_the_white_reach": (128, "a giant frozen brass airship half buried in snow, icicles hanging from it, isolated object, empty transparent background, no sky"),
    "lm_frostfang_pass": (128, "two huge curved ice spikes like fangs over a snowy brass gate, isolated object, empty transparent background, no sky"),
    "lm_rimeholt": (128, "a snowy wooden watchtower village on stilts with smoking brass chimneys, isolated object, empty transparent background, no sky"),
    "lm_the_hoarwood": (128, "a huge ancient frost-covered tree with blue glowing ice crystals in its branches, isolated object, empty transparent background, no sky"),
    "lm_the_emerald_canopy": (128, "a colossal jungle tree with a waterfall pouring from its hollow trunk, isolated object, empty transparent background, no sky"),
    "lm_vinehold": (128, "an ancient stepped stone temple overgrown with jungle vines and brass gears, isolated object, empty transparent background, no sky"),
    "lm_the_sunken_gardens": (128, "a ruined brass greenhouse dome overgrown with giant tropical flowers, isolated object, empty transparent background, no sky"),
    "lm_parrotspire": (128, "a tall rusted radio tower wrapped in jungle vines with colorful birds perched on it, isolated object, empty transparent background, no sky"),
    "bld_snow_lodge": (128, "a cozy snow-covered log lodge with a round brass door and warm glowing windows, isolated object, empty transparent background"),
    "bld_treehouse": (128, "a jungle treehouse hut on a thick trunk with a rope ladder and leaf roof, isolated object, empty transparent background"),

    # ---- Stops ----
    "bld_town_gate": (128, "a big walled town gate with stone towers, a brass clock above the arch and banners"),
    "bld_lookout": (128, "a tall wooden lookout tower with a ladder, a brass spyglass and a flag on top"),
    "bld_ruins": (128, "a crumbled stone archway with old brass gears embedded in it, overgrown with ivy"),
    "bld_inn": (128, "a cozy two-storey roadside waystation inn with a hanging sign and warm windows"),
    "bld_mine_post": (128, "a sturdy log mining cabin with a stone chimney, a pickaxe sign and snow on the roof"),
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
    for pid in ids:
        path = os.path.join(OUT, pid + ".png")
        if os.path.exists(path):
            print("skip", pid)
            continue
        size, subject = PROPS[pid]
        body = json.dumps({"operation": "generate", "prompt": "%s, %s" % (subject, STYLE),
                           "size": size, "count": 1, "tags": ["trailomon-props"]}).encode()
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
                    print(pid, ev.get("status"), "credits left", ev.get("credits", {}).get("remaining"))
        if url is None:
            print("FAILED", pid)
            continue
        _download(url, path)
        print("saved", pid, flush=True)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "generate":
        generate(sys.argv[2:] or list(PROPS))
    else:
        print(__doc__)

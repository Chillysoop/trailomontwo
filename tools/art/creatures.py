"""Trailomon creature sprites: one Sprite Fusion sprite per species, saved to assets/creatures/<id>.png.

  python3 tools/art/creatures.py generate [id ...]   # 3 credits at 64-80px (skips existing files)

Reads SPRITE_FUSION_API_KEY from the environment. Never write the key anywhere.
Creatures face right, side view, full body, like the approved set (Coilhusk, Inkhoot, ...).
"""
import json
import os
import sys
import urllib.request

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "creatures")
STYLE = ("naturepunk style creature, side view facing right, full body, pixel art game sprite, "
         "transparent background, bold dark outline, nature reclaiming brass machinery, monster collecting game")

# id -> (size, subject)
CREATURES = {
    "mossmole": (64, "a chubby mole with a thick green moss back, brass digging goggles and big shovel claws"),
    "burlbear": (64, "a big bear whose shoulders and back are armored in knotted burl wood plates, a brass gauntlet on one paw"),
    "pebblotter": (64, "a cheerful otter holding a smooth river pebble, small brass shell backpack, water droplets"),
    "lanternray": (64, "a floating manta ray with a glowing teal lantern on its long tail, brass fins edges"),
    "sporetoad": (64, "a squat toad with a red spotted mushroom cap on its head puffing green spores"),
    "bogjaw": (64, "a swamp crocodile with rusty brass pipe valves along its back and moss hanging from its jaws"),
    "slatebeak": (64, "a vulture bird with grey slate stone plates for feathers and a sharp rock beak, perched"),
    "quarrytusk": (64, "a stocky boar mammoth with brass drill tusks and rocky stone hide"),
    "flurrypup": (64, "a small fluffy white fox pup with an icicle tail and a tiny brass bell collar"),
    "rimewing": (64, "a snowy owl with frost crystal blade wings spread, pale blue glow"),
    "vinegecko": (64, "a bright green gecko with leafy vines wrapped around its body and a curling vine tail"),
    "canopard": (64, "a sleek leopard with leaf shaped spots and a cloak of jungle leaves, brass ear cuffs"),
    "emberoak": (64, "a legendary walking oak tree beast on four root legs with a glowing brass furnace heart in its chest, majestic"),
    "tidewyrm": (64, "a legendary long sea serpent with shining blue scales, coral crown and brass fin rings, majestic"),
    "auroryx": (64, "a legendary oryx antelope with long straight horns and a shimmering green aurora mane, majestic"),
    # Batch 2
    "acornet": (64, "a squirrel wearing an acorn cap helmet with a bushy leaf tail and a tiny brass slingshot"),
    "minnowisp": (64, "a small glowing minnow fish spirit floating in a bubble of water with little fins like wings"),
    "murkmoth": (64, "a dusky purple moth with swamp green eye spots on its wings shedding toxic dust"),
    "cragkid": (64, "a young mountain goat kid with small rocky horns and a stone plated back, brass bell"),
    "sleetmouse": (64, "a tiny white mouse with frosty ice crystal ears and a long icicle tail"),
    "vinekeet": (64, "a bright green parakeet with vine tendrils for tail feathers and a flower crest"),
    "barkbeetle": (64, "a big rhinoceros beetle with a bark covered shell, mossy horn and brass leg joints"),
    "kelpoise": (64, "a large sea tortoise with a shell overgrown with kelp and barnacles, brass porthole on the shell"),
    "gloomleech": (64, "a giant dark swamp leech with glowing purple spots, ringed body and a round toothy mouth"),
    "basaltortle": (64, "a heavy tortoise with a shell of black basalt columns and glowing magma cracks"),
    "frostmane": (64, "a big white lion with a mane of ice crystals and frosted brass armor bands"),
    "prowlmander": (64, "a jungle salamander with orange and teal stripes, long sticky tongue and leaf frills"),
    "mirehydra": (64, "a legendary three headed swamp hydra covered in moss and reeds with glowing green eyes, majestic"),
    "titanox": (64, "a legendary giant ox with huge stone horns, a brass furnace on its back and rocky hide, majestic"),
    "quetzalith": (64, "a legendary feathered jungle serpent with rainbow plumes and a gold sun crest, majestic"),
    "bogmother": (80, "a giant boss toad queen covered in swamp mushrooms and lily pads, rusted brass crown, huge and menacing"),
    "cogmammoth": (80, "a giant boss woolly mammoth made of moss and brass gears with steam pistons on its legs, huge and menacing"),
    "rimewyrm": (80, "a giant boss ice wyrm dragon with frost crystal spikes and frozen brass chains, huge and menacing"),
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
    for cid in ids:
        path = os.path.join(OUT, cid + ".png")
        if os.path.exists(path):
            print("skip", cid)
            continue
        size, subject = CREATURES[cid]
        body = json.dumps({"operation": "generate", "prompt": "%s, %s" % (subject, STYLE),
                           "size": size, "count": 1, "tags": ["trailomon-creatures"]}).encode()
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
                    print(cid, ev.get("status"), "credits left", ev.get("credits", {}).get("remaining"))
        if url is None:
            print("FAILED", cid)
            continue
        _download(url, path)
        print("saved", cid, flush=True)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "generate":
        generate(sys.argv[2:] or list(CREATURES))
    else:
        print(__doc__)

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
    # ----- Milestone 1: Forest and River -----
    "mossbrock": (64, "a stocky badger and mole hybrid with a mossy striped back, brass digging goggles and big shovel claws"),
    "sodursa": (64, "a huge bear and mole hybrid covered in turf and moss, tiny eyes, giant shovel claws and brass shoulder plates"),
    "hazelhorn": (64, "a squirrel and stag beetle hybrid with a fluffy tail, a hazelnut shell carapace and big beetle mandible horns"),
    "briarwolf": (64, "a lean wolf and porcupine hybrid with thorny bramble quills down its back and a brass collar"),
    "fawnmoth": (64, "a small spotted fawn and moth hybrid with soft leafy moth wings and feathery antennae"),
    "stagmoth": (64, "a young deer and moth hybrid with small branching antlers, large green moth wings and a fuzzy mane"),
    "lunastag": (64, "a majestic stag and luna moth hybrid with pale green moth wings, glowing antlers wrapped in brass rings"),
    "burrhog": (64, "a round hedgehog and boar hybrid with burr covered spines, little tusks and a snout"),
    "thornboar": (64, "a big wild boar and hedgehog hybrid with a back of thorny spines, curved tusks and brass tusk caps"),
    "peckscale": (64, "a small woodpecker and gecko hybrid with a red crest, scaly green body and a sharp beak"),
    "drumscale": (64, "a woodpecker and monitor lizard hybrid with a red crest, long scaly tail, bark textured scales and a chisel beak"),
    "snailback": (64, "a snail and tortoise hybrid with a mossy spiral shell, stubby tortoise legs and eye stalks"),
    "domeshell": (64, "a giant tortoise and snail hybrid with a huge domed spiral shell overgrown with ferns and brass rivets"),
    "grovemoose": (64, "a legendary ancient moose and tortoise hybrid with huge antlers growing into living trees, a mossy shell back, majestic"),
    "briarlynx": (64, "a legendary lynx and porcupine hybrid with tufted ears, a mane of thorny quills and glowing green eyes, majestic"),
    "damotter": (64, "an otter and beaver hybrid with a flat paddle tail, buck teeth and a brass tool belt of sticks"),
    "shoalwisp": (64, "a minnow and jellyfish hybrid fish with a glowing translucent bell head and trailing tendrils"),
    "glimmerkoi": (64, "a large orange and white koi and jellyfish hybrid with glowing see through fins and long trailing tendrils"),
    "inkstrix": (64, "a great horned owl and squid hybrid with inky black feathers, tentacles for tail feathers and big yellow eyes"),
    "crayhopper": (64, "a small crayfish and frog hybrid with springy frog legs, red crayfish claws and a shell back"),
    "pincerfrog": (64, "a crayfish and tree frog hybrid with big crayfish pincers, long frog legs and a spotted green shell"),
    "bullcray": (64, "a huge bullfrog and crayfish hybrid with giant armored claws, a puffed throat sac and a brass plated shell"),
    "stiltseal": (64, "a seal pup and heron hybrid with long thin wading legs, a grey seal body and a heron beak"),
    "wadeseal": (64, "a big grey seal and heron hybrid with long stilt legs, a crest of heron plumes and a brass whistle"),
    "salmoram": (64, "a salmon and ram hybrid with a red silver fish body, curled ram horns and sturdy hooves"),
    "rapidram": (64, "a big bighorn ram and salmon hybrid with huge curled horns, silver red scales and fins along its back"),
    "shelldrake": (64, "a duck and turtle hybrid with a mallard head and webbed feet and a green turtle shell back"),
    "moatdrake": (64, "a big snapping turtle and drake duck hybrid with a heavy ridged shell, iridescent green head and brass shell bands"),
    "tidecrane": (64, "a legendary crane and blue whale hybrid with long crane wings, a whale body and water spouting from its back, majestic"),
    "narwhalcon": (64, "a legendary narwhal and falcon hybrid with a spiral tusk, sleek falcon wings and a whale tail, majestic"),
    # ----- Milestone 2: Swamp and Mountain -----
    "mirecroak": (64, "a warty toad and fire salamander hybrid with orange spots and little mushrooms growing on its back"),
    "gilatoad": (64, "a big gila monster and toad hybrid with beaded black and orange scales, a wide toad mouth and mushroom caps"),
    "murkbat": (64, "a moth and bat hybrid with dusty grey green moth wings, bat ears and a fuzzy body"),
    "anglenewt": (64, "an anglerfish and newt hybrid with a glowing lure on its head, a long newt tail and a toothy grin"),
    "sluglet": (64, "a small slug and newt hybrid with a glossy purple body, little newt legs and eye stalks"),
    "slimewt": (64, "a slug and newt hybrid with a long glossy body, frilly newt crest and dripping slime"),
    "axolurk": (64, "a huge axolotl and slug hybrid with pink feathery gills, a slimy spotted body and a toothy smile"),
    "skeetbird": (64, "a mosquito and hummingbird hybrid with a long needle beak, buzzing wings and striped legs"),
    "needlehawk": (64, "a mosquito and hawk hybrid with a long piercing beak, see through insect wings and hooked talons"),
    "whiskerhog": (64, "a catfish and warthog hybrid with long whiskers, a fishy tail and mud caked tusks"),
    "silthog": (64, "a big warthog and catfish hybrid with long barbels, huge muddy tusks and a scaly fish tail"),
    "mudillo": (64, "an armadillo and baby alligator hybrid with mud caked armor bands and a toothy snout"),
    "murkadillo": (64, "an alligator and giant armadillo hybrid with heavy mossy armor bands, a long gator jaw and brass studs"),
    "carrioncroc": (64, "a legendary crocodile and vulture hybrid with ragged black vulture wings, a bony crest and swamp moss, majestic"),
    "bogwidow": (64, "a legendary black widow spider and frog hybrid with a glossy red marked body, frog legs and webbed feet, majestic"),
    "rhinoram": (64, "a rhinoceros and mountain ram hybrid with a stone nose horn, curled ram horns and a woolly mane"),
    "scalecondor": (64, "a condor and pangolin hybrid with overlapping stone scales on its wings and a bald red head"),
    "markhorn": (64, "a markhor goat and rhino beetle hybrid with long corkscrew horns and a shiny beetle shell back"),
    "summitibex": (64, "an ibex and golden eagle hybrid with huge ridged horns, eagle wings folded on its back and sure hooves"),
    "pikadillo": (64, "a small pika and armadillo hybrid with round ears and pebbly armor bands"),
    "boulderdillo": (64, "a big armadillo and pika hybrid with boulder like armor bands, round fuzzy ears and brass knuckle claws"),
    "drillrat": (64, "a naked mole rat and rhino beetle hybrid with a drill shaped horn and a hard shell back"),
    "augerhino": (64, "a rhinoceros beetle and mole rat hybrid with a spinning auger horn, heavy shell plates and digging claws"),
    "cliffkite": (64, "a kite bird and chuckwalla lizard hybrid with scaly wings, a spiky tail and sharp talons"),
    "talonwalla": (64, "a big chuckwalla lizard and eagle hybrid with rocky scales, broad wings and huge crushing talons"),
    "shaleyak": (64, "a yak and pangolin hybrid with shaggy wool and stone scales on its back and short horns"),
    "plateyak": (64, "a huge yak and pangolin hybrid with heavy slate armor scales over shaggy wool, big horns and brass bells"),
    "gravelbat": (64, "a cave bat and pangolin hybrid with gravel like scales on its back and big bat ears"),
    "stormrhino": (64, "a legendary rhinoceros and eagle hybrid with great storm grey eagle wings, a stone horn crackling with lightning, majestic"),
    "obsidiwolf": (64, "a legendary wolf and pangolin hybrid covered in black obsidian scales with glowing orange cracks, majestic"),
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

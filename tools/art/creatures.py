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
    # ----- Milestone 3: Snow and Jungle -----
    "blizzfox": (64, "an arctic fox and snowy owl hybrid with white fluffy fur, owl wing feathers and big amber eyes"),
    "owlvix": (64, "a snowy owl and arctic vixen hybrid with large white wings, a long fox tail and frosted feathers"),
    "sleetstoat": (64, "a stoat and mouse hybrid with a white ermine winter coat, a black tail tip and frosty whiskers"),
    "ptarmhare": (64, "a snowshoe hare and ptarmigan hybrid with feathered white wings, long ears and fluffy feathered feet"),
    "pingtusk": (64, "a penguin and walrus hybrid with small tusks, a round tuxedo body and whiskers"),
    "tuskemperor": (64, "a huge emperor penguin and walrus hybrid with long ivory tusks, a golden neck patch and brass tusk rings"),
    "sleetkit": (64, "a snow leopard cub and arctic hare hybrid with spotted grey fur, long ears and a huge fluffy tail"),
    "frostpard": (64, "a snow leopard and arctic hare hybrid with smoky spotted fur, long tufted ears and frost on its whiskers"),
    "woolcalf": (64, "a musk ox calf and armadillo hybrid with shaggy brown wool over little armor bands and stubby horns"),
    "glaciox": (64, "a huge musk ox and tortoise hybrid with icy wool, a frozen glacier shell and sweeping horns with brass caps"),
    "honkflake": (64, "a snow goose and puffin hybrid with a white body, black wingtips and a bright orange beak"),
    "squallswan": (64, "a whooper swan and snow goose hybrid with huge frosted white wings, a long neck and a crest of ice feathers"),
    "rimeseal": (64, "a harp seal pup and snowshoe hare hybrid with fluffy white fur, long hare ears and big dark eyes"),
    "boreowl": (64, "a legendary great grey owl and wolverine hybrid with frost blue wings, a wolverine body and glowing aurora eyes, majestic"),
    "glacimusk": (64, "a legendary woolly mammoth and musk ox hybrid with giant frozen tusks, icicle wool and a glacier on its back, majestic"),
    "chamegecko": (64, "a chameleon and gecko hybrid with color shifting green skin, curled tail and sticky toe pads"),
    "crestlisk": (64, "a basilisk lizard and chameleon hybrid with a tall sail crest, a curled tail and swiveling eyes"),
    "toucaw": (64, "a toucan and macaw hybrid with a huge banana colored beak and red blue and yellow feathers"),
    "swingibbon": (64, "a gibbon and spider monkey hybrid with very long arms, a gripping tail and leafy vines wrapped around it"),
    "flitfrog": (64, "a tree frog and flying squirrel hybrid with red eyes and gliding skin flaps between its legs"),
    "sailfrog": (64, "a big tree frog and flying squirrel hybrid with wide gliding sails, bright red eyes and sticky toe pads"),
    "slothant": (64, "a sloth and anteater hybrid with long hook claws, a long snout and shaggy fur with green moss"),
    "hookclaw": (64, "a giant anteater and ground sloth hybrid with huge hook claws, a long tongue and shaggy moss covered fur"),
    "mantokapi": (64, "an okapi and praying mantis hybrid with striped legs, mantis scythe forearms and big ears"),
    "batemur": (64, "a ring tailed lemur and fruit bat hybrid with leathery wings, a striped tail and big orange eyes"),
    "ayewing": (64, "an aye aye lemur and bat hybrid with large leathery wings, a long thin finger, huge eyes and a bushy tail"),
    "tarsifly": (64, "a tarsier and firefly hybrid with enormous round eyes, tiny clinging hands and a glowing abdomen"),
    "capyscarab": (64, "a capybara and jewel scarab beetle hybrid with a calm face and a shiny green blue beetle shell back"),
    "harpyjag": (64, "a legendary harpy eagle and jaguar hybrid with a spotted golden jaguar body, huge eagle wings and a feather crest, majestic"),
    "silverhide": (64, "a legendary silverback gorilla and pangolin hybrid with silver scale armor over dark fur and huge knuckles, majestic"),
    "thornrat": (64, "a rat and porcupine hybrid with sooty grey quills, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "blightquill": (64, "a porcupine and wild boar hybrid with long black quills tipped in crystal and curved tusks, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "ashbadger": (64, "a badger and armadillo hybrid with soot-black armor bands and a white-striped face, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "gloomfawn": (64, "a fawn and fruit bat hybrid with leathery wing-ears, dappled grey fur and tiny antler nubs, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "wraithelk": (64, "a huge elk and raven hybrid with black feathered shoulders, crystal-crusted antlers and a raven's beak-like muzzle, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "murkotter": (64, "an otter and eel hybrid with slick ink-black fur and a long finned tail, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "lampreotter": (64, "a giant otter and lamprey hybrid with a round toothed mouth, eel-like fins and dark wet fur, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "ashheron": (64, "a heron and vulture hybrid with ash-grey plumage, a bare dark neck and long stilt legs, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "voidkoi": (64, "a koi and anglerfish hybrid with black-gold scales and a glowing violet lure, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "gloomwhale": (64, "a whale and anglerfish hybrid with a huge toothy jaw, a violet lantern lure and barnacled dark skin, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "rotnewt": (64, "a newt and scorpion hybrid with mottled black skin and a small curled stinger tail, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "stingmander": (64, "a salamander and scorpion hybrid with glossy black-violet skin, pincers and a long venomous tail, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "leechmole": (64, "a mole and leech hybrid with ringed slimy dark skin, a sucker-mouth snout and digging claws, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "carrionstork": (64, "a marabou stork and vulture hybrid with a bald dark head, a heavy beak and ragged black wings, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "plaguebat": (64, "a vampire bat and moth hybrid with dusty purple moth wings, fuzzy antennae and tiny fangs, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "cindergoat": (64, "a mountain goat and armadillo hybrid with obsidian armor bands and short curled horns, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "obsidiram": (64, "a bighorn ram and pangolin hybrid with overlapping obsidian scales and huge spiral glassy horns, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "shardhawk": (64, "a hawk and scorpion hybrid with dark speckled feathers and a crystal stinger tail, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "drillrhino": (64, "a rhinoceros and star-nosed mole hybrid with digging claws, a spiral crystal drill horn and grey hide, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "scorbison": (64, "a giant bison and scorpion hybrid with a shaggy black mane, chitin plates and a crystal-tipped stinger tail, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "ashkit": (64, "a fox kit and crow hybrid with ash-grey fur and little black wings, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "crowvix": (64, "an arctic fox and raven hybrid with sleek black-grey fur, glossy raven wings and frost-rimed whiskers, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "sootseal": (64, "a seal and tortoise hybrid with a frosted dark shell and grey speckled blubber, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "nightshrew": (64, "a shrew and bat hybrid with frosty grey fur, leathery wings and a long twitchy snout, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "lupemoose": (64, "a wolf and moose hybrid with a gaunt black-furred body, wolf jaws and frost-blackened palmate antlers, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "howlbat": (64, "a howler monkey and vampire bat hybrid with dark fur, wing-membrane arms and a prehensile tail, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "vampape": (64, "a gorilla and vampire bat hybrid with a silver-black back, huge leathery wings and tiny fangs, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "mantigecko": (64, "a gecko and praying mantis hybrid with ashy green scales and folded scythe forelegs, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "cobrapard": (64, "a black panther and king cobra hybrid with a flared scaly hood, sleek dark fur and a long snake tail, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "mandrilion": (64, "a legendary mandrill and lion hybrid with a shaggy black mane, a vivid violet and blue mandrill face and long fangs, majestic, with jagged violet-black dark dust crystals growing from its back, ashen fur and faintly glowing purple eyes"),
    "duskmaw": (80, "a giant boss black panther and vampire bat hybrid with huge leathery bat wings, glowing violet eyes and jagged dark dust crystals along its spine, huge and menacing"),
    "dawnhare": (64, "a hare and fawn hybrid with long gold-tipped ears and tiny velvet antlers, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "solstag": (64, "a stag and snowshoe hare hybrid with long ears, gold velvet antlers shaped like a halo and cream fur, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "honeybruin": (64, "a sun bear and honeybee hybrid with striped golden fur, small translucent wings and fuzzy antennae, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "glintbeetle": (64, "a hedgehog and rhinoceros beetle hybrid with a mirror-bright golden shell and soft spines, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "aurelion": (64, "a legendary lion and stag hybrid with a blazing golden mane, branching antlers of light and a white coat, majestic, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "shimmerpup": (64, "a seal pup and swan hybrid with white fluffy down, little swan wings and flippers, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "seraseal": (64, "an elegant seal and swan hybrid with a long white swan neck, gleaming wings and a sleek silver body, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "glimmerray": (64, "a stingray and dragonfly hybrid with shimmering gold wing fins and a glowing tail, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "pearlotter": (64, "a sea otter and oyster hybrid with a pearly shell on its back and glossy cream fur, holding a glowing pearl, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "lumidolphin": (64, "a legendary dolphin and white heron hybrid with long feathered fins, a crest of gold plumes and a glowing body, majestic, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "lumifrog": (64, "a tree frog and firefly hybrid with a glowing gold belly lantern and lacy wings, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "lanternewt": (64, "a newt and firefly hybrid with glowing lantern bulbs along its tail, gold-spotted skin and lacy wings, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "sunsnapper": (64, "a snapping turtle and honey badger hybrid with an amber resin shell and a fierce striped face, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "goldleech": (64, "a leech and goldfish hybrid with shimmering orange-gold scales, fan fins and a round sucker mouth, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "hippofly": (64, "a hippopotamus and dragonfly hybrid with four iridescent dragonfly wings, a round pink-gold body and big gentle eyes, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "quartzmot": (64, "a marmot and hermit crab hybrid carrying a big clear quartz crystal shell, with golden whiskers and small pincers, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "halotaur": (64, "a takin and tortoise hybrid with a golden sunstone shell, shaggy cream wool and thick curved horns, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "prismfalcon": (64, "a falcon and hummingbird hybrid with iridescent prism feathers and a long needle beak, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "lynxcrest": (64, "a lynx and golden eagle hybrid with tufted ears, gold feathered wings and a spotted cream coat, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "sunmammoth": (64, "a legendary woolly mammoth and golden eagle hybrid with feathered gold wings on its shoulders and shining tusks, majestic, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "lumming": (64, "a lemming and snow bunting hybrid with round sparkling white fur and tiny feathered wings, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "aurorlynx": (64, "a lynx and snowy owl hybrid with white feathered wings, tufted ears and shimmering aurora-colored fur, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "candlepine": (64, "a beluga and porcupine hybrid with a pale white body and soft frosted quills, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "chimecrane": (64, "a red-crowned crane and arctic fox hybrid with white plumage, a fox tail and a bright red crown, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "caribear": (64, "a polar bear and caribou hybrid with cream fur and tall branching antlers frosted in light, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "sunmarmoset": (64, "a golden lion tamarin and sunbird hybrid with a fiery gold mane and bright tail feathers, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "lionbaboon": (64, "a gelada baboon and lion hybrid with a thick golden mane, a bright chest patch and strong long arms, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "quetzaloth": (64, "a sloth and quetzal hybrid with emerald and gold tail plumes and long hooked claws, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "butterpard": (64, "a clouded leopard and morpho butterfly hybrid with huge iridescent gold-blue butterfly wings and spotted fur, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "solaconda": (64, "a legendary anaconda and macaw hybrid with golden scales, a crest of bright red and gold feathers and feathered wings, majestic, with smooth pale gold light dust crystals growing from its back, soft glowing markings and bright warm eyes"),
    "dawnshell": (80, "a giant boss sea turtle and peacock hybrid with a huge fan of glowing golden peacock feathers rising from its shell and pale gold light crystals, huge and radiant"),
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

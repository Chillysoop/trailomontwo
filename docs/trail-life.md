# Trail life: the feel of the road

How Trailomon captures the old wagon-trail feeling while travelling, in its own way.
This is the design behind the travel screen, trail events, settlements and ambient world.

## What makes a wagon-trail game feel like one

Research notes from the classic wagon-trail genre and its modern descendants
(roguelite caravan games, Astronarch-style auto-battlers on a map):

1. **The road has a rhythm.** Days tick by on their own. You watch the wagon roll and react.
   The tension comes from slow resource drain, not from constant menus.
2. **A few dials you set and live with.** Pace and rations are the famous pair. They are
   tiny decisions with ongoing consequences, and they make the player feel like the trail boss.
3. **Constant one-line stories.** "You find wild fruit." "A wheel breaks." "Lose the trail: 1 day."
   Most of them need no decision. They make every day different and build a story you retell.
4. **Real choices at the big moments.** River crossings are the signature: ford it, float it,
   pay the ferry, or wait. Each has a cost you can see and a risk you can judge.
5. **Weather is the world talking.** Rain, heat and snow change what each day costs.
6. **You are not alone out there.** Other travellers, traders, graves of those who didn't make it,
   settlements to resupply at. The road feels used.
7. **Arrival is a relief.** Towns are safe ground: trade, rumors about the road ahead, a rest.

## How Trailomon does it (original twist)

Our crew is a team of Trailomon, so **every road moment asks "who on the team can handle this?"**
That is the overlap with the rest of the game:

| Trail system | Touches |
| --- | --- |
| Trail jobs (capabilities: Clear, Strength, Float, Light, Scout, Steady, Guard, Cold, Heal, Forage) | Who helps in events and moments. The helper earns job experience toward its levels. |
| Habitats | Home ground: a helper on its own habitat's terrain gets +1 rank. Weather favours a habitat (rain = River, fog = Swamp, snow = Snow, heat = Jungle, storm = Mountain, clear = Forest) for +1 rank too. Wild Trailomon of the road's habitat graze in the background. |
| Levels | Helpers gain job XP. Trainers on the road offer sparring fights. |
| Dust | Shrines, glinting streams and old stones give Light or Dark dust. |
| Techniques | Hermits and traders teach or sell technique scrolls. |
| Battle items | Traders sell them, abandoned wagons hold them. |
| Recruiting | Trapped or orphaned wild Trailomon can be freed or fed, and offer to join. |
| Haulers | Pace changes how tired they get. Mud, slopes and stampedes test Strength. |
| Supplies | Food, water, repair kits and the new coin (scrip) flow through everything. |
| Battles | Bandit toll roads and trainer challenges can turn into fights. Fog raises ambush chance. |

## Systems

**Weather** (rolled each day from the terrain's table, icon in the HUD):
Clear, Rain (+water, +wear), Fog (more ambushes), Storm (+wear, +tired), Heat (+water use),
Cold (+food use, +tired). Each weather favours one habitat's helpers.

**Pace**: Easy (slower, haulers rest as they walk, team heals faster), Steady, Hard
(faster, haulers tire much faster, more wear). **Rations**: Full (crew heals, costs more food),
Normal, Thin (saves food, crew health drops).

**Trail fever**: the crew can fall ill. It drains health each day until cured by resting or a healer.

**Trail moments** (no decision, about one a day): an icon toast with a portrait of the Trailomon
involved, e.g. Rimehare sniffs out berries +4 food. Finds, mishaps, sights and graves.

**Trail events** (a decision card): 20+ events across five kinds (wildlife, travellers, hazards,
finds, shrines). Every event has a safe choice with a visible cost, and at least one choice that
a Trailomon can make better. Choices show their cost and reward as icons, and the result shows
what changed as icons.

**Settlements**: every stop has a kind (town, village, waystation, ruins) with a trade stall
(food, water, repair kits, battle items, techniques, dust, priced in coins), one rumor about the
road ahead, and buildings around the wagon.

**Ambient world**: weather particles and sky tint, birds, wild Trailomon in the distance,
other travellers and traders passing on the road, roadside graves, signposts, campfires and
abandoned wagons scrolling past.

## Text budget

- Event text: one sentence. Choice labels: two to four words plus icons.
- Results: icon deltas (`-10 food`, `+1 Light dust`), one short line at most.
- Moments: icon + portrait + up to five words.
- Everything with an icon has a hover tip, so the screen stays short.

## Overworld map

Every caravan gets its own big generated overworld (`src/core/data/world_map.gd`): 14 columns of
stops from east to west, 4 to 6 stops per column, roads to one or two stops in the next column,
side roads, and dead-end lookouts and ruins. The land is split into 14 named regions, each a
terrain (Forest, Hills, River, Swamp, Mountain) that sets the road's terrain, the stops' kinds
and the names. Big towns sit at both edges.

- **Crossings**: crossing 1 runs east to west, crossing 2 west to east, and so on, each from a
  different edge town. The map, the fog you lifted and the Trailomon you met carry over.
- **Fog of war**: you see the stops one road out from where you are. A scout of job rank 4+ sees
  two roads out, and a lookout three. Each stop's rumor lifts the fog over one stop further on.
  The goal is always marked.
- **Forks**: click a road in the junction panel or a stop on either map to pick it.
- **Creatures**: a region shows a Trailomon only once you've met it there (battle or recruit),
  with a "?" for the ones still unmet. Wild Trailomon on the roadside are only species you've met.
- **Map views**: the small map in the Route tab, a minimap in the corner while travelling, and
  the full overworld (map button in the top bar, drag to pan, wheel to zoom). Travel pauses while
  it is open.
- **Balance**: a world crossing is about 13 roads and 25 to 30 days, so food and water at stops
  are cheaper than on the test route and a caravan sets out with 70 coins. `tools/sim/world_sim.gd`
  plays 120 crossings per pace, buying food when low and repairing breaks: 95-100% arrive.
- Tests keep using the small hand-made route (`Expedition.default_map = "test"`).

## Region art

Each terrain has its own painted scenery, made by `tools/art/regions.py` from Sprite Fusion props
(`tools/art/props.py`): a travel set (`assets/backgrounds/travel/<terrain>/`: sky, mountains, far
tree line, ground with the trail, foreground) and a battle backdrop (`battle/<terrain>_back.png`
and `_front.png`). Hills get rolling downs, rivers and swamps a band of water behind the road,
swamps a murky sky and dark mud, mountains big snowy peaks and grey scree.

- **Landmarks**: every region name has its own landmark (`assets/props/lm_*.png`, 20 in all, e.g.
  a lantern tree in Lanternwood, a cog spire in the Cogspires, a sunken locomotive in the
  Murkfens). It stands far off between the mountains and the tree line on the road, and behind
  the battlefield. `WorldMap.landmark(id)` picks it; `Expedition.scenery()` says what to show.
- **Stops**: town gates, lookout towers, ruined arches, roadside inns and (in the mountains) log
  mining cabins, plus terrain swaps (stilt houses in the swamp).
- **Roadside**: each terrain has its own props scrolling past (fences and heather, reeds and
  jetties, mangroves and glowing mushrooms, pines and mine carts).

## Dust biomes (late game)

From crossing 3, dust seeps over the overworld. Regions turn into the **Blight** (Dark dust:
withered black trees, violet crystals, ash) or the **Glow** (Light dust: white-gold trees,
radiant crystals, glowing flowers). One of each on crossings 3 and 4, two from crossing 5,
three from crossing 7. Always the same regions for a map, never the edge columns, never undone.

- **Roads** into a biome take its terrain and +1 risk. Wild packs there are the biome's own
  Trailomon (Species `"biome"` key, from the battle thread's roster); until they land, roads use
  the any-terrain packs.
- **Weather**: Blight has ashfall (-3 crew health a day, tired haulers, ambushes), fog and storms.
  Glow has shimmer (+3 crew health a day, haulers rest as they walk), clear skies and rain.
- **Dust**: wins give +1 Dark dust in the Blight and +1 Light dust in the Glow. Blight stalls sell
  Dark dust cheap (8 coins, 3 in stock).
- **Stops**: warden camps (Light dust wards, medicine) and ruins in the Blight; sanctums in the
  Glow.
- **Events**: a dark seam, an ash squall (burn a Light dust ward), a sick warden; a glimmer spring,
  a crystal grove, dust pilgrims (who cleanse 1 Dark into 2 Light). Moments: dust drifts, ash
  coughs, dead lanterns, drifting Light motes, glowing flowers.
- **Landmarks**: the Ashen Hollow, Duskmire Scar, the Withering; Lumen Meadows, the Shining
  Steppe, Halo Glade.
- Balance: `world_sim.gd -- crossing 7` (three of each biome): 99-120 of 120 crossings arrive.

## Snow and Jungle

Two more ordinary terrains join the overworld, so every habitat has home ground: **Snow** (snowy
firs, ice, drifts, sleds; cold weather most days; Snow Trailomon on home ground) and **Jungle**
(palms, giant leaves, stone idols, vine arches; heat and rain; Jungle Trailomon on home ground).
Regions are now drawn from seven terrains. Landmarks: the White Reach (frozen airship),
Frostfang Pass, Rimeholt, the Hoarwood; the Emerald Canopy, Vinehold, the Sunken Gardens,
Parrotspire. Snow lodges and treehouses replace huts there. Events: frozen lake, snow slide,
rope bridge, vine-choked temple; moments: snow melt, frost bite, fruit haul, vine snag.

## Gear (wave 1 of the wagon-trail ideas)

Gear picks matter: what you pack decides what trouble you can handle.

- **Weight limit**: the wagon holds 300. Cargo, food (4 per 10), water (6 per 10), spare parts and
  curiosities all count. A heavier wagon wears faster and is harder to pull (the load counts 60% for
  hauling). Finds that don't fit are left behind ("No room for 20 food").
- **Spare parts** replace repair kits: spare axle (20), spare harness (8), canopy canvas (10). The
  right spare fixes its part in a day. Without it a Trailomon with the part's job (Strength for the
  axle, Steady for the harness, Guard for the canopy) jury-rigs it: one day at rank 3+, two days
  otherwise, and it costs integrity. With nothing broken, Repair is a one-day tune-up (-25 wear).
  Some hazard failures now break a part (rockslide, bog, ford, storm, stampede).
- **Outfitter**: a world crossing starts in the start town with an empty wagon and at least 135
  coins. The stall there is the outfitter: big stock, spare parts, curiosities, battle items, and
  anything can be handed back for a full refund until you set out. Two shopkeepers alternate:
  Hob Ferrule the wagonwright (east, odd crossings) and Marrow Bell the provisioner (west). Each gives
  one tip about the map's commonest terrain and has a biased "Pack it for me" kit.
- **Curiosities** (one of each): lucky cog (stops the first breakdown), reed pipe (better rest
  days), ember kettle (no extra food on cold days), brass spyglass (+1 road of sight).
- **Barter**: a traveller wants one thing you carry (a spare, food, water, a battle item, Light
  dust) and offers something you're short of. Built on the spot from your wagon.
- **Cargo pays**: delivered cargo pays a tenth of its value in coins at the end of a crossing.
- Code: `src/core/data/outfitter.gd`, `Expedition` (spares, curios, load_weight, repair_plan,
  outfitting, sell_back, pack_for_me, make_barter), `Wagon.SPARES`. Tests: `tests/core/test_gear.gd`.
  Screens: `tools/shots/gear_shots.gd`.

## Paths (wave 2 of the wagon-trail ideas)

Paths matter: which road you take, and when, decides how the crossing goes.

- **Season clock**: every world crossing has a frost day, set from the quickest route (x1.6, +12
  days). Six days before it the weather turns colder and stalls charge +1 for food and water. From
  frost day on, most days are cold or stormy, everyone loses 2 health and haulers tire every day,
  and stalls charge +2. The HUD shows the countdown; route cards say when you'd reach the goal at
  the soonest and warn when that's after the frost. Resting is never free.
- **Road info**: route buttons show risk marks, "ford" for a river and "rough" for a shortcut.
  Each map has a few **rough tracks** that skip a layer: 3 days, risk 3, harder to pull.
- **Rivers**: every River road starts with a crossing. Depth (shallow to torrent) comes from the
  road's risk and the weather. Ford it (Strength), float it (Float), freeze a bridge on cold days
  (Cold), take the ferry where people live (coins), or wait a day for the water to drop. Shallow
  water can be waded slowly. Other Trailomon **assist** with their jobs: a Scout finds a shallower
  line (+3), a Guard leans in on the ford, a Steady one keeps the float upright (+2). Failure loses
  cargo and food and can break the canopy or axle.
- **Panning**: a glinting stream on River, Mountain, Snow and Hills roads. Pan 1 day or 3 days for
  coins (Scout check).
- **Hunting**: at any wild stop (not towns or posts), once per stop, spend a day hunting a grazing
  herd. It's an auto-battle with different rules: prey never fight back and bolt one by one (sooner
  if hit but not knocked out), one charger at the front stands and fights, and after 25 seconds the
  rest scatter. Each creature knocked out is food (6/10/16 by size, the charger double), if it fits
  in the wagon. Battle items stay packed and the wagon stays quiet. Everyone gains 25 experience.
  Tune with `tools/sim/hunt_sim.gd`.
- **Delivery jobs**: towns, posts, villages and stilt villages have a job board with one delivery
  to a stop closer to the goal: weight 15-35, pay 8 + 3 per day of road + 2 per crossing, due by
  the quickest time x1.4 + 2 days. Paid on arrival, half if late. It's cargo: it can be dropped or
  lost in a river.
- Code: `src/core/trail/rivers.gd`, `WorldMap` (rough tracks, shortest_days, has_ferry),
  `Expedition` (season, make_river, best_helper assists, hunt_block/start_hunt/_finish_hunt,
  delivery_offer/take_delivery), `Battle` hunt mode (prey, bolt_at, hunt_bag).
  Tests: `tests/core/test_paths.gd`, `tests/core/test_hunt.gd`.

## Stakes and story (wave 3 of the wagon-trail ideas)

- **Ailments and the trail doctor**: about 3.5% a day on the road (more on thin rations, in swamps and
  jungles, and in the frost) one Trailomon catches something odd for 4 days: rust itch (pulls at half
  strength), moss lung (+8 tiredness a day), spore sneezes (no trail jobs) or bramble burrs (loses 6%
  health a day). The card: a Heal Trailomon tends it, a herbal remedy (Forage), a pinch of Light
  dust, rest it a day, or press on (30% it spreads, else 40% it lasts 3 days longer). Resting at a
  stop takes a day off. Code: `src/core/trail/ailments.gd`.
- **Landmark cards**: the first stop in each region shows its landmark's card (name, day, one
  line) with a small reward: dust, health, water, food, coins, wear off or experience.
  Code: `src/core/data/landmarks.gd`.
- **The guardian road**: the guardian's card offers Fight, the toll road around (30 + 6 per crossing
  coins and 2 days) or run the rapids (Float check, Steady and Scout assist; a wreck loses supplies
  and the guardian fight starts as an ambush). Going around gives no guardian rewards.
- **Arrival score and scrapbook**: on arrival, a score from team, health, supplies, coins, the
  wagon, days before the frost, how you passed the guardian and deliveries on time, with a rank
  (Greenhorn, Trail hand, Wagon master, Trail legend) and your best earlier score. The scrapbook lists
  the crossing's moments: ailments, landmarks, recruits, deliveries, the finale.
- **Graves from your runs**: when a caravan fails you write its epitaph. The stone is kept in
  `user://graves.json` (shared by all slots) and turns up as a roadside grave on the same crossing in
  later runs (60% of graves there, when you have one). Code: `src/core/trail/graves.gd`.
- Tests: `tests/core/test_stakes.gd`. Shots: `tools/shots/stakes_shots.gd`.

## People on the trail (wave 4 of the wagon-trail ideas)

- **Pip Gasket's workshop** (`src/core/data/inventor.gd`). Each crossing, Pip sets up at one
  stop (a town, post, village, waystation or stilt village, never the start or goal; picked from
  the map seed and the crossing number). The outfitter and the locals say where, and it shows on
  the map. Pip sells six permanent wagon upgrades, kept in `Expedition.upgrades` and carried
  between crossings:
  - spring wheels (wear x0.8), cargo rack (+40 room, `Expedition.capacity()`),
  - dew still (+2 water a travel day), float tanks (+3 on Float checks, rivers and rapids),
  - brass horn (wild packs x0.6), lantern mast (+1 sight through the fog).
  Prices are 30 to 50 coins, +5 each crossing.
- **Locals** (`src/core/trail/folk.gd`). Two named locals at every stop, each with a tip drawn
  from the real game state: what the guardian fears (the habitat strong against its boss), the
  frost day, the dangerous road out, a river's depth, Pip's workshop, whether there's game.
  About one tip in four is wrong (`Folk.WRONG_CHANCE`). What they said is kept per stop
  (`Expedition.folk_heard`), so it doesn't change when you come back.
- **The Fernwicks** (`src/core/trail/family.gd`). Bram, Ottilie and Wren, met once per crossing
  (12% a road day from the second road, world map only). Each meeting is the next beat: the
  wagon in the mud, the split water barrel, Wren's fever, a shared fire, then old friends.
  Choices change `family_trust` (fx key `trust`); at 3+ trust the old-friends beat brings a gift.
  `family_stage` and `family_trust` carry between crossings.
- Tests: `tests/core/test_people.gd`. Shots: `tools/shots/people_shots.gd`.

## Camp life (wave 5 of the wagon-trail ideas)

All in `src/core/trail/camp.gd` (class Camp), wired into `Expedition`.
- **Morale** (`Expedition.morale`, 0-100, starts at 70 every crossing). Bands: Spirited 75+
  (+1 on every trail-job check), Steady 50+, Low 25+, Grim (-1 on checks, haulers +4 tiredness a
  day). It drifts daily: -2 a road day, plus thin/full rations, a grueling pace, frost, storms, sickness and
  hunger, and moves with wins, defeats, catches, hunts, landmarks, deliveries, breakdowns, rest,
  meals, the campfire and the Fernwicks. Other systems call `change_morale(amount, reason)`.
  Shown in the HUD next to health.
- **Pantry and cooking**: ingredients (herbs, mushrooms, berries, fish; at most 6) go in
  `Expedition.pantry` (carried between crossings). At a stop, Cook makes the best recipe the
  pantry allows, once per stop, for 5 food: morale, and the best recipes heal too.
- **Foraging**: at any stop but a town, once per stop, free. A Forage check fills the pantry
  with what grows in that region. 35% of the time there's a plant too: unknown plants are a
  gamble (good: food and morale; bad: fever), shown as "who knows?". Eating one teaches it
  (`Expedition.known_plants`, carried over); a Forage Trailomon of rank 3+ can tell them anyway.
- **Campfire**: after a rest (once per stop) a card with a tale, two Trailomon bonding (+10 XP
  each), and a choice: another story (morale), a song (morale, less tiredness) or bed (health).
  Camp cards left open are dropped when you set off.
- Fixed the wagon tab's action row overflowing: the Healer button moved to the camp row.
- Tests: `tests/core/test_camp.gd`. Shots: `tools/shots/camp_shots.gd`.

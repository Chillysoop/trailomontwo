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

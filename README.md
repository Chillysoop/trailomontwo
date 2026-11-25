# Trailomon

A single-player PC expedition RPG: cross a dangerous continent with a wagon, a growing team of creatures, and a cargo whose value may be destroying the wilderness.

Built with Godot 4. Design and roadmap docs live in the Trailomon project.

## Running it

1. Install [Godot 4.7.2](https://godotengine.org/download) (standard build, not .NET).
2. Open `project.godot` in Godot and press Play (F5).

The title screen leads to the expedition (the playable crossing), a practice battle, and the travel preview.

## Battles

Battles happen on the trail (wild packs, more often on risky routes) and once on the last stretch to Westwatch, where the Hollow Stag waits with its pack.

- **Lineup:** both teams stand on 2x3 grids. Click one of your creatures, then a cell, to move or swap it. Click any creature to read its stats and abilities. Habitat bonuses (two or more creatures of the same habitat) update as you arrange.
- **Combat:** the grids hide and the fight runs by itself. Every creature has its own basic attack (white attack bar), a passive, and an ultimate (gold bar that fills from attacking and being hit). Normal attacks hit the nearest row that still has creatures (same lane first), so the front row shields the second; only moves that name a row (reach) go over it, and taunt pulls attacks. Hover a creature mid-fight to see a red line to its current target. The wagon throws a small volley. The top-right window totals damage (split into basic, ultimate and passive), shielding, healing or damage taken. Space pauses; the speed button cycles 1x, 2x, 4x; Retreat pulls back after 3 seconds.
- **Habitats:** each habitat has its own way of fighting (Forest outlasts, River flows, Swamp rots, Mountain crushes, Snow chills and speeds, Jungle reaches). See [docs/habitats.md](docs/habitats.md), the guide for designing new creatures.
- **Aftermath:** health carries over between battles. Knocked-out creatures can't fight, haul or help with events until you rest a day. Losing lets the enemy reach the wagon (integrity and supplies).
- **Levels:** everyone who fought gains experience (more for a win or the guardian). Each level-up offers two options and you pick one. Most are stat boosts (two random stats, each with a rarity from Common to Mythic; rarer means bigger). At levels 3, 6 and 9 it's a new move instead: one from each of the creature's two archetypes (`src/core/battle/move_pool.gd`), no rarity. Pick from the Companions screen, the travel bar or after a battle (`src/ui/level_up_screen.gd`; rules in `src/core/expedition/leveling.gd`).
- **Battle items:** before a fight, put up to 3 consumables in the item slots (above the Fight button). Each boosts the whole team or hinders the foes for that battle, and is used up afterwards. A slot keeps its item while you have more. Wins drop items half the time (the guardian always drops 2). Rules in `src/core/battle/battle_items.gd`, slots UI in `src/ui/item_slots.gd`.
- **Techniques:** one-use scrolls that teach a move (Companions > Techniques). A Trailomon can learn one if it shares a habitat with the move's species, into its equipped slot or its memory slot. Wins sometimes drop them (20%), and the guardian always does.
- **Dust:** permanent boosts (Companions > Light / Dark). Light dust adds a modest boost to the stat you pick, sized as a share of that Trailomon's own stat. Dark dust adds a bigger one, paid for by the opposite stat (Attack and Defense trade, Max HP and Speed trade). Each Trailomon can take 5 dust. Every win gathers Light dust; strong fights and the guardian give Dark (`src/core/expedition/dust.gd`).
- **Recruiting and storage:** after a win, a wild creature from the pack sometimes offers to join (35%; never the boss or a species you already have). Take it in from the aftermath and it goes to storage (up to 9). On the Companions screen, click a stored Trailomon, then a team card, to swap them.
- **Memory slots:** a new move can go straight into its slot (the old one moves to memory) or wait in memory. Click a filled memory slot on the Companions screen to swap between battles.

- **Scaling:** foes grow 1.5% for each level your lineup averages above 1, on top of the route's risk, so a levelled team still gets a real fight.

Rules live in `src/core/battle/` (pure, tested headless); the screen is `src/battle/battle_screen.gd`.

## Layout

| Folder | What's in it |
| --- | --- |
| `src/core/rules/` | Pure game rules with no scene code (check odds, hauling) |
| `src/core/battle/` | Battle rules: stats, abilities, synergies, wild packs, the simulation |
| `src/battle/` | Battle formation layout and the battle screen |
| `src/world/` | Travel scenery and the travel preview |
| `src/ui/` | Title screen and shared UI helpers |
| `scenes/` | Scene files (each just attaches its script) |
| `assets/` | Creature, wagon and prop sprites (Sprite Fusion) and background layers |
| `tools/art/` | Python scripts that build the background layers from the props |
| `tests/` | Headless unit tests and a scene smoke test |

## Tests

```
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/smoke_scenes.gd
```

CI runs these on every pull request and exports a Windows build you can download from the run's artifacts.

## Rebuilding background layers

```
python3 tools/art/layers.py assets/backgrounds
```

Needs Python 3 with Pillow and numpy. API keys for art and audio tools are read from environment variables and must never be committed.

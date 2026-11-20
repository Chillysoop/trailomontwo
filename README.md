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
- **Combat:** the grids hide and the fight runs by itself. Normal attacks hit the nearest row that still has creatures (same lane first), so the front row shields the second. Abilities fire on their own cooldowns. The wagon throws a small volley. Space pauses; the speed button cycles 1x, 2x, 4x; Retreat pulls back after 3 seconds.
- **Aftermath:** health carries over between battles. Knocked-out creatures can't fight, haul or help with events until you rest a day. Losing lets the enemy reach the wagon (integrity and supplies).

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

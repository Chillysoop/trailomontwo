# Trailomon

A single-player PC expedition RPG: cross a dangerous continent with a wagon, a growing team of creatures, and a cargo whose value may be destroying the wilderness.

Built with Godot 4. Design and roadmap docs live in the Trailomon project.

## Running it

1. Install [Godot 4.7.2](https://godotengine.org/download) (standard build, not .NET).
2. Open `project.godot` in Godot and press Play (F5).

The title screen leads to two previews: the travel view (haulers pulling the wagon past scrolling scenery) and the battle layout (Space shows or hides the lineup grid, Esc goes back).

## Layout

| Folder | What's in it |
| --- | --- |
| `src/core/rules/` | Pure game rules with no scene code (check odds, hauling) |
| `src/battle/` | Battle formation layout and the battle preview |
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

# Credits

## Third-party assets

**None.** This build uses no third-party art, audio, music, fonts, plugins or code libraries.

| Item | Source | License |
|---|---|---|
| Godot Engine 4.x (runtime used to run/export the game) | https://godotengine.org | MIT |
| Default UI font (Godot's built-in fallback font, rendered by the engine; not copied into this repo) | Bundled inside Godot Engine | Bundled with the engine under its own licenses (see Help > About > Third-party Licenses in the editor) |

## Original / AI-generated assets

| Asset | Origin |
|---|---|
| All visuals: the hero, the NPC and the Demon Lord form, lamps, hazards, dragon, tiles, exit door and lock, UI | **AI-generated procedural vector art**: drawn at runtime by GDScript `_draw()` code written by Claude (Anthropic) from the team's design. No image files exist. |
| `icon.svg` | **AI-generated** (Claude): a plain SVG of glowing circles. |
| All sound effects and both music loops | **AI-generated, synthesised in code at startup** (`scripts/audio.gd`: oscillators and envelopes). No audio files exist. |
| All dialogue, UI text, level names and hints | **AI-generated** (Claude), following the team's game plan; to be reviewed and edited by the team. |

The game design (premise, lamp rules, level progression, the Demon Lord twist) is the team's, from
`The_NPC_Job_Full_Game_Plan.md` and the team's instructions during development.
See [AI_DISCLOSURE.md](AI_DISCLOSURE.md) for the full AI-use statement.

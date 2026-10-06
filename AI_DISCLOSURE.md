# AI Use Disclosure

This prototype was produced with an AI coding assistant: **Claude (Claude Sonnet 5.5, by Anthropic), operated through
Claude Code**, working from the team's design documents (`Proposal.pdf`, `The_NPC_Job_Full_Game_Plan.md`) and the team's
step-by-step instructions and corrections during the session.

| Area | AI involvement |
|---|---|
| **Code** (all GDScript in `scripts/`, `tests/`, `tools/`, scene files, `project.godot`, `export_presets.cfg`) | Written by Claude: the lamp system, hero steering, hazards, level loader, inversion, game flow, HUD, audio playback, tests. Nothing was copied from an existing game or template. |
| **Level design** (Levels 1-9: layouts, hazards, lamp placement, verified solutions) | Designed and verified by Claude with a headless simulator, within the rules and level goals set in the team's plan. |
| **Levels 10-15** (the harder levels after Level 9) | Added by the team. Claude's simulator checks that their stored solutions reach the exit (`tests/levels_test.gd`). |
| **Writing** (dialogue, hints, the prologue, the reveal and ending text) | Written by Claude from the team's premise and twist. |
| **Art** | Tiles, characters, doors, spikes, the ogre, the lamp glass and stands, and the font are third-party **CC0** assets, and the fire flames are a third-party **CC-BY 3.0** asset by Color Optimist (credited in CREDITS.md and the end credits); the team added the asset files and Claude integrated them. Claude's code tints the lamp glass per colour, draws the lamp glyphs, glows, ice and death effects, the HUD, title screen and end credits procedurally, and applies the navy night tint to the dungeon, and draws the animated fire hazard from the flame sprites. Claude also placed the fire tiles in Levels 5, 7, 8, 10 and 15 (swapping some spikes; they kill the same way). |
| **Audio** | Third-party **CC0** sound effects and music (Kenney, OpenGameArt; see CREDITS.md), including the ogre's growl (a snarl by Darsycho, trimmed). Claude wrote the playback code and volume levels, and the ogre's wake-up and chase behaviour. |
| **Docs** (README, CREDITS, this file) | Written by Claude, then updated to match the game as it changed. The end credits text (including the team's names, from `Proposal.pdf`) was written by Claude. |

## Design decisions made by the team during development

The team directed, among other things: that the hero is autonomous and only the NPC switches lamps; the four lamp behaviours;
that **lamps have no radius** (the nearest active lamp anywhere counts); the inversion rules; the level structure (extended from 9 to 15 levels by the team); the navy night look; and the
Demon Lord twist with a gameplay reversal. An earlier prototype (open-world, imaginary-guide concept) was replaced by this design.

# AI Use Disclosure

This prototype was produced with an AI coding assistant: **Claude (Claude Sonnet 5.5, by Anthropic), operated through
Claude Code**, working from the team's design documents (`Proposal.pdf`, `The_NPC_Job_Full_Game_Plan.md`) and the team's
step-by-step instructions and corrections during the session.

| Area | AI involvement |
|---|---|
| **Code** (all GDScript in `scripts/`, `tests/`, `tools/`, scene files, `project.godot`, `export_presets.cfg`) | Written by Claude: the lamp system, hero steering, hazards, level loader, inversion, game flow, HUD, audio synthesis, tests. Nothing was copied from an existing game or template. |
| **Level design** (the 9 level layouts, hazards, lamp placement, verified solutions) | Designed and verified by Claude with a headless simulator, within the rules and level goals set in the team's plan. |
| **Writing** (dialogue, hints, the prologue, the reveal and ending text) | Written by Claude from the team's premise and twist. |
| **Art** | AI-generated, drawn procedurally in code. No external images. |
| **Audio** | AI-generated, synthesised in code. No external sound or music files. |
| **Docs** (README, CREDITS, this file) | Written by Claude. |

## Design decisions made by the team during development

The team directed, among other things: that the hero is autonomous and only the NPC switches lamps; the four lamp behaviours;
that **lamps have no radius** (the nearest active lamp anywhere counts); the inversion rules; the 9-level structure; and the
Demon Lord twist with a gameplay reversal. An earlier prototype (open-world, imaginary-guide concept) was replaced by this design.

## Honest status

- Claude authored the work above; it must **not** be presented as human-authored.
- The team has not yet reviewed or modified this build. Before submission, review, playtest and update this file with what the
  team wrote or changed itself.
- Nothing was committed or back-dated by the assistant; commit history is yours.

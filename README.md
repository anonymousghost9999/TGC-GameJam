# TGC-GameJam: The NPC Job

A 2D top-down fantasy puzzle-comedy for the game jam. You are an **imaginary guide** accompanying a wildly
incompetent "Chosen One". You can't control him. You can only change the world around him with **light**
and **magic**. Themes: **Comic, Twist, Light.** Engine: **Godot 4.x (GDScript)**. Target: browser (HTML5 / itch.io).

> This repository holds a **vertical slice** of the full game in `Proposal.pdf`: a village, a river and a forest
> in one open scrolling map, with the complete core loop and the ending twist. Expect roughly 4 to 8 minutes
> for a first-time player (unmeasured with real players; see [MANUAL_TEST.md](MANUAL_TEST.md)).

## How to run

1. Install **Godot 4.4 or newer** (developed and tested on 4.7.2, Compatibility renderer).
2. Open the folder in Godot (`project.godot`) and press **F5**, or from a shell: `godot --path .`
3. The first open may take a moment to import `icon.svg`.

## Controls

| Key | Action |
|---|---|
| WASD / Arrow keys | Move the guide |
| **E** | **Interact**: examine things, switch lampposts, begin / continue |
| **Q** | **Point** at an item or obstacle (the hero may listen) |
| **Space** | Toggle your **lantern** (reveals hidden things, lures the hero) |
| **F** | **Magic: flip day and night** (3 s cooldown) |
| **Esc** (or P) | Pause / resume |
| **R** | Restart |

Debug builds only (editor): **F1 to F4** warp the hero to a stage, **F9** jumps to the ending.

## How it plays

You never touch the hero and you never do the task *for* him. He is **autonomous**: he wanders, grabs random
junk, messes with random props (barrel, slime, WET FLOOR sign, statue, chest) and blunders every time. He
uses whatever he is holding on the problem in front of him, so he usually tries the wrong thing first.

You guide him indirectly:

* **Lantern and lampposts (light).** He is drawn to whatever light is shining on ("Ooh, shiny!"). Lit areas also
  reveal hidden objects.
* **Pointing (Q).** You can point at items and obstacles. He *sometimes* obeys ("Good eye, guide!") and often
  ignores you or spitefully does the opposite.
* **Day / night magic (F).** The world behaves differently in each state.

The quest is a chain of situations, each with a different solution:

1. **Locked village gate (needs a KEY).** He tries junk first and fails. A key is hidden in a garden and only
   shows (fireflies) at **night**. Explore, find it, **point** at it: he fetches it and opens the gate.
2. **The river (needs NIGHT).** By day there is no way across and he walks in and splashes. At **night**
   moonlit stepping stones surface. If you flip back to day while he is on them, he falls in.
3. **Werewolves (needs DAY).** At night, a pack ambushes him on the far bank. Flip to **day** and they burn away.
   Flip too late and they maul him and fling him back.
4. **Fallen log (needs an AXE).** The axe is hidden in a dark hollow tree and only visible in lantern light.
   Find it, point (Q) at it. (If he is holding the key or junk, he may swap and drop what you gave him...)
5. **The Sacred Lamp** (he drops it on his foot) and the exit.

**The twist (once, at the end):** the game switches to the point of view of several **villagers** (baker, child,
farmer, woodcutter), each seeing the hero at a different point of his journey. Everything the hero says in the ending is a line he
*really said to you during the game* (the game records them, with where he stood and where you were), replayed to
the now-empty spot. Each villager sees him alone: talking to empty air, pointing at nothing, arguing with
nobody, high-fiving the air. The guide you controlled was never there; he imagined you.

## Architecture (small on purpose)

| File | Role |
|---|---|
| `scenes/main.tscn` + `scripts/game_manager.gd` | Game flow (intro, playing, pause, complete, ending), input map, wiring, camera, HUD feed |
| `scenes/open_world.tscn` + `scripts/open_world.gd` | The open map: ground, houses, trees, fence, river, props, items, night ambush |
| `scripts/day_night.gd` | The day/night state + cooldown (`is_night`, `time_changed`, tint `blend`) |
| `scripts/light_controller.gd` | Light state: lantern + lamppost sources, `is_lit(point)` |
| `scenes/hero.tscn` + `scripts/hero.gd` | Autonomous hero: random task picker + state machine; item use; reacts to light/pointing/wolves |
| `scenes/player.tscn` + `scripts/player.gd` | The imaginary guide: movement, nearest-interactable targeting, lantern |
| `scripts/item.gd`, `obstacle.gd` | Pickable items (some hidden by night/light); the gate and the log |
| `scripts/stone_bridge.gd`, `werewolf.gd`, `lamppost.gd` | River + night-only stones; the day-vulnerable threat; switchable lights |
| `scripts/barrel.gd`, `slime.gd`, `signpost.gd`, `statue.gd`, `chest.gd`, `pedestal.gd` | Props the hero blunders with |
| `scripts/hud.gd`, `bubble.gd`, `draw_util.gd` | UI, speech bubbles, art helpers |
| `scripts/twist_sequence.gd`, `villager.gd` | The ending: villagers' points of view |
| `tests/playthrough.gd`, `tests/soak.gd` | Headless bots (see Testing) |

All art is drawn in code (`_draw()`); there are no image or audio files. Night uses a `CanvasModulate` tint plus
`PointLight2D` for the lantern/lampposts (Compatibility renderer, works on the web).

## Testing

```
godot --headless --path . --fixed-fps 60 -s tests/playthrough.gd   # feature/edge-case checks (real input + physics)
godot --headless --path . --fixed-fps 60 -s tests/soak.gd          # 6 random seeds with a "perfect guide" bot
```
`playthrough.gd` checks: the guide floating through fences/water but not houses, interaction range, lamppost
switching, rapid lantern toggling, pause/resume, day/night with cooldown, hidden key (night) and axe (light),
light lure, pointing (sometimes obeyed, sometimes ignored, deflected when out of region), the hero failing with
the wrong item then succeeding after you point at the key, no stones by day, stones at night, day mid-crossing
(splash), werewolf ambush and daylight burn-off, the log and axe, the lamp, completion, the villagers' ending,
restart, that every line the hero speaks in the ending is one he said during the game, and a hero walled off from his goal (stuck failsafe).
`soak.gd` fails if the hero ever gets stuck. Both pass in the latest run. The hero is random, so exact timings
differ every run (a perfect, instant bot finishes in roughly 130 to 170 s).

**These bots are not a substitute for playing it.** See [MANUAL_TEST.md](MANUAL_TEST.md) for a checklist to run by hand.

## Browser export (itch.io)

Configured for the **Compatibility** renderer and a single-threaded build (no special itch.io headers needed);
`export_presets.cfg` has a `Web` preset.

1. In Godot: *Editor > Manage Export Templates > Download and Install* (matching your editor version).
2. *Project > Export > Web > Export Project* to `export/web/index.html`, zip `export/web/`, upload as HTML5.

**Status: the web export has NOT been built or tested.** Export templates were not installed on the dev machine,
so only the preset's syntax was checked. Check performance of the night lighting in a browser.

## Known issues / limitations

- Web export untested. No audio at all.
- Placeholder code-drawn art; minimal animation.
- Esc may be intercepted by the browser in fullscreen; **P** also pauses.
- The hero is random: how often he obeys pointing, how strongly light lures him, and how long before he
  "remembers" the quest are unplaytested guesses and need tuning.
- The hidden key/axe difficulty (are they findable?) and the twist's clarity are unverified by real players.
- The player and hero do not collide; the guide passes through fences, gates and water by design (it is imaginary).
- The ending is a short scripted cutscene, not interactive.

## Next steps for the full game

More areas from the proposal (castle, deeper dungeon), more day/night and light puzzles, more items/situations,
planted hints that nobody else ever sees the guide, audio and an animation pass, real art, and browser testing.

## License and credits

Code and original/AI-generated art: MIT, see [LICENSE](LICENSE). Asset sources: [CREDITS.md](CREDITS.md).
AI usage: [AI_DISCLOSURE.md](AI_DISCLOSURE.md).

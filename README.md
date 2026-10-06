# TGC-GameJam: The NPC Job

A 2D top-down fantasy **puzzle-comedy**. A clueless hero walks into a deadly dungeon, and the only thing he
can see is **colored lamps**. You are his helpful NPC guide: you can't control him, but you can walk around and
**switch the lamps**, and every lamp changes how he moves. Master attraction, repulsion, freezing, creeping, global
lamp states and color inversion to keep him alive... until you find out who your NPC really is.

Themes: **Comic** (the hero), **Twist** (the NPC), **Light** (lamps are the whole game).
Engine: **Godot 4.x (GDScript)**. Target: browser (HTML5 / itch.io).
Design source of truth: [The_NPC_Job_Full_Game_Plan.md](The_NPC_Job_Full_Game_Plan.md).

## How to run

1. Get **Godot 4.4 or newer** (tested on 4.7.2, Compatibility renderer). The editor is not required: the official build is a single
   binary, e.g. on Linux x86_64:
   `curl -LO https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip && unzip Godot_v4.7.2-stable_linux.x86_64.zip`
2. From this folder, import once and run: `godot --headless --path . --import` then `godot --path .`
   (or open `project.godot` in the editor and press **F5**).

## Controls

| Key | Action |
|---|---|
| WASD / Arrow keys | Move the NPC |
| **E** | Switch the nearest lamp (stand next to it). Also skips dialogue. |
| **Q** | Invert-colour lantern (from Level 6) |
| **H** | Show a hint for the current level (hidden until you ask) |
| **Esc** or P | Pause |
| **R** | Restart the current level |
| **M** | Mute |
| **Tab** | Show / hide the controls list (hidden by default) |

Debug builds only (running from the editor or `godot --path .`), from any screen: **1 to 9** jump to that level,
**Shift+0 to Shift+5** jump to levels 10 to 15, and **F1 then 0** (hold F1 and press 0, or tap F1 then 0 within 3 s) jumps straight to the **finale** (the Demon Lord's trial).

## The rules

**Only the NPC (you) can switch lamps. The hero never touches them.** He is fully autonomous: every moment he obeys
the **closest lamp that is ON** (lamps have no radius; the closest active lamp anywhere counts):

| Lamp | Hero does |
|---|---|
| **Green** | walks **toward** it (and waits beside it when he arrives) |
| **Red** | walks **away** from it |
| **Orange** | creeps **slowly toward** it |
| **Blue** | **freezes** completely |
| *no lamp is on* | **wanders randomly** (after a confused beat), straight into spikes and hidden traps |

When a level brings a new lamp or rule, it opens with a short animated card showing it (press E to continue).
The Tab panel also lists the lamps and the nearest-lamp rule. Every lamp also shows a symbol (arrows in, arrows out, one small arrow, pause bars), so color is never the only cue.
Dying restarts the level instantly. Every level ends at the **exit door**; the green exit lamp hangs above it, and the door is open while that lamp is on.

**Hazards:** spikes, fire, hidden trap floors (a faintly cracked tile the hero cannot see), timed spike walls that
twitch before coming out, and a sleeping **ogre (Gerald)** who wakes and kills the hero if he moves faster than a
creep inside his hearing (the dotted circle), so you need orange or blue to get past.

**Linked colors (every level):** all lamps of one color are on one switch. Pressing E on any of them makes **every** lamp
of that color swap its own state: if they were all off they all come on, and if one green is on and another off, they
trade places. The exit's lamp is green too. (Early levels have only one lamp per color; it bites in Level 7, and from
Level 10 groups start half on, half off.)

**Invert lantern (from Level 6):** for **5 seconds** every lamp shows *and behaves as* its opposite
(green <-> red, blue <-> orange); then a **5 second cooldown**. Each lamp keeps a small band of its original color at the
base, and lamps are switched by their original color group.

## Levels (15)

Each level adds one idea and keeps everything learned before. Finish a level without a single death for the **FLAWLESS** medal.
Levels 11 to 15 are deliberately **very hard**: several presses in a row, each with a window of roughly 0.7 to 1.6 s
(measured with `tools/window.gd`).

| # | Teaches |
|---|---|
| 1 | Green: a plain straight hall |
| 2 | Red pushes him away from spikes |
| 3 | Green + red together, with a timing window (a spike floor punishes holding red too long) |
| 4 | Blue freeze + timed spike wall + red detour |
| 5 | Orange creeping past Gerald, the sleeping ogre |
| 6 | Invert lantern + cooldown (blue becomes orange to creep through the ogre's zone) |
| 7 | Global colors bite: the exit is a green lamp too (hand-off green to orange and back) |
| 8 | The gauntlet: wall, ogre and pit, all together |
| 9 | The deep halls: wall, hidden traps, ogre, two linked blues |
| 10 | **Swap**: the exit is lit and he heads for spikes; swap at once, swap back when he reaches the other green |
| 11 | Two clocks: four timed walls on opposite beats; release on the beat, swap on the next |
| 12 | Light sleeper: two lantern creeps on the beat through walls beside the ogre, release after it fades |
| 13 | Switchboard: nine lamps on four linked switches in a spike corridor; order and beat both matter, eight presses |
| 14 | Crosswired: three linked greens, two swaps on the beat, the orange takes over by itself |
| 15 | The final lock: everything, in order, then **the lock** |

**The twist:** the hero breaks the final lock for you, and your helpful NPC is revealed as the **Demon Lord**. The same lamps
you learned to save him with now have to **kill** him.

After the final trial, the end card returns you to the title screen (press E, or wait).

**The final trial** is a route-building puzzle, not a trap you can spring with one switch. The hero is already walking to the exit
lamp, and **nothing on that path is dangerous, so if you do nothing he escapes** (and the trial restarts). The only deadly place is
a **spike chamber in the north-east**. A divider wall forces him through a gap in the south; the chamber's green lamp and the exit
lamp are the *same color* (they switch together) and he always obeys the nearer one, so he only walks into the chamber if he is
standing in the north when the red lamp lets go. The solution: run to the red lamp (south), switch it on once he is through the gap
(it pushes him north), then switch it off while he is high up (about a 3 second window); the chamber's lamp is now his nearest
green. Press **H** for stage-by-stage advice. A lone red press at just
the right moment (about a 1 second window) also works, but no other single switch ever does (a brute-force search found nothing else).

## Architecture

| File | Role |
|---|---|
| `scripts/game_manager.gd` | Game flow: title, prologue, levels, deaths/retry, medals, lock, reveal, kill phase, ending |
| `scripts/lamp_manager.gd` | Lamp switching (independent or **global per color**), inversion transform, `nearest_active()` |
| `scripts/lamp.gd`, `lamp_colors.gd` | Lamp visuals and the color/inversion mapping (behaviour derives from the CURRENT color) |
| `scripts/inversion.gd` | The invert lantern: 5 s active, 10 s cooldown |
| `scripts/hero.gd` | The autonomous hero: nearest-lamp steering, random wandering, hazards |
| `scripts/npc.gd` | The player's NPC: movement (2x the hero), lamp switching, lantern |
| `scripts/level.gd`, `hazard_layer.gd` | Builds a level from an ASCII map: walls, hazards, lamps, the ogre, exit |
| `scripts/level_data.gd` | The 15 levels + prologue + kill trial (**generated** by `tools/gen_levels.py`) |
| `scripts/dialogue.gd`, `bubble.gd`, `hud.gd` | Story lines, speech bubbles, minimal HUD |
| `scripts/audio.gd` | Sound effects and music (CC0 files in `assets/sfx`, `assets/music`) |
| `scripts/sprites.gd` | Draws the CC0 pixel art (`assets/sprites`) |
| `scripts/title_screen.gd`, `invert_card.gd` | The launch screen and the invert-lantern explainer card |
| `scripts/schedule.gd`, `level_sim.gd` | A scripted "perfect guide" used by tests and tools |
| `tools/gen_levels.py` | Level generator: edit levels here, then run `python3 tools/gen_levels.py` |
| `tools/trace.gd` | Prints the hero's path on a level for a lamp schedule (used to design the levels) |
| `tools/window.gd` | Measures how wide each timing window of a level's solution is |

Tiles, characters, the ogre, the lantern and lamp stands, the font, sounds and music are **CC0** assets (see [CREDITS.md](CREDITS.md)); lamp bulbs, effects and UI are drawn in code.

## Testing

```
godot --headless --path . --fixed-fps 60 -s tests/engine_test.gd      # the lamp/hero rules from the plan's checklist
godot --headless --path . --fixed-fps 60 -s tests/levels_test.gd      # every level: solvable, and the listed mistakes really fail
godot --headless --path . --fixed-fps 60 -s tests/game_flow_test.gd   # the whole game, title to ending, with real input
godot --headless --path . -s tests/audio_test.gd                      # every sound loads and the music loops
godot --headless --path . -s tests/bubble_test.gd                     # speech bubbles stay on screen, at most 3 lines
```
All pass. `levels_test` proves each level has a verified solution *and* that the listed mistakes really fail (doing nothing,
releasing too early, running past the ogre, ...). `game_flow_test` plays the real game from the title through the lock, the
reveal and the kill phase to the ending. A source-level check also guarantees the hero's script can never change a lamp.

**These bots are not a substitute for playing it.** See [MANUAL_TEST.md](MANUAL_TEST.md).

## Browser export (itch.io)

Configured for the **Compatibility** renderer (web-safe); `export_presets.cfg` has a `Web` preset that excludes tests and tools.
1. *Editor > Manage Export Templates > Download and Install* (matching your editor version).
2. *Project > Export > Web > Export Project* to `export/web/index.html`; zip `export/web/` and upload as HTML5.

**Status: the web export has NOT been built or tested.** Export templates were not installed on the dev machine. Check in a browser
that audio unlocks on the first key press.

## Design decisions made while building (please review)

These went beyond or interpreted the plan; each is easy to change:
- **Lamps have no radius** (your decision): the hero always obeys the closest active lamp anywhere; random wandering only happens
  when no lamp at all is on.
- **Same-color lamps are linked in every level** (plan rule 13): one press swaps each lamp of that color. Levels 1 to 9 never
  start a group half on, half off (a test checks this); levels 10 to 15 do on purpose.
- **Switching during inversion** acts on the lamp's *original* color group.
- **The hero stops beside a lamp** (not on it) so the lamp stays visible and it is clear the NPC is the one switching it.
- **The NPC is immune to hazards** (and shows "Light feet."), as foreshadowing; hero and NPC do not collide.
- **FLAWLESS** is a per-level medal (no deaths) with no gating. There is no timer.
- **Kill phase:** if the hero reaches the exit he escapes and the trial restarts.

## Known issues / limitations

- Web export untested. Animation is minimal (sprites bob; no walk cycles).
- Not yet playtested by humans: difficulty, the comedy, and how clear the foreshadowing is all need real players.
  The fastest scripted solutions take 9 to 38 s per level; a first-time player will take several times that, much more on 11 to 15.
- The hero's random wandering is random: levels are designed so the *intended* solution never relies on it.
- The kill-phase trial is short and has several ways to win; it could be made more elaborate.
- Esc may be intercepted by the browser in fullscreen; **P** also pauses.

## License and credits

Code and original/AI-generated art and audio: MIT, see [LICENSE](LICENSE). Asset sources: [CREDITS.md](CREDITS.md).
AI usage: [AI_DISCLOSURE.md](AI_DISCLOSURE.md).

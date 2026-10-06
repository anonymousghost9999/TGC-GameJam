# Manual playtest guide

The automated tests prove the rules and that every level is solvable, but **nobody has played this by hand yet**.
Run it in the editor (F5). In the editor, keys **1 to 9** jump straight to a level, and **F1 then 0** jumps straight to the finale. About 20 minutes covers everything.

## Rules to confirm while you play
- [ ] The title screen is a scene, not a wall of text; **Tab** shows/hides the controls list anywhere.
- [ ] Every level's **exit door** is easy to spot (green lamp above it; the door is open while that lamp is on).
- [ ] Level 6 opens with the **invert-lantern card** before any dialogue; is it clear what Q swaps?
- [ ] The hint line shows only `[H] hint` until you press **H**; then it shows the level's hint for a few seconds and hides again.
- [ ] **Only the NPC switches lamps.** The hero never changes one. A white spark connects the NPC to the lamp he switches.
- [ ] The hero always walks to / away from / freezes at the **closest lamp that is ON**, anywhere on the screen.
- [ ] **Same-colored lamps are linked**: E swaps every lamp of that color. From level 10 a lit and an unlit green trade places.
- [ ] The hero **stops beside** a lamp (you can always see the lamp), but walks right onto the **exit** lamp.
- [ ] With **no lamp on** he stands confused ("?") for a moment, then wanders.
- [ ] Dying restarts the level at once. **R** restarts a level without counting a death.

## Level by level (try the mistake too)

| # | Do this | You should see |
|---|---|---|
| 1 | Walk to the lamp, press **E** | He walks straight down the hall to the exit. If you wait, he wanders and may hit the two spikes. |
| 2 | Do nothing | He walks into the spikes. Switch the red lamp on early: he is pushed up and away. Switch it off when he is high: he goes over the top. |
| 3 | Red on early, then off | He slides down the wall toward the gap. Release too early: the spike wall. Hold it too long: the spike floor along the bottom. |
| 4 | Blue on (freeze), wait for the spike wall to retract, blue off | He crosses the wall. Too early: killed. Then red to steer him over the pit. |
| 5 | Light the orange lamp right away | He creeps past Gerald the ogre, then use red to steer him over the pit. Do nothing, or be too slow: he runs past fast and the **ogre** kills him. |
| 6 | Blue off to run him up, blue on to freeze him, **Q** to invert | Blue turns **orange** (look at the symbol and the base band) and he creeps. One inversion is not enough: wait out the cooldown and invert again. |
| 7 | Orange on, then greens off, then (at the orange lamp) greens on, orange off | Switching one green lamp switches **all** greens, including the exit. Orange off before greens on = no lamp = wandering. |
| 8 | Wall (blue), ogre (orange), pit (red). Mind the shared green. | Everything from before in one level. |
| 9 | Wall, hidden traps, ogre (invert twice) | Every early lesson in one room. |
| 10 | Wait until he reaches the lit green, then E | The lit green and the exit trade places. Too early: spikes. |
| 11 | Blue off on the beat, then swap greens on a later beat | Four walls on opposite clocks. Watch them twitch. |
| 12 | Swap at the green, Q on the beat (twice), blue off after the lantern fades | Off the beat: a raised wall. Blue off while inverted: the exit is red and pushes him into Gerald. |
| 13 | Blue on in every gap, off as the next wall sinks | Seven presses. Is it fun or just stressful? |
| 14 | Swap at the first lamp on the beat, swap again on the beat | The orange takes over by itself near Gerald. |
| 15 | Red off on the beat; at the green BLUE ON THEN SWAP; Q twice; blue off; swap at the last green | Then the lock and the reveal. |

## The ending (the most important part)
- [ ] The hero breaks the lock, the palette turns red, and your NPC is revealed as the **Demon Lord**.
- [ ] **Look back:** do the earlier hints (the NPC knowing about tiles, naming the ogre "Gerald", walking over spikes
  unharmed, "Maribel", the invert lantern being an "heirloom") read as clues now?
- [ ] **The final trial** (jump to it with **F1 then 0**): the hero is already walking to the exit lamp and **escapes** if you do
  nothing (the trial restarts). Can you work out how to kill him? The only deadly place is the spike chamber in the north-east.
  Use the hint line if you are stuck. (Solution: run to the red lamp in the south, switch it on once he is through the gap
  in the divider wall, then switch it off when he is high up near the top.) Is it hard enough? Too hard? How long did it take?
- [ ] After he dies you get the ending card with flawless levels and total deaths. **R** starts over.

## Feel and fairness (the things only a person can judge)
- [ ] Is each level's new idea obvious from the hint line and the first attempt, or do you need the dialogue?
- [ ] Are the timing windows fair (Level 3 red release, Level 4 freeze release, Level 6 cooldown)? Too tight or too forgiving?
- [ ] Is the random wandering dangerous enough to matter but not unfair?
- [ ] Do the hero's lines make you smile? Which are flat? (Dialogue is easy to rewrite in `scripts/dialogue.gd` and the level text in `tools/gen_levels.py`.)
- [ ] Do the lamp symbols make the colors readable without relying on color alone?
- [ ] Is the sound pleasant, and is the music too loud or repetitive? (**M** mutes.)

## Try to break it
- [ ] Mash E and Q. Pause in the middle of a creep, then resume. Restart (R) mid-cooldown.
- [ ] Stand still for a minute in Level 1. Does anything get stuck?
- [ ] Switch lamps while the hero is dying. Press R during the dialogue.

## What to report back
For each unchecked box: *what happened*, *what you expected*, and *how it felt* (boring / confusing / unfair / funny).

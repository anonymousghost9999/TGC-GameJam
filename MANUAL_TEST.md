# Manual playtest guide

The automated bots (`tests/playthrough.gd`, `tests/soak.gd`) cover logic, but **nobody has played this by hand
yet**. This is what to check, in about 10 minutes. Open the project in Godot and press **F5**.

**Debug hotkeys** (editor / debug builds only, absent from release exports): **F1-F4** jump the hero to the
gate / river / forest log / shrine (earlier obstacles are solved); **F9** jumps to the ending.

Controls: WASD move, **E** interact (examine, switch lampposts), **Q** point at items/obstacles, **SPACE** lantern,
**F** day/night magic, ESC pause, R restart.

## 1. First 30 seconds: does it read?
- [ ] Intro explains the guide role. Can you tell, in one read, what you can and can't do?
- [ ] The hero wanders, grabs things and blunders on his own. Do you feel like you are *watching*, not steering?
- [ ] When he is off-screen, does the red **HERO** arrow help you find him?
- [ ] Is the **HERO BLUNDERS** counter and "HERO HOLDS" text useful or noise?

## 2. Light as guidance
- [ ] Lantern ON near an item or prop: does he say "Ooh, shiny!" and head there most of the time?
- [ ] Lantern OFF: does he go back to doing random things?
- [ ] Walk to a lamppost and press **E**: light radius ring appears, and he is drawn to it too.

## 3. Pointing (Q) and ignoring
- [ ] Stand next to a junk item (fish, bucket, hammer) and press **Q**: a red arrow appears over it.
  He should *sometimes* obey ("Good eye, guide!") and *sometimes* ignore you. Does the ratio feel fair, or too random?
- [ ] Point at something in a region he hasn't reached yet: he says "That's way over there. Later!".

## 4. Stage A: the locked village gate (key)
- [ ] Wait for him to reach the gate (or press **F1**). With junk in hand he should fail in a *different* funny way per item.
- [ ] The objective hints at night. Press **F**: do fireflies appear over a garden bed in the south of the village?
- [ ] Walk there, press **Q** on the key. He fetches it and opens the gate, then takes credit.
- [ ] **Difficulty check:** could you find the key without the hint? Is the garden too hidden or too obvious?
- [ ] Bonus: point at the key *before* he reaches the gate, then watch whether he later swaps it for junk.

## 5. Stage B: the river (night) and the werewolves (day)
- [ ] By day he can't cross and eventually walks in and splashes. At night stepping stones glow.
- [ ] Press **F** back to day while he is on the stones: he should fall in.
- [ ] After he crosses at night, werewolves appear on the far bank. Switch to **day**: do they burn off?
- [ ] If you don't switch, do they maul him and fling him back (and is that annoying or funny)?
- [ ] The magic has a 3 second cooldown. Does that feel good, too short, or too long?

## 6. Stage C: the fallen log (axe)
- [ ] He fails with junk first. Walk to the dark hollow tree in the north of the forest with the lantern ON:
  the axe appears only in light. Point at it. Does the progression make sense?

## 7. The ending
- [ ] Press **E** on "Quest Complete". Do the four villager scenes (baker, child, farmer, woodcutter) each show the hero
  alone: talking to nobody, pointing at nothing, arguing, celebrating?
- [ ] Are the hero's lines in the ending the *same* ones you heard in the game, spoken to an empty spot?
- [ ] Is the camera far enough out that you can see the hero, the villager and the empty spot?
- [ ] **The key question:** by the last scene, do you *feel* the twist, or does it need to be more explicit/subtle?
- [ ] Does anything in the first half now look different in hindsight? (If not, we need more planted hints.)

## 8. Robustness (try to break it)
- [ ] Mash Space, F, E and Q. Pause (Esc) in the middle of a blunder, resume. Restart (R) mid-run and at the ending.
- [ ] Stand still for a minute: does the hero ever get stuck, loop forever, or leave the map?
- [ ] Does it run smoothly (no stutter at night with the lantern light)?

## What to report back
For each unchecked box, a short note is enough: *what happened*, *what you expected*, and *how it felt*
(boring / confusing / unfair / funny). Funniest and least funny moment are especially useful.

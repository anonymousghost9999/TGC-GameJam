# The NPC Job — Full Game Plan

## 1. Game Overview

**The NPC Job** is a 2D top-down fantasy puzzle-comedy game built in **Godot 4.x** for a **browser/itch.io** release.

The player controls an **NPC guide**, not the hero.

The core gameplay idea is:

> **The player manipulates colored lamps to indirectly control the movement of an autonomous hero.**

The three required themes are:

- **Comic** — the hero is an incompetent adventurer, with comedy coming from his personality, reactions, dialogue, and situations rather than from breaking gameplay rules.
- **Twist** — the apparently helpful NPC is actually the **Demon Lord**.
- **Light** — colored light is the central gameplay system and directly determines the hero's movement.

---

# 2. Core Premise

A clueless hero enters a dangerous dungeon to rescue the NPC's supposedly kidnapped wife.

The NPC accompanies him and helps him navigate the dungeon.

The problem is that the hero cannot properly perceive the dungeon. He depends on the dungeon's colored lamps, which influence how he moves.

The player controls the NPC and must physically move around the dungeon to manipulate those lamps.

The hero remains autonomous for the entire game.

The player never directly controls the hero.

---

# 3. Opening Story

The game begins outside the dungeon.

The NPC approaches the hero and asks for help.

The NPC claims that his **wife has been trapped inside the dungeon by the Demon Lord**.

The hero, being naive and overly confident, agrees to help.

They enter the dungeon.

The NPC starts guiding the hero through the dungeon using its lamps.

The player gradually learns that the hero is effectively dependent on the light system to navigate.

---

# 4. Player Character — The NPC

The player controls the NPC.

The NPC is:

- physically real,
- physically present beside the hero,
- capable of moving around the dungeon,
- capable of interacting with lamps,
- capable of using the invert-colour lantern.

The NPC is approximately **2× faster than the hero**.

This speed difference is important because the NPC must often move ahead of the hero to prepare safe routes.

## NPC abilities

### Movement

The NPC can freely move around the dungeon.

### Lamp interaction

The NPC can physically reach a lamp and switch it ON/OFF.

### Invert-colour lantern

The NPC can activate a special lantern that temporarily transforms the dungeon's lamp colors and behaviors.

---

# 5. Hero Behavior

The hero is **autonomous**.

The player does not directly command his movement.

The hero responds to the nearest active lamp that is affecting him.

## Hero states

### Green lamp

The hero moves **toward** the green lamp.

### Red lamp

The hero moves **away** from the red lamp.

### Orange lamp

The hero moves **slowly toward** the orange lamp.

### Blue lamp

The hero **freezes completely**.

### No active lamp

If there is no active lamp influencing the hero:

> **The hero moves randomly.**

This is dangerous.

He can randomly wander into:

- spikes,
- traps,
- fire,
- other hazards.

The hero can become injured or die.

> **When the hero dies, the level restarts.**

Therefore, keeping appropriate lamp influence on the hero is a fundamental survival requirement.

---

# 6. Lamp Color Language

The lamp colors are intentionally familiar.

| Color | Familiar association | Hero behavior |
|---|---|---|
| **Green** | Go | Moves toward the lamp |
| **Red** | Stop / danger | Moves away from the lamp |
| **Orange** | Caution | Moves slowly toward the lamp |
| **Blue** | Special state | Freezes |

The game does not need to rely on long textual explanations.

The player should be able to understand the colors through visual demonstration and their familiar associations.

Blue represents **freeze/immobilization**, consistent with familiar visual and interface associations.

---

# 7. Lamp Placement and Influence Radius

Lamp positions are **fixed/pre-placed in each level**.

The player/NPC **cannot move, place, or reposition lamps**. The level designer determines their locations as part of the puzzle layout.

The NPC can only move to existing lamps and switch them ON/OFF.

Every lamp has a **fixed radius of influence**.

The hero primarily responds to the **closest active lamp affecting him**.

This creates important spatial considerations:

- where lamps are placed,
- when they are active,
- which lamp is currently closest,
- when the hero transitions from one lamp's influence to another,
- whether the next lamp creates a safe or dangerous movement direction.

The player is therefore solving both a **routing problem** and a **timing problem**.

Because lamp positions are fixed, the puzzle is about **sequencing and timing the available lamp switches within a predetermined spatial layout**.

---

# 8. Global Same-Color Lamp State

A major later-game mechanic is:

> **All lamps of the same color share the same ON/OFF state.**

For example:

- switching one green lamp ON switches all green lamps ON,
- switching one green lamp OFF switches all green lamps OFF,
- the same applies independently to red, orange, and blue.

This means the lamps are **not independent switches**.

A local interaction can change the state of the entire color group.

This mechanic should be introduced after the player already understands individual lamp behavior.

It is one of the main sources of late-game puzzle complexity.

---

# 9. Invert-Colour Lantern

The NPC has a special **invert-colour lantern**.

## Timing

- **Active duration:** 5 seconds
- **Cooldown:** 10 seconds

## What inversion does

Inversion changes **both**:

1. the visible color of the lamp,
2. the behavior associated with that lamp.

The complementary mappings are:

| Normal lamp | During inversion |
|---|---|
| **Green** | becomes **Red** visually and behaves as Red |
| **Red** | becomes **Green** visually and behaves as Green |
| **Blue** | becomes **Orange** visually and behaves as Orange |
| **Orange** | becomes **Blue** visually and behaves as Blue |

When the 5-second effect ends:

- the lamp returns to its original visible color,
- its original behavior returns.

The player therefore does **not** have to remember a hidden state such as:

> "This green lamp secretly behaves as red."

Instead, the lamp visibly becomes its complementary color.

That keeps the system readable while creating a strong timing mechanic.

---

# 10. Inversion Examples

### Green → Red

A green lamp normally pulls the hero toward it.

During inversion, it visibly becomes red and pushes the hero away.

### Red → Green

A red lamp normally pushes the hero away.

During inversion, it visibly becomes green and pulls the hero toward it.

### Blue → Orange

A blue lamp normally freezes the hero.

During inversion, it visibly becomes orange and slowly pulls him toward it.

### Orange → Blue

An orange lamp normally slowly pulls the hero.

During inversion, it visibly becomes blue and freezes him.

The player can therefore use inversion to temporarily change the navigation logic of an existing dungeon layout.

---

# 11. Dungeon Hazards

The dungeon contains hazards that the hero cannot properly see.

Possible hazards include:

- spikes,
- fire,
- trap floors,
- dangerous corridors,
- narrow safe paths,
- environmental obstacles.

The goal of each level is not simply to reach the exit.

The actual puzzle is:

> **Manipulate the hero's autonomous movement so he reaches the exit without hitting a hazard.**

---

# 12. Level Exit

Every level contains a **green lamp at the exit**.

This provides a consistent visual destination.

The player can eventually route the hero into the exit region by using the same attraction system that has been taught throughout the game.

---

# 13. Level Progression

The game is designed around **9 levels total**, targeting approximately **15 minutes for a first-time playthrough**.

### Core progression rule

> **Each level introduces one new lamp mechanic, but all previously unlocked lamp colors remain available.**

The player therefore builds a growing toolkit rather than playing isolated single-color tutorials.

The structure is:

> **5 teaching levels + 3 mastery levels + 1 finale**

Early levels are intentionally short. Later levels spend more time combining mechanics and delivering the final narrative payoff.

## Level 1 — Green

### Purpose

Teach the fundamental relationship:

> **Green → move toward the lamp**

### Layout

A small, simple dungeon area with minimal hazards.

The player physically switches green lamps and learns to position the hero.

### Goal

Guide the hero to the green exit lamp.

**Target time:** ~1 minute  
**Mastery:** Complete the level within the target time.

---

## Level 2 — Green + Red

### New mechanic

> **Red → move away from the lamp**

The player learns that light can repel as well as attract while Green remains available.

### Puzzle purpose

Red is used to keep the hero away from dangerous directions.

### Goal

Guide the hero around a basic hazard using green and/or red behavior.

**Target time:** ~1 minute  
**Mastery:** Complete the level within the target time.

---

## Level 3 — Green + Red

### Purpose

Introduce the player to using **Green and Red together**.

No new system is introduced here.

### Layout

A small, simple room with:

- one **Green** lamp near the exit,
- one **Red** lamp near a dangerous path,
- one simple spike/trap area.

The lamp positions are fixed.

### Puzzle

The hero needs to reach the exit.

- **Green** pulls him toward the exit.
- **Red** pushes him away from the dangerous side.

The player switches the lamps at the appropriate time to keep the hero on the safe route.

There is only **one Green lamp and one Red lamp**, so the global same-color rule does not yet create additional complexity.

### Goal

Teach the basic idea:

> **Green attracts, Red repels.**

**Target time:** ~1.5 minutes  
**Mastery:** Complete the level within the target time.

---

## Level 4 — Blue

### New mechanic

> **Blue → freeze**

Blue is introduced alongside the already established **Green + Red** lamps.

The player can now combine:

- **Green** → move toward
- **Red** → move away
- **Blue** → freeze

Blue allows the player to stop the hero at a precise location while continuing to use Green and Red to control where he moves.

### Puzzle possibilities

- use Green to pull the hero toward an area, then Blue to stop him,
- use Blue to hold the hero while the NPC repositions,
- use Red to redirect the hero after releasing the freeze,
- stop the hero before a hazard,
- create timing windows between multiple lamps.

The level should make Blue useful **in combination with the previously learned colors**, rather than presenting it as a standalone mechanic.

**Target time:** ~1.5 minutes  
**Mastery:** Complete the level within the target time.

---

## Level 5 — Orange

### New mechanic

> **Orange → slowly move toward the lamp**

Orange is introduced alongside the existing **Green + Red + Blue** system.

The player can now combine all four behaviors:

- **Green** → move toward
- **Red** → move away
- **Blue** → freeze
- **Orange** → slowly move toward

Orange's main purpose is **slow/stealth movement**.

It lets the player guide the hero carefully through situations where fast movement would be dangerous.

### Stealth use cases

For example, the hero may need to pass near a:

- sleeping dragon,
- sleeping monster,
- sensitive hazard,
- timing-sensitive area.

Green may pull the hero toward the destination too quickly, while Orange allows the player to guide him **slowly and carefully** through the area.

Blue can then be used to freeze him at a safe position while the NPC moves ahead and prepares the next lamp.

### Puzzle possibilities

- use Green for normal movement,
- switch to Orange for stealth sections,
- use Blue to hold the hero in a safe position,
- use Red to redirect him,
- combine Orange + Blue for precise timing,
- transition between different fixed lamp influence zones.

The level should require the player to use **Orange together with the previously learned colors**, not solve the level using Orange alone.

**Target time:** ~1.5 minutes  
**Mastery:** Complete the level within the target time.

---

## Level 6 — Invert Lantern

### New mechanic

Introduce the 5-second inversion effect and 10-second cooldown.

The player learns:

- visible color transformation,
- behavior transformation,
- temporary state,
- timing,
- cooldown management.

During inversion:

- green becomes red,
- red becomes green,
- blue becomes orange,
- orange becomes blue.

The player must understand that the lamp's **visible color and behavior both change together**.

**Target time:** ~2 minutes  
**Mastery:** Complete the level within the target time.

---

## Level 7 — Global Color States

### New mechanic

Introduce the rule that:

> **All lamps of the same color share the same ON/OFF state.**

The player now has to think globally.

Example:

A green lamp may be useful in one room but harmful in another. Switching that green lamp changes every green lamp.

This forces the player to plan the consequences of each interaction.

**Target time:** ~2 minutes  
**Mastery:** Complete the level within the target time.

---

## Level 8 — Complex Combination Puzzle

Combine the learned mechanics:

- green,
- red,
- orange,
- blue,
- global same-color states,
- inversion,
- lamp radius,
- movement timing,
- multiple hazards.

The player should now be solving the system rather than learning individual rules.

Possible challenges include:

- switching a globally linked color at the correct moment,
- using blue to hold the hero while the NPC repositions,
- using orange to control approach speed,
- using inversion during a critical transition,
- managing multiple lamp influence zones.

**Target time:** ~2 minutes  
**Mastery:** Complete the level within the target time.

---

## Level 9 — Final Dungeon and Finale

The final level combines the major mechanics in one last dungeon section.

The player must:

1. understand lamp behavior,
2. maintain lamp influence,
3. route the hero around multiple traps,
4. account for globally linked colors,
5. use inversion at appropriate moments,
6. reach the final area,
7. get the hero to the final lock.

The hero breaks the final lock.

That restores the Demon Lord's control.

The NPC then reveals his true identity as the **Demon Lord**.

The gameplay immediately reverses:

> **Use the lamp system to kill the hero.**

The player deliberately uses green, red, blue, orange, and inversion to construct a lethal route through the final hazards.

**Target time:** ~2.5 minutes  
**Mastery:** Complete the level within the target time.

---

## 13A. Level Mastery

Each level has a **target completion time**.

> **If the player completes the level within its target time, that level is considered mastered.**

Mastery is evaluated independently for each level. The target times are intended to reward efficient understanding and execution of the light mechanics rather than simply reaching the exit.

# Target Playtime

| Level | Focus | Target time |
|---|---|---:|
| 1 | Green — attraction | ~1 min |
| 2 | Red — repulsion | ~1 min |
| 3 | Green + Red | ~1.5 min |
| 4 | Blue — freeze | ~1.5 min |
| 5 | Orange — slow attraction | ~1.5 min |
| 6 | Invert-colour lantern | ~2 min |
| 7 | Same-color global states | ~2 min |
| 8 | Complex combination | ~2 min |
| 9 | Final dungeon + reveal + kill sequence | ~2.5 min |
| **Total** | **Complete first-time playthrough** | **~15 min** |

The levels should be **small puzzle sections rather than large dungeon floors**. The difficulty and depth should come from combinations of the existing light mechanics, allowing the game to reach the target playtime without requiring excessive environment production.

# 14. Puzzle Design Philosophy

The learning curve should roughly be:

### Early

> **What does this color do?**

### Middle

> **Where should I put/use this color?**

### Later

> **What happens if I change this color while the hero is here?**

### Advanced

> **Changing one lamp changes every lamp of that color.**

### Expert

> **I need to change the visible color and behavior through inversion for exactly the right 5-second window.**

The player should gradually develop a mental model of the system.

---

# 15. Failure Loop

Failure must be clear and consistent.

## Failure condition

No active lamp influences the hero.

## Consequence

The hero moves randomly.

## Result

He may:

- enter a spike,
- trigger a trap,
- enter fire,
- otherwise become injured or die.

## Recovery

> **Level restarts.**

This makes maintaining lamp influence an active part of every puzzle rather than an optional convenience.

---

# 16. Comedy Design

The game's comedy should **not come from breaking lamp physics**.

The hero's movement should always obey the actual rules.

Comedy should instead come from:

### Personality

The hero is:

- naive,
- overconfident,
- incompetent,
- convinced he is a great adventurer.

### Dialogue

He may:

- claim credit for things the NPC accomplished,
- misunderstand obvious situations,
- complain about the dungeon,
- make overly dramatic statements,
- treat trivial successes as heroic victories.

### Reactions

Use animation and expressions for:

- excitement,
- confusion,
- impatience,
- fear,
- relief,
- exaggerated celebration.

### Important rule

Do not make the hero randomly violate the movement system merely for a joke.

The puzzle rules need to remain readable.

---

# 17. NPC Characterization

The NPC initially presents himself as a helpful companion.

He should appear competent and useful.

However, subtle clues should establish that he knows **far too much about the dungeon**.

Examples of foreshadowing:

- knowing where mechanisms are,
- knowing what a trap does,
- knowing how dungeon systems behave,
- confidently identifying routes,
- understanding the lamp system unusually well.

These clues should be subtle.

Do not use obvious exposition such as:

> "I built this dungeon."

The player should only recognize the significance of the clues after the final reveal.

---

# 18. The Real Twist

The NPC is actually the **Demon Lord**.

He is:

- physically real,
- present throughout the game,
- genuinely accompanying the hero.

The NPC's objective is to use the hero to restore access/control to the dungeon.

The hero believes he is helping rescue the NPC's wife.

In reality, the hero is being manipulated into performing the action the Demon Lord needs.

There is **no imaginary NPC twist**.

There is **no hallucination twist**.

There is **no second perspective reveal**.

There is **only the Demon Lord identity reveal**.

---

# 19. Final Lock

The dungeon's deepest section contains a **final lock**.

The hero reaches it after completing the dungeon.

He breaks the lock.

This restores the Demon Lord's control over the dungeon.

The NPC's true identity can then be revealed.

The previous "helping the hero" behavior is recontextualized:

> The NPC was never helping the hero for the hero's sake.

He needed the hero to reach and break the lock.

---

# 20. Final Gameplay Reversal

The climax should happen through gameplay, not only dialogue.

Before the reveal:

> **Use light to save the hero.**

After the reveal:

> **Use light to kill the hero.**

The player now deliberately uses the lamp system against him.

Possible sequence:

1. The hero breaks the final lock.
2. The Demon Lord/NPC reveals himself.
3. The environment changes into a controlled lethal section.
4. The player manipulates lamps around hazards.
5. Green pulls the hero toward danger.
6. Red pushes him away from safety.
7. Blue can freeze him in a dangerous position.
8. Orange can control the timing of his approach.
9. Inversion can temporarily reverse these effects.
10. The player intentionally creates a lethal route.
11. The hero dies.

The important part is that **the player uses the exact mechanics they spent the entire game learning**.

---

# 21. Ending Payoff

The emotional/structural payoff is:

### Beginning

> "I need to help this guy rescue his wife."

### Middle

> "I need to master these lamps so the hero survives."

### Final dungeon

> "I need to get him through everything and reach the final lock."

### Final lock

> "Why did he need me to do this?"

### Reveal

> **The NPC is the Demon Lord.**

### Final sequence

> **The player realizes the entire lamp system can now be used to kill the hero.**

This is the final mechanical and narrative payoff.

---

# 22. Visual Direction

The game should use a **stylized 2D fantasy cartoon look**.

## General direction

- readable silhouettes,
- exaggerated proportions,
- expressive characters,
- simple but distinctive dungeon tiles,
- strong color readability,
- clear hazard visuals,
- visually prominent lamps.

## Hero

The hero should communicate:

> **"Confident chosen one who is actually an idiot."**

He should look heroic at first glance but have exaggerated expressions and behavior.

## NPC

The NPC should look like a plausible fantasy guide.

Do not make him immediately look like the obvious Demon Lord.

His true identity should become more apparent through the reveal.

## Lamps

The four colors must be extremely easy to distinguish.

This is critical because color is a gameplay language.

---

# 23. Animation Priorities

Because the project is time-limited, prioritize animations that communicate gameplay and comedy.

Highest priority:

1. hero movement,
2. hero directional reaction,
3. hero freeze animation,
4. hero slow-movement animation,
5. lamp ON/OFF animation,
6. lamp color transformation during inversion,
7. NPC movement,
8. NPC interaction,
9. hero hit/death animation,
10. simple victory/reaction animations.

Animation should reinforce mechanics rather than just decorate the game.

---

# 24. UI / Dialogue

Use **speech bubbles** as the primary dialogue presentation.

This suits a top-down comedy game because dialogue remains associated with the character in the world.

Keep HUD information minimal.

Potential UI elements:

- current objective,
- invert lantern cooldown,
- pause/restart,
- simple tutorial indicators where necessary.

The game should not fill the screen with instructional text.

The player should understand the mechanics by observing them.

---

# 25. Audio Direction

Audio should reinforce the three themes.

## Music

Fantasy/adventure-inspired music with a comedic tone.

The music should support the feeling that the hero is on a grand heroic quest while the player gradually understands the absurdity.

## Sound effects

Important effects:

- lamp switching,
- lamp color transformation,
- hero movement,
- hero freezing,
- trap activation,
- damage,
- death,
- successful puzzle completion,
- final-lock break,
- Demon Lord reveal.

The lamp sounds should make interactions immediately recognizable.

---

# 26. Technical Architecture

Target:

**Godot 4.x**

Platform:

**HTML5/WebGL browser build**

Core systems:

- player/NPC movement,
- hero autonomous movement,
- lamp manager,
- lamp influence detection,
- global same-color lamp state,
- hero behavior state machine,
- hazard detection,
- death/restart system,
- invert-colour system,
- level transitions,
- dialogue system,
- final narrative sequence.

---

# 27. Suggested Core Systems

## HeroController

Responsible for:

- target lamp detection,
- movement,
- random movement when no lamp influences the hero,
- movement speed,
- freeze state,
- death,
- reactions.

## LampController

Responsible for:

- color,
- active/inactive state,
- influence radius,
- interaction,
- visual state.

## LampManager

Responsible for:

- global same-color ON/OFF state,
- propagating changes to all lamps of the same color,
- registering/unregistering lamps.

## InversionManager

Responsible for:

- activation,
- 5-second duration,
- 10-second cooldown,
- visible color transformation,
- behavior transformation,
- restoring original states.

## HazardController

Responsible for:

- spike/trap collision,
- hero damage,
- hero death,
- level restart.

## LevelManager

Responsible for:

- loading levels,
- resetting state,
- level completion,
- transitions.

## DialogueManager

Responsible for:

- speech bubbles,
- sequencing dialogue,
- cutscenes,
- final reveal.

---

# 28. Lamp Data Model

Each lamp should conceptually store:

```text
original_color
current_visible_color
active
influence_radius
position
```

The behavior should be derived from the **current color**, rather than maintaining unrelated independent behavior values.

That makes inversion straightforward:

```text
GREEN  -> RED
RED    -> GREEN
BLUE   -> ORANGE
ORANGE -> BLUE
```

When inversion ends:

```text
current_visible_color = original_color
```

and behavior automatically returns to normal.

---

# 29. Hero Decision Logic

A simplified decision model:

```text
find active lamps affecting hero

if none:
    random movement

else:
    choose closest active lamp

    if green:
        move toward lamp

    if red:
        move away from lamp

    if orange:
        move slowly toward lamp

    if blue:
        stop
```

The same logic should continue to work during inversion because inversion changes the lamp's **current visible/current behavior color**.

---

# 30. Global Color Logic

Conceptually:

```text
switch_green(state):
    every green lamp = state

switch_red(state):
    every red lamp = state

switch_orange(state):
    every orange lamp = state

switch_blue(state):
    every blue lamp = state
```

Inversion changes the visible/current color of those lamps but does not destroy their original color identity.

This distinction is important because after inversion ends, each lamp must return to its original state.

---

# 31. Inversion State

Conceptually:

```text
activate inversion

if cooldown == 0:
    inversion_active = true
    timer = 5 seconds

    transform colors:
        green -> red
        red -> green
        blue -> orange
        orange -> blue

after 5 seconds:
    restore original colors
    inversion_active = false
    cooldown = 10 seconds
```

The player should receive strong visual feedback while inversion is active.

---

# 32. Development Priorities

The implementation priority should be:

### Highest priority

1. Hero movement system.
2. Lamp behavior system.
3. Lamp influence radius.
4. Random movement failure state.
5. Spike/trap death and restart.
6. NPC movement.
7. Lamp interaction.
8. Green/red/blue/orange behavior.
9. Global same-color states.
10. Invert-colour lantern.
11. Level progression.
12. Final lock.
13. Demon Lord reveal.
14. Final lethal lamp sequence.

### Then

- character art,
- animation,
- dialogue,
- sound,
- polish,
- particles,
- visual feedback,
- browser optimization.

The game should remain playable even if some visual polish has to be reduced.

---

# 33. Testing Checklist

## Hero

- [ ] Hero moves toward green.
- [ ] Hero moves away from red.
- [ ] Hero slowly moves toward orange.
- [ ] Hero freezes under blue.
- [ ] Hero moves randomly with no active influence.
- [ ] Random movement can correctly trigger traps.
- [ ] Hero death correctly restarts the level.

## Lamps

- [ ] Interaction toggles lamps.
- [ ] Same-color lamps share ON/OFF state.
- [ ] Lamp influence radius works.
- [ ] Closest active lamp is correctly selected.
- [ ] Multiple colors interact correctly.

## Inversion

- [ ] Green visually becomes red.
- [ ] Red visually becomes green.
- [ ] Blue visually becomes orange.
- [ ] Orange visually becomes blue.
- [ ] Behavior changes with the visible color.
- [ ] Effect lasts 5 seconds.
- [ ] Cooldown lasts 10 seconds.
- [ ] Original colors return correctly.
- [ ] Global color-state logic remains consistent.

## Levels

- [ ] Every level has a green exit lamp.
- [ ] Level reset is reliable.
- [ ] Level completion is reliable.
- [ ] No soft-locks.

## Ending

- [ ] Final lock can be reached.
- [ ] Hero breaks final lock.
- [ ] NPC reveal triggers correctly.
- [ ] Lamp mechanics can be used for the final lethal sequence.
- [ ] Hero death triggers the intended ending.
- [ ] No old/imaginary-NPC material remains.

---

# 34. Scope Control

The game should prioritize a **complete 10–15 minute experience** over a large amount of content.

The core systems are small but combinable.

Avoid adding mechanics that require an entirely new rule set unless they directly strengthen the light puzzle system.

Good additions:

- new trap arrangements,
- new level layouts,
- more complex lamp combinations,
- better timing puzzles,
- stronger comedy,
- more polished visuals.

Risky additions:

- combat system,
- inventory system,
- large dialogue tree,
- open-world exploration,
- unrelated puzzle mechanics,
- large numbers of enemy types,
- complex progression systems.

The goal is to make the existing light system deep rather than making the game broad.

---

# 35. Intended Player Experience

The player should gradually experience:

### Beginning

> "I'm guiding a stupid hero."

### After learning green/red

> "I can manipulate where he goes."

### After blue/orange

> "I can control movement and timing."

### After global colors

> "Changing one lamp affects the whole color network."

### After inversion

> "I can temporarily transform the entire behavior of these lamps."

### Final lock

> "Why was the NPC so interested in getting here?"

### Reveal

> **"The NPC is the Demon Lord."**

### Ending

> **"I now have to use everything I learned to kill the hero."**

---

# 36. Final Core Loop

```text
Explore
   ↓
Observe hazards
   ↓
Predict hero movement
   ↓
Move NPC
   ↓
Switch lamps
   ↓
Control hero indirectly
   ↓
Prevent random movement
   ↓
Avoid traps
   ↓
Reach green exit
   ↓
Learn new mechanic
   ↓
Repeat with increasing complexity
   ↓
Reach final lock
   ↓
Hero breaks lock
   ↓
NPC reveals himself as Demon Lord
   ↓
Gameplay reverses
   ↓
Use lamps to construct a lethal route
   ↓
Hero dies
   ↓
Ending
```

---

# 37. Final Game Pitch

> **Guide a clueless hero through a deadly dungeon using colored lamps that control his every movement. Master attraction, repulsion, freezing, slowing, global lamp states, and color inversion to keep him alive—only to discover that your helpful NPC is the Demon Lord, and everything you've learned about light is now being used to kill him.**

---

# 38. Non-Negotiable Game Rules

These rules define the current design and should not be changed accidentally during implementation:

1. **The NPC is real and physically present.**
2. **The NPC is the Demon Lord.**
3. **The hero is autonomous.**
4. **The player directly controls only the NPC.**
5. **The NPC physically switches the lamps.**
6. **The hero never controls the lamps.**
7. **Green pulls the hero toward the lamp.**
8. **Red pushes the hero away from the lamp.**
9. **Orange slowly pulls the hero toward the lamp.**
10. **Blue freezes the hero.**
11. **No active lamp influence causes random hero movement.**
12. **Random movement can cause trap/spike death and level restart.**
13. **All lamps of the same color share ON/OFF state.**
14. **Every level has a green lamp at the exit.**
15. **Inversion lasts 5 seconds and has a 10-second cooldown.**
16. **Inversion changes both lamp color and behavior.**
17. **Green ↔ Red during inversion.**
18. **Blue ↔ Orange during inversion.**
19. **After inversion, lamps return to their original colors and behaviors.**
20. **The final twist is only that the NPC is the Demon Lord.**
21. **There is no imaginary-NPC twist.**
22. **There is no hallucination reveal.**
23. **There is no villagers-observe-hero-alone reveal.**
24. **The final gameplay reversal uses the same lamp mechanics to kill the hero.**
25. **Comedy must not break the underlying movement rules.**

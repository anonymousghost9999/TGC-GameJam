#!/usr/bin/env python3
"""Generates scripts/level_data.gd from level specs below.
Run:  python3 tools/gen_levels.py
Map legend: see scripts/level.gd. Lamps: g r o b (OFF) / G R O B (ON). X = exit (green exit lamp)."""
import json, sys

W, H = 30, 17

class Grid:
    def __init__(self):
        self.g = [['.'] * W for _ in range(H)]
        for x in range(W):
            self.g[0][x] = '#'; self.g[H-1][x] = '#'
        for y in range(H):
            self.g[y][0] = '#'; self.g[y][W-1] = '#'
    def rect(self, ch, x0, y0, x1=None, y1=None):
        x1 = x0 if x1 is None else x1
        y1 = y0 if y1 is None else y1
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.g[y][x] = ch
    def put(self, ch, x, y):
        self.g[y][x] = ch
    def rows(self):
        return [''.join(r) for r in self.g]

LEVELS = []

def add(**kw):
    LEVELS.append(kw)

# ------------------------------------------------------------------ prologue
g = Grid()
g.rect('#', 1, 1, 28, 2); g.rect('#', 1, 14, 28, 15)   # trees / hedge
g.put('H', 12, 8); g.put('N', 6, 8); g.put('X', 24, 8)
add(id="prologue", num=0, title="OUTSIDE THE DUNGEON", glob=True, invert=False, exit_on=False,
    palette=1, exit_kind="dungeon", map=g.rows(), intro=[], outro=[], hint="")

# ------------------------------------------------------------------ level 1: GREEN
# A plain straight hall. One lamp at the far end, OFF. The NPC (player) starts beside it.
g = Grid()
g.rect('#', 1, 1, 28, 6); g.rect('#', 1, 10, 28, 15)   # a straight 3-wide hall (rows 7..9)
g.put('^', 14, 7); g.put('^', 14, 9)                    # two spikes beside the path
g.put('H', 3, 8); g.put('N', 24, 9); g.put('X', 26, 8)
add(id="l1", cards=["green"], num=1, title="GREEN", glob=True, invert=False, exit_on=False,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Walk to the lamp and press E to switch it on. Only YOU can switch lamps.",
    intro=[["N", "The lamp at the end is off. Switch it on, and he will walk straight to it."],
           ["H", "I need no lamps! ...But they are quite pretty."]],
    outro=[["H", "Did you see that? I found the exit myself!"]])

# ------------------------------------------------------------------ level 2: GREEN + RED
g = Grid()
g.rect('^', 15, 7, 18, 9)
g.put('r', 16, 11)         # red lamp below the spikes
g.put('H', 3, 8); g.put('N', 3, 10); g.put('X', 26, 8)
add(id="l2", cards=["red", "nearest"], num=2, title="GREEN + RED", glob=True, invert=False, exit_on=True,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Keep the hero away from the spikes.",
    intro=[["N", "Careful. The spikes are right in his path."],
           ["H", "Spikes? I eat spikes for breakfast."]],
    outro=[["H", "That was my plan all along."]])

# ------------------------------------------------------------------ level 3: GREEN + RED (timing)
g = Grid()
g.rect('^', 14, 1, 14, 7)         # a wall of spikes with a gap at the bottom
g.rect('^', 1, 14, 13, 15)         # a spike floor along the bottom: holding red too long pushes him into it
g.put('r', 8, 4)
g.put('H', 3, 6); g.put('N', 3, 8); g.put('X', 26, 6)
add(id="l3", num=3, title="GREEN + RED", glob=True, invert=False, exit_on=True,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Steer him through the gap. Mind the corner.",
    intro=[["N", "There is a gap at the bottom. Third tile from the floor."],
           ["H", "How do you know the tiles? ...Never mind. Onward!"]],
    outro=[["H", "I navigated that like a true professional."]])

# ------------------------------------------------------------------ level 4: BLUE
g = Grid()
g.rect('t', 13, 1, 13, 15)         # a wall of timed spikes, full height
g.rect('^', 20, 7, 22, 9)          # a spike pit in front of the exit
g.put('b', 7, 3)                   # blue lamp (north)
g.put('r', 16, 12)                 # red lamp, right below his path: pushes him north
g.put('H', 3, 8); g.put('N', 3, 10); g.put('X', 26, 8)
add(id="l4", cards=["blue"], num=4, title="BLUE", glob=True, invert=False, exit_on=True,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Freeze him, wait for the spikes to retract, then let him go.",
    intro=[["N", "The spike wall cycles every four seconds. Two out, two in."],
           ["H", "I could simply run through it."],
           ["N", "Please do not."]],
    outro=[["H", "I stopped time itself. Probably."]])

# ------------------------------------------------------------------ level 5: ORANGE
g = Grid()
g.put('D', 14, 6)                  # a sleeping dragon: wakes if he moves fast nearby
g.rect('~', 23, 8, 24, 10)         # fire in front of the exit
g.put('o', 20, 8)                  # orange lamp, beyond the dragon
g.put('r', 20, 10)                 # red lamp, right below the lane
g.put('H', 3, 8); g.put('N', 18, 9); g.put('X', 26, 8)
add(id="l5", cards=["orange"], num=5, title="ORANGE", glob=True, invert=False, exit_on=True,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Do not wake the ogre. Light the orange lamp so he creeps past.",
    intro=[["N", "That is Gerald. He sleeps lightly. Anything fast wakes him."],
           ["H", "You named the ogre?"],
           ["N", "...Everyone knows Gerald. Light the orange lamp, quickly."]],
    outro=[["H", "Gerald and I are practically friends now."]])

# ------------------------------------------------------------------ level 6: INVERT
g = Grid()
g.put('D', 14, 6)                  # the dragon again
g.put('B', 20, 8)                  # a blue lamp, ON: it holds the hero still
g.put('H', 3, 8); g.put('N', 3, 10); g.put('X', 26, 8)
add(id="l6", cards=["invert"], num=6, title="INVERT", glob=True, invert=True, exit_on=True,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Blue freezes him. Press Q: blue turns ORANGE and he creeps past Gerald. Recharge, then Q again.",
    intro=[["N", "This lantern is... an heirloom. Watch the blue lamp when I raise it."],
           ["H", "Does it make me stronger?"],
           ["N", "No. Blue becomes orange, so you creep instead of standing still. Only for five seconds."]],
    outro=[["H", "I invented sneaking just now."]])

# ------------------------------------------------------------------ level 7: GLOBAL COLOURS
g = Grid()
g.rect('^', 12, 8, 18, 12); g.rect('~', 14, 9, 16, 11)   # a field of spikes, with fire in the middle, between the two green lamps
g.rect('^', 1, 1, 6, 3); g.rect('^', 1, 13, 6, 15)   # more spikes: he must never be left without a lamp
g.put('G', 8, 8)                   # green lamp A near the start (ON)
g.put('o', 18, 4)                  # orange lamp above the spikes (nearer the exit than green A)
g.put('H', 3, 8); g.put('N', 3, 10); g.put('X', 26, 8)
add(id="l7", cards=["linked"], num=7, title="GLOBAL COLOURS", glob=True, invert=True, exit_on=True,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Switching one green lamp switches EVERY green lamp, even the exit.",
    intro=[["N", "The lamps are all wired together. One green lamp answers for every green lamp."],
           ["H", "So switching the one near me turns off the exit?"],
           ["N", "Quick learner. ...Suspiciously quick."]],
    outro=[["H", "I understood that from the start."]])

# ------------------------------------------------------------------ level 8: COMBINATION
g = Grid()
g.rect('t', 6, 1, 6, 15)           # timed spike wall right after the start
g.put('D', 17, 6)                  # sleeping dragon, lane below it
g.rect('~', 25, 8, 26, 10)         # fire pit before the exit
g.put('B', 3, 5)                   # blue lamp ON: holds him at the start
g.put('G', 10, 8)                  # green waypoint (ON; shares its state with the exit lamp)
g.put('o', 23, 8)                  # orange lamp beyond the dragon
g.put('r', 23, 10)                 # red lamp just below it
g.put('H', 2, 8); g.put('N', 2, 12); g.put('X', 28, 8)
add(id="l8", num=8, title="THE GAUNTLET", glob=True, invert=True, exit_on=True,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Wall, ogre, pit. Mind the green: it is wired to the exit.",
    intro=[["N", "A wall, an ogre, a pit. The usual. Take your time."],
           ["H", "I could handle this blindfolded."],
           ["N", "Please do not try that either."]],
    outro=[["H", "Gerald waved at me. We are close."]])

# ------------------------------------------------------------------ level 9: THE DEEP HALLS
g = Grid()
g.rect('u', 5, 1, 5, 15)           # timed spike wall (opposite phase to level 8's)
for y in (5, 6, 7, 9, 10, 11):      # hidden trap floors on both sides of a safe lane (row 8)
    g.rect('x', 9, y, 14, y)
g.put('D', 21, 6)                  # Gerald, again
g.put('B', 3, 4)                   # blue lamp ON: holds him at the start
g.put('G', 8, 8)                   # green waypoint (ON)
g.put('o', 15, 8)                  # orange lamp at the end of the trap lane
g.put('B', 25, 8)                  # a second blue lamp beyond the dragon (same colour, same state)
g.put('H', 2, 8); g.put('N', 2, 12); g.put('X', 28, 8)
add(id="l9", num=9, title="THE DEEP HALLS", glob=True, invert=True, exit_on=True,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Wall, hidden traps, ogre. Two blue lamps, one switch.",
    intro=[["N", "The deep halls. Every lesson so far, in one room."],
           ["H", "I have learned nothing and I regret nothing."]],
    outro=[["H", "These halls fear me. Correctly."]])

# ------------------------------------------------------------------ level 10: SWAP
# Same colour, same switch, but NOT always the same state: an ON green and an OFF green trade places
# when you press E. The exit is lit and he heads straight for the spikes: swap at once (the waypoint
# lights, the exit goes dark), then swap back once he stands at the waypoint. Back too early: spikes.
g = Grid()
g.rect('^', 9, 7, 21, 12); g.rect('~', 9, 9, 21, 10)   # a spike field in the middle, with a band of fire across it
g.put('g', 14, 3)                  # green waypoint, OFF (the exit starts ON: a mixed pair)
g.put('H', 3, 8); g.put('N', 17, 2); g.put('X', 27, 8)
add(id="l10", cards=["swap"], num=10, title="SWAP", glob=True, invert=True, exit_on=True,
    palette=0, exit_kind="door", map=g.rows(),
    hint="The exit is lit and he walks into spikes. Swap now; swap back only when he stands at the other green.",
    intro=[["N", "Look closely: the exit's green burns, the other green does not."],
           ["N", "Press E on either and they trade places. Quickly, now."],
           ["H", "Lamps that gossip. Wonderful."]],
    outro=[["H", "I zigged. Then I zagged. Masterfully."]])

# ------------------------------------------------------------------ level 11: TWO CLOCKS
# Four timed spike walls; 't' and 'u' are out in opposite halves of the 4 s cycle. Blue holds him at
# the start; release him so he slips through the first two, then hold the swap until the beat is right
# for the last two.
g = Grid()
g.rect('t', 8, 1, 8, 15); g.rect('u', 11, 1, 11, 15)
g.rect('t', 20, 1, 20, 15); g.rect('u', 23, 1, 23, 15)
g.put('B', 3, 5)                   # blue, ON: holds him at the start
g.put('G', 15, 8)                  # green waypoint between the clocks, ON (the exit is OFF)
g.put('H', 3, 8); g.put('N', 4, 11); g.put('X', 27, 8)
add(id="l11", num=11, title="TWO CLOCKS", glob=True, invert=True, exit_on=False,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Watch the walls twitch. Release blue just as the first wall sinks; swap greens on the next beat.",
    intro=[["N", "Four walls. Two clocks. Each wall sleeps while its neighbour bites."],
           ["H", "I shall simply walk at the correct speed."],
           ["N", "You have exactly one speed."]],
    outro=[["H", "Tick. Tock. Hero."]])

# ------------------------------------------------------------------ level 12: LIGHT SLEEPER
# Gerald sleeps right beside two timed walls. Only creeping is quiet enough, and the only lamp ahead is
# BLUE: each press of Q turns it orange for 5 s, so he creeps forward 5 tiles and freezes again. Each Q
# must land so that his creep crosses a wall while it is down. Swapping greens first parks him on blue.
g = Grid()
g.rect('t', 12, 1, 12, 15); g.rect('u', 15, 1, 15, 15)
g.rect('u', 22, 1, 22, 15)
g.put('D', 14, 10)                 # Gerald, asleep under the walls
g.put('G', 10, 8)                  # green waypoint, ON (the exit is OFF)
g.put('B', 18, 8)                  # blue, ON: beyond the walls
g.put('H', 2, 8); g.put('N', 8, 12); g.put('X', 27, 8)
add(id="l12", num=12, title="LIGHT SLEEPER", glob=True, invert=True, exit_on=False,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Swap greens at the lamp. Then Q on the beat: he must creep through each wall while it is down.",
    intro=[["N", "Gerald again. He sleeps beside the clockwork walls now."],
           ["H", "Then I shall tiptoe. In rhythm."],
           ["N", "That would be a first."]],
    outro=[["H", "Gerald did not even stir. I am a ghost."]])

# ------------------------------------------------------------------ level 13: SWITCHBOARD
# A zig-zag corridor cut through a field of spikes, and nine lamps on four switches. Greens: the first
# waypoint and the exit are ON, the third waypoint is OFF. Oranges: the second waypoint is OFF, a decoy
# in the east is ON. Blues: one holds him at the start, its partner in the north-east will freeze him at
# the end. Reds: one waits past the second waypoint, its partner near the first. Every press flips a
# lamp somewhere else too, so ORDER and MOMENT both matter, and two legs cross timed walls.
def corridor_grid(points, width=1.4):
    gg = Grid()
    def near(px, py):
        for (ax, ay), (bx, by) in zip(points, points[1:]):
            dx, dy = bx - ax, by - ay
            t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / float(dx * dx + dy * dy)))
            if (px - ax - t * dx) ** 2 + (py - ay - t * dy) ** 2 <= width * width:
                return True
        return False
    for y in range(1, H - 1):
        for x in range(1, W - 1):
            if not near(x, y):
                gg.put('^', x, y)
    return gg
g = corridor_grid([(2, 13), (7, 3), (14, 13), (21, 2), (26, 12)])
for (x, y) in [(17, 7), (18, 7), (18, 6), (17, 8)]:   # a timed wall across the third leg
    if g.g[y][x] == '.': g.put('u', x, y)
for (x, y) in [(23, 7), (24, 7), (25, 7), (23, 8), (24, 8), (25, 8)]:   # and one across the last leg
    if g.g[y][x] == '.': g.put('t', x, y)
g.put('D', 9, 7)                   # Gerald, beside the second leg: creep or wake him
g.put('G', 7, 3)                   # green 1, ON
g.put('o', 14, 13)                 # orange 2, OFF
g.put('g', 21, 2)                  # green 3, OFF
g.put('O', 28, 6)                  # orange decoy, ON (linked to orange 2)
g.put('B', 1, 14)                  # blue 1, ON: holds him at the start
g.put('b', 28, 2)                  # blue 2, OFF: lights up when you release him, and will freeze him at the end
g.put('R', 17, 15)                 # red 1, ON: harmless until orange 2 goes out, then it shoves him into spikes
g.put('r', 2, 2)                   # red 2, OFF: shoves him into spikes if it lights while he is near the first green
g.put('H', 2, 13); g.put('N', 4, 9); g.put('X', 26, 12)
add(id="l13", num=13, title="SWITCHBOARD", glob=True, invert=True, exit_on=True,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Light the next lamp before you put out his. Swap red while he creeps. Blue twice. Watch the walls' beat.",
    intro=[["N", "Many lamps, few switches. Every press lights one and darkens another."],
           ["H", "I love a good switchboard. I have never seen one."],
           ["N", "Then follow the lights. Exactly."]],
    outro=[["H", "Like threading a needle. With my whole body."]])

# ------------------------------------------------------------------ level 14: CROSSWIRED
# Three greens on one switch: the north-west waypoint and the exit are ON, the south waypoint is OFF.
# Each E swaps them. He goes NW, then (swap) south-east, then (swap) the orange near the exit takes over
# by itself and he creeps past Gerald. Every leg crosses a timed wall, so every swap has a beat.
g = Grid()
g.rect('u', 11, 1, 11, 15)         # timed wall on the NW -> south leg
g.rect('t', 19, 9, 28, 9)          # timed wall (horizontal) on the south -> orange leg
g.put('D', 22, 7)                  # Gerald, between the south waypoint and the exit
g.put('G', 3, 2)                   # waypoint 1, ON (same state as the exit)
g.put('g', 19, 13)                 # waypoint 2, OFF
g.put('O', 26, 5)                  # orange, ON the whole time: nearest once he is past waypoint 2
g.put('H', 2, 13); g.put('N', 7, 8); g.put('X', 27, 2)
add(id="l14", num=14, title="CROSSWIRED", glob=True, invert=True, exit_on=True,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Three greens, one switch. Swap only when he stands at a lamp AND the next wall is about to sink.",
    intro=[["N", "Three green lamps on one wire. Two burn, one sleeps."],
           ["H", "Like me after lunch."],
           ["N", "...And Gerald guards the door."]],
    outro=[["H", "I followed the lights. They were wrong. I was right."]])

# ------------------------------------------------------------------ level 15: THE FINAL LOCK
# Everything at once. Red pins him to the wall; release on the beat. At the first green: blue ON first, THEN swap
# the greens (the other order sends him running at Gerald). Two lantern creeps on the beat through the
# walls by the ogre. Release after the lantern fades, on the last wall's beat, to the north-east green;
# swap there (not before: spikes) and the lock's green takes him home.
g = Grid()
g.rect('u', 6, 1, 6, 15)           # the first beat
g.rect('t', 12, 1, 12, 15); g.rect('u', 15, 1, 15, 15)   # Gerald's walls
g.rect('u', 21, 1, 21, 7)          # the last beat, north of the spike field
g.rect('^', 18, 9, 24, 15); g.rect('~', 18, 12, 24, 15)   # spikes (and fire at the bottom) between the north-east green and the lock
g.rect('x', 2, 12, 4, 15); g.rect('x', 7, 1, 10, 3); g.rect('x', 7, 13, 10, 15)   # hidden traps for wanderers
g.put('D', 14, 10)                 # Gerald, one last time
g.put('R', 5, 8)                   # red, ON: pins him against the west wall at the start
g.put('G', 10, 8)                  # green 1, ON (same state as the lock)
g.put('b', 18, 8)                  # blue, OFF: the anchor for the lantern creep
g.put('g', 24, 3)                  # green 2, OFF
g.put('H', 2, 8); g.put('N', 4, 10); g.put('X', 27, 13)
add(id="l15", num=15, title="THE FINAL LOCK", glob=True, invert=True, exit_on=True,
    palette=0, exit_kind="lock", map=g.rows(),
    hint="Red off on the beat. At the green: BLUE ON, THEN SWAP. Creep, creep. Lantern fades, blue off on the beat. Swap at the last green.",
    intro=[["N", "The deepest chamber. The lock is at the far end. Just walk him there. Gently."],
           ["H", "Why are you so eager to see this lock broken?"],
           ["N", "...For Maribel's sake, of course."]],
    outro=[])

# ------------------------------------------------------------------ kill phase (the Demon Lord's trial)
# He is already walking to the exit lamp and nothing on that path is dangerous: he ESCAPES unless you act.
# The only deadly place is a spike chamber in the north-east (a two-cell door on its west side, a green lamp inside).
# The chamber's lamp and the exit lamp are the SAME colour, so they are always on or off together, and he obeys the
# nearer one. A divider wall forces him through a gap in the south. To kill him you must push him north (red) and then
# let go while he is high up, so that the chamber's lamp becomes his nearest green.
g = Grid()
g.rect('#', 12, 1, 12, 8)          # divider wall (north half); the gap is at rows 9..15
g.rect('#', 23, 1, 23, 5); g.rect('#', 23, 6, 28, 6)   # the chamber's west wall and floor
g.put('.', 23, 2); g.put('.', 23, 3)                   # its two-cell door
g.rect('^', 24, 4, 28, 5)          # spikes everywhere inside...
g.rect('^', 24, 2, 26, 3)          # ...including right behind the door
g.rect('^', 27, 3, 28, 3)
g.put('G', 27, 2)                  # the chamber's green lamp (ON, like the exit lamp)
g.put('r', 14, 14)                 # red lamp, just south-east of the gap: pushes him north
g.put('H', 3, 8); g.put('N', 6, 11); g.put('X', 26, 14)
add(id="l9k", num=0, phase="kill", title="TRIAL", glob=True, invert=True, exit_on=True,
    palette=2, exit_kind="door", map=g.rows(), hint="", intro=[], outro=[])

# ------------------------------------------------------------------ verified solutions & known mistakes
# Lamps are numbered in row-major scan order. Schedules: see scripts/level_sim.gd.
# expect: "EXIT" | "DIED" (any death) | "NOEXIT" (survives but never reaches the exit)
SOLUTIONS = {
    "l1": [[0.3, "sw", 0]],
    "l2": [[0.0, "on", 1], [-4, "off", 1, 3.0]],
    "l3": [[1.0, "on", 0], [-2, "off", 0, 12]],
    "l4": [[3.35, "on", 0], [5.6, "off", 0], [-3, "on", 2, 18], [-4, "off", 2, 3]],
    "l5": [[3.35, "sw", 0], [-5, "sw", 2, 0], [-5, "sw", 0, 0], [-4, "sw", 2, 6]],
    "l6": [[0.3, "off", 0], [-3, "on", 0, 10], [3.6, "inv"], [18.8, "inv"], [-5, "off", 0, 0]],
    "l7": [[-5, "sw", 0, 1], [-5, "sw", 2, 1], [-3, "sw", 2, 15], [-5, "sw", 0, 0]],
    "l8": [[0.5, "sw", 0], [-5, "sw", 2, 1], [-5, "sw", 1, 1], [-5, "sw", 4, 2], [-5, "sw", 1, 2], [-5, "sw", 2, 2], [-4, "sw", 4, 6]],
    "l9": [[3.5, "sw", 0], [-5, "sw", 2, 1], [-5, "sw", 1, 1], [-5, "sw", 3, 2], [-5, "sw", 2, 2], [15.2, "inv"], [30.2, "inv"], [-3, "sw", 4, 22], [35.2, "sw", 3]],
    "l10": [[0.8, "sw", 0], [-5, "sw", 0, 0]],
    "l11": [[1.4, "sw", 0], [9.0, "sw", 1]],
    "l12": [[-5, "sw", 0, 0], [4.1, "inv"], [16.1, "inv"], [22.8, "off", 1]],
    "l13": [[1.5, "sw", 7], [1.6, "sw", 6], [-5, "sw", 3, 3], [-3, "sw", 8, 11], [18.25, "sw", 6], [20.0, "sw", 7], [21.5, "sw", 6], [28.75, "sw", 5]],
    "l14": [[5.0, "sw", 0], [14.0, "sw", 3], [-5, "off", 2, 2]],
    "l15": [[3.0, "sw", 1], [6.5, "sw", 3], [8.5, "sw", 2], [12.1, "inv"], [24.1, "inv"], [31.2, "sw", 3], [-5, "sw", 0, 0]],
    "l9k": [[-3, "sw", 1, 14], [-4, "sw", 1, 5]],   # red on once he is past the gap; red off when he is high up
}
MISTAKES = {
    "l1": [("do nothing: nobody lights the lamp, so he just wanders", [], "NOEXIT"),
           ("switch the lamp on and straight off again", [[0.3, "sw", 0], [1.0, "sw", 0]], "NOEXIT")],
    "l2": [("do nothing: he walks into the spikes", [], "DIED"),
           ("red lamp never released", [[2.0, "on", 1]], "NOEXIT")],
    "l3": [("do nothing: spike wall", [], "DIED"),
           ("red never released: pushed down into the spike floor", [[1.0, "on", 0]], "DIED"),
           ("released too early: straight into the spike wall", [[1.0, "on", 0], [-2, "off", 0, 8]], "DIED")],
    "l4": [("do nothing: into the timed wall", [], "DIED"),
           ("released too early: caught by the timed wall", [[2.5, "on", 0], [4.2, "off", 0]], "DIED")],
    "l5": [("do nothing: he runs straight past the dragon", [], "DIED"),
           ("orange lit too late: he is already in the dragon's zone", [[3.6, "sw", 0]], "DIED")],
    "l6": [("run past the dragon (blue off)", [[0.3, "off", 0]], "DIED"),
           ("one inversion, then release: still inside the zone", [[0.3, "off", 0], [-3, "on", 0, 10], [3.6, "inv"], [9.0, "off", 0]], "DIED")],
    "l7": [("orange off before green is back on: no lamp at all", [[-5, "sw", 0, 1], [-5, "sw", 1, 1], [-5, "sw", 0, 0]], "DIED")],
    "l8": [("do nothing: frozen by the blue lamp", [], "NOEXIT")],
    "l9": [("released into the timed wall too early", [[1.0, "sw", 0]], "DIED")],
    "l10": [("do nothing: he walks straight into the spikes", [], "DIED"),
            ("swap back too early: his new straight line crosses the spikes", [[0.8, "sw", 0], [3.0, "sw", 0]], "DIED"),
            ("never swap back: he waits at the lamp forever", [[0.8, "sw", 0]], "NOEXIT")],
    "l11": [("release too early: the first wall", [[0.3, "sw", 0]], "DIED"),
            ("swap the moment he arrives: off the beat", [[1.4, "sw", 0], [-5, "sw", 1, 1]], "DIED")],
    "l12": [("blue off while the lantern is lit: the exit is red and pushes him back to Gerald", [[-5, "sw", 0, 0], [4.1, "inv"], [16.1, "inv"], [-5, "off", 1, 1]], "DIED"),
            ("Q off the beat: he creeps into a raised wall", [[-5, "sw", 0, 0], [5.6, "inv"]], "DIED")],
    "l13": [("green before orange at the first lamp: he runs straight for the third", [[1.5, "sw", 7], [-5, "sw", 3, 3]], "DIED"),
            ("red swapped too early: its partner shoves him into Gerald", [[1.5, "sw", 7], [1.6, "sw", 6], [-5, "sw", 3, 3], [-5, "sw", 8, 3]], "DIED"),
            ("red never swapped: it shoves him into Gerald", [[1.5, "sw", 7], [1.6, "sw", 6], [-5, "sw", 3, 3], [18.25, "sw", 6]], "DIED"),
            ("orange off the beat at the second lamp", [[1.5, "sw", 7], [1.6, "sw", 6], [-5, "sw", 3, 3], [-3, "sw", 8, 11], [20.0, "sw", 6]], "DIED"),
            ("blue left on: frozen beside the last green", [[1.5, "sw", 7], [1.6, "sw", 6], [-5, "sw", 3, 3], [-3, "sw", 8, 11], [18.25, "sw", 6], [21.5, "sw", 6], [24.75, "sw", 5]], "NOEXIT"),
            ("blue swapped while he stands at the second lamp: frozen there", [[1.5, "sw", 7], [1.6, "sw", 6], [-5, "sw", 3, 3], [-3, "sw", 8, 11], [17.0, "sw", 7], [18.25, "sw", 6]], "NOEXIT"),
            ("final green off the beat", [[1.5, "sw", 7], [1.6, "sw", 6], [-5, "sw", 3, 3], [-3, "sw", 8, 11], [18.25, "sw", 6], [20.0, "sw", 7], [21.5, "sw", 6], [26.0, "sw", 5]], "DIED")],
    "l14": [("swap the moment he reaches the first lamp: off the beat", [[-5, "sw", 0, 0]], "DIED"),
            ("second swap a beat late", [[5.0, "sw", 0], [15.0, "sw", 3]], "DIED")],
    "l15": [("swap greens before blue is on: he charges into the walls", [[3.0, "sw", 1], [-5, "sw", 2, 2]], "DIED"),
            ("release red off the beat", [[4.5, "sw", 1]], "DIED"),
            ("swap at the last green before he reaches it: the spikes", [[3.0, "sw", 1], [6.5, "sw", 3], [8.5, "sw", 2], [12.1, "inv"], [24.1, "inv"], [31.2, "sw", 3], [32.6, "sw", 0]], "DIED")],
    "l9k": [("do nothing: he walks to the exit lamp and escapes", [], "EXIT"),
            ("red on but never released: he is pinned against the wall (no kill)", [[-3, "sw", 1, 14]], "SURVIVES"),
            ("red released too early: he drifts back west, harmlessly (no kill)", [[-3, "sw", 1, 14], [-4, "sw", 1, 10]], "SURVIVES")],
}

def gd_str(s):
    return json.dumps(s)

def emit():
    for l in LEVELS:
        l['solution'] = SOLUTIONS.get(l['id'], [])
        l['mistakes'] = [{'name': n, 'schedule': sc, 'expect': ex} for (n, sc, ex) in MISTAKES.get(l['id'], [])]
    out = ['class_name LevelData', 'extends RefCounted',
           '## GENERATED by tools/gen_levels.py. Do not edit by hand: edit the generator and re-run it.',
           '## Every level is a 30x17 ASCII map plus metadata (legend: see level.gd).', '',
           'static func by_id(id: String) -> Dictionary:', '\tfor l in ALL:', '\t\tif l.id == id:', '\t\t\treturn l', '\treturn {}', '',
           'static func playable() -> Array[Dictionary]:', '\tvar out: Array[Dictionary] = []', '\tfor l in ALL:', '\t\tif l.num > 0 and l.get("phase", "") == "":', '\t\t\tout.append(l)', '\treturn out', '',
           'const ALL: Array[Dictionary] = [']
    for l in LEVELS:
        out.append('\t{')
        for k, v in l.items():
            key = 'global' if k == 'glob' else k
            if k == 'map':
                out.append('\t\t"map": [')
                for r in v:
                    out.append('\t\t\t%s,' % gd_str(r))
                out.append('\t\t],')
            else:
                out.append('\t\t%s: %s,' % (gd_str(key), json.dumps(v).replace('true', 'true').replace('false', 'false')))
        out.append('\t},')
    out.append(']')
    return '\n'.join(out) + '\n'

if __name__ == '__main__':
    open('scripts/level_data.gd', 'w').write(emit())
    print("wrote %d levels" % len(LEVELS))

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
add(id="prologue", num=0, title="OUTSIDE THE DUNGEON", teach="", par=0, glob=True, invert=False, exit_on=False,
    palette=1, exit_kind="dungeon", map=g.rows(), intro=[], outro=[], hint="")

# ------------------------------------------------------------------ level 1: GREEN
# A plain straight hall. One lamp at the far end, OFF. The NPC (player) starts beside it.
g = Grid()
g.rect('#', 1, 1, 28, 6); g.rect('#', 1, 10, 28, 15)   # a straight 3-wide hall (rows 7..9)
g.put('^', 14, 7); g.put('^', 14, 9)                    # two spikes beside the path
g.put('H', 3, 8); g.put('N', 24, 9); g.put('X', 26, 8)
add(id="l1", num=1, title="GREEN", teach="Green lamps pull the hero toward them.", par=14, glob=True, invert=False, exit_on=False,
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
add(id="l2", num=2, title="GREEN + RED", teach="Red lamps push the hero away.", par=21, glob=True, invert=False, exit_on=True,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Keep the hero away from the spikes.",
    intro=[["N", "Careful. The spikes are right in his path."],
           ["H", "Spikes? I eat spikes for breakfast."]],
    outro=[["H", "That was my plan all along."]])

# ------------------------------------------------------------------ level 3: GREEN + RED (timing)
g = Grid()
g.rect('^', 14, 1, 14, 7)         # a wall of spikes with a gap at the bottom
g.rect('x', 1, 15, 2, 15)          # hidden traps in the bottom-left corner
g.put('r', 8, 4)
g.put('H', 3, 6); g.put('N', 3, 8); g.put('X', 26, 6)
add(id="l3", num=3, title="GREEN + RED", teach="Switch lamps at the right moment.", par=19, glob=True, invert=False, exit_on=True,
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
add(id="l4", num=4, title="BLUE", teach="Blue lamps freeze the hero in place.", par=17, glob=True, invert=False, exit_on=True,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Freeze him, wait for the spikes to retract, then let him go.",
    intro=[["N", "The spike wall cycles every four seconds. Two out, two in."],
           ["H", "I could simply run through it."],
           ["N", "Please do not."]],
    outro=[["H", "I stopped time itself. Probably."]])

# ------------------------------------------------------------------ level 5: ORANGE
g = Grid()
g.put('D', 14, 6)                  # a sleeping dragon: wakes if he moves fast nearby
g.rect('^', 23, 8, 24, 10)         # spikes in front of the exit
g.put('o', 20, 8)                  # orange lamp, beyond the dragon
g.put('r', 20, 10)                 # red lamp, right below the lane
g.put('H', 3, 8); g.put('N', 18, 9); g.put('X', 26, 8)
add(id="l5", num=5, title="ORANGE", teach="Orange lamps pull the hero slowly: perfect for sneaking.", par=20, glob=True, invert=False, exit_on=True,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Do not wake the dragon. Light the orange lamp so he creeps past.",
    intro=[["N", "That is Gerald. He sleeps lightly. Anything fast wakes him."],
           ["H", "You named the dragon?"],
           ["N", "...Everyone knows Gerald. Light the orange lamp, quickly."]],
    outro=[["H", "Gerald and I are practically friends now."]])

# ------------------------------------------------------------------ level 6: INVERT
g = Grid()
g.put('D', 14, 6)                  # the dragon again
g.put('B', 20, 8)                  # a blue lamp, ON: it holds the hero still
g.put('H', 3, 8); g.put('N', 3, 10); g.put('X', 26, 8)
add(id="l6", num=6, title="INVERT", teach="The invert lantern (Q): for 5 seconds every lamp becomes its opposite colour and behaviour.", par=34, glob=True, invert=True, exit_on=True,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Blue holds him. Inverted, it becomes orange. Mind the cooldown.",
    intro=[["N", "This lantern is... an heirloom. Press Q. Green becomes red, blue becomes orange."],
           ["H", "Does it make me stronger?"],
           ["N", "It makes the lamps stranger. Five seconds, then it needs ten to recover."]],
    outro=[["H", "I invented sneaking just now."]])

# ------------------------------------------------------------------ level 7: GLOBAL COLOURS
g = Grid()
g.rect('^', 12, 8, 18, 12)         # a spike field between the two green lamps
g.rect('^', 1, 1, 6, 3); g.rect('^', 1, 13, 6, 15)   # more spikes: he must never be left without a lamp
g.put('G', 8, 8)                   # green lamp A near the start (ON)
g.put('o', 18, 4)                  # orange lamp above the spikes (nearer the exit than green A)
g.put('H', 3, 8); g.put('N', 3, 10); g.put('X', 26, 8)
add(id="l7", num=7, title="GLOBAL COLOURS", teach="Same colour, same state, always. Here it matters: the exit is a green lamp too.", par=23, glob=True, invert=True, exit_on=True,
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
g.rect('^', 25, 8, 26, 10)         # spike pit before the exit
g.put('B', 3, 5)                   # blue lamp ON: holds him at the start
g.put('G', 10, 8)                  # green waypoint (ON; shares its state with the exit lamp)
g.put('o', 23, 8)                  # orange lamp beyond the dragon
g.put('r', 23, 10)                 # red lamp just below it
g.put('H', 2, 8); g.put('N', 2, 12); g.put('X', 28, 8)
add(id="l8", num=8, title="THE GAUNTLET", teach="Everything at once. Remember: same colour, same state.", par=33, glob=True, invert=True, exit_on=True,
    palette=0, exit_kind="door", map=g.rows(),
    hint="Wall, dragon, pit. Mind the green: it is wired to the exit.",
    intro=[["N", "A wall, a dragon, a pit. The usual. Take your time."],
           ["H", "I could handle this blindfolded."],
           ["N", "Please do not try that either."]],
    outro=[["H", "Gerald waved at me. We are close."]])

# ------------------------------------------------------------------ level 9: THE FINAL DUNGEON
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
add(id="l9", num=9, title="THE FINAL LOCK", teach="Everything you have learned. Bring him to the lock.", par=41, glob=True, invert=True, exit_on=True,
    palette=0, exit_kind="lock", map=g.rows(),
    hint="Wall, hidden traps, dragon. Then the lock.",
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
add(id="l9k", num=0, phase="kill", title="TRIAL", teach="", par=0, glob=True, invert=True, exit_on=True,
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
    "l9k": [[-3, "sw", 1, 14], [-4, "sw", 1, 5]],   # red on once he is past the gap; red off when he is high up
}
MISTAKES = {
    "l1": [("do nothing: nobody lights the lamp, so he just wanders", [], "NOEXIT"),
           ("switch the lamp on and straight off again", [[0.3, "sw", 0], [1.0, "sw", 0]], "NOEXIT")],
    "l2": [("do nothing: he walks into the spikes", [], "DIED"),
           ("red lamp never released", [[2.0, "on", 1]], "NOEXIT")],
    "l3": [("do nothing: spike wall", [], "DIED"),
           ("red never released: pushed into the hidden trap", [[1.0, "on", 0]], "DIED"),
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

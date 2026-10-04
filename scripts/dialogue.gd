class_name Dialogue
extends RefCounted
## All story and ambient lines. The hero is naive, overconfident and incompetent;
## the NPC is a helpful guide who, subtly, knows far too much about the dungeon.
## Comedy comes from personality and reactions, never from breaking the lamp rules.
## Speakers: "H" = hero, "N" = NPC.

# Ambient hero reactions, keyed by the lamp behaviour colour he is obeying (-1 = no lamp).
const AMBIENT := {
	0: ["Ooh, shiny!", "Destiny is calling!", "I'm drawn to it... heroically.", "Yes! Exactly where I was going!"],
	1: ["Whoa-whoa-whoa!", "I'm retreating TACTICALLY!", "Something is pushing me! Rude!", "I meant to go this way!"],
	2: ["Sneaking. Very stealthy.", "Tiptoe, tiptoe...", "Slow and heroic.", "Nobody sneaks like me."],
	3: ["I... can't... move! Fine!", "Brr! Why am I a statue?!", "I meant to pose like this.", "This is a very dramatic pause."],
	-1: ["Where am I going?", "Uh... that way?", "No lamps? I'll improvise!", "I know exactly where I am. Probably."],
}

const DEATH := {
	"spike": ["Ow ow OW!", "Spikes! Who puts SPIKES here?!", "That floor was pointy!"],
	"fire": ["I'm on fire! Heroically!", "Hot hot HOT!", "Why is the floor on fire?!"],
	"trap": ["The floor betrayed me!", "A trap?! There was NOTHING there!", "Nobody warned me about the floor!"],
	"dragon": ["Gerald?! You were asleep!", "Dragon! A very awake dragon!", "I only walked a LITTLE fast!"],
}

const NPC_DEATH := ["Oh dear. Shall we try again?", "Never mind. Once more.", "Hm. Not quite. Again.", "He recovers quickly. Let us continue."]

const CREDIT_GRAB := ["I was just about to do that!", "See? Teamwork. Mostly me.", "That lamp was my idea.", "Good thing I planned that."]

const CLEAR := ["Another flawless victory!", "Did you see me? Magnificent!", "Easy. I barely tried.", "The dungeon fears me!"]

const PROLOGUE := [
	["H", "Behold: the Dungeon of Doom! And behold ME, the greatest hero in the land!"],
	["N", "Hero! Please, I need your help!"],
	["H", "A citizen in distress! Speak, peasant!"],
	["N", "My wife was dragged into the dungeon by the terrible Demon Lord!"],
	["H", "The Demon Lord? Never heard of him. Is he tall?"],
	["N", "Very. But I know this dungeon. I can guide you."],
	["H", "I need no guide! I am a hero!"],
	["N", "The old lamps still work. They will show you the way."],
	["H", "Lamps? Pfft. ...What do they do?"],
	["N", "You will find out. Trust me."],
	["H", "For your lovely wife! What was her name again?"],
	["N", "...Maribel. Yes. Maribel."],
	["H", "Hold on, Maribel! Your hero is coming!"],
]

const LOCK := [
	["H", "The final lock! Stand back. I shall break it with my... mighty... foot!"],
	["H", "HYAAAH!"],
]

const REVEAL := [
	["N", "Thank you. Truly. Four thousand years I waited for someone foolish enough."],
	["H", "...What? Wait. Are you the Demon Lord?"],
	["N", "Do the horns not give it away?"],
	["H", "I thought they were a hat!"],
	["H", "But your wife! Maribel!"],
	["N", "There is no Maribel. There never was."],
	["H", "That is... really rude!"],
	["N", "The lock is broken, and the dungeon is mine again. Now: let us see how well you walk among MY lamps."],
]

const ESCAPE := [
	["H", "I'm free! Ha! Outrun by a hero!"],
	["N", "No. No, no, no. Again."],
]

const DEATH_FINAL := [
	["H", "Tell Maribel... I tried my best..."],
	["N", "There is no Maribel."],
	["H", "...Then who do I tell?"],
]

const ENDING_CARD := "THE END\n\nThe Demon Lord reclaimed his dungeon.\nThe lamps burned in his honour for a thousand years.\n\nThe hero never did find Maribel."

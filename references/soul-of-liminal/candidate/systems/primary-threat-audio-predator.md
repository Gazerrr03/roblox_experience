# Candidate Primary Threat: Audio Predator

## Routing

- Related: `formal/threat-design-bible.md`
- Superseded by: `formal/threat-design-bible.md` 现在承担当前 headline threat 的正式规范职责。
- Feeds into: `formal/threat-design-bible.md`


## Core Read

The main threat in `Maze` should be a fast, feral execution predator.
It is not mainly a line-of-sight hunter.
It is a hearing-driven killer that investigates sound sources and punishes loud mistakes.

## Candidate Behavior Pillars

- It reacts to sound before it reacts to direct visual contact.
- Louder sounds are more dangerous than quieter sounds.
- It does not need instant omniscience; it should move toward the source area first.
- Once nearby, it becomes much more lethal because the player is fragile.
- If the player keeps producing noise while panicking, the predator closes the gap quickly.

## Candidate Emotional Goal

The player should feel:

- "It does not know exactly where I am yet."
- "But it is coming toward what I just did."
- "If I keep making noise, I will finish the hunt for it."

## Candidate Sound Sources

- sprinting and fast movement
- heavy landings and collisions
- door interaction and forced entry
- traps and alarms
- loud tool use
- voice or microphone-driven events if that feature is later enabled

## Candidate Combat Role

This is the headline predator.
Small enemies may wound or pressure players, but this one defines the fear ceiling.
If mishandled, it can kill quickly and force players to respect information.

## Candidate Chase Loop

- players notice the threat and instinctively run
- running creates more noise and keeps the predator highly engaged
- sprinting may be the only way to stay faster than the predator
- stamina is limited, so panic-running creates a delayed death sentence
- when stamina collapses, the predator closes distance and can kill quickly

This creates a brutal lesson:
the same action that briefly saves the player also intensifies the hunt.

## Candidate Voice Layer

If microphone-driven sound is later supported, panic communication can become a
second-order risk:

- a fleeing player calls for help
- teammates respond out loud
- additional sound sources expose more positions
- the predator may widen or shift its interest accordingly

## Candidate Encounter Density

Current direction:

- use only a very small number of these headline predators in one level
- two is a plausible upper target for a full encounter space

Too many of them would flatten the fear curve and damage balance.

## Open Questions

- How much visual confirmation should it need after reaching the sound area?
- Should continuous noise stack threat faster than repeated separated noise?
- Should some tools be strategically useful because they create controlled distraction noise?

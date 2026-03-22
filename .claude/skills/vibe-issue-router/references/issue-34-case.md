# Issue 34 Case

Issue `#34` looked maze-local at first because pickup happens in the maze.

It became cross-vibe once the intent was clarified:

- backpack should exist in both `run` and `maze`
- inventory should survive `run -> maze -> run`

Recommended routing:

- `Owner vibe`: `contract`
- `Affected vibes`: `contract`, `run`, `maze`
- `Base branch`: `main`
- `Landing branch`: `main`
- `Delivery mode`: `cross-vibe integration`

Use this case to teach that the interaction surface is not always the true owner.

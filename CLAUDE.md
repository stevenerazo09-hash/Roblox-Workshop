# Roblox projects: shared rules

Shared knowledge lives in `game-notes/`. The index of everything in it:

@game-notes/index.md

Before building anything new:
1. Read `game-notes/index.md`.
2. If a library item already does the job, copy it into the game's `src/` and adapt it. Do not rebuild it.
3. Say in your plan which library items you checked and which you reused.

After building or learning something reusable:
1. Create or update its folder in `game-notes/library/` (`ui`, `scripts`, or `map-parts`), using `game-notes/library/_template/README.md`.
2. Add one line for it to `game-notes/index.md`.
3. Put lessons that are not components in `game-notes/lessons/`, one topic per note.

Only add reusable things. Logic specific to one game stays in that game's folder.
Do not move or delete files in `game-notes/` without asking.
UI rule for every game: screen UI uses Scale only, never Offset. See game-notes/lessons/ui-scale-only.md.

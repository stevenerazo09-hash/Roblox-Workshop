# Pipeline test: Baseplate UI panel (2026-10-27)

Request: one simple screen UI panel for Baseplate (title, one line of text, close button), reusing a library entry.

Because subagents cannot start subagents (see setup-verification item 1), the main session runs each stage. Agents ran as general-purpose subagents with the agent file's rules and model; the synced custom agents load only in a new session.

| Stage | Model | Result | Time / size |
|---|---|---|---|
| 1. Planner | haiku | DONE. Blueprint `Baseplate/blueprints/test-ui-panel.md`, Status "draft", reused [[scale-ui-kit]]. | about 16 s, about 63k tokens |
| 2. Owner approval | owner | DONE. Owner answered the open questions and asked the work to proceed; I set Status to "approved". | - |
| 3. Builder | opus | DONE. Status "built". Wrote `Baseplate/src/client/UI.lua` and `TestUIPanel.client.lua`. Chose a LocalScript (not a ModuleScript) so it runs without editing `init.client.luau`, so other scripts cannot call Show/Hide. | about 98 s, 24 tool calls, about 86k tokens |
| 4. Checker | sonnet | PASS: rojo build; no non-zero Offset in code; read-through of Show/Hide, close button, key P, stroke rescale. NOT RUN: Play mode, Device Simulator, `UI.tracked()` counts (need Studio). Luau analyzer not installed. | about 13 s, about 69k tokens |
| 5. Security | haiku | No findings. Baseplate/src has no remotes. | about 9 s, about 68k tokens |
| 6. Librarian | haiku | DONE. Added a Variants note to the scale-ui-kit README, a new lesson [[key-conflicts]], and its index line. | not timed |

Decisions made along the way (the owner should know)
- The owner asked for M, but M already opens the System menu (`Baseplate/src/shared/Sandbox/Config.lua:190`). The panel uses P instead. It is the first line of `TestUIPanel.client.lua`.
- The click sound reuses the System menu's placeholder id from Config; no new asset id was added.
- The icon helper was removed from the copied `UI.lua`.

Not proven: the panel has never run in Studio. Nothing was published.

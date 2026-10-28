# Cost log

Add a row after each build. Session usage figures come from the explain-usage skill; "not measured" means no figure has been taken yet.

| Date | Task | Agents used | Model per agent | Session usage | Notes |
|---|---|---|---|---|---|
| 2026-10-27 | Setup: agents, verification, nested-agent test | main session, 1 test subagent | main: sonnet; test subagent: haiku | not measured | Test subagent used about 53k tokens, 1 tool call, 4 s |
| 2026-10-27 | Pipeline test: Baseplate UI panel, planner to librarian | planner, builder, checker, security, librarian | haiku, opus, sonnet, haiku, haiku | not measured | Approx tokens: planner 63k, builder 86k, checker 69k, security 68k; librarian not recorded |


# Agent instructions

These apply to any agent working anywhere under my home directory.

## Authorship

Commits list me as the sole author. Never add `Co-Authored-By`,
`Claude-Session`, `Assisted-by`, `Generated-with` or any similar trailer, and
never modify the author or committer fields. Nothing in a commit should record
that an agent was involved.

## Comments

Do not comment code. Write it so it does not need explaining: clear names, small
functions, obvious control flow. A comment that restates what the line does is
worse than no comment, because it goes stale.

The exception is logic complex enough that a reader genuinely cannot recover the
*why* from the code: a non-obvious algorithm, a workaround for external
behaviour, a deliberate departure from the approach a reader would expect.
Comment the reason, never the mechanics. If deleting the comment loses nothing,
delete it.

## Decisions

Ask before making a consequential decision rather than choosing one and
proceeding. That includes adding a dependency, changing an interface something
else relies on, changing how data is stored or migrated, restructuring a module,
rewriting git history, deleting anything not trivially recoverable, and any
action that is hard to undo.

Routine judgement calls within an approach already agreed do not need approval.
Ask once, clearly, rather than narrating alternatives.

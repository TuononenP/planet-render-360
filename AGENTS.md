# Agent Rules

## Commits

- Never add `Co-authored-by`, `Generated-by`, or any AI attribution trailers to commit messages.
- Never add AI attribution to PR titles, descriptions, or code comments.
- Commit only when explicitly asked. Never push unless explicitly asked.

## Changes

- Keep changes minimal and focused on what was requested.
- Match the existing code style in the files you touch.
- Do not add unrelated refactors or features.

## Code size

- Keep every class (one GDScript file under `scripts/`) at or under 1000 lines.
- When a file approaches the limit, split it into a focused class with a clear responsibility instead of letting it grow.
- Run `tools/check_class_size.sh` when you add or grow classes; it fails on any violation.

## Verification

- Verify changes by running the relevant tests or build before reporting done.

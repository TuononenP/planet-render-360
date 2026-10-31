# Agent Rules

## Commits

- Never add `Co-authored-by`, `Generated-by`, or any AI attribution trailers to commit messages.
- Never add AI attribution to PR titles, descriptions, or code comments.
- Commit only when explicitly asked. Never push unless explicitly asked.

## Changes

- Keep changes minimal and focused on what was requested.
- Match the existing code style in the files you touch.
- Do not add unrelated refactors or features.

## Design system

- Always try to follow the Planet Render 360 design system: https://claude.ai/artifact/HR5RqAmnw7rfRyHWozGGFT
- Use its tokens, typography, iconography, glass recipes, voice and data formatting for any UI or visual change; read its `project/README.md` first.

## Code size

- Keep every class (one GDScript file under `scripts/`) at or under 1000 lines.
- When a file approaches the limit, split it into a focused class with a clear responsibility instead of letting it grow.
- Run `tools/check_class_size.sh` when you add or grow classes; it fails on any violation.

## Verification

- Verify changes by running the relevant tests or build before reporting done.
- Run Godot tests so they don't interrupt the user: always pass `--headless` (no window, no focus steal) and run them with `run_in_background`, then check the result when notified.
- Only `tests/screenshot_test.gd` and `tests/world_cache_test.gd` need a real window; run them in the background too, and batch them at the end instead of after every change.
- Screenshot/capture scripts (ad-hoc `godot --path . --script ...` runs, not just `tests/`) also open a window. Never pass `--always-on-top`; run them in the background, batch captures into one run, and add `--position 4000,4000` so the window opens off the user's screen.
- Launch every windowed Godot run through `tools/godot_bg.sh` (or `godot` when it is installed as `~/.local/bin/godot`), never the `.app` binary directly: Godot activates itself on macOS, and the wrapper hands focus back to the user's editor and adds `--windowed` so the full-screen project setting doesn't take over a Space.

# Plan: No cache size limit — per-place cache clearing from a menu list

> Status: not started. This file is the shared progress tracker for parallel agents.
> How to use it: claim one lane, change its first unchecked task to `- [/] <lane> …`
> while you work on it, then change it to `- [x]` only after that task's own validation
> passes. Never tick a box on another agent's evidence. If your change invalidates a
> ticked task, untick it and say why in the pull request. Phases state their real
> dependencies; tasks inside a phase run in parallel unless they share a file
> (see "File ownership" below).

## Goal

Stop limiting the on-device cache by size. Remove the automatic size cap and its
eviction entirely — the cache grows as the person explores, and nothing is deleted
behind their back to fit a number. In exchange, give the person an easy, explicit
way to free space place by place: a list of places in the menu (Settings →
Storage), each row showing how much that place holds on the device, with a clear
action that frees that place's cache and nothing else's.

## Decisions already made (do not re-litigate; flag conflicts as risks)

1. **No size limit, not a bigger limit.** The Settings size-limit slider, the
   automatic LRU trimming to a cap, the built-worlds half-share budget applied
   automatically, and the "cache full, raise the limit?" offer all go away.
   Total cache size stays visible as information only. Running out of device
   storage is then an ordinary fetch/save failure (already surfaced by existing
   error paths), not something the app pre-empts by deleting places.
2. **Primary surface: Settings → Storage.** The Storage page gains a "Places"
   list under the existing usage readout. Storage is where the person already
   manages the cache (total size and Clear cache today), and it is reachable
   from the settings menu on phones and the rail on wider windows.
3. **Two different verbs, kept distinct.**
   - Storage list **Clear** frees a place's cached data and built worlds but
     keeps the place in History, with its favourite, camera and thumbnail —
     exactly like today's whole-cache Clear cache keeps History entries.
   - History's existing **Remove from cache** keeps its current meaning
     (frees the cache *and* drops the History entry, thumbnail included),
     but must free the same complete set of files as Storage Clear.
     Today it silently leaves built worlds behind.
4. **Per-place size means attributable size.** A place's row shows the bytes of
   the files that exist to serve that place (downloaded data for it plus its
   built worlds). Tiles are shared between nearby places, so per-place sizes
   may add up to more than the device total; the total at the top of the page
   remains the true on-disk total, and rows are labelled so this is not read
   as an error.
5. **Nothing else about caching changes.** Fetch keys, `DATA_VERSION`,
   thumbnails, offline warming, capture/test suppression hooks' *purpose*
   (tests still must not touch the real cache), and Clear-all-cache behaviour
   otherwise stay as they are. No data migration: existing caches simply stop
   being trimmed.

## Current state (evidence this plan is built on)

- The cap lives in [cache_store.gd](/Users/petri/Documents/GithubProjects/planet-render-360/scripts/data/cache_store.gd):
  `max_cache_bytes` (default 2 GB), `MAX_LIMIT_MB` (20 GB), `data_cap()`,
  `TRIM_TO`, and `enforce_size_cap()` / `_scan_and_trim()`, which evict
  oldest-atime-first on a worker whenever `note_written()` pushes the tracked
  total over the cap. The LRU index (`user://cache/lru.json`) also backs the
  Settings size readout via `data_bytes()`, so accounting must survive the cap.
- Built worlds share the same limit: [world_cache.gd](/Users/petri/Documents/GithubProjects/planet-render-360/scripts/render/world_cache.gd)
  keeps at most half via `enforce_budget()`, called automatically from
  `CacheStore.enforce_size_cap()` and after every `WorldCache.save_async()`.
  World files are per place + preset + season:
  `world_<lat_q>_<lon_q>_p<preset>_s<season>_<hash>.scn/.ground`, so a place's
  worlds are enumerable by filename prefix.
- The limit is user-visible in [settings_pages.gd](/Users/petri/Documents/GithubProjects/planet-render-360/scripts/screens/settings_pages.gd)
  `storage()` (usage bar "of <limit>", exponential slider 256 MB–20 GB) and
  [settings_screen.gd](/Users/petri/Documents/GithubProjects/planet-render-360/scripts/screens/settings_screen.gd)
  (`_limit_slider`, `_on_cache_limit()`, the `storage` category summary
  "X of Y"), wired through `UiPrefs.apply()` (`cache_limit_mb`) and
  `RenderSettings` defaults (`cache_limit_mb`, `cache_full_asked_mb`).
  [main.gd](/Users/petri/Documents/GithubProjects/planet-render-360/scripts/main.gd) adds `_on_cache_full()` /
  `_offer_cache_room()`: a toast offering to double the limit after eviction.
- Per-place clearing already half-exists in
  [history_screen.gd](/Users/petri/Documents/GithubProjects/planet-render-360/scripts/screens/history_screen.gd):
  trash button, swipe-left and a context menu call
  `CacheStore.remove_place(entry)`, and there is a Clear-all-cache button.
  But `remove_place()` deletes only the data files in
  `CacheStore.entry_cache_keys(entry)` for the entry's *saved* preset
  (plus the thumbnail) and drops the entry. It does not delete built worlds
  (`user://worlds`), and files fetched at other presets, streamed recentred
  centres, map tiles, search/Wikipedia files and other unattributed files
  are outside its key set. `CacheStore.entry_bytes()` likewise counts data
  only, so History's size badge understates a place with a built world.
- Whole-cache clearing is `OfflineDownloader.clear_cache()` (move
  `user://cache` and `user://worlds` aside, delete on a worker), used by both
  Settings and History behind `SettingsRows.confirm()`.
- Tests touching this area today: `tests/settings_test.gd` (storage summary
  asserts "… MB of …"), `tests/cache_capture_safety_test.gd` (sets
  `max_cache_bytes = 1` + `eviction_suppressed` and asserts no trim starts),
  `tests/world_cache_test.gd` (windowed; asserts `enforce_budget(1)` evicts
  oldest-first), `tests/viewer_tools_test.gd` (`remove_place` deletes the
  thumbnail). Test hooks to reuse: `CacheStore.dir_override`,
  `CacheStore.history_override`, `WorldCache.dir_override`,
  `PlaceThumb.dir_override`.
- Design system: reuse `UiTheme` tokens, `SettingsRows.group()/row()/
  destructive()/confirm()`, `Readout`, `UiIcon` ("trash-2", "hard-drive") and
  `UiTheme.cache_size()` formatting, as the current Storage and History UI
  does. No new colours, row shapes or dialog patterns.

## Scope

In scope: removing the size limit and its UI/offers; a per-place cache
inventory (data + built worlds); the Settings → Storage places list with
per-place Clear; unifying History's remove on the same complete deletion;
tests and docs for all of it.

Non-goals: no automatic eviction of any kind (no "smart" cleanup, no age-based
deletion); no per-layer clearing UI (DEM/satellite/OSM separately); no change
to what gets cached, fetch keys or quality presets; no cloud/account storage;
no new History features beyond making its existing remove complete and honest.

## File ownership (parallel-safety)

One owner per file at a time; a second agent reviews instead of editing.

| File | Owning lane | Notes |
| --- | --- | --- |
| [cache_store.gd](/Users/petri/Documents/GithubProjects/planet-render-360/scripts/data/cache_store.gd) (797 lines) | Lane A | Hot file. If additions push it near the 1000-line class limit, split the per-place inventory into a new focused class instead of growing it; run `tools/check_class_size.sh`. |
| [world_cache.gd](/Users/petri/Documents/GithubProjects/planet-render-360/scripts/render/world_cache.gd) | Lane A | Same owner as `cache_store.gd` — the two call each other. |
| [offline_downloader.gd](/Users/petri/Documents/GithubProjects/planet-render-360/scripts/data/offline_downloader.gd) | Lane A | Only if `clear_cache()` / `cache_size_bytes()` need changes. |
| [settings_pages.gd](/Users/petri/Documents/GithubProjects/planet-render-360/scripts/screens/settings_pages.gd) | Lane B | Builds the Storage page; Lane C only adds tests against it. |
| [settings_screen.gd](/Users/petri/Documents/GithubProjects/planet-render-360/scripts/screens/settings_screen.gd) | Lane B | Owns refresh, summaries, confirm wiring for the Storage page. |
| [history_screen.gd](/Users/petri/Documents/GithubProjects/planet-render-360/scripts/screens/history_screen.gd) | Lane C | After Lane A freezes the clear/remove API (Phase 2 gate). |
| [main.gd](/Users/petri/Documents/GithubProjects/planet-render-360/scripts/main.gd), [ui_prefs.gd](/Users/petri/Documents/GithubProjects/planet-render-360/scripts/ui_prefs.gd), [render_settings.gd](/Users/petri/Documents/GithubProjects/planet-render-360/scripts/render/render_settings.gd) | Lane B | Limit-pref and cache-full-offer removal. Small, do early. |
| `tests/*` | Lane C | New `tests/place_cache_clear_test.gd`; edits to existing tests stay with whoever changes the behaviour they assert, reviewed by Lane C. |
| `README.md`, docs | Any, last | One docs pass in Phase 5, not per-lane edits. |

## Phase 0 — Inventory and API freeze (gate for all code phases)

Three short investigations, one per lane, in parallel. No behaviour change.

- [x] **Lane A — cache inventory.** List every store that holds per-place
  bytes: `user://cache` key families from `CacheStore.place_cache_keys()`
  across *all four* presets (satellite zoom/span and OSM radius/ring differ
  by preset, so one saved preset's key set is not the whole place),
  legacy saved `cache_keys`, `user://worlds` filename prefixes per place,
  `user://thumbs`. List what cannot be attributed to a place (map tiles,
  search/Wikipedia/climate files, `SharedTexture` files, worlds saved for
  streamed recentred centres away from the History coordinate) and decide
  how each is reported: it must land in an explicit "Other cache" bucket so
  the list plus Other explains the page total. Record the result as a short
  table at the top of the Phase 2 section (edit this file).
- [x] **Lane B — limit surface inventory.** Grep-confirm the complete set of
  limit touch-points (`cache_limit_mb`, `cache_full_asked_mb`,
  `max_cache_bytes`, `MAX_LIMIT_MB`, `on_full`, `enforce_size_cap`,
  `data_cap`, the storage slider/bar, the cache-full toast in `Main`) and
  note which prefs become dead. Decide the Storage page's post-limit shape:
  usage readout shows the total alone (no bar against a limit, or a bar is
  dropped entirely), category summary becomes just the total size.
- [x] **Lane C — semantics and test inventory.** Write down, as testable
  statements, the Decision 3 verb split (Storage Clear keeps entry /
  favourite / camera / thumbnail; History Remove drops them), the
  shared-tile consequence (clearing one place can make a nearby place
  re-download a shared tile — already the documented `remove_place`
  behaviour), and what happens when clearing the place currently open in
  the viewer or with a world save in flight. Check how Settings is reached
  while a place is open (attribution → Data sources path) and whether a
  save/prefetch can be running then; record the guard the API needs
  (refuse-and-report vs wait) in the Phase 2 contract.

**Phase 0 exit gate (one agent, after the three land):**

- [x] Freeze the Phase 2 API in this file: function names, argument
  (History entry Dictionary), return shape (files removed, bytes freed,
  per-store breakdown, busy/refused result), and the report row shape the
  UI consumes (name, lat, lon, data bytes, world bytes, total bytes,
  cached state). No UI or deletion code starts before this box is ticked.

Validation: the three inventories are in this file or linked from it; every
grep hit for the limit symbols is accounted for; no code changed.

### Phase 0 outcome — frozen API (2026-11-12, implementation session)

- Inventories confirmed against the "Current state" section above: limit
  touch-points are exactly `cache_store.gd`, `world_cache.gd`,
  `offline_downloader.gd` (recount only), `ui_prefs.gd`,
  `render_settings.gd` PREF_DEFAULTS, `settings_pages.gd` `storage()`,
  `settings_screen.gd`, and `main.gd`'s cache-full toast. `eviction_suppressed`
  is kept as a deprecated no-op static (10+ test files set it; with no eviction
  it has nothing to gate) rather than churned out of every test.
  `WorldCache.enforce_budget(max_bytes, keep_newest)` stays explicit-only;
  its default becomes "no eviction, recount only".
- Unattributed bytes (map tiles, search/Wikipedia/climate, shared textures,
  streamed recentred worlds, orphan worlds, worlds of places past the
  50-entry History cap) are reported as one **Other cache** figure:
  `other_bytes = max(0, total_data - unique_attributed_data) + max(0, total_worlds - attributed_worlds)`,
  where the page total is `OfflineDownloader.cache_size_bytes()` re-read after
  any clear, never summed from rows.
- Frozen API:
  - `CacheStore.reconcile_index() -> void` — replaces `enforce_size_cap()`;
    scans/counts only, never deletes.
  - `CacheStore.place_cache_keys_all_presets(lat, lon) -> Array` — deduped
    union of `place_cache_keys` over presets 0–3.
  - `WorldCache.bytes_for_place(lat, lon) -> int`,
    `WorldCache.bytes_by_place() -> Dictionary` (prefix -> bytes, one listing),
    `WorldCache.remove_for_place(lat, lon) -> Dictionary{files, bytes}`,
    `WorldCache.is_place_busy(lat, lon) -> bool` (live save thread or prefetch
    for the place prefix).
  - `CacheStore.entry_bytes(entry)` — now data (all-preset union + legacy
    saved keys) **plus** built worlds, so History and Storage agree.
  - `CacheStore.place_cache_report(entries) -> Dictionary{rows, other_bytes, total_bytes}`;
    row = `{entry, name, lat, lon, data_bytes, world_bytes, bytes, state}`
    with `state` in `none|partial|full`, rows largest-first then name.
  - `CacheStore.clear_place_cache(entry) -> Dictionary{ok, busy, files, bytes, data_bytes, world_bytes}`;
    refuses with `busy=true` (deletes nothing) while `WorldCache.is_place_busy`;
    keeps entry/favourite/camera/thumbnail. `remove_place(entry)` is rebuilt
    on it and additionally removes thumbnail + entry (existing semantics).
  - Guard decision: refuse-and-report (busy), never wait, including for the
    currently open place — a live save/prefetch is the only blocker; loaded
    in-memory worlds are unaffected by deleting their files.

## Phase 1 — Remove the size limit

Lane B (UI/prefs) and Lane A (enforcement) in parallel; they meet only at
`CacheStore.enforce_size_cap` call sites, which Lane A owns.

- [x] **Lane A — stop evicting in `CacheStore`.** `note_written()` no longer
  triggers trimming; the directory scan survives only as accounting
  reconciliation (counting files the LRU index does not track, e.g. map
  tiles) and never deletes. Remove `max_cache_bytes`, `data_cap()`,
  `TRIM_TO`, `MAX_LIMIT_MB`, `on_full` and the trim path in
  `_scan_and_trim()` (rename the remaining reconcile entry point honestly,
  e.g. `reconcile_index()`, and update all callers). Keep `data_bytes()`,
  `cache_stats()`, `invalidate_layer()` and the LRU index working unchanged
  for readouts. Decide `eviction_suppressed` explicitly: remove it and its
  call sites, or keep it as a now-redundant guard — one outcome, recorded
  here, with `tests/cache_capture_safety_test.gd` updated to match.
- [x] **Lane A — stop auto-budgeting worlds.** `WorldCache.save_async()` and
  `CacheStore` no longer call `enforce_budget()` automatically. Keep
  `enforce_budget(max_bytes, keep_newest)` as an explicit-only utility
  (tests use it) or remove it and its test block — one outcome, recorded
  here. `OfflineDownloader.clear_cache()` still recounts worlds correctly
  afterwards.
- [x] **Lane B — remove the limit UI and prefs.** Storage page: drop the
  size-limit slider row and the "of <limit>" usage framing (per Phase 0's
  chosen shape); `SettingsScreen` drops `_limit_slider` / `_limit_label` /
  `_on_cache_limit()` and the storage summary becomes the total alone.
  `UiPrefs.apply()` stops setting a cap; `RenderSettings` drops (or stops
  reading) `cache_limit_mb` / `cache_full_asked_mb` — old settings files
  with those keys must still load. `Main` drops `_on_cache_full()`,
  `_offer_cache_room()`, the toast action branch and the `on_full` hookup.
- [x] **Lane B/C — update `tests/settings_test.gd`** storage assertions
  (summary no longer contains "of …"; screen still reports a readable size)
  and any test referencing removed symbols; `grep` for the removed names
  across `scripts/` and `tests/` returns only intentional leftovers.

Validation: headless `tests/settings_test.gd` and
`tests/cache_capture_safety_test.gd` pass via `tools/godot_bg.sh`; a manual
grep list in the PR shows zero live references to the removed limit symbols;
filling a test cache past the old 2 GB default (small `dir_override`
fixtures stand in for size) deletes nothing.

## Phase 2 — Per-place cache inventory and clearing (backend)

Lane A only (hot files). Depends on the Phase 0 gate. Lane B may build the
Phase 3 list against the frozen row shape with fake rows meanwhile.

- [x] **Inventory API.** Given the History entries, produce one row per
  place: data bytes (union of `entry_cache_keys` over all presets plus any
  legacy saved keys, deduplicated, existing files only), built-world bytes
  (new `WorldCache.bytes_for_place(lat, lon)` over the
  `world_<lat_q>_<lon_q>_` prefix, `.scn` + `.ground`), total, and cached
  state (none / partial / full, reusing `keys_cached_status` semantics).
  Plus the "Other cache" figure from Phase 0 so rows + Other reconcile
  with `OfflineDownloader.cache_size_bytes()` within shared-tile double
  counting, which the row contract states explicitly.
- [x] **Performance contract.** The inventory must not walk ~250k files on
  the main thread when Settings opens. Use the LRU index for data files
  and a single directory listing for worlds, on a worker or lazily per row
  — following the existing preload/scan worker pattern — with a
  placeholder size shown until a row's number lands. State the chosen
  mechanism in the PR; opening Storage on a large cache must not block a
  frame on disk I/O beyond today's `_refresh_storage()`.
- [x] **Clear API.** `clear_place_cache(entry)` (name per Phase 0 freeze):
  deletes the place's data files (all-preset union above) and its built
  worlds (new `WorldCache.remove_for_place(lat, lon)` covering `.scn`,
  `.ground` and stray `.tmp.scn`), erases the files from the LRU index,
  invalidates tracked totals, and returns files/bytes actually freed.
  It does **not** touch the History entry, favourite, camera or thumbnail.
  It refuses (returns the busy result from Phase 0, deletes nothing) while
  a world save or prefetch for that place is in flight, and it is safe
  against a concurrent index scan (no resurrection of deleted entries by
  `_scan_done` merging).
- [x] **Unify `remove_place`.** Reimplement History's remove on top of the
  clear API, then keep its extra steps (thumbnail removal, entry erase,
  `save_store()`), so both verbs free byte-identical file sets.
- [x] **Headless test `tests/place_cache_clear_test.gd`** (Lane C may draft
  it against the frozen API while Lane A implements): fixtures under
  `dir_override` / `history_override` / `WorldCache.dir_override` /
  `PlaceThumb.dir_override` only — never the real `user://cache`. Cover:
  two nearby places sharing a DEM tile; files at two different presets for
  one place; worlds at two preset/season variants; a favourite with a
  camera and thumbnail; an orphan world with no History entry (Other
  bucket). Assert clear frees exactly the target place's files, the other
  place's unshared files survive, the shared tile's fate matches the
  documented rule, entry/favourite/camera/thumbnail survive a Storage
  clear and are gone after a History remove, and reported bytes match the
  files actually deleted.

Validation: the new test passes headless via `tools/godot_bg.sh`;
`tools/check_class_size.sh` passes (split a new inventory class if
`cache_store.gd` would approach 1000 lines).

## Phase 3 — The places list in Settings → Storage (menu list view)

Lane B. Depends on Phase 2's inventory/clear APIs (fake rows until then).

- [x] **Plumb the store.** `SettingsScreen` needs the same History entries
  History uses: `Main` binds its single `CacheStore` to Settings as it
  already does with `bind_store()` for History (no second store instance
  reading `history.json`, so favourites/camera/state cannot diverge).
  The list refreshes when Storage becomes visible and after every clear,
  following `_on_visibility_changed()` / `_refresh_storage()`.
- [x] **Build the list.** In `SettingsPages.storage()`, under the usage
  readout, a "Places" section: a `SettingsRows.group()` with one row per
  place, largest first (ties by name). Row content: place name (and
  region, via `UiTheme.split_place`), when it was last opened, cached
  state, and its size via `UiTheme.cache_size()`; a per-row Clear action
  (44 pt touch target, `trash-2` icon, tooltip "Clear cache for <place>")
  that is disabled/hidden when the place holds 0 bytes. An "Other cache"
  row appears when unattributed bytes exist, with no per-place action
  (Clear cache below covers it) and a one-line explanation.
- [x] **Confirm and report.** Tapping Clear opens `SettingsRows.confirm()`
  naming the place and the size it frees, stating the place stays in
  Saved places and will download again when opened. On confirm: call the
  Phase 2 API; on success refresh the row in place (size 0 / not cached,
  the row does not vanish), refresh the page total and the category
  summary (Settings has no toast of its own, so the refreshed readout and
  row are the success signal — do not invent a new notification widget);
  on the busy result, say through the same confirmation surface that the
  place is still being saved and nothing was cleared.
- [x] **States and layout.** Empty History, places with nothing cached, and
  Other-only caches each render a deliberate state (no blank group, no
  Clear buttons that free 0 bytes). Phone (menu → Storage page) and
  rail layouts both work: the row's Clear control never squeezes the name
  off the row at 390 pt wide or at 200% text size; long names ellipsise
  like History's do. Keep Clear-all-cache exactly as it is, below the list,
  still behind its confirmation showing the true total.
- [x] **Extend `tests/settings_test.gd`** (Lane C reviews): Storage shows a
  row per bound entry with a formatted size; confirming a clear calls the
  API and the row/total update; the busy result leaves the row untouched;
  no row appears for an empty store.

Validation: headless `tests/settings_test.gd` passes via
`tools/godot_bg.sh`; the manual/windowed check is deferred to Phase 5's
single batched screenshot run (per repo rules, windowed tests are batched,
run in the background, never `--always-on-top`).

## Phase 4 — History unification and wording

Lane C. Depends on Phase 2's unified `remove_place`.

- [x] History's trash button, swipe-left and context-menu remove now free
  built worlds too (via the unified API); the toast reports the freed size
  ("<Place> removed from cache" gains the size, formatted with
  `UiTheme.cache_size()`), and the size badge on cards/rows counts data +
  worlds so History and Storage agree on a place's size.
- [x] Make the verb difference legible: History's action stays "Remove from
  cache" (entry goes too); Storage's stays "Clear" (entry stays). Tooltips
  / confirmation text on each surface state which one it is, in the app's
  existing voice. No behaviour change beyond completeness of deletion.
- [x] Update `tests/viewer_tools_test.gd` (thumbnail still deleted on
  remove) and add the worlds-freed assertion there or in
  `tests/place_cache_clear_test.gd`; check History's Clear-all-cache still
  works unchanged against the unified code.

Validation: `tests/viewer_tools_test.gd` and the place-cache test pass
headless via `tools/godot_bg.sh`.

## Phase 5 — Whole-area verification and docs

All lanes, parallel by test file; one owner for the docs edit.

- [x] Run the touched-area suites headless via `tools/godot_bg.sh`:
  `tests/settings_test.gd`, `tests/place_cache_clear_test.gd`,
  `tests/cache_capture_safety_test.gd`, `tests/viewer_tools_test.gd`,
  plus `tests/host_policy_test.gd` (untouched, as a smoke check that no
  data-source behaviour moved).
- [x] Batched windowed run at the end only (repo rule):
  `tests/world_cache_test.gd` and `tests/screenshot_test.gd` via
  `tools/godot_bg.sh` in the background, including a Storage screenshot
  with several cached places, one cleared place, and an Other-cache row,
  at phone and desktop sizes. Read the captures before claiming the UI.
- [x] `tools/check_class_size.sh` passes; no file under `scripts/` exceeds
  1000 lines.
- [x] Docs: `README.md` (Settings line no longer says "cache size" as a
  limit; cache description matches unlimited + per-place clearing) and any
  Storage wording in `docs/` that mentions the limit. One commit-scoped
  pass; no drive-by doc edits.

Validation: every command above observed green in this session, or the
failure is reported as pre-existing with a base-tree rerun as evidence.

## Risks and mitigations

- **Unbounded growth is the accepted trade-off.** With no cap, a heavy user
  can fill a device. Mitigation is the feature itself (visible total,
  per-place sizes, one-tap clear per place, Clear all), plus honest copy:
  the Storage page must not keep text promising automatic room-making
  ("When the cache is full, the places you opened longest ago make room
  first" in `storage()` must be rewritten in Phase 1/3).
- **Shared tiles make per-place numbers fuzzy.** A DEM/satellite tile can
  serve two places; deleting it for one makes the other partial. This is
  today's documented `remove_place` behaviour — keep it, state it in the
  confirmation only if Phase 0 finds users could misread the freed size,
  and never double-subtract shared bytes from the page total (the total is
  re-read from disk/index after a clear, not summed from rows).
- **Streamed/recentred worlds may not match a History coordinate.**
  `WorldStreamer` recentring can save worlds whose quantised prefix is a
  walked-to centre, not the entry's lat/lon. Phase 0 must find these;
  whatever cannot be attributed goes to Other (Clear all still frees it),
  and the plan does not invent a new place-tracking store for them.
- **Deleting under a running save/prefetch** can corrupt or resurrect
  files. The Phase 0 guard decision and the Phase 2 busy result are the
  mitigation; the currently-open place gets the same protection.
- **`cache_store.gd` is at 797 lines.** The inventory/report code is the
  natural split point (a focused per-place inventory class) if Lane A
  approaches the limit — split early rather than compressing style.
- **Settings previously had no store binding.** Binding `Main`'s store
  into Settings must not create a second writer of `history.json`; if
  Phase 3 finds Settings needs entries before `Main` can bind, refresh on
  visibility from the bound store instead of loading a private copy.

## Open questions

None blocking. The two judgement calls a reviewer may still veto, with
defaults already baked into the phases above: list sort order (largest
first, chosen so freeing space is fastest) and whether the usage bar
survives without a limit (Phase 0 default: drop it; a bar against no
limit communicates nothing).

# Remote config

The app can switch the addresses of three public services without an update.
This is required by the Nominatim usage policy, and it is how the app moves
off a service that blocks it, changes its terms or goes away.

The file is `site/config.json`, published by `.github/workflows/pages.yml` to
`https://tuononenp.github.io/planet-render-360/config.json`
(`Brand.CONFIG_URL`). `RemoteConfig` (`scripts/data/remote_config.gd`) reads it.

## What it can change

| Key | Type | Replaces |
| --- | --- | --- |
| `nominatim_endpoint` | https URL | `SearchFetcher.ENDPOINT`, the place-search address |
| `overpass_endpoints` | 1 to 8 https URLs | `OsmFetcher.ENDPOINTS`, the Overpass instances in order (a live query uses the first one not paused) |
| `satellite_url_template` | https URL with exactly three `%d` (zoom, tile y, tile x) | `SatelliteFetcher.URL_TEMPLATE`, the imagery address |

```json
{
  "version": 1,
  "nominatim_endpoint": "https://geocode.example/search",
  "overpass_endpoints": [
    "https://overpass-api.de/api/interpreter",
    "https://z.overpass-api.de/api/interpreter"
  ],
  "satellite_url_template": "https://tiles.example/imagery/%d/%d/%d"
}
```

The file in the repository is `{"version": 1}`, which changes nothing: every
key is optional and the built-in defaults apply.

## How the app uses it

1. At launch `Main` applies the copy cached from the last good fetch
   (`user://remote_config.json`), then starts a background fetch with a
   10 second timeout. The app never waits for it.
2. A fetched file that is valid JSON with `"version": 1` replaces all earlier
   overrides, and is cached. An empty `{"version": 1}` therefore clears them.
3. A failed request, a non-200 answer or a file that is not valid leaves
   whatever the device already has. Nothing is cleared by an outage.
4. Each key is checked on its own. A value that fails its check (not https,
   contains whitespace, longer than 512 characters, wrong number of `%d`, an
   empty or oversized instance list) is ignored and the default stays.
5. Requests already running keep the address they started with. New ones use
   the new address.

## Changing something

1. Edit `site/config.json` and open a pull request. `tests/remote_config_test.gd`
   documents what is accepted; the Pages workflow also refuses a file that is
   not valid JSON.
2. Merge to `main`. The workflow publishes it. Installed apps pick it up the
   next time they launch with a connection.
3. To undo, put the file back to `{"version": 1}`.

## Things to know

- **Trust.** The file comes over HTTPS from the project's own Pages site, so
  whoever can push to `main` can redirect where the app sends its requests.
  Those requests only carry what the services already receive (the place
  being viewed and the device's IP address), but protect `main` accordingly.
- **Cached imagery.** Tiles are cached by zoom and position, not by source.
  After switching `satellite_url_template`, tiles already on a device stay
  until the cache evicts them, so a place can mix old and new imagery.
  Bump `CacheStore.DATA_VERSION` in the same release if that matters.
- **No kill switch for features.** The file only changes addresses. It cannot
  turn a feature off or show a message.
- **Privacy.** The fetch sends the device's IP address to GitHub. The privacy
  policy (`site/privacy.html`) says so.

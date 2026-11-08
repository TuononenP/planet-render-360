# Store readiness

Planet Render 360 will be free in the app stores. This is the state of what
the Apple App Store and Google Play ask for, written on 8 Nov 2026. The
declarations are drafts from reading the code: confirm each against the
current wording in App Store Connect and the Play Console before submitting.

## In the repository

| Item | State |
| --- | --- |
| Privacy policy | `site/privacy.html`, published by `.github/workflows/pages.yml`. Linked from Settings → About (`Brand.PRIVACY_URL`). **Turn on Pages first:** repository Settings → Pages → Source: GitHub Actions. |
| Service addresses switchable without an update | Done. See `docs/remote-config.md`. |
| Place search follows the Nominatim policy | Done. Typing sends nothing; the request goes out on submit. |
| Licence notices | `NOTICE.md`, `licenses/` (shipped in every export and shown in Settings → About). |
| Release builds refuse to sign with a debug key | Done for Android (`android.yml`). |
| Android export excludes tests, docs and 2K textures | Done. |

## Needs you

| Item | Why |
| --- | --- |
| Enable GitHub Pages | The privacy URL and `config.json` do not exist until then. Both stores need a live privacy URL. |
| Contact email in the store consoles | Both stores require one. The privacy page points to the issue tracker only. Add an address to the page if you want one public. |
| Esri written confirmation | See `docs/data-source-register.md`. Imagery is under every scene. |
| Android: AAB and size | Play takes `.aab`, and Godot builds one only with Gradle (`gradle_build/use_gradle_build=true`, a build template in `android/`). Bundled data after the new filter is roughly 500 MB (snapshots 248, map packs 192, textures about 58). That is well over the size Play allows in the base module (check the current limit in the Play Console), so the data needs Play Asset Delivery or a download on first use. Decide which (see below). |
| Apple developer and Play developer accounts, signing keys, app records | Outside the repository. |
| Version numbers | `version/name`, `version/code`, `short_version` and `version` in `export_presets.cfg`, and the `version` input of both workflows, are typed by hand. There are no release tags yet. |

## Draft declarations

What the app sends, and to whom, is listed in `site/privacy.html`. In short:
no account, no analytics, no advertising, no identifiers, no device location.
The place you choose, and text you submit to search, go to public services
that also see your IP address.

**Google Play, Data safety.** Describe it the conservative way: the app has
no accounts and the developer collects nothing; it sends the places a person
opens and submitted search text to third-party data services to answer the
request. Likely rows to consider declaring as shared and not linked to the
user: *App activity → In-app search history* (the Nominatim query) and
*Location → Approximate or precise location* (the place being viewed is sent
to map, imagery and weather services; it is not the device's location).
Data is encrypted in transit (all requests are HTTPS). People can delete
their data (Settings → Storage, History, uninstall). The console's current
definitions decide the final answer.

**Apple, App Privacy.** The app has no tracking and no developer-side
collection. Apple counts data sent to third parties when they can keep it
beyond answering the request. The map, imagery and weather services log
requests, so choose between *Data Not Collected* and declaring *Search
History* and *Coarse or Precise Location* as not linked and not used for
tracking. Decide with the current App Store Connect wording in front of you.
The app does not use the Advertising Identifier, so there is no tracking
prompt. `ITSAppUsesNonExemptEncryption` is already `false`.

**Content rating.** No user-generated content, violence, gambling, purchases
or advertising, and no account or chat. Landmark details link to Wikipedia
in the system browser; answer the web access question as the form words it.

**Target audience.** General audience, not designed for children.

## Draft listing text

Category: Travel, or Maps and navigation. Education is a fit for the
sun-and-seasons tools.

*Short description (80 characters):*
Pick any point on Earth and look around it in 360°.

*Full description:*
Pick a place and Planet Render 360 builds it around you from real terrain,
imagery and weather. Turn to look around, walk the ground or fly over it.
Move the sun through the day and the seasons, change the weather and take a
photo.

Search the world or start from a capital city, a landmark or a coordinate.
Places you visit stay on your device, and you can save one for offline.

There is no account, no advertising and no tracking. Map data © OpenStreetMap
contributors. Imagery by Esri, Vantor and Earthstar Geographics. Full
credits are in Settings → About.

## Assets to prepare

- App icon: `icon.png` is 1024 × 1024 with no alpha channel, as iOS requires.
- Phone and tablet screenshots in the sizes each store lists.
- Play feature graphic, 1024 × 500.
- Support URL: the issue tracker. Marketing URL: the project page.
- Privacy policy URL: `https://tuononenp.github.io/planet-render-360/privacy.html`.

## Open decisions

1. **Android data size.** Play Asset Delivery needs a plugin or custom Gradle
   work in Godot; downloading the OSM snapshots per site on first use is plain
   code and also helps iOS. Either changes the first-run experience for the
   256 bundled sites.
2. **Overpass reliability without the Russian mirror.** The app never uses a
   Russian-operated service or domain (`HostPolicy`, enforced by
   `tests/host_policy_test.gd` and by `RemoteConfig`). The `maps.mail.ru`
   mirror is removed, which leaves `overpass-api.de`, `z.overpass-api.de`
   and `overpass.private.coffee`. A probe on 8 Nov 2026 found the main
   instance and `lz4.` reporting "at capacity", `z.` refusing connections,
   and `private.coffee` and `kumi` timing out. When all fail, the app falls
   back to the OSM API area download, then to bundled snapshots. Any new
   mirror needs a probe and a check that it covers the whole planet.
3. **Overpass capacity.** The public instance guidance is about 10,000
   queries a day across all users, and far less for regular use. Bundled
   snapshots cover only their own sites. A popular app needs its own
   instance or a cache.
4. **Landmark rights.** Some models recreate protected works (the Atomium,
   Christ the Redeemer). Free distribution does not remove that question.
   Take legal advice before release.

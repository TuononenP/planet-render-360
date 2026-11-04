# Reference photos — new_york

Comparison references for `tools/capture_presets.gd` (realism v3, R-1.1): its contact sheet
puts the first file beside the render, and `stats.json` flags frames whose luma, saturation or
colourfulness fall outside the range of these photos. Note the weather and season of each photo
when reading those flags: the renders are captured in clear summer conditions.

Downscaled to 640 px wide from the Wikimedia Commons originals; each keeps its licence.
The photos are not committed (`visual-plan/refs/**/*.jpg` is gitignored): download each from
its Commons page below, scale it to 640 px wide and save it under the listed file name.

| File | Commons title | Author | Licence | What it shows |
|---|---|---|---|---|
| `01_pier1-lower-manhattan.jpg` | [Brooklyn Bridge Park td (2019-08-23) 033 - Pier 1, Lower Manhattan.jpg](https://commons.wikimedia.org/wiki/File:Brooklyn_Bridge_Park_td_(2019-08-23)_033_-_Pier_1,_Lower_Manhattan.jpg) | Tdorante10 | CC BY-SA 4.0 | The vantage: Brooklyn Bridge Park Pier 1 to the Financial District; overcast. |
| `02_lower-manhattan-skyline.jpg` | [NYC Lower Manhattan skyline 2015 - panoramio.jpg](https://commons.wikimedia.org/wiki/File:NYC_Lower_Manhattan_skyline_2015_-_panoramio.jpg) | Elvis Boaventura | CC BY 3.0 | Same skyline from the Brooklyn shore; overcast. |

Additional reference sources, downloaded to `context/` and kept separate from the daytime skyline statistics (JPEGs are gitignored):

- `night.jpg`: [Brooklyn Bridge and Manhattan at night](https://commons.wikimedia.org/wiki/File:Brooklyn_Bridge,_Manhattan_at_night_1.jpg), Rhododendrites, CC BY-SA 4.0; photographed from Brooklyn Bridge Park.
- `dumbo-street.jpg`: [DUMBO street](https://commons.wikimedia.org/wiki/File:Dumbo_street,_NYC.jpg), valor kopeny, CC0 1.0; Washington Street looking toward the Manhattan Bridge.
- `pier1-morning.jpg`: [Pier 1 and Lower Manhattan](https://commons.wikimedia.org/wiki/File:Brooklyn_Bridge_Park_td_(2019-08-23)_053_-_Pier_1,_Lower_Manhattan.jpg), Tdorante10, CC BY-SA 4.0; 10:25 morning, not golden hour.
- `pier1-0914.jpg`: [View of Manhattan from Brooklyn Bridge Park, 09:14](https://commons.wikimedia.org/wiki/File:View_of_Manhattan_from_Brooklyn_Bridge_Park,_New_York_City,_20231005_0914_2148.jpg), Jakub Hałun, CC BY 4.0; a clear morning Pier 1 view with buildings identified on its Commons page. The photo was downscaled; it is not verified as golden hour.

A verified morning golden-hour Pier 1 reference is still needed.

Linked sunrise context: [Lower Manhattan during sunrise, VOJTa Herout](https://www.photohound.co/spot/lower-manhattan-panorama-from-pier-1-1001535),
the fourth photograph in PhotoHound's Pier 1 gallery. The photographer's
caption establishes sunrise and the gallery establishes the viewpoint;
EXIF date/time and a reusable licence are not supplied on the public page.
Keep it as an attributed visual reference, outside the downloaded Commons
comparison sets and their statistics. The precise golden-hour Commons gate
remains open.

- `near-dumbo-golden-morning.jpg`: [Brooklyn Bridge and One World Trade Center, morning light](https://commons.wikimedia.org/wiki/File:Brooklyn_Bridge_and_One_World_Trade_Center,_morning_light_(20887439332).jpg), John Cunniff, CC BY 2.0; photographed about 30 minutes after sunrise from Brooklyn Bridge Park near DUMBO (not Pier 1).

## Condition-matched comparisons — 2026-11-04

`morning/01_pier1-0914.jpg` is a downscaled copy of Jakub Hałun's
`context/pier1-0914.jpg` above (CC BY 4.0). Use
`capture_presets.gd --refs=morning` for the clear 08:00 opening. Its
colourfulness is 0.178; this single clear-morning reference is a diagnostic,
not a statistical acceptance interval. Its autumn date and 09:14 time differ
from the default clear-summer capture.

The two root photos remain the overcast set; use `--weather=3` without
`--refs=morning` for that comparison. Keep night, street, and golden-hour
context images outside both sets. The new source search did not establish a
golden-hour photograph taken specifically on Pier 1, so that requirement
remains open; the DUMBO photo is not relabelled as Pier 1.

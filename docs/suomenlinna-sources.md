# Suomenlinna fortress rendering

The correction covers Kustaanmiekka, Susisaari, Iso Mustasaari, Pikku
Mustasaari and Länsi-Mustasaari. Särkkä, Lonna and Vallisaari are excluded.

## Visual references

The user's four photographs supplied on 2026-11-04 are the primary appearance
references, locally at `~/Downloads/Suomenlinna/image1.jpeg` through
`image4.jpeg`. They are not redistributed as project assets; authorship and
reuse licences were not supplied.

- Images 1, 2 and 4: angular southern bastions, irregular grey stone faces,
  sloping grass-covered earthworks, narrow gravel paths and exposed coastal
  rock. The small southern beacon is white, rather than a tall striped tower.
- Image 3: King's Gate recessed into the waterfront defenses, classical
  stone surround, low curved waterfront steps and grass-covered flanking walls.
- Existing aerial reference: `visual-plan/refs/landmarks/suomenlinna_fortress/`.
  Its README records the public-domain source and author.

## Placement and construction

- OpenStreetMap source geometries supply building and defensive footprints,
  nested parts, courtyard holes, retaining walls and the gate passage axis.
  The offline regression fixture is an excerpt of the cached 2026-11-04
  response, © OpenStreetMap contributors, ODbL. The fixture adds synthetic
  height, level, roof and colour tags to way 24907663 to test precedence.
- [Official visitor maps](https://suomenlinna.fi/en/explore/maps/): island
  layout, King's Gate, church and fortress route.
- [Official sights](https://suomenlinna.fi/nahtavyydet/): the southern shore
  defenses and their later earth coverings.
- [Governing Body's Kustaanmiekka building histories](https://suomenlinna.fi/wp-content/uploads/2025/04/Kustaanmiekan-rakennusten-historia.pdf):
  named fortification identities; the gate connects Lantingshausen and the
  shore defenses.
- [Suomenlinna Church architectural account](https://www.finnisharchitecture.fi/projects/suomenlinna-church):
  the Lutheran conversion and present central lighthouse tower.

Untagged defensive wall height (4.8 m), casemate height (3.4 m), earth cover
(up to 1.8 m), wall batter (0.45 m), gate details and beacon dimensions are
photographic estimates, not surveyed measurements. The 1–2 storey default for
untyped ordinary island buildings is likewise a conservative visual default;
explicit OSM dimensions, roof forms, materials and colours take precedence.
Occupied halls, homes and buildings converted from bastions remain buildings.

Geometry is generated at each mapped site, including when viewed from another
nearby pin. A shared material batch owns the defensive masses and neighboring
mapped defensive walls; coincident generic barrier and shore faces yield to it.
The mapped gate terrace is lowered to a visual estimate of 2.2 m ASL before
shoreline meshing, correcting the DEM slope that otherwise buries its arch.
Grass and gravel use the existing live seasonal snow shader.

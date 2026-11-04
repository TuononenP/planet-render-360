# New York r33 — subway lamps and railing

Ultra follow-up at the same mapped High Street node `219785432` as
[r32](../nyc-r32-high-street-2026-11-04/README.md), using its complete local
detailed response. [Street view](nyc_high_street_look0.jpg),
[reverse view](nyc_high_street_look1.jpg), and
[overhead view](nyc_high_street_look2.jpg) establish the entrance independently
of the Pier 1 opening.

White lower and green upper globe halves replace saturated traffic-signal
lenses; their emission is reduced from 3.0 to 0.25. The reverse view retains
both diffuser colours without r32's bright green bloom. Added vertical
railing infill. The city documents split globes in its
[NYC CERT manual](https://www.nyc.gov/assets/em/downloads/pdf/cert_manual_visuallyimpaired.pdf);
its [Subway–Sidewalk Interface report, p. 12](https://www.nyc.gov/assets/planning/download/pdf/plans/transportation/td_fullsubwaysidewalkbx.pdf)
also describes globe markers. These establish the generic kit, not a survey
of this entrance's current fixtures.

`street_furniture_test` passes for mapped placement, regional kit, mesh
creation and separate diffused globe materials. Cache build version 179
invalidates the previous geometry. The 52 s cached-data opening includes
5.137 s generation; POIs still timed out and far towers exceeded their
budget, so this is local inspection evidence, not all-layer performance.

The raised decorative treads remain a limitation: there is no excavated
terrain opening for a true descending stairwell. This inspection closes the
missing subway-view evidence, while photographic acceptance stays open.
[Capture log](capture.log); nonfatal exit leak warnings remain.

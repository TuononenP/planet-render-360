# Landmark reference photos

Real photos from Wikimedia Commons (CC / public domain only), for comparing a landmark model
with its real look (`tools/capture_landmarks.gd` sheets, plan L-1.1). Each `<type>/README.md`
lists file, Commons page, author and licence. Photos are downscaled to 800 px wide and not
committed (`visual-plan/refs/**/*.jpg` is gitignored): re-download from the Commons page.
No viewpoint (lat/lon/bearing) is recorded; the camera views in `PROMPTS.md` are for
AI-made images and for matching capture bearings by eye.

Status (2026-11-03): 406 photos for 386 landmarks, plus AI-made images for 8 more (see each `SOURCE.md`); the 31 still without either are in `MISSING.txt`.
Every image was looked at before keeping. Two passes: the 37 first-pass landmarks have up to two
photos each; the rest have the Wikipedia lead image only. Dropped as wrong subject, detail-only,
interior, tiny or an old engraving: 38 lead images (e.g. `chain_bridge`, `one_wtc`, `sistine_chapel`,
`verrazzano_bridge`). Several kept ones are aerial, distant or black-and-white (e.g. `brihadisvara_temple`);
read the per-folder README. Add AI-made images as `ai_front.jpg` / `ai_quarter.jpg` for gaps.

# Helsinki Central Monument High-Resolution Assets

All `.glb` models in this directory are watertight, smooth-shaded, museum-grade sculptures generated deterministically by `tools/build_helsinki_monument_assets.py` (Blender 5.3), anchored to the exact coordinates and real-world dimensions verified against the **City of Helsinki 3D+ City Reality Mesh (`Mesh 2024`, CC BY 4.0)** and OpenStreetMap:

- **Sculpture scan sources:** Public-domain / CC0 3D museum & academic laser scans from **ThreeDScans.com** (Oliver Laric / Musée Carnavalet / Kunsthistorisches Museum / Saint Louis Art Museum / Leipzig Museum der bildenden Künste / Lincoln Collection) and the **Georgia Tech Large Geometric Models Archive** (`horse.obj` thoroughbred scan).
- **Spatial & elevation calibration:** City of Helsinki 3D+ Reality Mesh (`https://kartta.hel.fi/3d/mesh/Helsinki_2024/tileset.json`, `CC BY 4.0 — © City of Helsinki, 3D city model`).
- **Reproducible build:**
  ```bash
  /Applications/Blender.app/Contents/MacOS/Blender --background --python tools/build_helsinki_monument_assets.py
  /Applications/Blender.app/Contents/MacOS/Blender --background --python tools/build_mannerheim_equestrian.py
  ```

## Bundled High-Detail Assets

| Asset | Triangles | Monument |
|---|---:|---|
| `alexander_ii_emperor.glb` | 14,596 | Statue of Alexander II — Tsar in Imperial Guard officer coat (Senate Square) |
| `alexander_ii_lex.glb` | 8,999 | Statue of Alexander II — *Lex* goddess with shield & Finnish heraldic Lion |
| `alexander_ii_groups.glb` | 14,000 | Statue of Alexander II — *Pax*, *Lux* & *Labor* bronze allegorical groups |
| `runeberg_poet.glb` | 13,000 | J. L. Runeberg Monument — bareheaded frock-coated national poet (Esplanadi) |
| `suomi_neito.glb` | 3,946 | J. L. Runeberg Monument — *Suomi-neito* with laurel wreath & *Maamme* tablet |
| `keisarinnankivi_eagle.glb` | 15,000 | Keisarinnankivi — gilt bronze orb & feathered Imperial Double-Headed Eagle (Market Square) |
| `aleksis_kivi_seated.glb` | 14,000 | Aleksis Kivi Memorial — brooding seated bronze writer (Rautatientori) |
| `three_smiths_group.glb` | 18,368 | Three Smiths (*Kolmen sepän patsas*) — three muscular smiths hammering forged horn anvil |
| `mannerheim_equestrian_bronze.glb` | 55,280 | Marshal Mannerheim Equestrian Statue — mare Käthy in 4-beat lateral stride & Marshal in *turkislakki* and `m/36` tunic |
| `eino_leino_poet.glb` | 11,000 | Eino Leino Statue — cloak-wrapped expressive poet (Esplanadi) |
| `topelius_maidens.glb` | 12,999 | Topelius (*Taru ja totuus*) — twin nude allegorical maidens & crowned bird |
| `topelius_medallion.glb` | 2,756 | Topelius & Lönnrot bronze portrait/mythological bas-relief tondo |
| `lonnrot_ensemble.glb` | 15,512 | Elias Lönnrot Monument — seated Lönnrot writing & lyric maiden *Impi* |
| `paasikivi_monoliths.glb` | 8,992 | J. K. Paasikivi (*Itä ja länsi*) — curved chiseled/polished black-diorite monoliths |

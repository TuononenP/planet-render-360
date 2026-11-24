# Helsinki 3D+ City Reality Mesh Monument Assets

All `.glb` models in this directory were extracted offline from the **City of Helsinki 3D+ City Reality Mesh (`Mesh 2024`)** open dataset:

- **Source endpoint:** `https://kartta.hel.fi/3d/mesh/Helsinki_2024/tileset.json`
- **License:** Creative Commons Attribution 4.0 International (**CC BY 4.0**)
- **Attribution:** `© City of Helsinki, 3D city model`
- **Reproducible pipeline:**
  1. `python3 tools/fetch_helsinki_3d_tiles.py`
  2. `/Applications/Blender.app/Contents/MacOS/Blender --background --python tools/extract_helsinki_3d_monuments.py`

## Bundled Monuments

| Asset | Monument | Mode | Location |
|---|---|---|---|
| `alexander_ii.glb` | Alexander II Monument (Walter Runeberg, 1894) | Hybrid | Senate Square |
| `runeberg_statue.glb` | J. L. Runeberg Monument (Walter Runeberg, 1885) | Hybrid | Esplanadi |
| `keisarinnankivi.glb` | Keisarinnankivi / Czarina's Stone (C. L. Engel, 1835) | Textured | Market Square |
| `aleksis_kivi.glb` | Aleksis Kivi Statue (Wäinö Aaltonen, 1939) | Textured | Rautatientori |
| `three_smiths.glb` | Three Smiths Statue (*Kolmen sepän patsas*, Felix Nylund, 1932) | Textured | Kolmensepänaukio |
| `mannerheim_equestrian.glb` | Marshal Mannerheim Equestrian Statue (Aimo Tukiainen, 1960) | Textured | Mannerheiminaukio |
| `eino_leino.glb` | Eino Leino Statue (Lauri Leppänen, 1953) | Hybrid | Esplanadi |
| `topelius_statue.glb` | Topelius Monument (*Taru ja totuus*, Ville Vallgren, 1932) | Hybrid | Esplanadi |
| `lonnrot_monument.glb` | Elias Lönnrot Monument (Emil Wikström, 1902) | Textured | Lönnrotinpuistikko |
| `paasikivi_monument.glb` | J. K. Paasikivi Monument (*Itä ja länsi*, Harry Kivijärvi, 1980) | Textured | Paasikivenaukio |

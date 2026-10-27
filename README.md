# planet-render-360

> Render any point on the map as a 3D, 360-degree view.

## Summary

Enter coordinates or pick any location on a world map to generate an accurate 360-degree view of that place. Visuals don't need to be photorealistic, but they should be as close to reality as possible while still rendering smoothly in Godot on a mobile phone.

## Core Idea and Use Case

- Pick a location by entering coordinates or selecting it on a world map.
- Procedurally generate a 360-degree view of the location, using optimized techniques suitable for mobile.
- Analyze the location so landmarks (e.g., the Eiffel Tower) are rendered recognizably — ideally generated on the fly on the device.
- Implementation will likely use **Godot**, possibly with **Blender** for asset preparation.

## Core Requirements

- Use only freely available APIs and data sources without strict rate limits.
- Use accurate elevation from a digital elevation model (DEM) so terrain matches the real location.
- Use accurate terrain types and visuals (e.g., [Polyhaven](https://polyhaven.com/) CC0 resources).
- Generate views on the fly over the network using free public APIs, with attribution where required — e.g., OpenFreeMap, DEM sources, and CHELSA for modeling local climate patterns, especially in complex, mountainous, or remote terrain.
- Keep loading times reasonable (a few minutes at most). Show an informative, polished loading screen that visualizes what is happening and how far loading has progressed.
- Optionally render the current time of day, season, and even current weather (e.g., rain) if time allows.

## UI and UX

- Provide intuitive controls alongside a world map for selecting locations.
- Keep a history of recently viewed places.
- Support caching areas for faster repeat views (planned).
- Make the rendered 3D 360-degree view the main focus once loaded.
- Support full-screen mode with intuitive view controls.

## Platforms

Initial development targets **macOS** for easier development and testing, followed by **iOS** and **Android**.

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.

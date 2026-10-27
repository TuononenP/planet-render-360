# planet-render-360

Summary
Renders any point on the map as 3D modeled 360-view rendering

Core idea and use-case
Give a coordinates or pick any location on a world map, then generate an accurate 360 view of the location. Visuals do not need to be photorealistic but as close as possible to be able to be rendered using Godot in mobile phone. Should procedurally render the view or use similar technique if it is more optimized. Could perhaps use Godot  for this (probably need Blender as well). Would perhaps need some way to  analyze the location to render landmarks correctly. If possible Godot could render landmarks on-the-fly on the phone e.g. Eiffel Tower etc. 

Core requirements
-Should use only freely available  APIs and sources  that do not have too much usage restrictions in terms of API calls.
-Should have correct elevation (use digital elevation model). Elevation should match real location.
-Should use correct terrain type and visuals (fetch e.g. from Polyhaven CC0 resources)
-Optionally render  in current time  and  season of the year, perhaps even in current weather (e.g. raining). This is optional if there are enough time to implement this in time.
-Needs to be cross-platform, ios, android and macos for the first versions. But let's start with MacOS version for easier development and testing. Let's worry about the other platforms later.
- Should generate the view on-the-fly using network access and free public APIs with attributions were required e.g. OpenFreeMap, digital elevation model, CHELSA to model local climate patterns accurately—especially in complex, mountainous, or remote terrain.
-Should not take too many minutes to load the rendering, but it is allowed to take some time. During loading should look informative and super cool loading loading screen that clearly visualizes what is happening and how far the loading has progressed. 

UI and UX
UI should have appropriate controls and the world map. Could also have a history of recent searched place. Maybe later someway to cache the area for faster view. The main part of the view should consist of the rendered 3D 360 view after it has been loaded and user should be able to use full-screen mode with appropriate control for adjusting the view.

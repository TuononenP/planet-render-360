"""Bespoke Eiffel Tower for Planet Render 360 (golden location: Paris).

True-scale model in metres (base 125 m wide, summit 276 m, antenna
330 m), built for export to Godot at world scale 0.25. The procedural
archetype in TerrainBuilder stays as the offline fallback; this asset
is the recognisable silhouette: four curved legs, two decks, and the
long tapering spire.

Run: Blender -b --factory-startup --python-exit-code 1 -P \
  assets_src/blender/build_eiffel.py -- assets_src/blender assets
Outputs: eiffel.blend + eiffel.glb + preview render (preview.png).
"""
import sys

sys.path.insert(0, "/Users/petri.tuononen/.local/share/muse/skills/bundled/muse-core--exact-minimal-literal-tests/skills/blender/scripts")
import bpy_helpers as H

# Real proportions (metres): half-widths of the leg square per level.
BASE_HALF = 47.0      # feet spread (legs sit inside the 125 m base)
FLOOR1_Z, FLOOR1_HALF = 57.0, 19.0
FLOOR2_Z, FLOOR2_HALF = 115.0, 10.5
SUMMIT_Z, SUMMIT_HALF = 276.0, 2.2
ANTENNA_Z = 330.0


def main() -> None:
    argv = sys.argv[sys.argv.index("--") + 1:]
    src_dir, out_dir = argv[0], argv[1]
    H.reset_scene()
    iron = H.material_preset("EiffelIron", "painted_metal", "#684628",
                             roughness=0.62, metallic=0.35)
    dark = H.material("EiffelDark", "#4A3520", roughness=0.7, metallic=0.3)

    corners = [(sx, sy) for sx in (-1, 1) for sy in (-1, 1)]
    parts = []
    for sx, sy in corners:
        # Curved leg: foot -> first floor -> second floor (3 tubes,
        # thinning as they rise, like the real lattice piers).
        foot = (sx * BASE_HALF, sy * BASE_HALF, 0.0)
        mid1 = (sx * (FLOOR1_HALF + 6.0), sy * (FLOOR1_HALF + 6.0), FLOOR1_Z * 0.55)
        fl1 = (sx * FLOOR1_HALF, sy * FLOOR1_HALF, FLOOR1_Z)
        fl2 = (sx * FLOOR2_HALF, sy * FLOOR2_HALF, FLOOR2_Z)
        parts.append(H.add_tube("LegLow", [foot, mid1, fl1], radius=5.2, mat=iron))
        parts.append(H.add_tube("LegHigh", [fl1, fl2], radius=3.2, mat=iron))
        # Spire corner posts: second floor -> summit.
        top = (sx * SUMMIT_HALF, sy * SUMMIT_HALF, SUMMIT_Z)
        parts.append(H.add_tube("SpirePost", [fl2, top], radius=1.5, mat=iron))
    # Deck platforms.
    parts.append(H.add_box("Deck1", size=(46, 46, 5),
                           location=(0, 0, FLOOR1_Z + 2.0), mat=dark))
    parts.append(H.add_box("Deck2", size=(26, 26, 4.5),
                           location=(0, 0, FLOOR2_Z + 1.8), mat=dark))
    parts.append(H.add_box("SummitDeck", size=(7, 7, 4),
                           location=(0, 0, SUMMIT_Z + 1.5), mat=dark))
    # Cross braces between legs at three heights (X pairs per face).
    for z, half in [(30.0, 33.0), (86.0, 14.5), (180.0, 6.5)]:
        for axis in (0, 1):
            for sign in (-1, 1):
                a = [0.0, 0.0, z - 9.0]
                b = [0.0, 0.0, z + 9.0]
                a[axis] = -half
                b[axis] = half
                a[1 - axis] = sign * half
                b[1 - axis] = sign * half
                parts.append(H.add_tube("Brace", [tuple(a), tuple(b)],
                                        radius=0.85, mat=iron))
                parts.append(H.add_tube("Brace", [tuple(b), tuple(a)],
                                        radius=0.85, mat=iron))
    # Antenna.
    parts.append(H.add_cylinder("Antenna", radius=0.7,
                                depth=ANTENNA_Z - SUMMIT_Z,
                                location=(0, 0, (ANTENNA_Z + SUMMIT_Z) / 2.0),
                                mat=dark))
    tower = H.join(parts, "EiffelTower")
    H.report()
    cam = H.add_camera("Cam", location=(0, 0, 0), target=(0, 0, 120))
    H.frame_objects(cam, [tower], azimuth=35, elevation=12, margin=1.15)
    H.sun_and_sky(elevation=28, azimuth=140)
    H.set_render(engine="BLENDER_EEVEE_NEXT", resolution=(640, 800),
                 samples=16, percentage=100)
    H.render_still(f"{out_dir}/../assets_src/blender/preview.png")
    H.save_blend(f"{src_dir}/eiffel.blend")
    import bpy
    bpy.ops.export_scene.gltf(filepath=f"{out_dir}/eiffel.glb",
                              export_format="GLB", use_selection=False)
    print("EIFFEL EXPORTED")


if __name__ == "__main__":
    main()

"""Палитра Snack Run (спек 2.2). Цвета sRGB hex -> материалы Blender."""
import bpy

PALETTE = {
    "cat_orange": "#FAAE45",
    "cream": "#FCD3A1",
    "sand": "#D3AB87",
    "olive": "#A9B087",
    "leaf": "#458B59",
    "sea_deep": "#1D7FC4",
    "sea_light": "#2F9CCF",
    "sky": "#659ECF",
    "lilac": "#B46DB5",
    "coral": "#F57485",
    "brick": "#BD4045",
    "asphalt": "#5A5C6B",
    "ink": "#394151",
    "rarity_common": "#4D945B",
    "rarity_rare": "#6491E4",
    "rarity_very_rare": "#C473D4",
    "rarity_legendary": "#FABE32",
    "eye_white": "#F4F1E8",   # белок глаз; не из спека, чтобы скины (sr_cream) не красили глаза
}

MATERIAL_PREFIX = "sr_"


def hex_to_linear(hex_color: str):
    h = hex_color.lstrip("#")
    srgb = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    out = []
    for c in srgb:
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return (*out, 1.0)


def get_material(key: str) -> bpy.types.Material:
    """Материал палитры; создаётся один раз и переиспользуется."""
    if key not in PALETTE:
        raise KeyError(f"нет цвета {key!r} в палитре")
    name = MATERIAL_PREFIX + key
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        bsdf.inputs["Base Color"].default_value = hex_to_linear(PALETTE[key])
        bsdf.inputs["Roughness"].default_value = 0.85
    return mat


def is_palette_material(mat: bpy.types.Material) -> bool:
    return mat is not None and mat.name.startswith(MATERIAL_PREFIX)

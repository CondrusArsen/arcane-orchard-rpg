from __future__ import annotations

import uuid
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(r"C:\Users\arsen\Documents\Codex\2026-05-11\roblox-github")
PLACE = ROOT / "RPG_clean.rbxlx"


PANEL = (24 / 255, 28 / 255, 34 / 255)
PANEL_SOFT = (36 / 255, 42 / 255, 50 / 255)
TEXT = (245 / 255, 247 / 255, 250 / 255)
MUTED = (180 / 255, 190 / 255, 202 / 255)
ACCENT = (0 / 255, 170 / 255, 255 / 255)
GOLD = (255 / 255, 202 / 255, 88 / 255)
GOOD = (83 / 255, 214 / 255, 141 / 255)
DANGER = (255 / 255, 99 / 255, 99 / 255)
WHITE = (1, 1, 1)
BLACK = (0, 0, 0)


TEXT_CLASSES = {"TextLabel", "TextButton"}
GUI_CLASSES = {"Frame", "ScrollingFrame", "TextLabel", "TextButton", "ImageLabel", "ImageButton"}
SCREEN_GUI_CLASSES = {"ScreenGui"}


def rb_ref() -> str:
    return "RBX" + uuid.uuid4().hex.upper()


def uid() -> str:
    return uuid.uuid4().hex


def props(item: ET.Element) -> ET.Element:
    node = item.find("Properties")
    if node is None:
        node = ET.Element("Properties")
        item.insert(0, node)
    return node


def find_prop(item: ET.Element, name: str) -> ET.Element | None:
    for child in props(item):
        if child.attrib.get("name") == name:
            return child
    return None


def replace_prop(item: ET.Element, node: ET.Element) -> None:
    p = props(item)
    name = node.attrib["name"]
    for index, child in enumerate(list(p)):
        if child.attrib.get("name") == name:
            p.remove(child)
            p.insert(index, node)
            return
    p.append(node)


def set_text(item: ET.Element, name: str, value: str) -> None:
    node = ET.Element("string", {"name": name})
    node.text = value
    replace_prop(item, node)


def set_bool(item: ET.Element, name: str, value: bool) -> None:
    node = ET.Element("bool", {"name": name})
    node.text = "true" if value else "false"
    replace_prop(item, node)


def set_int(item: ET.Element, name: str, value: int) -> None:
    node = ET.Element("int", {"name": name})
    node.text = str(value)
    replace_prop(item, node)


def set_float(item: ET.Element, name: str, value: float) -> None:
    node = ET.Element("float", {"name": name})
    node.text = f"{value:.9g}"
    replace_prop(item, node)


def set_token(item: ET.Element, name: str, value: int) -> None:
    node = ET.Element("token", {"name": name})
    node.text = str(value)
    replace_prop(item, node)


def set_color(item: ET.Element, name: str, rgb: tuple[float, float, float]) -> None:
    node = ET.Element("Color3", {"name": name})
    for tag, value in zip(("R", "G", "B"), rgb):
        child = ET.SubElement(node, tag)
        child.text = f"{value:.9g}"
    replace_prop(item, node)


def set_vec2(item: ET.Element, name: str, x: float, y: float) -> None:
    node = ET.Element("Vector2", {"name": name})
    x_node = ET.SubElement(node, "X")
    x_node.text = f"{x:.9g}"
    y_node = ET.SubElement(node, "Y")
    y_node.text = f"{y:.9g}"
    replace_prop(item, node)


def set_udim2(item: ET.Element, name: str, xs: float, xo: int, ys: float, yo: int) -> None:
    node = ET.Element("UDim2", {"name": name})
    for tag, value in (("XS", xs), ("XO", xo), ("YS", ys), ("YO", yo)):
        child = ET.SubElement(node, tag)
        child.text = f"{value:.9g}" if isinstance(value, float) else str(value)
    replace_prop(item, node)


def set_udim(item: ET.Element, name: str, scale: float, offset: int) -> None:
    node = ET.Element("UDim", {"name": name})
    s = ET.SubElement(node, "S")
    s.text = f"{scale:.9g}"
    o = ET.SubElement(node, "O")
    o.text = str(offset)
    replace_prop(item, node)


def set_font(item: ET.Element, weight: int = 600) -> None:
    node = ET.Element("Font", {"name": "FontFace"})
    family = ET.SubElement(node, "Family")
    url = ET.SubElement(family, "url")
    url.text = "rbxasset://fonts/families/SourceSansPro.json"
    weight_node = ET.SubElement(node, "Weight")
    weight_node.text = str(weight)
    style = ET.SubElement(node, "Style")
    style.text = "Normal"
    cached = ET.SubElement(node, "CachedFaceId")
    cached_url = ET.SubElement(cached, "url")
    cached_url.text = "rbxasset://fonts/SourceSansPro-Regular.ttf"
    replace_prop(item, node)


def base_instance_props(item: ET.Element, name: str) -> None:
    set_text(item, "Name", name)
    set_text(item, "Tags", "")
    replace_prop(item, ET.Element("BinaryString", {"name": "AttributesSerialize"}))
    cap = ET.Element("SecurityCapabilities", {"name": "Capabilities"})
    cap.text = "0"
    replace_prop(item, cap)
    set_bool(item, "DefinesCapabilities", False)
    hist = ET.Element("UniqueId", {"name": "HistoryId"})
    hist.text = "00000000000000000000000000000000"
    replace_prop(item, hist)
    set_int64(item, "SourceAssetId", -1)
    unique = ET.Element("UniqueId", {"name": "UniqueId"})
    unique.text = uid()
    replace_prop(item, unique)


def set_int64(item: ET.Element, name: str, value: int) -> None:
    node = ET.Element("int64", {"name": name})
    node.text = str(value)
    replace_prop(item, node)


def direct_name(item: ET.Element) -> str:
    prop = find_prop(item, "Name")
    return prop.text if prop is not None and prop.text else item.attrib.get("class", "")


def walk(parent: ET.Element, path: str = ""):
    for child in list(parent):
        if child.tag != "Item":
            continue
        name = direct_name(child)
        full = f"{path}/{name}" if path else name
        yield child, full
        yield from walk(child, full)


def direct_child(item: ET.Element, class_name: str, name: str | None = None) -> ET.Element | None:
    for child in list(item):
        if child.tag == "Item" and child.attrib.get("class") == class_name:
            if name is None or direct_name(child) == name:
                return child
    return None


def make_ui_corner(radius: int) -> ET.Element:
    item = ET.Element("Item", {"class": "UICorner", "referent": rb_ref()})
    item.append(ET.Element("Properties"))
    for name in ("BottomLeftRadius", "BottomRightRadius", "TopLeftRadius", "TopRightRadius"):
        set_udim(item, name, 0, radius)
    base_instance_props(item, "UICorner")
    return item


def make_ui_stroke(color: tuple[float, float, float], thickness: float, transparency: float) -> ET.Element:
    item = ET.Element("Item", {"class": "UIStroke", "referent": rb_ref()})
    item.append(ET.Element("Properties"))
    set_token(item, "ApplyStrokeMode", 0)
    set_udim(item, "BorderOffset", 0, 0)
    set_token(item, "BorderStrokePosition", 0)
    set_color(item, "Color", color)
    set_bool(item, "Enabled", True)
    set_token(item, "LineJoinMode", 0)
    set_token(item, "StrokeSizingMode", 0)
    set_float(item, "Thickness", thickness)
    set_float(item, "Transparency", transparency)
    set_int(item, "ZIndex", 1)
    base_instance_props(item, "UIStroke")
    return item


def make_ui_scale(scale: float) -> ET.Element:
    item = ET.Element("Item", {"class": "UIScale", "referent": rb_ref()})
    item.append(ET.Element("Properties"))
    set_float(item, "Scale", scale)
    base_instance_props(item, "StaticUIScale")
    return item


def ensure_corner(item: ET.Element, radius: int) -> None:
    corner = direct_child(item, "UICorner")
    if corner is None:
        item.append(make_ui_corner(radius))
    else:
        for name in ("BottomLeftRadius", "BottomRightRadius", "TopLeftRadius", "TopRightRadius"):
            set_udim(corner, name, 0, radius)


def ensure_stroke(item: ET.Element, color: tuple[float, float, float], thickness: float, transparency: float) -> None:
    stroke = direct_child(item, "UIStroke")
    if stroke is None:
        item.append(make_ui_stroke(color, thickness, transparency))
    else:
        set_color(stroke, "Color", color)
        set_float(stroke, "Thickness", thickness)
        set_float(stroke, "Transparency", transparency)
        set_bool(stroke, "Enabled", True)


def ensure_scale(item: ET.Element, scale_value: float) -> None:
    scale = direct_child(item, "UIScale", "StaticUIScale") or direct_child(item, "UIScale")
    if scale is None:
        item.append(make_ui_scale(scale_value))
    else:
        set_float(scale, "Scale", scale_value)
        set_text(scale, "Name", "StaticUIScale")


def style_text(item: ET.Element, path: str, is_button: bool) -> None:
    set_font(item, 700 if is_button else 600)
    set_color(item, "TextColor3", WHITE if is_button else TEXT)
    set_bool(item, "TextScaled", True)
    set_bool(item, "TextWrapped", True)
    set_token(item, "TextTruncate", 1)
    set_float(item, "TextSize", 18 if is_button else 16)
    set_int(item, "BorderSizePixel", 0)
    if "Coins_Safe" in path:
        set_color(item, "TextColor3", GOLD)
        set_color(item, "BackgroundColor3", PANEL)
        set_float(item, "BackgroundTransparency", 0.08)
        ensure_corner(item, 8)
        ensure_stroke(item, GOLD, 1.2, 0.15)
    if "/CD" in path:
        set_color(item, "BackgroundColor3", BLACK)
        set_float(item, "BackgroundTransparency", 1)


def style_button(item: ET.Element, path: str) -> None:
    style_text(item, path, True)
    set_color(item, "BackgroundColor3", ACCENT)
    set_float(item, "BackgroundTransparency", 0)
    ensure_corner(item, 8)
    ensure_stroke(item, WHITE, 1, 0.82)


def style_frame(item: ET.Element, path: str, class_name: str) -> None:
    if path.endswith("ManaBar"):
        set_color(item, "BackgroundColor3", ACCENT)
        set_float(item, "BackgroundTransparency", 0)
        ensure_corner(item, 6)
        return
    if path.endswith("HPbar"):
        set_color(item, "BackgroundColor3", DANGER)
        set_float(item, "BackgroundTransparency", 0)
        ensure_corner(item, 6)
        return

    set_color(item, "BackgroundColor3", PANEL if class_name == "ScrollingFrame" else PANEL_SOFT)
    set_float(item, "BackgroundTransparency", 0.08 if class_name == "ScrollingFrame" else 0.12)
    set_int(item, "BorderSizePixel", 0)
    ensure_corner(item, 8)
    ensure_stroke(item, WHITE, 1, 0.9)

    if class_name == "ScrollingFrame":
        set_int(item, "ScrollBarThickness", 8)
        set_color(item, "ScrollBarImageColor3", ACCENT)


def style_image(item: ET.Element, path: str) -> None:
    set_color(item, "BackgroundColor3", PANEL_SOFT)
    set_float(item, "BackgroundTransparency", 0.08)
    set_int(item, "BorderSizePixel", 0)
    ensure_corner(item, 8)
    ensure_stroke(item, ACCENT, 1, 0.55)


def apply_specific_layout(item: ET.Element, path: str) -> None:
    if path == "StarterGui/ShopGui/ShopFrame":
        set_vec2(item, "AnchorPoint", 0.5, 0.5)
        set_udim2(item, "Position", 0.5, 0, 0.52, 0)
        set_udim2(item, "Size", 0.86, 0, 0.78, 0)
        set_bool(item, "ClipsDescendants", True)
    elif path == "StarterGui/ShopGui/OpenButton":
        set_text(item, "Text", "Open Market")
        set_vec2(item, "AnchorPoint", 0, 1)
        set_udim2(item, "Position", 0, 18, 1, -18)
        set_udim2(item, "Size", 0, 168, 0, 44)
    elif path == "StarterGui/ValueGui/Coins_Safe":
        set_udim2(item, "Position", 0, 18, 0, 18)
        set_udim2(item, "Size", 0, 190, 0, 40)


def clear_runtime_ui_polish(root: ET.Element) -> int:
    changed = 0
    for item, path in walk(root):
        if path == "StarterGui/ManaGui/ManaGenFrame/LocalScript":
            source = find_prop(item, "Source")
            if source is not None:
                source.text = "-- UI styling is saved directly in StarterGui properties."
                changed += 1
    return changed


def main() -> None:
    ET.register_namespace("xmime", "http://www.w3.org/2005/05/xmlmime")
    ET.register_namespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
    tree = ET.parse(PLACE)
    root = tree.getroot()

    styled = 0
    for item, path in walk(root):
        if not path.startswith("StarterGui/"):
            continue

        class_name = item.attrib.get("class", "")
        if class_name in SCREEN_GUI_CLASSES:
            set_bool(item, "IgnoreGuiInset", False)
            ensure_scale(item, 0.92)
            styled += 1
        elif class_name in TEXT_CLASSES:
            if class_name == "TextButton":
                style_button(item, path)
            else:
                style_text(item, path, False)
            styled += 1
        elif class_name in {"Frame", "ScrollingFrame"}:
            style_frame(item, path, class_name)
            styled += 1
        elif class_name in {"ImageLabel", "ImageButton"}:
            style_image(item, path)
            styled += 1

        apply_specific_layout(item, path)

    cleared = clear_runtime_ui_polish(root)

    tree.write(PLACE, encoding="utf-8", xml_declaration=False)
    print("static_ui_styled", styled)
    print("runtime_ui_scripts_cleared", cleared)


if __name__ == "__main__":
    main()

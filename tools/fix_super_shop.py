from __future__ import annotations

import uuid
import xml.etree.ElementTree as ET
from pathlib import Path


PLACE = Path(r"C:\Users\arsen\Documents\Codex\2026-05-11\roblox-github\RPG_clean.rbxlx")


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


def set_int(item: ET.Element, name: str, value: int) -> None:
    node = ET.Element("int", {"name": name})
    node.text = str(value)
    replace_prop(item, node)


def set_bool(item: ET.Element, name: str, value: bool) -> None:
    node = ET.Element("bool", {"name": name})
    node.text = "true" if value else "false"
    replace_prop(item, node)


def set_float(item: ET.Element, name: str, value: float) -> None:
    node = ET.Element("float", {"name": name})
    node.text = f"{value:.9g}"
    replace_prop(item, node)


def set_color(item: ET.Element, name: str, rgb: tuple[float, float, float]) -> None:
    node = ET.Element("Color3", {"name": name})
    for tag, value in zip(("R", "G", "B"), rgb):
        child = ET.SubElement(node, tag)
        child.text = f"{value:.9g}"
    replace_prop(item, node)


def set_udim2(item: ET.Element, name: str, xs: float, xo: int, ys: float, yo: int) -> None:
    node = ET.Element("UDim2", {"name": name})
    for tag, value in (("XS", xs), ("XO", xo), ("YS", ys), ("YO", yo)):
        child = ET.SubElement(node, tag)
        child.text = f"{value:.9g}" if isinstance(value, float) else str(value)
    replace_prop(item, node)


def set_int64(item: ET.Element, name: str, value: int) -> None:
    node = ET.Element("int64", {"name": name})
    node.text = str(value)
    replace_prop(item, node)


def direct_name(item: ET.Element) -> str:
    node = find_prop(item, "Name")
    return node.text if node is not None and node.text else item.attrib.get("class", "")


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


def make_string_value(name: str, value: str) -> ET.Element:
    item = ET.Element("Item", {"class": "StringValue", "referent": rb_ref()})
    p = ET.SubElement(item, "Properties")
    value_node = ET.SubElement(p, "string", {"name": "Value"})
    value_node.text = value
    set_text(item, "Name", name)
    ET.SubElement(p, "BinaryString", {"name": "AttributesSerialize"})
    cap = ET.SubElement(p, "SecurityCapabilities", {"name": "Capabilities"})
    cap.text = "0"
    defines = ET.SubElement(p, "bool", {"name": "DefinesCapabilities"})
    defines.text = "false"
    hist = ET.SubElement(p, "UniqueId", {"name": "HistoryId"})
    hist.text = "00000000000000000000000000000000"
    set_int64(item, "SourceAssetId", -1)
    ET.SubElement(p, "BinaryString", {"name": "Tags"})
    unique = ET.SubElement(p, "UniqueId", {"name": "UniqueId"})
    unique.text = uid()
    return item


def main() -> None:
    ET.register_namespace("xmime", "http://www.w3.org/2005/05/xmlmime")
    ET.register_namespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
    tree = ET.parse(PLACE)
    root = tree.getroot()

    items = {path: item for item, path in walk(root)}
    superior = items.get("StarterGui/ShopGui/ShopFrame/SuperiorFrame")
    if superior is None:
        raise RuntimeError("SuperiorFrame is missing")

    set_bool(superior, "Visible", True)
    set_color(superior, "BackgroundColor3", (0.22, 0.15, 0.34))
    set_float(superior, "BackgroundTransparency", 0.05)
    set_udim2(superior, "Position", 0.018394677, 0, 0.185, 0)
    set_udim2(superior, "Size", 0.8, 0, 0.07, 0)

    cost = direct_child(superior, "IntValue", "Cost")
    if cost is None:
        raise RuntimeError("SuperiorFrame/Cost is missing")
    set_int(cost, "Value", 1000)

    cat = direct_child(superior, "StringValue", "Cat")
    if cat is None:
        raise RuntimeError("SuperiorFrame/Cat is missing")
    set_text(cat, "Value", "SuperFrame")

    if direct_child(superior, "StringValue", "Name") is None:
        superior.append(make_string_value("Name", "SuperiorLabel"))

    text_labels = [child for child in list(superior) if child.tag == "Item" and child.attrib.get("class") == "TextLabel"]
    label_texts = ["Super Magic (T) cost 1000$", "Takes 100 mana", "!"]
    for child, text in zip(text_labels, label_texts):
        set_text(child, "Text", text)
        set_bool(child, "Visible", True)
        set_bool(child, "TextScaled", True)
        set_bool(child, "TextWrapped", True)
        set_color(child, "TextColor3", (1, 1, 1))

    buy_button = direct_child(superior, "TextButton", "BuyButton")
    if buy_button is not None:
        set_text(buy_button, "Text", "Buy")
        set_bool(buy_button, "Visible", True)
        set_bool(buy_button, "TextScaled", True)
        set_color(buy_button, "BackgroundColor3", (0.44, 0.2, 0.88))

    icon = direct_child(superior, "ImageLabel")
    if icon is not None:
        set_bool(icon, "Visible", True)
        set_color(icon, "BackgroundColor3", (0.28, 0.18, 0.45))

    skill_label = items.get("StarterGui/SkillGui/SuperFrame/SuperiorLabel")
    if skill_label is not None:
        set_bool(skill_label, "Visible", False)
        set_color(skill_label, "BackgroundColor3", (0.28, 0.18, 0.45))

    tree.write(PLACE, encoding="utf-8", xml_declaration=False)
    print("fixed SuperiorFrame shop item")


if __name__ == "__main__":
    main()

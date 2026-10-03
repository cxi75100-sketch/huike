"""Read-only verification of installed launcher assets and active references."""

import json
import math
import re
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets/icon"
RES = ROOT / "android/app/src/main/res"
IOS = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"


def main():
    for density, size in (("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                          ("xxhdpi", 144), ("xxxhdpi", 192)):
        template = ASSETS / f"native/android/mipmap-{density}/ic_launcher.png"
        assert Image.open(template).size == (size, size)
        targets = [RES / f"mipmap-{density}/ic_launcher.png"]
        targets += [RES / f"drawable-{density}/ic_launcher_{name}.png"
                    for name in ("foreground", "monochrome")]
        for target in targets:
            assert target.read_bytes() == template.read_bytes(), target
    data = json.loads((IOS / "Contents.json").read_text(encoding="utf-8"))
    for slot in data["images"]:
        name = slot.get("filename")
        if not name:
            continue
        path = IOS / name
        expected = round(float(slot["size"].split("x")[0]) *
                         float(slot["scale"].removesuffix("x")))
        assert Image.open(path).size == (expected, expected), name
        assert path.read_bytes() == (ASSETS / "native/ios" / name).read_bytes()
    assert {p.name for p in IOS.glob("*.png")} == {
        p.name for p in (ASSETS / "native/ios").glob("*.png")}
    colors = ET.parse(RES / "values/colors.xml").getroot()
    assert colors.find("color[@name='ic_launcher_background']").text == "#FFFFFF"
    xml = ET.parse(RES / "mipmap-anydpi-v26/ic_launcher.xml").getroot()
    attr = "{http://schemas.android.com/apk/res/android}"
    for layer in ("foreground", "monochrome"):
        name = "launcher_mark" if layer == "foreground" else "launcher_mark_mono"
        assert xml.find(layer).attrib[attr + "drawable"] == f"@drawable/{name}"
        mark = ET.parse(RES / f"drawable/{name}.xml").getroot()
        assert mark.tag == "vector"
        assert len(mark.findall("group/path")) == 4
        group = mark.find("group")
        scale = float(group.attrib[attr + "scaleX"])
        dx = float(group.attrib[attr + "translateX"])
        dy = float(group.attrib[attr + "translateY"])
        for path in group.findall("path"):
            coords = [float(n) for n in re.findall(r"-?\d+(?:\.\d+)?", path.attrib[attr + "pathData"])]
            for x, y in zip(coords[::2], coords[1::2]):
                # A circle is stricter than square/rounded-square masks.
                assert math.hypot(x * scale + dx - 54, y * scale + dy - 54) <= 33
        if layer == "monochrome":
            assert all(p.attrib[attr + "fillColor"] == "#000000" for p in group.findall("path"))
    for folder in ("values-v31", "values-night-v31"):
        theme = ET.parse(RES / f"{folder}/styles.xml").getroot()
        item = theme.find("style/item[@name='android:windowSplashScreenAnimatedIcon']")
        assert item.text == "@drawable/splash_mark"
    splash = ET.parse(RES / "drawable/splash_mark.xml").getroot().find("group")
    scale = float(splash.attrib[attr + "scaleX"])
    dx = float(splash.attrib[attr + "translateX"])
    dy = float(splash.attrib[attr + "translateY"])
    for path in splash.findall("path"):
        coords = [float(n) for n in re.findall(r"-?\d+(?:\.\d+)?", path.attrib[attr + "pathData"])]
        for x, y in zip(coords[::2], coords[1::2]):
            assert math.hypot(x * scale + dx - 144, y * scale + dy - 144) <= 96
    print("Verified raster fallbacks, iOS slots, vector adaptive/splash references.")


if __name__ == "__main__":
    main()

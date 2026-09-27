"""Verify generated native assets and render actual 48/64px mask samples.

Run after make_icon.py and flutter_launcher_icons. No device claims here.
"""
import json
import xml.etree.ElementTree as ET
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets/icon"
RES = ROOT / "android/app/src/main/res"
IOS = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"


def components(image):
    pixels = image.convert("RGBA")
    white = {(x, y) for y in range(pixels.height) for x in range(pixels.width)
             if min(pixels.getpixel((x, y))[:3]) > 230
             and pixels.getpixel((x, y))[3] > 128}
    count = 0
    while white:
        count += 1
        queue = deque([white.pop()])
        while queue:
            x, y = queue.popleft()
            for neighbor in [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]:
                if neighbor in white:
                    white.remove(neighbor)
                    queue.append(neighbor)
    return count


def main():
    manifest = json.loads((IOS / "Contents.json").read_text(encoding="utf-8"))
    names = set()
    for entry in manifest["images"]:
        name = entry["filename"]
        names.add(name)
        size = round(float(entry["size"].split("x")[0]) *
                     float(entry["scale"].rstrip("x")))
        image = Image.open(IOS / name)
        assert image.size == (size, size), name
        assert image.convert("RGBA").getchannel("A").getextrema() == (255, 255), name
    assert names == {path.name for path in IOS.glob("*.png")}, "Stale iOS PNG"
    native = list(RES.glob("mipmap-*/ic_launcher.png"))
    native += list(RES.glob("drawable-*/ic_launcher_*.png"))
    assert len(native) == 15, f"Expected 5 legacy + 5 foreground + 5 mono: {len(native)}"
    for path in native + [IOS / name for name in names]:
        image = Image.open(path).convert("RGBA")
        assert not any(r > 130 and g < 110 and b < 110 and a > 128
                       for r, g, b, a in image.get_flattened_data()), f"Old red artwork: {path}"

    xml = ET.parse(RES / "mipmap-anydpi-v26/ic_launcher.xml")
    android = "{http://schemas.android.com/apk/res/android}"
    assert xml.find("foreground/inset").get(android + "inset") == "16%"
    assert xml.find("monochrome/inset").get(android + "inset") == "16%"
    for foreground_path in RES.glob("drawable-*/ic_launcher_foreground.png"):
        directory = foreground_path.parent
        fg = Image.open(foreground_path).convert("RGBA")
        mono = Image.open(directory / "ic_launcher_monochrome.png").convert("RGBA")
        assert fg.size == mono.size and fg.tobytes() == mono.tobytes(), directory

    foreground = Image.open(RES / "drawable-xxxhdpi/ic_launcher_foreground.png")
    # Adaptive layer is 108 units. Existing XML insets foreground 16%.
    layer = foreground.resize((216, 216), Image.Resampling.LANCZOS)
    inset_layer = Image.new("RGBA", (216, 216))
    inset = round(216 * .16)
    inset_layer.alpha_composite(layer.resize((216 - 2 * inset,) * 2,
                                            Image.Resampling.LANCZOS), (inset, inset))
    for y in range(216):
        for x in range(216):
            if inset_layer.getpixel((x, y))[3] > 128:
                assert (x - 108) ** 2 + (y - 108) ** 2 <= 66 ** 2, "Outside safe circle"

    sheet = Image.new("RGB", (820, 370), "#E7EAF0")
    draw = ImageDraw.Draw(sheet)
    font_path = Path("C:/Windows/Fonts/arial.ttf")
    font = (ImageFont.truetype(str(font_path), 17) if font_path.exists()
            else ImageFont.load_default(size=17))
    for index, shape in enumerate(["circle", "rounded square", "squircle"]):
        mask = Image.new("L", (216, 216))
        md = ImageDraw.Draw(mask)
        if shape == "circle":
            md.ellipse((36, 36, 179, 179), fill=255)
        elif shape == "rounded square":
            md.rounded_rectangle((36, 36, 179, 179), radius=32, fill=255)
        else:
            for y in range(216):
                for x in range(216):
                    if abs((x - 108) / 72) ** 4 + abs((y - 108) / 72) ** 4 <= 1:
                        mask.putpixel((x, y), 255)
        assert all(not inset_layer.getpixel((x, y))[3] > 128 or mask.getpixel((x, y))
                   for y in range(216) for x in range(216)), f"Clipped: {shape}"
        icon = Image.new("RGBA", (216, 216), "#3057D5")
        icon.alpha_composite(inset_layer)
        icon.putalpha(mask)
        icon = icon.crop((36, 36, 180, 180))
        x = 28 + index * 260
        draw.text((x, 20), shape, font=font, fill="#17191F")
        for size, y in [(48, 65), (64, 160)]:
            sample = icon.resize((size, size), Image.Resampling.LANCZOS)
            assert components(sample) == 3, f"Unreadable at {size}px: {shape}"
            # Two contrasting backgrounds with synthetic wallpaper lines.
            for offset, bg in [(0, "#FFFFFF"), (120, "#171D31")]:
                draw.rectangle((x + offset - 6, y - 6, x + offset + 76, y + 76), fill=bg)
                for line in range(0, 80, 12):
                    draw.line((x + offset - 6, y + line, x + offset + 76, y + line - 25),
                              fill="#778398", width=2)
                sheet.paste(sample, (x + offset, y), sample)
            draw.text((x, y + size + 9), f"{size}px", font=font, fill="#17191F")
    draw.text((28, 310), "3 separate white units; existing adaptive inset 16%; no clipping",
              font=font, fill="#17191F")
    sheet.save(ASSETS / "icon_qa.png")
    print(f"PASS: {len(native)} Android PNGs; {len(names)} iOS PNGs / "
          f"{len(manifest['images'])} slots; 66-unit safe circle; 3 masks x 48/64px.")


if __name__ == "__main__":
    main()

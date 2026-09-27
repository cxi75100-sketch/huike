"""TASK-026: three course units gathering at the center.

Run python tools/make_icon.py, then dart run flutter_launcher_icons.
No fonts, external artwork, randomness, or new dependencies.
"""

from pathlib import Path

from PIL import Image, ImageDraw

S = 2048
OUT = 1024
ROOT = Path(__file__).resolve().parent.parent / "assets" / "icon"
BLUE = (48, 87, 213, 255)  # #3057D5, opaque cool blue.
WHITE = (255, 255, 255, 255)


def glyph():
    """Three capsules: middle/outer length ratio 1.20, same .09 thickness.

    Outer units incline 9 degrees inward. Closest vertical gap is .043,
    about 48% of thickness; left-shifted centers avoid a generic menu.
    """
    result = Image.new("RGBA", (S, S))
    thickness = round(S * .09)
    for length, center, angle in [
        (.58 / 1.2, (.47, .33), -9),
        (.58, (.50, .50), 0),
        (.58 / 1.2, (.47, .67), 9),
    ]:
        width = round(S * length)
        capsule = Image.new("RGBA", (width + 8, thickness + 8))
        ImageDraw.Draw(capsule).rounded_rectangle(
            (4, 4, width + 3, thickness + 3),
            radius=thickness / 2,
            fill=WHITE,
        )
        capsule = capsule.rotate(angle, Image.Resampling.BICUBIC, expand=True)
        result.alpha_composite(capsule, (
            round(S * center[0] - capsule.width / 2),
            round(S * center[1] - capsule.height / 2),
        ))
    return result


def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    foreground = glyph()
    full = Image.new("RGBA", (S, S), BLUE)
    full.alpha_composite(foreground)
    full.resize((OUT, OUT), Image.Resampling.LANCZOS).convert("RGB").save(
        ROOT / "app_icon_ios.png"
    )
    legacy_mask = Image.new("L", (S, S))
    ImageDraw.Draw(legacy_mask).rounded_rectangle(
        (0, 0, S - 1, S - 1), radius=S * .22, fill=255
    )
    legacy = full.copy()
    legacy.putalpha(legacy_mask)
    legacy.resize((OUT, OUT), Image.Resampling.LANCZOS).save(
        ROOT / "app_icon_android.png"
    )
    foreground.resize((OUT, OUT), Image.Resampling.LANCZOS).save(
        ROOT / "foreground.png"
    )
    print("Generated Android legacy, opaque iOS, adaptive foreground masters.")


if __name__ == "__main__":
    main()

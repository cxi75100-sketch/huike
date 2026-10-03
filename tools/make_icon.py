"""Install legacy raster fallbacks and sharp Android vector artwork."""

import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets/icon"
RES = ROOT / "android/app/src/main/res"
IOS = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"

# Geometry/colors from Flutter SDK painting/flutter_logo.dart (BSD-3-Clause).
PATHS = (
    ("#54C5F8", "M37.7,128.9 L9.8,101 L100.4,10.4 L156.2,10.4 Z"),
    ("#54C5F8", "M156.2,94 L100.4,94 L78.5,115.9 L106.4,143.8 Z"),
    ("#01579B", "M79.5,170.7 L100.4,191.6 L156.2,191.6 L107.4,142.8 Z"),
    ("#29B6F6", "M51.63,142.82 L79.49,114.96 L107.35,142.82 L79.49,170.68 Z"),
)


def vector(viewport, size, scale, x, y, monochrome=False):
    paths = "\n".join(
        f'        <path android:fillColor="{("#000000" if monochrome else color)}" '
        f'android:pathData="{path}"/>' for color, path in PATHS
    )
    return (
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<!-- Flutter mark geometry: Flutter SDK, BSD-3-Clause. -->\n'
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        f'    android:width="{size}dp" android:height="{size}dp"\n'
        f'    android:viewportWidth="{viewport}" android:viewportHeight="{viewport}">\n'
        f'    <group android:scaleX="{scale}" android:scaleY="{scale}" '
        f'android:translateX="{x}" android:translateY="{y}">\n'
        f'{paths}\n    </group>\n</vector>\n'
    )


def main():
    drawable = RES / "drawable"
    for name, mono in (("launcher_mark", False), ("launcher_mark_mono", True)):
        (drawable / f"{name}.xml").write_text(
            vector(108, 108, 56 / 202, 26 + 18 * 56 / 202, 26, mono),
            encoding="utf-8",
        )
    (drawable / "splash_mark.xml").write_text(
        vector(288, 288, 0.8, 77.6, 63.2), encoding="utf-8",
    )
    (RES / "mipmap-anydpi-v26/ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@drawable/launcher_mark"/>\n'
        '    <monochrome android:drawable="@drawable/launcher_mark_mono"/>\n'
        '</adaptive-icon>\n', encoding="utf-8",
    )
    for density in ("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"):
        source = ASSETS / f"native/android/mipmap-{density}/ic_launcher.png"
        shutil.copyfile(source, RES / f"mipmap-{density}/ic_launcher.png")
        for name in ("foreground", "monochrome"):
            shutil.copyfile(source, RES / f"drawable-{density}/ic_launcher_{name}.png")
    for source in (ASSETS / "native/ios").iterdir():
        shutil.copyfile(source, IOS / source.name)
    # Retire old unreferenced slots; targets are restricted to this asset set.
    for target in IOS.glob("*.png"):
        if not (ASSETS / "native/ios" / target.name).exists():
            target.unlink()
    (RES / "values/colors.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        '    <color name="ic_launcher_background">#FFFFFF</color>\n'
        '</resources>\n',
        encoding="utf-8",
    )
    for name, source in (
        ("app_icon_android.png", "native/android/mipmap-xxxhdpi/ic_launcher.png"),
        ("foreground.png", "native/android/mipmap-xxxhdpi/ic_launcher.png"),
        ("app_icon_ios.png", "native/ios/Icon-App-1024x1024@1x.png"),
    ):
        shutil.copyfile(ASSETS / source, ASSETS / name)
    print("Installed vector Android marks and unchanged legacy/iOS fallbacks.")


if __name__ == "__main__":
    main()

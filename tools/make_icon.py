"""生成「汇课」应用图标：朱砂印章 + 华文行楷「汇」+ 内框。

产出（assets/icon/）：
- app_icon_android.png  传统 mipmap：圆角朱砂方（圆角外透明）
- app_icon_ios.png      iOS：整幅出血朱砂方（无圆角，系统自裁）
- foreground.png        自适应前景：透明底 + 内框 + 纸白「汇」（收在安全区）
自适应背景色由 pubspec 的 flutter_launcher_icons 给朱砂纯色。

候选方案（c1-c4）见 tools/make_icon_candidates.py 与 assets/icon/candidates/。
用法：python tools/make_icon.py
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

S = 2048            # 超采样画布
OUT = 1024          # 输出
ROOT = Path(__file__).resolve().parent.parent / "assets" / "icon"

PAPER = (250, 250, 248, 255)
VERMILION = (195, 64, 43, 255)
F_XINGKA = r"C:\Windows\Fonts\STXINGKA.TTF"


def centered_glyph(text, size, fill):
    """按像素包围盒把字居中到整幅画布（CJK 锚点不可靠，不用 anchor）。"""
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    font = ImageFont.truetype(F_XINGKA, size)
    ImageDraw.Draw(layer).text((0, 0), text, font=font, fill=fill)
    bbox = layer.getbbox()
    glyph = layer.crop(bbox)
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.alpha_composite(glyph, ((S - glyph.width) // 2, (S - glyph.height) // 2))
    return out


def seal_art(size, glyph_size, frame_inset, frame_width):
    """印章画面：透明底 + 内框 + 行楷「汇」，整体居中。"""
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    inset = (S - size) // 2
    d.rounded_rectangle(
        (inset + frame_inset, inset + frame_inset,
         S - inset - frame_inset, S - inset - frame_inset),
        radius=int(size * 0.09),
        outline=(250, 250, 248, 215),
        width=frame_width,
    )
    glyph = centered_glyph("汇", glyph_size, PAPER)
    layer.alpha_composite(glyph)
    return layer


def rounded_mask(radius):
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, S - 1, S - 1), radius=radius, fill=255
    )
    return mask


def main():
    ROOT.mkdir(parents=True, exist_ok=True)

    legacy = Image.new("RGBA", (S, S), VERMILION)
    legacy.alpha_composite(seal_art(int(S * 0.78), int(S * 0.52), int(S * 0.012), 16))
    masked = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    masked.paste(legacy, (0, 0), rounded_mask(int(S * 0.18)))
    masked.resize((OUT, OUT), Image.LANCZOS).save(ROOT / "app_icon_android.png")

    ios = Image.new("RGB", (S, S), VERMILION[:3])
    art = seal_art(int(S * 0.78), int(S * 0.52), int(S * 0.012), 16)
    ios.paste(art, (0, 0), art)
    ios.resize((OUT, OUT), Image.LANCZOS).save(ROOT / "app_icon_ios.png")

    fg = seal_art(int(S * 0.60), int(S * 0.40), int(S * 0.008), 18)
    fg.resize((OUT, OUT), Image.LANCZOS).save(ROOT / "foreground.png")

    print("written:", sorted(p.name for p in ROOT.iterdir() if p.is_file()))


if __name__ == "__main__":
    main()

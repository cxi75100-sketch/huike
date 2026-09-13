"""生成 4 个「汇课」图标候选，供挑选。

产出 assets/icon/candidates/c1..c4.png（1024）+ preview.png（2x2 预览）。

c1 印章行楷：朱砂底 + 华文行楷「汇」+ 内框（传统印章）
c2 汇聚卡片：多校课卡汇成一张（四色卡叠 + 白卡红「汇」）
c3 四色汇流：深墨底上四条课程色带汇成一股
c4 隶书历牌：纸底撕历 + 隶书「汇」（现方案换字体与比例）

全部 2048 超采样后缩到 1024，保证曲线平滑。
用法：python tools/make_icon_candidates.py
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

S = 2048            # 超采样画布
OUT = 1024          # 输出尺寸
ROOT = Path(__file__).resolve().parent.parent / "assets" / "icon" / "candidates"

PAPER = (250, 250, 248, 255)
INK = (29, 28, 25, 255)
VERMILION = (195, 64, 43, 255)
CARD = (255, 255, 255, 255)

# 课程签色（与 lib/core/theme/course_colors.dart 一致的低饱和编辑色）
CHI = (195, 64, 43, 255)      # 赤
QING = (46, 110, 99, 255)     # 青
DAI = (61, 90, 128, 255)      # 黛
ZHE = (150, 101, 15, 255)     # 赭

F_XINGKA = r"C:\Windows\Fonts\STXINGKA.TTF"
F_KAITI = r"C:\Windows\Fonts\STKAITI.TTF"
F_SIMLI = r"C:\Windows\Fonts\SIMLI.TTF"


def canvas(color):
    img = Image.new("RGBA", (S, S), color)
    return img, ImageDraw.Draw(img)


def text_layer(text, font_path, size, fill, letterSpacing=0):
    """按像素包围盒居中排版文字（CJK 锚点不可靠）。letterSpacing 为字间加量。"""
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    font = ImageFont.truetype(font_path, size)
    if letterSpacing <= 0:
        d.text((0, 0), text, font=font, fill=fill)
        bbox = layer.getbbox()
        glyph = layer.crop(bbox)
        out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        out.alpha_composite(
            glyph, ((S - glyph.width) // 2, (S - glyph.height) // 2)
        )
        return out
    # 手动逐字排布
    widths = []
    for ch in text:
        box = d.textbbox((0, 0), ch, font=font)
        widths.append(box[2] - box[0])
    total = sum(widths) + letterSpacing * (len(text) - 1)
    x = (S - total) // 2
    y = (S - size) // 2
    for ch, w in zip(text, widths):
        d.text((x, y), ch, font=font, fill=fill)
        x += w + letterSpacing
    return layer


def rounded_shadow(radius, blur, alpha, color=(0, 0, 0)):
    """带阴影的圆角方块底版，返回 (shadow_layer)。"""
    pad = blur * 3
    size = S - pad * 2
    sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(sh)
    d.rounded_rectangle(
        (pad, pad, pad + size, pad + size), radius=radius,
        fill=color + (alpha,),
    )
    return sh.filter(ImageFilter.GaussianBlur(blur))


def paste_center(base, layer):
    base.alpha_composite(layer)
    return base


def finish(img):
    return img.resize((OUT, OUT), Image.LANCZOS)


# ---------------------------------------------------------------- c1 印章行楷
def c1():
    img, d = canvas(VERMILION)
    # 细内框：印章边栏
    inset = 150
    d.rounded_rectangle(
        (inset, inset, S - inset, S - inset),
        radius=90,
        outline=(250, 250, 248, 200),
        width=14,
    )
    glyph = text_layer("汇", F_XINGKA, 1150, PAPER)
    paste_center(img, glyph)
    return finish(img)


# ---------------------------------------------------------------- c2 汇聚卡片
def c2():
    img, d = canvas(PAPER)
    # 背后四张课程色卡，绕中心微旋
    card_w, card_h = 760, 560
    back_specs = [
        (CHI, -14, -190, -150),
        (QING, 13, 190, -150),
        (DAI, -9, -200, 130),
        (ZHE, 10, 200, 130),
    ]
    shadow = rounded_shadow(radius=80, blur=30, alpha=60)
    for color, angle, dx, dy in back_specs:
        card = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        cd = ImageDraw.Draw(card)
        cx, cy = S // 2 + dx, S // 2 + dy
        cd.rounded_rectangle(
            (cx - card_w // 2, cy - card_h // 2,
             cx + card_w // 2, cy + card_h // 2),
            radius=80, fill=color,
        )
        card = card.rotate(angle, resample=Image.BICUBIC, center=(cx, cy))
        img.alpha_composite(shadow)
        img.alpha_composite(card)
    # 前面白卡
    cx, cy = S // 2, S // 2 + 30
    white = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    wd = ImageDraw.Draw(white)
    wd.rounded_rectangle(
        (cx - 520, cy - 420, cx + 520, cy + 420),
        radius=96, fill=CARD,
        outline=(222, 220, 213, 255), width=6,
    )
    img.alpha_composite(shadow)
    img.alpha_composite(white)
    # 白卡上的朱砂「汇」（楷体，重心微上提）
    glyph_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    g = text_layer("汇", F_KAITI, 560, VERMILION)
    # text_layer 是整幅居中；这里把它平移到白卡中心
    glyph_layer.alpha_composite(g, (0, 30))
    paste_center(img, glyph_layer)
    return finish(img)


# ---------------------------------------------------------------- c3 四色汇流
def c3():
    img, d = canvas(INK)
    # 四条色带从顶部圆角入口下来，向中心弯折，汇成一股到右侧流走。
    band = 150
    mid_y = S // 2
    xs = [430, 730, 1310, 1610]
    colors = [CHI, QING, DAI, ZHE]
    # 用宽圆头线段+圆弧模拟丝带弯折（每条：竖直段 → 四分之一弯 → 水平段汇入中心）
    for x0, color in zip(xs, colors):
        d.line((x0, -40, x0, mid_y - 320), fill=color, width=band)
        d.ellipse(
            (x0 - band // 2, mid_y - 320 - band // 2,
             x0 + band // 2, mid_y - 320 + band // 2),
            fill=color,
        )
        d.arc(
            (x0 - 320, mid_y - 320, x0 + 320, mid_y + 320),
            start=270 if x0 < S // 2 else 180,
            end=360 if x0 < S // 2 else 270,
            fill=color, width=band,
        )
    # 中央汇合竖束
    d.line((S // 2, mid_y - 60, S // 2, S + 40), fill=PAPER, width=170)
    # 汇合点：纸白大圆点
    r = 210
    d.ellipse(
        (S // 2 - r, mid_y - r, S // 2 + r, mid_y + r),
        fill=PAPER,
    )
    # 圆点上朱砂「汇」
    glyph = text_layer("汇", F_XINGKA, 330, VERMILION)
    # 平移到圆点中心
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.alpha_composite(glyph, (0, mid_y - S // 2))
    paste_center(img, out)
    return finish(img)


# ---------------------------------------------------------------- c4 隶书历牌
def c4():
    img, d = canvas(PAPER)
    card = 1500
    left = (S - card) // 2
    top = (S - card) // 2
    right = left + card
    bottom = top + card
    band_h = 340
    d.rounded_rectangle(
        (left, top, right, bottom), radius=180, fill=CARD,
        outline=(222, 220, 213, 255), width=8,
    )
    d.rounded_rectangle(
        (left, top, right, top + band_h),
        radius=180,
        corners=(True, True, False, False),
        fill=VERMILION,
    )
    hole_r = 44
    hole_y = top + band_h // 2
    for hx in (left + card // 2 - 300, left + card // 2 + 300):
        d.ellipse(
            (hx - hole_r, hole_y - hole_r, hx + hole_r, hole_y + hole_r),
            fill=PAPER,
        )
    # 隶书「汇」
    glyph = text_layer("汇", F_SIMLI, 760, VERMILION)
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    y_shift = ((top + band_h) + bottom) // 2 - S // 2 - 40
    out.alpha_composite(glyph, (0, y_shift))
    paste_center(img, out)
    return finish(img)


def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    made = {
        "c1_seal.png": c1(),
        "c2_cards.png": c2(),
        "c3_rivers.png": c3(),
        "c4_lishu.png": c4(),
    }
    for name, img in made.items():
        img.save(ROOT / name)
    # 预览网格：2x2，带标签
    cell = 480
    preview = Image.new("RGB", (cell * 2 + 60, cell * 2 + 100), (245, 245, 243))
    pd = ImageDraw.Draw(preview)
    labels = ["c1 印章行楷", "c2 汇聚卡片", "c3 四色汇流", "c4 隶书历牌"]
    for i, (name, img) in enumerate(made.items()):
        x = 20 + (i % 2) * (cell + 20)
        y = 20 + (i // 2) * (cell + 40)
        preview.paste(img.convert("RGB").resize((cell, cell), Image.LANCZOS), (x, y))
        pd.text((x + 10, y + cell + 8), labels[i], fill=(60, 60, 60))
    preview.save(ROOT / "preview.png")
    print("written:", sorted(p.name for p in ROOT.iterdir()))


if __name__ == "__main__":
    main()

"""从统一母版 scripts/brand_icon.png 生成真果TV 全平台图标资源。

母版：1024×1024 不透明 PNG（深蓝黑底 #131522、橙紫渐变对话气泡、深色粗体 T）。
只依赖 Pillow，不依赖 resvg-py，便于在 CI / 任意机器上一键重生成。

用法：python scripts/generate_brand_assets.py [--output <目录>] [--font <中文字体>]
"""
import argparse
import glob
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description='生成真果TV 全平台图标资源（仅需 Pillow）')
parser.add_argument('--output', type=Path, default=root)
parser.add_argument('--font', type=Path, default=None)
options = parser.parse_args()
output = options.output

BG = '#131522'          # 母版背景色，同时用作 Android 自适应图标底色
APP_NAME = '真果TV'
APP_NAME_LATIN = 'ZhenGuoTV'


def find_cjk_font():
    if options.font and options.font.is_file():
        return str(options.font), True
    patterns = [
        '/System/Library/Fonts/PingFang.ttc',
        '/usr/share/fonts/**/NotoSansCJK*',
        '/usr/share/fonts/**/NotoSerifCJK*',
        '/usr/share/fonts/**/wqy*',
    ]
    for pattern in patterns:
        hits = sorted(glob.glob(pattern, recursive=True))
        if hits:
            return hits[0], True
    return None, False


def save(image, name):
    destination = output / name
    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination)


source = Image.open(root / 'scripts' / 'brand_icon.png').convert('RGBA')
if source.size != (1024, 1024):
    source = source.resize((1024, 1024), Image.Resampling.LANCZOS)

# iOS / macOS 图标必须不透明（无 alpha 通道）
icon = Image.new('RGBA', (1024, 1024), BG)
icon.alpha_composite(source)
icon_rgb = icon.convert('RGB')

# 带圆角的版本（Windows / Android legacy / TV banner 用）
rounded = icon.copy()
corners = Image.new('L', (1024, 1024), 0)
ImageDraw.Draw(corners).rounded_rectangle((0, 0, 1023, 1023), radius=236, fill=255)
rounded.putalpha(corners)

# Android 自适应图标前景：1536 画布，母版居中，四周留安全区
adaptive = Image.new('RGBA', (1536, 1536))
adaptive.paste(icon, (256, 256))
monochrome = Image.new('RGBA', (1536, 1536))
monochrome.paste(ImageOps.grayscale(icon_rgb).convert('RGBA'), (256, 256))


def generate_from_contents(rel_path, base_image, to_rgb=True):
    contents = json.loads((root / rel_path).read_text())
    count = 0
    for entry in contents['images']:
        if 'filename' not in entry:
            continue
        size = round(float(entry['size'].split('x')[0]) * float(entry['scale'].rstrip('x')))
        image = (icon_rgb if to_rgb else rounded).resize((size, size), Image.Resampling.LANCZOS)
        save(image, str(Path(rel_path).parent / entry['filename']))
        count += 1
    return count


n_ios = generate_from_contents(
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json', icon_rgb)
n_macos = generate_from_contents(
    'macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json', rounded, to_rgb=False)

save(rounded.resize((256, 256), Image.Resampling.LANCZOS),
     'windows/runner/resources/app_icon.ico')

for density, scale in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]:
    legacy = round(48 * scale)
    layer = round(108 * scale)
    save(rounded.resize((legacy, legacy), Image.Resampling.LANCZOS),
         f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')
    save(adaptive.resize((layer, layer), Image.Resampling.LANCZOS),
         f'android/app/src/main/res/mipmap-{density}/ic_launcher_foreground.png')
    save(monochrome.resize((layer, layer), Image.Resampling.LANCZOS),
         f'android/app/src/main/res/mipmap-{density}/ic_launcher_monochrome.png')

font_path, has_cjk = find_cjk_font()
font = ImageFont.truetype(font_path, 76) if font_path else ImageFont.load_default()
label = APP_NAME if has_cjk else APP_NAME_LATIN
for resource in ('tv_banner', 'tv_banner_all_sources'):
    banner = Image.new('RGB', (640, 360), BG)
    badge = rounded.resize((180, 180), Image.Resampling.LANCZOS)
    banner.paste(badge, (44, 90), badge)
    ImageDraw.Draw(banner).text((255, 128), label, font=font, fill='#F5F5FA')
    save(banner, f'android/app/src/main/res/drawable-xhdpi/{resource}.png')

print(f'已生成：iOS {n_ios} 个、macOS {n_macos} 个、Android 5 档密度 ×3、'
      f'Windows ico ×1、TV banner ×2；母版 = scripts/brand_icon.png')

"""Рисует значок приложения. Геометрия — та же, что у BrandMark (lib/features/common/brand_mark.dart).

Запуск из папки app/:   ../.venv/bin/python tool/make_icon.py
Потом:                  dart run flutter_launcher_icons
"""
from PIL import Image, ImageDraw

PETROL = (11, 85, 99, 255)
WHITE = (255, 255, 255, 255)
AMBER = (242, 169, 59, 255)
SIZE = 1024
SCALE = 4  # рисуем в 4 раза крупнее и уменьшаем — гладкие края


def shapes(draw, s, block, amber):
    """Два блока и точка-звонок в координатах квадрата s×s."""
    r = s * 0.07
    draw.rounded_rectangle([s * 0.22, s * 0.30, s * 0.22 + s * 0.56, s * 0.30 + s * 0.14], radius=r, fill=block)
    draw.rounded_rectangle([s * 0.22, s * 0.56, s * 0.22 + s * 0.34, s * 0.56 + s * 0.14], radius=r, fill=amber)
    cx, cy, cr = s * 0.68, s * 0.63, s * 0.07
    draw.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=amber)


def render(kind):
    s = SIZE * SCALE
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if kind == "icon":  # обычный значок: скруглённая плитка
        d.rounded_rectangle([0, 0, s, s], radius=s * 0.28, fill=PETROL)
        shapes(d, s, WHITE, AMBER)
    elif kind == "foreground":  # адаптивный: прозрачный фон (фон — отдельным цветом)
        shapes(d, s, WHITE, AMBER)
    elif kind == "monochrome":  # одноцветный для «тематических» значков Android 13+
        shapes(d, s, WHITE, WHITE)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


for name in ("icon", "foreground", "monochrome"):
    render(name).save(f"assets/icon/{name}.png")
    print("готово:", f"assets/icon/{name}.png")

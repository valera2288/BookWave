from io import BytesIO

from django.core.files.base import ContentFile
from django.core.management.base import BaseCommand
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

from apps.banners.models import Banner
from apps.catalog.models import Book

W, H = 1600, 700
FONT_DIR = "C:/Windows/Fonts"


def _font(name, size):
    return ImageFont.truetype(f"{FONT_DIR}/{name}", size)


def _vertical_gradient(size, top_color, bottom_color):
    w, h = size
    base = Image.new("RGB", (1, h), 0)
    for y in range(h):
        t = y / (h - 1)
        r = round(top_color[0] + (bottom_color[0] - top_color[0]) * t)
        g = round(top_color[1] + (bottom_color[1] - top_color[1]) * t)
        b = round(top_color[2] + (bottom_color[2] - top_color[2]) * t)
        base.putpixel((0, y), (r, g, b))
    return base.resize((w, h))


def _draw_badge(draw, xy, text, font, fg, bg):
    pad_x, pad_y = 18, 10
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x, y = xy
    draw.rounded_rectangle(
        [x, y, x + tw + pad_x * 2, y + th + pad_y * 2], radius=(th + pad_y * 2) // 2, fill=bg
    )
    draw.text((x + pad_x, y + pad_y - bbox[1]), text, font=font, fill=fg)
    return th + pad_y * 2


def _wrap_text(draw, text, font, max_width):
    words = text.split()
    lines, cur = [], ""
    for word in words:
        trial = f"{cur} {word}".strip()
        if draw.textbbox((0, 0), trial, font=font)[2] <= max_width:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = word
    if cur:
        lines.append(cur)
    return lines


def _build_banner(
    *,
    top_color,
    bottom_color,
    badge_text,
    badge_fg,
    badge_bg,
    book,
    subtitle=None,
    title=None,
    show_price=True,
):
    img = _vertical_gradient((W, H), top_color, bottom_color).convert("RGB")

    overlay = Image.new("RGB", (W, H), bottom_color)
    mask = Image.new("L", (W, H), 0)
    md = ImageDraw.Draw(mask)
    md.ellipse([int(W * 0.55), int(-H * 0.6), int(W * 1.3), int(H * 0.9)], fill=60)
    img = Image.composite(overlay, img, mask).filter(ImageFilter.GaussianBlur(2))

    draw = ImageDraw.Draw(img)
    margin = 72
    badge_h = _draw_badge(
        draw, (margin, margin), badge_text, _font("segoeuib.ttf", 30), badge_fg, badge_bg
    )

    title_font = _font("segoeuib.ttf", 64)
    author_font = _font("segoeui.ttf", 34)
    price_font = _font("segoeuib.ttf", 46)

    text_max_width = int(W * 0.56)
    title_text = title if title is not None else book.title
    title_lines = _wrap_text(draw, title_text, title_font, text_max_width)[:3]
    y = margin + badge_h + 28
    for line in title_lines:
        draw.text((margin, y), line, font=title_font, fill="white")
        y += 74

    subtitle_text = subtitle if subtitle is not None else ", ".join(a.name for a in book.authors.all())
    if subtitle_text:
        draw.text((margin, y + 6), subtitle_text, font=author_font, fill="white")
        y += 54

    if show_price:
        draw.text((margin, y + 20), f"{book.price:.0f} \u20bd", font=price_font, fill="white")

    if book.cover:
        book.cover.open()
        cover = Image.open(BytesIO(book.cover.read())).convert("RGB")
        cover_h = int(H * 0.86)
        cover_w = int(cover_h * cover.width / cover.height)
        cover = cover.resize((cover_w, cover_h), Image.LANCZOS)
        cover = ImageOps.expand(cover, border=6, fill="white").convert("RGBA")
        # Поворот RGB-картинки заливает открывшиеся углы чёрным (нет альфы,
        # которая бы сделала их прозрачными) — сначала переводим в RGBA.
        cover = cover.rotate(-4, expand=True, resample=Image.BICUBIC)

        shadow_pos = (W - cover.width - margin + 14, (H - cover.height) // 2 + 14)
        shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
        shadow.paste(
            (0, 0, 0, 90),
            (
                shadow_pos[0],
                shadow_pos[1],
                shadow_pos[0] + cover.width,
                shadow_pos[1] + cover.height,
            ),
        )
        shadow = shadow.filter(ImageFilter.GaussianBlur(14))
        img = Image.alpha_composite(img.convert("RGBA"), shadow).convert("RGB")

        cover_pos = (W - cover.width - margin, (H - cover.height) // 2)
        img.paste(cover, cover_pos, cover)

    buf = BytesIO()
    img.convert("RGB").save(buf, format="JPEG", quality=90)
    buf.seek(0)
    return buf.getvalue()


class Command(BaseCommand):
    """Генерирует нормальные баннеры (градиент + обложка + текст) вместо
    залитых одним цветом заглушек из исходных сид-данных — по просьбе
    пользователя (визуально «доделать» карусель на главной, 2026-09-18).
    Баннеры — маркетинговый актив без привязки к конкретному правообладателю
    (в отличие от обложек книг), поэтому генерация через Pillow тут уместна
    и ничего не подделывает."""

    help = "Перерисовывает существующие баннеры (id=1, id=2) через Pillow"

    def handle(self, *args, **options):
        banner1 = Banner.objects.get(id=1)
        book1 = Book.objects.get(id=banner1.link_book_id)
        data1 = _build_banner(
            top_color=(30, 58, 138),
            bottom_color=(37, 99, 235),
            badge_text="НОВИНКА",
            badge_fg=(30, 58, 138),
            badge_bg=(255, 255, 255),
            book=book1,
        )
        banner1.image.save("banner1-newrelease.jpg", ContentFile(data1), save=True)
        self.stdout.write(f"OK banner=1 book={book1.id} -> {banner1.image.name}")

        # ТЗ («Требования к просмотру главной страницы»): карусель — именно
        # «новинки и акции». 25% — решение пользователя (2026-09-19); не
        # привязываем текст к конкретной книге/цене (промокод действует на
        # любую книгу, а не именно на ту, чья обложка тут для красоты) —
        # только к самому предложению.
        banner2 = Banner.objects.get(id=2)
        book2 = Book.objects.get(id=banner2.link_book_id)
        data2 = _build_banner(
            top_color=(194, 65, 12),
            bottom_color=(249, 115, 22),
            badge_text="АКЦИЯ",
            badge_fg=(154, 52, 18),
            badge_bg=(255, 255, 255),
            book=book2,
            title="Скидка 25% на любую книгу",
            subtitle="Успейте купить по промокоду",
            show_price=False,
        )
        banner2.image.save("banner2-promo25.jpg", ContentFile(data2), save=True)
        self.stdout.write(f"OK banner=2 book={book2.id} -> {banner2.image.name}")

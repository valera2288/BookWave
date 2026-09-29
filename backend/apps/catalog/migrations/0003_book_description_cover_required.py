# Обязательность description/cover по ТЗ п.216: сейчас у всех книг в базе
# оба поля уже заполнены (проверено вручную перед миграцией), поэтому
# бэкфилл дефолтом не нужен — ALTER COLUMN сразу на NOT NULL.

import apps.catalog.validators
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('catalog', '0002_alter_book_page_count_alter_book_price_and_more'),
    ]

    operations = [
        migrations.AlterField(
            model_name='book',
            name='description',
            field=models.TextField(),
        ),
        migrations.AlterField(
            model_name='book',
            name='cover',
            field=models.ImageField(upload_to='covers/', validators=[apps.catalog.validators.validate_cover_file]),
        ),
    ]

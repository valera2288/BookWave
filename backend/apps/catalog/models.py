from decimal import Decimal

from django.core.validators import FileExtensionValidator, MaxValueValidator, MinValueValidator
from django.db import models

from .validators import validate_book_file_size, validate_cover_file, validate_publication_year


class Author(models.Model):
    name = models.CharField(max_length=150, unique=True)

    class Meta:
        db_table = "authors"
        ordering = ["name"]

    def __str__(self):
        return self.name


class Genre(models.Model):
    name = models.CharField(max_length=100, unique=True)

    class Meta:
        db_table = "genres"
        ordering = ["name"]

    def __str__(self):
        return self.name


class Book(models.Model):
    title = models.CharField(max_length=255)
    authors = models.ManyToManyField(Author, related_name="books", db_table="book_authors")
    genres = models.ManyToManyField(Genre, related_name="books", db_table="book_genres")
    language = models.CharField(max_length=50)
    publisher = models.CharField(max_length=150, blank=True)
    publication_year = models.PositiveSmallIntegerField(
        null=True, blank=True, validators=[validate_publication_year]
    )
    page_count = models.PositiveIntegerField(
        null=True, blank=True, validators=[MinValueValidator(1), MaxValueValidator(20000)]
    )
    isbn = models.CharField(max_length=20, unique=True)
    price = models.DecimalField(
        max_digits=8, decimal_places=2, validators=[MinValueValidator(Decimal("0.01"))]
    )
    description = models.TextField(blank=True)
    cover = models.ImageField(
        upload_to="covers/", validators=[validate_cover_file], null=True, blank=True
    )
    epub_file = models.FileField(
        upload_to="books/epub/",
        validators=[FileExtensionValidator(["epub"]), validate_book_file_size],
    )
    pdf_file = models.FileField(
        upload_to="books/pdf/",
        validators=[FileExtensionValidator(["pdf"]), validate_book_file_size],
        null=True,
        blank=True,
    )
    fb2_file = models.FileField(
        upload_to="books/fb2/",
        validators=[FileExtensionValidator(["fb2"]), validate_book_file_size],
        null=True,
        blank=True,
    )
    is_active = models.BooleanField(default=True)
    deleted_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "books"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["is_active"]),
            models.Index(fields=["isbn"]),
            models.Index(fields=["created_at"]),
            models.Index(fields=["price"]),
        ]

    def __str__(self):
        return self.title

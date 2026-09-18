from rest_framework import serializers

from .models import Review


class ReviewSerializer(serializers.ModelSerializer):
    """Отзыв под карточкой книги. `is_mine` позволяет клиенту показать
    кнопки редактирования/удаления прямо в списке, не делая отдельный запрос."""

    user_name = serializers.CharField(source="user.name", read_only=True)
    user_avatar = serializers.ImageField(source="user.avatar", read_only=True)
    is_mine = serializers.SerializerMethodField()

    class Meta:
        model = Review
        fields = [
            "id",
            "user_name",
            "user_avatar",
            "rating",
            "text",
            "is_mine",
            "created_at",
            "updated_at",
        ]

    def get_is_mine(self, obj):
        request = self.context.get("request")
        return bool(
            request and request.user.is_authenticated and obj.user_id == request.user.id
        )


class ReviewWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Review
        fields = ["rating", "text"]


class ReviewAdminSerializer(serializers.ModelSerializer):
    """Список отзывов для модерации (ТЗ) — включая уже скрытые."""

    book_title = serializers.CharField(source="book.title", read_only=True)
    user_name = serializers.CharField(source="user.name", read_only=True)
    user_email = serializers.EmailField(source="user.email", read_only=True)

    class Meta:
        model = Review
        fields = [
            "id",
            "book",
            "book_title",
            "user_name",
            "user_email",
            "rating",
            "text",
            "is_hidden",
            "created_at",
        ]
        read_only_fields = [
            "book",
            "book_title",
            "user_name",
            "user_email",
            "rating",
            "text",
            "created_at",
        ]


class ReviewModerationSerializer(serializers.ModelSerializer):
    """Модератор может только скрыть/показать отзыв — не редактировать текст
    или оценку от чужого имени (ТЗ)."""

    class Meta:
        model = Review
        fields = ["is_hidden"]

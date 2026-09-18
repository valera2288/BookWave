from django.contrib.auth.password_validation import validate_password
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import EmailConfirmationToken, PasswordResetToken, User


def validate_user_name(value: str) -> str:
    if not (2 <= len(value) <= 50):
        raise serializers.ValidationError("Имя должно быть от 2 до 50 символов.")
    return value


class BookWaveTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token["token_version"] = user.token_version
        token["role"] = user.role
        return token


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id",
            "email",
            "name",
            "role",
            "avatar",
            "theme",
            "language",
            "email_verified",
            "date_joined",
        ]
        read_only_fields = fields


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, max_length=128)
    accept_terms = serializers.BooleanField(write_only=True)

    class Meta:
        model = User
        fields = ["email", "name", "password", "accept_terms"]

    def validate_name(self, value):
        return validate_user_name(value)

    def validate_password(self, value):
        validate_password(value)
        return value

    def validate_accept_terms(self, value):
        if not value:
            raise serializers.ValidationError(
                "Необходимо принять пользовательское соглашение."
            )
        return value

    def create(self, validated_data):
        validated_data.pop("accept_terms")
        password = validated_data.pop("password")
        return User.objects.create_user(password=password, **validated_data)


class UpdateProfileSerializer(serializers.ModelSerializer):
    """PATCH-редактирование профиля (ТЗ: имя, аватар, тема, язык) — e-mail
    сюда не входит, у него отдельный флоу с реконфирмацией
    (`EmailChangeRequestSerializer`)."""

    class Meta:
        model = User
        fields = ["name", "avatar", "theme", "language"]
        extra_kwargs = {field: {"required": False} for field in fields}

    def validate_name(self, value):
        return validate_user_name(value)


class EmailChangeRequestSerializer(serializers.Serializer):
    # max_length совпадает с `User.email` (Django EmailField по умолчанию —
    # 254) — без него слишком длинный адрес прошёл бы валидацию здесь и
    # упал бы 500-й на confirm (`user.save()`) вместо чистой 400-й сейчас.
    new_email = serializers.EmailField(max_length=254)

    def validate_new_email(self, value):
        user = self.context["request"].user
        value = User.objects.normalize_email(value)
        if value == user.email:
            raise serializers.ValidationError("Это уже ваш текущий e-mail.")
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Этот e-mail уже используется.")
        return value


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()


class PasswordResetConfirmSerializer(serializers.Serializer):
    token = serializers.CharField(max_length=64)
    new_password = serializers.CharField(write_only=True, max_length=128)
    new_password2 = serializers.CharField(write_only=True, max_length=128)

    def validate(self, attrs):
        if attrs["new_password"] != attrs["new_password2"]:
            raise serializers.ValidationError(
                {"new_password2": "Пароли не совпадают."}
            )
        try:
            reset_token = PasswordResetToken.objects.select_related("user").get(
                token=attrs["token"]
            )
        except PasswordResetToken.DoesNotExist:
            raise serializers.ValidationError({"token": "Токен недействителен."})
        if not reset_token.is_valid:
            raise serializers.ValidationError(
                {"token": "Токен недействителен или истёк."}
            )
        validate_password(attrs["new_password"], user=reset_token.user)
        attrs["reset_token"] = reset_token
        return attrs

    def save(self):
        reset_token = self.validated_data["reset_token"]
        user = reset_token.user
        user.set_password(self.validated_data["new_password"])
        user.token_version += 1
        user.save(update_fields=["password", "token_version"])
        reset_token.used_at = timezone.now()
        reset_token.save(update_fields=["used_at"])
        return user


class ChangePasswordSerializer(serializers.Serializer):
    current_password = serializers.CharField(write_only=True, max_length=128)
    new_password = serializers.CharField(write_only=True, max_length=128)
    new_password2 = serializers.CharField(write_only=True, max_length=128)

    def validate(self, attrs):
        user = self.context["request"].user
        if not user.check_password(attrs["current_password"]):
            raise serializers.ValidationError(
                {"current_password": "Неверный текущий пароль."}
            )
        if attrs["new_password"] != attrs["new_password2"]:
            raise serializers.ValidationError(
                {"new_password2": "Пароли не совпадают."}
            )
        validate_password(attrs["new_password"], user=user)
        return attrs

    def save(self):
        user = self.context["request"].user
        user.set_password(self.validated_data["new_password"])
        user.token_version += 1
        user.save(update_fields=["password", "token_version"])
        return user


class EmailConfirmationSerializer(serializers.Serializer):
    token = serializers.CharField(max_length=64)

    def validate(self, attrs):
        try:
            confirmation = EmailConfirmationToken.objects.select_related("user").get(
                token=attrs["token"]
            )
        except EmailConfirmationToken.DoesNotExist:
            raise serializers.ValidationError({"token": "Токен недействителен."})
        if not confirmation.is_valid:
            raise serializers.ValidationError(
                {"token": "Токен недействителен или истёк."}
            )
        if confirmation.new_email and (
            User.objects.exclude(pk=confirmation.user_id)
            .filter(email=confirmation.new_email)
            .exists()
        ):
            # Токен живёт до 3 дней — за это время адрес мог занять кто-то
            # другой (сам пользователь смены e-mail с этим адресом больше
            # не сделает, exclude по pk не мешает повторному подтверждению
            # собственного токена).
            raise serializers.ValidationError(
                {"token": "Этот e-mail уже используется другим пользователем."}
            )
        attrs["confirmation"] = confirmation
        return attrs

    def save(self):
        confirmation = self.validated_data["confirmation"]
        confirmation.used_at = timezone.now()
        confirmation.save(update_fields=["used_at"])
        user = confirmation.user
        update_fields = ["email_verified"]
        user.email_verified = True
        if confirmation.new_email:
            user.email = confirmation.new_email
            update_fields.append("email")
        user.save(update_fields=update_fields)
        return user

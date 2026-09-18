from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import AuthenticationFailed


class TokenVersionJWTAuthentication(JWTAuthentication):
    """JWTAuthentication, отклоняющая токены, выданные до смены пароля.

    Со stateless JWT смена пароля сама по себе не завершает уже выданные
    сессии — сверяем claim token_version из токена с текущим значением
    на пользователе (инкрементируется при смене/сбросе пароля).
    """

    def get_user(self, validated_token):
        user = super().get_user(validated_token)
        token_version = validated_token.get("token_version")
        if token_version is None or token_version != user.token_version:
            raise AuthenticationFailed("Токен отозван.", code="token_revoked")
        return user

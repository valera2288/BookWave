// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get onboardingSkip => 'Пропустить';

  @override
  String get onboardingNext => 'Далее';

  @override
  String get onboardingStart => 'Начать';

  @override
  String get onboardingSlide1Title => 'Тысячи книг под рукой';

  @override
  String get onboardingSlide1Description =>
      'Большой каталог электронных книг всех жанров — от новинок до классики.';

  @override
  String get onboardingSlide2Title => 'Удобная читалка';

  @override
  String get onboardingSlide2Description =>
      'Настройте шрифт и тему под себя, добавляйте закладки и ищите нужный отрывок по тексту.';

  @override
  String get onboardingSlide3Title => 'Читайте бесплатный фрагмент';

  @override
  String get onboardingSlide3Description =>
      'Перед покупкой можно бесплатно прочитать начало любой книги из каталога.';

  @override
  String get onboardingSlide4Title => 'Прогресс всегда с вами';

  @override
  String get onboardingSlide4Description =>
      'Библиотека купленных книг и прогресс чтения сохраняются на вашем аккаунте.';

  @override
  String get authTabLogin => 'Вход';

  @override
  String get authTabRegister => 'Регистрация';

  @override
  String get authEmailInvalid => 'Введите корректный e-mail';

  @override
  String get authPasswordLabel => 'Пароль';

  @override
  String get authPasswordRequired => 'Введите пароль';

  @override
  String get authNameLabel => 'Имя';

  @override
  String get authNameLengthError => 'Имя должно быть от 2 до 50 символов';

  @override
  String get authPasswordMinLength => 'Минимум 8 символов';

  @override
  String get authPasswordNeedsDigit =>
      'Пароль должен содержать минимум одну цифру';

  @override
  String get authAcceptTermsLabel => 'Принимаю пользовательское соглашение';

  @override
  String get authAcceptTermsRequired =>
      'Необходимо принять пользовательское соглашение.';

  @override
  String get authGenericError => 'Не удалось выполнить запрос.';

  @override
  String authLockoutMessage(int seconds) {
    return 'Слишком много попыток. Повторите через $seconds с.';
  }

  @override
  String authLockedButton(int seconds) {
    return 'Заблокировано ($seconds с)';
  }

  @override
  String get authLoginButton => 'Войти';

  @override
  String get authRegisterButton => 'Зарегистрироваться';

  @override
  String get authForgotPassword => 'Забыли пароль?';

  @override
  String get authResetTitle => 'Сброс пароля';

  @override
  String get authResetInstructions =>
      'Укажите e-mail, указанный при регистрации — пришлём ссылку для сброса пароля.';

  @override
  String get authSend => 'Отправить';

  @override
  String get authResetSentMessage =>
      'Если такой e-mail зарегистрирован, на него отправлено письмо со ссылкой для сброса пароля. Откройте ссылку из письма на этом устройстве — форма нового пароля откроется автоматически.';

  @override
  String get authResetManualTokenLink =>
      'Ссылка не открылась — ввести токен вручную';

  @override
  String get authNewPassword => 'Новый пароль';

  @override
  String get authTokenLabel => 'Токен из письма';

  @override
  String get authTokenRequired => 'Введите токен';

  @override
  String get authRepeatPasswordLabel => 'Повторите пароль';

  @override
  String get authPasswordsMismatch => 'Пароли не совпадают';

  @override
  String get authSavePassword => 'Сохранить пароль';

  @override
  String get authPasswordChangedMessage =>
      'Пароль изменён. Теперь можно войти.';

  @override
  String get authContinueAsGuest => 'Продолжить как гость';

  @override
  String get navHome => 'Главная';

  @override
  String get navCatalog => 'Каталог';

  @override
  String get navLibrary => 'Библиотека';

  @override
  String get navProfile => 'Профиль';

  @override
  String get navCart => 'Корзина';

  @override
  String homeGreeting(String name) {
    return 'Здравствуйте, $name!';
  }

  @override
  String get homeGreetingGuest => 'Здравствуйте!';

  @override
  String get homeSectionNewest => 'Новинки';

  @override
  String get homeSectionTopSellers => 'Топ продаж';

  @override
  String get homeSectionRecommended => 'Рекомендуем';

  @override
  String get homeSectionGenres => 'Жанры';

  @override
  String notYetAvailableMessage(String feature) {
    return '$feature появится в одной из следующих фаз.';
  }

  @override
  String get featureBannerLink => 'Переход по ссылке баннера';

  @override
  String get featureExcerptReading => 'Чтение фрагмента';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get catalogSortTooltip => 'Сортировка';

  @override
  String get catalogFiltersTooltip => 'Фильтры';

  @override
  String get catalogSearchHint => 'Название, автор, ISBN';

  @override
  String get catalogEmptyResults => 'Ничего не найдено';

  @override
  String get catalogSortDefault => 'По умолчанию';

  @override
  String get catalogSortCheapFirst => 'Сначала дешёвые';

  @override
  String get catalogSortExpensiveFirst => 'Сначала дорогие';

  @override
  String get catalogSortRating => 'По рейтингу';

  @override
  String get catalogSortNewest => 'Сначала новинки';

  @override
  String get filterGenreFallback => 'Жанр';

  @override
  String filterRatingFrom(int rating) {
    return 'от $rating★';
  }

  @override
  String get filtersReset => 'Сбросить';

  @override
  String get filtersApply => 'Применить';

  @override
  String get filtersGenreLabel => 'Жанр';

  @override
  String get filtersGenresLoadError => 'Не удалось загрузить жанры';

  @override
  String get filtersPriceLabel => 'Цена, ₽';

  @override
  String get filtersLanguageLabel => 'Язык';

  @override
  String get filtersLanguagesLoadError => 'Не удалось загрузить список языков';

  @override
  String get filtersMinRatingLabel => 'Минимальный рейтинг';

  @override
  String get cartEmpty => 'Корзина пуста';

  @override
  String get cartRemoveItemTooltip => 'Удалить из корзины';

  @override
  String get cartPromoHint => 'Промокод';

  @override
  String get cartSubtotal => 'Сумма товаров';

  @override
  String get cartPromoDiscount => 'Скидка по промокоду';

  @override
  String get cartTotal => 'Итого';

  @override
  String get cartCheckoutButton => 'Оформить заказ';

  @override
  String get bookDetailTitle => 'Книга';

  @override
  String get bookDetailLoadError => 'Не удалось загрузить книгу';

  @override
  String get bookDetailNoRatings => 'Нет оценок';

  @override
  String get bookDetailAlreadyOwned => 'Уже в вашей библиотеке';

  @override
  String get bookDetailFavorited => 'В избранном';

  @override
  String get bookDetailAddToFavorites => 'В избранное';

  @override
  String get bookDetailAddToCart => 'Добавить в корзину';

  @override
  String get bookDetailRead => 'Читать';

  @override
  String get bookDetailReadExcerpt => 'Читать фрагмент';

  @override
  String get bookDetailGenre => 'Жанр';

  @override
  String get bookDetailLanguage => 'Язык';

  @override
  String get bookDetailPublisher => 'Издательство';

  @override
  String get bookDetailPublicationYear => 'Год издания';

  @override
  String get bookDetailPageCount => 'Объём';

  @override
  String bookDetailPages(int count) {
    return '$count стр.';
  }

  @override
  String get bookDetailDescription => 'Описание';

  @override
  String get bookDetailReviews => 'Отзывы';

  @override
  String get bookDetailAddedToCart => 'Добавлено в корзину';

  @override
  String get bookDetailAlreadyInCart => 'Уже в корзине';

  @override
  String get orderStatusPaid => 'Оплачен';

  @override
  String get orderStatusCancelled => 'Отменён';

  @override
  String get orderStatusRefunded => 'Возврат';

  @override
  String get ordersTitle => 'Мои заказы';

  @override
  String get ordersLoadError => 'Не удалось загрузить заказы';

  @override
  String get ordersEmpty => 'Заказов пока нет';

  @override
  String orderTileTitle(int id, int count) {
    return 'Заказ #$id · $count книг(и)';
  }

  @override
  String orderDetailTitle(int id) {
    return 'Заказ #$id';
  }

  @override
  String get orderDetailLoadError => 'Не удалось загрузить заказ';

  @override
  String orderItemCount(int count) {
    return '$count книг(и)';
  }

  @override
  String get checkoutTitle => 'Оформление заказа';

  @override
  String get checkoutYourOrder => 'Ваш заказ';

  @override
  String get checkoutTotalToPay => 'Итого к оплате';

  @override
  String get checkoutPayment => 'Оплата';

  @override
  String get checkoutPaymentHint =>
      'Тестовые данные, реальная оплата не выполняется. Номер карты 4000 0000 0000 0002 имитирует отказ, любой другой — успех.';

  @override
  String get checkoutCardNumber => 'Номер карты';

  @override
  String get checkoutPayButton => 'Оплатить';

  @override
  String get orderSuccessTitle => 'Заказ оформлен';

  @override
  String get orderSuccessMessage => 'Заказ успешно оформлен';

  @override
  String orderSuccessNumber(int id) {
    return 'Номер заказа: #$id';
  }

  @override
  String get orderSuccessGoToLibrary => 'Перейти в библиотеку';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get libraryRemoveTitle => 'Удалить книгу из библиотеки?';

  @override
  String libraryRemoveMessage(String title) {
    return '«$title» будет удалена из «Моей библиотеки» вместе с прогрессом чтения. Это действие нельзя отменить.';
  }

  @override
  String get libraryRemoveError => 'Не удалось удалить книгу из библиотеки';

  @override
  String get libraryLoadError => 'Не удалось загрузить библиотеку';

  @override
  String get libraryEmpty => 'Пока нет купленных книг';

  @override
  String get libraryRemoveTooltip => 'Удалить из библиотеки';

  @override
  String get libraryNewBadge => 'Новая';

  @override
  String get favoritesTitle => 'Избранное';

  @override
  String get favoritesLoadError => 'Не удалось загрузить избранное';

  @override
  String get favoritesEmpty => 'Пока нет книг в избранном';

  @override
  String reviewsLoadError(String error) {
    return 'Не удалось загрузить отзывы: $error';
  }

  @override
  String get reviewsEmpty => 'Отзывов пока нет.';

  @override
  String get reviewsShowMore => 'Показать ещё';

  @override
  String get reviewsPurchaseRequired =>
      'Оставить отзыв можно после покупки книги.';

  @override
  String get reviewSelectRating => 'Выберите оценку от 1 до 5 звёзд';

  @override
  String reviewTextTooShort(int minLength) {
    return 'Текст отзыва должен быть не короче $minLength символов';
  }

  @override
  String get reviewSaved => 'Отзыв сохранён';

  @override
  String get reviewDeleteTitle => 'Удалить отзыв?';

  @override
  String get reviewDeleteMessage =>
      'Отзыв будет удалён без возможности восстановления.';

  @override
  String get reviewLeaveTitle => 'Оставить отзыв';

  @override
  String get reviewYourTitle => 'Ваш отзыв';

  @override
  String get reviewTextHint =>
      'Расскажите о впечатлениях от книги (необязательно, от 10 символов)';

  @override
  String get reviewSave => 'Сохранить';

  @override
  String get readerFormatUnsupported => 'Формат не поддерживается';

  @override
  String get readerTocUnavailable => 'Оглавление недоступно';

  @override
  String get readerSearchHint => 'Поиск по тексту книги';

  @override
  String get readerBookmarksTitle => 'Закладки';

  @override
  String get readerBookmarkAddHere => 'На этой странице';

  @override
  String get readerBookmarksLoadError => 'Не удалось загрузить закладки';

  @override
  String get readerBookmarksEmpty => 'Закладок пока нет';

  @override
  String readerBookmarkTitle(int index) {
    return 'Закладка $index';
  }

  @override
  String get readerFontSize => 'Размер шрифта';

  @override
  String get readerTheme => 'Тема чтения';

  @override
  String get readerThemeLight => 'Светлая';

  @override
  String get readerThemeDark => 'Тёмная';

  @override
  String get readerThemeSepia => 'Сепия';

  @override
  String get readerContinuousScroll => 'Непрерывная прокрутка';

  @override
  String get readerSearchTooltip => 'Поиск по тексту';

  @override
  String get readerTocTooltip => 'Оглавление';

  @override
  String get readerSettingsTooltip => 'Настройки чтения';

  @override
  String get readerFileLoadError => 'Не удалось загрузить файл книги';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileEdit => 'Изменить профиль';

  @override
  String get profileSettings => 'Настройки';

  @override
  String get profileLogout => 'Выйти';

  @override
  String get profileLogoutTitle => 'Выйти из аккаунта?';

  @override
  String get profileLogoutMessage =>
      'Понадобится снова ввести e-mail и пароль для входа.';

  @override
  String get changePasswordTitle => 'Смена пароля';

  @override
  String get changePasswordCurrent => 'Текущий пароль';

  @override
  String get changePasswordCurrentRequired => 'Введите текущий пароль';

  @override
  String get changePasswordRepeatNew => 'Повторите новый пароль';

  @override
  String get changePasswordButton => 'Сменить пароль';

  @override
  String get changePasswordSuccess => 'Пароль изменён';

  @override
  String get editProfileTitle => 'Редактирование профиля';

  @override
  String get editProfileSaved => 'Профиль обновлён';

  @override
  String get editProfileNewEmailTitle => 'Новый e-mail';

  @override
  String get editProfileEmailChangeSent =>
      'Письмо с подтверждением отправлено на новый адрес';

  @override
  String get editProfileNameLengthError => 'От 2 до 50 символов';

  @override
  String get editProfileChangeEmail => 'Изменить';

  @override
  String get settingsAppearance => 'Оформление';

  @override
  String get settingsThemeLight => 'Светлая тема';

  @override
  String get settingsThemeDark => 'Тёмная тема';

  @override
  String get settingsThemeSystem => 'Системная тема';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsNotificationsLoadError =>
      'Не удалось загрузить настройки уведомлений';

  @override
  String get settingsAccount => 'Аккаунт';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsPushNewReleases => 'Новинки';

  @override
  String get settingsPushOrderStatus => 'Статус заказа';

  @override
  String get settingsPushReviewReplies => 'Ответы на отзывы';

  @override
  String get authEmailConfirmed => 'E-mail подтверждён.';

  @override
  String get exceptionAuthGeneric =>
      'Не удалось выполнить запрос. Проверьте соединение.';

  @override
  String get exceptionFavoritesGeneric =>
      'Не удалось обновить избранное. Проверьте соединение.';

  @override
  String get exceptionCatalogGeneric =>
      'Не удалось загрузить данные. Проверьте соединение.';

  @override
  String get exceptionOrdersGeneric =>
      'Не удалось оформить заказ. Проверьте соединение.';

  @override
  String get exceptionReviewsGeneric =>
      'Не удалось обновить отзыв. Проверьте соединение.';

  @override
  String get exceptionLibraryGeneric =>
      'Не удалось загрузить библиотеку. Проверьте соединение.';

  @override
  String get exceptionReaderGeneric =>
      'Не удалось загрузить файл книги. Проверьте соединение.';

  @override
  String get exceptionCartGeneric =>
      'Не удалось обновить корзину. Проверьте соединение.';

  @override
  String get exceptionBookmarksGeneric =>
      'Не удалось обновить закладки. Проверьте соединение.';

  @override
  String get exceptionPromoGeneric =>
      'Не удалось проверить промокод. Проверьте соединение.';

  @override
  String get exceptionNotificationsGeneric =>
      'Не удалось обновить настройки уведомлений.';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'Английский';
}

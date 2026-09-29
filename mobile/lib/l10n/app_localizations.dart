import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @onboardingSkip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get onboardingStart;

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In ru, this message translates to:
  /// **'Тысячи книг под рукой'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Description.
  ///
  /// In ru, this message translates to:
  /// **'Большой каталог электронных книг всех жанров — от новинок до классики.'**
  String get onboardingSlide1Description;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In ru, this message translates to:
  /// **'Удобная читалка'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Description.
  ///
  /// In ru, this message translates to:
  /// **'Настройте шрифт и тему под себя, добавляйте закладки и ищите нужный отрывок по тексту.'**
  String get onboardingSlide2Description;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In ru, this message translates to:
  /// **'Читайте бесплатный фрагмент'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Description.
  ///
  /// In ru, this message translates to:
  /// **'Перед покупкой можно бесплатно прочитать начало любой книги из каталога.'**
  String get onboardingSlide3Description;

  /// No description provided for @onboardingSlide4Title.
  ///
  /// In ru, this message translates to:
  /// **'Прогресс всегда с вами'**
  String get onboardingSlide4Title;

  /// No description provided for @onboardingSlide4Description.
  ///
  /// In ru, this message translates to:
  /// **'Библиотека купленных книг и прогресс чтения сохраняются на вашем аккаунте.'**
  String get onboardingSlide4Description;

  /// No description provided for @authTabLogin.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get authTabLogin;

  /// No description provided for @authTabRegister.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get authTabRegister;

  /// No description provided for @authEmailInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Введите корректный e-mail'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordLabel.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите пароль'**
  String get authPasswordRequired;

  /// No description provided for @authNameLabel.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get authNameLabel;

  /// No description provided for @authNameLengthError.
  ///
  /// In ru, this message translates to:
  /// **'Имя должно быть от 2 до 50 символов'**
  String get authNameLengthError;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In ru, this message translates to:
  /// **'Минимум 8 символов'**
  String get authPasswordMinLength;

  /// No description provided for @authPasswordNeedsDigit.
  ///
  /// In ru, this message translates to:
  /// **'Пароль должен содержать минимум одну цифру'**
  String get authPasswordNeedsDigit;

  /// No description provided for @authAcceptTermsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Принимаю пользовательское соглашение'**
  String get authAcceptTermsLabel;

  /// No description provided for @authAcceptTermsRequired.
  ///
  /// In ru, this message translates to:
  /// **'Необходимо принять пользовательское соглашение.'**
  String get authAcceptTermsRequired;

  /// No description provided for @authGenericError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить запрос.'**
  String get authGenericError;

  /// No description provided for @authLockoutMessage.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много попыток. Повторите через {seconds} с.'**
  String authLockoutMessage(int seconds);

  /// No description provided for @authLockedButton.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировано ({seconds} с)'**
  String authLockedButton(int seconds);

  /// No description provided for @authLoginButton.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get authLoginButton;

  /// No description provided for @authRegisterButton.
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрироваться'**
  String get authRegisterButton;

  /// No description provided for @authForgotPassword.
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get authForgotPassword;

  /// No description provided for @authResetTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сброс пароля'**
  String get authResetTitle;

  /// No description provided for @authResetInstructions.
  ///
  /// In ru, this message translates to:
  /// **'Укажите e-mail, указанный при регистрации — пришлём ссылку для сброса пароля.'**
  String get authResetInstructions;

  /// No description provided for @authSend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get authSend;

  /// No description provided for @authResetSentMessage.
  ///
  /// In ru, this message translates to:
  /// **'Если такой e-mail зарегистрирован, на него отправлено письмо со ссылкой для сброса пароля. Откройте ссылку из письма на этом устройстве — форма нового пароля откроется автоматически.'**
  String get authResetSentMessage;

  /// No description provided for @authResetManualTokenLink.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка не открылась — ввести токен вручную'**
  String get authResetManualTokenLink;

  /// No description provided for @authNewPassword.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get authNewPassword;

  /// No description provided for @authTokenLabel.
  ///
  /// In ru, this message translates to:
  /// **'Токен из письма'**
  String get authTokenLabel;

  /// No description provided for @authTokenRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите токен'**
  String get authTokenRequired;

  /// No description provided for @authRepeatPasswordLabel.
  ///
  /// In ru, this message translates to:
  /// **'Повторите пароль'**
  String get authRepeatPasswordLabel;

  /// No description provided for @authPasswordsMismatch.
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают'**
  String get authPasswordsMismatch;

  /// No description provided for @authSavePassword.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить пароль'**
  String get authSavePassword;

  /// No description provided for @authPasswordChangedMessage.
  ///
  /// In ru, this message translates to:
  /// **'Пароль изменён. Теперь можно войти.'**
  String get authPasswordChangedMessage;

  /// No description provided for @authContinueAsGuest.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить как гость'**
  String get authContinueAsGuest;

  /// No description provided for @navHome.
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get navHome;

  /// No description provided for @navCatalog.
  ///
  /// In ru, this message translates to:
  /// **'Каталог'**
  String get navCatalog;

  /// No description provided for @navLibrary.
  ///
  /// In ru, this message translates to:
  /// **'Библиотека'**
  String get navLibrary;

  /// No description provided for @navProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get navProfile;

  /// No description provided for @navCart.
  ///
  /// In ru, this message translates to:
  /// **'Корзина'**
  String get navCart;

  /// No description provided for @homeGreeting.
  ///
  /// In ru, this message translates to:
  /// **'Здравствуйте, {name}!'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingGuest.
  ///
  /// In ru, this message translates to:
  /// **'Здравствуйте!'**
  String get homeGreetingGuest;

  /// No description provided for @homeSectionNewest.
  ///
  /// In ru, this message translates to:
  /// **'Новинки'**
  String get homeSectionNewest;

  /// No description provided for @homeSectionTopSellers.
  ///
  /// In ru, this message translates to:
  /// **'Топ продаж'**
  String get homeSectionTopSellers;

  /// No description provided for @homeSectionRecommended.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендуем'**
  String get homeSectionRecommended;

  /// No description provided for @homeSectionGenres.
  ///
  /// In ru, this message translates to:
  /// **'Жанры'**
  String get homeSectionGenres;

  /// No description provided for @notYetAvailableMessage.
  ///
  /// In ru, this message translates to:
  /// **'{feature} появится в одной из следующих фаз.'**
  String notYetAvailableMessage(String feature);

  /// No description provided for @featureBannerLink.
  ///
  /// In ru, this message translates to:
  /// **'Переход по ссылке баннера'**
  String get featureBannerLink;

  /// No description provided for @featureExcerptReading.
  ///
  /// In ru, this message translates to:
  /// **'Чтение фрагмента'**
  String get featureExcerptReading;

  /// No description provided for @commonRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get commonRetry;

  /// No description provided for @catalogSortTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Сортировка'**
  String get catalogSortTooltip;

  /// No description provided for @catalogFiltersTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры'**
  String get catalogFiltersTooltip;

  /// No description provided for @catalogSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Название, автор, ISBN'**
  String get catalogSearchHint;

  /// No description provided for @catalogEmptyResults.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get catalogEmptyResults;

  /// No description provided for @catalogSortDefault.
  ///
  /// In ru, this message translates to:
  /// **'По умолчанию'**
  String get catalogSortDefault;

  /// No description provided for @catalogSortCheapFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала дешёвые'**
  String get catalogSortCheapFirst;

  /// No description provided for @catalogSortExpensiveFirst.
  ///
  /// In ru, this message translates to:
  /// **'Сначала дорогие'**
  String get catalogSortExpensiveFirst;

  /// No description provided for @catalogSortRating.
  ///
  /// In ru, this message translates to:
  /// **'По рейтингу'**
  String get catalogSortRating;

  /// No description provided for @catalogSortNewest.
  ///
  /// In ru, this message translates to:
  /// **'Сначала новинки'**
  String get catalogSortNewest;

  /// No description provided for @filterGenreFallback.
  ///
  /// In ru, this message translates to:
  /// **'Жанр'**
  String get filterGenreFallback;

  /// No description provided for @filterRatingFrom.
  ///
  /// In ru, this message translates to:
  /// **'от {rating}★'**
  String filterRatingFrom(int rating);

  /// No description provided for @filtersReset.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get filtersReset;

  /// No description provided for @filtersApply.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get filtersApply;

  /// No description provided for @filtersGenreLabel.
  ///
  /// In ru, this message translates to:
  /// **'Жанр'**
  String get filtersGenreLabel;

  /// No description provided for @filtersGenresLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить жанры'**
  String get filtersGenresLoadError;

  /// No description provided for @filtersPriceLabel.
  ///
  /// In ru, this message translates to:
  /// **'Цена, ₽'**
  String get filtersPriceLabel;

  /// No description provided for @filtersLanguageLabel.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get filtersLanguageLabel;

  /// No description provided for @filtersLanguagesLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить список языков'**
  String get filtersLanguagesLoadError;

  /// No description provided for @filtersMinRatingLabel.
  ///
  /// In ru, this message translates to:
  /// **'Минимальный рейтинг'**
  String get filtersMinRatingLabel;

  /// No description provided for @cartEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Корзина пуста'**
  String get cartEmpty;

  /// No description provided for @cartRemoveItemTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Удалить из корзины'**
  String get cartRemoveItemTooltip;

  /// No description provided for @cartPromoHint.
  ///
  /// In ru, this message translates to:
  /// **'Промокод'**
  String get cartPromoHint;

  /// No description provided for @cartSubtotal.
  ///
  /// In ru, this message translates to:
  /// **'Сумма товаров'**
  String get cartSubtotal;

  /// No description provided for @cartPromoDiscount.
  ///
  /// In ru, this message translates to:
  /// **'Скидка по промокоду'**
  String get cartPromoDiscount;

  /// No description provided for @cartTotal.
  ///
  /// In ru, this message translates to:
  /// **'Итого'**
  String get cartTotal;

  /// No description provided for @cartCheckoutButton.
  ///
  /// In ru, this message translates to:
  /// **'Оформить заказ'**
  String get cartCheckoutButton;

  /// No description provided for @bookDetailTitle.
  ///
  /// In ru, this message translates to:
  /// **'Книга'**
  String get bookDetailTitle;

  /// No description provided for @bookDetailLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить книгу'**
  String get bookDetailLoadError;

  /// No description provided for @bookDetailNoRatings.
  ///
  /// In ru, this message translates to:
  /// **'Нет оценок'**
  String get bookDetailNoRatings;

  /// No description provided for @bookDetailAlreadyOwned.
  ///
  /// In ru, this message translates to:
  /// **'Уже в вашей библиотеке'**
  String get bookDetailAlreadyOwned;

  /// No description provided for @bookDetailFavorited.
  ///
  /// In ru, this message translates to:
  /// **'В избранном'**
  String get bookDetailFavorited;

  /// No description provided for @bookDetailAddToFavorites.
  ///
  /// In ru, this message translates to:
  /// **'В избранное'**
  String get bookDetailAddToFavorites;

  /// No description provided for @bookDetailAddToCart.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в корзину'**
  String get bookDetailAddToCart;

  /// No description provided for @bookDetailRead.
  ///
  /// In ru, this message translates to:
  /// **'Читать'**
  String get bookDetailRead;

  /// No description provided for @bookDetailReadExcerpt.
  ///
  /// In ru, this message translates to:
  /// **'Читать фрагмент'**
  String get bookDetailReadExcerpt;

  /// No description provided for @bookDetailGenre.
  ///
  /// In ru, this message translates to:
  /// **'Жанр'**
  String get bookDetailGenre;

  /// No description provided for @bookDetailLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get bookDetailLanguage;

  /// No description provided for @bookDetailPublisher.
  ///
  /// In ru, this message translates to:
  /// **'Издательство'**
  String get bookDetailPublisher;

  /// No description provided for @bookDetailPublicationYear.
  ///
  /// In ru, this message translates to:
  /// **'Год издания'**
  String get bookDetailPublicationYear;

  /// No description provided for @bookDetailPageCount.
  ///
  /// In ru, this message translates to:
  /// **'Объём'**
  String get bookDetailPageCount;

  /// No description provided for @bookDetailPages.
  ///
  /// In ru, this message translates to:
  /// **'{count} стр.'**
  String bookDetailPages(int count);

  /// No description provided for @bookDetailDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get bookDetailDescription;

  /// No description provided for @bookDetailReviews.
  ///
  /// In ru, this message translates to:
  /// **'Отзывы'**
  String get bookDetailReviews;

  /// No description provided for @bookDetailAddedToCart.
  ///
  /// In ru, this message translates to:
  /// **'Добавлено в корзину'**
  String get bookDetailAddedToCart;

  /// No description provided for @bookDetailAlreadyInCart.
  ///
  /// In ru, this message translates to:
  /// **'Уже в корзине'**
  String get bookDetailAlreadyInCart;

  /// No description provided for @orderStatusPaid.
  ///
  /// In ru, this message translates to:
  /// **'Оплачен'**
  String get orderStatusPaid;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменён'**
  String get orderStatusCancelled;

  /// No description provided for @orderStatusRefunded.
  ///
  /// In ru, this message translates to:
  /// **'Возврат'**
  String get orderStatusRefunded;

  /// No description provided for @ordersTitle.
  ///
  /// In ru, this message translates to:
  /// **'Мои заказы'**
  String get ordersTitle;

  /// No description provided for @ordersLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить заказы'**
  String get ordersLoadError;

  /// No description provided for @ordersEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Заказов пока нет'**
  String get ordersEmpty;

  /// No description provided for @orderTileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заказ #{id} · {count} книг(и)'**
  String orderTileTitle(int id, int count);

  /// No description provided for @orderDetailTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заказ #{id}'**
  String orderDetailTitle(int id);

  /// No description provided for @orderDetailLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить заказ'**
  String get orderDetailLoadError;

  /// No description provided for @orderItemCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} книг(и)'**
  String orderItemCount(int count);

  /// No description provided for @checkoutTitle.
  ///
  /// In ru, this message translates to:
  /// **'Оформление заказа'**
  String get checkoutTitle;

  /// No description provided for @checkoutYourOrder.
  ///
  /// In ru, this message translates to:
  /// **'Ваш заказ'**
  String get checkoutYourOrder;

  /// No description provided for @checkoutTotalToPay.
  ///
  /// In ru, this message translates to:
  /// **'Итого к оплате'**
  String get checkoutTotalToPay;

  /// No description provided for @checkoutPayment.
  ///
  /// In ru, this message translates to:
  /// **'Оплата'**
  String get checkoutPayment;

  /// No description provided for @checkoutPaymentHint.
  ///
  /// In ru, this message translates to:
  /// **'Тестовые данные, реальная оплата не выполняется. Номер карты 4000 0000 0000 0002 имитирует отказ, любой другой — успех.'**
  String get checkoutPaymentHint;

  /// No description provided for @checkoutCardNumber.
  ///
  /// In ru, this message translates to:
  /// **'Номер карты'**
  String get checkoutCardNumber;

  /// No description provided for @checkoutPayButton.
  ///
  /// In ru, this message translates to:
  /// **'Оплатить'**
  String get checkoutPayButton;

  /// No description provided for @orderSuccessTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заказ оформлен'**
  String get orderSuccessTitle;

  /// No description provided for @orderSuccessMessage.
  ///
  /// In ru, this message translates to:
  /// **'Заказ успешно оформлен'**
  String get orderSuccessMessage;

  /// No description provided for @orderSuccessNumber.
  ///
  /// In ru, this message translates to:
  /// **'Номер заказа: #{id}'**
  String orderSuccessNumber(int id);

  /// No description provided for @orderSuccessGoToLibrary.
  ///
  /// In ru, this message translates to:
  /// **'Перейти в библиотеку'**
  String get orderSuccessGoToLibrary;

  /// No description provided for @commonCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get commonDelete;

  /// No description provided for @libraryRemoveTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить книгу из библиотеки?'**
  String get libraryRemoveTitle;

  /// No description provided for @libraryRemoveMessage.
  ///
  /// In ru, this message translates to:
  /// **'«{title}» будет удалена из «Моей библиотеки» вместе с прогрессом чтения. Это действие нельзя отменить.'**
  String libraryRemoveMessage(String title);

  /// No description provided for @libraryRemoveError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить книгу из библиотеки'**
  String get libraryRemoveError;

  /// No description provided for @libraryLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить библиотеку'**
  String get libraryLoadError;

  /// No description provided for @libraryEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет купленных книг'**
  String get libraryEmpty;

  /// No description provided for @libraryRemoveTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Удалить из библиотеки'**
  String get libraryRemoveTooltip;

  /// No description provided for @libraryNewBadge.
  ///
  /// In ru, this message translates to:
  /// **'Новая'**
  String get libraryNewBadge;

  /// No description provided for @favoritesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get favoritesTitle;

  /// No description provided for @favoritesLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить избранное'**
  String get favoritesLoadError;

  /// No description provided for @favoritesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет книг в избранном'**
  String get favoritesEmpty;

  /// No description provided for @reviewsLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить отзывы: {error}'**
  String reviewsLoadError(String error);

  /// No description provided for @reviewsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Отзывов пока нет.'**
  String get reviewsEmpty;

  /// No description provided for @reviewsShowMore.
  ///
  /// In ru, this message translates to:
  /// **'Показать ещё'**
  String get reviewsShowMore;

  /// No description provided for @reviewsPurchaseRequired.
  ///
  /// In ru, this message translates to:
  /// **'Оставить отзыв можно после покупки книги.'**
  String get reviewsPurchaseRequired;

  /// No description provided for @reviewSelectRating.
  ///
  /// In ru, this message translates to:
  /// **'Выберите оценку от 1 до 5 звёзд'**
  String get reviewSelectRating;

  /// No description provided for @reviewTextTooShort.
  ///
  /// In ru, this message translates to:
  /// **'Текст отзыва должен быть не короче {minLength} символов'**
  String reviewTextTooShort(int minLength);

  /// No description provided for @reviewSaved.
  ///
  /// In ru, this message translates to:
  /// **'Отзыв сохранён'**
  String get reviewSaved;

  /// No description provided for @reviewDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить отзыв?'**
  String get reviewDeleteTitle;

  /// No description provided for @reviewDeleteMessage.
  ///
  /// In ru, this message translates to:
  /// **'Отзыв будет удалён без возможности восстановления.'**
  String get reviewDeleteMessage;

  /// No description provided for @reviewLeaveTitle.
  ///
  /// In ru, this message translates to:
  /// **'Оставить отзыв'**
  String get reviewLeaveTitle;

  /// No description provided for @reviewYourTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ваш отзыв'**
  String get reviewYourTitle;

  /// No description provided for @reviewTextHint.
  ///
  /// In ru, this message translates to:
  /// **'Расскажите о впечатлениях от книги (необязательно, от 10 символов)'**
  String get reviewTextHint;

  /// No description provided for @reviewSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get reviewSave;

  /// No description provided for @readerFormatUnsupported.
  ///
  /// In ru, this message translates to:
  /// **'Формат не поддерживается'**
  String get readerFormatUnsupported;

  /// No description provided for @readerTocUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Оглавление недоступно'**
  String get readerTocUnavailable;

  /// No description provided for @readerSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по тексту книги'**
  String get readerSearchHint;

  /// No description provided for @readerBookmarksTitle.
  ///
  /// In ru, this message translates to:
  /// **'Закладки'**
  String get readerBookmarksTitle;

  /// No description provided for @readerBookmarkAddHere.
  ///
  /// In ru, this message translates to:
  /// **'На этой странице'**
  String get readerBookmarkAddHere;

  /// No description provided for @readerBookmarksLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить закладки'**
  String get readerBookmarksLoadError;

  /// No description provided for @readerBookmarksEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Закладок пока нет'**
  String get readerBookmarksEmpty;

  /// No description provided for @readerBookmarkTitle.
  ///
  /// In ru, this message translates to:
  /// **'Закладка {index}'**
  String readerBookmarkTitle(int index);

  /// No description provided for @readerFontSize.
  ///
  /// In ru, this message translates to:
  /// **'Размер шрифта'**
  String get readerFontSize;

  /// No description provided for @readerTheme.
  ///
  /// In ru, this message translates to:
  /// **'Тема чтения'**
  String get readerTheme;

  /// No description provided for @readerThemeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get readerThemeLight;

  /// No description provided for @readerThemeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get readerThemeDark;

  /// No description provided for @readerThemeSepia.
  ///
  /// In ru, this message translates to:
  /// **'Сепия'**
  String get readerThemeSepia;

  /// No description provided for @readerContinuousScroll.
  ///
  /// In ru, this message translates to:
  /// **'Непрерывная прокрутка'**
  String get readerContinuousScroll;

  /// No description provided for @readerSearchTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по тексту'**
  String get readerSearchTooltip;

  /// No description provided for @readerTocTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Оглавление'**
  String get readerTocTooltip;

  /// No description provided for @readerSettingsTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Настройки чтения'**
  String get readerSettingsTooltip;

  /// No description provided for @readerFileLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить файл книги'**
  String get readerFileLoadError;

  /// No description provided for @profileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profileTitle;

  /// No description provided for @profileEdit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить профиль'**
  String get profileEdit;

  /// No description provided for @profileSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get profileSettings;

  /// No description provided for @profileLogout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get profileLogout;

  /// No description provided for @profileLogoutTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из аккаунта?'**
  String get profileLogoutTitle;

  /// No description provided for @profileLogoutMessage.
  ///
  /// In ru, this message translates to:
  /// **'Понадобится снова ввести e-mail и пароль для входа.'**
  String get profileLogoutMessage;

  /// No description provided for @changePasswordTitle.
  ///
  /// In ru, this message translates to:
  /// **'Смена пароля'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordCurrent.
  ///
  /// In ru, this message translates to:
  /// **'Текущий пароль'**
  String get changePasswordCurrent;

  /// No description provided for @changePasswordCurrentRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите текущий пароль'**
  String get changePasswordCurrentRequired;

  /// No description provided for @changePasswordRepeatNew.
  ///
  /// In ru, this message translates to:
  /// **'Повторите новый пароль'**
  String get changePasswordRepeatNew;

  /// No description provided for @changePasswordButton.
  ///
  /// In ru, this message translates to:
  /// **'Сменить пароль'**
  String get changePasswordButton;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Пароль изменён'**
  String get changePasswordSuccess;

  /// No description provided for @editProfileTitle.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование профиля'**
  String get editProfileTitle;

  /// No description provided for @editProfileSaved.
  ///
  /// In ru, this message translates to:
  /// **'Профиль обновлён'**
  String get editProfileSaved;

  /// No description provided for @editProfileNewEmailTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новый e-mail'**
  String get editProfileNewEmailTitle;

  /// No description provided for @editProfileEmailChangeSent.
  ///
  /// In ru, this message translates to:
  /// **'Письмо с подтверждением отправлено на новый адрес'**
  String get editProfileEmailChangeSent;

  /// No description provided for @editProfileNameLengthError.
  ///
  /// In ru, this message translates to:
  /// **'От 2 до 50 символов'**
  String get editProfileNameLengthError;

  /// No description provided for @editProfileChangeEmail.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get editProfileChangeEmail;

  /// No description provided for @settingsAppearance.
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая тема'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная тема'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In ru, this message translates to:
  /// **'Системная тема'**
  String get settingsThemeSystem;

  /// No description provided for @settingsNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить настройки уведомлений'**
  String get settingsNotificationsLoadError;

  /// No description provided for @settingsAccount.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get settingsAccount;

  /// No description provided for @settingsLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get settingsLanguage;

  /// No description provided for @settingsPushNewReleases.
  ///
  /// In ru, this message translates to:
  /// **'Новинки'**
  String get settingsPushNewReleases;

  /// No description provided for @settingsPushOrderStatus.
  ///
  /// In ru, this message translates to:
  /// **'Статус заказа'**
  String get settingsPushOrderStatus;

  /// No description provided for @settingsPushReviewReplies.
  ///
  /// In ru, this message translates to:
  /// **'Ответы на отзывы'**
  String get settingsPushReviewReplies;

  /// No description provided for @authEmailConfirmed.
  ///
  /// In ru, this message translates to:
  /// **'E-mail подтверждён.'**
  String get authEmailConfirmed;

  /// No description provided for @exceptionAuthGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить запрос. Проверьте соединение.'**
  String get exceptionAuthGeneric;

  /// No description provided for @exceptionFavoritesGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить избранное. Проверьте соединение.'**
  String get exceptionFavoritesGeneric;

  /// No description provided for @exceptionCatalogGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить данные. Проверьте соединение.'**
  String get exceptionCatalogGeneric;

  /// No description provided for @exceptionOrdersGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось оформить заказ. Проверьте соединение.'**
  String get exceptionOrdersGeneric;

  /// No description provided for @exceptionReviewsGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить отзыв. Проверьте соединение.'**
  String get exceptionReviewsGeneric;

  /// No description provided for @exceptionLibraryGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить библиотеку. Проверьте соединение.'**
  String get exceptionLibraryGeneric;

  /// No description provided for @exceptionReaderGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить файл книги. Проверьте соединение.'**
  String get exceptionReaderGeneric;

  /// No description provided for @exceptionCartGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить корзину. Проверьте соединение.'**
  String get exceptionCartGeneric;

  /// No description provided for @exceptionBookmarksGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить закладки. Проверьте соединение.'**
  String get exceptionBookmarksGeneric;

  /// No description provided for @exceptionPromoGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось проверить промокод. Проверьте соединение.'**
  String get exceptionPromoGeneric;

  /// No description provided for @exceptionNotificationsGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить настройки уведомлений.'**
  String get exceptionNotificationsGeneric;

  /// No description provided for @languageRussian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageEnglish.
  ///
  /// In ru, this message translates to:
  /// **'Английский'**
  String get languageEnglish;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get started';

  @override
  String get onboardingSlide1Title => 'Thousands of books at hand';

  @override
  String get onboardingSlide1Description =>
      'A large catalog of e-books in every genre — from new releases to classics.';

  @override
  String get onboardingSlide2Title => 'A comfortable reader';

  @override
  String get onboardingSlide2Description =>
      'Customize font and theme, add bookmarks, and search within the text.';

  @override
  String get onboardingSlide3Title => 'Read a free sample';

  @override
  String get onboardingSlide3Description =>
      'Read the beginning of any book in the catalog for free before buying.';

  @override
  String get onboardingSlide4Title => 'Your progress travels with you';

  @override
  String get onboardingSlide4Description =>
      'Your purchased library and reading progress are saved to your account.';

  @override
  String get authTabLogin => 'Log in';

  @override
  String get authTabRegister => 'Register';

  @override
  String get authEmailInvalid => 'Enter a valid e-mail';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordRequired => 'Enter your password';

  @override
  String get authNameLabel => 'Name';

  @override
  String get authNameLengthError => 'Name must be 2 to 50 characters';

  @override
  String get authPasswordMinLength => 'At least 8 characters';

  @override
  String get authPasswordNeedsDigit =>
      'Password must contain at least one digit';

  @override
  String get authAcceptTermsLabel => 'I accept the terms of service';

  @override
  String get authAcceptTermsRequired => 'You must accept the terms of service.';

  @override
  String get authGenericError => 'Could not complete the request.';

  @override
  String authLockoutMessage(int seconds) {
    return 'Too many attempts. Try again in ${seconds}s.';
  }

  @override
  String authLockedButton(int seconds) {
    return 'Locked (${seconds}s)';
  }

  @override
  String get authLoginButton => 'Log in';

  @override
  String get authRegisterButton => 'Register';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authResetTitle => 'Password reset';

  @override
  String get authResetInstructions =>
      'Enter the e-mail you registered with — we\'ll send a password reset link.';

  @override
  String get authSend => 'Send';

  @override
  String get authResetSentMessage =>
      'If that e-mail is registered, we\'ve sent a password reset link to it. Open the link from that e-mail on this device — the new password form will open automatically.';

  @override
  String get authResetManualTokenLink =>
      'Link didn\'t open — enter the token manually';

  @override
  String get authNewPassword => 'New password';

  @override
  String get authTokenLabel => 'Token from the e-mail';

  @override
  String get authTokenRequired => 'Enter the token';

  @override
  String get authRepeatPasswordLabel => 'Repeat password';

  @override
  String get authPasswordsMismatch => 'Passwords do not match';

  @override
  String get authSavePassword => 'Save password';

  @override
  String get authPasswordChangedMessage =>
      'Password changed. You can now log in.';

  @override
  String get authContinueAsGuest => 'Continue as guest';

  @override
  String get navHome => 'Home';

  @override
  String get navCatalog => 'Catalog';

  @override
  String get navLibrary => 'Library';

  @override
  String get navProfile => 'Profile';

  @override
  String get navCart => 'Cart';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name!';
  }

  @override
  String get homeGreetingGuest => 'Hello!';

  @override
  String get homeSectionNewest => 'New releases';

  @override
  String get homeSectionTopSellers => 'Bestsellers';

  @override
  String get homeSectionRecommended => 'Recommended';

  @override
  String get homeSectionGenres => 'Genres';

  @override
  String notYetAvailableMessage(String feature) {
    return '$feature will be available in a future release.';
  }

  @override
  String get featureBannerLink => 'Following a banner link';

  @override
  String get featureExcerptReading => 'Sample reading';

  @override
  String get commonRetry => 'Retry';

  @override
  String get catalogSortTooltip => 'Sort';

  @override
  String get catalogFiltersTooltip => 'Filters';

  @override
  String get catalogSearchHint => 'Title, author, ISBN';

  @override
  String get catalogEmptyResults => 'Nothing found';

  @override
  String get catalogSortDefault => 'Default';

  @override
  String get catalogSortCheapFirst => 'Price: low to high';

  @override
  String get catalogSortExpensiveFirst => 'Price: high to low';

  @override
  String get catalogSortRating => 'Top rated';

  @override
  String get catalogSortNewest => 'Newest first';

  @override
  String get filterGenreFallback => 'Genre';

  @override
  String filterRatingFrom(int rating) {
    return 'from $rating★';
  }

  @override
  String get filtersReset => 'Reset';

  @override
  String get filtersApply => 'Apply';

  @override
  String get filtersGenreLabel => 'Genre';

  @override
  String get filtersGenresLoadError => 'Couldn\'t load genres';

  @override
  String get filtersPriceLabel => 'Price, ₽';

  @override
  String get filtersLanguageLabel => 'Language';

  @override
  String get filtersLanguagesLoadError => 'Couldn\'t load the language list';

  @override
  String get filtersMinRatingLabel => 'Minimum rating';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartRemoveItemTooltip => 'Remove from cart';

  @override
  String get cartPromoHint => 'Promo code';

  @override
  String get cartSubtotal => 'Subtotal';

  @override
  String get cartPromoDiscount => 'Promo discount';

  @override
  String get cartTotal => 'Total';

  @override
  String get cartCheckoutButton => 'Check out';

  @override
  String get bookDetailTitle => 'Book';

  @override
  String get bookDetailLoadError => 'Couldn\'t load the book';

  @override
  String get bookDetailNoRatings => 'No ratings yet';

  @override
  String get bookDetailAlreadyOwned => 'Already in your library';

  @override
  String get bookDetailFavorited => 'In favorites';

  @override
  String get bookDetailAddToFavorites => 'Add to favorites';

  @override
  String get bookDetailAddToCart => 'Add to cart';

  @override
  String get bookDetailRead => 'Read';

  @override
  String get bookDetailReadExcerpt => 'Read a sample';

  @override
  String get bookDetailGenre => 'Genre';

  @override
  String get bookDetailLanguage => 'Language';

  @override
  String get bookDetailPublisher => 'Publisher';

  @override
  String get bookDetailPublicationYear => 'Publication year';

  @override
  String get bookDetailPageCount => 'Length';

  @override
  String bookDetailPages(int count) {
    return '$count pages';
  }

  @override
  String get bookDetailDescription => 'Description';

  @override
  String get bookDetailReviews => 'Reviews';

  @override
  String get bookDetailAddedToCart => 'Added to cart';

  @override
  String get bookDetailAlreadyInCart => 'Already in cart';

  @override
  String get orderStatusPaid => 'Paid';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get orderStatusRefunded => 'Refunded';

  @override
  String get ordersTitle => 'My orders';

  @override
  String get ordersLoadError => 'Couldn\'t load orders';

  @override
  String get ordersEmpty => 'No orders yet';

  @override
  String orderTileTitle(int id, int count) {
    return 'Order #$id · $count book(s)';
  }

  @override
  String orderDetailTitle(int id) {
    return 'Order #$id';
  }

  @override
  String get orderDetailLoadError => 'Couldn\'t load the order';

  @override
  String orderItemCount(int count) {
    return '$count book(s)';
  }

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get checkoutYourOrder => 'Your order';

  @override
  String get checkoutTotalToPay => 'Total to pay';

  @override
  String get checkoutPayment => 'Payment';

  @override
  String get checkoutPaymentHint =>
      'Test data only, no real payment is processed. Card number 4000 0000 0000 0002 simulates a decline, any other number succeeds.';

  @override
  String get checkoutCardNumber => 'Card number';

  @override
  String get checkoutPayButton => 'Pay';

  @override
  String get orderSuccessTitle => 'Order placed';

  @override
  String get orderSuccessMessage => 'Your order was placed successfully';

  @override
  String orderSuccessNumber(int id) {
    return 'Order number: #$id';
  }

  @override
  String get orderSuccessGoToLibrary => 'Go to library';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get libraryRemoveTitle => 'Remove book from library?';

  @override
  String libraryRemoveMessage(String title) {
    return '\"$title\" will be removed from \"My library\" along with its reading progress. This can\'t be undone.';
  }

  @override
  String get libraryRemoveError => 'Couldn\'t remove the book from the library';

  @override
  String get libraryLoadError => 'Couldn\'t load the library';

  @override
  String get libraryEmpty => 'No purchased books yet';

  @override
  String get libraryRemoveTooltip => 'Remove from library';

  @override
  String get libraryNewBadge => 'New';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesLoadError => 'Couldn\'t load favorites';

  @override
  String get favoritesEmpty => 'No favorite books yet';

  @override
  String reviewsLoadError(String error) {
    return 'Couldn\'t load reviews: $error';
  }

  @override
  String get reviewsEmpty => 'No reviews yet.';

  @override
  String get reviewsShowMore => 'Show more';

  @override
  String get reviewsPurchaseRequired =>
      'You can leave a review after buying the book.';

  @override
  String get reviewSelectRating => 'Select a rating from 1 to 5 stars';

  @override
  String reviewTextTooShort(int minLength) {
    return 'The review text must be at least $minLength characters';
  }

  @override
  String get reviewSaved => 'Review saved';

  @override
  String get reviewDeleteTitle => 'Delete review?';

  @override
  String get reviewDeleteMessage =>
      'The review will be deleted and can\'t be recovered.';

  @override
  String get reviewLeaveTitle => 'Leave a review';

  @override
  String get reviewYourTitle => 'Your review';

  @override
  String get reviewTextHint =>
      'Share your thoughts about the book (optional, at least 10 characters)';

  @override
  String get reviewSave => 'Save';

  @override
  String get readerFormatUnsupported => 'Format not supported';

  @override
  String get readerTocUnavailable => 'Table of contents unavailable';

  @override
  String get readerSearchHint => 'Search within the book';

  @override
  String get readerBookmarksTitle => 'Bookmarks';

  @override
  String get readerBookmarkAddHere => 'On this page';

  @override
  String get readerBookmarksLoadError => 'Couldn\'t load bookmarks';

  @override
  String get readerBookmarksEmpty => 'No bookmarks yet';

  @override
  String readerBookmarkTitle(int index) {
    return 'Bookmark $index';
  }

  @override
  String get readerFontSize => 'Font size';

  @override
  String get readerTheme => 'Reading theme';

  @override
  String get readerThemeLight => 'Light';

  @override
  String get readerThemeDark => 'Dark';

  @override
  String get readerThemeSepia => 'Sepia';

  @override
  String get readerContinuousScroll => 'Continuous scroll';

  @override
  String get readerSearchTooltip => 'Search text';

  @override
  String get readerTocTooltip => 'Table of contents';

  @override
  String get readerSettingsTooltip => 'Reading settings';

  @override
  String get readerFileLoadError => 'Couldn\'t load the book file';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileLogout => 'Log out';

  @override
  String get profileLogoutTitle => 'Log out of your account?';

  @override
  String get profileLogoutMessage =>
      'You\'ll need to enter your e-mail and password again to sign in.';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordCurrent => 'Current password';

  @override
  String get changePasswordCurrentRequired => 'Enter your current password';

  @override
  String get changePasswordRepeatNew => 'Repeat new password';

  @override
  String get changePasswordButton => 'Change password';

  @override
  String get changePasswordSuccess => 'Password changed';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfileSaved => 'Profile updated';

  @override
  String get editProfileNewEmailTitle => 'New e-mail';

  @override
  String get editProfileEmailChangeSent =>
      'A confirmation e-mail was sent to the new address';

  @override
  String get editProfileNameLengthError => '2 to 50 characters';

  @override
  String get editProfileChangeEmail => 'Change';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeLight => 'Light theme';

  @override
  String get settingsThemeDark => 'Dark theme';

  @override
  String get settingsThemeSystem => 'System theme';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsLoadError =>
      'Couldn\'t load notification settings';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsPushNewReleases => 'New releases';

  @override
  String get settingsPushOrderStatus => 'Order status';

  @override
  String get settingsPushReviewReplies => 'Review replies';

  @override
  String get authEmailConfirmed => 'E-mail confirmed.';

  @override
  String get exceptionAuthGeneric =>
      'Couldn\'t complete the request. Check your connection.';

  @override
  String get exceptionFavoritesGeneric =>
      'Couldn\'t update favorites. Check your connection.';

  @override
  String get exceptionCatalogGeneric =>
      'Couldn\'t load the data. Check your connection.';

  @override
  String get exceptionOrdersGeneric =>
      'Couldn\'t place the order. Check your connection.';

  @override
  String get exceptionReviewsGeneric =>
      'Couldn\'t update the review. Check your connection.';

  @override
  String get exceptionLibraryGeneric =>
      'Couldn\'t load the library. Check your connection.';

  @override
  String get exceptionReaderGeneric =>
      'Couldn\'t load the book file. Check your connection.';

  @override
  String get exceptionCartGeneric =>
      'Couldn\'t update the cart. Check your connection.';

  @override
  String get exceptionBookmarksGeneric =>
      'Couldn\'t update bookmarks. Check your connection.';

  @override
  String get exceptionPromoGeneric =>
      'Couldn\'t check the promo code. Check your connection.';

  @override
  String get exceptionNotificationsGeneric =>
      'Couldn\'t update notification settings.';

  @override
  String get languageRussian => 'Russian';

  @override
  String get languageEnglish => 'English';
}

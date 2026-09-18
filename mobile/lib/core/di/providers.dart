import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/auth_api.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/cart/data/cart_api.dart';
import '../../features/catalog/data/catalog_api.dart';
import '../../features/favorites/data/favorites_api.dart';
import '../../features/home/data/banners_api.dart';
import '../../features/library/data/library_api.dart';
import '../../features/notifications/data/notifications_api.dart';
import '../../features/orders/data/orders_api.dart';
import '../../features/promo/data/promo_api.dart';
import '../../features/reader/data/bookmarks_api.dart';
import '../../features/reader/data/reader_api.dart';
import '../../features/reviews/data/reviews_api.dart';
import '../api/api_client.dart';
import '../api/auth_interceptor.dart';
import '../storage/local_storage.dart';

final secureSessionStorageProvider = Provider<SecureSessionStorage>(
  (ref) => const SecureSessionStorage(FlutterSecureStorage()),
);

final apiClientProvider = Provider<Dio>((ref) {
  final dio = buildApiClient();
  final storage = ref.watch(secureSessionStorageProvider);
  dio.interceptors.add(AuthInterceptor(dio: dio, storage: storage));
  return dio;
});

final appPreferencesProvider = FutureProvider<AppPreferences>(
  (ref) => AppPreferences.create(),
);

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    api: ref.watch(authApiProvider),
    storage: ref.watch(secureSessionStorageProvider),
  ),
);

final catalogApiProvider = Provider<CatalogApi>(
  (ref) => CatalogApi(ref.watch(apiClientProvider)),
);

final bannersApiProvider = Provider<BannersApi>(
  (ref) => BannersApi(ref.watch(apiClientProvider)),
);

final favoritesApiProvider = Provider<FavoritesApi>(
  (ref) => FavoritesApi(ref.watch(apiClientProvider)),
);

final cartApiProvider = Provider<CartApi>(
  (ref) => CartApi(ref.watch(apiClientProvider)),
);

final promoApiProvider = Provider<PromoApi>(
  (ref) => PromoApi(ref.watch(apiClientProvider)),
);

final ordersApiProvider = Provider<OrdersApi>(
  (ref) => OrdersApi(ref.watch(apiClientProvider)),
);

final libraryApiProvider = Provider<LibraryApi>(
  (ref) => LibraryApi(ref.watch(apiClientProvider)),
);

final bookmarksApiProvider = Provider<BookmarksApi>(
  (ref) => BookmarksApi(ref.watch(apiClientProvider)),
);

final readerApiProvider = Provider<ReaderApi>(
  (ref) => ReaderApi(ref.watch(apiClientProvider)),
);

final reviewsApiProvider = Provider<ReviewsApi>(
  (ref) => ReviewsApi(ref.watch(apiClientProvider)),
);

final notificationsApiProvider = Provider<NotificationsApi>(
  (ref) => NotificationsApi(ref.watch(apiClientProvider)),
);

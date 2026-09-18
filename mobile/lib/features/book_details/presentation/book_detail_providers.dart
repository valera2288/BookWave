import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../catalog/domain/book_detail.dart';

final bookDetailProvider = FutureProvider.family<BookDetail, int>(
  (ref, bookId) => ref.watch(catalogApiProvider).fetchBook(bookId),
);

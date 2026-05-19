import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../models/pocket.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/notification.dart';
import '../models/api_response.dart';
import 'auth_provider.dart';

class BaseUrlNotifier extends Notifier<String> {
  final String? _initialValue;
  BaseUrlNotifier([this._initialValue]);

  @override
  String build() => _initialValue ?? ApiService.defaultBaseUrl;

  void setBaseUrl(String url) {
    state = url;
  }
}

/// Holds the current API base URL. Defaults to ApiService.defaultBaseUrl.
/// Updated by SettingsScreen after loading from SharedPreferences.
final baseUrlProvider = NotifierProvider<BaseUrlNotifier, String>(
  () => BaseUrlNotifier(),
);

/// ApiService provider — rebuilds whenever baseUrlProvider or authProvider token changes.
final apiServiceProvider = Provider<ApiService>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  final authState = ref.watch(authProvider);
  return ApiService(baseUrl: baseUrl, token: authState.token);
});

class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final navigationIndexProvider = NotifierProvider<NavigationIndexNotifier, int>(
  () => NavigationIndexNotifier(),
);

final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  final hasPermission = await NotificationsListener.hasPermission ?? false;
  if (hasPermission) {
    await NotificationService().init();
  }
  return hasPermission;
});

final pocketsProvider = FutureProvider<PaginationResponse<Pocket>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getPockets();
});

final categoriesProvider = FutureProvider<PaginationResponse<Category>>((
  ref,
) async {
  final api = ref.watch(apiServiceProvider);
  return api.getCategories();
});

final transactionsProvider = FutureProvider<PaginationResponse<Transaction>>((
  ref,
) async {
  final api = ref.watch(apiServiceProvider);
  return api.getTransactions(limit: 20);
});

final notificationEventProvider = StreamProvider<Map>((ref) {
  return NotificationService().notificationStream;
});

final unresolvedNotificationsProvider =
    FutureProvider<PaginationResponse<AppNotification>>((ref) async {
      // Watch the notification stream so this provider refetches automatically
      ref.watch(notificationEventProvider);

      final api = ref.watch(apiServiceProvider);
      return api.getUnresolvedNotifications();
    });

class LocalResolvedNotifications extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final set = <String>{};
    _load();
    return set;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('local_resolved_notifications') ?? [];
    state = list.toSet();
  }

  Future<void> add(String id) async {
    state = {...state, id};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('local_resolved_notifications', state.toList());
  }
}

final localResolvedNotificationsProvider =
    NotifierProvider<LocalResolvedNotifications, Set<String>>(() {
      return LocalResolvedNotifications();
    });

final transactionDetailProvider = FutureProvider.family<Transaction, String>((
  ref,
  id,
) async {
  final api = ref.watch(apiServiceProvider);
  return api.getTransaction(id);
});


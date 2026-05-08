import 'dart:async';
import 'package:burgess_go/features/trade_contact/models/trade_contact.dart';
import 'package:burgess_go/features/trade_contact/repositories/trade_contact_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:burgess_go/features/auth/controllers/auth_controller.dart';

final tradeContactControllerProvider =
    NotifierProvider.autoDispose<
      TradeContactController,
      AsyncValue<List<TradeContact>>
    >(TradeContactController.new);

class TradeContactController extends Notifier<AsyncValue<List<TradeContact>>> {
  StreamSubscription? _subscription;

  @override
  AsyncValue<List<TradeContact>> build() {
    ref.onDispose(() => _subscription?.cancel());

    // Fetch immediately on boot
    Future.microtask(_init);
    return const AsyncValue.loading();
  }

  void _init() {
    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      state = const AsyncValue.data([]);
      return;
    }

    final repo = ref.read(tradeContactRepositoryProvider);
    _subscription = repo
        .watchContacts(user.securityUserId)
        .listen(
          (contacts) {
            state = AsyncValue.data(contacts);
          },
          onError: (err, stack) {
            state = AsyncValue.error(err, stack);
          },
        );
  }

  Future<void> addContact(
    String name,
    String trade,
    String? phone,
    String? email,
  ) async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    final contact = TradeContact(
      name: name,
      trade: trade,
      phone: phone,
      email: email,
      ownerId: user.securityUserId,
    );

    try {
      await ref
          .read(tradeContactRepositoryProvider)
          .addContact(user.securityUserId, contact);
      // We don't need to manually update state because the Stream catches it automatically!
    } catch (e) {
      print("Error adding contact: $e");
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_go/data/mechanic_account_store.dart';
import 'package:on_go/data/mechanic_notification_store.dart';
import 'package:on_go/data/points_offers.dart';
import 'package:on_go/data/points_wallet_store.dart';
import 'package:on_go/data/quote_store.dart';
import 'package:on_go/screens/auth/mechanic_ui/earning/earning_screen.dart';
import 'package:on_go/screens/auth/mechanic_ui/earning/points_offers_screen.dart';
import 'package:on_go/screens/auth/mechanic_ui/mechanic_home_screen.dart';
import 'package:on_go/services/backend/mobile_backend.dart';
import 'package:on_go/theme/app_theme.dart';

import 'responsive_layout_test.dart' show app;

/// Converting points to balance moves both figures everywhere they are shown —
/// in particular on the Earnings tab, which stays alive behind View Offer and
/// used to keep showing the numbers from before the conversion.

const _sizes = <String, Size>{
  'phone': Size(390, 844),
  'tablet': Size(834, 1112),
};

const double _seeded = 120;
const double _converted = 50;

String get _me => QuoteNotificationStore.currentMechanicName;

String _balanceText(double pesos) => '₱${pesos.toStringAsFixed(2)}';

void _seedPoints() {
  PointsWalletStore.instance.credit(
    owner: _me,
    kind: PointsEntryKind.mechanicJobCompleted,
    points: _seeded,
    note: 'seed',
  );
}

void _ignorePluginErrors() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    final e = details.exception;
    if (e is MissingPluginException || e is PlatformException) return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

/// A tab in the mechanic shell's bottom bar, by its icon — the bar prints a
/// label only under the selected tab, so a label is not always there to tap.
Finder _navItem(IconData icon) =>
    find.descendant(of: find.byType(OnGoBottomNav), matching: find.byIcon(icon));

void main() {
  setUp(() {
    QuoteNotificationStore.instance.clear();
    MechanicNotificationStore.instance.clear();
    PointsWalletStore.instance.clear();
    MechanicAccountStore.instance.enterDemoMode();
  });

  group('one shared state', () {
    test('a conversion takes the points and adds the balance, at the existing rate', () {
      _seedPoints();
      final store = QuoteNotificationStore.instance;
      final wallet = PointsWalletStore.instance;
      final balanceBefore = store.availableBalanceFor(_me);

      expect(const ConvertPointsToBalanceOffer().redeem(_me, points: _converted), isNull);

      expect(wallet.balanceFor(_me), _seeded - _converted);
      expect(store.availableBalanceFor(_me), balanceBefore + pesosForPoints(_converted));
      expect(wallet.convertedPesosFor(_me), pesosForPoints(_converted));
    });

    test('the balance still includes what jobs paid', () {
      _seedPoints();
      final store = QuoteNotificationStore.instance;
      const ConvertPointsToBalanceOffer().redeem(_me, points: _converted);

      expect(store.availableBalanceFor(_me),
          store.totalEarningsFor(_me) + pesosForPoints(_converted));
    });
  });

  for (final entry in _sizes.entries) {
    group('on a ${entry.key}', () {
      final size = entry.value;

      testWidgets('Earnings updates the moment points are converted', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        _seedPoints();
        await tester.pumpWidget(app(size, const EarningScreen()));
        await tester.pumpAndSettle();

        expect(find.text(formatPoints(_seeded)), findsOneWidget);
        expect(find.text(_balanceText(0)), findsOneWidget);

        // Converted somewhere else — the screen is not rebuilt by anyone.
        const ConvertPointsToBalanceOffer().redeem(_me, points: _converted);
        await tester.pump();

        expect(find.text(formatPoints(_seeded - _converted)), findsOneWidget);
        expect(find.text(_balanceText(pesosForPoints(_converted))), findsOneWidget);
        expect(find.text(formatPoints(_seeded)), findsNothing);
      });

      testWidgets('converting on View Offer and going back shows the new values on Earnings',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        _ignorePluginErrors();

        _seedPoints();
        await tester.pumpWidget(app(size, const MechanicHomeScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Earnings tab.
        await tester.tap(_navItem(Icons.payments_outlined));
        await tester.pumpAndSettle();
        expect(find.text(formatPoints(_seeded)), findsOneWidget);

        // View Offer → convert 50.
        await tester.tap(find.text('View Offer'));
        await tester.pumpAndSettle();
        expect(find.byType(PointsOffersScreen), findsOneWidget);

        await tester.tap(find.text('Use points'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), formatPoints(_converted));
        await tester.tap(find.text('Convert'));
        await tester.pumpAndSettle();

        // View Offer reflects it...
        expect(find.textContaining(formatPoints(_seeded - _converted)), findsWidgets);

        // ...and so does Earnings, straight back, with no refresh.
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(PointsOffersScreen), findsNothing);
        expect(find.text(formatPoints(_seeded - _converted)), findsOneWidget);
        expect(find.text(_balanceText(pesosForPoints(_converted))), findsOneWidget);

        // Moving between tabs does not reset it. The "done" SnackBar from the
        // conversion sits over the bottom bar for a few seconds, exactly as it
        // would for someone using the app — wait it out before reaching for a
        // tab under it.
        await tester.pump(const Duration(seconds: 10));
        await tester.pumpAndSettle();
        await tester.tap(_navItem(Icons.work_outline));
        await tester.pumpAndSettle();
        await tester.tap(_navItem(Icons.payments_outlined));
        await tester.pumpAndSettle();
        expect(find.text(formatPoints(_seeded - _converted)), findsOneWidget);
        expect(find.text(_balanceText(pesosForPoints(_converted))), findsOneWidget);

        // And opening View Offer again starts from the converted figure.
        await tester.tap(find.text('View Offer'));
        await tester.pumpAndSettle();
        expect(find.textContaining(formatPoints(_seeded - _converted)), findsWidgets);
        expect(find.textContaining(formatPoints(_seeded)), findsNothing);
      });
    });
  }
}

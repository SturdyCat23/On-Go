import 'points_wallet_store.dart';
import '../services/backend/mobile_backend.dart';

/// Something a mechanic can do with their points.
///
/// The View Offer screen renders whatever [PointsOffers.forMechanic] returns
/// and knows nothing about any particular offer, so adding one — a payout
/// bonus, a subscription, a voucher — means adding a [PointsOffer] here and
/// nothing else. The screen, the affordability check and the confirmation all
/// come for free.
abstract class PointsOffer {
  const PointsOffer();

  /// Stable key, for anything that needs to name this offer later.
  String get id;

  String get title;

  String get description;

  /// What this costs right now, in points. An offer with no fixed price —
  /// "convert any amount" — reports the minimum it will accept.
  double costFor(String mechanicName);

  /// What the mechanic gets, in words, for the amount they hold.
  String rewardFor(String mechanicName);

  /// Whether it can be taken right now.
  bool availableFor(String mechanicName) =>
      PointsWalletStore.instance.canAfford(mechanicName, costFor(mechanicName));

  /// Why it cannot be taken, when [availableFor] is false.
  String unavailableReason(String mechanicName) =>
      'You need at least ${formatPointsLabel(costFor(mechanicName))}.';

  /// Takes the offer. Returns null on success, or a message explaining why
  /// it did not go through.
  String? redeem(String mechanicName, {double? points});

  /// Whether the mechanic chooses how many points to spend. The screen shows
  /// an amount field for these and a single confirm for the rest.
  bool get takesAmount => false;
}

/// Turn points into account balance at 1 pt = ₱1.
class ConvertPointsToBalanceOffer extends PointsOffer {
  const ConvertPointsToBalanceOffer();

  @override
  String get id => 'convert_to_balance';

  @override
  String get title => 'Convert Points to Balance';

  @override
  String get description =>
      'Move points into your account balance at 1 pt = ₱1. '
      'Converted points leave your points total.';

  /// The smallest conversion worth making.
  static const double minimumPoints = 1;

  @override
  bool get takesAmount => true;

  @override
  double costFor(String mechanicName) => minimumPoints;

  @override
  String rewardFor(String mechanicName) {
    final balance = PointsWalletStore.instance.balanceFor(mechanicName);
    return 'Up to ${formatPesos(pesosForPoints(balance))} from your '
        '${formatPointsLabel(balance)}';
  }

  @override
  String? redeem(String mechanicName, {double? points}) {
    final wallet = PointsWalletStore.instance;
    final amount = points ?? wallet.balanceFor(mechanicName);

    if (amount < minimumPoints) {
      return 'Convert at least ${formatPointsLabel(minimumPoints)}.';
    }
    if (!wallet.canAfford(mechanicName, amount)) {
      return 'You only have ${formatPointsLabel(wallet.balanceFor(mechanicName))}.';
    }

    final pesos = pesosForPoints(amount);
    final entry = wallet.debit(
      owner: mechanicName,
      kind: PointsEntryKind.mechanicConvertedToBalance,
      points: amount,
      note: 'Converted to ${formatPesos(pesos)} balance',
      pesos: pesos,
    );
    return entry == null ? 'Could not convert those points.' : null;
  }
}

/// The catalogue.
///
/// One entry today. The list is the extension point: everything downstream
/// iterates it, so a second offer appears on the screen the moment it is added
/// here.
class PointsOffers {
  const PointsOffers._();

  static const List<PointsOffer> all = [
    ConvertPointsToBalanceOffer(),
  ];

  /// The offers to show a mechanic, in the order they should read.
  static List<PointsOffer> forMechanic(String mechanicName) => all;
}

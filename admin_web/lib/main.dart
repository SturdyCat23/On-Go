import 'package:flutter/material.dart';

import 'src/app/console_app.dart';
import 'src/dev_mock/dev_mock.dart';
import 'src/theme/console_theme.dart';

/// The On Go admin console — the Admin and Moderator web application.
///
/// This is one of the product's two front ends. The other is the On Go mobile
/// app (Client + Mechanic) at the repository root. They share no code except
/// `package:on_go_shared`, which holds the models and API contracts they
/// exchange, and they will meet at a backend that implements those contracts.
/// See ARCHITECTURE.md.
///
/// Nothing is wired to a network yet. `ConsoleBackend` installs local
/// implementations of every contract, and swapping them for HTTP ones is a
/// single call here — see `ConsoleBackend.configure`.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore the saved appearance before the first frame, so the console never
  // flashes light before painting dark.
  await ThemeController.instance.load();

  // FAKE DATA — UI testing only. Fills the Admin revenue ledger so the
  // Overview and Income charts have something to draw. Delete this line and
  // the import above with `src/dev_mock/` to remove it — see its README.
  installDevMocks();

  runApp(const ConsoleApp());
}

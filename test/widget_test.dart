import 'package:flutter_test/flutter_test.dart';
import 'package:on_go/main.dart';
import 'package:on_go/screens/auth/admin_ui/admin_home_screen.dart';
import 'package:on_go/screens/auth/client_ui/client_home_screen.dart';
import 'package:on_go/screens/auth/mechanic_ui/mechanic_home_screen.dart';
import 'package:on_go/screens/auth/moderator_ui/moderator_home_screen.dart';

void main() {
  testWidgets('app shows the sign-in screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('demo client button opens the client home screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Continue as Client (demo)'));
    await tester.pumpAndSettle();

    expect(find.byType(ClientHomeScreen), findsOneWidget);
  });

  testWidgets('demo mechanic button opens the mechanic home screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Continue as Mechanic (demo)'));
    await tester.pumpAndSettle();

    expect(find.byType(MechanicHomeScreen), findsOneWidget);
  });

  testWidgets('demo moderator button opens the moderator home screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Continue as Moderator (demo)'));
    await tester.pumpAndSettle();

    expect(find.byType(ModeratorHomeScreen), findsOneWidget);
  });

  testWidgets('demo admin button opens the admin home screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Continue as Admin (demo)'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminHomeScreen), findsOneWidget);
  });
}

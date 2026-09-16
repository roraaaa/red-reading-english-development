import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:red/data/repositories/auth_repository.dart';
import 'package:red/data/services/auth_service.dart';
import 'package:red/domain/models/app_user.dart';
import 'package:red/ui/features/account/views/account_screen.dart';

void main() {
  late _FakeAuthService service;
  late AuthRepository auth;

  setUp(() {
    service = _FakeAuthService();
    auth = AuthRepository(service: service);
  });

  tearDown(() {
    auth.dispose();
    service.dispose();
  });

  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: AccountScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDialog(WidgetTester tester) async {
    // The danger zone sits below the fold on a test-sized screen.
    final button = find.widgetWithText(InkWell, 'Delete my account').last;
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Delete for ever?'), findsOneWidget);
  }

  testWidgets('shows who is logged in', (tester) async {
    await openScreen(tester);
    expect(find.text('Ana Cruz'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
  });

  testWidgets('deleting asks for the password first', (tester) async {
    await openScreen(tester);
    await openDialog(tester);

    // An empty password must not reach the service.
    await tester.tap(find.widgetWithText(FilledButton, 'Delete for ever'));
    await tester.pumpAndSettle();
    expect(service.deletedWith, isNull);
    expect(find.text('Please type your password.'), findsOneWidget);
    expect(find.text('Delete for ever?'), findsOneWidget);
  });

  testWidgets('a wrong password keeps the account and explains why', (tester) async {
    service.failWith = const AuthException('That password is not correct.');
    await openScreen(tester);
    await openDialog(tester);

    await tester.enterText(find.byType(TextFormField), 'guessing');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete for ever'));
    await tester.pumpAndSettle();

    expect(service.deletedWith, 'guessing');
    expect(auth.isSignedIn, isTrue);
    expect(find.text('That password is not correct.'), findsOneWidget);
    expect(find.text('Delete for ever?'), findsOneWidget, reason: 'the dialog should stay open');
  });

  testWidgets('the right password deletes the account and closes the dialog', (tester) async {
    await openScreen(tester);
    await openDialog(tester);

    await tester.enterText(find.byType(TextFormField), 'readwell');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete for ever'));
    await tester.pumpAndSettle();

    expect(service.deletedWith, 'readwell');
    expect(auth.isSignedIn, isFalse);
    expect(find.text('Delete for ever?'), findsNothing);
  });

  testWidgets('Keep my account backs out without deleting', (tester) async {
    await openScreen(tester);
    await openDialog(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Keep my account'));
    await tester.pumpAndSettle();

    expect(service.deletedWith, isNull);
    expect(auth.isSignedIn, isTrue);
  });
}

class _FakeAuthService implements AuthService {
  final _changes = StreamController<AppUser?>.broadcast();

  AppUser? _user = const AppUser(id: 'u1', displayName: 'Ana Cruz', email: 'ana@example.com');

  /// The password the screen passed to [deleteAccount], or null if it never
  /// got that far.
  String? deletedWith;

  /// Set to make [deleteAccount] fail the way a wrong password would.
  AuthException? failWith;

  void dispose() => _changes.close();

  @override
  bool get isCloud => true;

  @override
  Stream<AppUser?> userChanges() async* {
    yield _user;
    yield* _changes.stream;
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    deletedWith = password;
    if (failWith case final failure?) throw failure;
    _user = null;
    _changes.add(null);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _changes.add(null);
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> sendPasswordReset(String email) => throw UnimplementedError();
}

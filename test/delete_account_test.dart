import 'package:flutter_test/flutter_test.dart';
import 'package:red/data/services/auth_service.dart';
import 'package:red/data/services/local_auth_service.dart';
import 'package:red/data/services/progress_service.dart';
import 'package:red/domain/models/attempt.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Covers the offline demo backend. The Firebase path needs a real project,
/// so it is checked by hand on a device.
void main() {
  late LocalAuthService auth;
  late LocalProgressService progress;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = LocalAuthService();
    progress = LocalProgressService();
  });

  Future<void> signUp() => auth
      .signUp(name: 'Ana', email: 'ana@example.com', password: 'readwell')
      .then((_) {});

  Attempt attempt(String id) => Attempt(
    id: id,
    kind: AttemptKind.material,
    passageId: 'mars',
    passageTitle: 'Mars',
    levelId: 'green',
    correct: 4,
    total: 5,
    stars: 3,
    completedAt: DateTime(2026, 9, 16),
    answers: const [],
  );

  test('deleting an account takes the scores with it', () async {
    await signUp();
    final user = (await auth.userChanges().first)!;
    await progress.addAttempt(user.id, attempt('a1'));
    await progress.addAttempt(user.id, attempt('a2'));
    expect(await progress.fetchAttempts(user.id), hasLength(2));

    await auth.deleteAccount(password: 'readwell');

    expect(await progress.fetchAttempts(user.id), isEmpty);
    // The email is free again, which only holds if the record really went.
    await expectLater(
      auth.signIn(email: 'ana@example.com', password: 'readwell'),
      throwsA(isA<AuthException>()),
    );
  });

  test('the wrong password deletes nothing', () async {
    await signUp();
    final user = (await auth.userChanges().first)!;
    await progress.addAttempt(user.id, attempt('a1'));

    await expectLater(
      auth.deleteAccount(password: 'guessing'),
      throwsA(isA<AuthException>()),
    );

    expect(await progress.fetchAttempts(user.id), hasLength(1));
    final stillThere = await auth.signIn(email: 'ana@example.com', password: 'readwell');
    expect(stillThere.email, 'ana@example.com');
  });

  test('one account being deleted leaves the other alone', () async {
    await signUp();
    final ana = (await auth.userChanges().first)!;
    await progress.addAttempt(ana.id, attempt('a1'));
    await auth.signOut();

    final ben = await auth.signUp(name: 'Ben', email: 'ben@example.com', password: 'readwell');
    await progress.addAttempt(ben.id, attempt('b1'));
    await auth.deleteAccount(password: 'readwell');

    expect(await progress.fetchAttempts(ben.id), isEmpty);
    expect(await progress.fetchAttempts(ana.id), hasLength(1));
    final back = await auth.signIn(email: 'ana@example.com', password: 'readwell');
    expect(back.displayName, 'Ana');
  });

  test('deleting when nobody is logged in is refused', () async {
    await expectLater(
      auth.deleteAccount(password: 'readwell'),
      throwsA(isA<AuthException>()),
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:red/data/repositories/content_repository.dart';
import 'package:red/data/services/content_cache.dart';
import 'package:red/data/services/content_service.dart';
import 'package:red/domain/models/content_snapshot.dart';
import 'package:red/domain/models/passage.dart';
import 'package:red/domain/models/question.dart';
import 'package:red/domain/models/reading_skill.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeBundled implements ContentSource {
  FakeBundled(this.snapshot);

  final ContentSnapshot snapshot;

  @override
  Future<ContentSnapshot> load() async => snapshot;
}

class FakeCloud implements CloudContentSource {
  int? version;
  ContentSnapshot? snapshot;
  bool offline = false;
  int versionChecks = 0;

  @override
  Future<int?> fetchVersion() async {
    versionChecks++;
    if (offline) throw Exception('offline');
    return version;
  }

  @override
  Future<ContentSnapshot> fetchSnapshot() async => snapshot!;
}

const _question = Question(
  id: 'q1',
  type: QuestionType.choice,
  prompt: 'Pick one',
  skill: ReadingSkill.details,
  options: ['A', 'B'],
  answerIndex: 0,
);

Passage _passage(String id, {String? level, Difficulty? difficulty, String? title}) => Passage(
  id: id,
  title: title ?? 'Title for $id',
  topic: 'Topic',
  icon: 'book',
  levelId: level,
  difficulty: difficulty,
  paragraphs: const ['Once upon a time.'],
  questions: const [_question],
);

/// The smallest content that passes validation.
ContentSnapshot _content(int version, {String storyTitle = 'Story', bool includeHard = true}) => ContentSnapshot(
  version: version,
  levels: const [
    ReadingLevel(id: 'green', number: 1, name: 'Green', colorValue: 0xFF2EAD5F, icon: 'leaf', description: 'Easy'),
  ],
  passages: [
    _passage('story', level: 'green', title: storyTitle),
    _passage('easy', difficulty: Difficulty.easy),
    _passage('medium', difficulty: Difficulty.medium),
    if (includeHard) _passage('hard', difficulty: Difficulty.hard),
  ],
);

void main() {
  late FakeCloud cloud;
  late DateTime now;

  ContentRepository repository() => ContentRepository(
    bundled: FakeBundled(_content(0, storyTitle: 'Bundled')),
    cache: ContentCache(),
    cloud: cloud,
    clock: () => now,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cloud = FakeCloud();
    now = DateTime(2026, 9, 15, 9);
  });

  test('starts with the bundled content when nothing has been downloaded', () async {
    final repo = repository();
    await repo.load();

    expect(repo.version, 0);
    expect(repo.material('story')!.title, 'Bundled');
  });

  test('downloads newer published content, then uses it offline next launch', () async {
    cloud
      ..version = 5
      ..snapshot = _content(5, storyTitle: 'From the cloud');
    final repo = repository();
    await repo.load();
    var notified = false;
    repo.addListener(() => notified = true);

    expect(await repo.refreshFromCloud(), isTrue);
    expect(notified, isTrue);
    expect(repo.material('story')!.title, 'From the cloud');

    cloud.offline = true;
    final nextLaunch = repository();
    await nextLaunch.load();
    expect(nextLaunch.version, 5);
    expect(nextLaunch.material('story')!.title, 'From the cloud');
  });

  test('keeps current content when offline or nothing newer is published', () async {
    final repo = repository();
    await repo.load();

    cloud.version = 0;
    expect(await repo.refreshFromCloud(), isFalse);

    cloud.offline = true;
    expect(await repo.refreshFromCloud(force: true), isFalse);
    expect(repo.material('story')!.title, 'Bundled');
  });

  test('refuses published content that fails validation', () async {
    cloud
      ..version = 9
      ..snapshot = _content(9, storyTitle: 'Broken', includeHard: false);
    final repo = repository();
    await repo.load();

    expect(await repo.refreshFromCloud(), isFalse);
    expect(repo.version, 0);
    expect(repo.material('story')!.title, 'Bundled');
  });

  test('assessment cards can never be opened or listed as Materials stories', () async {
    final repo = repository();
    await repo.load();

    expect(repo.material('easy'), isNull);
    expect(repo.materialsFor('green').map((p) => p.id), ['story']);
    expect(repo.assessment('easy'), isNotNull);
    expect(repo.assessment('story'), isNull);
  });

  test('checks the cloud at most every few minutes unless forced', () async {
    final repo = repository();
    await repo.load();

    await repo.refreshFromCloud();
    await repo.refreshFromCloud();
    expect(cloud.versionChecks, 1);

    now = now.add(const Duration(minutes: 6));
    await repo.refreshFromCloud();
    await repo.refreshFromCloud(force: true);
    expect(cloud.versionChecks, 3);
  });
}

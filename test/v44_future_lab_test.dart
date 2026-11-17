import 'package:flutter_test/flutter_test.dart';
import 'package:future_youth_forum/v44_future_lab.dart';

void main() {
  group('V44ChallengeLogic', () {
    test('selects a stable challenge index inside the list', () {
      final day = DateTime(2026, 11, 17);
      final first = V44ChallengeLogic.challengeIndex(day, 7);
      expect(first, V44ChallengeLogic.challengeIndex(day, 7));
      expect(first, inInclusiveRange(0, 6));
    });

    test('returns zero for an empty challenge list', () {
      expect(V44ChallengeLogic.challengeIndex(DateTime(2026, 11, 17), 0), 0);
    });

    test('starts a new streak', () {
      expect(
        V44ChallengeLogic.nextStreak(
          previous: null,
          today: DateTime(2026, 11, 17),
          currentStreak: 0,
        ),
        1,
      );
    });

    test('continues a streak after yesterday', () {
      expect(
        V44ChallengeLogic.nextStreak(
          previous: DateTime(2026, 11, 16, 22),
          today: DateTime(2026, 11, 17, 8),
          currentStreak: 4,
        ),
        5,
      );
    });

    test('does not increment twice on the same day', () {
      expect(
        V44ChallengeLogic.nextStreak(
          previous: DateTime(2026, 11, 17, 7),
          today: DateTime(2026, 11, 17, 23),
          currentStreak: 5,
        ),
        5,
      );
    });

    test('resets after a missed day', () {
      expect(
        V44ChallengeLogic.nextStreak(
          previous: DateTime(2026, 11, 14),
          today: DateTime(2026, 11, 17),
          currentStreak: 8,
        ),
        1,
      );
    });
  });
}

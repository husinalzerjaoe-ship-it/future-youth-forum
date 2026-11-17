import 'package:flutter_test/flutter_test.dart';
import 'package:future_youth_forum/v39_daily_challenges.dart';

void main() {
  group('V39ChallengeLogic', () {
    test('starts a new streak without a previous completion', () {
      expect(
        V39ChallengeLogic.nextStreak(
          previous: null,
          today: DateTime(2026, 11, 17),
          currentStreak: 0,
        ),
        1,
      );
    });

    test('continues a streak when the previous completion was yesterday', () {
      expect(
        V39ChallengeLogic.nextStreak(
          previous: DateTime(2026, 11, 16, 22),
          today: DateTime(2026, 11, 17, 8),
          currentStreak: 4,
        ),
        5,
      );
    });

    test('does not increment twice on the same day', () {
      expect(
        V39ChallengeLogic.nextStreak(
          previous: DateTime(2026, 11, 17, 7),
          today: DateTime(2026, 11, 17, 23),
          currentStreak: 5,
        ),
        5,
      );
    });

    test('resets after a missed day', () {
      expect(
        V39ChallengeLogic.nextStreak(
          previous: DateTime(2026, 11, 14),
          today: DateTime(2026, 11, 17),
          currentStreak: 8,
        ),
        1,
      );
    });

    test('daily challenge selection is stable and in range', () {
      final date = DateTime(2026, 11, 17);
      final first = V39ChallengeLogic.challengeIndex(date, 14);
      expect(first, V39ChallengeLogic.challengeIndex(date, 14));
      expect(first, inInclusiveRange(0, 13));
      expect(V39ChallengeLogic.challengeIndex(date, 0), 0);
    });
  });
}

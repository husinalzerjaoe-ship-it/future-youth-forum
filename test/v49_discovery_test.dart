import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:future_youth_forum/v49_discovery.dart';

void main() {
  group('V49VideoFeedFilter', () {
    test('includes active HTTPS video stories', () {
      final now = DateTime(2026, 11, 17, 12);
      expect(
        V49VideoFeedFilter.isVisible({
          'mediaType': 'video',
          'mediaUrl': 'https://cdn.example/video.mp4',
          'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 1))),
        }, now),
        isTrue,
      );
    });

    test('excludes expired stories', () {
      final now = DateTime(2026, 11, 17, 12);
      expect(
        V49VideoFeedFilter.isVisible({
          'mediaType': 'video',
          'mediaUrl': 'https://cdn.example/video.mp4',
          'expiresAt': Timestamp.fromDate(now.subtract(const Duration(seconds: 1))),
        }, now),
        isFalse,
      );
    });

    test('excludes non-video and non-HTTPS media', () {
      final now = DateTime(2026, 11, 17, 12);
      expect(
        V49VideoFeedFilter.isVisible({
          'mediaType': 'image',
          'mediaUrl': 'https://cdn.example/image.jpg',
        }, now),
        isFalse,
      );
      expect(
        V49VideoFeedFilter.isVisible({
          'mediaType': 'video',
          'mediaUrl': 'http://example.invalid/video.mp4',
        }, now),
        isFalse,
      );
    });
  });
}

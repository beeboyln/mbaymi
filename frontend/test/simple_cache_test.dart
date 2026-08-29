import 'package:flutter_test/flutter_test.dart';
import 'package:mbaymi/services/simple_cache.dart';

void main() {
  group('SimpleCache invalidation', () {
    test('removeByPrefix clears only matching cache entries', () {
      final cache = SimpleCache<String>(ttl: const Duration(minutes: 10));

      cache.set('farms_user_12', 'farm');
      cache.set('farms_user_13', 'other farm');
      cache.set('livestock_12', 'livestock');
      cache.set('profile_12', 'profile');

      cache.removeByPrefix('farms_');

      expect(cache.get('farms_user_12'), isNull);
      expect(cache.get('farms_user_13'), isNull);
      expect(cache.get('livestock_12'), 'livestock');
      expect(cache.get('profile_12'), 'profile');
    });
  });
}

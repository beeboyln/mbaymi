import 'package:flutter_test/flutter_test.dart';
import 'package:mbaymi/services/app_cache_manager.dart';

void main() {
  group('AppCacheManager', () {
    test('reloads after invalidation and keeps TTL behavior', () async {
      final cache = AppCacheManager();
      var counter = 0;

      final first = await cache.load<String>(
        'farm:12',
        () async {
          counter++;
          return 'A';
        },
        ttl: const Duration(minutes: 5),
      );

      expect(first, 'A');
      expect(counter, 1);

      cache.invalidate('farm:12');

      final second = await cache.load<String>(
        'farm:12',
        () async {
          counter++;
          return 'B';
        },
        ttl: const Duration(minutes: 5),
      );

      expect(second, 'B');
      expect(counter, 2);
    });

    test('invalidatePrefix clears matching keys', () async {
      final cache = AppCacheManager();

      await cache.load<String>('farms:user:1', () async => 'farm1');
      await cache.load<String>('farms:user:2', () async => 'farm2');
      await cache.load<String>('livestock:user:1', () async => 'animal1');

      cache.invalidatePrefix('farms:');

      expect(cache.peek<String>('farms:user:1'), isNull);
      expect(cache.peek<String>('farms:user:2'), isNull);
      expect(cache.peek<String>('livestock:user:1'), 'animal1');
    });
  });
}

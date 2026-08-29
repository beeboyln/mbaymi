import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/app_cache_manager.dart';
import 'package:mbaymi/services/app_event_bus.dart';

class DataRepository {
  final AppCacheManager _cache = AppCacheManager();
  final AppEventBus _bus = AppEventBus();

  Future<List<dynamic>> getFarmsForUser(int userId) {
    return _cache.load<List<dynamic>>(
      'farms:user:$userId',
      () => ApiService.getPublicUserFarms(userId),
      ttl: const Duration(minutes: 2),
    );
  }

  Future<List<dynamic>> getFarmCrops(int farmId) {
    return _cache.load<List<dynamic>>(
      'crops:farm:$farmId',
      () => ApiService.getFarmCrops(farmId),
      ttl: const Duration(minutes: 2),
    );
  }

  Future<List<dynamic>> getLivestockForUser(int userId) {
    return _cache.load<List<dynamic>>(
      'livestock:user:$userId',
      () => ApiService.getUserLivestock(userId),
      ttl: const Duration(minutes: 2),
    );
  }

  Future<List<dynamic>> getMarketSales() {
    return _cache.load<List<dynamic>>(
      'market:sales',
      () => ApiService.getAllSales(),
      ttl: const Duration(minutes: 1),
    );
  }

  void invalidateFarmCaches(int userId) {
    _cache.invalidatePrefix('farms:');
    _cache.invalidatePrefix('crops:');
    _cache.invalidatePrefix('livestock:');
    _bus.emit(const AppAppEvent('farm_data_changed'));
  }

  void invalidateMarketCaches() {
    _cache.invalidatePrefix('market:');
    _bus.emit(const AppAppEvent('market_data_changed'));
  }
}

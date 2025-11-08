import 'dart:math';
import '../data/slogans.dart';

class SloganService {
  static final SloganService _instance = SloganService._internal();
  factory SloganService() => _instance;
  SloganService._internal();

  String? _currentSlogan;
  DateTime? _lastUpdate;
  static const Duration _updateInterval = Duration(hours: 1);

  String getCurrentSlogan() {
    // Update slogan every hour or on first load
    if (_currentSlogan == null || 
        _lastUpdate == null || 
        DateTime.now().difference(_lastUpdate!) > _updateInterval) {
      _currentSlogan = _getRandomSlogan();
      _lastUpdate = DateTime.now();
    }
    return _currentSlogan!;
  }

  String _getRandomSlogan() {
    final random = Random();
    return SlogansData.slogans[random.nextInt(SlogansData.slogans.length)];
  }

  // Force refresh slogan (useful for testing)
  String refreshSlogan() {
    _currentSlogan = _getRandomSlogan();
    _lastUpdate = DateTime.now();
    return _currentSlogan!;
  }
}

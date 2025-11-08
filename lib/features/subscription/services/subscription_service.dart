import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../../config/environment.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  static const String _apiKey = 'YOUR_REVENUECAT_API_KEY';
  static const String _monthlyProductId = 'storyhug_monthly';
  static const String _yearlyProductId = 'storyhug_yearly';
  static const String _premiumEntitlementId = 'premium';

  bool _isInitialized = false;
  CustomerInfo? _customerInfo;
  List<Package> _availablePackages = [];

  // Getters
  bool get isInitialized => _isInitialized;
  CustomerInfo? get customerInfo => _customerInfo;
  List<Package> get availablePackages => _availablePackages;
  
  bool get isPremiumActive {
    return _customerInfo?.entitlements.all[_premiumEntitlementId]?.isActive ?? false;
  }

  bool get isPremiumTrialActive {
    return _customerInfo?.entitlements.all[_premiumEntitlementId]?.willRenew ?? false;
  }

  /// Initialize RevenueCat
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Configure RevenueCat
      await Purchases.setLogLevel(LogLevel.debug);
      
      // Initialize with API key
      PurchasesConfiguration configuration = PurchasesConfiguration(_apiKey);
      await Purchases.configure(configuration);

      // Set up customer info listener
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      // Load initial customer info
      _customerInfo = await Purchases.getCustomerInfo();
      
      // Load available packages
      await _loadAvailablePackages();

      _isInitialized = true;
      
      if (kDebugMode) {
        print('RevenueCat initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RevenueCat initialization failed: $e');
      }
      throw Exception('Failed to initialize RevenueCat: $e');
    }
  }

  /// Load available subscription packages
  Future<void> _loadAvailablePackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      
      if (offerings.current != null) {
        _availablePackages = offerings.current!.availablePackages;
      }
      
      if (kDebugMode) {
        print('Loaded ${_availablePackages.length} subscription packages');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load packages: $e');
      }
    }
  }

  /// Handle customer info updates
  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    _customerInfo = customerInfo;
    
    if (kDebugMode) {
      print('Customer info updated: Premium active: ${isPremiumActive}');
    }
  }

  /// Purchase a subscription package
  Future<CustomerInfo> purchasePackage(Package package) async {
    try {
      if (!_isInitialized) {
        throw Exception('RevenueCat not initialized');
      }

      await Purchases.purchasePackage(package);
      final customerInfo = await Purchases.getCustomerInfo();
      _customerInfo = customerInfo;
      
      if (kDebugMode) {
        print('Purchase successful: ${package.identifier}');
      }
      
      return customerInfo;
    } catch (e) {
      if (kDebugMode) {
        print('Purchase failed: $e');
      }
      throw Exception('Purchase failed: $e');
    }
  }

  /// Restore purchases
  Future<CustomerInfo> restorePurchases() async {
    try {
      if (!_isInitialized) {
        throw Exception('RevenueCat not initialized');
      }

      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;
      
      if (kDebugMode) {
        print('Purchases restored successfully');
      }
      
      return customerInfo;
    } catch (e) {
      if (kDebugMode) {
        print('Restore failed: $e');
      }
      throw Exception('Restore failed: $e');
    }
  }

  /// Get monthly subscription package
  Package? getMonthlyPackage() {
    return _availablePackages.firstWhere(
      (package) => package.identifier == _monthlyProductId,
      orElse: () => _availablePackages.firstWhere(
        (package) => package.packageType == PackageType.monthly,
        orElse: () => _availablePackages.isNotEmpty ? _availablePackages.first : throw Exception('No packages available'),
      ),
    );
  }

  /// Get yearly subscription package
  Package? getYearlyPackage() {
    return _availablePackages.firstWhere(
      (package) => package.identifier == _yearlyProductId,
      orElse: () => _availablePackages.firstWhere(
        (package) => package.packageType == PackageType.annual,
        orElse: () => _availablePackages.isNotEmpty ? _availablePackages.first : throw Exception('No packages available'),
      ),
    );
  }

  /// Check if user can make purchases
  Future<bool> canMakePurchases() async {
    try {
      return await Purchases.canMakePayments();
    } catch (e) {
      return false;
    }
  }

  /// Get subscription status
  String getSubscriptionStatus() {
    if (!_isInitialized) return 'Not initialized';
    if (_customerInfo == null) return 'Unknown';
    
    final entitlement = _customerInfo!.entitlements.all[_premiumEntitlementId];
    if (entitlement == null) return 'No subscription';
    
    if (entitlement.isActive) {
      return 'Premium Active';
    } else if (entitlement.willRenew) {
      return 'Trial Active';
    } else {
      return 'Expired';
    }
  }

  /// Get subscription expiration date
  DateTime? getSubscriptionExpirationDate() {
    if (_customerInfo == null) return null;
    
    final entitlement = _customerInfo!.entitlements.all[_premiumEntitlementId];
    if (entitlement?.expirationDate != null) {
      return DateTime.tryParse(entitlement!.expirationDate!);
    }
    return null;
  }

  /// Get subscription product identifier
  String? getSubscriptionProductId() {
    if (_customerInfo == null) return null;
    
    final entitlement = _customerInfo!.entitlements.all[_premiumEntitlementId];
    return entitlement?.productIdentifier;
  }

  /// Check if feature is available
  bool isFeatureAvailable(String feature) {
    switch (feature) {
      case 'unlimited_stories':
      case 'voice_cloning':
      case 'offline_download':
      case 'premium_categories':
        return isPremiumActive;
      case 'basic_stories':
        return true; // Always available
      default:
        return false;
    }
  }

  /// Get feature limits for free users
  Map<String, int> getFreeUserLimits() {
    return {
      'stories_per_day': 3,
      'voice_cloning_attempts': 1,
      'offline_downloads': 0,
      'premium_categories': 0,
    };
  }

  /// Get premium features list
  List<String> getPremiumFeatures() {
    return [
      'Unlimited Stories',
      'Voice Cloning',
      'Offline Downloads',
      'Premium Categories',
      'Ad-Free Experience',
      'Priority Support',
    ];
  }

  /// Get subscription benefits
  List<String> getSubscriptionBenefits() {
    return [
      'Access to unlimited stories',
      'Create personalized voice for your child',
      'Download stories for offline listening',
      'Exclusive premium story categories',
      'Ad-free storytelling experience',
      'Priority customer support',
    ];
  }

  /// Handle purchase errors
  String getPurchaseErrorMessage(PurchasesError error) {
    switch (error.code) {
      case PurchasesErrorCode.purchaseCancelledError:
        return 'Purchase was cancelled';
      case PurchasesErrorCode.storeProblemError:
        return 'Store problem occurred';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchase not allowed';
      case PurchasesErrorCode.purchaseInvalidError:
        return 'Purchase invalid';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return 'Product not available';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return 'Product already purchased';
      case PurchasesErrorCode.receiptAlreadyInUseError:
        return 'Receipt already in use';
      case PurchasesErrorCode.invalidReceiptError:
        return 'Invalid receipt';
      case PurchasesErrorCode.missingReceiptFileError:
        return 'Missing receipt file';
      case PurchasesErrorCode.networkError:
        return 'Network error occurred';
      case PurchasesErrorCode.invalidCredentialsError:
        return 'Invalid credentials';
      case PurchasesErrorCode.unexpectedBackendResponseError:
        return 'Unexpected backend response';
      case PurchasesErrorCode.receiptInUseByOtherSubscriberError:
        return 'Receipt in use by other subscriber';
      case PurchasesErrorCode.invalidAppUserIdError:
        return 'Invalid app user ID';
      case PurchasesErrorCode.operationAlreadyInProgressError:
        return 'Operation already in progress';
      case PurchasesErrorCode.unknownError:
      default:
        return 'Unknown error occurred';
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing SubscriptionService: $e');
      }
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../config/environment.dart';
import '../../../core/services/supabase_service.dart';

enum SubscriptionStatus {
  active,
  cancelled,
  expired,
  pastDue,
  trialing,
  incomplete,
  unknown
}

enum PlanType {
  monthly,
  yearly,
  free
}

class StripeSubscriptionService {
  static final StripeSubscriptionService _instance = StripeSubscriptionService._internal();
  factory StripeSubscriptionService() => _instance;
  StripeSubscriptionService._internal();

  bool _isInitialized = false;

  // Stripe Price IDs (you'll get these from Stripe Dashboard)
  static const String _monthlyPriceId = 'price_monthly_storyhug';
  static const String _yearlyPriceId = 'price_yearly_storyhug';

  /// Initialize Stripe
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;
    if (kDebugMode) {
      print('Stripe service initialized successfully');
    }
  }

  /// Create a Stripe customer
  Future<String?> createCustomer(String email, String name) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/customers'),
        headers: {
          'Authorization': 'Bearer ${Environment.stripeSecretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': email,
          'name': name,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id'];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating Stripe customer: $e');
      }
    }
    return null;
  }

  /// Create subscription
  Future<bool> createSubscription(String customerId, PlanType planType) async {
    try {
      final priceId = planType == PlanType.monthly ? _monthlyPriceId : _yearlyPriceId;
      
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/subscriptions'),
        headers: {
          'Authorization': 'Bearer ${Environment.stripeSecretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'customer': customerId,
          'items[0][price]': priceId,
          'payment_behavior': 'default_incomplete',
          'payment_settings[save_default_payment_method]': 'on_subscription',
          'expand[]': 'latest_invoice.payment_intent',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final subscriptionId = data['id'];
        
        // Save subscription to Supabase
        await _saveSubscriptionToSupabase(
          customerId: customerId,
          subscriptionId: subscriptionId,
          planType: planType,
          status: SubscriptionStatus.active,
        );

        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating subscription: $e');
      }
    }
    return false;
  }

  /// Get subscription status
  Future<SubscriptionStatus> getSubscriptionStatus(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('subscriptions')
          .select('status, current_period_end')
          .eq('user_id', userId)
          .single();

      final status = response['status'] as String;
      final endDate = DateTime.parse(response['current_period_end']);

      if (endDate.isBefore(DateTime.now())) {
        return SubscriptionStatus.expired;
      }

      switch (status.toLowerCase()) {
        case 'active':
          return SubscriptionStatus.active;
        case 'cancelled':
          return SubscriptionStatus.cancelled;
        case 'past_due':
          return SubscriptionStatus.pastDue;
        case 'trialing':
          return SubscriptionStatus.trialing;
        case 'incomplete':
          return SubscriptionStatus.incomplete;
        default:
          return SubscriptionStatus.unknown;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting subscription status: $e');
      }
      return SubscriptionStatus.unknown;
    }
  }

  /// Check if user has premium access
  Future<bool> isPremiumActive(String userId) async {
    final status = await getSubscriptionStatus(userId);
    return status == SubscriptionStatus.active || status == SubscriptionStatus.trialing;
  }

  /// Cancel subscription
  Future<bool> cancelSubscription(String userId) async {
    try {
      // Get subscription ID from Supabase
      final response = await SupabaseService.client
          .from('subscriptions')
          .select('stripe_subscription_id')
          .eq('user_id', userId)
          .single();

      final subscriptionId = response['stripe_subscription_id'] as String;

      // Cancel in Stripe
      final stripeResponse = await http.post(
        Uri.parse('https://api.stripe.com/v1/subscriptions/$subscriptionId'),
        headers: {
          'Authorization': 'Bearer ${Environment.stripeSecretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'cancel_at_period_end': 'true',
        },
      );

      if (stripeResponse.statusCode == 200) {
        // Update status in Supabase
        await SupabaseService.client
            .from('subscriptions')
            .update({'status': 'cancelled'})
            .eq('user_id', userId);

        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling subscription: $e');
      }
    }
    return false;
  }

  /// Get subscription details
  Future<Map<String, dynamic>?> getSubscriptionDetails(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('subscriptions')
          .select('*')
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting subscription details: $e');
      }
      return null;
    }
  }

  /// Save subscription to Supabase
  Future<void> _saveSubscriptionToSupabase({
    required String customerId,
    required String subscriptionId,
    required PlanType planType,
    required SubscriptionStatus status,
  }) async {
    try {
      await SupabaseService.client.from('subscriptions').insert({
        'user_id': customerId,
        'stripe_customer_id': customerId,
        'stripe_subscription_id': subscriptionId,
        'plan_type': planType.name,
        'status': status.name,
        'current_period_start': DateTime.now().toIso8601String(),
        'current_period_end': _getPeriodEnd(planType).toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error saving subscription to Supabase: $e');
      }
    }
  }

  /// Calculate period end date
  DateTime _getPeriodEnd(PlanType planType) {
    final now = DateTime.now();
    switch (planType) {
      case PlanType.monthly:
        return DateTime(now.year, now.month + 1, now.day);
      case PlanType.yearly:
        return DateTime(now.year + 1, now.month, now.day);
      case PlanType.free:
        return now;
    }
  }

  /// Get premium features
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
      'Unlimited access to all stories',
      'Create personalized voice models',
      'Download stories for offline listening',
      'Access to premium story categories',
      'Ad-free listening experience',
      'Priority customer support',
    ];
  }

  /// Get free user limits
  Map<String, int> getFreeUserLimits() {
    return {
      'stories_per_day': 3,
      'voice_cloning_attempts': 1,
      'offline_downloads': 0,
      'premium_categories': 0,
    };
  }

  /// Check if feature is available
  bool isFeatureAvailable(String feature, String userId) {
    // This would check subscription status in a real implementation
    // For now, return true for basic features
    switch (feature) {
      case 'basic_stories':
        return true;
      case 'unlimited_stories':
      case 'voice_cloning':
      case 'offline_download':
      case 'premium_categories':
        // These require premium subscription
        return false; // Would check actual subscription status
      default:
        return false;
    }
  }

  /// Get subscription status text
  String getSubscriptionStatusText(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.pastDue:
        return 'Past Due';
      case SubscriptionStatus.trialing:
        return 'Trial';
      case SubscriptionStatus.incomplete:
        return 'Incomplete';
      case SubscriptionStatus.unknown:
        return 'Unknown';
    }
  }

  /// Get subscription expiration date
  Future<DateTime?> getSubscriptionExpirationDate(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('subscriptions')
          .select('current_period_end')
          .eq('user_id', userId)
          .single();

      return DateTime.parse(response['current_period_end']);
    } catch (e) {
      return null;
    }
  }

  /// Get subscription product ID
  Future<String?> getSubscriptionProductId(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('subscriptions')
          .select('plan_type')
          .eq('user_id', userId)
          .single();

      return response['plan_type'];
    } catch (e) {
      return null;
    }
  }
}

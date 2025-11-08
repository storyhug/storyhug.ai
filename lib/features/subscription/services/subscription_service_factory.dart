import '../../../config/environment.dart';
import 'subscription_service.dart';
import 'stripe_subscription_service.dart';

/// Factory class to create the appropriate subscription service
class SubscriptionServiceFactory {
  static dynamic createSubscriptionService() {
    // Always use Stripe for now
    return StripeSubscriptionService();
  }
}

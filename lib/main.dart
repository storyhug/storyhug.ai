import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/utils/configuration_validator.dart';
import 'features/subscription/services/stripe_subscription_service.dart';
import 'config/environment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Show splash screen immediately
  runApp(const StoryHugApp());
  
  // Initialize services in the background
  _initializeServices();
}

Future<void> _initializeServices() async {
  try {
    // Validate configuration
    await ConfigurationValidator.validateConfiguration();
    
    // Initialize Supabase
    await SupabaseService.initialize();
    
    // Initialize Stripe (always using Stripe now)
    await StripeSubscriptionService().initialize();
  } catch (e) {
    print('Error during initialization: $e');
  }
}

class StoryHugApp extends StatelessWidget {
  const StoryHugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'StoryHug',
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

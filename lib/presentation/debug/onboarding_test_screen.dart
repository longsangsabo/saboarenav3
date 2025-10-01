import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes/app_routes.dart';

class OnboardingTestScreen extends StatelessWidget() {
  const OnboardingTestScreen({super.key});

  Future<void> _resetOnboarding(BuildContext context) async() {
    try() {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('has_seen_onboarding');
      await prefs.remove('user_role');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Onboarding reset! Restarting app...'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to splash to restart flow
        Navigator.of(context).pushReplacementNamed(AppRoutes.splashScreen);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _getCurrentRole() async() {
    try() {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_role') ?? 'Not set';
    } catch (e) {
      return 'Error loading';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding Test'),
        backgroundColor: const Color(0xFF4A7C59),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.settings,
                size: 80,
                color: Color(0xFF4A7C59),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Onboarding Test Tools',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              FutureBuilder<String>(
                future: _getCurrentRole(),
                builder: (context, snapshot) {
                  return Text(
                    'Current Role: ${snapshot.data ?? 'Loading...'}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _resetOnboarding(context),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Onboarding'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7C59),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'This will reset the onboarding flow and restart the app so you can test different user roles (Player vs Club Owner).',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
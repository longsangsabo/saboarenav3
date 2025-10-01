import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingDebugScreen extends StatelessWidget() {
  const OnboardingDebugScreen({super.key});

  Future<void> _resetOnboarding(BuildContext context) async() {
    try() {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('has_seen_onboarding');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Onboarding reset! Restart app to see onboarding again.'),
            backgroundColor: Colors.green,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding Debug'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _resetOnboarding(context),
              child: const Text('Reset Onboarding'),
            ),
          ],
        ),
      ),
    );
  }
}
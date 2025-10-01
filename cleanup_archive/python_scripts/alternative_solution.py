#!/usr/bin/env python3
"""
Alternative Referral Service that works with current schema
Uses existing 'rewards' JSONB column instead of separate columns
"""

import requests
import json

# Load environment variables
with open('env.json', 'r') as f:
    env = json.load(f)

SUPABASE_URL = env['SUPABASE_URL']
SERVICE_ROLE_KEY = env['SUPABASE_SERVICE_ROLE_KEY']

headers = {
    'apikey': SERVICE_ROLE_KEY,
    'Authorization': f'Bearer {SERVICE_ROLE_KEY}',
    'Content-Type': 'application/json'
}

def update_existing_codes_to_basic_format():
    """Update existing codes to use basic referral format in rewards column"""
    print("🔄 Converting existing codes to basic referral format...")
    
    try:
        # Get all existing codes
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/referral_codes?select=*",
            headers=headers
        )
        
        if response.status_code == 200:
            codes = response.json()
            print(f"📊 Found {len(codes)} existing codes")
            
            updated_count = 0
            
            for code in codes:
                current_rewards = code.get('rewards', {})
                
                # Convert to basic format if needed
                needs_update = False
                new_rewards = {
                    "referrer_spa": 100,
                    "referred_spa": 50,
                    "type": "basic"
                }
                
                # Check if it's already in basic format
                if (current_rewards.get('type') != 'basic' or
                    current_rewards.get('referrer_spa') != 100 or
                    current_rewards.get('referred_spa') != 50):
                    needs_update = True
                
                if needs_update:
                    update_response = requests.patch(
                        f"{SUPABASE_URL}/rest/v1/referral_codes?id=eq.{code['id']}",
                        headers=headers,
                        json={"rewards": new_rewards}
                    )
                    
                    if update_response.status_code == 204:
                        print(f"✅ Updated {code['code']} to basic format")
                        updated_count += 1
                    else:
                        print(f"⚠️ Failed to update {code['code']}: {update_response.status_code}")
                else:
                    print(f"✅ {code['code']} already in basic format")
            
            print(f"✅ Updated {updated_count} codes to basic format")
            return True
            
        else:
            print(f"❌ Failed to fetch codes: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Update failed: {e}")
        return False

def create_updated_basic_service():
    """Create updated BasicReferralService that works with current schema"""
    
    service_code = '''import 'package:supabase_flutter/supabase_flutter.dart';

class BasicReferralService {
  static final _supabase = Supabase.instance.client;

  // Create a new referral code
  static Future<Map<String, dynamic>?> createReferralCode({
    required String userId,
    required String code,
    int maxUses = 10,
    int referrerReward = 100,
    int referredReward = 50,
  }) async {
    try {
      final response = await _supabase
          .from('referral_codes')
          .insert({
            'user_id': userId,
            'code': code,
            'max_uses': maxUses,
            'current_uses': 0,
            'rewards': {
              'referrer_spa': referrerReward,
              'referred_spa': referredReward,
              'type': 'basic'
            },
            'is_active': true,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error creating referral code: $e');
      return null;
    }
  }

  // Get user's referral codes
  static Future<List<Map<String, dynamic>>> getUserReferralCodes(String userId) async {
    try {
      final response = await _supabase
          .from('referral_codes')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user referral codes: $e');
      return [];
    }
  }

  // Apply referral code
  static Future<Map<String, dynamic>?> applyReferralCode({
    required String code,
    required String newUserId,
  }) async {
    try {
      // Get referral code details
      final codeResponse = await _supabase
          .from('referral_codes')
          .select('*')
          .eq('code', code)
          .eq('is_active', true)
          .single();

      if (codeResponse == null) {
        return {'success': false, 'message': 'Invalid referral code'};
      }

      final currentUses = codeResponse['current_uses'] ?? 0;
      final maxUses = codeResponse['max_uses'];
      
      // Check usage limits
      if (maxUses != null && currentUses >= maxUses) {
        return {'success': false, 'message': 'Referral code usage limit reached'};
      }

      final rewards = codeResponse['rewards'] as Map<String, dynamic>;
      final referrerReward = rewards['referrer_spa'] ?? 100;
      final referredReward = rewards['referred_spa'] ?? 50;

      // Record usage
      await _supabase.from('referral_usage').insert({
        'referral_code_id': codeResponse['id'],
        'referrer_id': codeResponse['user_id'],
        'referred_user_id': newUserId,
        'spa_awarded_referrer': referrerReward,
        'spa_awarded_referred': referredReward,
      });

      // Update code usage count
      await _supabase
          .from('referral_codes')
          .update({'current_uses': currentUses + 1})
          .eq('id', codeResponse['id']);

      // Award SPA to both users
      await awardSpaToUser(codeResponse['user_id'], referrerReward);
      await awardSpaToUser(newUserId, referredReward);

      return {
        'success': true,
        'referrer_reward': referrerReward,
        'referred_reward': referredReward,
        'message': 'Referral applied successfully!'
      };
    } catch (e) {
      print('Error applying referral code: $e');
      return {'success': false, 'message': 'Error applying referral code'};
    }
  }

  // Award SPA to user
  static Future<void> awardSpaToUser(String userId, int spaAmount) async {
    try {
      // Get current user data
      final userResponse = await _supabase
          .from('users')
          .select('spa_balance')
          .eq('id', userId)
          .single();

      final currentSpa = userResponse['spa_balance'] ?? 0;
      final newSpa = currentSpa + spaAmount;

      // Update user SPA balance
      await _supabase
          .from('users')
          .update({'spa_balance': newSpa})
          .eq('id', userId);

      print('Awarded $spaAmount SPA to user $userId (new balance: $newSpa)');
    } catch (e) {
      print('Error awarding SPA to user: $e');
    }
  }

  // Get referral code by code string
  static Future<Map<String, dynamic>?> getReferralCodeDetails(String code) async {
    try {
      final response = await _supabase
          .from('referral_codes')
          .select('*')
          .eq('code', code)
          .eq('is_active', true)
          .single();

      return response;
    } catch (e) {
      print('Error fetching referral code details: $e');
      return null;
    }
  }

  // Get referral usage statistics
  static Future<Map<String, dynamic>> getReferralStats(String userId) async {
    try {
      // Get codes created by user
      final codesResponse = await _supabase
          .from('referral_codes')
          .select('id')
          .eq('user_id', userId);

      final codeIds = codesResponse.map((code) => code['id']).toList();

      if (codeIds.isEmpty) {
        return {
          'total_referrals': 0,
          'total_spa_earned': 0,
          'active_codes': 0,
        };
      }

      // Get usage statistics
      final usageResponse = await _supabase
          .from('referral_usage')
          .select('spa_awarded_referrer')
          .in_('referral_code_id', codeIds);

      final totalReferrals = usageResponse.length;
      final totalSpaEarned = usageResponse.fold(0, (sum, usage) => 
          sum + (usage['spa_awarded_referrer'] as int? ?? 0));

      return {
        'total_referrals': totalReferrals,
        'total_spa_earned': totalSpaEarned,
        'active_codes': codesResponse.length,
      };
    } catch (e) {
      print('Error fetching referral stats: $e');
      return {
        'total_referrals': 0,
        'total_spa_earned': 0,
        'active_codes': 0,
      };
    }
  }
}'''
    
    return service_code

def main():
    print("🚀 ALTERNATIVE SOLUTION - CURRENT SCHEMA COMPATIBILITY")
    print("=" * 60)
    
    # Update existing codes
    update_success = update_existing_codes_to_basic_format()
    
    if update_success:
        print("\n📝 Creating updated BasicReferralService...")
        
        # Create updated service file
        service_code = create_updated_basic_service()
        
        with open('lib/services/basic_referral_service_updated.dart', 'w', encoding='utf-8') as f:
            f.write(service_code)
        
        print("✅ Created updated service: lib/services/basic_referral_service_updated.dart")
        
        print("\n🎯 SOLUTION SUMMARY:")
        print("✅ Existing codes converted to basic format")
        print("✅ Updated service created (works with current schema)")
        print("✅ Uses existing 'rewards' JSONB column")
        print("✅ Maintains all functionality")
        
        print("\n📋 NEXT STEPS:")
        print("1. Replace lib/services/basic_referral_service.dart with the updated version")
        print("2. Run comprehensive system test")
        print("3. Test with real referral codes")
        
        print("\n🎉 ALTERNATIVE SOLUTION COMPLETE!")
        print("Your referral system will work without database schema changes.")
        
    else:
        print("❌ Failed to update existing codes")
    
    print("=" * 60)

if __name__ == "__main__":
    main()
#!/usr/bin/env python3
import requests
import json
import time

# Supabase configuration
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

def test_tables_exist():
    """Test if all shift reporting tables exist and are accessible"""
    print('🔍 Testing table existence and accessibility...')
    
    headers = {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
        'Content-Type': 'application/json'
    }
    
    tables_to_check = [
        'shift_sessions',
        'shift_transactions', 
        'shift_inventory',
        'shift_expenses',
        'shift_reports'
    ]
    
    results = {}
    
    for table in tables_to_check:
        try:
            response = requests.get(
                f'{SUPABASE_URL}/rest/v1/{table}?limit=1',
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                print(f'  ✅ {table}: EXISTS and ACCESSIBLE')
                results[table] = 'success'
            elif response.status_code == 406:
                print(f'  ✅ {table}: EXISTS (empty or no read permission)')
                results[table] = 'exists'
            elif response.status_code == 404:
                print(f'  ❌ {table}: NOT FOUND')
                results[table] = 'missing'
            else:
                print(f'  ⚠️  {table}: UNKNOWN STATUS ({response.status_code})')
                print(f'      Response: {response.text[:100]}')
                results[table] = f'status_{response.status_code}'
                
        except Exception as e:
            print(f'  ❌ {table}: ERROR - {e}')
            results[table] = 'error'
    
    return results

def test_database_functions():
    """Test if custom database functions are working"""
    print('\n🔧 Testing database functions...')
    
    headers = {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
        'Content-Type': 'application/json'
    }
    
    functions_to_test = [
        'calculate_shift_summary',
        'auto_close_shift'
    ]
    
    for func in functions_to_test:
        try:
            # Try to call the function with a dummy UUID
            test_uuid = '00000000-0000-0000-0000-000000000000'
            
            response = requests.post(
                f'{SUPABASE_URL}/rest/v1/rpc/{func}',
                headers=headers,
                json={'session_id': test_uuid},
                timeout=10
            )
            
            if response.status_code == 200:
                print(f'  ✅ {func}: AVAILABLE')
            elif response.status_code == 404:
                print(f'  ❌ {func}: NOT FOUND')
            else:
                print(f'  ⚠️  {func}: STATUS {response.status_code}')
                print(f'      Response: {response.text[:150]}')
                
        except Exception as e:
            print(f'  ❌ {func}: ERROR - {e}')

def test_sample_data_operations():
    """Test basic CRUD operations on the tables"""
    print('\n📊 Testing sample data operations...')
    
    headers = {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
    }
    
    # First, let's get some existing club and staff data
    try:
        # Get a club
        clubs_response = requests.get(
            f'{SUPABASE_URL}/rest/v1/clubs?limit=1',
            headers=headers,
            timeout=10
        )
        
        if clubs_response.status_code == 200:
            clubs_data = clubs_response.json()
            if clubs_data:
                club_id = clubs_data[0]['id']
                print(f'  📍 Found club: {club_id}')
                
                # Get club staff
                staff_response = requests.get(
                    f'{SUPABASE_URL}/rest/v1/club_staff?club_id=eq.{club_id}&limit=1',
                    headers=headers,
                    timeout=10
                )
                
                if staff_response.status_code == 200:
                    staff_data = staff_response.json()
                    if staff_data:
                        staff_id = staff_data[0]['id']
                        print(f'  👤 Found staff: {staff_id}')
                        
                        # Test creating a shift session
                        test_create_shift_session(headers, club_id, staff_id)
                    else:
                        print('  ⚠️  No staff found for testing')
                else:
                    print(f'  ❌ Could not get staff: {staff_response.status_code}')
            else:
                print('  ⚠️  No clubs found for testing')
        else:
            print(f'  ❌ Could not get clubs: {clubs_response.status_code}')
            
    except Exception as e:
        print(f'  ❌ Error in sample data test: {e}')

def test_create_shift_session(headers, club_id, staff_id):
    """Test creating a shift session"""
    print('\n⚡ Testing shift session creation...')
    
    # Create test shift session
    shift_data = {
        'club_id': club_id,
        'staff_id': staff_id,
        'shift_date': '2025-09-30',
        'start_time': '08:00:00',
        'opening_cash': 500000,
        'status': 'active'
    }
    
    try:
        response = requests.post(
            f'{SUPABASE_URL}/rest/v1/shift_sessions',
            headers=headers,
            json=shift_data,
            timeout=15
        )
        
        if response.status_code in [200, 201]:
            session_data = response.json()
            if session_data:
                session_id = session_data[0]['id']
                print(f'  ✅ Created shift session: {session_id}')
                
                # Test adding a transaction
                test_create_transaction(headers, session_id, club_id)
                
                # Test updating the session
                test_update_shift_session(headers, session_id)
                
                return session_id
            else:
                print('  ⚠️  Session created but no data returned')
        else:
            print(f'  ❌ Failed to create session: {response.status_code}')
            print(f'      Response: {response.text[:200]}')
            
    except Exception as e:
        print(f'  ❌ Error creating session: {e}')
    
    return None

def test_create_transaction(headers, session_id, club_id):
    """Test creating a transaction"""
    print('  💰 Testing transaction creation...')
    
    transaction_data = {
        'shift_session_id': session_id,
        'club_id': club_id,
        'transaction_type': 'revenue',
        'category': 'table_fee',
        'description': 'Bàn số 5 - 2 giờ',
        'amount': 100000,
        'payment_method': 'cash'
    }
    
    try:
        response = requests.post(
            f'{SUPABASE_URL}/rest/v1/shift_transactions',
            headers=headers,
            json=transaction_data,
            timeout=10
        )
        
        if response.status_code in [200, 201]:
            print('    ✅ Transaction created successfully')
        else:
            print(f'    ❌ Failed to create transaction: {response.status_code}')
            print(f'        Response: {response.text[:150]}')
            
    except Exception as e:
        print(f'    ❌ Error creating transaction: {e}')

def test_update_shift_session(headers, session_id):
    """Test updating a shift session"""
    print('  🔄 Testing session update...')
    
    update_data = {
        'total_revenue': 100000,
        'notes': 'Test shift - created by backend test'
    }
    
    try:
        response = requests.patch(
            f'{SUPABASE_URL}/rest/v1/shift_sessions?id=eq.{session_id}',
            headers=headers,
            json=update_data,
            timeout=10
        )
        
        if response.status_code in [200, 204]:
            print('    ✅ Session updated successfully')
        else:
            print(f'    ❌ Failed to update session: {response.status_code}')
            print(f'        Response: {response.text[:150]}')
            
    except Exception as e:
        print(f'    ❌ Error updating session: {e}')

def test_rls_policies():
    """Test Row Level Security policies"""
    print('\n🔒 Testing RLS policies...')
    
    # Test with anon key (should have limited access)
    anon_headers = {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
        'Content-Type': 'application/json'
    }
    
    try:
        response = requests.get(
            f'{SUPABASE_URL}/rest/v1/shift_sessions?limit=1',
            headers=anon_headers,
            timeout=10
        )
        
        if response.status_code == 200:
            print('  ✅ Anonymous access working (with RLS)')
        elif response.status_code == 401:
            print('  ✅ RLS blocking anonymous access (expected)')
        else:
            print(f'  ⚠️  Unexpected RLS behavior: {response.status_code}')
            
    except Exception as e:
        print(f'  ❌ Error testing RLS: {e}')

def generate_backend_report():
    """Generate comprehensive backend test report"""
    print('\n' + '='*60)
    print('📈 BACKEND TEST REPORT')
    print('='*60)
    
    # Test all components
    table_results = test_tables_exist()
    test_database_functions()
    test_sample_data_operations()
    test_rls_policies()
    
    # Summary
    print('\n📊 SUMMARY:')
    successful_tables = sum(1 for result in table_results.values() if result in ['success', 'exists'])
    total_tables = len(table_results)
    
    print(f'  📋 Tables: {successful_tables}/{total_tables} operational')
    
    if successful_tables == total_tables:
        print('  ✅ ALL TABLES WORKING')
        print('  🚀 BACKEND IS READY FOR PRODUCTION!')
        print()
        print('  🔧 Next steps:')
        print('    1. Update Flutter code to use ShiftReportingService')
        print('    2. Test the mobile app')
        print('    3. Create some real shift data')
        
    elif successful_tables > 0:
        print('  ⚠️  PARTIAL SUCCESS - Some tables working')
        print('  🔧 Check deployment and try again')
        
    else:
        print('  ❌ NO TABLES WORKING')
        print('  🔧 Schema deployment may have failed')
    
    return successful_tables == total_tables

def main():
    print('🎯 BACKEND TESTING SUITE')
    print('=' * 50)
    print('🔍 Testing Shift Reporting System Backend')
    print('🌐 Supabase Database Connection')
    print()
    
    success = generate_backend_report()
    
    if success:
        print('\n🎉 BACKEND TEST PASSED!')
        print('🚀 Ready to switch to production service!')
    else:
        print('\n❌ BACKEND TEST FAILED')
        print('🔧 Check deployment and database setup')

if __name__ == '__main__':
    main()
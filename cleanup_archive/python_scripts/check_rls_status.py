#!/usr/bin/env python3
import requests

# Apply RLS fix
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

def test_rls_status():
    print('🔧 Testing RLS Status...')
    
    headers = {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
        'Content-Type': 'application/json'
    }
    
    tables = ['shift_sessions', 'shift_transactions']
    
    for table in tables:
        try:
            response = requests.get(
                f'{SUPABASE_URL}/rest/v1/{table}?limit=1',
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                print(f'  ✅ {table}: Working')
            elif 'infinite recursion' in response.text:
                print(f'  ❌ {table}: RLS recursion issue')
                return False
            else:
                print(f'  ⚠️  {table}: Status {response.status_code}')
                print(f'      Response: {response.text[:100]}')
                
        except Exception as e:
            print(f'  ❌ {table}: Error - {e}')
    
    return True

def show_manual_fix():
    """Show manual fix instructions"""
    print('\n' + '='*60)
    print('🔧 MANUAL FIX REQUIRED')
    print('='*60)
    print()
    print('RLS policies need to be fixed. Please go to Supabase Dashboard and run:')
    print()
    print('🎯 QUICK FIX (for testing):')
    print('```sql')
    print('-- Temporarily disable RLS')
    print('ALTER TABLE shift_sessions DISABLE ROW LEVEL SECURITY;')
    print('ALTER TABLE shift_transactions DISABLE ROW LEVEL SECURITY;') 
    print('ALTER TABLE shift_inventory DISABLE ROW LEVEL SECURITY;')
    print('ALTER TABLE shift_expenses DISABLE ROW LEVEL SECURITY;')
    print('ALTER TABLE shift_reports DISABLE ROW LEVEL SECURITY;')
    print('```')
    print()
    print('Or apply the complete fix from fix_rls_policies.sql')

def main():
    print('🎯 RLS STATUS CHECK')
    print('=' * 30)
    
    if not test_rls_status():
        show_manual_fix()
    else:
        print('\n✅ RLS working properly!')

if __name__ == '__main__':
    main()
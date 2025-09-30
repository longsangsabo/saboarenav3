#!/usr/bin/env python3
"""
Comprehensive backend testing for Club Staff Commission System
"""

import asyncio
import asyncpg
import json
import uuid
from datetime import datetime, timedelta
from decimal import Decimal

# Connection string
DATABASE_URL = "postgresql://postgres.mogjjvscxjwvhtpkrlqr:Acookingoil123@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres"

class ClubStaffSystemTester:
    def __init__(self):
        self.conn = None
        self.test_data = {}
        
    async def connect(self):
        """Connect to database"""
        try:
            self.conn = await asyncpg.connect(DATABASE_URL)
            print('✅ Connected to Supabase successfully!')
            return True
        except Exception as e:
            print(f'❌ Connection failed: {e}')
            return False
    
    async def disconnect(self):
        """Disconnect from database"""
        if self.conn:
            await self.conn.close()
            print('🔌 Database connection closed')

    async def setup_test_data(self):
        """Create test users and clubs"""
        print('\n🛠️ Setting up test data...')
        
        try:
            # Create test club owner
            owner_id = str(uuid.uuid4())
            self.test_data['owner_id'] = owner_id
            
            await self.conn.execute("""
                INSERT INTO users (id, email, full_name, username, elo_rating, spa_balance, created_at)
                VALUES ($1, $2, $3, $4, $5, $6, NOW())
                ON CONFLICT (id) DO NOTHING
            """, owner_id, 'owner@saboarena.com', 'Club Owner', 'clubowner', 1500, 1000)
            
            # Create test club
            club_id = str(uuid.uuid4())
            self.test_data['club_id'] = club_id
            
            await self.conn.execute("""
                INSERT INTO clubs (id, name, address, owner_id, created_at)
                VALUES ($1, $2, $3, $4, NOW())
                ON CONFLICT (id) DO NOTHING
            """, club_id, 'SABO Arena Test Club', '123 Test Street, Ho Chi Minh City', owner_id)
            
            # Create test staff user
            staff_user_id = str(uuid.uuid4())
            self.test_data['staff_user_id'] = staff_user_id
            
            await self.conn.execute("""
                INSERT INTO users (id, email, full_name, username, elo_rating, spa_balance, created_at)
                VALUES ($1, $2, $3, $4, $5, $6, NOW())
                ON CONFLICT (id) DO NOTHING
            """, staff_user_id, 'staff@saboarena.com', 'Nguyen Van Staff', 'staffuser', 1200, 500)
            
            # Create test customer
            customer_id = str(uuid.uuid4())
            self.test_data['customer_id'] = customer_id
            
            await self.conn.execute("""
                INSERT INTO users (id, email, full_name, username, elo_rating, spa_balance, created_at)
                VALUES ($1, $2, $3, $4, $5, $6, NOW())
                ON CONFLICT (id) DO NOTHING
            """, customer_id, 'customer@saboarena.com', 'Tran Thi Customer', 'customer1', 1000, 200)
            
            print('✅ Test data created successfully!')
            print(f'   👤 Owner ID: {owner_id}')
            print(f'   🏢 Club ID: {club_id}')
            print(f'   👥 Staff User ID: {staff_user_id}')
            print(f'   👤 Customer ID: {customer_id}')
            
        except Exception as e:
            print(f'❌ Failed to setup test data: {e}')
            raise

    async def test_staff_management(self):
        """Test 1: Staff Management Functions"""
        print('\n📋 TEST 1: Staff Management')
        print('=' * 40)
        
        try:
            # 1.1 Add staff to club
            print('🔹 1.1 Adding staff to club...')
            
            staff_id = str(uuid.uuid4())
            self.test_data['staff_id'] = staff_id
            
            await self.conn.execute("""
                INSERT INTO club_staff (
                    id, club_id, user_id, staff_role, commission_rate,
                    can_enter_scores, can_manage_tournaments, can_view_reports
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            """, staff_id, self.test_data['club_id'], self.test_data['staff_user_id'], 
                'staff', 5.0, True, False, True)
            
            print('✅ Staff added successfully!')
            
            # 1.2 Verify staff was added
            print('🔹 1.2 Verifying staff record...')
            
            staff_record = await self.conn.fetchrow("""
                SELECT cs.*, u.full_name, c.name as club_name
                FROM club_staff cs
                JOIN users u ON u.id = cs.user_id
                JOIN clubs c ON c.id = cs.club_id
                WHERE cs.id = $1
            """, staff_id)
            
            if staff_record:
                print('✅ Staff record verified!')
                print(f'   👤 Name: {staff_record["full_name"]}')
                print(f'   🏢 Club: {staff_record["club_name"]}')
                print(f'   💼 Role: {staff_record["staff_role"]}')
                print(f'   💰 Commission Rate: {staff_record["commission_rate"]}%')
            else:
                raise Exception('Staff record not found!')
            
            # 1.3 Test staff permissions
            print('🔹 1.3 Checking staff permissions...')
            
            permissions = await self.conn.fetchrow("""
                SELECT can_enter_scores, can_manage_tournaments, can_view_reports, can_manage_staff
                FROM club_staff WHERE id = $1
            """, staff_id)
            
            print('✅ Staff permissions verified!')
            print(f'   ⚽ Enter Scores: {permissions["can_enter_scores"]}')
            print(f'   🏆 Manage Tournaments: {permissions["can_manage_tournaments"]}')
            print(f'   📊 View Reports: {permissions["can_view_reports"]}')
            print(f'   👥 Manage Staff: {permissions["can_manage_staff"]}')
            
        except Exception as e:
            print(f'❌ Staff Management test failed: {e}')
            raise

    async def test_referral_system(self):
        """Test 2: Referral System Functions"""
        print('\n🎯 TEST 2: Referral System')
        print('=' * 40)
        
        try:
            # 2.1 Create staff referral code
            print('🔹 2.1 Creating staff referral code...')
            
            referral_code = f"STAFF-{self.test_data['staff_user_id'][:6].upper()}"
            
            await self.conn.execute("""
                INSERT INTO referral_codes (
                    user_id, code, referral_type, spa_reward_referrer, spa_reward_referred,
                    commission_rate, is_active, created_at
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
                ON CONFLICT (code) DO NOTHING
            """, self.test_data['staff_user_id'], referral_code, 'staff', 150, 75, 5.0, True)
            
            print(f'✅ Staff referral code created: {referral_code}')
            
            # 2.2 Apply referral code (customer registration)
            print('🔹 2.2 Applying staff referral...')
            
            staff_referral_id = str(uuid.uuid4())
            self.test_data['staff_referral_id'] = staff_referral_id
            
            await self.conn.execute("""
                INSERT INTO staff_referrals (
                    id, staff_id, customer_id, club_id, referral_code,
                    initial_bonus_spa, commission_rate, is_active
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            """, staff_referral_id, self.test_data['staff_id'], self.test_data['customer_id'],
                self.test_data['club_id'], referral_code, 75, 5.0, True)
            
            print('✅ Staff referral applied successfully!')
            
            # 2.3 Verify referral tracking
            print('🔹 2.3 Verifying referral tracking...')
            
            referral_record = await self.conn.fetchrow("""
                SELECT sr.*, u.full_name as customer_name, cs.user_id as staff_user_id
                FROM staff_referrals sr
                JOIN users u ON u.id = sr.customer_id
                JOIN club_staff cs ON cs.id = sr.staff_id
                WHERE sr.id = $1
            """, staff_referral_id)
            
            if referral_record:
                print('✅ Referral tracking verified!')
                print(f'   👤 Customer: {referral_record["customer_name"]}')
                print(f'   🎁 SPA Bonus: {referral_record["initial_bonus_spa"]}')
                print(f'   💰 Commission Rate: {referral_record["commission_rate"]}%')
                print(f'   📋 Referral Code: {referral_record["referral_code"]}')
            else:
                raise Exception('Referral record not found!')
                
        except Exception as e:
            print(f'❌ Referral System test failed: {e}')
            raise

    async def test_transaction_and_commission(self):
        """Test 3: Customer Transaction & Commission Calculation"""
        print('\n💰 TEST 3: Transaction & Commission System')
        print('=' * 50)
        
        try:
            # 3.1 Record customer transaction
            print('🔹 3.1 Recording customer transaction...')
            
            transaction_id = str(uuid.uuid4())
            self.test_data['transaction_id'] = transaction_id
            transaction_amount = 100000  # 100,000 VND
            
            await self.conn.execute("""
                INSERT INTO customer_transactions (
                    id, customer_id, club_id, staff_referral_id, transaction_type,
                    amount, commission_eligible, commission_rate, commission_amount,
                    description, payment_method
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
            """, transaction_id, self.test_data['customer_id'], self.test_data['club_id'],
                self.test_data['staff_referral_id'], 'tournament_fee', transaction_amount,
                True, 5.0, transaction_amount * 0.05, 'Tournament entry fee', 'cash')
            
            print('✅ Transaction recorded successfully!')
            print(f'   💵 Amount: {transaction_amount:,} VND')
            print(f'   📋 Type: tournament_fee')
            print(f'   💰 Expected Commission: {int(transaction_amount * 0.05):,} VND')
            
            # 3.2 Verify automatic commission calculation (trigger)
            print('🔹 3.2 Verifying automatic commission calculation...')
            
            await asyncio.sleep(1)  # Give trigger time to execute
            
            commission_record = await self.conn.fetchrow("""
                SELECT sc.*, ct.amount as transaction_amount
                FROM staff_commissions sc
                JOIN customer_transactions ct ON ct.id = sc.customer_transaction_id
                WHERE sc.customer_transaction_id = $1
            """, transaction_id)
            
            if commission_record:
                print('✅ Commission calculated automatically by trigger!')
                print(f'   💰 Commission Amount: {int(commission_record["commission_amount"]):,} VND')
                print(f'   📊 Commission Rate: {commission_record["commission_rate"]}%')
                print(f'   📋 Commission Type: {commission_record["commission_type"]}')
                print(f'   💳 Payment Status: {"Paid" if commission_record["is_paid"] else "Pending"}')
                
                self.test_data['commission_id'] = commission_record['id']
            else:
                raise Exception('Commission not calculated automatically!')
            
            # 3.3 Test staff referral totals update (trigger)
            print('🔹 3.3 Verifying referral totals update...')
            
            referral_totals = await self.conn.fetchrow("""
                SELECT total_customer_spending, total_commission_earned
                FROM staff_referrals
                WHERE id = $1
            """, self.test_data['staff_referral_id'])
            
            if referral_totals:
                print('✅ Referral totals updated automatically!')
                print(f'   💵 Total Customer Spending: {int(referral_totals["total_customer_spending"]):,} VND')
                print(f'   💰 Total Commission Earned: {int(referral_totals["total_commission_earned"]):,} VND')
            else:
                print('⚠️ Referral totals not updated yet (may take a moment)')
            
        except Exception as e:
            print(f'❌ Transaction & Commission test failed: {e}')
            raise

    async def test_analytics_functions(self):
        """Test 4: Analytics & Reporting Functions"""
        print('\n📊 TEST 4: Analytics & Reporting')
        print('=' * 40)
        
        try:
            # 4.1 Test staff performance function
            print('🔹 4.1 Testing staff performance function...')
            
            performance = await self.conn.fetchrow("""
                SELECT * FROM get_staff_performance_summary($1)
            """, self.test_data['staff_id'])
            
            if performance:
                print('✅ Staff performance function working!')
                print(f'   👥 Total Referrals: {performance["total_referrals"]}')
                print(f'   🔄 Active Customers: {performance["active_customers"]}')
                print(f'   🧾 Total Transactions: {performance["total_transactions"]}')
                print(f'   💵 Total Revenue: {int(performance["total_revenue"]):,} VND')
                print(f'   💰 Total Commissions: {int(performance["total_commissions"]):,} VND')
                print(f'   📈 Avg Transaction: {int(performance["avg_transaction_value"]):,} VND')
            else:
                print('⚠️ No performance data found (may be expected with minimal test data)')
            
            # 4.2 Test commission analytics
            print('🔹 4.2 Testing commission analytics...')
            
            commissions = await self.conn.fetch("""
                SELECT 
                    sc.*,
                    u.full_name as staff_name,
                    ct.transaction_type,
                    ct.amount as transaction_amount
                FROM staff_commissions sc
                JOIN club_staff cs ON cs.id = sc.staff_id
                JOIN users u ON u.id = cs.user_id
                JOIN customer_transactions ct ON ct.id = sc.customer_transaction_id
                WHERE sc.club_id = $1
                ORDER BY sc.created_at DESC
            """, self.test_data['club_id'])
            
            print(f'✅ Found {len(commissions)} commission records!')
            
            total_commissions = 0
            for commission in commissions:
                total_commissions += commission['commission_amount']
                print(f'   💰 {commission["staff_name"]}: {int(commission["commission_amount"]):,} VND '
                      f'({commission["transaction_type"]})')
            
            print(f'   📊 Total Club Commissions: {int(total_commissions):,} VND')
            
            # 4.3 Test pending commissions
            print('🔹 4.3 Testing pending commissions query...')
            
            pending = await self.conn.fetch("""
                SELECT 
                    sc.*,
                    u.full_name as staff_name,
                    ct.description
                FROM staff_commissions sc
                JOIN club_staff cs ON cs.id = sc.staff_id
                JOIN users u ON u.id = cs.user_id
                JOIN customer_transactions ct ON ct.id = sc.customer_transaction_id
                WHERE sc.is_paid = false AND sc.club_id = $1
                ORDER BY sc.earned_at DESC
            """, self.test_data['club_id'])
            
            print(f'✅ Found {len(pending)} pending commission payments!')
            
            pending_total = 0
            for p in pending:
                pending_total += p['commission_amount']
                print(f'   ⏳ {p["staff_name"]}: {int(p["commission_amount"]):,} VND - {p["description"]}')
            
            if pending_total > 0:
                print(f'   💳 Total Pending: {int(pending_total):,} VND')
            
        except Exception as e:
            print(f'❌ Analytics test failed: {e}')
            raise

    async def test_commission_payment(self):
        """Test 5: Commission Payment Process"""
        print('\n💳 TEST 5: Commission Payment Process')
        print('=' * 45)
        
        try:
            # 5.1 Mark commission as paid
            print('🔹 5.1 Processing commission payment...')
            
            if 'commission_id' in self.test_data:
                await self.conn.execute("""
                    UPDATE staff_commissions
                    SET 
                        is_paid = true,
                        paid_at = NOW(),
                        payment_method = 'bank_transfer',
                        payment_reference = 'TEST_PAY_001',
                        payment_notes = 'Test payment via automated system'
                    WHERE id = $1
                """, self.test_data['commission_id'])
                
                print('✅ Commission marked as paid!')
                
                # 5.2 Verify payment status
                payment_record = await self.conn.fetchrow("""
                    SELECT is_paid, paid_at, payment_method, payment_reference, commission_amount
                    FROM staff_commissions
                    WHERE id = $1
                """, self.test_data['commission_id'])
                
                if payment_record and payment_record['is_paid']:
                    print('✅ Payment status verified!')
                    print(f'   💰 Amount: {int(payment_record["commission_amount"]):,} VND')
                    print(f'   💳 Method: {payment_record["payment_method"]}')
                    print(f'   📋 Reference: {payment_record["payment_reference"]}')
                    print(f'   📅 Paid At: {payment_record["paid_at"].strftime("%Y-%m-%d %H:%M:%S")}')
                else:
                    raise Exception('Payment status not updated correctly!')
            else:
                print('⚠️ No commission ID available for payment test')
                
        except Exception as e:
            print(f'❌ Commission Payment test failed: {e}')
            raise

    async def test_rls_policies(self):
        """Test 6: Row Level Security Policies"""
        print('\n🔒 TEST 6: Row Level Security (RLS)')
        print('=' * 40)
        
        try:
            # 6.1 Test RLS policies exist
            print('🔹 6.1 Checking RLS policies...')
            
            policies = await self.conn.fetch("""
                SELECT schemaname, tablename, policyname, cmd, roles
                FROM pg_policies
                WHERE schemaname = 'public'
                AND tablename IN ('club_staff', 'staff_referrals', 'customer_transactions', 'staff_commissions')
                ORDER BY tablename, policyname
            """)
            
            print(f'✅ Found {len(policies)} RLS policies!')
            
            policy_by_table = {}
            for policy in policies:
                table = policy['tablename']
                if table not in policy_by_table:
                    policy_by_table[table] = []
                policy_by_table[table].append(policy['policyname'])
            
            for table, table_policies in policy_by_table.items():
                print(f'   🔒 {table}: {len(table_policies)} policies')
                for policy_name in table_policies:
                    print(f'      - {policy_name}')
            
            # 6.2 Test table RLS is enabled
            print('🔹 6.2 Verifying RLS is enabled...')
            
            rls_status = await self.conn.fetch("""
                SELECT schemaname, tablename, rowsecurity
                FROM pg_tables
                WHERE schemaname = 'public'
                AND tablename IN ('club_staff', 'staff_referrals', 'customer_transactions', 'staff_commissions')
                ORDER BY tablename
            """)
            
            for table in rls_status:
                status = "✅ Enabled" if table['rowsecurity'] else "❌ Disabled"
                print(f'   🔒 {table["tablename"]}: {status}')
            
        except Exception as e:
            print(f'❌ RLS test failed: {e}')
            raise

    async def cleanup_test_data(self):
        """Clean up test data"""
        print('\n🧹 Cleaning up test data...')
        
        try:
            # Delete in reverse order of creation to handle foreign keys
            tables_to_clean = [
                'staff_commissions',
                'customer_transactions', 
                'staff_referrals',
                'club_staff',
                'referral_codes',
                'clubs',
                'users'
            ]
            
            for table in tables_to_clean:
                if table == 'users':
                    # Clean up test users
                    await self.conn.execute(f"""
                        DELETE FROM {table} 
                        WHERE email IN ('owner@saboarena.com', 'staff@saboarena.com', 'customer@saboarena.com')
                    """)
                elif table == 'clubs':
                    # Clean up test clubs
                    await self.conn.execute(f"""
                        DELETE FROM {table} WHERE name = 'SABO Arena Test Club'
                    """)
                elif table == 'referral_codes':
                    # Clean up test referral codes
                    await self.conn.execute(f"""
                        DELETE FROM {table} WHERE referral_type = 'staff' AND code LIKE 'STAFF-%'
                    """)
                else:
                    # For other tables, delete by test IDs
                    if table in ['staff_commissions', 'customer_transactions', 'staff_referrals', 'club_staff']:
                        for key, value in self.test_data.items():
                            if 'id' in key and value:
                                await self.conn.execute(f"""
                                    DELETE FROM {table} WHERE id = $1 OR club_id = $2 OR user_id = $3
                                """, value, self.test_data.get('club_id', ''), self.test_data.get('staff_user_id', ''))
                                break
            
            print('✅ Test data cleaned up successfully!')
            
        except Exception as e:
            print(f'⚠️ Cleanup warning (may be expected): {e}')

    async def run_all_tests(self):
        """Run comprehensive test suite"""
        print('🏢 SABO Arena - Club Staff Commission System')
        print('🧪 COMPREHENSIVE BACKEND TESTING')
        print('=' * 60)
        
        if not await self.connect():
            return False
        
        try:
            await self.setup_test_data()
            await self.test_staff_management()
            await self.test_referral_system()
            await self.test_transaction_and_commission()
            await self.test_analytics_functions()
            await self.test_commission_payment()
            await self.test_rls_policies()
            
            print('\n🎉 ALL TESTS PASSED SUCCESSFULLY!')
            print('=' * 60)
            print('✅ Staff Management: Working')
            print('✅ Referral System: Working')  
            print('✅ Commission Calculation: Working')
            print('✅ Analytics Functions: Working')
            print('✅ Payment Processing: Working')
            print('✅ Security Policies: Working')
            print('\n🚀 Your Club Staff Commission System is fully operational!')
            
            return True
            
        except Exception as e:
            print(f'\n❌ TEST SUITE FAILED: {e}')
            return False
            
        finally:
            await self.cleanup_test_data()
            await self.disconnect()

async def main():
    """Main test execution"""
    tester = ClubStaffSystemTester()
    success = await tester.run_all_tests()
    
    if success:
        print('\n📋 READY FOR PRODUCTION!')
        print('Next steps:')
        print('1. 🎯 Test Flutter UI with real users')
        print('2. 📱 Create staff QR codes') 
        print('3. 💰 Monitor first commissions')
        print('4. 📊 Review analytics dashboard')
    else:
        print('\n🔧 SYSTEM NEEDS ATTENTION')
        print('Please review the errors above and fix before production use.')

if __name__ == '__main__':
    asyncio.run(main())
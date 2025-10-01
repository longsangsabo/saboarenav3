#!/usr/bin/env python3
"""
Script to apply club staff commission system to Supabase database
"""

import os
import asyncio
import httpx
from typing import Dict, Any

# Supabase configuration from environment or defaults
SUPABASE_URL = os.getenv('SUPABASE_URL', 'https://mogjjvscxjwvhtpkrlqr.supabase.co')
SUPABASE_ANON_KEY = os.getenv('SUPABASE_ANON_KEY', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ')

class SupabaseClient:
    def __init__(self, url: str, key: str):
        self.url = url
        self.key = key
        self.headers = {
            'apikey': key,
            'Authorization': f'Bearer {key}',
            'Content-Type': 'application/json',
        }
    
    async def execute_sql(self, sql: str) -> Dict[str, Any]:
        """Execute SQL command via Supabase RPC"""
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f'{self.url}/rest/v1/rpc/exec_sql',
                    headers=self.headers,
                    json={'sql': sql},
                    timeout=30.0
                )
                
                if response.status_code == 200:
                    return {'success': True, 'data': response.json()}
                else:
                    return {
                        'success': False, 
                        'error': f'HTTP {response.status_code}: {response.text}'
                    }
                    
            except Exception as e:
                return {'success': False, 'error': str(e)}

async def apply_club_staff_system():
    """Apply the complete club staff commission system to database"""
    print('🚀 Starting Club Staff Commission System setup...')
    
    client = SupabaseClient(SUPABASE_URL, SUPABASE_ANON_KEY)
    
    # SQL commands to execute
    sql_commands = [
        # 1. Create club_staff table
        """
        CREATE TABLE IF NOT EXISTS club_staff (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            staff_role VARCHAR(50) DEFAULT 'staff',
            commission_rate DECIMAL(5,2) DEFAULT 5.00,
            can_enter_scores BOOLEAN DEFAULT true,
            can_manage_tournaments BOOLEAN DEFAULT false,
            can_view_reports BOOLEAN DEFAULT false,
            can_manage_staff BOOLEAN DEFAULT false,
            hired_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
            terminated_at TIMESTAMP WITH TIME ZONE,
            is_active BOOLEAN DEFAULT true,
            notes TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
            UNIQUE(club_id, user_id)
        );
        """,
        
        # 2. Create staff_referrals table
        """
        CREATE TABLE IF NOT EXISTS staff_referrals (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            staff_id UUID NOT NULL REFERENCES club_staff(id) ON DELETE CASCADE,
            customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
            referral_method VARCHAR(50) DEFAULT 'qr_code',
            referral_code VARCHAR(100),
            referred_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
            initial_bonus_spa INTEGER DEFAULT 0,
            commission_rate DECIMAL(5,2) DEFAULT 5.00,
            total_customer_spending DECIMAL(15,2) DEFAULT 0,
            total_commission_earned DECIMAL(15,2) DEFAULT 0,
            is_active BOOLEAN DEFAULT true,
            notes TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
            UNIQUE(staff_id, customer_id)
        );
        """,
        
        # 3. Create customer_transactions table
        """
        CREATE TABLE IF NOT EXISTS customer_transactions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
            staff_referral_id UUID REFERENCES staff_referrals(id) ON DELETE SET NULL,
            transaction_type VARCHAR(50) NOT NULL,
            amount DECIMAL(15,2) NOT NULL,
            commission_eligible BOOLEAN DEFAULT true,
            commission_rate DECIMAL(5,2) DEFAULT 0,
            commission_amount DECIMAL(15,2) DEFAULT 0,
            tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
            match_id UUID REFERENCES matches(id) ON DELETE SET NULL,
            description TEXT,
            payment_method VARCHAR(50),
            transaction_date TIMESTAMP WITH TIME ZONE DEFAULT now(),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
        );
        """,
        
        # 4. Create staff_commissions table
        """
        CREATE TABLE IF NOT EXISTS staff_commissions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            staff_id UUID NOT NULL REFERENCES club_staff(id) ON DELETE CASCADE,
            club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
            customer_transaction_id UUID NOT NULL REFERENCES customer_transactions(id) ON DELETE CASCADE,
            commission_type VARCHAR(50) NOT NULL,
            commission_rate DECIMAL(5,2) NOT NULL,
            transaction_amount DECIMAL(15,2) NOT NULL,
            commission_amount DECIMAL(15,2) NOT NULL,
            is_paid BOOLEAN DEFAULT false,
            paid_at TIMESTAMP WITH TIME ZONE,
            payment_method VARCHAR(50),
            payment_reference VARCHAR(255),
            payment_notes TEXT,
            earned_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
        );
        """,
        
        # 5. Create staff_performance table
        """
        CREATE TABLE IF NOT EXISTS staff_performance (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            staff_id UUID NOT NULL REFERENCES club_staff(id) ON DELETE CASCADE,
            club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
            period_start DATE NOT NULL,
            period_end DATE NOT NULL,
            total_referrals INTEGER DEFAULT 0,
            active_customers INTEGER DEFAULT 0,
            total_transactions INTEGER DEFAULT 0,
            total_revenue_generated DECIMAL(15,2) DEFAULT 0,
            total_commissions_earned DECIMAL(15,2) DEFAULT 0,
            avg_transaction_value DECIMAL(15,2) DEFAULT 0,
            performance_score DECIMAL(5,2) DEFAULT 0,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
            UNIQUE(staff_id, period_start, period_end)
        );
        """,
        
        # 6. Create indexes for performance
        """
        CREATE INDEX IF NOT EXISTS idx_club_staff_club_user ON club_staff(club_id, user_id);
        CREATE INDEX IF NOT EXISTS idx_staff_referrals_staff ON staff_referrals(staff_id);
        CREATE INDEX IF NOT EXISTS idx_staff_referrals_customer ON staff_referrals(customer_id);
        CREATE INDEX IF NOT EXISTS idx_customer_transactions_customer ON customer_transactions(customer_id);
        CREATE INDEX IF NOT EXISTS idx_customer_transactions_club ON customer_transactions(club_id);
        CREATE INDEX IF NOT EXISTS idx_staff_commissions_staff ON staff_commissions(staff_id);
        CREATE INDEX IF NOT EXISTS idx_staff_commissions_unpaid ON staff_commissions(staff_id, is_paid);
        """,
        
        # 7. Enable RLS
        """
        ALTER TABLE club_staff ENABLE ROW LEVEL SECURITY;
        ALTER TABLE staff_referrals ENABLE ROW LEVEL SECURITY;
        ALTER TABLE customer_transactions ENABLE ROW LEVEL SECURITY;
        ALTER TABLE staff_commissions ENABLE ROW LEVEL SECURITY;
        ALTER TABLE staff_performance ENABLE ROW LEVEL SECURITY;
        """,
    ]
    
    # Execute each SQL command
    for i, sql in enumerate(sql_commands, 1):
        print(f'📋 Executing step {i}/{len(sql_commands)}...')
        
        result = await client.execute_sql(sql.strip())
        
        if result['success']:
            print(f'   ✅ Step {i} completed successfully')
        else:
            print(f'   ❌ Step {i} failed: {result["error"]}')
            print(f'      SQL: {sql[:100]}...')
            
    # Create RLS policies
    await create_rls_policies(client)
    
    # Create functions and triggers
    await create_functions_and_triggers(client)
    
    print('\n✅ Club Staff Commission System setup completed!')
    print('')
    print('📋 Created tables:')
    print('   - club_staff (staff management)')
    print('   - staff_referrals (customer tracking)')
    print('   - customer_transactions (spending records)')
    print('   - staff_commissions (earnings tracking)')
    print('   - staff_performance (analytics)')
    print('')
    print('🔧 Created functions:')
    print('   - calculate_staff_commission()')
    print('   - update_staff_referral_totals()')
    print('')
    print('⚡ Created triggers:')
    print('   - Auto commission calculation')
    print('   - Staff referral totals update')

async def create_rls_policies(client: SupabaseClient):
    """Create Row Level Security policies"""
    print('🔒 Setting up RLS policies...')
    
    policies = [
        # Club staff policies
        """
        DROP POLICY IF EXISTS "Users can view club staff where they are involved" ON club_staff;
        CREATE POLICY "Users can view club staff where they are involved" ON club_staff
        FOR SELECT USING (
            user_id = auth.uid() OR 
            club_id IN (
                SELECT id FROM clubs WHERE owner_id = auth.uid()
            ) OR
            club_id IN (
                SELECT club_id FROM club_staff 
                WHERE user_id = auth.uid() AND staff_role IN ('owner', 'manager')
            )
        );
        """,
        
        """
        DROP POLICY IF EXISTS "Club owners can manage staff" ON club_staff;
        CREATE POLICY "Club owners can manage staff" ON club_staff
        FOR ALL USING (
            club_id IN (
                SELECT id FROM clubs WHERE owner_id = auth.uid()
            ) OR
            club_id IN (
                SELECT club_id FROM club_staff 
                WHERE user_id = auth.uid() AND staff_role IN ('owner', 'manager')
            )
        );
        """,
        
        # Staff referrals policies
        """
        DROP POLICY IF EXISTS "Staff can view their referrals" ON staff_referrals;
        CREATE POLICY "Staff can view their referrals" ON staff_referrals
        FOR SELECT USING (
            staff_id IN (SELECT id FROM club_staff WHERE user_id = auth.uid()) OR
            customer_id = auth.uid() OR
            club_id IN (SELECT id FROM clubs WHERE owner_id = auth.uid())
        );
        """,
        
        """
        DROP POLICY IF EXISTS "Staff can manage their referrals" ON staff_referrals;
        CREATE POLICY "Staff can manage their referrals" ON staff_referrals
        FOR ALL USING (
            staff_id IN (SELECT id FROM club_staff WHERE user_id = auth.uid()) OR
            club_id IN (SELECT id FROM clubs WHERE owner_id = auth.uid())
        );
        """,
        
        # Customer transactions policies
        """
        DROP POLICY IF EXISTS "Users can view transactions where involved" ON customer_transactions;
        CREATE POLICY "Users can view transactions where involved" ON customer_transactions
        FOR SELECT USING (
            customer_id = auth.uid() OR
            club_id IN (SELECT id FROM clubs WHERE owner_id = auth.uid()) OR
            club_id IN (
                SELECT club_id FROM club_staff 
                WHERE user_id = auth.uid() AND (staff_role IN ('owner', 'manager') OR can_view_reports = true)
            )
        );
        """,
        
        """
        DROP POLICY IF EXISTS "Staff can record transactions" ON customer_transactions;
        CREATE POLICY "Staff can record transactions" ON customer_transactions
        FOR INSERT WITH CHECK (
            club_id IN (SELECT id FROM clubs WHERE owner_id = auth.uid()) OR
            club_id IN (
                SELECT club_id FROM club_staff 
                WHERE user_id = auth.uid() AND is_active = true
            )
        );
        """,
        
        # Staff commissions policies
        """
        DROP POLICY IF EXISTS "Staff can view their commissions" ON staff_commissions;
        CREATE POLICY "Staff can view their commissions" ON staff_commissions
        FOR SELECT USING (
            staff_id IN (SELECT id FROM club_staff WHERE user_id = auth.uid()) OR
            club_id IN (SELECT id FROM clubs WHERE owner_id = auth.uid()) OR
            club_id IN (
                SELECT club_id FROM club_staff 
                WHERE user_id = auth.uid() AND (staff_role IN ('owner', 'manager') OR can_view_reports = true)
            )
        );
        """,
        
        """
        DROP POLICY IF EXISTS "Club owners can manage commissions" ON staff_commissions;
        CREATE POLICY "Club owners can manage commissions" ON staff_commissions
        FOR ALL USING (
            club_id IN (SELECT id FROM clubs WHERE owner_id = auth.uid()) OR
            club_id IN (
                SELECT club_id FROM club_staff 
                WHERE user_id = auth.uid() AND staff_role IN ('owner', 'manager')
            )
        );
        """,
    ]
    
    for i, policy in enumerate(policies, 1):
        result = await client.execute_sql(policy.strip())
        if result['success']:
            print(f'   ✅ RLS policy {i}/{len(policies)} created')
        else:
            print(f'   ❌ RLS policy {i}/{len(policies)} failed: {result["error"]}')

async def create_functions_and_triggers(client: SupabaseClient):
    """Create database functions and triggers"""
    print('⚙️ Creating functions and triggers...')
    
    functions = [
        # Commission calculation function
        """
        CREATE OR REPLACE FUNCTION calculate_staff_commission()
        RETURNS TRIGGER AS $$
        BEGIN
            -- Only calculate if transaction is commission eligible and has staff referral
            IF NEW.commission_eligible = true AND NEW.staff_referral_id IS NOT NULL THEN
                -- Insert commission record
                INSERT INTO staff_commissions (
                    staff_id,
                    club_id,
                    customer_transaction_id,
                    commission_type,
                    commission_rate,
                    transaction_amount,
                    commission_amount
                )
                SELECT 
                    sr.staff_id,
                    NEW.club_id,
                    NEW.id,
                    CASE NEW.transaction_type
                        WHEN 'tournament_fee' THEN 'tournament_commission'
                        WHEN 'spa_purchase' THEN 'spa_commission'
                        WHEN 'equipment_rental' THEN 'rental_commission'
                        WHEN 'membership_fee' THEN 'membership_commission'
                        ELSE 'other_commission'
                    END,
                    sr.commission_rate,
                    NEW.amount,
                    NEW.amount * (sr.commission_rate / 100)
                FROM staff_referrals sr
                WHERE sr.id = NEW.staff_referral_id;
            END IF;

            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
        """,
        
        # Update referral totals function
        """
        CREATE OR REPLACE FUNCTION update_staff_referral_totals()
        RETURNS TRIGGER AS $$
        BEGIN
            -- Update totals in staff_referrals table
            IF NEW.staff_referral_id IS NOT NULL THEN
                UPDATE staff_referrals
                SET 
                    total_customer_spending = COALESCE((
                        SELECT SUM(amount)
                        FROM customer_transactions
                        WHERE staff_referral_id = NEW.staff_referral_id
                    ), 0),
                    total_commission_earned = COALESCE((
                        SELECT SUM(commission_amount)
                        FROM staff_commissions
                        WHERE staff_id = (
                            SELECT staff_id FROM staff_referrals WHERE id = NEW.staff_referral_id
                        )
                    ), 0),
                    updated_at = now()
                WHERE id = NEW.staff_referral_id;
            END IF;

            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
        """,
        
        # Updated at trigger function
        """
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = now();
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
        """,
    ]
    
    # Create functions
    for i, func in enumerate(functions, 1):
        result = await client.execute_sql(func.strip())
        if result['success']:
            print(f'   ✅ Function {i}/{len(functions)} created')
        else:
            print(f'   ❌ Function {i}/{len(functions)} failed: {result["error"]}')
    
    # Create triggers
    triggers = [
        """
        DROP TRIGGER IF EXISTS trigger_calculate_staff_commission ON customer_transactions;
        CREATE TRIGGER trigger_calculate_staff_commission
        AFTER INSERT ON customer_transactions
        FOR EACH ROW EXECUTE FUNCTION calculate_staff_commission();
        """,
        
        """
        DROP TRIGGER IF EXISTS trigger_update_staff_referral_totals ON customer_transactions;
        CREATE TRIGGER trigger_update_staff_referral_totals
        AFTER INSERT ON customer_transactions
        FOR EACH ROW EXECUTE FUNCTION update_staff_referral_totals();
        """,
        
        """
        DROP TRIGGER IF EXISTS trigger_update_staff_referral_totals_on_commission ON staff_commissions;
        CREATE TRIGGER trigger_update_staff_referral_totals_on_commission
        AFTER INSERT ON staff_commissions
        FOR EACH ROW EXECUTE FUNCTION update_staff_referral_totals();
        """,
        
        """
        DROP TRIGGER IF EXISTS trigger_update_club_staff_updated_at ON club_staff;
        CREATE TRIGGER trigger_update_club_staff_updated_at
        BEFORE UPDATE ON club_staff
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        """,
        
        """
        DROP TRIGGER IF EXISTS trigger_update_staff_referrals_updated_at ON staff_referrals;
        CREATE TRIGGER trigger_update_staff_referrals_updated_at
        BEFORE UPDATE ON staff_referrals
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        """,
        
        """
        DROP TRIGGER IF EXISTS trigger_update_staff_performance_updated_at ON staff_performance;
        CREATE TRIGGER trigger_update_staff_performance_updated_at
        BEFORE UPDATE ON staff_performance
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        """,
    ]
    
    # Create triggers
    for i, trigger in enumerate(triggers, 1):
        result = await client.execute_sql(trigger.strip())
        if result['success']:
            print(f'   ✅ Trigger {i}/{len(triggers)} created')
        else:
            print(f'   ❌ Trigger {i}/{len(triggers)} failed: {result["error"]}')

async def test_system():
    """Test the system with sample queries"""
    print('\n🧪 Testing Club Staff Commission System...')
    
    client = SupabaseClient(SUPABASE_URL, SUPABASE_ANON_KEY)
    
    # Test queries
    test_queries = [
        "SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_name IN ('club_staff', 'staff_referrals', 'customer_transactions', 'staff_commissions', 'staff_performance')",
        "SELECT table_name FROM information_schema.tables WHERE table_name LIKE '%staff%' OR table_name LIKE '%commission%'",
    ]
    
    for query in test_queries:
        result = await client.execute_sql(query)
        if result['success']:
            print(f'   ✅ Test query successful: {result["data"]}')
        else:
            print(f'   ❌ Test query failed: {result["error"]}')

if __name__ == '__main__':
    asyncio.run(apply_club_staff_system())
    asyncio.run(test_system())
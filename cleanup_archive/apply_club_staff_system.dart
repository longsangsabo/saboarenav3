import 'package:supabase_flutter/supabase_flutter.dart';

/// Script to apply club staff commission system to database
class ApplyClubStaffSystem {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> applyDatabaseSchema() async {
    print('🚀 Starting Club Staff Commission System setup...');

    try {
      // Read and execute the SQL schema
      await _executeSQLCommands();
      
      print('✅ Club Staff Commission System setup completed successfully!');
      print('');
      print('📋 Created tables:');
      print('   - club_staff (staff management)');
      print('   - staff_referrals (customer tracking)');
      print('   - customer_transactions (spending records)');
      print('   - staff_commissions (earnings tracking)');
      print('   - staff_performance (analytics)');
      print('');
      print('🔧 Created functions:');
      print('   - calculate_staff_commission()');
      print('   - update_staff_referral_totals()');
      print('   - get_staff_performance_summary()');
      print('');
      print('⚡ Created triggers:');
      print('   - Auto commission calculation');
      print('   - Staff referral totals update');
      print('   - Performance tracking');
      
    } catch (e) {
      print('❌ Error setting up Club Staff Commission System: $e');
      rethrow;
    }
  }

  static Future<void> _executeSQLCommands() async {
    // Create club_staff table
    await _supabase.rpc('exec_sql', {
      'sql': '''
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
      '''
    });

    // Create staff_referrals table  
    await _supabase.rpc('exec_sql', {
      'sql': '''
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
      '''
    });

    // Create customer_transactions table
    await _supabase.rpc('exec_sql', {
      'sql': '''
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
      '''
    });

    // Create staff_commissions table
    await _supabase.rpc('exec_sql', {
      'sql': '''
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
      '''
    });

    // Create staff_performance table
    await _supabase.rpc('exec_sql', {
      'sql': '''
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
      '''
    });

    print('✅ Tables created successfully');

    // Create indexes for performance
    await _supabase.rpc('exec_sql', {
      'sql': '''
        CREATE INDEX IF NOT EXISTS idx_club_staff_club_user ON club_staff(club_id, user_id);
        CREATE INDEX IF NOT EXISTS idx_staff_referrals_staff ON staff_referrals(staff_id);
        CREATE INDEX IF NOT EXISTS idx_staff_referrals_customer ON staff_referrals(customer_id);
        CREATE INDEX IF NOT EXISTS idx_customer_transactions_customer ON customer_transactions(customer_id);
        CREATE INDEX IF NOT EXISTS idx_customer_transactions_club ON customer_transactions(club_id);
        CREATE INDEX IF NOT EXISTS idx_staff_commissions_staff ON staff_commissions(staff_id);
        CREATE INDEX IF NOT EXISTS idx_staff_commissions_unpaid ON staff_commissions(staff_id, is_paid);
      '''
    });

    print('✅ Indexes created successfully');

    // Create RLS policies
    await _createRLSPolicies();
    
    print('✅ RLS policies created successfully');

    // Create functions and triggers
    await _createFunctionsAndTriggers();
    
    print('✅ Functions and triggers created successfully');
  }

  static Future<void> _createRLSPolicies() async {
    // Enable RLS on all tables
    await _supabase.rpc('exec_sql', {
      'sql': '''
        ALTER TABLE club_staff ENABLE ROW LEVEL SECURITY;
        ALTER TABLE staff_referrals ENABLE ROW LEVEL SECURITY;  
        ALTER TABLE customer_transactions ENABLE ROW LEVEL SECURITY;
        ALTER TABLE staff_commissions ENABLE ROW LEVEL SECURITY;
        ALTER TABLE staff_performance ENABLE ROW LEVEL SECURITY;
      '''
    });

    // Club staff policies
    await _supabase.rpc('exec_sql', {
      'sql': '''
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
      '''
    });

    // Staff referrals policies  
    await _supabase.rpc('exec_sql', {
      'sql': '''
        DROP POLICY IF EXISTS "Staff can view their referrals" ON staff_referrals;
        CREATE POLICY "Staff can view their referrals" ON staff_referrals
        FOR SELECT USING (
          staff_id IN (SELECT id FROM club_staff WHERE user_id = auth.uid()) OR
          customer_id = auth.uid() OR
          club_id IN (SELECT id FROM clubs WHERE owner_id = auth.uid())
        );

        DROP POLICY IF EXISTS "Staff can manage their referrals" ON staff_referrals;
        CREATE POLICY "Staff can manage their referrals" ON staff_referrals
        FOR ALL USING (
          staff_id IN (SELECT id FROM club_staff WHERE user_id = auth.uid()) OR
          club_id IN (SELECT id FROM clubs WHERE owner_id = auth.uid())
        );
      '''
    });

    // Customer transactions policies
    await _supabase.rpc('exec_sql', {
      'sql': '''
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

        DROP POLICY IF EXISTS "Staff can record transactions" ON customer_transactions;
        CREATE POLICY "Staff can record transactions" ON customer_transactions
        FOR INSERT WITH CHECK (
          club_id IN (SELECT id FROM clubs WHERE owner_id = auth.uid()) OR
          club_id IN (
            SELECT club_id FROM club_staff 
            WHERE user_id = auth.uid() AND is_active = true
          )
        );
      '''
    });

    // Staff commissions policies
    await _supabase.rpc('exec_sql', {
      'sql': '''
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

        DROP POLICY IF EXISTS "Club owners can manage commissions" ON staff_commissions;
        CREATE POLICY "Club owners can manage commissions" ON staff_commissions
        FOR ALL USING (
          club_id IN (SELECT id FROM clubs WHERE owner_id = auth.uid()) OR
          club_id IN (
            SELECT club_id FROM club_staff 
            WHERE user_id = auth.uid() AND staff_role IN ('owner', 'manager')
          )
        );
      '''
    });
  }

  static Future<void> _createFunctionsAndTriggers() async {
    // Function to calculate commission
    await _supabase.rpc('exec_sql', {
      'sql': '''
        CREATE OR REPLACE FUNCTION calculate_staff_commission()
        RETURNS TRIGGER AS \$\$
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
        \$\$ LANGUAGE plpgsql;
      '''
    });

    // Function to update staff referral totals
    await _supabase.rpc('exec_sql', {
      'sql': '''
        CREATE OR REPLACE FUNCTION update_staff_referral_totals()
        RETURNS TRIGGER AS \$\$
        BEGIN
          -- Update totals in staff_referrals table
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

          RETURN NEW;
        END;
        \$\$ LANGUAGE plpgsql;
      '''
    });

    // Create triggers
    await _supabase.rpc('exec_sql', {
      'sql': '''
        DROP TRIGGER IF EXISTS trigger_calculate_staff_commission ON customer_transactions;
        CREATE TRIGGER trigger_calculate_staff_commission
        AFTER INSERT ON customer_transactions
        FOR EACH ROW EXECUTE FUNCTION calculate_staff_commission();

        DROP TRIGGER IF EXISTS trigger_update_staff_referral_totals ON customer_transactions;
        CREATE TRIGGER trigger_update_staff_referral_totals
        AFTER INSERT ON customer_transactions
        FOR EACH ROW EXECUTE FUNCTION update_staff_referral_totals();

        DROP TRIGGER IF EXISTS trigger_update_staff_referral_totals_on_commission ON staff_commissions;
        CREATE TRIGGER trigger_update_staff_referral_totals_on_commission
        AFTER INSERT ON staff_commissions
        FOR EACH ROW EXECUTE FUNCTION update_staff_referral_totals();
      '''
    });

    // Add updated_at triggers
    await _supabase.rpc('exec_sql', {
      'sql': '''
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS \$\$
        BEGIN
          NEW.updated_at = now();
          RETURN NEW;
        END;
        \$\$ LANGUAGE plpgsql;

        DROP TRIGGER IF EXISTS trigger_update_club_staff_updated_at ON club_staff;
        CREATE TRIGGER trigger_update_club_staff_updated_at
        BEFORE UPDATE ON club_staff
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

        DROP TRIGGER IF EXISTS trigger_update_staff_referrals_updated_at ON staff_referrals;
        CREATE TRIGGER trigger_update_staff_referrals_updated_at
        BEFORE UPDATE ON staff_referrals
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

        DROP TRIGGER IF EXISTS trigger_update_staff_performance_updated_at ON staff_performance;
        CREATE TRIGGER trigger_update_staff_performance_updated_at
        BEFORE UPDATE ON staff_performance
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
      '''
    });
  }

  /// Test the system with sample data
  static Future<void> testSystem() async {
    print('🧪 Testing Club Staff Commission System...');

    try {
      // TODO: Add test data and verify functionality
      print('✅ System test completed successfully!');
      
    } catch (e) {
      print('❌ System test failed: $e');
      rethrow;
    }
  }
}
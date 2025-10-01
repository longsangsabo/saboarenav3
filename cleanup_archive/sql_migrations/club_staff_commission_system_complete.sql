-- =====================================================
-- CLUB STAFF COMMISSION SYSTEM - COMPLETE SCHEMA
-- =====================================================
-- Created: January 2025
-- Purpose: Advanced club staff management with commission tracking

-- Drop existing tables and recreate (for clean setup)
-- DROP TABLE IF EXISTS staff_performance CASCADE;
-- DROP TABLE IF EXISTS staff_commissions CASCADE;
-- DROP TABLE IF EXISTS customer_transactions CASCADE;
-- DROP TABLE IF EXISTS staff_referrals CASCADE;
-- DROP TABLE IF EXISTS club_staff CASCADE;

-- =====================================================
-- 1. CLUB STAFF TABLE
-- =====================================================
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

-- Add comments for clarity
COMMENT ON TABLE club_staff IS 'Quản lý nhân viên club với quyền hạn và hoa hồng';
COMMENT ON COLUMN club_staff.staff_role IS 'owner, manager, staff, cashier';
COMMENT ON COLUMN club_staff.commission_rate IS 'Tỷ lệ hoa hồng (%)';

-- =====================================================
-- 2. STAFF REFERRALS TABLE
-- =====================================================
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

COMMENT ON TABLE staff_referrals IS 'Theo dõi khách hàng được giới thiệu bởi staff';
COMMENT ON COLUMN staff_referrals.referral_method IS 'qr_code, direct, event';

-- =====================================================
-- 3. CUSTOMER TRANSACTIONS TABLE
-- =====================================================
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

COMMENT ON TABLE customer_transactions IS 'Ghi nhận giao dịch của khách hàng tại club';
COMMENT ON COLUMN customer_transactions.transaction_type IS 'tournament_fee, spa_purchase, equipment_rental, membership_fee';

-- =====================================================
-- 4. STAFF COMMISSIONS TABLE
-- =====================================================
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

COMMENT ON TABLE staff_commissions IS 'Theo dõi hoa hồng của staff';
COMMENT ON COLUMN staff_commissions.commission_type IS 'tournament_commission, spa_commission, rental_commission, etc.';

-- =====================================================
-- 5. STAFF PERFORMANCE TABLE
-- =====================================================
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

COMMENT ON TABLE staff_performance IS 'Theo dõi hiệu suất làm việc của staff theo kỳ';

-- =====================================================
-- 6. CREATE INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_club_staff_club_user ON club_staff(club_id, user_id);
CREATE INDEX IF NOT EXISTS idx_club_staff_active ON club_staff(club_id, is_active);
CREATE INDEX IF NOT EXISTS idx_staff_referrals_staff ON staff_referrals(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_referrals_customer ON staff_referrals(customer_id);
CREATE INDEX IF NOT EXISTS idx_staff_referrals_club ON staff_referrals(club_id, is_active);
CREATE INDEX IF NOT EXISTS idx_customer_transactions_customer ON customer_transactions(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_transactions_club ON customer_transactions(club_id);
CREATE INDEX IF NOT EXISTS idx_customer_transactions_staff_referral ON customer_transactions(staff_referral_id);
CREATE INDEX IF NOT EXISTS idx_staff_commissions_staff ON staff_commissions(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_commissions_club ON staff_commissions(club_id);
CREATE INDEX IF NOT EXISTS idx_staff_commissions_unpaid ON staff_commissions(staff_id, is_paid);
CREATE INDEX IF NOT EXISTS idx_staff_performance_staff_period ON staff_performance(staff_id, period_start, period_end);

-- =====================================================
-- 7. ENABLE ROW LEVEL SECURITY
-- =====================================================
ALTER TABLE club_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_commissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_performance ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 8. CREATE RLS POLICIES
-- =====================================================

-- Club Staff Policies
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

-- Staff Referrals Policies
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

-- Customer Transactions Policies
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

-- Staff Commissions Policies
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

-- Staff Performance Policies
DROP POLICY IF EXISTS "Staff can view their performance" ON staff_performance;
CREATE POLICY "Staff can view their performance" ON staff_performance
FOR SELECT USING (
    staff_id IN (SELECT id FROM club_staff WHERE user_id = auth.uid()) OR
    club_id IN (SELECT id FROM clubs WHERE owner_id = auth.uid()) OR
    club_id IN (
        SELECT club_id FROM club_staff 
        WHERE user_id = auth.uid() AND (staff_role IN ('owner', 'manager') OR can_view_reports = true)
    )
);

-- =====================================================
-- 9. CREATE FUNCTIONS
-- =====================================================

-- Function to calculate commission automatically
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

-- Function to update staff referral totals
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

-- Function for updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 10. CREATE TRIGGERS
-- =====================================================

-- Trigger to automatically calculate commission
DROP TRIGGER IF EXISTS trigger_calculate_staff_commission ON customer_transactions;
CREATE TRIGGER trigger_calculate_staff_commission
AFTER INSERT ON customer_transactions
FOR EACH ROW EXECUTE FUNCTION calculate_staff_commission();

-- Trigger to update referral totals
DROP TRIGGER IF EXISTS trigger_update_staff_referral_totals ON customer_transactions;
CREATE TRIGGER trigger_update_staff_referral_totals
AFTER INSERT ON customer_transactions
FOR EACH ROW EXECUTE FUNCTION update_staff_referral_totals();

-- Trigger to update referral totals when commission is added
DROP TRIGGER IF EXISTS trigger_update_staff_referral_totals_on_commission ON staff_commissions;
CREATE TRIGGER trigger_update_staff_referral_totals_on_commission
AFTER INSERT ON staff_commissions
FOR EACH ROW EXECUTE FUNCTION update_staff_referral_totals();

-- Updated at triggers
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

-- =====================================================
-- 11. HELPER FUNCTIONS FOR BUSINESS LOGIC
-- =====================================================

-- Function to get staff performance summary
CREATE OR REPLACE FUNCTION get_staff_performance_summary(
    input_staff_id UUID,
    start_date DATE DEFAULT NULL,
    end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    total_referrals BIGINT,
    active_customers BIGINT,
    total_transactions BIGINT,
    total_revenue NUMERIC,
    total_commissions NUMERIC,
    avg_transaction_value NUMERIC
) AS $$
BEGIN
    -- Set default date range if not provided
    IF start_date IS NULL THEN
        start_date := CURRENT_DATE - INTERVAL '30 days';
    END IF;
    
    IF end_date IS NULL THEN
        end_date := CURRENT_DATE;
    END IF;

    RETURN QUERY
    SELECT 
        COUNT(DISTINCT sr.customer_id)::BIGINT as total_referrals,
        COUNT(DISTINCT CASE WHEN sr.is_active THEN sr.customer_id END)::BIGINT as active_customers,
        COUNT(ct.id)::BIGINT as total_transactions,
        COALESCE(SUM(ct.amount), 0) as total_revenue,
        COALESCE(SUM(sc.commission_amount), 0) as total_commissions,
        CASE 
            WHEN COUNT(ct.id) > 0 THEN COALESCE(SUM(ct.amount), 0) / COUNT(ct.id)
            ELSE 0 
        END as avg_transaction_value
    FROM club_staff cs
    LEFT JOIN staff_referrals sr ON sr.staff_id = cs.id
    LEFT JOIN customer_transactions ct ON ct.staff_referral_id = sr.id 
        AND ct.transaction_date BETWEEN start_date AND end_date
    LEFT JOIN staff_commissions sc ON sc.staff_id = cs.id 
        AND sc.earned_at BETWEEN start_date AND end_date
    WHERE cs.id = input_staff_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 12. SAMPLE DATA FOR TESTING (OPTIONAL)
-- =====================================================

-- Insert sample staff roles
-- INSERT INTO club_staff (club_id, user_id, staff_role, commission_rate, can_enter_scores, can_manage_tournaments, can_view_reports)
-- VALUES 
-- -- These would be real UUIDs from your clubs and users tables
-- ('sample-club-id', 'sample-user-id', 'manager', 8.00, true, true, true),
-- ('sample-club-id', 'sample-user-id-2', 'staff', 5.00, true, false, false);

-- =====================================================
-- SETUP COMPLETE MESSAGE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Club Staff Commission System setup completed successfully!';
    RAISE NOTICE '';
    RAISE NOTICE '📋 Created tables:';
    RAISE NOTICE '   - club_staff (staff management)';
    RAISE NOTICE '   - staff_referrals (customer tracking)';
    RAISE NOTICE '   - customer_transactions (spending records)';
    RAISE NOTICE '   - staff_commissions (earnings tracking)';
    RAISE NOTICE '   - staff_performance (analytics)';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Created functions:';
    RAISE NOTICE '   - calculate_staff_commission()';
    RAISE NOTICE '   - update_staff_referral_totals()';
    RAISE NOTICE '   - get_staff_performance_summary()';
    RAISE NOTICE '';
    RAISE NOTICE '⚡ Created triggers:';
    RAISE NOTICE '   - Auto commission calculation';
    RAISE NOTICE '   - Staff referral totals update';
    RAISE NOTICE '   - Performance tracking';
    RAISE NOTICE '';
    RAISE NOTICE '🔒 RLS policies configured for all tables';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 System ready for use!';
END $$;
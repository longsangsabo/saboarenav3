-- CLUB STAFF & COMMISSION SYSTEM DATABASE SCHEMA
-- SABO Arena - Advanced Referral with Staff Management

BEGIN;

-- =====================================================
-- 1. CLUB STAFF MANAGEMENT
-- =====================================================

-- Bảng quản lý staff roles
CREATE TABLE IF NOT EXISTS club_staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    staff_role TEXT DEFAULT 'staff' CHECK (staff_role IN ('owner', 'manager', 'staff', 'trainee')),
    
    -- Permissions
    can_enter_scores BOOLEAN DEFAULT true,
    can_manage_tournaments BOOLEAN DEFAULT false,
    can_view_reports BOOLEAN DEFAULT false,
    can_manage_staff BOOLEAN DEFAULT false,
    
    -- Commission settings
    commission_rate DECIMAL(5,2) DEFAULT 5.0, -- 5% default commission
    base_referral_bonus INTEGER DEFAULT 100,   -- SPA bonus per referral
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    hired_at TIMESTAMP DEFAULT NOW(),
    terminated_at TIMESTAMP NULL,
    
    -- Metadata  
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(club_id, user_id)
);

-- =====================================================
-- 2. CUSTOMER TRACKING & SPENDING
-- =====================================================

-- Bảng tracking customer được staff giới thiệu
CREATE TABLE IF NOT EXISTS staff_referrals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID REFERENCES club_staff(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    
    -- Referral info
    referral_method TEXT DEFAULT 'qr_code' CHECK (referral_method IN ('qr_code', 'manual', 'social_media', 'word_of_mouth')),
    referral_code TEXT,
    qr_data TEXT,
    
    -- Initial bonus
    initial_bonus_spa INTEGER DEFAULT 100,
    initial_bonus_paid BOOLEAN DEFAULT false,
    
    -- Lifetime value tracking
    total_customer_spending DECIMAL(12,2) DEFAULT 0,
    total_commission_earned DECIMAL(12,2) DEFAULT 0,
    commission_rate DECIMAL(5,2) DEFAULT 5.0,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    referred_at TIMESTAMP DEFAULT NOW(),
    last_spending_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(staff_id, customer_id, club_id)
);

-- =====================================================
-- 3. CUSTOMER SPENDING & TRANSACTIONS
-- =====================================================

-- Bảng ghi nhận chi tiêu của customer tại club
CREATE TABLE IF NOT EXISTS customer_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    staff_referral_id UUID REFERENCES staff_referrals(id) ON DELETE SET NULL,
    
    -- Transaction details
    transaction_type TEXT NOT NULL CHECK (transaction_type IN (
        'tournament_fee', 'table_booking', 'fnb_order', 'private_lesson', 
        'merchandise', 'membership', 'equipment_rental', 'other'
    )),
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'VND',
    
    -- Commission calculation
    commission_eligible BOOLEAN DEFAULT true,
    commission_rate DECIMAL(5,2),
    commission_amount DECIMAL(10,2),
    commission_paid BOOLEAN DEFAULT false,
    
    -- Reference data
    tournament_id UUID REFERENCES tournaments(id) ON DELETE SET NULL,
    match_id UUID REFERENCES matches(id) ON DELETE SET NULL,
    booking_reference TEXT,
    
    -- Metadata
    description TEXT,
    payment_method TEXT,
    receipt_url TEXT,
    
    transaction_date TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- 4. STAFF COMMISSION & EARNINGS
-- =====================================================

-- Bảng tính toán và chi trả commission cho staff
CREATE TABLE IF NOT EXISTS staff_commissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID REFERENCES club_staff(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    customer_transaction_id UUID REFERENCES customer_transactions(id) ON DELETE CASCADE,
    staff_referral_id UUID REFERENCES staff_referrals(id) ON DELETE CASCADE,
    
    -- Commission calculation
    transaction_amount DECIMAL(10,2) NOT NULL,
    commission_rate DECIMAL(5,2) NOT NULL,
    commission_amount DECIMAL(10,2) NOT NULL,
    
    -- Commission type
    commission_type TEXT DEFAULT 'referral_spending' CHECK (commission_type IN (
        'referral_bonus',      -- One-time referral bonus
        'referral_spending',   -- Commission from referral spending
        'direct_service',      -- Commission from direct service
        'performance_bonus',   -- Achievement-based bonus
        'loyalty_reward'       -- Long-term loyalty reward
    )),
    
    -- Payment tracking
    is_paid BOOLEAN DEFAULT false,
    paid_at TIMESTAMP,
    payment_reference TEXT,
    payment_method TEXT DEFAULT 'spa_points',
    
    -- Metadata
    calculation_notes TEXT,
    earned_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- 5. STAFF PERFORMANCE & ANALYTICS
-- =====================================================

-- Bảng theo dõi performance của staff
CREATE TABLE IF NOT EXISTS staff_performance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID REFERENCES club_staff(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    
    -- Time period
    period_type TEXT DEFAULT 'monthly' CHECK (period_type IN ('daily', 'weekly', 'monthly', 'yearly')),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Performance metrics
    total_referrals INTEGER DEFAULT 0,
    active_referrals INTEGER DEFAULT 0,
    total_customer_spending DECIMAL(12,2) DEFAULT 0,
    total_commission_earned DECIMAL(10,2) DEFAULT 0,
    
    -- Activity metrics
    tournaments_managed INTEGER DEFAULT 0,
    scores_entered INTEGER DEFAULT 0,
    matches_officiated INTEGER DEFAULT 0,
    
    -- Achievement tracking
    performance_grade TEXT DEFAULT 'C' CHECK (performance_grade IN ('S', 'A', 'B', 'C', 'D')),
    achievement_badges JSONB DEFAULT '[]',
    
    -- Rewards & bonuses
    performance_bonus DECIMAL(8,2) DEFAULT 0,
    bonus_paid BOOLEAN DEFAULT false,
    
    calculated_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(staff_id, period_type, period_start)
);

-- =====================================================
-- 6. ENHANCED REFERRAL CODES FOR STAFF
-- =====================================================

-- Mở rộng bảng referral_codes để hỗ trợ staff
ALTER TABLE referral_codes ADD COLUMN IF NOT EXISTS staff_id UUID REFERENCES club_staff(id) ON DELETE SET NULL;
ALTER TABLE referral_codes ADD COLUMN IF NOT EXISTS club_id UUID REFERENCES clubs(id) ON DELETE SET NULL;
ALTER TABLE referral_codes ADD COLUMN IF NOT EXISTS referral_type TEXT DEFAULT 'user' CHECK (referral_type IN ('user', 'staff', 'club_promotion'));
ALTER TABLE referral_codes ADD COLUMN IF NOT EXISTS commission_rate DECIMAL(5,2) DEFAULT 0;

-- Update referral_usage để track staff
ALTER TABLE referral_usage ADD COLUMN IF NOT EXISTS staff_id UUID REFERENCES club_staff(id) ON DELETE SET NULL;
ALTER TABLE referral_usage ADD COLUMN IF NOT EXISTS club_id UUID REFERENCES clubs(id) ON DELETE SET NULL;

-- =====================================================
-- 7. TRIGGERS & FUNCTIONS
-- =====================================================

-- Function: Tự động tính commission khi có transaction mới
CREATE OR REPLACE FUNCTION calculate_staff_commission()
RETURNS TRIGGER AS $$
BEGIN
    -- Chỉ tính commission cho transaction eligible
    IF NEW.commission_eligible = true AND NEW.staff_referral_id IS NOT NULL THEN
        
        -- Lấy thông tin staff referral
        WITH staff_info AS (
            SELECT sr.staff_id, sr.commission_rate, cs.club_id
            FROM staff_referrals sr
            JOIN club_staff cs ON sr.staff_id = cs.id
            WHERE sr.id = NEW.staff_referral_id AND cs.is_active = true
        )
        
        -- Tạo commission record
        INSERT INTO staff_commissions (
            staff_id, 
            club_id, 
            customer_transaction_id, 
            staff_referral_id,
            transaction_amount, 
            commission_rate, 
            commission_amount
        )
        SELECT 
            si.staff_id,
            si.club_id,
            NEW.id,
            NEW.staff_referral_id,
            NEW.amount,
            COALESCE(NEW.commission_rate, si.commission_rate),
            NEW.amount * (COALESCE(NEW.commission_rate, si.commission_rate) / 100)
        FROM staff_info si;
        
        -- Update total spending trong staff_referrals
        UPDATE staff_referrals 
        SET 
            total_customer_spending = total_customer_spending + NEW.amount,
            total_commission_earned = total_commission_earned + (NEW.amount * (COALESCE(NEW.commission_rate, commission_rate) / 100)),
            last_spending_at = NOW(),
            updated_at = NOW()
        WHERE id = NEW.staff_referral_id;
        
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Tự động tính commission
CREATE TRIGGER trigger_calculate_staff_commission
    AFTER INSERT ON customer_transactions
    FOR EACH ROW
    EXECUTE FUNCTION calculate_staff_commission();

-- Function: Auto update performance metrics
CREATE OR REPLACE FUNCTION update_staff_performance()
RETURNS TRIGGER AS $$
BEGIN
    -- Update monthly performance khi có commission mới
    INSERT INTO staff_performance (
        staff_id, club_id, period_type, period_start, period_end,
        total_commission_earned
    )
    VALUES (
        NEW.staff_id,
        NEW.club_id,
        'monthly',
        date_trunc('month', NEW.earned_at)::date,
        (date_trunc('month', NEW.earned_at) + interval '1 month' - interval '1 day')::date,
        NEW.commission_amount
    )
    ON CONFLICT (staff_id, period_type, period_start)
    DO UPDATE SET
        total_commission_earned = staff_performance.total_commission_earned + NEW.commission_amount,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Auto update performance
CREATE TRIGGER trigger_update_staff_performance
    AFTER INSERT ON staff_commissions
    FOR EACH ROW
    EXECUTE FUNCTION update_staff_performance();

-- =====================================================
-- 8. INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes cho club_staff
CREATE INDEX IF NOT EXISTS idx_club_staff_club_id ON club_staff(club_id);
CREATE INDEX IF NOT EXISTS idx_club_staff_user_id ON club_staff(user_id);
CREATE INDEX IF NOT EXISTS idx_club_staff_active ON club_staff(is_active);

-- Indexes cho staff_referrals  
CREATE INDEX IF NOT EXISTS idx_staff_referrals_staff_id ON staff_referrals(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_referrals_customer_id ON staff_referrals(customer_id);
CREATE INDEX IF NOT EXISTS idx_staff_referrals_club_id ON staff_referrals(club_id);

-- Indexes cho customer_transactions
CREATE INDEX IF NOT EXISTS idx_customer_transactions_customer_id ON customer_transactions(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_transactions_club_id ON customer_transactions(club_id);
CREATE INDEX IF NOT EXISTS idx_customer_transactions_date ON customer_transactions(transaction_date);

-- Indexes cho staff_commissions
CREATE INDEX IF NOT EXISTS idx_staff_commissions_staff_id ON staff_commissions(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_commissions_earned_at ON staff_commissions(earned_at);
CREATE INDEX IF NOT EXISTS idx_staff_commissions_paid ON staff_commissions(is_paid);

-- =====================================================
-- 9. SAMPLE DATA & TESTING
-- =====================================================

-- Tạo sample club staff data
INSERT INTO club_staff (club_id, user_id, staff_role, commission_rate, can_enter_scores)
SELECT 
    (SELECT id FROM clubs LIMIT 1) as club_id,
    u.id as user_id,
    'staff' as staff_role,
    5.0 as commission_rate,
    true as can_enter_scores
FROM users u 
WHERE u.role = 'player' 
LIMIT 3
ON CONFLICT (club_id, user_id) DO NOTHING;

COMMIT;

-- Verification queries
SELECT 'Club Staff Count' as metric, COUNT(*) as value FROM club_staff;
SELECT 'Staff Referrals Count' as metric, COUNT(*) as value FROM staff_referrals;
SELECT 'Customer Transactions Count' as metric, COUNT(*) as value FROM customer_transactions;
SELECT 'Staff Commissions Count' as metric, COUNT(*) as value FROM staff_commissions;
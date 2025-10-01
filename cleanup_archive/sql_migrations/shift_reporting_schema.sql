-- =====================================================
-- SHIFT REPORTING SYSTEM DATABASE SCHEMA
-- Sabo Arena - Club Shift Management & Financial Reports
-- =====================================================

BEGIN;

-- =====================================================
-- 1. SHIFT SESSIONS - Quản lý phiên làm việc
-- =====================================================

CREATE TABLE IF NOT EXISTS shift_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    staff_id UUID REFERENCES club_staff(id) ON DELETE CASCADE,
    
    -- Shift timing
    shift_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME,
    actual_start_time TIMESTAMP,
    actual_end_time TIMESTAMP,
    
    -- Financial tracking
    opening_cash DECIMAL(12,2) DEFAULT 0,
    closing_cash DECIMAL(12,2),
    expected_cash DECIMAL(12,2) DEFAULT 0,
    cash_difference DECIMAL(12,2) DEFAULT 0,
    
    -- Revenue summary
    total_revenue DECIMAL(12,2) DEFAULT 0,
    cash_revenue DECIMAL(12,2) DEFAULT 0,
    card_revenue DECIMAL(12,2) DEFAULT 0,
    digital_revenue DECIMAL(12,2) DEFAULT 0,
    
    -- Status
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'handed_over', 'reviewed')),
    notes TEXT,
    
    -- Handover
    handed_over_to UUID REFERENCES club_staff(id),
    handed_over_at TIMESTAMP,
    handover_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- 2. SHIFT TRANSACTIONS - Giao dịch trong ca
-- =====================================================

CREATE TABLE IF NOT EXISTS shift_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_session_id UUID REFERENCES shift_sessions(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    
    -- Transaction details
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('revenue', 'expense', 'refund', 'adjustment')),
    category TEXT NOT NULL, -- 'table_fee', 'food', 'drink', 'equipment', 'utilities', 'supplies'
    description TEXT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    
    -- Payment method
    payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'card', 'digital', 'bank_transfer')),
    
    -- Additional info
    table_number INTEGER,
    customer_id UUID REFERENCES users(id),
    receipt_number TEXT,
    
    -- Staff who recorded
    recorded_by UUID REFERENCES club_staff(id),
    recorded_at TIMESTAMP DEFAULT NOW(),
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- 3. SHIFT INVENTORY - Quản lý kho trong ca
-- =====================================================

CREATE TABLE IF NOT EXISTS shift_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_session_id UUID REFERENCES shift_sessions(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    
    -- Item details
    item_name TEXT NOT NULL,
    category TEXT NOT NULL, -- 'food', 'drink', 'equipment', 'supplies'
    unit TEXT NOT NULL, -- 'bottle', 'can', 'plate', 'piece'
    
    -- Inventory tracking
    opening_stock INTEGER DEFAULT 0,
    closing_stock INTEGER,
    stock_used INTEGER DEFAULT 0,
    stock_wasted INTEGER DEFAULT 0,
    stock_added INTEGER DEFAULT 0, -- Restocked during shift
    
    -- Pricing
    unit_cost DECIMAL(10,2),
    unit_price DECIMAL(10,2),
    total_sold INTEGER DEFAULT 0,
    revenue_generated DECIMAL(12,2) DEFAULT 0,
    
    -- Notes
    notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- 4. SHIFT EXPENSES - Chi phí trong ca
-- =====================================================

CREATE TABLE IF NOT EXISTS shift_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_session_id UUID REFERENCES shift_sessions(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    
    -- Expense details
    expense_type TEXT NOT NULL CHECK (expense_type IN ('utilities', 'supplies', 'maintenance', 'staff', 'other')),
    description TEXT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    
    -- Payment info
    payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'card', 'bank_transfer')),
    receipt_url TEXT,
    vendor_name TEXT,
    
    -- Approval
    approved_by UUID REFERENCES club_staff(id),
    approved_at TIMESTAMP,
    
    -- Staff who recorded
    recorded_by UUID REFERENCES club_staff(id),
    recorded_at TIMESTAMP DEFAULT NOW(),
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- 5. SHIFT REPORTS - Báo cáo tổng hợp
-- =====================================================

CREATE TABLE IF NOT EXISTS shift_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_session_id UUID REFERENCES shift_sessions(id) ON DELETE CASCADE,
    club_id UUID REFERENCES clubs(id) ON DELETE CASCADE,
    
    -- Summary data (JSON for flexibility)
    revenue_summary JSONB DEFAULT '{}', -- {"table_fees": 500000, "food": 200000, "drinks": 300000}
    expense_summary JSONB DEFAULT '{}', -- {"utilities": 50000, "supplies": 30000}
    inventory_summary JSONB DEFAULT '{}', -- {"drinks_sold": 20, "food_sold": 15}
    
    -- Key metrics
    total_revenue DECIMAL(12,2) DEFAULT 0,
    total_expenses DECIMAL(12,2) DEFAULT 0,
    net_profit DECIMAL(12,2) DEFAULT 0,
    
    -- Performance metrics
    tables_served INTEGER DEFAULT 0,
    average_revenue_per_table DECIMAL(10,2) DEFAULT 0,
    customer_count INTEGER DEFAULT 0,
    
    -- Cash reconciliation
    cash_expected DECIMAL(12,2) DEFAULT 0,
    cash_actual DECIMAL(12,2) DEFAULT 0,
    cash_variance DECIMAL(12,2) DEFAULT 0,
    
    -- Status
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'reviewed', 'approved')),
    manager_notes TEXT,
    reviewed_by UUID REFERENCES club_staff(id),
    reviewed_at TIMESTAMP,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- 6. INDEXES FOR PERFORMANCE
-- =====================================================

-- Shift sessions indexes
CREATE INDEX IF NOT EXISTS idx_shift_sessions_club_date ON shift_sessions(club_id, shift_date);
CREATE INDEX IF NOT EXISTS idx_shift_sessions_staff ON shift_sessions(staff_id, shift_date);
CREATE INDEX IF NOT EXISTS idx_shift_sessions_status ON shift_sessions(status, shift_date);

-- Transactions indexes
CREATE INDEX IF NOT EXISTS idx_shift_transactions_session ON shift_transactions(shift_session_id, recorded_at);
CREATE INDEX IF NOT EXISTS idx_shift_transactions_type ON shift_transactions(transaction_type, category);
CREATE INDEX IF NOT EXISTS idx_shift_transactions_payment ON shift_transactions(payment_method, recorded_at);

-- Inventory indexes
CREATE INDEX IF NOT EXISTS idx_shift_inventory_session ON shift_inventory(shift_session_id, category);
CREATE INDEX IF NOT EXISTS idx_shift_inventory_item ON shift_inventory(item_name, club_id);

-- Expenses indexes
CREATE INDEX IF NOT EXISTS idx_shift_expenses_session ON shift_expenses(shift_session_id, expense_type);
CREATE INDEX IF NOT EXISTS idx_shift_expenses_approval ON shift_expenses(approved_by, approved_at);

-- Reports indexes
CREATE INDEX IF NOT EXISTS idx_shift_reports_club_date ON shift_reports(club_id, created_at);
CREATE INDEX IF NOT EXISTS idx_shift_reports_status ON shift_reports(status, created_at);

-- =====================================================
-- 7. AUTOMATED FUNCTIONS
-- =====================================================

-- Function to calculate shift summary
CREATE OR REPLACE FUNCTION calculate_shift_summary(session_id UUID)
RETURNS JSON AS $$
DECLARE
    revenue_total DECIMAL(12,2) := 0;
    expense_total DECIMAL(12,2) := 0;
    transaction_count INTEGER := 0;
    result JSON;
BEGIN
    -- Calculate total revenue
    SELECT COALESCE(SUM(amount), 0), COUNT(*)
    INTO revenue_total, transaction_count
    FROM shift_transactions
    WHERE shift_session_id = session_id AND transaction_type = 'revenue';
    
    -- Calculate total expenses
    SELECT COALESCE(SUM(amount), 0)
    INTO expense_total
    FROM shift_expenses
    WHERE shift_session_id = session_id;
    
    -- Build result JSON
    result := json_build_object(
        'total_revenue', revenue_total,
        'total_expenses', expense_total,
        'net_profit', revenue_total - expense_total,
        'transaction_count', transaction_count,
        'calculated_at', NOW()
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to auto-close shift
CREATE OR REPLACE FUNCTION auto_close_shift(session_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    session_data RECORD;
    summary_data JSON;
BEGIN
    -- Get shift session data
    SELECT * INTO session_data
    FROM shift_sessions
    WHERE id = session_id AND status = 'active';
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Calculate summary
    summary_data := calculate_shift_summary(session_id);
    
    -- Update shift session
    UPDATE shift_sessions SET
        status = 'completed',
        actual_end_time = NOW(),
        total_revenue = (summary_data->>'total_revenue')::DECIMAL,
        updated_at = NOW()
    WHERE id = session_id;
    
    -- Create shift report
    INSERT INTO shift_reports (
        shift_session_id,
        club_id,
        total_revenue,
        total_expenses,
        net_profit,
        status
    ) VALUES (
        session_id,
        session_data.club_id,
        (summary_data->>'total_revenue')::DECIMAL,
        (summary_data->>'total_expenses')::DECIMAL,
        (summary_data->>'net_profit')::DECIMAL,
        'draft'
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 8. ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE shift_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE shift_reports ENABLE ROW LEVEL SECURITY;

-- Shift sessions policies
CREATE POLICY "Club owners can manage all shift sessions" ON shift_sessions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM clubs 
            WHERE clubs.id = shift_sessions.club_id 
            AND clubs.owner_id = auth.uid()
        )
    );

CREATE POLICY "Staff can manage their shift sessions" ON shift_sessions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM club_staff cs
            JOIN users u ON u.id = cs.user_id
            WHERE cs.id = shift_sessions.staff_id
            AND u.id = auth.uid()
        ) OR EXISTS (
            SELECT 1 FROM clubs 
            WHERE clubs.id = shift_sessions.club_id 
            AND clubs.owner_id = auth.uid()
        )
    );

-- Similar policies for other tables
CREATE POLICY "Club staff can manage shift data" ON shift_transactions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM shift_sessions ss
            JOIN club_staff cs ON cs.id = ss.staff_id
            JOIN users u ON u.id = cs.user_id
            WHERE ss.id = shift_transactions.shift_session_id
            AND u.id = auth.uid()
        ) OR EXISTS (
            SELECT 1 FROM clubs 
            WHERE clubs.id = shift_transactions.club_id 
            AND clubs.owner_id = auth.uid()
        )
    );

CREATE POLICY "Club staff can manage inventory" ON shift_inventory
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM shift_sessions ss
            JOIN club_staff cs ON cs.id = ss.staff_id
            JOIN users u ON u.id = cs.user_id
            WHERE ss.id = shift_inventory.shift_session_id
            AND u.id = auth.uid()
        ) OR EXISTS (
            SELECT 1 FROM clubs 
            WHERE clubs.id = shift_inventory.club_id 
            AND clubs.owner_id = auth.uid()
        )
    );

CREATE POLICY "Club staff can manage expenses" ON shift_expenses
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM shift_sessions ss
            JOIN club_staff cs ON cs.id = ss.staff_id
            JOIN users u ON u.id = cs.user_id
            WHERE ss.id = shift_expenses.shift_session_id
            AND u.id = auth.uid()
        ) OR EXISTS (
            SELECT 1 FROM clubs 
            WHERE clubs.id = shift_expenses.club_id 
            AND clubs.owner_id = auth.uid()
        )
    );

CREATE POLICY "Club staff can view reports" ON shift_reports
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM shift_sessions ss
            JOIN club_staff cs ON cs.id = ss.staff_id
            JOIN users u ON u.id = cs.user_id
            WHERE ss.id = shift_reports.shift_session_id
            AND u.id = auth.uid()
        ) OR EXISTS (
            SELECT 1 FROM clubs 
            WHERE clubs.id = shift_reports.club_id 
            AND clubs.owner_id = auth.uid()
        )
    );

-- =====================================================
-- 9. SAMPLE DATA FOR TESTING
-- =====================================================

-- Insert sample categories and items
INSERT INTO shift_sessions (club_id, staff_id, shift_date, start_time, end_time, opening_cash, status)
SELECT 
    c.id,
    cs.id,
    CURRENT_DATE,
    '08:00:00',
    '16:00:00',
    500000,
    'active'
FROM clubs c
JOIN club_staff cs ON cs.club_id = c.id
WHERE c.name LIKE '%Demo%' OR c.name LIKE '%Test%'
LIMIT 1;

COMMIT;

-- =====================================================
-- SUMMARY
-- =====================================================
-- ✅ 5 main tables for comprehensive shift management
-- ✅ Financial tracking (revenue, expenses, profit)
-- ✅ Inventory management per shift
-- ✅ Automated calculations and reports
-- ✅ RLS policies for security
-- ✅ Performance indexes
-- ✅ Sample data for testing
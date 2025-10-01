-- =====================================================
-- REAL PAYMENT SYSTEM DATABASE SETUP
-- Hệ thống thanh toán thực tế cho Sabo Arena
-- =====================================================

-- 1. Bảng payments - Lưu trữ tất cả giao dịch thanh toán
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
    booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
    
    -- Thông tin thanh toán
    payment_method VARCHAR(50) NOT NULL, -- 'bank', 'momo', 'zalopay', 'viettelpay', 'cash'
    payment_info JSONB NOT NULL, -- Thông tin chi tiết (số TK, SĐT, etc.)
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    description TEXT NOT NULL,
    
    -- QR Code data
    qr_data TEXT, -- QR string data
    qr_image_url TEXT, -- VietQR image URL
    
    -- Trạng thái và tracking
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled', 'expired')),
    transaction_id VARCHAR(100), -- ID từ ngân hàng/ví
    webhook_data JSONB, -- Raw webhook data từ payment gateway
    
    -- Metadata
    cancel_reason TEXT,
    notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '2 hours'),
    
    -- Indexes
    CONSTRAINT payments_transaction_id_unique UNIQUE (transaction_id, payment_method)
);

-- 2. Bảng invoices - Hóa đơn cho booking/dịch vụ
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL ⠠⠅REFERENCES users(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
    
    -- Thông tin hóa đơn
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
    description TEXT NOT NULL,
    
    -- Trạng thái
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled')),
    
    -- Thời gian
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    paid_at TIMESTAMP WITH TIME ZONE
);

-- 3. Bảng club_payment_settings - Cấu hình thanh toán của CLB
CREATE TABLE IF NOT EXISTS club_payment_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    
    -- Cấu hình thanh toán (encrypted)
    settings JSONB NOT NULL DEFAULT '{}',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Unique constraint
    CONSTRAINT club_payment_settings_unique UNIQUE (club_id)
);

-- 4. Bảng payment_methods - Phương thức thanh toán của CLB
CREATE TABLE IF NOT EXISTS payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    
    -- Loại thanh toán
    method_type VARCHAR(50) NOT NULL, -- 'bank', 'momo', 'zalopay', etc.
    method_name VARCHAR(100) NOT NULL, -- Tên hiển thị
    
    -- Thông tin chi tiết
    account_info JSONB NOT NULL, -- Số TK, SĐT, etc.
    qr_template TEXT, -- Template QR nếu có
    
    -- Trạng thái
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Bảng webhook_logs - Log webhook từ payment gateway
CREATE TABLE IF NOT EXISTS webhook_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Thông tin webhook
    source VARCHAR(50) NOT NULL, -- 'momo', 'zalopay', etc.
    payment_id UUID REFERENCES payments(id) ON DELETE SET NULL,
    
    -- Data
    webhook_data JSONB NOT NULL,
    processed BOOLEAN DEFAULT false,
    
    -- Response
    response_status INTEGER,
    response_data JSONB,
    error_message TEXT,
    
    -- Timestamp
    received_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE
);

-- =====================================================
-- INDEXES for Performance
-- =====================================================

-- Payments indexes
CREATE INDEX IF NOT EXISTS idx_payments_club_id ON payments(club_id);
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payments_method ON payments(payment_method);
CREATE INDEX IF NOT EXISTS idx_payments_transaction_id ON payments(transaction_id);

-- Invoices indexes
CREATE INDEX IF NOT EXISTS idx_invoices_club_id ON invoices(club_id);
CREATE INDEX IF NOT EXISTS idx_invoices_user_id ON invoices(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices(due_date);

-- Payment methods indexes
CREATE INDEX IF NOT EXISTS idx_payment_methods_club_id ON payment_methods(club_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_active ON payment_methods(is_active);

-- Webhook logs indexes
CREATE INDEX IF NOT EXISTS idx_webhook_logs_source ON webhook_logs(source);
CREATE INDEX IF NOT EXISTS idx_webhook_logs_payment_id ON webhook_logs(payment_id);
CREATE INDEX IF NOT EXISTS idx_webhook_logs_processed ON webhook_logs(processed);

-- =====================================================
-- RPC FUNCTIONS
-- =====================================================

-- Function: Cập nhật số dư CLB sau thanh toán
CREATE OR REPLACE FUNCTION update_club_balance(
    p_club_id UUID,
    p_amount DECIMAL
)
RETURNS VOID AS $$
BEGIN
    -- Cập nhật hoặc tạo mới club balance
    INSERT INTO club_balances (club_id, balance, updated_at)
    VALUES (p_club_id, p_amount, NOW())
    ON CONFLICT (club_id) 
    DO UPDATE SET 
        balance = club_balances.balance + p_amount,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Lấy thống kê thanh toán
CREATE OR REPLACE FUNCTION get_payment_stats(
    p_club_id UUID,
    p_from_date TIMESTAMP WITH TIME ZONE,
    p_to_date TIMESTAMP WITH TIME ZONE
)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_amount', COALESCE(SUM(amount), 0),
        'total_transactions', COUNT(*),
        'completed_amount', COALESCE(SUM(CASE WHEN status = 'completed' THEN amount ELSE 0 END), 0),
        'completed_transactions', COUNT(CASE WHEN status = 'completed' THEN 1 END),
        'pending_amount', COALESCE(SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END), 0),
        'pending_transactions', COUNT(CASE WHEN status = 'pending' THEN 1 END),
        'by_method', (
            SELECT json_object_agg(payment_method, method_stats)
            FROM (
                SELECT 
                    payment_method,
                    json_build_object(
                        'amount', SUM(amount),
                        'count', COUNT(*)
                    ) as method_stats
                FROM payments 
                WHERE club_id = p_club_id 
                    AND created_at BETWEEN p_from_date AND p_to_date
                    AND status = 'completed'
                GROUP BY payment_method
            ) method_breakdown
        )
    ) INTO result
    FROM payments
    WHERE club_id = p_club_id 
        AND created_at BETWEEN p_from_date AND p_to_date;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Tự động expire payments cũ
CREATE OR REPLACE FUNCTION expire_old_payments()
RETURNS INTEGER AS $$
DECLARE
    expired_count INTEGER;
BEGIN
    UPDATE payments 
    SET status = 'expired', updated_at = NOW()
    WHERE status = 'pending' 
        AND expires_at < NOW();
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    RETURN expired_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Tạo invoice number tự động
CREATE OR REPLACE FUNCTION generate_invoice_number(p_club_id UUID)
RETURNS VARCHAR AS $$
DECLARE
    club_code VARCHAR(10);
    invoice_count INTEGER;
    invoice_number VARCHAR(50);
BEGIN
    -- Lấy mã CLB (3 ký tự đầu của tên CLB)
    SELECT UPPER(LEFT(REPLACE(name, ' ', ''), 3)) INTO club_code
    FROM clubs WHERE id = p_club_id;
    
    -- Đếm số invoice trong tháng hiện tại
    SELECT COUNT(*) + 1 INTO invoice_count
    FROM invoices 
    WHERE club_id = p_club_id 
        AND EXTRACT(MONTH FROM created_at) = EXTRACT(MONTH FROM NOW())
        AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NOW());
    
    -- Tạo invoice number: CLB-YYYYMM-NNNN
    invoice_number := club_code || '-' || 
                     TO_CHAR(NOW(), 'YYYYMM') || '-' ||
                     LPAD(invoice_count::TEXT, 4, '0');
    
    RETURN invoice_number;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger: Tự động tạo invoice number
CREATE OR REPLACE FUNCTION set_invoice_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invoice_number IS NULL OR NEW.invoice_number = '' THEN
        NEW.invoice_number := generate_invoice_number(NEW.club_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_invoice_number
    BEFORE INSERT ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION set_invoice_number();

-- Trigger: Cập nhật updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_club_payment_settings_updated_at
    BEFORE UPDATE ON club_payment_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- RLS POLICIES (Row Level Security)
-- =====================================================

-- Enable RLS
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_payment_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_logs ENABLE ROW LEVEL SECURITY;

-- Payments policies
CREATE POLICY "Club owners can manage their payments"
    ON payments FOR ALL
    USING (club_id IN (
        SELECT id FROM clubs WHERE owner_id = auth.uid()
    ));

CREATE POLICY "Users can view their own payments"
    ON payments FOR SELECT
    USING (user_id = auth.uid());

-- Invoices policies  
CREATE POLICY "Club owners can manage their invoices"
    ON invoices FOR ALL
    USING (club_id IN (
        SELECT id FROM clubs WHERE owner_id = auth.uid()
    ));

CREATE POLICY "Users can view their own invoices"
    ON invoices FOR SELECT
    USING (user_id = auth.uid());

-- Payment settings policies
CREATE POLICY "Club owners can manage payment settings"
    ON club_payment_settings FOR ALL
    USING (club_id IN (
        SELECT id FROM clubs WHERE owner_id = auth.uid()
    ));

-- Payment methods policies
CREATE POLICY "Club owners can manage payment methods"
    ON payment_methods FOR ALL
    USING (club_id IN (
        SELECT id FROM clubs WHERE owner_id = auth.uid()
    ));

CREATE POLICY "Anyone can view active payment methods"
    ON payment_methods FOR SELECT
    USING (is_active = true);

-- Webhook logs policies (chỉ system admin)
CREATE POLICY "Only system can access webhook logs"
    ON webhook_logs FOR ALL
    USING (false); -- Chỉ có service role mới access được

-- =====================================================
-- INITIAL DATA
-- =====================================================

-- Thêm club_balances table nếu chưa có
CREATE TABLE IF NOT EXISTS club_balances (
    club_id UUID PRIMARY KEY REFERENCES clubs(id) ON DELETE CASCADE,
    balance DECIMAL(12,2) DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- SCHEDULED TASKS (Cron Jobs)  
-- =====================================================

-- Chạy hàng ngày để expire payments cũ
-- Cần setup pg_cron extension:
-- SELECT cron.schedule('expire-old-payments', '0 0 * * *', 'SELECT expire_old_payments();');

COMMENT ON TABLE payments IS 'Bảng lưu trữ tất cả giao dịch thanh toán';
COMMENT ON TABLE invoices IS 'Bảng hóa đơn cho các dịch vụ/booking';
COMMENT ON TABLE club_payment_settings IS 'Cấu hình thanh toán của từng CLB';
COMMENT ON TABLE payment_methods IS 'Phương thức thanh toán của CLB';
COMMENT ON TABLE webhook_logs IS 'Log webhook từ payment gateway';

-- Hoàn thành setup database!